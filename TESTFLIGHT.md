# TestFlight submission worksheet

This is draft metadata, not evidence of an upload or approval. Replace the bundle ID and enter your real contact details in App Store Connect. Do not submit before a successful Mac build and physical-device test.

## App

Name: Flux — Motion Studio

Version: 1.0

Initial build: 1

Category: Graphics & Design

Bundle ID: Set your own registered identifier; com.yourcompany.Flux is only a project placeholder.

## Beta description

Make your screen move with Flux, a personal wallpaper and motion studio. Explore six animated wallpaper styles, tune their colors and motion, save still images or Live Photos, and share video loops. Try springy cards, 3D flips, and a draggable glowing orb in the motion lab.

Flux customizes its own interface. It does not jailbreak iOS or replace system animations. Lock Screen motion depends on iOS Live Photo support; Home Screen wallpapers remain still.

## What to Test

- Try each wallpaper and each accent. Adjust speed and intensity.
- Add favorites, close Flux, and reopen it. Check that your preferences remain.
- Share a PNG and a movie; play the movie in Photos or another viewer.
- Save a Live Photo, verify that Photos identifies and plays it, then try it as a Lock Screen wallpaper. Report if iOS marks motion unavailable, with your iPhone model and iOS version.
- Deny Photos access, attempt a save, and check that the app shows a helpful error. Try saving again after changing the permission in Settings.
- Cancel a video export before it finishes.
- Try all motion presets, duration and bounce settings, and haptics.
- Enable Reduce Motion and Low Power Mode. Check that moving previews pause.
- Test with VoiceOver and larger text.

## Review notes

No sign-in or demo account is required. All wallpapers are generated locally. There is no remote server, executable download, profile installation, or operating-system modification.

The Photos permission is add-only and appears when the user chooses Save Live Photo. Still images and movie loops are shared through the system share sheet.

Wallpaper setup is performed by the user in iOS Settings. Flux makes no claim to control system animations or to guarantee Lock Screen motion for every generated Live Photo.

## Fields the account owner must supply

- Beta feedback email.
- Review contact name, email, and telephone number.
- Unique bundle ID and developer team.
- Appropriate age rating and any current platform compliance responses.
- Privacy/support URLs if requested by the relevant submission flow.

If publishing a privacy policy, review PRIVACY.md and host it at a real URL you control. This source package does not provide a hosted support website.
