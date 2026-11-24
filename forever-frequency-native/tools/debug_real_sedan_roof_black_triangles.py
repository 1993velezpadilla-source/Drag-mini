"""Forensic REAL Blender scene-isolation frames for sedan ragged upper door rims.

Input is the production polished GLB-derived .blend, not AI or placeholder.
We don't 'fix' anything in the diagnostic: isolate exactly which original
mesh makes the black zig-zag canopy artifact in GLB Viewer screenshots.
"""
import bpy, json
from mathutils import Vector
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets'/'curated_rigged_polished'/'curated_family_sedan.blend'
OUT=ROOT/'real_sedan_roof_forensics'
OUT.mkdir(exist_ok=True)
if not SOURCE.exists():
    raise RuntimeError('Missing genuine polished sedan Blender source: '+str(SOURCE))
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
real_meshes=[o for o in bpy.data.objects if o.type=='MESH']
assert len(real_meshes)>45
assert all(not o.name.startswith('Cube') for o in real_meshes)
scene=bpy.context.scene
scene.render.engine='BLENDER_WORKBENCH'
scene.display.shading.light='STUDIO'
scene.display.shading.color_type='MATERIAL'
scene.display.shading.show_shadows=True
scene.display.shading.show_cavity=True
scene.display.shading.background_type='WORLD'
scene.render.resolution_x=1500
scene.render.resolution_y=900
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'

camera_data=bpy.data.cameras.new('ACTUAL_CAR_BROKEN_ROOF_INSPECT_CAMERA')
camera_data.type='ORTHO'
camera_data.ortho_scale=3.85
camera=bpy.data.objects.new('ACTUAL_CAR_BROKEN_ROOF_INSPECT_CAMERA',camera_data)
scene.collection.objects.link(camera)
scene.camera=camera

# No hiding source assets during shipment. Hide_render is only used for
# controlled paired diagnostic images and reset after every screenshot.
objects={o.name:o for o in real_meshes}
tests={
 'full_original_actual_car':[],
 'without_pillar_lining':['pillar_lining'],
 'without_fixed_upper_rail':['window_trim_L','window_trim_R'],
 'without_moving_upper_window_frames':[n for n in objects if n.startswith('door_') and '_glass_side_' in n],
 'without_rear_glass_surround':['glass_rear','glass_side_L','glass_side_R'],
 'without_pillar_and_rail':['pillar_lining','window_trim_L','window_trim_R']
}
evidence=[]
for case,hide in tests.items():
    for o in real_meshes:
        o.hide_render=any(o.name==n for n in hide)
    bpy.context.view_layer.update()
    # Camera X positive = one exterior side, Y is longitudinal. Center upper
    # side windows at about y=-.25 in original Blender Z-up coordinates.
    target=Vector((0,-.19,1.14))
    camera.location=target+Vector((5.9,-1.15,1.68))
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    outfile=OUT/(case+'.png')
    scene.render.filepath=str(outfile)
    bpy.ops.render.render(write_still=True)
    assert outfile.stat().st_size>20000,(outfile,outfile.stat().st_size)
    evidence.append({'case':case,'hidden_actual_meshes':hide,'path':outfile.name,
                     'file_bytes':outfile.stat().st_size})
    print('GENUINE BLENDER ROOF FORENSIC',case,hide,outfile,flush=True)
for o in real_meshes:o.hide_render=False
bpy.context.view_layer.update()
(OUT/'roof_triangle_isolation_report.json').write_text(json.dumps(evidence,indent=2)+'\n')
assert len(evidence)==6
print('REAL SEDAN ROOF TRIANGLE SOURCE DIAGNOSTIC SIX FRAMES COMPLETE',flush=True)
