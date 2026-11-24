"""City Zero: legitimate Ferrari Roma 3D PBR restyling + close-up Blender forensics.

REAL original artist GLB is required, SHA-256 pinned. Preserve the author's
existing mesh positions, original body, roof, wheel, glazing, engine and cabin.
Change PBR paint/glass/lighting, NOT geometry, to evaluate actual quality.
NO mock images; no fake doors. This mesh has NO separate door/hood/trunk nodes.
Owner's orange Lamborghini remains the ONLY art-approved vehicle.
"""
import bpy
import hashlib
import json
import math
import os
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT = Path(__file__).resolve().parents[1]
ORIGINAL = ROOT / "assets" / "tevy_cc0_blender_vehicles" / "ferrari_roma_2020_real_import.glb"
OUTPUT = ROOT / "ferrari_roma_gold_review"
OUTPUT.mkdir(parents=True, exist_ok=True)
ORIGINAL_SHA256 = "c37724315266153beb7bc4964488c1e3362df24c40d12cfce6951fa359b27c23"
ORIGINAL_ROMA_SOURCE_SHA256 = "ef07485782a96c1a2e3e20fd5117dc6aba35a23e691f791fd361c540581851e2"
GOLD_ORANGE_SHA256 = "45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7"

if not ORIGINAL.is_file() or hashlib.sha256(ORIGINAL.read_bytes()).hexdigest() != ORIGINAL_SHA256:
    raise RuntimeError("REAL artist-authored Ferrari Roma import missing or substituted")
original_size = ORIGINAL.stat().st_size
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ORIGINAL))
original_objects = list(bpy.data.objects)
meshes = [o for o in original_objects if o.type == "MESH"]
original_tris = sum(sum(len(face.vertices)-2 for face in o.data.polygons) for o in meshes)
if original_tris < 150000 or len(meshes) < 12:
    raise RuntimeError("Source body, cabin, trim, wheels or other true geometry lost")
material_names = {m.name for o in meshes for m in o.data.materials if m}
if len(material_names) < 20:
    raise RuntimeError("Real artist material topology was lost")

def bounds(objects):
    corners = [o.matrix_world @ Vector(p) for o in objects for p in o.bound_box]
    return (Vector(min(p[i] for p in corners) for i in range(3)),
            Vector(max(p[i] for p in corners) for i in range(3)))
bpy.context.view_layer.update()
lo, hi = bounds(meshes)
extent = hi-lo
span = max(extent)
center = (lo+hi)*.5
if not 4.4 < span < 4.95:
    raise RuntimeError("Original Ferrari Roma exact GT length lost: " + str(tuple(extent)))

# No false assertions that this merged source has functioning door geometry.
real_moving_nodes = [o.name for o in original_objects
                     if any(k in o.name.lower() for k in
                            ("door_left", "door_right", "door_hinge", "bonnet_hinge", "trunk_hinge"))]
if real_moving_nodes:
    raise RuntimeError("Unexpected true hinge tree; must independently inspect before animation")
if any(o.name.lower().startswith("cube") for o in meshes):
    raise RuntimeError("Procedural cube substituted for original vehicle!")

def bsdf(mat):
    mat.use_nodes = True
    return mat.node_tree.nodes.get("Principled BSDF")

