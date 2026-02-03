#!/bin/bash

# PowerSync Setup Script
# This script sets up the PowerSync database roles, permissions, and publication

set -e

echo "=========================================="
echo "PowerSync Database Setup"
echo "=========================================="

# Check if PostgreSQL container is running
if ! docker compose ps postgres | grep -q "Up"; then
    echo "❌ PostgreSQL container is not running. Please start it first with:"
    echo "   docker compose up -d postgres"
    exit 1
fi

echo "✅ PostgreSQL container is running"

# Wait a moment for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 2

# Run the PowerSync setup SQL
echo "🔧 Setting up PowerSync database configuration..."
if docker compose exec -T postgres psql -U postgres -d quanitya < powersync_setup.sql; then
    echo "✅ PowerSync database setup completed successfully!"
else
    echo "❌ Failed to set up PowerSync database configuration"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ PowerSync Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Start PowerSync service: docker compose up -d powersync"
echo "2. Verify setup: ./verify_powersync_setup.sh"
echo ""