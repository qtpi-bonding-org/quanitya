#!/usr/bin/env bash
set -euo pipefail

# Generates a temporary RSA key pair and runs the PowerSync endpoint tests.
# Usage: ./scripts/run_powersync_tests.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"
TMPDIR_KEY="$(mktemp -d)"

cleanup() {
  rm -rf "$TMPDIR_KEY"
}
trap cleanup EXIT

echo "Generating temporary RSA key pair for tests..."
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
  -outform PEM -out "$TMPDIR_KEY/private.pem" 2>/dev/null

# Base64-encode the PEM (single line, no wrapping)
PEM_BASE64=$(base64 < "$TMPDIR_KEY/private.pem" | tr -d '\n')

echo "Running PowerSync endpoint tests..."
cd "$SERVER_DIR"

POWERSYNC_JWT_PRIVATE_KEY_PEM="$PEM_BASE64" \
  dart test test/integration/powersync_endpoint_test.dart "$@"
