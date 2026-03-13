#!/usr/bin/env bash
set -euo pipefail

# Downloads the native PowerSync SQLite extension for running tests.
#
# Usage: ./scripts/setup_powersync_tests.sh
#
# Prerequisites:
#   - Homebrew SQLite with extension loading (brew install sqlite)
#     macOS system SQLite ships with OMIT_LOAD_EXTENSION
#
# What this does:
#   1. Detects your OS and CPU architecture
#   2. Downloads the matching libpowersync binary from GitHub releases
#   3. Places it in the project root as libpowersync.dylib / .so / .dll
#   4. Verifies it loads correctly
#
# After running this script, you can run PowerSync-native tests:
#   flutter test test/data/powersync_native_test.dart

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# PowerSync SQLite core version — update when upgrading powersync package
POWERSYNC_CORE_VERSION="v0.4.11"
GITHUB_BASE="https://github.com/powersync-ja/powersync-sqlite-core/releases/download/${POWERSYNC_CORE_VERSION}"

# ── Detect platform ──────────────────────────────────────────────────────────

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin)
    case "$ARCH" in
      x86_64)  ASSET="libpowersync_x64.macos.dylib" ;;
      arm64)   ASSET="libpowersync_aarch64.macos.dylib" ;;
      *)       echo "❌ Unsupported macOS architecture: $ARCH"; exit 1 ;;
    esac
    TARGET="libpowersync.dylib"
    ;;
  Linux)
    case "$ARCH" in
      x86_64)  ASSET="libpowersync_x64.so" ;;
      aarch64) ASSET="libpowersync_aarch64.so" ;;
      *)       echo "❌ Unsupported Linux architecture: $ARCH"; exit 1 ;;
    esac
    TARGET="libpowersync.so"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    ASSET="powersync_x64.dll"
    TARGET="powersync.dll"
    ;;
  *)
    echo "❌ Unsupported OS: $OS"
    exit 1
    ;;
esac

TARGET_PATH="$PROJECT_DIR/$TARGET"

# ── Check prerequisites ──────────────────────────────────────────────────────

if [[ "$OS" == "Darwin" ]]; then
  # Check for Homebrew SQLite (system SQLite has OMIT_LOAD_EXTENSION)
  SQLITE_LIB=""
  if [[ -f "/usr/local/opt/sqlite/lib/libsqlite3.dylib" ]]; then
    SQLITE_LIB="/usr/local/opt/sqlite/lib/libsqlite3.dylib"
  elif [[ -f "/opt/homebrew/opt/sqlite/lib/libsqlite3.dylib" ]]; then
    SQLITE_LIB="/opt/homebrew/opt/sqlite/lib/libsqlite3.dylib"
  fi

  if [[ -z "$SQLITE_LIB" ]]; then
    echo "⚠️  Homebrew SQLite not found."
    echo "   macOS system SQLite has OMIT_LOAD_EXTENSION."
    echo "   Install with: brew install sqlite"
    exit 1
  fi
  echo "✓ Homebrew SQLite: $SQLITE_LIB"
fi

# ── Download ─────────────────────────────────────────────────────────────────

if [[ -f "$TARGET_PATH" ]]; then
  echo "✓ $TARGET already exists at $TARGET_PATH"
  echo "  Delete it and re-run to force re-download."
else
  echo "Downloading $ASSET (${POWERSYNC_CORE_VERSION})..."
  curl -L --fail -o "$TARGET_PATH" "$GITHUB_BASE/$ASSET"
  echo "✓ Downloaded to $TARGET_PATH"
fi

# ── Verify ───────────────────────────────────────────────────────────────────

echo ""
echo "Verifying native library..."
file "$TARGET_PATH"

if [[ "$OS" == "Darwin" && -n "${SQLITE_LIB:-}" ]]; then
  SQLITE_BIN=""
  if [[ -f "/usr/local/opt/sqlite/bin/sqlite3" ]]; then
    SQLITE_BIN="/usr/local/opt/sqlite/bin/sqlite3"
  elif [[ -f "/opt/homebrew/opt/sqlite/bin/sqlite3" ]]; then
    SQLITE_BIN="/opt/homebrew/opt/sqlite/bin/sqlite3"
  fi

  if [[ -n "$SQLITE_BIN" ]]; then
    if $SQLITE_BIN ':memory:' ".load $TARGET_PATH sqlite3_powersync_init" ".exit" 2>/dev/null; then
      echo "✓ Extension loads successfully"
    else
      echo "⚠️  Extension load test failed (tests may still work via Dart FFI)"
    fi
  fi
fi

# ── Check .gitignore ─────────────────────────────────────────────────────────

if ! grep -q "$TARGET" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
  echo ""
  echo "⚠️  Add '$TARGET' to .gitignore — it's a platform-specific binary."
fi

echo ""
echo "Setup complete. Run PowerSync tests with:"
echo "  flutter test test/data/powersync_native_test.dart"
