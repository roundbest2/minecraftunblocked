#!/bin/bash
# Produces a signed archive. Upload it from Xcode Organizer after device testing.
set -eo pipefail
cd "$(dirname "$0")/.."
if [[ -z "$FLUX_TEAM_ID" || -z "$FLUX_BUNDLE_ID" ]]; then
    echo "Set FLUX_TEAM_ID and FLUX_BUNDLE_ID to your Apple team and registered bundle ID." >&2
    exit 1
fi
if [[ -z "$FLUX_BUILD_NUMBER" ]]; then FLUX_BUILD_NUMBER=1; fi
set -u
if [[ "$FLUX_BUNDLE_ID" == "com.yourcompany.Flux" ]]; then
    echo "Register your own bundle identifier before archiving." >&2
    exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "A Mac with full Xcode is required." >&2
    exit 1
fi
archive_path="$PWD/build/Flux.xcarchive"
if [[ -e "$archive_path" ]]; then
    echo "build/Flux.xcarchive already exists. Move it before making another archive." >&2
    exit 1
fi
xcodebuild \
  -project Flux.xcodeproj \
  -scheme Flux \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$archive_path" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$FLUX_TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$FLUX_BUNDLE_ID" \
  CURRENT_PROJECT_VERSION="$FLUX_BUILD_NUMBER" \
  archive
open "$archive_path"
echo "In Organizer choose Distribute App > App Store Connect > Upload."
