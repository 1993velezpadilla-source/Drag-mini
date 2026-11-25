"""City Zero: a real original artist 1975 Porsche 911/930 Turbo visual gauntlet.

Original 75-mesh/241260-triangle Blender export from SceneView (artist Karol
Miklas, CC BY 4.0) SHA-locked. Remove ONLY its disconnected 2-triangle showroom
floor, NOT a single source car face. Uniformly calibrate the genuine car's
source scale to the nominal 1975 930 length (4.291m), preserve true original
UVs/interior, and render five frame-filling 3D Cycles views. No AI imagery, no
procedural car stand-ins. No owner art approval without independent review.
"""
import bpy
import hashlib
import json
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT=Path(__file__).resolve().parents[1]
INPUT=ROOT/"assets/licensed_ccby_car_fleet/porsche_911_blender_import.glb"
OUT=ROOT/"porsche_930_original_gold_review"
OUT.mkdir(parents=True,exist_ok=True)
PINNED_IMPORT_SHA="c2f989537740772c3e7478f7d0f3349023406b828c48d05a1c83ff22c936074e"
ORIGINAL_ARTIST_SOURCE_SHA="e1d7de07dda7d42aa9d87da33af4d4b05ed344e9c0222d571dce19e3658436ac"
APPROVED_ORANGE_LAMBORGHINI_SHA="45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7"
REFERENCE_LENGTH_M=4.291
if not INPUT.is_file() or hashlib.sha256(INPUT.read_bytes()).hexdigest()!=PINNED_IMPORT_SHA:
    raise RuntimeError("Original Porsche 911 Turbo artist GLB not found, SHA identity changed")
if INPUT.stat().st_size!=20047848:
    raise RuntimeError("Original Porsche artist Blender GLB byte length changed")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(INPUT))
original_objects=list(bpy.data.objects)
meshes=[x for x in original_objects if x.type=="MESH"]
all_source_triangles=sum(sum(len(face.vertices)-2 for face in obj.data.polygons) for obj in meshes)
if len(meshes)!=75 or all_source_triangles!=241260:
    raise RuntimeError("The 75 artist mesh objects / 241260 original triangles changed "+str((len(meshes),all_source_triangles)))
original_material_names={m.name for obj in meshes for m in obj.data.materials if m is not None}
if len(original_material_names)<14:
    raise RuntimeError("Original artist paint/tire/sticker/glass PBR materials missing")

def bounds(objects):
    if not objects:raise RuntimeError("No real authored geometry to frame")
    points=[obj.matrix_world@Vector(v) for obj in objects for v in obj.bound_box]
    lo=Vector(min(p[i] for p in points) for i in range(3))
    hi=Vector(max(p[i] for p in points) for i in range(3))
    return lo,hi

# The archived Porsche source actually includes a detached original exhibition
# stand, just two triangles 6.233m long. Source car bodywork remains unchanged.
floor_candidates=[obj for obj in meshes
                  if len(obj.data.polygons)==2
                  and max(bounds([obj])[1]-bounds([obj])[0])>5.8]
if len(floor_candidates)!=1:
    raise RuntimeError("Expected exactly one original 2-face noncar studio display floor; reject if car topology differs")
source_floor=floor_candidates[0]
noncar_showroom_tris=sum(len(p.vertices)-2 for p in source_floor.data.polygons)
if noncar_showroom_tris!=2:
    raise RuntimeError("Do not remove arbitrary vehicle surface")
noncar_showroom_name=source_floor.name
real_car=[obj for obj in meshes if obj!=source_floor]
car_faces=sum(sum(len(face.vertices)-2 for face in o.data.polygons) for o in real_car)
if len(real_car)!=74 or car_faces!=241258:
    raise RuntimeError("Source Porsche car panels lost (only 2-face noncar stand may be excluded)")
before_lo,before_hi=bounds(real_car)
source_original_dimensions=before_hi-before_lo
original_body_longitudinal_span=max(source_original_dimensions)
if not 4.7<original_body_longitudinal_span<5.1:
    raise RuntimeError("Original car excluding plinth unexpectedly malformed "+str(tuple(source_original_dimensions)))
