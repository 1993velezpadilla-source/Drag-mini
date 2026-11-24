"""Independent, brutally literal Blender proof: 4 cars, doors closed/open.

Renders ACTUAL exported GLBs, not generating target images. Do not approve by
counts alone: 4 side/profile comparisons and 4 opened-door images must pass
human visual inspection before uploading screenshots to the user.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
OUT=R/"door_proof"
OUT.mkdir(exist_ok=True)
names=["exotic_supercar__rossa_v","compact_sedan__compact_c",
       "basic_pickup__workhorse","electric_future__cyber_wedge"]
# A fresh Blender background launch includes its default 2-metre cube.
# Never let that cube obscure the imported vehicle: clean-review geometry only.
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
assert not bpy.context.scene.objects, "Default Blender cube contaminated photo review"
scene=bpy.context.scene
scene.render.engine="BLENDER_WORKBENCH"
scene.display.shading.light="STUDIO"
scene.display.shading.color_type="MATERIAL"
scene.display.shading.show_shadows=True
scene.display.shading.show_cavity=True
scene.render.resolution_x=1280
scene.render.resolution_y=720
scene.render.resolution_percentage=90
scene.render.image_settings.file_format="PNG"
cam_data=bpy.data.cameras.new("actual geometry reviewer")
cam=bpy.data.objects.new("actual geometry reviewer",cam_data)
scene.collection.objects.link(cam)
scene.camera=cam
cam_data.type="ORTHO"
report=[]
for n in names:
    existed=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(R/"assets"/"premium_fleet"/(n+".glb")))
    imported=[o for o in bpy.data.objects if o not in existed]
    hinges=[o for o in imported if o.name.startswith("DOOR_") and o.name.endswith("_HINGE")]
    expected=2 if n.startswith("exotic_supercar") else 4
    assert len(hinges)==expected,(n,len(hinges),[o.name for o in hinges])
    meshes=[o for o in imported if o.type=="MESH"]
    corners=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
    lo=Vector((min(p.x for p in corners),min(p.y for p in corners),min(p.z for p in corners)))
    hi=Vector((max(p.x for p in corners),max(p.y for p in corners),max(p.z for p in corners)))
    center=(lo+hi)*.5;radius=max((hi-lo).x,(hi-lo).y,(hi-lo).z)
    cam_data.ortho_scale=radius*1.55
    cam.location=center+Vector((radius*1.15,-radius*1.25,radius*.69))
    cam.rotation_euler=(center-cam.location).to_track_quat("-Z","Y").to_euler()
    for opened in (False,True):
        for h in hinges:
            # Blender's GLTF importer restores hinges as QUATERNION objects.
            # Writing Euler without switching mode previously did NOTHING.
            h.rotation_mode='XYZ'
            h.rotation_euler.z=math.radians((65 if "LEFT" in h.name else -65) if opened else 0)
        bpy.context.view_layer.update()
        target=OUT/(n+("-open.png" if opened else "-closed.png"))
        scene.render.filepath=str(target)
        bpy.ops.render.render(write_still=True)
        assert target.stat().st_size>20000,target
    # Use Blender's own image pixels; external PIL is not part of Blender images.
    import numpy as np
    img_a=bpy.data.images.load(str(OUT/(n+"-closed.png")),check_existing=False)
    img_b=bpy.data.images.load(str(OUT/(n+"-open.png")),check_existing=False)
    arr_a=np.empty(len(img_a.pixels),dtype=np.float32)
    arr_b=np.empty(len(img_b.pixels),dtype=np.float32)
    img_a.pixels.foreach_get(arr_a)
    img_b.pixels.foreach_get(arr_b)
    bpy.data.images.remove(img_a)
    bpy.data.images.remove(img_b)
    changed_pixels=int(np.count_nonzero(np.max(np.abs(arr_a.reshape((-1,4))[:,:3]-arr_b.reshape((-1,4))[:,:3]),axis=1)>.13))
    if changed_pixels < 500:
        raise RuntimeError("VISUAL CRITIC RED: model has fake or nearly invisible door movement "+n+" "+str(changed_pixels))
    print("TRUE VISUAL DOOR CHANGE",n,changed_pixels,flush=True)
    report.append({"id":n,"hinges":len(hinges),"screenshots":2,
                   "body_meshes":len(meshes),"bounds_m":[round(float(v),2) for v in hi-lo]})
    for o in imported:bpy.data.objects.remove(o,do_unlink=True)
(OUT/"hinge_visual_report.json").write_text(json.dumps(report,indent=2))
print("REAL BLENDER FOUR CAR DOOR PHOTO GATE GREEN",report,flush=True)