changed = []
for material in bpy.data.materials:
    p = bsdf(material)
    if p is None:
        continue
    name = material.name.casefold()
    if "paint_material" in name and "roma" in name:
        # Give actual original premium body a clearly readable deep Ferrari-red
        # 2026 luxury lacquer. Never paint black on a dark studio background.
        color = (.50, .011, .024, 1.0)
        p.inputs["Base Color"].default_value = color
        p.inputs["Metallic"].default_value = .47
        p.inputs["Roughness"].default_value = .205
        if p.inputs.get("Coat Weight") is not None:
            p.inputs["Coat Weight"].default_value = .52
        if p.inputs.get("Coat Roughness") is not None:
            p.inputs["Coat Roughness"].default_value = .10
        material.diffuse_color = color
        changed.append({"part":"original body paint","name":material.name})
    elif "window_material" in name and "roma" in name:
        # Preserve actual windshield, side and rear glazing mesh surfaces.
        p.inputs["Base Color"].default_value = (.13, .22, .28, 1.0)
        p.inputs["Metallic"].default_value = .03
        p.inputs["Roughness"].default_value = .09
        if p.inputs.get("Transmission Weight") is not None:
            p.inputs["Transmission Weight"].default_value = .55
        if p.inputs.get("Alpha") is not None:
            p.inputs["Alpha"].default_value = .68
        material.diffuse_color = (.13, .22, .28, .68)
        changed.append({"part":"original glazing shader","name":material.name})
    elif ("wheel1a" in name or "chrome" in name) and "caliper" not in name:
        p.inputs["Metallic"].default_value = .78
        p.inputs["Roughness"].default_value = .24
        changed.append({"part":"real original forged-wheel/chrome shader","name":material.name})
    elif "calliper" in name:
        p.inputs["Base Color"].default_value = (.63,.02,.012,1.0)
        p.inputs["Roughness"].default_value = .22
        changed.append({"part":"original brake calipers","name":material.name})
if len(changed) < 3:
    raise RuntimeError("PBR art change did not reach original paint and glass materials")

# Export only real original artist source nodes, before studio meshes/cameras.
bpy.ops.object.select_all(action="DESELECT")
for obj in original_objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
export = OUTPUT/"ferrari_roma_2020_artist_geometry_pbr_material_review.glb"
bpy.ops.export_scene.gltf(filepath=str(export),export_format="GLB",use_selection=True)
if export.stat().st_size < original_size*.80:
    raise RuntimeError("Updated GLB unexpectedly lost author geometry/textures")
# Editable Blender master includes the original scene's PBR materials.
master = OUTPUT/"ferrari_roma_2020_true_artist_body_PBR.blend"
bpy.ops.wm.save_as_mainfile(filepath=str(master))
if master.stat().st_size < 2_000_000:
    raise RuntimeError("Editable true-artist Blender master missing")

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 24
bpy.context.view_layer.cycles.use_denoising = True
scene.render.resolution_x = 1600
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = False
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Medium High Contrast"
# Neutral studio backdrop and soft true physical surface reflections.
world = bpy.data.worlds.new("CITY_ZERO_NEUTRAL_PHOTOGRAPHIC_BACKDROP")
scene.world = world
world.use_nodes = True
background = world.node_tree.nodes.get("Background")
background.inputs["Color"].default_value = (.50,.59,.72,1.0)
background.inputs["Strength"].default_value = .72
# Floor is a photographic setting, excluded from exported original car geometry.
bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,lo.z-.038))
floor = bpy.context.object
floor.name = "QA only neutral matte studio floor NOT part of car"
mat = bpy.data.materials.new("QA_STUDIO_NEUTRAL")
mat.diffuse_color=(.32,.38,.46,1)
mat.use_nodes=True
mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(.32,.38,.46,1.0)
mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value=.84
floor.data.materials.append(mat)

def area(name, location, power, size):
    ld=bpy.data.lights.new(name,"AREA")
    ld.energy=power
    ld.shape="DISK"
    ld.size=size
    o=bpy.data.objects.new(name,ld)
    scene.collection.objects.link(o)
    o.location=center+Vector(location)*span
    o.rotation_euler=(center-o.location).to_track_quat("-Z","Y").to_euler()
    return o
area("REAL PBR studio softbox KEY",(+.9,-.9,1.15),1650,5.0)
area("REAL PBR studio softbox FILL",(-1.0,+.2,.8),1200,5.5)
area("REAL PBR studio softbox RIM",(+.3,1.4,1.1),1850,3.5)

camera_data=bpy.data.cameras.new("TRUE ORIGINAL FERRARI FRAME FILL 80 PERCENT")
camera_data.type="ORTHO"
camera=bpy.data.objects.new("TRUE ORIGINAL FERRARI FRAME FILL 80 PERCENT",camera_data)
scene.collection.objects.link(camera)
scene.camera=camera

