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
