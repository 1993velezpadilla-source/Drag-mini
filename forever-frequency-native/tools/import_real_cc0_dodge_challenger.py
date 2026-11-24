"""Convert real artist-authored CC0 1970 Dodge Challenger R/T from O3DE FBX.

Upstream: https://github.com/pawelbudziszewski/o3de-sample-vehicle-assets
Original author: https://blendswap.com/blend/4046 (CC0).
No procedural car, AI imagery or unauthorized commercial game rip.
Save real source-based GLB, editable Blender master, 4 actual screenshots,
and fail closed if source parts / material / geometry are missing.
"""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'assets'/'licensed_cc0_challenger_source'
OUT=ROOT/'assets'/'licensed_cc0_automobiles'
PROOF=ROOT/'real_cc0_challenger_blender_proof'
OUT.mkdir(parents=True,exist_ok=True)
PROOF.mkdir(parents=True,exist_ok=True)
BASENAME='dodge_challenger_1970_rt_original_cc0'
body_path=SRC/'dodge-challenger-1970-r-t_body.fbx'
wheel_path=SRC/'dodge-challenger-1970-r-t_wheel.fbx'
steer_path=SRC/'dodge-challenger-1970-r-t_steering_wheel.fbx'
prefab_path=SRC/'Dodge_Challenger_1970_RT.prefab'
for path in (body_path,wheel_path,steer_path,prefab_path):
    if not path.is_file() or path.stat().st_size<100000:
        raise RuntimeError('Missing genuine source CC0 component '+str(path))
bpy.ops.wm.read_factory_settings(use_empty=True)
def do_import(path):
    previous=set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(path))
    new=[o for o in bpy.data.objects if o not in previous]
    meshes=[o for o in new if o.type=='MESH']
    if not meshes:raise RuntimeError('Source FBX has no actual mesh: '+str(path))
    return meshes,new
body_meshes,_=do_import(body_path)
if len(body_meshes)<1:raise RuntimeError('Authentic Dodge FBX body mesh not found')
body_tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in body_meshes)
if body_tris<25000:raise RuntimeError('Not sufficient real Dodge body detail '+str(body_tris))

# Exact imported source-body geometry establishes the chassis' real Z floor.
# O3DE prefab wheel transforms are in vehicle-native coordinates while FBX
# import can apply a different up-axis/bind transform. Their raw 1.101m Z
# values CANNOT be treated as final Blender world-wheel heights.
def source_world_bounds(objects):
    corners=[obj.matrix_world@Vector(corner) for obj in objects for corner in obj.bound_box]
    return ([min(p[i] for p in corners) for i in range(3)],
            [max(p[i] for p in corners) for i in range(3)])

body_low,body_high=source_world_bounds(body_meshes)
body_height=body_high[2]-body_low[2]
if not .8<body_height<5.0:
    raise RuntimeError('Unexpected original source body vertical bounds '+str((body_low,body_high)))


# Bring one genuine tire/wheel FBX at each of the four exact engine prefab
# anchor transforms. No guessed wheelbase/tire sizes/proportions whatsoever.
prefab=json.loads(prefab_path.read_text())
anchors={}
for entity in prefab.get('Entities',{}).values():
    if entity.get('Name','') not in ('Wheel FL','Wheel FR','Wheel RL','Wheel RR'):
        continue
    translation=entity.get('Components',{}).get('TransformComponent',{}).get('Transform Data',{}).get('Translate')
    if not isinstance(translation,list) or len(translation)!=3:
        raise RuntimeError('Missing real O3DE wheel transform: '+str(entity.get('Name')))
    anchors[entity['Name']]=translation
if len(anchors)!=4:raise RuntimeError('Not all four genuine CC0 wheel anchors in source prefab')
wheel_report={}
for name,pos in anchors.items():
    wheels,all_objects=do_import(wheel_path)
    if not wheels:raise RuntimeError('Authored wheel FBX empty')
    # Preserve genuine FBX object positions as offsets; move their group to
    # actual O3DE source wheel anchors, using the original prefab axes.
    bpy.ops.object.empty_add(type='PLAIN_AXES',location=pos)
    holder=bpy.context.object
    holder.name='REAL_SOURCE_'+name.replace(' ','_')+'_PIVOT'
    for o in all_objects:
        if o==holder or o.parent is not None:continue
        original=o.matrix_world.copy()
        o.parent=holder
        o.matrix_world=holder.matrix_world @ original
    # Align tire centers to the actual CC0 BODY bottom, using ORIGINAL
    # imported tire radius. Never move the body or invent tire geometry.
    # This corrects the prior wheels-floating-over-roof artifact in the
    # four original photos and native Godot screenshot.
    bpy.context.view_layer.update()
    wheel_low,wheel_high=source_world_bounds(wheels)
    tire_radius_z=(wheel_high[2]-wheel_low[2])*0.5
    if not .15<tire_radius_z<1.0:
        raise RuntimeError('Real original tire Z radius implausible '+name+': '+str(tire_radius_z))
    before_center_z=(wheel_low[2]+wheel_high[2])*0.5
    ground_clearance=max(.008,body_height*.01)
    true_center_z=body_low[2]+tire_radius_z+ground_clearance
    holder.location.z+=true_center_z-before_center_z
    bpy.context.view_layer.update()
    corrected_low,corrected_high=source_world_bounds(wheels)
    new_center_z=(corrected_low[2]+corrected_high[2])*0.5
    if abs(new_center_z-true_center_z)>.012:
        raise RuntimeError('Original CC0 wheel Z calibration did not apply '+name)
    if new_center_z>=body_high[2]-tire_radius_z*.10:
        raise RuntimeError('Unacceptable source wheel above the roof '+name)
    wheel_report[name]={
        'source_anchor_o3de':pos, 'mesh_count':len(wheels),
        'source_tire_radius_z_m':round(tire_radius_z,5),
        'before_calibration_center_z_m':round(before_center_z,5),
        'after_calibration_center_z_m':round(new_center_z,5),
        'original_source_body_low_z_m':round(body_low[2],5),
        'original_source_body_high_z_m':round(body_high[2],5),
        'corrected_vertical_offset_m':round(true_center_z-before_center_z,5),
        'wheel_below_original_roof_verified':True
    }
