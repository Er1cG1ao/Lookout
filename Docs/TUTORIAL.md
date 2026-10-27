# Lookout user guide

**English** · [简体中文](TUTORIAL.zh-CN.md)

## Set up and calibrate

Move Lookout to Applications and open it. Allow Camera access; if previously denied, enable Lookout in System Settings → Privacy & Security → Camera, then reconnect. Select the camera and correct rotation (0°, 90°, 180°, 270°). Preview is mirrored; detection uses the correctly rotated, unmirrored image.

Look at the screen, not the camera. Click `同时校准` (Calibrate both) and hold your natural posture for about a second. You can calibrate either axis separately. Vertical-only calibration leaves the horizontal baseline unchanged; horizontal calibration or manual horizontal setup is required before the first start.

Blue pointers are baselines, green pointers are live angles, pale blue arcs are allowed ranges. Drag a dial or type its baseline. The horizontal dial is a top view. Vertical is a side view: zero points right, up is above it and down below it. Apple's pitch convention is positive for nodding down. Decisions use angles relative to your baseline.

Set left/right and up/down tolerances independently. Vertical protection is off by default, but its dial remains usable. Click `应用并开始保护` (Apply and start). Closing with ⌘W without applying discards pending edits. Camera or rotation changes, including Reconnect, require recalibration. Calibration cannot fix an obstructed face or extreme side view.

## Protection and pauses

Defaults: four tolerances of 30°, turn-away dwell 0.6 seconds, missing face/horizontal angle dwell 1.2 seconds. Return within a range 7° smaller than the trigger range and hold for 0.35 seconds to reveal. Camera errors or frames older than 1.5 seconds activate covering immediately. With vertical protection enabled, missing pitch also prevents a clear result.

These rules do not prove that you left or looked away. Pose is not eye-gaze tracking; face detection is not identity matching.

The menu bar eye icon offers pause, resume, settings and quit. `立即解除遮挡并暂停` immediately clears the cover. Opening settings temporarily clears it for adjustment. Pause and close settings to release the camera. Quitting stops all protection. Each launch needs a manual start. Lock/sleep notifications suspend capture; wake/unlock reacquires a stable face. Lock-notification behavior still needs testing across OS versions.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| No picture | Permission, selected device, other camera apps; reconnect and recalibrate. |
| Normal pose triggers cover | Calibrate while looking at the screen; check limits and vertical switch. |
| Box stays but pointer jumps under occlusion | Pose estimation is disturbed. 0.1.1 adds no smoothing. |
| Box disappears or angle is `—` | Face/pose is unavailable; missing-input rules may activate. |
| Black cover instead of blur | The private blur API failed; opaque fallback is active. |
| Camera indicator stays on | Expected while capturing; other apps may also hold the camera. |
| Another person clears covering | Known limitation: no identity matching. |

## Local data and privacy

Frames stay in memory and are replaced by new frames. No recordings, enrollment, microphone, screen capture, analytics, update checks or network requests. Settings use local `local.giao.lookout` UserDefaults; macOS manages Camera permission independently. The menu bar stays usable. Use the system lock screen for security.
