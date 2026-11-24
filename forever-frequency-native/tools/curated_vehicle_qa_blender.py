"""Forever Frequency: reference-grade GLB vehicle technical & visual audition.

Non-generative. Imports legally curated CC0 vehicle GLBs into Blender and
produces actual 1280x720 Workbench photographs from four separate cameras.
All results remain REJECTED/PENDING until an adversarial human reviews them.
Run only after downloads pass pinned SHA256 verification.
"""
import bpy, json, math
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
records=json.loads((R/"data"/"curated_vehicle_candidates.json").read_text())["candidate_models"]
OUT=R/"vehicle_quality_audition"
OUT.mkdir(parents=True,exist_ok=True)
scene=bpy.context.scene
scene.render.engine="BLENDER_WORKBENCH"
scene.display.shading.light="STUDIO"
scene.display.shading.color_type="MATERIAL"
scene.display.shading.show_shadows=True
scene.display.shading.show_cavity=True
scene.render.resolution_x=1280
scene.render.resolution_y=720
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
camera_data=bpy.data.cameras.new("Geometry Audit Camera")
camera_data.type="ORTHO"
camera=bpy.data.objects.new("Geometry Audit Camera",camera_data)
scene.collection.objects.link(camera)
scene.camera=camera
results=[]
for rec in records:
    f=R/"assets"/"curated_cars"/(rec["id"]+".glb")
    if not f.is_file():
        raise RuntimeError("REJECTED: missing downloaded CC0 base "+str(f))
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(f))
    imported=list(set(bpy.data.objects)-before)
    meshes=[o for o in imported if o.type=="MESH"]
    nodes=[o.name for o in imported]
    if not meshes:
        raise RuntimeError("REJECTED: imported car has no real 3D geometry")
    # Blender handles glTF coordinate conversion; exported world positions.
    bb=[o.matrix_world@Vector(p) for o in meshes for p in o.bound_box]
    low=Vector(tuple(min(p[i] for p in bb) for i in range(3)))
    high=Vector(tuple(max(p[i] for p in bb) for i in range(3)))
    dim=high-low
    center=(high+low)*.5
    footprint=sorted([float(dim.x),float(dim.y)],reverse=True)
    length,width=footprint
    height=float(dim.z)
    if rec["source_slug"]=="family-sedan":
        assert 4.20 < length < 5.30 and 1.60 < width < 2.50 and 1.15 < height < 1.85, "Sedan dimensions do not fit real road car"
    elif rec["source_slug"]=="supercar":
        assert 4.0 < length < 5.2 and 1.7 < width < 2.7 and .95 < height < 1.60, "Supercar dimensions do not fit real road car"
    triangles=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
    if not .4*rec["triangles"] < triangles < rec["triangles"]*1.7:
        raise RuntimeError("REJECTED: triangles inconsistent with published mobile LOD")
    named=[]
    for term in rec["expected_doornames"]:
        matches=[o for o in imported if term.lower() in o.name.lower()]
        if not matches:
            raise RuntimeError("REJECTED: no physically separate named door "+term)
        named.append(matches)
    # Do not claim hinges animate simply because a mesh is named door_FL.
    # Geometry parity + animation must be independently verified in Godot.
    camera_data.ortho_scale=length*1.36
    # Never assume that imported glTF bodies are longitudinal X.
    # Both current real CC0 models have longitudinal Y; the old code
    # mislabeled their profile views as "front" and vice versa.
    longitudinal=Vector((1.0,0.0,0.0)) if dim.x>=dim.y else Vector((0.0,1.0,0.0))
    lateral=Vector((0.0,1.0,0.0)) if dim.x>=dim.y else Vector((1.0,0.0,0.0))
    up=Vector((0.0,0.0,1.0))
    views={
        "side":-lateral*length*1.90+longitudinal*length*.05+up*length*.28,
        "front":-longitudinal*length*1.75+up*length*.30,
        "rear":longitudinal*length*1.75+up*length*.30,
        "three_quarter":-longitudinal*length*1.22-lateral*length*1.36+up*length*.72
    }
    assert abs(views["front"].dot(longitudinal)) > abs(views["front"].dot(lateral))
    assert abs(views["side"].dot(lateral)) > abs(views["side"].dot(longitudinal))
    images={}
    for angle,delta in views.items():
        camera.location=center+delta
        camera.rotation_euler=(center-camera.location).to_track_quat("-Z","Y").to_euler()
        target=OUT/(rec["id"]+"-"+angle+".png")
        scene.render.filepath=str(target)
        bpy.ops.render.render(write_still=True)
        if not target.exists() or target.stat().st_size<60000:
            raise RuntimeError("REJECTED: missing meaningful true Blender capture "+str(target))
        images[angle]=target.name
    item=dict(id=rec["id"],source_url=rec["source_url"],license="CC0 1.0",
              world_dimensions_m=[round(float(d),3) for d in dim],
              triangle_count=triangles,meshes=len(meshes),
              expected_doors=rec["expected_doors"],
              found_named_doors=len(named),
              node_names=nodes[:180],renders=images,
              longitudinal_axis="X" if dim.x>=dim.y else "Y",
              front_direction="NEGATIVE_LONGITUDINAL_AXIS_PENDING_NOSE_VERIFICATION",
              status="PENDING_ADVERSARIAL_VISUAL_REVIEW",
              actionable="Do not ship without Godot mechanical opening/closing tests")
    results.append(item)
    print("CURATED CAR CANDIDATE MEASURED",item["id"],triangles,item["world_dimensions_m"],flush=True)
    for o in imported:
        bpy.data.objects.remove(o,do_unlink=True)
(OUT/"actual_car_audit.json").write_text(json.dumps(results,indent=2),encoding="utf-8")
assert len(results)==2
print("CURATED REAL 3D SOURCE AUDITION COMPLETE — NOT ART APPROVED",flush=True)
