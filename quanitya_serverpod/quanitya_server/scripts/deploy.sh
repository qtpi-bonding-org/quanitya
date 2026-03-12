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

# Ensure passwords.yaml matches .env
cat > config/passwords.yaml << EOF
production:
  database: $POSTGRES_PASSWORD
  redis: ${REDIS_PASSWORD:-changeme}
EOF

# Build and start services
echo "Building and starting services..."
$COMPOSE up -d --build

# Wait for Postgres
echo "Waiting for PostgreSQL..."
until $COMPOSE exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    sleep 2
done

# PowerSync replication setup (idempotent — errors on re-run are expected)
echo "Setting up PowerSync replication..."
$COMPOSE exec -T postgres psql -U postgres -d quanitya \
    -v powersync_password="'$POSTGRES_PASSWORD'" < powersync_setup.sql 2>/dev/null || true

# Apply migrations
echo "Applying migrations..."
$COMPOSE run --rm quanitya-server /app/server --mode production --role maintenance --apply-migrations --apply-repair-migration

# Restart server after migrations
$COMPOSE restart quanitya-server

echo ""
echo "=== Quanitya is running ==="
echo "  API:       http://localhost:8080"
echo "  PowerSync: http://localhost:8095"
echo ""
echo "Stop with: $COMPOSE down"
