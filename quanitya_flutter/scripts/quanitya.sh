#!/bin/bash
# Quanitya Master Build & Run Script
# Supports iOS, Web, and Android with optimized workflows

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
COMMAND=""
PLATFORM="web"
DEVICE_ID=""
PORT=8080
RELEASE=false
CLEAN=false
INCOGNITO=true  # Default to incognito for web to avoid cache issues
WIPE=false      # Default to not wiping data


# Help function
show_help() {
    echo -e "${BLUE}Quanitya Master Script${NC}"
    echo ""
    echo "Usage: ./quanitya.sh <command> [options]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  setup           Setup dependencies and assets"
    echo "  run             Run in development mode"
    echo "  build           Build for production/release"
    echo "  generate        Run code generation (build_runner)"
    echo "  icons           Generate icon packs for flutter_iconpicker"
    echo "  clean           Clean build cache"
    echo "  test            Run tests"
    echo ""
    echo -e "${YELLOW}Platforms (iOS, Web, Android):${NC}"
    echo "  -p web          Web development (default)
  -p ios          iOS simulator/device
  -p android      Android emulator/device
  -d, --device    Specific device ID/name (e.g. 4DD596AB-...)
  -w, --wipe      Wipe app data before running (fresh start)

Options:
  --port          Web server port (default: 8080)
  --release       Build in release mode
  --clean         Clean before build
  --no-incognito  Disable incognito mode for web (default: enabled)
  -h, --help      Show this help
"
    echo ""
    echo -e "${YELLOW}Environment Variables:${NC}"
    echo "  Automatically loads .env file and injects as --dart-define:"
    echo "  • SERVERPOD_URL → SERVERPOD_URL"
    echo "  • POWERSYNC_URL → POWERSYNC_URL"
    echo "  • OPENROUTER_API_KEY, OPENROUTER_MODEL, GEMINI_API_KEY"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./quanitya.sh setup                    # Setup all dependencies"
    echo "  ./quanitya.sh run                      # Run web dev (incognito)"
    echo "  ./quanitya.sh run -p ios               # Run on iOS simulator"
    echo "  ./quanitya.sh run -p android           # Run on Android"
    echo "  ./quanitya.sh run --port 3000          # Web on port 3000"
    echo "  ./quanitya.sh build                    # Build web for production"
    echo "  ./quanitya.sh build -p ios --release   # Build iOS release"
    echo "  ./quanitya.sh build -p android --release # Build Android release"
    echo ""
    echo -e "${YELLOW}Web Features:${NC}"
    echo "  • Automatic incognito mode (no cache issues)"
    echo "  • PowerSync WASM support (COOP/COEP headers)"
    echo "  • Icon picker support (generated icon packs)"
    echo "  • Security headers for Cloudflare deployment"
    echo "  • Environment variable injection from .env file"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        setup|run|build|generate|icons|clean|test)
            COMMAND="$1"
            shift
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -d|--device)
            DEVICE_ID="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --release)
            RELEASE=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --no-incognito)
            INCOGNITO=false
            shift
            ;;
        -w|--wipe)
            WIPE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate command
if [[ -z "$COMMAND" ]]; then
    echo -e "${RED}Error: No command specified${NC}"
    show_help
    exit 1
fi

# Validate platform
case $PLATFORM in
    web|ios|android|serve)
        ;;
    *)
        echo -e "${RED}Error: Unsupported platform '$PLATFORM'. Use: web, ios, android, or serve${NC}"
        exit 1
        ;;
esac

# Load environment variables from .env file
load_env() {
    if [[ -f ".env" ]]; then
        log_info "Loading environment variables from .env..."
        
        # Export variables, handling comments and empty lines
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip comments and empty lines
            if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
                continue
            fi
            
            # Export valid variable assignments
            if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
                export "${BASH_REMATCH[1]}"="${BASH_REMATCH[2]}"
            fi
        done < .env
        
        log_success "Environment variables loaded"
    else
        log_warning ".env file not found - using default values"
    fi
}

