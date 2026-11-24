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
# SOURCE-PRIMITIVE TEST: Body is a multi-material glTF source mesh.
# This separation happens ONLY in a disposable forensic scene.
body=bpy.data.objects.get('body')
if body is None or body.type!='MESH':raise RuntimeError("Source sedan body missing")
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
bpy.context.view_layer.objects.active=body
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.separate(type='MATERIAL')
bpy.ops.object.mode_set(mode='OBJECT')
body_parts={}
for obj in bpy.data.objects:
    if obj.type!='MESH' or not (obj.name=='body' or obj.name.startswith('body.')):
        continue
    if not obj.data.polygons:continue
    idx=obj.data.polygons[0].material_index
    if idx>=len(obj.data.materials):continue
    mat=obj.data.materials[idx]
    if mat:body_parts.setdefault(mat.name,[]).append(obj)
print('SOURCE BODY MATERIAL PRIMITIVES', {k:[o.name for o in v] for k,v in body_parts.items()},flush=True)
for label,kind in (
        ('hide_body_panel_gap_material','panel_gap'),
        ('hide_body_trim_gloss_material','trim_gloss'),
        ('hide_body_paint_material','paint_body'),
        ('hide_body_matte_material','trim_matte')):
    hidden=[obj for material,objs in body_parts.items()
            if material.startswith(kind) for obj in objs]
    if not hidden:raise RuntimeError("No sourced material "+kind)
    for obj in hidden:obj.hide_render=True
    bpy.context.view_layer.update()
    outfile=OUT/(label+'.png')
    scene.render.filepath=str(outfile)
    bpy.ops.render.render(write_still=True)
    assert outfile.stat().st_size>20000
    evidence.append({'case':label,'hidden_actual_meshes':[o.name for o in hidden],
                     'source_material':kind,'path':outfile.name,
                     'file_bytes':outfile.stat().st_size})
    for obj in hidden:obj.hide_render=False
(OUT/'roof_triangle_isolation_report.json').write_text(json.dumps(evidence,indent=2)+'\n')
assert len(evidence)==10
print('REAL SEDAN ROOF TRIANGLE SOURCE DIAGNOSTIC TEN FRAMES COMPLETE',flush=True)
