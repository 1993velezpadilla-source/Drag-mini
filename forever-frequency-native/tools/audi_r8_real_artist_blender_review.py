"""Import REAL third-party artist-authored car geometry into Blender 4.5.

Input is a verified Objaverse distribution of wallon's CC BY 4.0 Audi R8; source receipt pins downloaded bytes.
Never generate approximation OEM silhouettes, never download game rips.
Exports editable .blend, original-based Blender GLB, 4 true Blender views,
one real native Cycles textured image, and an audit JSON per source.
These are unmodified source car BODY models, not approved rigged cars:
doors, hood, trunk, wheels, collisions, mobile budget remain for inspection.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "original_artist_ccby_sources"
OUTPUT = ROOT / "assets" / "licensed_ccby_car_fleet"
PROOF = ROOT / "artist_ccby_real_car_blender_proof"
OUTPUT.mkdir(parents=True, exist_ok=True)
PROOF.mkdir(parents=True, exist_ok=True)

# Receipt produced only after dataset metadata and author/license checks.
receipt = json.loads((SOURCE / "audi_r8_source_receipt.json").read_text())
assert receipt["source_uid"] in {"e17e438f076f4427a58d93aa779edaed","2dee503c05f940739ff6f9e2b3562337","d10f75f74355452f8e417cc36f253841","e32c7e692d46410eb60c078bb5e272f4","a1f5aa63d30046d2858929f144e0d986","7463fcd44a00428486c09487f7fcda0c"}
assert receipt["license"] == "CC BY 4.0" and receipt["artist"]
MODELS = (("audi_r8", "Audi R8", receipt["artist"], receipt["source_url"], receipt["sha256"]),)

def frame_car(scene, center, span, direction, camera):
    camera.location = center + Vector(direction) * span
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.ortho_scale = span * 1.30
    scene.camera = camera

def make_area_light(name, center, span, delta, watts, size):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = watts
    data.shape = "DISK"
    data.size = size * span
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = center + Vector(delta) * span
    obj.rotation_euler = (center - obj.location).to_track_quat("-Z", "Y").to_euler()
    return obj

def load_real_car(model):
    identifier, label, author, original_page, sha = model
    path = SOURCE / (identifier + ".glb")
    if not path.is_file() or path.stat().st_size < 300000 or path.read_bytes()[:4] != b"glTF":
        raise RuntimeError("Missing verified ORIGINAL licensed GLB: " + str(path))
    import hashlib
    with path.open("rb") as source_handle:
        digest = hashlib.file_digest(source_handle, "sha256").hexdigest()
    if digest != sha:
        raise RuntimeError("ORIGINAL CC-BY SOURCE SHA-256 mismatch " + identifier)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise RuntimeError("No renderable REAL authored geometry " + identifier)
    triangle_count = sum(sum(len(poly.vertices) - 2 for poly in o.data.polygons)
                         for o in meshes)
    if triangle_count < 300000:
        raise RuntimeError("Source has too few REAL triangles " + identifier)
    originals = [o for o in bpy.data.objects]
    bounds_points = [o.matrix_world @ Vector(corner) for o in meshes for corner in o.bound_box]
    low = Vector(min(p[i] for p in bounds_points) for i in range(3))
    high = Vector(max(p[i] for p in bounds_points) for i in range(3))
    center = (low + high) * 0.5
    dims = high - low
    span = max(dims)
    if span < 0.03 or span > 1000:
        raise RuntimeError("Invalid real GLB extent " + identifier + " " + repr(dims))

    # Save EDITABLE genuine imported master, without studio stand-ins.
    bpy.ops.file.pack_all()
    blend = OUTPUT / (identifier + "_artist_original_import.blend")
    bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    bpy.ops.object.select_all(action="SELECT")
    exported = OUTPUT / (identifier + "_blender_import.glb")
    bpy.ops.export_scene.gltf(filepath=str(exported), export_format="GLB", use_selection=True)
    if exported.stat().st_size < 300000:
        raise RuntimeError("Blender exported empty REAL source " + identifier)

    # Proof-only camera and studio setup: never included in car GLB.
    scene = bpy.context.scene
    cam_data = bpy.data.cameras.new("SOURCE_AUTHENTIC_3D_PROOF_CAMERA")
    cam_data.type = "ORTHO"
    cam = bpy.data.objects.new("SOURCE_AUTHENTIC_3D_PROOF_CAMERA", cam_data)
    scene.collection.objects.link(cam)
    scene.render.image_settings.file_format = "PNG"
    scene.render.resolution_x = 1500
    scene.render.resolution_y = 1000
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "AgX"

    # First four workbench photos show objectively inspectable source mesh
    # from orthographic directions, no synthetic/non-source body replacement.
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    camera_angles = (
        ("left_side", (1.9, 0.0, 0.25)),
        ("right_side", (-1.9, 0.0, 0.25)),
        ("front_three_quarter", (1.35, -1.45, 0.6)),
        ("rear_three_quarter", (-1.35, 1.45, 0.6)),
    )
    photo_files = []
    for angle, position in camera_angles:
        frame_car(scene, center, span, position, cam)
        scene.render.filepath = str(PROOF / (identifier + "_real_blender_" + angle + ".png"))
        bpy.ops.render.render(write_still=True)
        photo_files.append(scene.render.filepath)
        if Path(scene.render.filepath).stat().st_size < 16000:
            raise RuntimeError("Missing REAL 3D proof: " + scene.render.filepath)

    # Native Cycles (actual glTF source materials/textures, no AI generated
    # picture). Source mesh remains the same as the clean editable BLEND.
    world = bpy.data.worlds.new(identifier + "_STUDIO")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.21, 0.24, 0.29, 1.0)
    background.inputs["Strength"].default_value = 0.65
    make_area_light("Source Car Key", center, span, (1.2, -1.1, 1.7), 420 * span, 1.7)
    make_area_light("Source Car Rim", center, span, (-1.2, 1.1, 1.4), 260 * span, 1.2)
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    # Cycles denoising moved to ViewLayer in recent Blender releases.
    if hasattr(bpy.context.view_layer, "cycles"):
        bpy.context.view_layer.cycles.use_denoising = True
    frame_car(scene, center, span, (1.25, -1.5, 0.65), cam)
    pbr = PROOF / (identifier + "_REAL_native_cycles_textured.png")
    scene.render.filepath = str(pbr)
    bpy.ops.render.render(write_still=True)
    if pbr.stat().st_size < 20000:
        raise RuntimeError("Cycles screenshot did not produce true source car: " + identifier)
    photo_files.append(str(pbr))

    # Source-based facts; door opening NOT verified. Keep all models fail-closed
    # for gameplay until a separate, real hinge and material geometry audit.
    images = sum(bool(i.has_data) for i in bpy.data.images)
    materials = len({mat.name for obj in meshes for mat in obj.data.materials if mat})
    report = {
        "id": identifier, "car": label, "author": author,
        "source_url": original_page, "license": "CC-BY-4.0",
        "license_notice": "Attribution required; source mesh license applies independently of dataset license",
        "source_release": "https://huggingface.co/datasets/allenai/objaverse",
        "source_sha256": digest, "source_bytes": path.stat().st_size,
        "blender_source_mesh_objects": len(meshes),
        "blender_source_triangles": triangle_count,
        "source_material_count": materials, "decoded_embedded_image_count": images,
        "source_dimensions_blender_units": [round(float(v), 5) for v in dims],
        "editable_blend": blend.name, "blender_exported_glb": exported.name,
        "native_blender_photos": [Path(n).name for n in photo_files],
        "game_ready": False, "doors_hinges_approved": False,
        "trunk_hood_animation_approved": False,
        "visual_inspection_pending": True,
    }
    (PROOF / (identifier + "_REAL_original_source_audit.json")).write_text(
        json.dumps(report, indent=2) + "\n")
    print("AUTHENTIC_CCBY_BLENDER_SOURCE_PASS " + identifier + " " + json.dumps(report), flush=True)
    for obj in originals:
        if obj.name not in bpy.data.objects:
            raise RuntimeError("Source mesh was unexpectedly removed " + identifier)
    return report

results = [load_real_car(model) for model in MODELS]
(PROOF / "licensed_artist_fleet_report.json").write_text(
    json.dumps(results, indent=2) + "\n")
print("AUDI_R8_REAL_ARTIST_BLENDER_FIVE_VIEWS_NOT_APPROVED", flush=True)