# Get dart-define arguments from environment variables
get_dart_defines() {
    local dart_defines=()
    
    # Map environment variables to dart-define arguments
    if [[ -n "$SERVERPOD_URL" ]]; then
        dart_defines+=("--dart-define=SERVERPOD_URL=$SERVERPOD_URL")
    fi
    
    if [[ -n "$POWERSYNC_URL" ]]; then
        dart_defines+=("--dart-define=POWERSYNC_URL=$POWERSYNC_URL")
    fi
    
    # Add other environment variables as needed
    if [[ -n "$OPENROUTER_API_KEY" ]]; then
        dart_defines+=("--dart-define=OPENROUTER_API_KEY=$OPENROUTER_API_KEY")
    fi
    
    if [[ -n "$OPENROUTER_MODEL" ]]; then
        dart_defines+=("--dart-define=OPENROUTER_MODEL=$OPENROUTER_MODEL")
    fi
    
    if [[ -n "$GEMINI_API_KEY" ]]; then
        dart_defines+=("--dart-define=GEMINI_API_KEY=$GEMINI_API_KEY")
    fi
    
    echo "${dart_defines[@]}"
}

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Flutter is available
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter not found. Please install Flutter first."
        exit 1
    fi
    log_success "Flutter available: $(flutter --version | head -n1)"
}

# Setup PowerSync web assets
setup_powersync_web() {
    log_info "Setting up PowerSync web assets..."
    mkdir -p web
    
    if [[ -f "web/sqlite3.wasm" && -f "web/powersync_db.worker.js" ]]; then
        log_success "PowerSync assets already exist"
        return
    fi
    
    log_info "Downloading sqlite3.wasm..."
    if ! curl -L -o web/sqlite3.wasm "https://github.com/powersync-ja/powersync.dart/releases/download/powersync-v1.17.0/sqlite3.wasm"; then
        log_error "Failed to download sqlite3.wasm"
        exit 1
    fi
    
    log_info "Downloading powersync_db.worker.js..."
    if ! curl -L -o web/powersync_db.worker.js "https://github.com/powersync-ja/powersync.dart/releases/download/powersync-v1.17.0/powersync_db.worker.js"; then
        log_error "Failed to download powersync_db.worker.js"
        exit 1
    fi
    
    # Verify assets
    if [[ ! -f "web/sqlite3.wasm" ]]; then
        log_error "sqlite3.wasm not found after download"
        exit 1
    fi
    
    if [[ ! -f "web/powersync_db.worker.js" ]]; then
        log_error "powersync_db.worker.js not found after download"
        exit 1
    fi
    

    
    log_success "PowerSync web assets downloaded and configured"
}

# Setup environment file
setup_env() {
    if [[ ! -f ".env" ]]; then
        log_info "Creating .env file from template..."
        cp .env.example .env
        log_success ".env file created"
    else
        log_success ".env file already exists"
    fi
}

# Generate icon packs
generate_icons() {
    log_info "Generating icon packs for flutter_iconpicker..."
    dart run flutter_iconpicker:generate_packs --packs material
    log_success "Icon packs generated"
}

# Run code generation
run_codegen() {
    log_info "Running code generation..."
    dart run build_runner build --delete-conflicting-outputs
    log_success "Code generation completed"
}

# Clean build cache
clean_build() {
    log_info "Cleaning build cache..."
    flutter clean
    dart run build_runner clean
    log_success "Build cache cleaned"
}

# Get dependencies
get_deps() {
    log_info "Getting Flutter dependencies..."
    flutter pub get
    log_success "Dependencies updated"
}

# Create Cloudflare headers for web
create_web_headers() {
    log_info "Creating security headers for web..."
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
    log_success "Security headers created"
}

# Open browser in incognito mode
open_incognito() {
    local url="http://localhost:$PORT"
    log_info "Opening $url in incognito Chrome..."
    
    case "$(uname -s)" in
        Darwin)  # macOS
            # Try Chrome first (most reliable for development)
            if command -v "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" &> /dev/null; then
                "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --incognito --new-window "$url" &
                log_success "Opened in Chrome incognito mode"
            elif open -Ra "Google Chrome" --args --incognito "$url" 2>/dev/null; then
                log_success "Opened in Chrome incognito mode"
            else
                log_warning "Chrome not found. Opening in default browser..."
                open "$url"
            fi
            ;;
        Linux)
            if command -v google-chrome &> /dev/null; then
                google-chrome --incognito --new-window "$url" &
                log_success "Opened in Chrome incognito mode"
            elif command -v chromium-browser &> /dev/null; then
                chromium-browser --incognito --new-window "$url" &
                log_success "Opened in Chromium incognito mode"
            else
                log_warning "Chrome not found. Opening in default browser..."
                xdg-open "$url"
            fi
            ;;
        *)
            log_warning "Auto-open not supported on this OS. Open manually: $url"
            ;;
    esac
}

