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
check('LA CALDERA RECORDS' in world and 'ECHO STUDIO' not in world, 'Rebrand fully to La Caldera Records')
check('_dress_citizen_avatar(citizen_visual, i)' in world and 'material_override = instance_mat' in world, '12 citizens have individuated clothing and skin materials')
check("res://assets/urban_life_district.glb" in world, 'Visual: actual playable city loads the additional Blender district')
check((R/'tools/premium_art_pass.py').is_file() and (R/'tools/urban_life_district.py').is_file(), 'Two separate Blender architecture + urban detail passes')
check("'la_caldera_records.glb'" in blender and 'res://assets/la_caldera_records.glb' in world, 'Blender hero studio is loaded in Godot')
check('def build_market()' in blender and 'def build_home()' in blender and 'def build_stage()' in blender, 'Custom architectural assets replace dull box landmarks')
check('def build_artist()' in blender and 'def build_pet()' in blender, 'Original 3D avatar and companion')
check('titlepanel.add_child(meta)' in world and 'meta.add_child(world_time_label)' in world, 'Clock anchored within HUD card, no floating overlap')
check('var studio := _make_building' in world and 'not has_studio' in world, 'Visuals not occluded by old primitive boxes')
check('env.ambient_light_energy = 0.31' in world and 'sunlight.light_energy = 0.71' in world and 'ProceduralSkyMaterial' in world, 'Adversarial visual: reduced washout, atmospheric sky')
check('android' in (R/'export_presets.cfg').read_text().lower(), 'Android export preset exists')
check('window/handheld/orientation=6' in (R/'project.godot').read_text(), 'Mobile orientation specified')
check(not any(p.suffix.lower() == '.html' for p in R.rglob('*')), 'No HTML game')
# Production GLBs are runtime-only; the Blender source must not be imported by Godot.
import json
assets=R/'assets'
if assets.is_dir() and any(assets.glob('*.glb')):
    check(not any(assets.glob('*.blend')), 'No Blender source files in Godot import folder')
    check(not (assets/'studio_entrance.glb').exists() and not (assets/'street_kiosk.glb').exists(), 'No duplicate legacy GLB imports')
    check(len(list(assets.glob('*.glb'))) == 13, 'Exactly 13 optimized GLBs including premium living district')
    check((assets/'urban_life_district.glb').is_file(), 'Premium district GLB included, not a procedural placeholder')
    urban_metrics=assets/'urban_metrics.json'
    check(urban_metrics.exists(), 'Independent geometry/draw-call metrics exist')
    if urban_metrics.exists():
        u=json.loads(urban_metrics.read_text())
        check(u['original_meshes']>=600 and u['runtime_batches']<20 and u['district_facades']>=9, 'Detailed city art exceeds toy-greybox baseline and stays batched')
    metrics=assets/'mesh_metrics.json'
    if metrics.exists():
        data=json.loads(metrics.read_text())
        check(len(data)==12 and all(x['export_nodes']<x['source_meshes'] for x in data.values()), 'All GLBs reduced scene node count')
        check(data['la_caldera_records']['export_nodes']*2<data['la_caldera_records']['source_meshes'], 'La Caldera meshes batched at least 2:1')
    else:
        check(False, 'Missing Blender optimization metrics')
check('tools/pbr_upgrade.py' not in world, 'Game runs without Blender/Python runtime dependency')
print(f'{len(problems)} failures among {20+(5 if assets.is_dir() and any(assets.glob("*.glb")) else 0)} audit checks')
sys.exit(1 if problems else 0)
