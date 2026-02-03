#!/bin/bash
# Cloudflare Pages build script for Quanitya Flutter Web
# Handles PowerSync web assets and crypto dependencies

set -e

echo "🚀 Building Quanitya Flutter Web for Cloudflare Pages"

# Install Flutter if not available (with caching optimization)
if ! command -v flutter &> /dev/null; then
    echo "📱 Installing Flutter..."
    # Use shallow clone for faster download
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
    export PATH="/opt/flutter/bin:$PATH"
    # Skip doctor for faster builds
    flutter --version
else
    echo "✅ Flutter already available"
fi

# Setup PowerSync web assets (with caching check)
echo "📦 Setting up PowerSync web assets..."
mkdir -p web

# Check if assets already exist (for rebuild optimization)
if [ -f "web/sqlite3.wasm" ] && [ -f "web/powersync_db.worker.js" ]; then
    echo "✅ PowerSync assets already exist, skipping download"
else
    # Download PowerSync web assets
    echo "Downloading sqlite3.wasm..."
    curl -L -o web/sqlite3.wasm https://github.com/powersync-ja/powersync-js/releases/download/packages%2Fweb%401.17.0/sqlite3.wasm

    echo "Downloading powersync_db.worker.js..."
    curl -L -o web/powersync_db.worker.js https://github.com/powersync-ja/powersync-js/releases/download/packages%2Fweb%401.17.0/powersync_db.worker.js

    # Verify assets
    if [ ! -f "web/sqlite3.wasm" ]; then
        echo "❌ Failed to download sqlite3.wasm"
        exit 1
    fi

    if [ ! -f "web/powersync_db.worker.js" ]; then
        echo "❌ Failed to download powersync_db.worker.js"
        exit 1
    fi

    echo "✅ PowerSync web assets downloaded"
fi
ls -la web/

# Get Flutter dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Generate code (required for build)
echo "🔧 Generating code..."
dart run build_runner build --delete-conflicting-outputs

# Build Flutter web
echo "🔨 Building Flutter web..."
flutter build web \
    --release \
    --base-href "/" \
    --source-maps \
    --no-tree-shake-icons \
    --no-wasm-dry-run

# Create Cloudflare headers file
echo "🛡️ Creating security headers..."
cat > build/web/_headers << 'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  Cross-Origin-Resource-Policy: cross-origin

/*.wasm
  Content-Type: application/wasm
  Cross-Origin-Resource-Policy: cross-origin

/*.js
  Cross-Origin-Resource-Policy: cross-origin
EOF

# Verify build
echo "✅ Build complete!"
echo "📊 Build size:"
du -sh build/web/

echo "📁 Build contents:"
ls -la build/web/

echo "🔧 Headers file:"
cat build/web/_headers

echo "🚀 Ready for Cloudflare Pages deployment!"