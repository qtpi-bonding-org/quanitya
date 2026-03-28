#!/bin/bash
# Patches the llamadart framework MinimumOSVersion and re-exports the IPA.
#
# llamadart bug: framework Info.plist says MinimumOSVersion 13.0 but the
# binary targets 16.4. Apple rejects the mismatch. This patches the plist
# and re-exports from the existing archive.
#
# Run after: ./scripts/quanitya.sh build -p ios --release
# Then upload: build/ios/ipa/*.ipa via Transporter

set -e

ARCHIVE="build/ios/archive/Runner.xcarchive"
FRAMEWORK_PLIST="$ARCHIVE/Products/Applications/Runner.app/Frameworks/llamadart.framework/Info.plist"
EXPORT_OPTIONS="build/ios/ipa/ExportOptions.plist"
OUTPUT_DIR="build/ios/ipa"

if [[ ! -f "$FRAMEWORK_PLIST" ]]; then
    echo "Archive not found. Run './scripts/quanitya.sh build -p ios --release' first."
    exit 1
fi

echo "Patching llamadart MinimumOSVersion 13.0 → 16.4..."
plutil -replace MinimumOSVersion -string "16.4" "$FRAMEWORK_PLIST"

echo "Re-exporting IPA..."
rm -f "$OUTPUT_DIR"/*.ipa
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$OUTPUT_DIR" \
    -allowProvisioningUpdates

echo ""
echo "Done. Upload via Transporter: $OUTPUT_DIR/*.ipa"