# Main command handlers
cmd_setup() {
    log_info "Setting up Quanitya development environment..."
    check_flutter
    setup_env
    get_deps
    
    if [[ "$PLATFORM" == "web" ]]; then
        setup_powersync_web
    fi
    
    generate_icons
    run_codegen
    log_success "Setup completed for $PLATFORM!"
}

cmd_run() {
    log_info "Starting Quanitya in development mode..."
    log_info "Platform: $PLATFORM"
    
    check_flutter
    load_env  # Load environment variables
    
    # Setup PowerSync assets for web development
    if [[ "$PLATFORM" == "web" ]]; then
        setup_powersync_web
    fi
    
    get_deps
    
    # Get dart-define arguments from environment
    local dart_defines
    read -ra dart_defines <<< "$(get_dart_defines)"
    
    # Add git commit hash for version tracking
    local git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    dart_defines+=("--dart-define=GIT_COMMIT_HASH=$git_commit")
    
    if [[ ${#dart_defines[@]} -gt 0 ]]; then
        log_info "Using environment variables: ${dart_defines[*]}"
    fi
    
    case $PLATFORM in
        web)
            log_info "Starting web development server on port $PORT"
            log_warning "PowerSync WASM support enabled (COOP/COEP headers)"
            log_warning "Icon picker support enabled"
            
            # Verify PowerSync assets exist
            if [[ ! -f "web/sqlite3.wasm" || ! -f "web/powersync_db.worker.js" ]]; then
                log_error "PowerSync WASM assets missing. Run: ./quanitya.sh setup"
                exit 1
            fi
            
            if [[ "$INCOGNITO" == true ]]; then
                log_info "Incognito mode enabled - no cache issues!"
                flutter run \
                    -d chrome \
                    --web-port=$PORT \
                    --web-browser-flag="--incognito" \
                    --web-header "Cross-Origin-Opener-Policy=same-origin" \
                    --web-header "Cross-Origin-Embedder-Policy=require-corp" \
                    --web-header "Cross-Origin-Resource-Policy=cross-origin" \
                    "${dart_defines[@]}"
            else
                flutter run \
                    -d chrome \
                    --web-port=$PORT \
                    --web-header "Cross-Origin-Opener-Policy=same-origin" \
                    --web-header "Cross-Origin-Embedder-Policy=require-corp" \
                    --web-header "Cross-Origin-Resource-Policy=cross-origin" \
                    "${dart_defines[@]}"
            fi
            ;;
        ios)
            log_info "Starting on iOS simulator/device..."
            if [[ "$WIPE" == true ]]; then
                log_warning "Wiping iOS app data and resetting keychain for com.quanitya.quanitya..."
                local target_device="${DEVICE_ID:-booted}"
                # Wipe app sandbox (database, documents)
                xcrun simctl uninstall "$target_device" com.quanitya.quanitya || log_warning "Failed to uninstall (maybe app not installed?)"
                # Nuke keychain (where Encryption Keys are stored)
                xcrun simctl keychain "$target_device" reset
                log_info "iOS factory reset complete."
            fi

            flutter run -d "${DEVICE_ID:-ios}" "${dart_defines[@]}"
            ;;
        android)
            log_info "Starting on Android emulator/device..."
            if [[ "$WIPE" == true ]]; then
                log_warning "Wiping Android app data for com.quanitya.quanitya..."
                local target_device="${DEVICE_ID:-android}"
                adb -s "$target_device" shell pm clear com.quanitya.quanitya || log_warning "Failed to clear (maybe app not installed?)"
            fi
            flutter run -d "${DEVICE_ID:-android}" "${dart_defines[@]}"
            ;;
    esac
}

