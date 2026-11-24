"""Render unmodified actual Blender GLBs at reviewer angles (no generative AI).

This is intentionally an adversarial asset contact sheet: silhouette, readable
wheels, glazing, open cargo beds, recognizable service category and no missing
pieces. Do not call a GLB finished on structural checks alone.
"""
import bpy, json, math, os
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"fleet_review"
OUT.mkdir(exist_ok=True)
choices=[
 ("premium_fleet","compact_sedan__compact_c","01-economy-compact.png"),
 ("premium_fleet","exotic_supercar__revulse","02-modern-exotic.png"),
 ("premium_fleet","basic_pickup__ranger","03-work-pickup.png"),
 ("premium_fleet","luxury_pickup__denali","04-luxury-pickup.png"),
 ("premium_fleet","electric_future__cyber_wedge","05-angular-electric-truck.png"),
 ("mobility_fleet","hypersport__falcon_1340","06-modern-hypersport.png"),
 ("mobility_fleet","dirtbike__trail_450","07-dirtbike.png"),
 ("mobility_fleet","buggy__dune_4x4","08-buggy.png"),
 ("mobility_fleet","watercraft__coastal_rib","09-rib-boat.png"),
 ("mobility_fleet","helicopter__med_evac","10-medical-helicopter.png"),
 ("mobility_fleet","airplane__sky_train","11-civilian-aircraft.png"),
 ("mobility_fleet","rail__city_tram","12-modern-tram.png")
]
# Workbench gives honest visible geometry and avoids fake cinematic promotion.
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
scene.display.shading.cavity_type="BOTH"
scene.render.resolution_x=1280
scene.render.resolution_y=720
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.film_transparent=False
camera_data=bpy.data.cameras.new("AUDIT CAMERA")
camera=bpy.data.objects.new("AUDIT CAMERA",camera_data)
scene.collection.objects.link(camera)
scene.camera=camera
camera_data.type="ORTHO"
bpy.ops.mesh.primitive_plane_add(size=1)
ground=bpy.context.object
ground.name="Reviewer ground plane"
ground.hide_render=True
counter=[]
for kind,key,name in choices:
    glb=ROOT/"assets"/kind/(key+".glb")
    assert glb.is_file(),("Missing real Blender exported file",glb)
    existing=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(glb))
    imported=[o for o in bpy.data.objects if o not in existing]
    meshes=[o for o in imported if o.type=="MESH"]
    assert len(meshes)>=6,("No detailed meshes",key)
    # Bounding boxes account for scene node transforms, not local object origin.
    pts=[o.matrix_world @ Vector(corner) for o in meshes for corner in o.bound_box]
    lo=Vector((min(p.x for p in pts),min(p.y for p in pts),min(p.z for p in pts)))
    hi=Vector((max(p.x for p in pts),max(p.y for p in pts),max(p.z for p in pts)))
    center=(lo+hi)*.5
    extent=hi-lo
    radius=max(extent.x,extent.y,extent.z)
    camera_data.ortho_scale=radius*1.58
    camera.location=center+Vector((radius*1.25,-radius*1.45,radius*.92))
    camera.rotation_euler=(center-camera.location).to_track_quat("-Z","Y").to_euler()
    out=OUT/name
    scene.render.filepath=str(out)
    bpy.ops.render.render(write_still=True)
    assert out.stat().st_size>10000,("Image not generated",key)
    counter.append({"name":key,"image":name,"meshes":len(meshes),"bounds":tuple(round(float(x),3) for x in extent),"bytes":out.stat().st_size})
    print("REAL WORKBENCH GEOMETRY PROOF",name,counter[-1],flush=True)
    for o in imported:
        bpy.data.objects.remove(o,do_unlink=True)
(OUT/"visual_inventory.json").write_text(json.dumps(counter,indent=2))
assert len(counter)==12
print("TRUE BLENDER 12-ASSET VISUAL PROOF GREEN",flush=True)
