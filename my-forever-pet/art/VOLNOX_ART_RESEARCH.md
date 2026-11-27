# Volnox pixel-art pipeline research and production gates
User review: Coralcrab front claws must be in the foreground; side views must show the full creature turned. Every species must have its own silhouette, personality and anatomically plausible locomotion. Actual runtime character art stays 2D, nearest-neighbor, within existing 3D terrain.
## Investigated upstream tools (not installed)
- https://github.com/Orama-Interactive/Pixelorama — Godot-based frame/layer editor.
- https://github.com/LibreSprite/LibreSprite — open-source sprite editor and animation workflow.
- https://github.com/arqsbo3d/spriteforge — Blender multi-view sprite export; reference only, not runtime 3D characters.
- https://github.com/AlienPolygon/pribambase — Aseprite/Blender texture sync; requires compatible editors.
- https://github.com/alanfrigo/pixel-studio — AI-assisted sprite studio with external provider requirements. Review license, credentials, costs and output quality before use.
- https://github.com/skulitom/Pixelbolt — editable recipes and sprite exports, evaluate on isolated sample.
- https://docs.godotengine.org/en/stable/classes/class_sprite3d.html — 2D sprites in 3D scenes.
## Review gate
Each species: independent silhouette in all four views; direction changes must transform claws, limbs, tail, armor and eyes together. Compare front/back/side at native resolution. Verify alpha, anchor, and frame-to-frame anatomical change. Do not count a tint or flattening as an attack or defeat animation. Shader lighting cannot repair an incorrect silhouette. Keep external art replaceable, separate attack VFX, no universal hop. Do not claim the remaining 30 are complete.
