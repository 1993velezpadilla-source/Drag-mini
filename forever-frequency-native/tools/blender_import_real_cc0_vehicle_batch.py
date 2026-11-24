"""Blender 4.5 proof of ACTUAL CC0 original vehicle GLBs, no invented bodies.

Each source from tevy.dev/models.json is verified by source SHA before Blender
touches it. Produces editable .blend, native GLB, FOUR native Blender views,
and geometry/provenance audit for distinct vehicles; not fake concept images.
Only mark game-ready after separate source/visual/rig/Android/Godot gates.
"""
import bpy
import json
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "real_cc0_source_vehicle_audit"
SOURCES = ROOT / "assets" / "tevy_cc0_original_sources"
OUT = ROOT / "assets" / "tevy_cc0_blender_vehicles"
PHOTOS = ROOT / "real_cc0_blender_vehicle_photos"
OUT.mkdir(parents=True, exist_ok=True)
PHOTOS.mkdir(parents=True, exist_ok=True)

batch = json.loads((AUDIT / "downloaded_original_cc0_vehicle_batch.json").read_text())
finished = []
for spec in batch["models"]:
    name = spec["id"]
    source_file = SOURCES / (name + ".glb")
    if not source_file.exists() or source_file.stat().st_size != spec["bytes"]:
        raise RuntimeError("Missing REAL verified original source: " + name)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source_file))
    meshes = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("Authentic CC0 GLB imported no real mesh " + name)
    triangles = sum(sum(len(poly.vertices) - 2 for poly in ob.data.polygons) for ob in meshes)
    expected = spec["author_declared_triangles_lod0"]
    if triangles < 6000 or abs(triangles - expected) / max(1, expected) > .15:
        raise RuntimeError("Authentic source triangle audit mismatch %s (%s vs %s)" %
                           (name, triangles, expected))
    materials = {mat.name for obj in meshes for mat in obj.data.materials if mat}
    if not materials:
        raise RuntimeError("Original has no real materials: " + name)
    bounds = [ob.matrix_world @ Vector(corner) for ob in meshes for corner in ob.bound_box]
    lo = Vector(min(v[i] for v in bounds) for i in range(3))
    hi = Vector(max(v[i] for v in bounds) for i in range(3))
    mid = (lo + hi) / 2
    ext = hi - lo
    span = max(ext)
    if span < 0.35 or span > 150:
        raise RuntimeError("Original source bounds implausible: " + name + " " + str(ext))
    # Compare true source dimensions, unordered to respect original Y-up -> Blender Z-up.
    declared = spec["dimensions"]
    if isinstance(declared, dict) and all(k in declared for k in ("x","y","z")):
        original = sorted([float(declared[k]) for k in ("x","y","z")])
        current = sorted([float(v) for v in ext])
        for a,b in zip(original,current):
            if abs(a-b) > max(.25, a*.14):
                raise RuntimeError("GLB imported with broken scale or axis %s: %s vs %s" %
                                   (name, original, current))

    # Save AUTHENTIC original editable scene before any proof-only camera/lights.
    edit = OUT / (name + "_original_source.blend")
    bpy.ops.wm.save_as_mainfile(filepath=str(edit))
    bpy.ops.object.select_all(action="SELECT")
    export = OUT / (name + "_real_import.glb")
    bpy.ops.export_scene.gltf(filepath=str(export),export_format="GLB",use_selection=True)
    if export.stat().st_size < 50000:
        raise RuntimeError("Original Blender GLB export empty: " + name)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 800
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"

    data = bpy.data.cameras.new("AUTHENTIC_CC0_SOURCE_PROOF_CAMERA")
    data.type = "ORTHO"
    data.ortho_scale = span * 1.5
    camera = bpy.data.objects.new("AUTHENTIC_CC0_SOURCE_PROOF_CAMERA", data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    views = {
        "side": (1.8,0,.24),
        "front": (0,-1.8,.32),
        "rear": (0,1.8,.32),
        "three_quarter": (1.4,-1.45,.55),
    }
    photos = []
    for view,dir in views.items():
        camera.location = mid + Vector(dir) * span
        camera.rotation_euler = (mid - camera.location).to_track_quat("-Z","Y").to_euler()
        destination = PHOTOS / (name + "_REAL_Blend_" + view + ".png")
        scene.render.filepath = str(destination)
        bpy.ops.render.render(write_still=True)
        if not destination.exists() or destination.stat().st_size < 16000:
            raise RuntimeError("Real 3D native Blender photo not generated " + str(destination))
        photos.append(destination.name)
    report = {
        "id": name, "original_source_sha256": spec["sha256"],
        "original_source_url": spec["source_glb"],
        "source_license_claim": spec["license"],
        "original_source_triangles": expected,
        "actual_imported_blender_triangles": triangles,
        "real_blender_mesh_objects": len(meshes),
        "real_blender_material_count": len(materials),
        "actual_blender_bounds_m": [round(float(v), 4) for v in ext],
        "original_declared_movable_parts": spec["parts"],
        "editable_blend": edit.name,
        "actual_exported_glb": export.name,
        "authentic_blender_photos": photos,
        "door_frame_alignment_approved": False,
        "wheel_placement_approved": False,
        "interior_material_review_approved": False,
        "visual_comparison_to_approved_lamborghini_pending": True,
        "actual_godot_gameplay_test_pending": True,
        "game_ready": False,
        "status": "REAL_ORIGINAL_SOURCE_IMPORTED_AND_RENDERED__PENDING_ADVERSARIAL_VISUAL_GODOT_REVIEW",
    }
    (AUDIT / (name + "_real_blender_metrics.json")).write_text(json.dumps(report,indent=2)+"\n")
    finished.append(report)
    print("CITY_ZERO_REAL_CC0_BLENDER_VEHICLE_SOURCE_IMPORTED",name,triangles,photos,flush=True)
(AUDIT / "batch_real_blender_results.json").write_text(json.dumps(finished,indent=2)+"\n")
print("CITY_ZERO_AUTHENTIC_SOURCE_BLENDER_BATCH_GREEN",len(finished),flush=True)
