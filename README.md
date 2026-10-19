# DRAG MINI — portrait street-racing rebuild

**Godot 4.6 · C++17 track authoring · Android ARM64 · single-player offline**

This branch replaces the broken landscape photo-based prototype with an interactive native portrait UI. All four original owner-provided vehicle sprites are preserved as independent transparent textures with chassis/wheel separation. The environment is no longer a stretched race-strip JPEG.

## What's playable

- **Portrait mobile UI:** HOME, RACE, GARAGE, UPGRADES, SETTINGS, CAREER and WALLPAPER each have their own native touch controls. Quick Start launches a race; RACE opens distance selection.
- **Distances:** 1/8 mile (201.168m), 1/4 mile (402.336m), 1/2 mile (804.672m), full mile (1609.344m), with a real world-space finish line.
- **C++17 race environment:** `native/track_generator.cpp` emits reproducible 1800m scenery to `assets/tracks/track_geometry.json`. `scripts/procedural_track.gd` renders road, dashes, Christmas tree, finish line, world props and repeating parallax skyline in Godot's CanvasItem. Scroll/culling is position-based. Supports day, dawn, dusk and night.
- **Driving:** multi-finger gas + launch/shift, single shift timing lamp, EARLY/PERFECT/LATE feedback shown only when tapping shift, false starts, CPU rivals, manual/auto shifting, physics-coupled independently spinning wheels, optional nitrous.
- **Career:** 12 named rival stages with intro lines, escalating challenge distances, one-time result processing and offline progression.
- **Tuning:** 7 parts (engine, turbo, transmission, tires/grip, weight reduction, ECU and nitrous), five levels each, purchases use saved credits, installed parts influence physics (arcade balancing, not real OEM specifications).
- **Persistent preferences:** player cash, XP, story chapter, wins/losses, best times, car choice, tuning, selected distance, auto/manual shift, km/h/mph, haptics, night-vs-device-time and wallpaper touch toggle in `user://drag_mini_v1.cfg`.
- **Wallpaper path:** Godot 4.6 Android live wallpaper plugin integration plus preview inside the app. A swipe/tap on wallpaper responds when the launcher/plugin delivers a touch. The Android picker is opened by the native bridge; not an unrestricted draw-over-other-apps service.

## Build in Godot

1. Install Godot **4.6** and open `project.godot`; game viewport is 432×960 and mobile orientation is portrait.
2. Compile the optional deterministic C++ asset generator from the project root:
   ```sh
   mkdir -p build
   c++ -std=c++17 -O2 native/track_generator.cpp -o build/track_generator
   build/track_generator build/track_geometry.json
   ```
   The committed `assets/tracks/track_geometry.json` is generated from the same source and compared byte-logically in CI; the game also has a deterministic built-in fallback if it is absent.
3. For an Android wallpaper-capable APK, run `python3 scripts/install_wallpaper_plugin.py`, then `bash scripts/build_live_wallpaper_46.sh`. The workflow installs/compiles the pinned third-party MIT plugin against Godot 4.6, exports a signed **debug APK** and verifies the manifest.
4. Run `godot --headless --path . --editor --import --quit`, then the smoke tests:
   ```sh
   godot --headless --path . --script res://tests/smoke.gd
   godot --headless --path . --script res://tests/touch_smoke.gd
   godot --headless --path . --script res://tests/official_assets_smoke.gd
   godot --headless --path . --script res://tests/gauntlet_v1.gd
   ```
   GitHub Actions also rasterizes **portrait screens** using Xvfb, checks C++ generator output and tests menu/career/transactions/shift timing.

## Limitations and release gate

This is **an Android-focused playable rebuild, not a final commercial release**. The Android live wallpaper plugin must still be checked on a physical phone (including lock screen and launchers) after a signed APK builds. Interactions with other apps are *not* implemented: Android requires a separate overlay implementation, permissions and launcher-dependent capabilities; ordinary wallpapers cannot freely control apps or intercept their touch events. There is no online multiplayer, cloud sync, purchased/licensed car sound pack, original in-app music, or store listing. Digital currency is in-game only; no real-money purchases.

The game's car sprites originate from the owner's art; the deprecated JPEG reference `assets/ui/official_main_menu.jpg` is not part of runtime UI nor included in the APK. The previous flat race-strip photo was removed. Verify vehicle branding and asset licensing before publishing.

## Contribution

Prefer PRs to `main`; every screen and mechanic should pass **Master Orchestrator / Adversarial Critic** tests, Android APK checks, real 432×960 screen raster tests, and phone input testing before calling it complete. No credentials/secrets committed.
