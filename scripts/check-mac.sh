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
xcodebuild \
  -quiet \
  -project Flux.xcodeproj \
  -scheme Flux \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath build/DerivedData \
  -parallel-testing-enabled NO \
  -resultBundlePath "build/Tests-$(date +%Y%m%d-%H%M%S).xcresult" \
  CODE_SIGNING_ALLOWED=NO \
  test
