#!/bin/bash
# Builds a real iPhone binary without signing. This IPA is not installable yet.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build dist
xcodebuild -version
xcodebuild \
  -quiet \
  -project Flux.xcodeproj \
  -scheme Flux \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -derivedDataPath build/device \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  build 2>&1 | tee build/iphone-build.log
app_path="$PWD/build/device/Build/Products/Release-iphoneos/Flux.app"
test -f "$app_path/Flux"
file "$app_path/Flux"
mkdir -p build/package/Payload
ditto "$app_path" build/package/Payload/Flux.app
ditto -c -k --sequesterRsrc --keepParent build/package/Payload dist/Flux-unsigned.ipa
cat > dist/READ-ME.txt <<'INFO'
Flux-unsigned.ipa contains the compiled iPhone app.

This build is UNSIGNED. It cannot be installed normally on an iPhone and
cannot be submitted to TestFlight as-is. A valid Apple distribution identity,
App Store provisioning, and an App Store Connect upload are still required.

The Flux-simulator artifact is a separate app for an iPhone simulator on a Mac.
It is not an iPhone installer.
INFO
shasum -a 256 dist/Flux-unsigned.ipa > dist/Flux-unsigned.sha256
