# DRAG MINI 🏁

Godot 4.6 · Android-first · Pixel drag racing — **prototype v0.1**.

This repo contains a **first offline quarter-mile prototype**, not a published game. Choose from four starter cars, toggle automatic/manual shifting, and race a CPU rival. Powertrain parameters are fictional **arcade balancing** values.

## How to run
1. Install Godot 4.6 and import `project.godot`.
2. Hit Play. Select a car in the garage; choose AUTO/MANUAL and then `RACE 1/4 MILE`.
3. In manual mode **hold gas** and **shift +** near redline. Auto mode accelerates and shifts itself.
4. Headless smoke: `godot --headless --path . --script res://tests/smoke.gd`.

## Included
Four transparent pixel PNGs from project-owner images, downscaled as 128×54 game sprites for the first mobile prototype: yellow hatch, white coupe, red targa and panda 86. Larger master sprites are packaged separately for the team.

## Not implemented yet
Online races, persistent garage, paid slots, mods/tuning, animated wheel layers, actual Android wallpaper service, system overlay, Android APK, authoritative server, real licensed car audio. **Six free garage slots** is a planned product rule, not real save data yet. Wallpaper/overlay will require a native Android plugin and operating-system permission handling.

## Collaboration
Work in feature branches. Review PRs before merge. Invite Félix under GitHub Settings → Collaborators. Never add private keys or secrets to Git.

Before publishing, vet names, vehicle likenesses and intellectual-property rights.

## Wallpaper plugin — TheOathMan
We use **TheOathMan/Godot-Android-Live-Wallpaper v1.5.1**, MIT licensed.
Pinned official release: `0bfc928515cf1ba8f7127754a2d28e995f508145aadd35d7a5ebdf8f2153a6b2` SHA-256.
This third-party binary is **not checked into the repository**. Install it before opening in the editor:

```sh
python3 scripts/install_wallpaper_plugin.py
```

Project settings enable the `LiveWallpaper` editor plugin. Use **Godot 4.6, GL Compatibility**, install **Android Build Template**, and **Use Gradle Build** in the Android export preset.
The home screen wallpaper integration displays the selected car on a quiet track and suppresses race controls; wallpaper mode caps the frame rate and pauses rendering when the system reports it hidden. The normal Android app displays a `WALLPAPER` button to open the system wallpaper picker. Selection persists in `user://garage.cfg`. Nothing takes over another application's UI: that requires a separate **Android overlay** implementation.

**Caution:** Release v1.5.1 was built against Godot 4.5.0, and compatibility with the Godot 4.6 *Android binary export* is unproven. The GitHub CI checks only import and script behavior on Linux; physical Android verification is required (including lock screen, Android 14+ behavior, launchers, battery). Samsung launchers may not report home-screen offsets correctly. Wallpaper is not an unrestricted interactive overlay.

Upstream: https://github.com/TheOathMan/Godot-Android-Live-Wallpaper — MIT © 2024 Othman Alzhrani.
