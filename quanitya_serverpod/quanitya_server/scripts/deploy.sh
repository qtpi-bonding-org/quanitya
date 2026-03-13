#!/bin/bash
# Quanitya Self-Hosted Deploy
# Generates PowerSync keys, starts all services via Docker Compose.
# Prerequisites: .env file with passwords configured.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"
cd "$SERVER_DIR"

COMPOSE="docker compose -f docker-compose.prod.yaml"

echo "=== Quanitya Self-Hosted Deploy ==="
echo ""

# Check .env exists
if [ ! -f .env ]; then
    echo "ERROR: No .env file found."
    echo "  cp .env.example .env"
    echo "  Edit .env and set your passwords, then re-run this script."
    exit 1
fi

source .env

# Check required vars
if [ -z "$POSTGRES_PASSWORD" ] || [ "$POSTGRES_PASSWORD" = "your_secure_password_here" ]; then
    echo "ERROR: Set POSTGRES_PASSWORD in .env"
    exit 1
fi

# Generate JWK keys if .jwk file doesn't exist
if [ ! -f .jwk ]; then
    echo "Generating PowerSync JWK keys..."
    bash scripts/generate_jwk.sh
    echo ""
fi

# Generate Serverpod auth secrets if not in .env
if [ -z "$SERVICE_SECRET" ]; then
    SERVICE_SECRET=$(openssl rand -base64 48 | tr -d '/+=' | head -c 64)
    echo "SERVICE_SECRET=$SERVICE_SECRET" >> .env
fi
if [ -z "$JWT_HMAC_SHA512_PRIVATE_KEY" ]; then
    JWT_HMAC_SHA512_PRIVATE_KEY=$(openssl rand -base64 48 | tr -d '/+=' | head -c 64)
    echo "JWT_HMAC_SHA512_PRIVATE_KEY=$JWT_HMAC_SHA512_PRIVATE_KEY" >> .env
fi

# Re-source .env to pick up generated secrets
source .env

# Ensure passwords.yaml matches .env
cat > config/passwords.yaml << EOF
production:
  database: $POSTGRES_PASSWORD
  redis: ${REDIS_PASSWORD:-changeme}
  serviceSecret: '$SERVICE_SECRET'
  jwtHmacSha512PrivateKey: '$JWT_HMAC_SHA512_PRIVATE_KEY'
EOF

# Build the server image
echo "Building server image..."
$COMPOSE build quanitya-server

# Step 1: Start postgres + redis
echo "Starting database services..."
$COMPOSE up -d postgres redis

echo "Waiting for PostgreSQL..."
until $COMPOSE exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    sleep 2
done

# Step 2: PowerSync replication setup (before PowerSync starts)
echo "Setting up PowerSync replication..."
$COMPOSE exec -T postgres psql -U postgres -c "CREATE DATABASE powersync_storage;" 2>/dev/null || true
$COMPOSE exec -T postgres psql -U postgres -d quanitya \
    -v powersync_password="$POSTGRES_PASSWORD" < powersync_setup.sql 2>/dev/null || true

# Step 3: Apply migrations (override entrypoint to run migration mode)
echo "Applying migrations..."
$COMPOSE run --rm --entrypoint "./server --mode=production --role=maintenance --apply-migrations --apply-repair-migration" quanitya-server

# Step 4: Start all services
echo "Starting all services..."
$COMPOSE up -d

echo ""
echo "=== Quanitya is running ==="
echo "  API:       http://localhost:8080"
echo "  PowerSync: http://localhost:8095"
echo ""
echo "Stop with: docker compose -f docker-compose.prod.yaml down"
