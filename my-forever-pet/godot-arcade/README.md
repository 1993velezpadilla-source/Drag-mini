# Pet Dash 3D lab
Standalone Godot 4.4.1 experiment, not yet linked to the Android app. Open project.godot or run godot --path . . Swipe or arrows, P pauses. 3D geometry and track recycling, smooth lane movement, jump/slide, separate snacks and coins, one-time result. The scene currently uses original procedural placeholder geometry; Blender GLB models, texture polish, native host integration, Android profiling and screenshot comparisons remain necessary. No native wallet mutations or ad integration are implemented. MIT Godot engine license notices must be included on distribution.

Second pass: Blender GLB generation with material batching, actual rendered viewport capture, swept depth collision and jump/slide assertions. No Android host integration yet. Current playable mascot is Mosskit only.

Android lab export: separate package org.myforeverpet.dashlab, ARM64 debug signing only. Does not overwrite native pet app or grant shared currency. Swipe triggers during drag rather than waiting for release; synthetic mouse events ignored. Device gameplay and performance still require physical testing.

0.2 lab: compact interactive HUD, pause/results panel, finish/retry, five-coin trails and varied safe-lane obstacle patterns, recycled entities and jump buffering/fast fall. These are still isolated lab rewards. Automated smoke now checks reuse and repeated coin pickup. Physical performance and final reference-quality art are not yet verified.

0.5 lab: per-type pickup/contact depths, grounded boost trigger, reusable radial contact shadows, floating pickup feedback, and local best score. CI tests do not modify a player's records. These are not shared native app rewards. Physical device performance and visual parity remain open.
