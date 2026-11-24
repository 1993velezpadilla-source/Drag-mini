# City Zero: real 3D reference car (CC0) — reproducible import, not invented geometry

Source repository: https://github.com/JaronKBragg7337/spectral-gt-rs  
Game-ready 3D GLB: https://github.com/JaronKBragg7337/spectral-gt-rs/blob/main/spectral_gt_rs_game_ready.glb  
Editable Blender master: https://github.com/JaronKBragg7337/spectral-gt-rs/blob/main/spectral_gt_rs_master.blend  
Source generator: https://github.com/JaronKBragg7337/spectral-gt-rs/blob/main/spectral_gt_car.py  
Source license: https://github.com/JaronKBragg7337/spectral-gt-rs/blob/main/LICENSE  
Maintainer's technical handoff: https://github.com/JaronKBragg7337/spectral-gt-rs/blob/main/REALTIME.md

## Why this asset, and what is actually established

The project's author explicitly dedicates its **original** vehicle model, source scripts and renders to CC0 1.0. It is a fictitious sports car, **not** a verified production Toyota, Civic or other licensed OEM. It can be a **development validation car** without pretending to supply NFSU2 assets or unauthorized models.

Author's published facts:
- A real exported glTF 2.0 / GLB file, approximately **4.7 MB**; 3D geometry with **263 independent objects**, of which **59** represent mechanical detail.
- Distinct body panels, wheels/brakes, engine forms, cockpit/interior, windows, material classes, lights.
- Authored at **meter scale**, vehicle nose faces **+X** (must map to Godot coordinate conventions).
- Four real animation clips: \`Doors_PingPong\`, \`Doors_PingPong.001\`, \`Hood_Service_PingPong\`, \`Steering_Input_PingPong\`.
- The source scene includes editable Blender model and generator for further legitimate modification.
- Importing a GLB does NOT automatically implement correct suspension, a trunk opening pivot, an audio box, multiplayer or vehicle handling.

## Executable audit

Workflow: [cityzero-real-car-reference.yml](../../.github/workflows/cityzero-real-car-reference.yml)

This workflow:
1. Downloads the author-published original CC0 GLB directly into an **ephemeral** GitHub runner. No NFSU2 files involved.
2. Verifies its \`glTF\` magic, minimum file size and SHA256.
3. Runs [cityzero_vehicle_inventory.py](../../tools/cityzero_vehicle_inventory.py) against the actual GLB's node tree and geometry metadata. Reports material count and node/triangle inventory.
4. Imports it with **Godot 4.6.1**, runs a [real-model screenshot smoke script](../vehicle_runtime/test_cc0_model.gd) under an Xvfb software GL display.
5. Uploads actual audit, logs and rendered PNG as a GitHub Actions artifact **if produced**.

Evidence policy: a committed workflow is not proof it successfully ran. Do not call the PNG real until the Actions artifact exists and its image has been inspected. Once a capture exists, compare its car silhouette to the actual source model, including a 360° rotation and inspection for clipping.

## Mapping to our modular system

Code: [CityZeroModularVehicle.gd](../vehicle_runtime/CityZeroModularVehicle.gd)

- Use separate Blender-authored Node3D pivots for hood, trunk, and left/right doors (the reference car has door and hood animations, not a confirmed separate animated trunk).
- Keep Blender's source animation clips if they already work; adapt their output to the typed hinge state interface.
- Speaker sockets \`MARKER_AUDIO_COMP_0 ... MARKER_AUDIO_COMP_11\` are authoring conventions learned from NFSU2, not alleged mesh objects already in the CC0 GLB.
- Build our own compatible trunk insert and speaker boxes using properly licensed meshes.
- When geometry is missing, label it missing rather than faking an installed production option.

## Commercial safeguards

The **CC0 file** and repository's authored model are licensed independently of original Need for Speed; any trademark/patent/publicity rights remain separate. NFSU2's proprietary car geometry and music **cannot** simply be included in City Zero. Other random GitHub repositories may have permissive code licenses but their downloaded auto-maker meshes may be unlicensed: inspect provenance per asset before including it.