scale=REFERENCE_LENGTH_M/original_body_longitudinal_span
if not .75<scale<1.05:
    raise RuntimeError("Invalid dimensional calibration factor for real source model")
# Apply uniform change to scene's original roots, including car mesh origin
# hierarchy (uniform only, no baking of original UVs/mesh vertices).
for ob in original_objects:
    if ob.parent is None:
        ob.scale*=scale
bpy.context.view_layer.update()
cal_lo,cal_hi=bounds(real_car)
cal_dims=cal_hi-cal_lo
if abs(max(cal_dims)-REFERENCE_LENGTH_M)>.035:
    raise RuntimeError("Porsche source calibrated length not preserved "+str(tuple(cal_dims)))
if not 1.7<cal_dims.x<2.15 or not 1.1<cal_dims.z<1.9:
    raise RuntimeError("Porsche width/height physically implausible "+str(tuple(cal_dims)))

# The removed showroom plane is NOT part of the car. Keep the original mesh
# in the editable provenance scene but hide it from render and export.
source_floor.hide_render=True
source_floor.hide_set(True)
real_mesh_names={o.name for o in real_car}

# Refinish real existing paint and glass only. Insert a color tint after
# texture node so every original artist bitmap/UV normal remains intact.
def tinted_material(mat,color,tint=.91):
    mat.use_nodes=True
    nodes=mat.node_tree.nodes
    shader=nodes.get("Principled BSDF")
    if shader is None:return False
    base=shader.inputs["Base Color"]
    if base.is_linked:
        links=mat.node_tree.links
        previous=base.links[0].from_socket
        links.remove(base.links[0])
        blend=nodes.new("ShaderNodeMixRGB")
        blend.blend_type="MULTIPLY"
        blend.inputs[0].default_value=tint
        blend.inputs[2].default_value=color
        links.new(previous,blend.inputs[1])
        links.new(blend.outputs[0],base)
    else:
        base.default_value=color
    mat.diffuse_color=color
    return True
material_changes={}
for mat in bpy.data.materials:
    m=mat.name.lower().split(".")[0]
    if m in {"paint","coat"}:
        tint=(.71,.017,.029,1.0)
        if not tinted_material(mat,tint):
            raise RuntimeError("Porsche vintage original paint shader inaccessible")
        p=mat.node_tree.nodes.get("Principled BSDF")
        p.inputs["Metallic"].default_value=.36
        p.inputs["Roughness"].default_value=.19
        if p.inputs.get("Coat Weight") is not None:p.inputs["Coat Weight"].default_value=.52
        if p.inputs.get("Coat Roughness") is not None:p.inputs["Coat Roughness"].default_value=.11
        material_changes[mat.name]="Real Porsche original paint texture retained with Guards Red PBR clearcoat"
    elif m=="glass":
        mat.use_nodes=True
        p=mat.node_tree.nodes.get("Principled BSDF")
        if p:
            p.inputs["Roughness"].default_value=.085
            p.inputs["Metallic"].default_value=.02
            if p.inputs.get("Transmission Weight") is not None:
                p.inputs["Transmission Weight"].default_value=.48
            material_changes[mat.name]="Original authored window meshes/glass PBR retained"
    elif m=="930_rim":
        if tinted_material(mat,(.16,.17,.18,1.0),.68):
            p=mat.node_tree.nodes.get("Principled BSDF")
            p.inputs["Metallic"].default_value=.77
            p.inputs["Roughness"].default_value=.26
            material_changes[mat.name]="Actual source forged Fuchs-style alloy finish"
    elif m=="930_chromes":
        mat.use_nodes=True
        p=mat.node_tree.nodes.get("Principled BSDF")
        if p:
            p.inputs["Metallic"].default_value=.81
            p.inputs["Roughness"].default_value=.24
            material_changes[mat.name]="Original source polished chrome trim"
if not any("paint" in k for k in material_changes) or "930_rim" not in material_changes:
    raise RuntimeError("No source-original Porsche body/wheel PBR shader restoration")
