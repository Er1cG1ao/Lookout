# Development / 开发说明

Requires Apple Silicon, macOS 14+, current Xcode or Command Line Tools, and Python 3 for ICNS packaging. No third-party runtime dependencies.

```sh
bash test.sh
bash build.sh
open build/Lookout.app
```

Output: `build/Lookout.app`. Compilation does not activate capture. Builds are ad hoc signed, not notarized.

## Source map / 源码结构

| Path | Responsibility |
| --- | --- |
| `Sources/main.swift` | Lifecycle, menu bar and settings window |
| `Sources/AppModel.swift` | Permission, settings, calibration and capture/cover coordination |
| `Sources/CameraTracker.swift` | Serial capture, rotation, face selection and Vision pose |
| `Sources/AttentionPolicy.swift` | Configuration and pure time-based policy |
| `Sources/ScreenCover.swift` | Multi-screen windows, private blur and opaque fallback |
| `Sources/SettingsView.swift` | Preview, independent dials and controls |
| `Support/` | Original icon drawing and ICNS packing |
| `Tests/main.swift` | 33 offline policy/settings checks |

Capture prefers 640×480 and analyzes at most eight frames/second. Face selection prefers spatial continuity, otherwise the largest qualifying face; this is not identity matching. Angles are not smoothed. Apple's `VNObservation.h` specifies positive pitch for nodding down.

The private blur API is isolated and falls back to opaque covering on errors. Successful returns do not prove working visuals. Windows ignore mouse input, sit below the menu bar and use all-Spaces/full-screen auxiliary behavior; validate target apps and displays.

## Packaging / 打包

```sh
bash build.sh
bash package.sh dist
bash package-dmg.sh dist
```

Version comes from `Info.plist`. ZIP contains the app, source archive and bilingual documentation. DMG contains the app, Applications shortcut and installation notes. DiskImages support is needed to create DMGs; ZIP is available when that service is unavailable.

The release workflow builds tagged source on an Apple Silicon macOS GitHub Actions runner when a release is published, verifies its tag matches `Info.plist`, runs tests and attaches DMG/ZIP/SHA-256 assets. It needs contents-write permission. CI builds and runs offline checks on source pushes and pull requests. Do not commit camera images, face templates, settings, credentials or build caches.

## Validation / 验证范围

0.1.1 passes 33 offline checks for baseline offsets, asymmetric limits, pitch sign, dwell, hysteresis, missing input, camera errors, persistence and old preference decoding. Local archive integrity, executable permissions and ad hoc signatures were verified. The original user tried the prototype; systematic accuracy, resource, lock/wake and full-screen benchmarks remain outstanding. Compilation alone is not camera or visual verification.
