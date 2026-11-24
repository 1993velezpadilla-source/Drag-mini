"""Real Blender side/front/rear renders next to actual archived car photographs.

The geometry is generated using factory dimensions recorded in
real_vehicle_photo_references.json. This script deliberately DOES NOT approve
silhouettes via fake metric comparisons; real perspective photos require a human
to align wheel/horizon/camera before visual judging.
"""
import bpy, json, math
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
refs=json.loads((ROOT/"data"/"real_vehicle_photo_references.json").read_text())["vehicle_references"]
catalog=json.loads((ROOT/"data"/"vehicle_fleet_catalog.json").read_text())["models"]
CARS={c["id"]:c for c in catalog}
PHOTOS=ROOT/"real_car_photo_references"
OUTPUT=ROOT/"real_car_comparison"
OUTPUT.mkdir(exist_ok=True)
metrics={}
scene=bpy.context.scene
scene.render.engine="BLENDER_WORKBENCH"
scene.display.shading.color_type="MATERIAL"
scene.display.shading.light="STUDIO"
scene.display.shading.show_shadows=True
scene.display.shading.show_cavity=True
scene.render.resolution_x=1280
scene.render.resolution_y=720
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.film_transparent=False
camdata=bpy.data.cameras.new("ACTUAL_CAR_REFERENCE_REVIEW_CAMERA")
camdata.type="ORTHO"
camera=bpy.data.objects.new("ACTUAL_CAR_REFERENCE_REVIEW_CAMERA",camdata)
scene.collection.objects.link(camera)
scene.camera=camera

for reference in refs:
    name=reference["id"]
    car=CARS[name]
    true=reference["oem_dimensions_m"]
    required="length width height wheelbase".split()
    observed={"length":car["length_m"],"width":car["width_m"],
              "height":car["height_m"],
              "wheelbase":car["wheelbase_ratio"]*car["length_m"]}
    for prop in required:
        if abs(observed[prop]-true[prop])>.015:
            raise RuntimeError(f"NOT PHOTO CALIBRATED: {name} {prop} {observed[prop]:.3f} vs {true[prop]:.3f}")
    photo_dir=PHOTOS/name
    for view in reference["photos"]:
        image=photo_dir/(view["view"]+".jpg")
        if not image.is_file():
            raise RuntimeError("Missing actual photograph before modeling proof "+str(image))
        photo=bpy.data.images.load(str(image),check_existing=True)
        if min(photo.size)<400:
            raise RuntimeError("Real car photograph invalid "+str(image))

    target_glb=ROOT/"assets"/"premium_fleet"/(name+".glb")
    if not target_glb.is_file():raise RuntimeError("Missing real car GLB "+str(target_glb))
    prior=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(target_glb))
    imported=[o for o in bpy.data.objects if o not in prior]
    meshes=[o for o in imported if o.type=="MESH"]
    if len(meshes)<60:raise RuntimeError("Toy car geometry "+name)
    corners=[o.matrix_world@Vector(p) for o in meshes for p in o.bound_box]
    low=Vector([min(p[i] for p in corners) for i in range(3)])
    high=Vector([max(p[i] for p in corners) for i in range(3)])
    center=(low+high)*.5
    L=car["length_m"]
    camdata.ortho_scale=L*1.25
    cameras={"side":Vector((L*2.8,0,L*.09)),
             "front":Vector((L*.27,-L*2.1,L*.36)),
             "rear":Vector((L*.27,L*2.1,L*.36)),
             "three_quarter":Vector((L*1.14,-L*1.60,L*.54)),
             "front_three_quarter":Vector((L*1.14,-L*1.60,L*.54)),
             "rear_three_quarter":Vector((L*1.14,L*1.60,L*.54))}
    for ref in reference["photos"]:
        view=ref["view"]
        camera.location=center+cameras[view]
        camera.rotation_euler=(center-camera.location).to_track_quat("-Z","Y").to_euler()
        out=OUTPUT/(name+"-"+view+"-blender.png")
        scene.render.filepath=str(out)
        bpy.ops.render.render(write_still=True)
        if out.stat().st_size<20000:raise RuntimeError("Empty Blender screenshot "+str(out))
        print("REAL PHOTO TO BLENDER COMPARE",name,view,str(out),flush=True)
    metrics[name]={"catalog_dimensions_m":observed,"factory_dimensions_m":true,
        "model_bounds_m":[round(float(x),3) for x in high-low],
        "photo_count":len(reference["photos"]),
        "camera_matching":"HUMAN_REVIEW_REQUIRED_PHOTOS_ARE_PERSPECTIVE_NOT_ORTHOGRAPHIC",
        "visual_approval":"REJECTED_PENDING_REVIEW"}
    for o in imported:bpy.data.objects.remove(o,do_unlink=True)
(OUTPUT/"factory_geometry_checks.json").write_text(json.dumps(metrics,indent=2)+"\n")
print("REAL AUTOMOTIVE PHOTO REFERENCED BLENDER FRAMES COMPLETE - NOT VISUALLY APPROVED",flush=True)
