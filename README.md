<p align="center">
  <img src="Assets/AppIcon.png" width="128" alt="Lookout app icon">
</p>

# Lookout

**Look away. Keep your screen to yourself.**

A lightweight native macOS menu bar app that blurs your screens when you turn away or leave your seat. Lookout estimates head orientation with your camera and Apple's Vision framework, entirely on your Mac.

**English** · [简体中文](README.zh-CN.md)

[Download](https://github.com/Er1cG1ao/Lookout/releases) · [User guide](Docs/TUTORIAL.md) · [Development](Docs/DEVELOPMENT.md) · [Report an issue](https://github.com/Er1cG1ao/Lookout/issues)

**Public prototype · 0.1.1.** Lookout detects faces and head orientation; it does **not** recognize identity or track exact eye gaze. Another person can clear the cover. Visual covering does not replace locking your Mac.

## What it does

- **Calibrate for your setup:** set your natural screen-facing pose, including when the camera is beside the display.
- **Adjust two independent dials:** horizontal/vertical baselines, live pointers, numeric input, separate or combined calibration.
- **Set four tolerances:** left, right, looking up and looking down are independent. Vertical protection is optional.
- **Avoid boundary flicker:** configurable dwell and a smaller return range tolerate brief movements.
- **Cover every display:** turning away, losing the face/pose or interrupted capture can activate the cover; blur errors fall back to an opaque cover.
- **Stay in the menu bar:** open settings for a Dock icon and preview; close with ⌘W to return to menu bar mode. Pause at any time.

Swift, SwiftUI, AppKit, AVFoundation and Vision. No bundled browser, downloaded model, account or network service. Docs are bilingual; the app interface currently uses Simplified Chinese.

## Install and start

Requires **Apple Silicon (M-series), macOS 14+**, and a camera. Intel installers are not provided.

1. Download the DMG or ZIP from **Assets** in [Releases](https://github.com/Er1cG1ao/Lookout/releases). Prototypes are marked **Pre-release**.
2. Quit the older instance, then drag `Lookout.app` into **Applications**.
3. Open, allow Camera access, select the device and correct image rotation if needed.
4. Look naturally at the screen. Click `同时校准` (Calibrate both), hold still about a second and fine-tune either dial.
5. Set tolerances, optionally enable vertical protection, then click `应用并开始保护` (Apply and start).

Settings temporarily removes the cover. Closing without applying discards pending changes. Each launch needs a manual start. See the [guide](Docs/TUTORIAL.md).

Builds use ad hoc signing and are **not Apple-notarized**. If first launch is blocked, verify the source and allow the app in **Privacy & Security**. Disabling system security protections is not required.

## Scope and privacy

- Frames stay in memory and are never recorded, saved or uploaded. No microphone use or network requests.
- Camera stays active during protection/settings preview, with the macOS camera-use indicator visible. Pause and close settings to release it.
- Face detection proves neither identity nor attention. Partial occlusion can disturb angles while a face box remains. Light, glasses and camera placement can affect detection.
- Blur uses the private `CGSSetWindowBackgroundBlurRadius` API. Future OS updates can affect it. Missing symbols or errors trigger opaque covering; successful returns still need visual verification.
- This is not a lock screen, authentication barrier or screenshot protection. Menu bar access deliberately remains available.
- Settings stay in local UserDefaults. No enrollment or face template is stored.

## Build from source

Install current Apple Command Line Tools or Xcode:

```sh
git clone https://github.com/Er1cG1ao/Lookout.git
cd Lookout
bash build.sh
bash test.sh
```

Output: `build/Lookout.app`. Building neither installs the app nor activates capture. See [Development](Docs/DEVELOPMENT.md) for packaging and validation.

## Help and contribute

Open an [Issue](https://github.com/Er1cG1ao/Lookout/issues) with app/macOS versions, camera placement, steps, and expected versus actual results. For occlusion issues, note whether the face box disappears or angles jump. Remove personal information and avoid uploading camera images of people.

[English guide](Docs/TUTORIAL.md) · [中文教程](Docs/TUTORIAL.zh-CN.md) · [Development](Docs/DEVELOPMENT.md) · [Changelog](CHANGELOG.md)

## License and origins

[MIT](LICENSE). [HeadOrbit](https://github.com/Cogria-AI/HeadOrbit) inspired the blur and dwell/hysteresis approach; [Glance](https://github.com/jonnyoo/glance) informed the camera/Vision pipeline. No Glance identity model is included. See [Third-party notices](THIRD_PARTY_NOTICES.md). The original icon is drawn in [`Support/make-icon.swift`](Support/make-icon.swift).
