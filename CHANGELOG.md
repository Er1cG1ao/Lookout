# Changelog

## 0.1.1 — Public prototype

- Independent horizontal/vertical dials, live pointers and numeric baselines.
- Separate axis calibration or combined calibration.
- Independent up/down limits with optional vertical protection.
- Preserve 0.1.0 calibration and symmetric vertical tolerance.
- Bilingual docs, packaging/release tooling and original icon.

Known limitations: no identity recognition or precise eye-gaze tracking; occlusion can disturb pose. Camera stays active during protection with the macOS indicator visible. Private blur needs compatibility testing.

## 0.1.0 — Initial personal prototype

- Native menu bar app, camera selection/rotation and baseline yaw dial.
- Time-based turn-away, missing-face and camera-failure decisions.
- Multi-display blur with opaque fallback, preview and manual pause.
