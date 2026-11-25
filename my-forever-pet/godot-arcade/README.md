# Pet Dash 3D lab
Standalone Godot 4.4.1 experiment, not yet linked to the Android app. Open project.godot or run godot --path . . Swipe or arrows, P pauses. 3D geometry and track recycling, smooth lane movement, jump/slide, separate snacks and coins, one-time result. The scene currently uses original procedural placeholder geometry; Blender GLB models, texture polish, native host integration, Android profiling and screenshot comparisons remain necessary. No native wallet mutations or ad integration are implemented. MIT Godot engine license notices must be included on distribution.

Second pass: Blender GLB generation with material batching, actual rendered viewport capture, swept depth collision and jump/slide assertions. No Android host integration yet. Current playable mascot is Mosskit only.

Android lab export: separate package org.myforeverpet.dashlab, ARM64 debug signing only. Does not overwrite native pet app or grant shared currency. Swipe triggers during drag rather than waiting for release; synthetic mouse events ignored. Device gameplay and performance still require physical testing.

0.2 lab: compact interactive HUD, pause/results panel, finish/retry, five-coin trails and varied safe-lane obstacle patterns, recycled entities and jump buffering/fast fall. These are still isolated lab rewards. Automated smoke now checks reuse and repeated coin pickup. Physical performance and final reference-quality art are not yet verified.

0.5 lab: per-type pickup/contact depths, grounded boost trigger, reusable radial contact shadows, floating pickup feedback, and local best score. CI tests do not modify a player's records. These are not shared native app rewards. Physical device performance and visual parity remain open.

0.5 follow-up: deterministic 900m procedural route soak with real collision, scoring and pool limits; capture timing follows the generated safe route instead of benchmarking a crashed/paused screen. HUD updates capped near 13 Hz and camera FOV increases with speed. The headless test is not an Android performance claim.

0.6: screen-size-aware capture environment, APK packaging before visual verification, size-adaptive geometry for small Blender details, earlier imported scenery LODs, shorter shadow range and per-mesh triangle/material/byte reports. No visual-quality or Android FPS claim until verified.

0.7: original baked cloud panorama and distant castle geometry, wooden material texture and crate fittings, explicit Jump/Slide buttons, midair down-swipe fast fall with full landing slide, slide-to-jump cancel, progressive mandatory jump/slide rows and 25m/s top base speed. Deterministic test driver performs required actions rather than bypassing collision. Await verified captures and Android testing.

0.8: continuous-touch direction chaining, quicker lane transitions, jump/roll body pitch, dynamic camera height, floating island motion, power-up rings and speed trails, decorated arches and irregular castle-island silhouettes. Mobile perf and visual parity remain unverified.

0.9 Endless: no destination, finish line or distance-based game-over. Distance only controls difficulty and score. Track chunks and entities recycle indefinitely; collision ends a run unless protected, and deliberate retirement is accessible only through Pause. CI now tests passage through 3000m and an additional 180 physics frames with continued gameplay; this checkpoint is not a production limit. Lab rewards remain local.

Endless hardening: rebase track-local coordinates every 1024m while keeping total distance/score, so long runs do not accumulate world-position precision error. Recycled chunks vary castle-island position, size and rotation using a separate seeded RNG, without allocating new scenery. Soak reports rebases and chunk recycle count.

0.10: moving lane carts, tall lane-blockers, low jump bars, correct red beam vertical overlap and post geometry, crash animation before game-over, original looping music and independent music setting, sky seam blending. Visual reference is still an artistic target; no equivalence claim. Smoke includes vertical clearance and tall obstacle checks; soak includes moving carts.

0.10 visual follow-up: original airborne ship with motion, rainbow geometry, planter flowers, warmer emissive lantern/pickup materials, and exact cart versus tall-block heights. Sky decorations are separate meshes with shadows disabled. Artistic review remains pending.
