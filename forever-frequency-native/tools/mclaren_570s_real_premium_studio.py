"""One-car City Zero quality pass: original artist-authored McLaren 570S GLB.

No procedural bodywork, fake meshes, AI imagery or car impostors.
Licensed creator source verified with SHA; repaint original real PBR materials,
preserve ALL source geometry, save editable .blend and five CLOSE native Cycles
angles. Not user art-approved; mechanical body panel work is a later gate.
"""
import bpy, hashlib, json
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"assets/tevy_cc0_blender_vehicles/mclaren_570s_2016_real_import.glb"
OUT=ROOT/"mclaren_570s_visual_quality_review"
OUT.mkdir(parents=True,exist_ok=True)
HASH="61a9b74c50be614d38121df8e7166462452bb95f4371215202c7658e87568639"
ORIGIN="abe0311a1c9653d1259d5fa8568407424d5da2ebca21194709e55f6877589c23"
GOLD="45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7"
if not SRC.is_file() or hashlib.sha256(SRC.read_bytes()).hexdigest()!=HASH:
    raise RuntimeError("McLaren REAL original artist-authored source hash missing or modified")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SRC))
artist_objects=list(bpy.data.objects)
meshes=[o for o in artist_objects if o.type=="MESH"]
tris=sum(len(poly.vertices)-2 for o in meshes for poly in o.data.polygons)
if tris!=57933 or len(meshes)<78:
    raise RuntimeError("McLaren actual 57,933-triangle artist geometry not intact "+str((tris,len(meshes))))
materials={m.name for o in meshes for m in o.data.materials if m}
if len(materials)<38:raise RuntimeError("Original McLaren interior, wheel, paint and glazing materials missing")
raw_bounds=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
lo=Vector(min(v[i] for v in raw_bounds) for i in range(3))
hi=Vector(max(v[i] for v in raw_bounds) for i in range(3))
size=hi-lo
span=max(size)
mid=(lo+hi)*.5
if not 4.48<span<4.58 or not 1.9<size.x<2.3 or not 1.0<size.z<1.4:
    raise RuntimeError("Artist McLaren true physical size/stance wrong "+str(tuple(size)))

# Work exclusively on existing original PBR materials, not vertex positions.
changes={}
for m in bpy.data.materials:
    if not m.name:continue
    m.use_nodes=True
    p=m.node_tree.nodes.get("Principled BSDF")
    if p is None:continue
    n=m.name.casefold()
    if n.startswith("fullm_carpaint_max"):
        p.inputs["Base Color"].default_value=(.015,.082,.34,1.0)
        p.inputs["Metallic"].default_value=.66
        p.inputs["Roughness"].default_value=.19
        if p.inputs.get("Coat Weight") is not None:
            p.inputs["Coat Weight"].default_value=.58
        if p.inputs.get("Coat Roughness") is not None:
            p.inputs["Coat Roughness"].default_value=.105
        m.diffuse_color=(.015,.082,.34,1.0)
        changes[m.name]="source original exterior: deep cobalt luxury metallic clear coat"
    elif "rim_main" in n or "rim_secondary" in n:
        p.inputs["Base Color"].default_value=(.066,.078,.094,1.0)
        p.inputs["Metallic"].default_value=.78
        p.inputs["Roughness"].default_value=.24
        m.diffuse_color=(.066,.078,.094,1.0)
        changes[m.name]="original forged alloy wheel surfaces: dark graphite"
    elif "carbon" in n or "plasticroughblack" in n:
        p.inputs["Roughness"].default_value=.29
        if "carbon" in n:p.inputs["Metallic"].default_value=.12
        changes[m.name]="original carbon/aero trim physical shader, geometry preserved"
    elif "glass_windowfront" in n or n=="black_glass":
        p.inputs["Base Color"].default_value=(.11,.18,.23,1.0)
        p.inputs["Roughness"].default_value=.085
        p.inputs["Metallic"].default_value=.02
        if p.inputs.get("Transmission Weight") is not None:
            p.inputs["Transmission Weight"].default_value=.50
        m.diffuse_color=(.11,.18,.23,1.0)
        changes[m.name]="original glass shader restored, source UVs retained"
    elif "chrome" in n or "satin" in n:
        p.inputs["Metallic"].default_value=.78
        p.inputs["Roughness"].default_value=.24
        changes[m.name]="original stainless trim physical reflectance"
if not any(k.startswith("fullM_CarPaint_Max") for k in changes):
    raise RuntimeError("No authentic source car paint material was actually changed")
if not any("Rim_Main" in k for k in changes):
    raise RuntimeError("Actual McLaren wheel source must be darkened, not invented")
if not any("WindowFront" in k for k in changes):
    raise RuntimeError("Source windshield must retain glass PBR")

# 100% original geometry exported first; NEVER append fake physical components.
bpy.ops.object.select_all(action="DESELECT")
for obj in artist_objects:obj.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
car=OUT/"mclaren_570s_2016_ORIGINAL_Author_DeepBlue_PBR.glb"
bpy.ops.export_scene.gltf(filepath=str(car),export_format="GLB",use_selection=True)
if car.stat().st_size<3500000:raise RuntimeError("GLB lost original PBR mesh/materials")
blend=OUT/"mclaren_570s_2016_original_artist_EDITABLE_PBR.blend"
bpy.ops.wm.save_as_mainfile(filepath=str(blend))
if blend.stat().st_size<5000000:raise RuntimeError("Editable real artist Blender source incomplete")
if sum(len(poly.vertices)-2 for o in meshes for poly in o.data.polygons)!=tris:
    raise RuntimeError("Source geometry was replaced or lost during material restoration")

