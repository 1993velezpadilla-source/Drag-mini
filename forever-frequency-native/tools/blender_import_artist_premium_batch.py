"""Blender 4.5 proof of ORIGINAL ARTIST CC-BY high-detail car GLBs, not procedural bodies.

Each source is SHA/Git-tree pinned and its creator license checked before Blender
touches it. Produces editable .blend, native GLB, FOUR native Blender views,
and geometry/provenance audit for distinct vehicles; not fake concept images.
Neither user-approved nor commercial-game-ready. Uniform geometric scale only.
"""
import bpy
import hashlib
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
    if hashlib.sha256(source_file.read_bytes()).hexdigest() != spec["sha256"]:
        raise RuntimeError("Original source SHA changed: " + name)
    decoded = ROOT / "assets" / "tevy_cc0_decoded_sources" / source_file.name
    if not decoded.is_file():
        raise RuntimeError("Missing decoded source: " + name)
    bpy.ops.import_scene.gltf(filepath=str(decoded))
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
    source_imported_bounds = [round(float(v), 7) for v in ext]
    expected_length = float(spec["target_longest_extent_m"])
    if not 3.0 <= expected_length <= 6.8 or not 0.0005 < span < 150:
        raise RuntimeError("Authentic source dimension/reference implausible " + name + " " + str(ext))
    # Some real artist GLBs are authored in ~centimetre scale (BMW M3 ~0.048m).
    # Uniformly scale only the REAL ORIGINAL hierarchy roots. Never replace
    # existing doors, body, lamps, interior, wheels or geometry with generated art.
    factor = expected_length / span
    if not .02 <= factor <= 5000:
        raise RuntimeError("Reject absurd original source unit scale " + name + " " + str(factor))
    original_roots = [o for o in bpy.data.objects if o.parent is None]
    if not original_roots:
        raise RuntimeError("No imported source root to uniformly scale " + name)
    for obj in original_roots:
        obj.scale = obj.scale * factor
    bpy.context.view_layer.update()
    bounds = [ob.matrix_world @ Vector(corner) for ob in meshes for corner in ob.bound_box]
    lo = Vector(min(v[i] for v in bounds) for i in range(3))
    hi = Vector(max(v[i] for v in bounds) for i in range(3))
    mid = (lo + hi) / 2
    ext = hi - lo
    span = max(ext)
    if span < 3.0 or span > 6.8 or abs(span-expected_length) > expected_length*.02:
        raise RuntimeError("Uniform source model calibration failed " + name + " " + str(ext))
    print("REAL_ARTIST_GLTF_ORIGINAL_UNIFORMLY_CALIBRATED", name,
          "original_extent", source_imported_bounds,
          "factor", round(factor, 8), "verified_length", round(span, 5), flush=True)
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
        "original_artist_import_bounds_m": source_imported_bounds,
        "uniform_real_source_scale": round(factor, 9),
        "manufacturer_length_reference_m": expected_length,
        "manufacturer_reference_url": spec["physical_length_reference"],
        "geometry_generated_or_replaced": False,
        "commercial_rights_verified": False,
        "native_3d_approved_by_user": False,
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
