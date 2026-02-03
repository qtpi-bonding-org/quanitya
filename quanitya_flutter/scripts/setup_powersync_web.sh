#!/bin/bash
set -e

echo "Downloading PowerSync Web Dependencies..."

# Create web directory if it doesn't exist
mkdir -p web

# Download powersync_db.worker.js (Version 1.17.0 matching pubspec.lock)
# Source: https://github.com/powersync-ja/powersync.dart/releases
echo "Downloading powersync_db.worker.js..."
curl -L -o web/powersync_db.worker.js "https://github.com/powersync-ja/powersync.dart/releases/download/powersync-v1.17.0/powersync_db.worker.js"

# Download sqlite3.wasm
# Source: https://github.com/powersync-ja/powersync.dart/releases
# Using PowerSync-specific WASM (includes extension)
echo "Downloading sqlite3.wasm..."
curl -L -o web/sqlite3.wasm "https://github.com/powersync-ja/powersync.dart/releases/download/powersync-v1.17.0/sqlite3.wasm"

echo "Download complete."
echo "Please verify files in web/ directory."
