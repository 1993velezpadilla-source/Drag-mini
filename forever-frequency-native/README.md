# FOREVER FREQUENCY — City Zero (Native 3D Alpha)

A **native Godot 4.4** third-person Android game: city exploration, companion evolution, music composition, farm harvesting, business investment, and a concert stage. No HTML wrapper. GDScript is plain text and easy to modify.

## Controls
- PC: WASD/arrow keys walk, right mouse drag rotates camera, E interacts.
- Android: left thumb virtual joystick, drag right side of screen to look, INTERACT button.
- Studio: repeat the eight-pad sequence, release a track, grow your audience.
- Home: bond with and evolve your companion.
- Garden: harvest on cooldown.
- Market: expand your businesses (offline coins, capped to eight hours).
- Radio: broadcast your latest track.
- Stage: unlock with 50 fans + 200 coins and play gigs.

## The Blender pipeline
`blender -b -t 2 --python tools/build_assets_blender.py` makes new editable original assets: `assets/city_zero_modular.blend`, `studio_entrance.glb`, `street_kiosk.glb`. Godot imports GLB at edit time. The game supports a fallback procedural studio if the GLB has not been built yet.

## Native Android build
The GitHub workflow `.github/workflows/forever-frequency-android.yml` installs Blender, builds 3D GLBs, runs engine/script tests, and exports **ARM64 APK** with the Godot Android export template. The output is a debug-signed playable test APK, **not a production release**. A Play Store/release signing keystore must be managed separately.

## Modding
Open in Godot. Edit `scripts/city_zero.gd`, `scripts/game_state.gd`, and `scripts/mobile_input.gd`; or change model geometry/materials with `tools/build_assets_blender.py`. `game_state.gd` stores a local save at `user://city_zero_save.json`. No ads, microtransactions, external accounts, or connection needed in this prototype.

## Constraints
Only a first vertical slice. Not yet multiplayer, full APEX DAW integration, full 3D model importer UI, Android live wallpaper, or a large streaming world. These require substantial subsequent development. Android low-end FPS is not yet device-benchmarked.
