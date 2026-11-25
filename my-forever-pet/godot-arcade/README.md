# Pet Dash 3D lab
Standalone Godot 4.4.1 experiment, not yet linked to the Android app. Open project.godot or run godot --path . . Swipe or arrows, P pauses. 3D geometry and track recycling, smooth lane movement, jump/slide, separate snacks and coins, one-time result. The scene currently uses original procedural placeholder geometry; Blender GLB models, texture polish, native host integration, Android profiling and screenshot comparisons remain necessary. No native wallet mutations or ad integration are implemented. MIT Godot engine license notices must be included on distribution.

Second pass: Blender GLB generation with material batching, actual rendered viewport capture, swept depth collision and jump/slide assertions. No Android host integration yet. Current playable mascot is Mosskit only.

Android lab export: separate package org.myforeverpet.dashlab, ARM64 debug signing only. Does not overwrite native pet app or grant shared currency. Swipe triggers during drag rather than waiting for release; synthetic mouse events ignored. Device gameplay and performance still require physical testing.
