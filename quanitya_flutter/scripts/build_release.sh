#!/bin/bash

# Quanitya Release Build Script
# Builds production releases for all Flutter platforms with dev code excluded via .dartignore

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[BUILD]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <platform> [options]"
    echo ""
    echo "Platforms:"
    echo "  android    - Build Android APK"
    echo "  ios        - Build iOS IPA (requires macOS and Xcode)"
    echo "  web        - Build web app"
    echo "  macos      - Build macOS app (requires macOS)"
    echo "  windows    - Build Windows app (requires Windows)"
    echo "  linux      - Build Linux app (requires Linux)"
    echo "  all        - Build for all supported platforms on current OS"
    echo ""
    echo "Options:"
    echo "  --release  - Build in release mode (default)"
    echo "  --profile  - Build in profile mode"
    echo "  --help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 android"
    echo "  $0 web --profile"
    echo "  $0 all"
}

# Default values
PLATFORM=""
BUILD_MODE="release"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        android|ios|web|macos|windows|linux|all)
            PLATFORM="$1"
            shift
            ;;
        --release)
            BUILD_MODE="release"
            shift
            ;;
        --profile)
            BUILD_MODE="profile"
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if platform is specified
if [[ -z "$PLATFORM" ]]; then
    print_error "Platform not specified"
    show_usage
    exit 1
fi

# Verify Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Verify .dartignore exists
if [[ ! -f ".dartignore" ]]; then
    print_error ".dartignore file not found. Dev code exclusion requires .dartignore"
    exit 1
fi

print_status "Starting build process..."
print_status "Platform: $PLATFORM"
print_status "Build mode: $BUILD_MODE"
print_status "Dev code excluded via .dartignore"

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Function to build for specific platform
build_platform() {
    local platform=$1
    local mode=$2
    
    print_status "Building for $platform in $mode mode..."
    
    case $platform in
        android)
            flutter build apk --$mode
            if [[ $? -eq 0 ]]; then
                print_success "Android APK built successfully"
                print_status "Output: build/app/outputs/flutter-apk/app-$mode.apk"
            else
                print_error "Android build failed"
                return 1
            fi
            ;;
        ios)
            if [[ "$OSTYPE" != "darwin"* ]]; then
                print_warning "iOS builds require macOS. Skipping..."
                return 0
            fi
            flutter build ios --$mode --no-codesign
            if [[ $? -eq 0 ]]; then
                print_success "iOS app built successfully"
                print_status "Output: build/ios/iphoneos/Runner.app"
                print_warning "Code signing required for distribution"
            else
                print_error "iOS build failed"
                return 1
            fi
            ;;
        web)
            print_status "Using specialized web build script for PowerSync assets..."
            if [[ -f "build_web.sh" ]]; then
                chmod +x build_web.sh
                ./build_web.sh
                if [[ $? -eq 0 ]]; then
                    print_success "Web app built successfully with PowerSync assets"
                    print_status "Output: build/web/"
                else
                    print_error "Web build failed"
                    return 1
                fi
            else
                print_error "build_web.sh not found - required for web builds with PowerSync"
                return 1
            fi
            ;;
        macos)
            if [[ "$OSTYPE" != "darwin"* ]]; then
                print_warning "macOS builds require macOS. Skipping..."
                return 0
            fi
            flutter build macos --$mode
            if [[ $? -eq 0 ]]; then
                print_success "macOS app built successfully"
                print_status "Output: build/macos/Build/Products/Release/quanitya_flutter.app"
            else
                print_error "macOS build failed"
                return 1
            fi
            ;;
        windows)
            if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
                flutter build windows --$mode
                if [[ $? -eq 0 ]]; then
                    print_success "Windows app built successfully"
                    print_status "Output: build/windows/runner/Release/"
                else
                    print_error "Windows build failed"
                    return 1
                fi
            else
                print_warning "Windows builds require Windows. Skipping..."
                return 0
            fi
            ;;
        linux)
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                flutter build linux --$mode
                if [[ $? -eq 0 ]]; then
                    print_success "Linux app built successfully"
                    print_status "Output: build/linux/x64/release/bundle/"
                else
                    print_error "Linux build failed"
                    return 1
                fi
            else
                print_warning "Linux builds require Linux. Skipping..."
                return 0
            fi
            ;;
        *)
            print_error "Unknown platform: $platform"
            return 1
            ;;
    esac
}

# Build for specified platform(s)
if [[ "$PLATFORM" == "all" ]]; then
    print_status "Building for all supported platforms on current OS..."
    
    # Determine which platforms to build based on current OS
    platforms_to_build=()
    
    case "$OSTYPE" in
        darwin*)
            platforms_to_build=("android" "ios" "web" "macos")
            ;;
        linux-gnu*)
            platforms_to_build=("android" "web" "linux")
            ;;
        msys*|cygwin*|win32*)
            platforms_to_build=("android" "web" "windows")
            ;;
        *)
            platforms_to_build=("android" "web")
            ;;
    esac
    
    print_status "Will build for: ${platforms_to_build[*]}"
    
    failed_builds=()
    for platform in "${platforms_to_build[@]}"; do
        if ! build_platform "$platform" "$BUILD_MODE"; then
            failed_builds+=("$platform")
        fi
    done
    
    if [[ ${#failed_builds[@]} -eq 0 ]]; then
        print_success "All builds completed successfully!"
    else
        print_error "Some builds failed: ${failed_builds[*]}"
        exit 1
    fi
else
    build_platform "$PLATFORM" "$BUILD_MODE"
fi

print_success "Build process completed!"
print_status "Dev code was automatically excluded via .dartignore"