views = {
    "01_front_three_quarter":Vector((+1.03,-1.4,.52)),
    "02_true_side":Vector((+1.8,0,.18)),
    "03_true_front":Vector((0,-1.8,.19)),
    "04_true_rear":Vector((0,1.8,.20)),
    "05_rear_three_quarter":Vector((+1.03,+1.4,.53))
}

photos=[]
for title,offset in views.items():
    camera.location = center + offset * span
    camera.rotation_euler=(center-camera.location).to_track_quat("-Z","Y").to_euler()
    camera_data.ortho_scale=span*1.25
    bpy.context.view_layer.update()
    def projected_box():
        samples=[world_to_camera_view(scene,camera,obj.matrix_world @ Vector(corner))
                 for obj in meshes for corner in obj.bound_box]
        return min(p.x for p in samples),max(p.x for p in samples),min(p.y for p in samples),max(p.y for p in samples)
    a,b,c,d=projected_box()
    # Camera calibration chooses the limiting x/y coverage. No cropping,
    # no far-away toy-car look. Exact original mesh creates every pixel.
    increase=max((b-a)/.79,(d-c)/.78)
    if not .01<increase<4.0:
        raise RuntimeError("Cannot calibrate source-car camera for "+title)
    camera_data.ortho_scale*=increase
    bpy.context.view_layer.update()
    a,b,c,d=projected_box()
    width=b-a;height=d-c
    if min(a,c)<.01 or max(b,d)>.99 or width<.55 or max(width,height)<.75:
        raise RuntimeError("Photo does not adequately fill actual frame "+
                           title+" "+str([a,b,c,d]))
    image = OUTPUT/(title+"_ACTUAL_Blend_CYCLES_2026.png")
    scene.render.filepath = str(image)
    bpy.ops.render.render(write_still=True)
    if not image.exists() or image.stat().st_size<50000:
        raise RuntimeError("Full-frame genuine Cycles Ferrari 3D render missing")
    photos.append({"file":image.name,"frame_width":round(width,4),
                   "frame_height":round(height,4),"real_pbr_render":True})
    print("FERRARI_ROMA_2020_ACTUAL_BLENDER_CYCLES_STUDIO_PROOF",title,round(width,3),flush=True)

report={
 "model":"ferrari_roma_2020",
 "original_ferrari_source_sha256":ORIGINAL_ROMA_SOURCE_SHA256,
 "preserved_blender_import_sha256":ORIGINAL_SHA256,
 "approved_orange_lamborghini_reference_sha256":GOLD_ORANGE_SHA256,
 "original_art_author":"Ddiaz Design",
 "source_license_claim":"Creator per-model attribution CC BY 4.0, separate commercial rights review required",
 "original_source_triangles":original_tris,
 "final_source_triangles":sum(sum(len(face.vertices)-2 for face in o.data.polygons) for o in meshes),
 "real_mesh_object_count":len(meshes),
 "physical_original_extent_m":[round(v,5) for v in extent],
 "geometry_generated_or_replaced":False,
 "roof_and_window_geometry_preserved":True,
 "original_interior_preserved":True,
 "wheel_geometry_preserved":True,
 "original_source_movable_hinges":len(real_moving_nodes),
 "mechanical_doors_ready":False,
 "mechanical_hood_ready":False,
 "mechanical_trunk_ready":False,
 "do_not_fake_opening_doors":"This original artist mesh is NOT separated by hinged door nodes",
 "real_material_improvements":changed,
 "native_cycles_views":photos,
 "owner_art_approved":False,
 "commercial_rights_verified":False,
 "actual_city_gameplay_quality_pending":True,
 "status":"AUTHENTIC_PBR_FERRARI_RENDERED_REAL_CLOSE_ANGLES_NOT_YET_OWNER_APPROVED"
}
assert report["original_source_triangles"]==report["final_source_triangles"]
(OUTPUT/"ferrari_roma_pbr_adversarial_report.json").write_text(json.dumps(report,indent=2)+"\n")
print("FERRARI_ROMA_AUTHENTIC_HIGH_DETAIL_BODY_5_CLOSE_PBR_VIEWS_READY_NOT_APPROVED",flush=True)