scene=bpy.context.scene
scene.render.engine="CYCLES"
scene.cycles.samples=20
bpy.context.view_layer.cycles.use_denoising=True
scene.render.resolution_x=1400
scene.render.resolution_y=900
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.view_settings.view_transform="AgX"
scene.view_settings.look="AgX - Medium High Contrast"
world=bpy.data.worlds.new("CITYZERO_SILVER_DAYLIGHT_NEUTRAL_STUDIO")
world.use_nodes=True
world.node_tree.nodes["Background"].inputs["Color"].default_value=(.65,.72,.81,1.0)
world.node_tree.nodes["Background"].inputs["Strength"].default_value=.90
scene.world=world
bpy.ops.mesh.primitive_plane_add(size=120,location=(0,0,lo.z-.05))
floor=bpy.context.object
floor.name="REAL_CYCLES_REVIEW_NEUTRAL_STAGE_NOT_EXPORTED"
mat=bpy.data.materials.new("QUALITY_PHOTOGRAPHY_ONLY_FLOOR")
mat.use_nodes=True
mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(.34,.38,.42,1.0)
mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value=.81
floor.data.materials.append(mat)
for title,offset,power,radius in [
    ("REAL_SOURCE_CAR_KEY",(.9,-.8,1.12),1850,5.5),
    ("REAL_SOURCE_CAR_FILL",(-1.1,.55,.76),1100,5.0),
    ("REAL_SOURCE_CAR_RIM",(.35,1.40,.92),1700,3.5)]:
    data=bpy.data.lights.new(title,"AREA")
    data.energy=power
    data.shape="DISK"
    data.size=radius
    obj=bpy.data.objects.new(title,data)
    scene.collection.objects.link(obj)
    obj.location=mid+Vector(offset)*span
    obj.rotation_euler=(mid-obj.location).to_track_quat("-Z","Y").to_euler()

cam_data=bpy.data.cameras.new("EXACT_MC_LAREN_SOURCE_75_PERCENT_FRAME")
cam_data.type="ORTHO"
camera=bpy.data.objects.new("EXACT_MC_LAREN_SOURCE_75_PERCENT_FRAME",cam_data)
scene.collection.objects.link(camera)
scene.camera=camera
angles={
 "01_front_three_quarter":(1.17,-1.45,.47),
 "02_full_side":(1.9,0,.22),
 "03_real_front":(0,-1.9,.23),
 "04_real_rear":(0,1.9,.23),
 "05_rear_three_quarter":(1.17,1.45,.47),
}
images=[]
for title,direction in angles.items():
    camera.location=mid+Vector(direction)*span
    camera.rotation_euler=(mid-camera.location).to_track_quat("-Z","Y").to_euler()
    cam_data.ortho_scale=span*1.55
    bpy.context.view_layer.update()
    def projected():
        pts=[world_to_camera_view(scene,camera,obj.matrix_world@Vector(v))
             for obj in meshes for v in obj.bound_box]
        return (min(p.x for p in pts),max(p.x for p in pts),
                min(p.y for p in pts),max(p.y for p in pts))
    a,b,c,d=projected()
    factor=max((b-a)/.76,(d-c)/.73)
    if not .01<factor<6:raise RuntimeError("Original car camera project failed "+title)
    cam_data.ortho_scale*=factor
    bpy.context.view_layer.update()
    a,b,c,d=projected()
    if min(a,c)<.01 or max(b,d)>.99 or b-a<.49 or max(b-a,d-c)<.71:
        raise RuntimeError("McLaren too small, clipped or badly framed "+title+" "+str((a,b,c,d)))
    png=OUT/(title+"_ACTUAL_CYCLES_McLaren570S_PBR.png")
    scene.render.filepath=str(png)
    bpy.ops.render.render(write_still=True)
    if png.stat().st_size<50000:raise RuntimeError("Actual Blender Cycles frame missing "+title)
    images.append({"view":title,"filename":png.name,"fraction_of_image_width":round(b-a,4),
                   "fraction_of_image_height":round(d-c,4)})
    print("CITYZERO_REAL_MCLAREN_SOURCE_CLOSEUP_BLENDER_CYCLES",title,flush=True)
report={
 "source":"REAL McLaren 570S by Ddiaz Design (third-party CC BY 4.0 notice)",
 "source_sha256":HASH, "author_original_source_sha256":ORIGIN,
 "owner_approved_orange_lamborghini_sha256":GOLD,
 "source_original_triangles":tris,"after_pbr_triangles":tris,
 "original_mesh_objects":len(meshes),"original_materials":len(materials),
 "physical_bounds_m":list(map(float,size)),
 "source_geometry_replaced":False,
 "source_has_genuine_hinged_doors":False,
 "original_mesh_UVs_preserved":True,
 "visual_reference_frames":images,
 "original_shaders_changed":changes,
 "owner_art_approved":False,"commercial_rights_review_pending":True,
 "android_runtime_included":False,
 "status":"NATIVE_PBR_ARTIST_MCLAREN_570S_5_REAL_BLENDER_VIEWS__HUMAN_ART_QA_PENDING"
}
(OUT/"mclaren_real_materials_geometry_visual_forensic_report.json").write_text(json.dumps(report,indent=2)+"\n")
print("CITYZERO_MCLAREN570S_REAL_AUTHOR_SOURCE_PBR_FIVE_CLOSEUP_BLENDER_GREEN_NO_ART_APPROVAL",flush=True)