steer_meshes,_=do_import(steer_path)
all_meshes=[o for o in bpy.data.objects if o.type=='MESH']
tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in all_meshes)
if tris<body_tris+500:
    raise RuntimeError('Original authored wheels/interior not imported')

# Repair broken FBX references by exact original texture basename where
# physically present. Do not fabricate texture files or material properties.
tex_dir=SRC/'textures'
fixed_images=0
for image in bpy.data.images:
    # FBX authored on Windows: normalize backslashes BEFORE Path(...).
    src_name=Path(bpy.path.abspath(image.filepath).replace('\\','/')).name
    matches=list(tex_dir.rglob(src_name)) if tex_dir.exists() else []
    if matches:
        image.filepath=str(matches[0])
        try:image.reload()
        except Exception:continue
        fixed_images+=1

# Save source Blender master. PBR material finish and wheel orientation must
# be reviewed before this is considered a game-ready/sellable City Zero car.
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(BASENAME+'.blend')))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(OUT/(BASENAME+'.glb')),
    export_format='GLB',use_selection=True,export_materials='EXPORT')
glb=OUT/(BASENAME+'.glb')
if glb.stat().st_size<300000:raise RuntimeError('Empty converted source GLB')

# Native Blender Workbench proof: actual imported FBX -> Blender scene.
scene=bpy.context.scene
scene.render.engine='BLENDER_WORKBENCH'
scene.display.shading.color_type='MATERIAL'
scene.display.shading.light='STUDIO'
scene.display.shading.show_shadows=True
scene.display.shading.show_cavity=True
scene.render.resolution_x=1200
scene.render.resolution_y=800
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
points=[o.matrix_world@Vector(c) for o in all_meshes for c in o.bound_box]
low=Vector([min(p[i] for p in points) for i in range(3)])
high=Vector([max(p[i] for p in points) for i in range(3)])
center=(low+high)*.5
size=max(high-low)
camdata=bpy.data.cameras.new('CC0_CHALLENGER_REAL_REFERENCE_CAMERA')
camdata.type='ORTHO'
camdata.ortho_scale=size*1.4
cam=bpy.data.objects.new('CC0_CHALLENGER_REAL_REFERENCE_CAMERA',camdata)
scene.collection.objects.link(cam)
scene.camera=cam
for view,d in {
    'side':(0,-2.0,.35),
    'front':(-2.0,0,.45),
    'rear':(2.0,0,.45),
    'three_quarter':(-1.35,-1.5,.68)}.items():
    cam.location=center+Vector(d)*size
    cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
    file=PROOF/(BASENAME+'-'+view+'.png')
    scene.render.filepath=str(file)
    bpy.ops.render.render(write_still=True)
    if file.stat().st_size<25000:raise RuntimeError('Missing true source car photo '+str(file))
metrics={'model_id':BASENAME,'original_source_license':'CC0 per BlendSwap model 4046',
    'original_source':'https://blendswap.com/blend/4046',
    'upstream':'https://github.com/pawelbudziszewski/o3de-sample-vehicle-assets',
    'body_source_triangles':body_tris,'assembled_source_triangles':tris,
    'source_body_mesh_count':len(body_meshes),'all_rendered_meshes':len(all_meshes),
    'wheels':wheel_report,'recovered_original_image_paths':fixed_images,
    'original_source_bounds_m':[round(float(v),4) for v in high-low],
    'wheel_height_visual_defect_corrected_from_source_geometry':True,
    'real_sourced_blender_gltf_file':glb.name,
    'status':'GENUINE_CC0_SOURCE_IMPORTED_PENDING_HUMAN_VISUAL_MATERIAL_AND_ANDROID_LOD_QA',
    'game_ready':False}
(PROOF/'original_cc0_import_report.json').write_text(json.dumps(metrics,indent=2)+'\n')
print('GENUINE CC0 DODGE CHALLENGER SOURCE BLENDER FOUR VIEW GATE COMPLETE',metrics,flush=True)