cmd_build() {
    log_info "Building Quanitya for $PLATFORM..."
    check_flutter
    load_env  # Load environment variables
    
    if [[ "$CLEAN" == true ]]; then
        clean_build
    fi
    
    get_deps
    run_codegen
    
    # Get dart-define arguments from environment
    local dart_defines
    read -ra dart_defines <<< "$(get_dart_defines)"
    
    # Add git commit hash for version tracking
    local git_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    dart_defines+=("--dart-define=GIT_COMMIT_HASH=$git_commit")
    
    if [[ ${#dart_defines[@]} -gt 0 ]]; then
        log_info "Using environment variables: ${dart_defines[*]}"
    fi
    
    case $PLATFORM in
        web)
            log_info "Building Flutter web for production..."
            
            # Create .env file with API keys (matching GitHub workflow)
            log_info "Setting up environment file..."
            cat > .env << 'EOF'
# OpenRouter API Configuration (for AI features)
OPENROUTER_API_KEY=dummy_key_for_web_build
OPENROUTER_MODEL=openai/gpt-4o-mini

# BYOK - Bring Your Own Key (Gemini)
# GEMINI_API_KEY=dummy_gemini_key
EOF
            log_success "Environment file created"
            
            setup_powersync_web
            
            # Verify PowerSync assets exist
            if [[ ! -f "web/sqlite3.wasm" || ! -f "web/powersync_db.worker.js" ]]; then
                log_error "PowerSync WASM assets missing. Run: ./quanitya.sh setup"
                exit 1
            fi
            
            # Clean build cache to ensure fresh generation (matching GitHub workflow)
            log_info "Cleaning build cache..."
            flutter clean
            dart run build_runner clean
            
            # Get dependencies
            flutter pub get
            
            # Generate code (required for build)
            log_info "Running code generation..."
            dart run build_runner build --delete-conflicting-outputs
            log_success "Code generation completed"
            
            BUILD_ARGS=(
                "web"
            )
            
            # Use debug mode for development builds, release for production
            if [[ "$RELEASE" == true ]]; then
                BUILD_ARGS+=("--release")
                log_info "Building in RELEASE mode for production"
            else
                BUILD_ARGS+=("--debug")
                log_info "Building in DEBUG mode for development"
            fi
            
            BUILD_ARGS+=(
                "--base-href" "/"
                "--source-maps"
                "--no-tree-shake-icons"
                "${dart_defines[@]}"
            )
            
            flutter build "${BUILD_ARGS[@]}"
            
            # Create headers with WASM support (matching GitHub workflow)
            cat > build/web/_headers << 'EOF'
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  Cross-Origin-Resource-Policy: cross-origin
  Permissions-Policy: web-share=(), camera=(), microphone=(), geolocation=()
  Referrer-Policy: strict-origin-when-cross-origin
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY

/*.wasm
  Content-Type: application/wasm
  Cross-Origin-Resource-Policy: cross-origin
  Cache-Control: public, max-age=31536000, immutable

/*.js
  Cross-Origin-Resource-Policy: cross-origin
  Cache-Control: public, max-age=31536000, immutable

/flutter_service_worker.js
  Cache-Control: no-cache, no-store, must-revalidate

/main.dart.js
  Cross-Origin-Resource-Policy: cross-origin
EOF
            
            log_success "Web build completed!"
            log_info "Build size: $(du -sh build/web | cut -f1)"
            log_info "Deploy: Upload build/web/ to your web server"
            log_info "Headers: _headers file created with WASM MIME type support"
            ;;
        ios)
            if [[ "$RELEASE" == true ]]; then
                log_info "Building iOS for App Store release..."
                flutter build ios --release "${dart_defines[@]}"
                log_success "iOS release build completed!"
                log_info "Next: Open ios/Runner.xcworkspace in Xcode to archive"
            else
                log_info "Building iOS for development..."
                flutter build ios "${dart_defines[@]}"
                log_success "iOS development build completed!"
            fi
            ;;
        android)
            if [[ "$RELEASE" == true ]]; then
                log_info "Building Android App Bundle for Play Store..."
                flutter build appbundle --release "${dart_defines[@]}"
                log_success "Android App Bundle completed!"
                log_info "File: build/app/outputs/bundle/release/app-release.aab"
            else
                log_info "Building Android APK for development..."
                flutter build apk "${dart_defines[@]}"
                log_success "Android APK completed!"
                log_info "File: build/app/outputs/flutter-apk/app-release.apk"
            fi
            ;;
    esac
}

cmd_generate() {
    log_info "Running code generation..."
    check_flutter
    run_codegen
}

cmd_icons() {
    log_info "Generating icon packs..."
    check_flutter
    generate_icons
}

cmd_clean() {
    log_info "Cleaning build cache..."
    clean_build
}

cmd_test() {
    log_info "Running tests..."
    check_flutter
    flutter test
    log_success "Tests completed!"
}

# Execute command
case $COMMAND in
    setup)
        cmd_setup
        ;;
    run)
        cmd_run
        ;;
    build)
        cmd_build
        ;;
    generate)
        cmd_generate
        ;;
    icons)
        cmd_icons
        ;;
    clean)
        cmd_clean
        ;;
    test)
        cmd_test
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac