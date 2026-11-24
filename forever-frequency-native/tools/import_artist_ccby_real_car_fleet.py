"""Import REAL third-party artist-authored car geometry into Blender 4.5.

Inputs are pinned licensed GLB originals from SceneView's public GitHub
release (the models themselves are CC BY 4.0, NOT Apache licensed).
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

MODELS = (
    ("ferrari_f40", "Ferrari F40", "Black Snow",
     "https://sketchfab.com/3d-models/ferrari-f40-52a66c41cfcd4f999fb1b1c49bf24d70",
     "a1ec281f1c219c049ecd07e4ef20c69d26c233b6270614743ca015a7f5713674"),
    ("porsche_911", "Porsche 911 (930) Turbo 1975", "Karol Miklas",
     "https://sketchfab.com/3d-models/free-1975-porsche-911-930-turbo-8568d9d14a994b9cae59499f0dbed21e",
     "e1d7de07dda7d42aa9d87da33af4d4b05ed344e9c0222d571dce19e3658436ac"),
    ("fiat_punto", "Fiat Punto GT 1995", "Karol Miklas",
     "https://sketchfab.com/3d-models/free-1995-fiat-punto-gt-48db6facb4b64e99b60f36b8c01185e1",
     "903a94662e6a170fdf1a1323b7ebc2cbbda9185623ec9e814cfc91437902173f"),
)

def frame_car(scene, center, span, direction, camera):
    camera.location = center + Vector(direction) * span
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.ortho_scale = span * 1.90
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
    with path.open("rb") as source_handle:\n        digest = hashlib.file_digest(source_handle, "sha256").hexdigest()
    if digest != sha:
        raise RuntimeError("ORIGINAL CC-BY SOURCE SHA-256 mismatch " + identifier)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise RuntimeError("No renderable REAL authored geometry " + identifier)
    triangle_count = sum(sum(len(poly.vertices) - 2 for poly in o.data.polygons)
                         for o in meshes)
    if triangle_count < 1500:
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
    scene.render.resolution_x = 1060
    scene.render.resolution_y = 700
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
    scene.cycles.samples = 12
    # Cycles denoising moved to ViewLayer in recent Blender releases.\n    if hasattr(bpy.context.view_layer, "cycles"):\n        bpy.context.view_layer.cycles.use_denoising = True
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
        "license_notice": "Attribution required; SceneView assets are not covered by SceneView's Apache license",
        "source_release": "https://github.com/sceneview/sceneview/releases/tag/assets-v1",
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
print("THREE REAL ARTIST-AUTHORED CC-BY BLENDER CARS FIVE VIEWS EACH GREEN", flush=True)
