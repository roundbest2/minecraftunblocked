# Validation status

Date: November 14, 2026.

## Checks performed

- Parsed all 12 Swift files (11 app files and one test file) with the Swift Tree-sitter grammar: no syntax-error or missing-node results.
- Parsed the Xcode project as an OpenStep property list: 55 objects, with no dangling object references.
- Confirmed every referenced app and test source exists and every app Swift source is included in the app's Sources build phase.
- Confirmed the asset catalog and privacy manifest are included in Resources.
- Parsed Info.plist, PrivacyInfo.xcprivacy, asset-catalog JSON files, the shared scheme, and workspace XML.
- Verified the app icon is an opaque 1024 × 1024 RGB PNG.
- Checked both shell scripts with bash syntax validation.
- Inspected source for private APIs, remote services, and fake jailbreak controls: none are included.

## Checks not performed

The authoring environment runs Linux and has neither Xcode nor the Apple iOS SDK. Swift parsing checks syntax only; it is not Swift type-checking or proof of an iOS build.

Not performed: xcodebuild compilation, XCTest execution, simulator launch, native layout verification, on-device performance tests, Photos import, Lock Screen eligibility tests, signing, archive export, App Store Connect upload, or TestFlight review.

Seven XCTest cases are included for a Mac to run. The Live Photo test checks matching JPEG/MOV identifiers and the still-image timestamp; it cannot guarantee that iOS accepts the resulting image for animated Lock Screen wallpaper.

## Required before distribution

Run scripts/check-mac.sh on a Mac with full Xcode. Resolve any compiler or test failures. Then test on a physical iPhone, especially Live Photo playback, denied Photos permissions, background/resume behavior, export cancellation, large text, VoiceOver, Reduce Motion, and Low Power Mode.

Set a real developer team and unique bundle ID. Create and validate a signed archive, upload it to App Store Connect, and complete the applicable TestFlight review. Nothing in this package is an existing TestFlight invitation or installable IPA.
