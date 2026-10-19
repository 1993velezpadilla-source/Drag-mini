# Drag Mini — retained sprites and visual system

The four 128×54 RGBA vehicle PNGs were provided by the project owner:
- `assets/cars/civic_hatch_game.png` (yellow hatch)
- `assets/cars/supra_mk4_game.png` (white coupe)
- `assets/cars/del_sol_game.png` (red open-roof car)
- `assets/cars/trueno_ae86_game.png` (panda 86)

Each car renders as *one correctly proportioned independent car*, with wheel holes filled by generated independent wheel layer textures in `scripts/wheel_layers.gd`.

The earlier `assets/tracks/official_drag_strip.jpg` was an overly short static photograph that could not properly support 1-mile scrolling. It was explicitly retired and removed. Runtime now draws the track via `scripts/procedural_track.gd`, referencing data authored by the C++17 `native/track_generator.cpp` utility.

The former `assets/ui/official_main_menu.jpg` is an **archival visual reference only**, excluded from Android export. Every interactive control is rendered by `scripts/portrait_shell.gd`—not invisible hotspots over a photo.

Do not treat any one screenshot/photo as proof of dynamic menus, movement, a live Android wallpaper, or phone compatibility. Those must be tested separately.
