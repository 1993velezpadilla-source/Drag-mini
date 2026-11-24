"""Independent source audit; complements engine-level gauntlet.gd tests.
Run: python3 tools/adversarial_audit.py
"""
from pathlib import Path
import sys
R = Path(__file__).resolve().parents[1]
world = (R/'scripts/city_zero.gd').read_text()
state = (R/'scripts/game_state.gd').read_text()
mobile = (R/'scripts/mobile_input.gd').read_text()
blender = (R/'tools/build_assets_blender.py').read_text()
problems = []

def check(ok: bool, title: str):
    print(('PASS' if ok else 'FAIL') + ' | ' + title)
    if not ok:
        problems.append(title)

check((R/'project.godot').is_file(), 'Godot native project')
check((R/'scenes/main.tscn').is_file(), 'Native 3D launch scene')
check('extends Node3D' in world, '3D world—not 2D sprites or HTML')
check('CharacterBody3D' in world and 'move_and_slide()' in world, 'Collision-aware third-person player')
check('Camera3D' in world and 'look_at(desired)' in world, 'Orbit camera follows avatar')
check('InputEventScreenTouch' in mobile and 'InputEventScreenDrag' in mobile, 'Touchscreen movement/look')
check('MultiMeshInstance3D' in world, 'Batched building windows / draw-call optimization')
check('BEAT:' in world and 'publish_track(BEAT)' in world, 'Playable beat interaction')
check('if coins < cost' in state and 'if stage_built or coins < 200 or fans < 50:' in state, 'Shop/stage never incur debt')
check('MAX_OFFLINE_SECONDS := 8 * 3600' in state, 'Offline business exploit capped')
check('JSON.parse_string' in state and 'FileAccess.open' in state, 'Persistent local save')
check('export_scene.gltf' in blender and 'save_as_mainfile' in blender, 'Blender-generated editable 3D assets')
check('android' in (R/'export_presets.cfg').read_text().lower(), 'Android export preset exists')
check('window/handheld/orientation=6' in (R/'project.godot').read_text(), 'Mobile orientation specified')
check(not any(p.suffix.lower() == '.html' for p in R.rglob('*')), 'No HTML game')
print(f'{len(problems)} failures among 15 audit checks')
sys.exit(1 if problems else 0)
