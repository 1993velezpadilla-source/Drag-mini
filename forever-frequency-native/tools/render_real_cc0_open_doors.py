"""REAL Blender screenshot proof of sourced CC0 sedan/supercar with open DOORS.
Source .blend files were produced by rig_cc0_cars_blender.py from pinned CC0 GLBs.
THIS SCRIPT NEVER synthesizes images, replaces car bodies, or uses AI generation.
"""
import bpy, json, math, sys
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
from polish_real_cc0_sedan import polish_loaded_sedan

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets"/"curated_rigged"
OUTPUT=ROOT/"real_cc0_open_door_proof"
POLISHED=ROOT/"assets"/"curated_rigged_polished"
OUTPUT.mkdir(exist_ok=True)
POLISHED.mkdir(parents=True,exist_ok=True)
report=[]

def descendants(node):
    result=[]
    for child in node.children:
        if child.type=="MESH":result.append(child)
        result.extend(descendants(child))
    return result

def sample(node):
    return [(o,v.co.copy()) for o in descendants(node)
            for v in list(o.data.vertices)[::max(1,len(o.data.vertices)//90)]]

def positions(points):
    return [o.matrix_world@co for o,co in points]

def bounds(meshes):
    corners=[o.matrix_world@Vector(p) for o in meshes for p in o.bound_box]
    lo=Vector(tuple(min(p[i] for p in corners) for i in range(3)))
    hi=Vector(tuple(max(p[i] for p in corners) for i in range(3)))
    return lo,hi

def render_for(name,mode,view,camera,scene,meshes):
    low,high=bounds(meshes)
    center=(high+low)*.5
    length=max((high-low).x,(high-low).y,(high-low).z)
    # Force a consistent FULL-BODY framing for proof. Open doors can
    # extend outside the closed car bounds; compute the bounds afresh.
    camera.data.ortho_scale=length*1.46
    if view=="three_quarter":
        camera.location=center+Vector((length*1.22,-length*1.48,length*.76))
    elif view=="side":
        camera.location=center+Vector((length*2.05,-length*.05,length*.32))
    else:
        raise ValueError(view)
    camera.rotation_euler=(center-camera.location).to_track_quat("-Z","Y").to_euler()
    scene.render.filepath=str(OUTPUT/(name+"-"+mode+"-"+view+".png"))
    bpy.ops.render.render(write_still=True)
    file=Path(scene.render.filepath)
    if file.stat().st_size<15000:
        raise RuntimeError("Empty real Blender capture "+str(file))
    return {"png":file.name,"bytes":file.stat().st_size}

for name,number in (("curated_midengine_supercar",2),("curated_family_sedan",4)):
    source=SOURCE/(name+".blend")
    if not source.is_file():
        raise RuntimeError("Real rigged .blend missing: "+str(source))
    bpy.ops.wm.open_mainfile(filepath=str(source))
    if bpy.data.objects.get("Cube"):
        raise RuntimeError("Blender startup cube contaminated real vehicle proof")
    meshes=[o for o in bpy.data.objects if o.type=="MESH"]
    tris=sum(len(p.vertices)-2 for m in meshes for p in m.data.polygons)
    if tris<25000 or tris>65000:
        raise RuntimeError("Not actual LOD1 car topology "+name+" "+str(tris))
    polish=polish_loaded_sedan() if name=="curated_family_sedan" else None
    updated_tris=sum(len(p.vertices)-2 for m in meshes for p in m.data.polygons)
    if not 25000<updated_tris<=65000:
        raise RuntimeError("Polished source GLB above 65k mobile budget")
    if name=="curated_midengine_supercar" and updated_tris!=tris:
        raise RuntimeError("Lamborghini 3D topology changed")
    hinge_list=sorted([o for o in bpy.data.objects if
        o.name.startswith("DOOR_") and o.name.endswith("_HINGE")],key=lambda o:o.name)
    if len(hinge_list)!=number:
        raise RuntimeError("Missing real source door hinges "+name+" "+str(len(hinge_list)))
    initial={}
    for h in hinge_list:
        h.rotation_mode="XYZ"
        initial[h.name]=h.rotation_euler.copy()

    # Store real, improved GLB for Android and an editable Blender master.
    bpy.ops.wm.save_as_mainfile(filepath=str(POLISHED/(name+".blend")))
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(POLISHED/(name+".glb")),
        export_format="GLB",use_selection=True,export_materials="EXPORT",export_apply=True)
    assert (POLISHED/(name+".glb")).stat().st_size>100000

    scene=bpy.context.scene
    scene.render.engine="BLENDER_WORKBENCH"
    scene.display.shading.light="STUDIO"
    scene.display.shading.color_type="MATERIAL"
    scene.display.shading.show_shadows=True
    scene.display.shading.show_cavity=True
    scene.display.shading.cavity_type="BOTH"
    scene.display.shading.background_type="VIEWPORT"
    scene.display.shading.background_color=(.91,.92,.94)
    scene.render.resolution_x=1400
    scene.render.resolution_y=950
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    scene.render.film_transparent=False
    camera_data=bpy.data.cameras.new("REAL_CC0_REVIEW_CAMERA")
    camera_data.type="ORTHO"
    camera=bpy.data.objects.new("REAL_CC0_REVIEW_CAMERA",camera_data)
    scene.collection.objects.link(camera)
    scene.camera=camera

    result={"id":name,"original_model":"pinned third-party CC0 GLB",
            "source_triangles":tris,"triangles":updated_tris,"hinges":number,"actual_model":str(POLISHED/(name+".glb")),
            "screenshots":[],"measured_door_movement":{},
            "sedan_polish":polish}
    for mode in ("closed","open"):
        if mode=="open":
            for h in hinge_list:
                h.rotation_euler.z=initial[h.name].z+math.radians(
                    -66 if "_LEFT_" in h.name else 66)
            bpy.context.view_layer.update()
            for h in hinge_list:
                points=sample(h)
                before=[]
                h.rotation_euler=initial[h.name]
                bpy.context.view_layer.update()
                before=positions(points)
                h.rotation_euler.z=initial[h.name].z+math.radians(
                    -66 if "_LEFT_" in h.name else 66)
                bpy.context.view_layer.update()
                after=positions(points)
                motion=max((a-b).length for a,b in zip(before,after))
                if motion <.13:
                    raise RuntimeError("NOT ACTUAL OPENING GEOMETRY "+h.name)
                result["measured_door_movement"][h.name]=round(float(motion),3)
        for view in ("three_quarter","side"):
            result["screenshots"].append(render_for(name,mode,view,camera,scene,meshes))
    for h in hinge_list:
        h.rotation_euler=initial[h.name]
    bpy.context.view_layer.update()
    report.append(result)
    print("TRUE BLENDER GLB OPEN/CLOSED CAR PHOTOS",name,result,flush=True)

(OUTPUT/"actual_geometry_door_report.json").write_text(json.dumps(report,indent=2)+"\n")
assert len(report)==2 and len(list(OUTPUT.glob("*.png")))==8
print("REAL BLENDER SOURCED CC0 CAR OPEN-DOOR CAPTURES COMPLETE - NOT AI ART",flush=True)
