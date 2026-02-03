#!/bin/bash

# PowerSync Setup Verification Script (Phase 2 & Phase 3)
# This script verifies that PostgreSQL and PowerSync Service are correctly configured

set -e

echo "=========================================="
echo "PowerSync Setup Verification"
echo "=========================================="
echo ""

# Configuration
DB_USER="postgres"
DB_NAME="quanitya"

echo "Checking if PostgreSQL service is running..."
if ! docker compose ps postgres | grep -q "Up\|healthy"; then
    echo "❌ ERROR: PostgreSQL service is not running"
    echo "   Run: docker compose up -d"
    exit 1
fi
echo "✅ PostgreSQL service is running"
echo ""

echo "=========================================="
echo "PHASE 2: PostgreSQL Configuration"
echo "=========================================="
echo ""

echo "1. Verifying wal_level is set to 'logical'..."
WAL_LEVEL=$(docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -t -c "SHOW wal_level;" | xargs)
if [ "$WAL_LEVEL" = "logical" ]; then
    echo "✅ wal_level = $WAL_LEVEL"
else
    echo "❌ ERROR: wal_level = $WAL_LEVEL (expected: logical)"
    exit 1
fi
echo ""

echo "2. Verifying powersync_role exists with correct privileges..."
ROLE_CHECK=$(docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -t -c \
    "SELECT COUNT(*) FROM pg_roles WHERE rolname = 'powersync_role' AND rolreplication = true AND rolbypassrls = true AND rolcanlogin = true;" | xargs)
if [ "$ROLE_CHECK" = "1" ]; then
    echo "✅ powersync_role exists with REPLICATION, BYPASSRLS, and LOGIN privileges"
    docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -c \
        "SELECT rolname, rolreplication, rolbypassrls, rolcanlogin FROM pg_roles WHERE rolname = 'powersync_role';" | head -3
else
    echo "❌ ERROR: powersync_role not found or missing required privileges"
    exit 1
fi
echo ""

echo "3. Verifying powersync publication exists..."
PUB_CHECK=$(docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -t -c \
    "SELECT COUNT(*) FROM pg_publication WHERE pubname = 'powersync' AND puballtables = true;" | xargs)
if [ "$PUB_CHECK" = "1" ]; then
    echo "✅ powersync publication exists with FOR ALL TABLES"
    docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -c \
        "SELECT pubname, puballtables FROM pg_publication WHERE pubname = 'powersync';" | head -3
else
    echo "❌ ERROR: powersync publication not found or not configured for all tables"
    exit 1
fi
echo ""

echo "4. Verifying SELECT permissions for powersync_role..."
# Create a temporary test table
docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -c \
    "CREATE TABLE IF NOT EXISTS _powersync_test (id SERIAL PRIMARY KEY, data TEXT);" > /dev/null
docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -c \
    "INSERT INTO _powersync_test (data) VALUES ('test');" > /dev/null

# Try to SELECT as powersync_role
if docker compose exec -T postgres psql -U powersync_role -d $DB_NAME -c \
    "SELECT * FROM _powersync_test;" > /dev/null 2>&1; then
    echo "✅ powersync_role can SELECT from tables"
else
    echo "❌ ERROR: powersync_role cannot SELECT from tables"
    docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -c \
        "DROP TABLE IF EXISTS _powersync_test;" > /dev/null
    exit 1
fi

# Clean up test table
docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -c \
    "DROP TABLE _powersync_test;" > /dev/null
echo ""

echo "=========================================="
echo "PHASE 3: PowerSync Service"
echo "=========================================="
echo ""

echo "5. Checking if PowerSync service is running..."
if ! docker compose ps powersync | grep -q "Up\|healthy"; then
    echo "❌ ERROR: PowerSync service is not running"
    echo "   Run: docker compose up -d powersync"
    exit 1
fi
echo "✅ PowerSync service is running"
echo ""

echo "6. Verifying PowerSync replication slot exists and is active..."
SLOT_CHECK=$(docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -t -c \
    "SELECT COUNT(*) FROM pg_replication_slots WHERE slot_name LIKE '%powersync%' AND active = true;" | xargs)
if [ "$SLOT_CHECK" -ge "1" ]; then
    echo "✅ PowerSync replication slot is active"
    docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -c \
        "SELECT slot_name, plugin, active FROM pg_replication_slots WHERE slot_name LIKE '%powersync%';" | head -3
else
    echo "❌ ERROR: PowerSync replication slot not found or not active"
    exit 1
fi
echo ""

echo "7. Verifying powersync schema exists..."
SCHEMA_CHECK=$(docker compose exec -T postgres psql -U $DB_USER -d $DB_NAME -t -c \
    "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = 'powersync';" | xargs)
if [ "$SCHEMA_CHECK" = "1" ]; then
    echo "✅ powersync schema exists"
else
    echo "❌ ERROR: powersync schema not found"
    exit 1
fi
echo ""

echo "10. Verification of PowerSync logs..."
# Using docker compose logs instead of docker logs for service-level abstraction
echo "Checking PowerSync logs for errors..."
ERROR_KIND=$(docker compose logs powersync --tail 100 2>&1 | grep -i "\"level\":\"error\"" | head -n 1)
if [ -z "$ERROR_KIND" ]; then
    echo "✅ No obvious errors in recent PowerSync logs"
else
    echo "⚠️  WARNING: Found potential errors in PowerSync logs"
    echo "   $ERROR_KIND"
fi
echo ""

echo "=========================================="
echo "✅ All verifications passed!"
echo "=========================================="
echo ""
echo "Your PowerSync setup is complete and working correctly!"
echo ""