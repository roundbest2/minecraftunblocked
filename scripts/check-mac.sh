#!/bin/bash
# Builds and runs export/persistence tests without signing or an Apple account.
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Install full Xcode on a Mac before running this check." >&2
    exit 1
fi
xcodebuild -version
device_id="$(xcrun simctl list devices available --json | python3 -c '
import json,sys
devices=json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    if "iOS" not in runtime:
        continue
    for device in devices[runtime]:
        if device.get("isAvailable") and device.get("name","").startswith("iPhone"):
            print(device["udid"]); sys.exit(0)
sys.exit("Install an iPhone simulator runtime in Xcode Settings > Components.")
')"
result_path="build/Tests-$(date +%Y%m%d-%H%M%S).xcresult"
xcodebuild \
  -quiet \
  -project Flux.xcodeproj \
  -scheme Flux \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath build/DerivedData \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
xcrun simctl bootstatus "$device_id" -b
app_path="$PWD/build/DerivedData/Build/Products/Debug-iphonesimulator/Flux.app"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app_path/Info.plist")"
xcrun simctl install "$device_id" "$app_path"
xcrun simctl privacy "$device_id" grant photos-add "$bundle_id"
xcrun simctl status_bar "$device_id" override --time "9:41" --batteryState charged --batteryLevel 100
set +e
xcodebuild \
  -quiet \
  -project Flux.xcodeproj \
  -scheme Flux \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath build/DerivedData \
  -parallel-testing-enabled NO \
  -resultBundlePath "$result_path" \
  CODE_SIGNING_ALLOWED=NO \
  test-without-building
test_status=$?
set -e
if [[ -d "$result_path" ]]; then
  xcrun xcresulttool get test-results summary --path "$result_path" > build/test-summary.json
  xcrun xcresulttool export attachments --path "$result_path" --output-path build/screenshots
  cat build/test-summary.json
fi
exit "$test_status"
