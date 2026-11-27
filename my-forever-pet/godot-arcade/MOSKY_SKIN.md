# Editable Mosky skin — first phase

One live companion remains enabled. To replace its artwork without modifying gameplay,
put a transparent PNG at `res://assets/mosky/sprites.png` (480 × 384 (eight directions; legacy 480 × 192 still supported) pixels).
Each cell is exactly 48 × 48 pixels. Keep the same ground anchor, use nearest filtering,
and do not add padding or margins.

Rows, top to bottom: front/down, rear/up, left, right.

Columns, left to right: idle, walk 1, walk 2, walk 3, walk 4,
attack 1, attack 2, blink, sleep, eat.

The Godot export script produces the current editable atlas in CI. The PNG is optional:
if absent, the built-in original pixel art is used. The same file supplies home portraits,
wallpaper, adventure animations and Pet Dash rear frames. The current roster and save
system remain single-companion; future species activation is a separate change.

Diagonal rows appended: southeast, southwest, northeast, northwest. Each row uses the original ten pose columns.

## Ponoko combat preview
The optional 672 × 384 combat atlas keeps the first ten columns unchanged and appends hurt, recover, defeat, cast. Original 480-pixel-wide sheets remain valid. Four diagonal rows are separately drawn from cardinal rows; left/right variants reflect the three-quarter drawing. The new pass does not change the existing cardinal art, enemies, saved IDs or wallpaper paths. Defeat is an available atlas pose, not a new death system.