if car_faces!=sum(sum(len(f.vertices)-2 for f in o.data.polygons) for o in real_car):
    raise RuntimeError("Never alter artist's body polygons during PBR visual review")

# The exported GLB includes original authored car geometry only, not the
# oversized 2-triangle exhibition slab, camera, lights or invented bodywork.
bpy.ops.object.select_all(action="DESELECT")
for obj in original_objects:
    if obj==source_floor:continue
    obj.select_set(True)
bpy.context.view_layer.objects.active=real_car[0]
glb=OUT/"porsche_911_930_1975_SOURCE_REAL_Artist_ClassicRed_PBR.glb"
bpy.ops.export_scene.gltf(filepath=str(glb),export_format="GLB",use_selection=True)
if glb.stat().st_size<14000000:
    raise RuntimeError("Original artist Porsche 1975 model/UV images lost during export")
# Save editable original source BEFORE adding any studio stage meshes.
blender_master=OUT/"porsche_911_930_1975_SOURCE_Artist_Editable.blend"
bpy.ops.wm.save_as_mainfile(filepath=str(blender_master))
if blender_master.stat().st_size<16000000:
    raise RuntimeError("Original editable Porsche 911 source BLEND incomplete")

scene=bpy.context.scene
scene.render.engine="CYCLES"
scene.cycles.samples=22
bpy.context.view_layer.cycles.use_denoising=True
scene.render.resolution_x=1500
scene.render.resolution_y=1000
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.view_settings.view_transform="AgX"
scene.view_settings.look="AgX - Medium High Contrast"
world=bpy.data.worlds.new("Porsche_1975_DAYLIGHT_SOURCE_REVIEW")
world.use_nodes=True
world.node_tree.nodes["Background"].inputs["Color"].default_value=(.64,.71,.81,1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value=.87
scene.world=world
# Real photographic floor, NOT in the exported GLB.
bpy.ops.mesh.primitive_plane_add(size=120,location=(0,0,cal_lo.z-.045))
studio_floor=bpy.context.object
studio_floor.name="REVIEW_STUDIO_FLOOR_NOT_PART_OF_PORSCHE_GLTF"
floor_mat=bpy.data.materials.new("REAL_CYCLES_NEUTRAL_STUDIO_FLOOR")
floor_mat.use_nodes=True
floor_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(.30,.33,.38,1)
floor_mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value=.85
studio_floor.data.materials.append(floor_mat)
mid=(cal_lo+cal_hi)*.5
longest=max(cal_dims)
for name,delta,power,radius in (
    ("Porsche source car KEY",(.8,-1.15,1.35),1900,5.0),
    ("Porsche source car FILL",(-.95,.48,.88),1100,5.5),
    ("Porsche source car RIM",(.4,1.12,1.05),1750,3.8)
):
    data=bpy.data.lights.new(name,"AREA")
    data.energy=power
    data.shape="DISK"
    data.size=radius
    o=bpy.data.objects.new(name,data)
    scene.collection.objects.link(o)
    o.location=mid+Vector(delta)*longest
    o.rotation_euler=(mid-o.location).to_track_quat("-Z","Y").to_euler()
cam_data=bpy.data.cameras.new("Porsche 930 close frame truth camera")
cam_data.type="ORTHO"
camera=bpy.data.objects.new("Porsche 930 close frame truth camera",cam_data)
scene.collection.objects.link(camera)
scene.camera=camera
angles={
    "01_front_three_quarter":(1.12,-1.45,.54),
    "02_full_side":(1.85,0,.26),
    "03_true_front":(0,-1.8,.24),
    "04_true_rear":(0,1.8,.25),
    "05_rear_three_quarter":(-1.12,1.45,.56)
}
photos=[]
for name,direction in angles.items():
    camera.location=mid+Vector(direction)*longest
    camera.rotation_euler=(mid-camera.location).to_track_quat("-Z","Y").to_euler()
    cam_data.ortho_scale=longest*1.5
    bpy.context.view_layer.update()
    def projected_box():
        view=[world_to_camera_view(scene,camera,obj.matrix_world@Vector(v))
              for obj in real_car for v in obj.bound_box]
        return min(x.x for x in view),max(x.x for x in view),min(x.y for x in view),max(x.y for x in view)
    xmin,xmax,ymin,ymax=projected_box()
    magnification=max((xmax-xmin)/.79,(ymax-ymin)/.76)
    if not .02<magnification<5:
        raise RuntimeError("Porsche original car 3D camera bounding projection invalid "+name)
    cam_data.ortho_scale*=magnification
    bpy.context.view_layer.update()
    xmin,xmax,ymin,ymax=projected_box()
    frac_x=xmax-xmin
    frac_y=ymax-ymin
    if min(xmin,ymin)<.01 or max(xmax,ymax)>.99 or max(frac_x,frac_y)<.74 or frac_x<.48:
        raise RuntimeError("Owner-quality criterion: reject tiny/partial original Porsche "+str((name,xmin,xmax,ymin,ymax)))
    png=OUT/(name+"_TRUE_NATIVE_Cycles_Porsche_930_Red.png")
    scene.render.filepath=str(png)
    bpy.ops.render.render(write_still=True)
    if not png.is_file() or png.stat().st_size<60000:
        raise RuntimeError("Source-real Porsche Cycles original image missing: "+name)
    print("Porsche 930 REAL BLENDER PHOTO",name,round(frac_x,3),round(frac_y,3),flush=True)
    photos.append({"view":name,"file":png.name,"frame_fill_width":round(frac_x,4),
                   "frame_fill_height":round(frac_y,4),"genuine_blender_cycles":True})
result={
    "id":"porsche_911_930_1975",
    "artist":"Karol Miklas",
    "original_artist_page":"https://sketchfab.com/3d-models/free-1975-porsche-911-930-turbo-8568d9d14a994b9cae59499f0dbed21e",
    "source_license":"Original CC BY 4.0 artist notice, not a commercial trademark clearance",
    "artist_original_sha256":ORIGINAL_ARTIST_SOURCE_SHA,
    "pinned_blender_source_sha256":PINNED_IMPORT_SHA,
    "original_source_triangles_with_showroom_floor":all_source_triangles,
    "excluded_only_authored_noncar_floor_faces":noncar_showroom_tris,
    "original_author_porsche_body_triangles":car_faces,
    "exported_true_car_triangles":sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in real_car),
    "source_mesh_count_including_display_slab":len(meshes),
    "real_car_mesh_objects":len(real_car),
    "original_source_materials":len(original_material_names),
    "original_source_embedded_textures_preserved":True,
    "source_authored_exhibition_slab":noncar_showroom_name,
    "artist_original_source_dimensions_blender_units":[round(float(v),5) for v in source_original_dimensions],
    "uniform_source_unit_scale":round(float(scale),9),
    "body_and_antenna_nominal_length_m":round(max(cal_dims),4),
    "world_car_dimensions_m":[round(float(v),4) for v in cal_dims],
    "geometry_generated_or_replaced":False,
    "body_roof_glass_wheels_and_original_interior_preserved":True,
    "real_movable_door_hinges_verified":False,
    "original_hood_trunk_articulated":False,
    "approved_orange_lamborghini_exact_sha256":APPROVED_ORANGE_LAMBORGHINI_SHA,
    "original_material_rework":material_changes,
    "five_actual_native_cyles_renders":photos,
    "owner_approved":False,
    "commercial_brand_rights_cleared":False,
    "not_gameplay_or_android_approved":True,
    "status":"ACTUAL_1975_PORSCHE_930_ARTIST_MESH_PBR_NATIVE_BLENDER_FIVE_VIEWS_PENDING_VISUAL_APPROVAL"
}
if result["original_author_porsche_body_triangles"]+2 != all_source_triangles:
    raise RuntimeError("Original Porsche real car topology has been falsified")
(OUT/"porsche_930_original_source_adversarial_report.json").write_text(json.dumps(result,indent=2)+"\n")
print("CITYZERO_PORSCHE_930_REAL_SOURCE_241258_CAR_TRIS_5_CYCLES_IMAGES_GREEN_NOT_ART_APPROVED",flush=True)
