#!/bin/bash

# Default port
PORT=8080

# Check for custom port argument
# Parse arguments to extract port
ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --web-port=*)
      PORT="${1#*=}"
      shift # Remove --web-port=... from arguments
      ;;
    *)
      ARGS+=("$1") # Save other arguments
      shift # Remove generic argument
      ;;
  esac
done

# Restore arguments for passing to flutter run
set -- "${ARGS[@]}"

echo "🚀 Starting Quanitya Flutter Web on port $PORT..."
echo "🔒 Enabling COOP/COEP headers for SQLite WASM support..."
echo "🎨 Disabling tree-shake-icons for flutter_iconpicker support..."
echo "ℹ️  Run 'sh setup_powersync_web.sh' first if you haven't downloaded dependencies."

# Run flutter with required headers for SharedArrayBuffer (WASM) support
flutter run \
    --web-port=$PORT \
    --web-header "Cross-Origin-Opener-Policy=same-origin" \
    --web-header "Cross-Origin-Embedder-Policy=require-corp" \
    --no-tree-shake-icons \
    "$@"
