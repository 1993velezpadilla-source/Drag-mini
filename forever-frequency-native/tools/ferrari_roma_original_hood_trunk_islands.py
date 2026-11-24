"""Separate existing artist-authored Ferrari Roma hood and trunk shells.

Input is the EXACT source-preserving, 238791-triangle, independently rigged
Ferrari Roma GLB with true left/right doors. Original paint/body mesh contains
two factory-sculpted disconnected hood shell islands (3256 + 1836 triangles)
and two independent rear hatch shell islands (1240 + 1154 triangles).
Build physical X-axis pivots for these true faces WITHOUT inventing geometry,
retopology, paint boxes, fake openings or moving the complete car body.

Owner's approved orange Lamborghini never touched. New Ferrari remains
NOT ART-APPROVED, not commercial-license-cleared or gameplay released.
"""
import bpy
import bmesh
import hashlib
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets"/"ferrari_roma_review"/"ferrari_roma_2020_real_artist_island_DOOR_HINGES.glb"
SOURCE_SHA="0620ad40472c2816d9b3cabf13c4f7a94d7ab420b3f36fca4c2b048ea7e73a2c"
OUT=ROOT/"ferrari_roma_real_hood_trunk_review"
OUT.mkdir(parents=True,exist_ok=True)
if not SOURCE.exists() or hashlib.sha256(SOURCE.read_bytes()).hexdigest()!=SOURCE_SHA:
    raise RuntimeError("Failed original exact Ferrari source rigged GLB identity pin")

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
meshes=[o for o in bpy.data.objects if o.type=="MESH"]
total_triangles=lambda:sum(sum(len(face.vertices)-2 for face in o.data.polygons) for o in bpy.data.objects if o.type=="MESH")
original_triangles=total_triangles()
if original_triangles!=238791 or len(meshes)<17:
    raise RuntimeError("Real Ferrari source imported with altered body/hinged doors")
doors=[o.name for o in bpy.data.objects if o.name.startswith("DOOR_") and o.name.endswith("_HINGE")]
if set(doors)!={"DOOR_LEFT_FRONT_HINGE","DOOR_RIGHT_FRONT_HINGE"}:
    raise RuntimeError("Original Ferrari door hinges were destroyed before hood/trunk addition")
source_paint=next((o for o in meshes if o.name.startswith("bodyPaint_Geo_lodA") and len(o.data.polygons)>39000),None)
if source_paint is None:
    raise RuntimeError("Cannot find original detailed author body paint mesh with hood/trunk islands")

def pieces(obj):
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    bm.faces.index_update()
    remaining=set(bm.faces)
    result=[]
    matrix=obj.matrix_world.copy()
    while remaining:
        start=remaining.pop()
        queue=[start]
        found=[start]
        while queue:
            face=queue.pop()
            for edge in face.edges:
                for linked in edge.link_faces:
                    if linked in remaining:
                        remaining.remove(linked)
                        queue.append(linked)
                        found.append(linked)
        pts=[matrix@v.co for face in found for v in face.verts]
        lo=Vector(min(p[i] for p in pts) for i in range(3))
        hi=Vector(max(p[i] for p in pts) for i in range(3))
        result.append({"faces":len(found),"indices":{face.index for face in found},
                       "lo":lo,"hi":hi,"size":hi-lo})
    bm.free()
    return result

source_islands=pieces(source_paint)
def hood_shell(p):
    x,y,z=p["size"]
    return (p["faces"] in (3256,1836)
            and 1.45<x<1.65 and 1.45<y<1.7 and .25<z<.34
            and -.8<p["lo"].x<-.7 and .7<p["hi"].x<.8
            and -2.18<p["lo"].y<-2.12 and -.61<p["hi"].y<-.55
            and .58<p["lo"].z<.67 and .88<p["hi"].z<.96)
def trunk_shell(p):
    x,y,z=p["size"]
    return (p["faces"] in (1240,1154)
            and 1.10<x<1.20 and .57<y<.66 and .17<z<.58
            and -.61<p["lo"].x<-.54 and .54<p["hi"].x<.61
            and 1.67<p["lo"].y<1.75 and 2.27<p["hi"].y<2.33
            and .42<p["lo"].z<.82 and .96<p["hi"].z<1.02)
hood=[p for p in source_islands if hood_shell(p)]
trunk=[p for p in source_islands if trunk_shell(p)]
if sorted(x["faces"] for x in hood)!=[1836,3256]:
    raise RuntimeError("Real hood original 3256+1836 surfaces missing or damaged, reject artificial panel")
if sorted(x["faces"] for x in trunk)!=[1154,1240]:
    raise RuntimeError("Real trunk original 1240+1154 surfaces missing or damaged, reject artificial deck")
if (set.union(*(p["indices"] for p in hood)) & set.union(*(p["indices"] for p in trunk))):
    raise RuntimeError("Cannot separate overlapping original factory body parts")

def create_pivot(name,pos):
    ob=bpy.data.objects.new(name,None)
    bpy.context.scene.collection.objects.link(ob)
    ob.empty_display_type="ARROWS"
    ob.location=pos
    return ob

hood_pivot=create_pivot("HOOD_FRONT_HINGE",(0,-.584,.73))
trunk_pivot=create_pivot("TRUNK_REAR_HINGE",(0,1.70,.84))
def separate_authored_shell(group,name,pivot):
    indices=set.union(*(p["indices"] for p in group))
    original_count=len(source_paint.data.polygons)
    before=set(bpy.data.objects)
    bpy.ops.object.select_all(action="DESELECT")
    source_paint.select_set(True)
    bpy.context.view_layer.objects.active=source_paint
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    for face in source_paint.data.polygons:
        face.select=face.index in indices
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    new=[x for x in bpy.data.objects if x not in before and x.type=="MESH"]
    if len(new)!=1:
        raise RuntimeError("Expected exactly one separated existing author shell "+name)
    child=new[0]
    child.name=name
    if sum(len(face.vertices)-2 for face in child.data.polygons)!=len(indices):
        raise RuntimeError("Artist original hood/trunk faces changed during separation "+name)
    if len(source_paint.data.polygons)+len(child.data.polygons)!=original_count:
        raise RuntimeError("Original body physical source triangles were lost "+name)
    old_global=child.matrix_world.copy()
    child.parent=pivot
    child.matrix_world=old_global
    return child,{"source_component_faces":[p["faces"] for p in group],
                  "detached_original_faces":len(indices),
                  "actual_author_geometry":True,
                  "name":name}
hood_mesh,hood_info=separate_authored_shell(hood,"REAL_ARTIST_FERRARI_ROMA_HOOD_SURFACES",hood_pivot)
# Blender BMesh face IDs change after first split: always re-evaluate
# connected original trunk islands on the *remaining* physical body mesh.
trunk_now=[p for p in pieces(source_paint) if trunk_shell(p)]
if sorted(x["faces"] for x in trunk_now)!=[1154,1240]:
    raise RuntimeError("Trunk original disconnected triangles no longer match after true hood split")
trunk_mesh,trunk_info=separate_authored_shell(trunk_now,"REAL_ARTIST_FERRARI_ROMA_TRUNK_SURFACES",trunk_pivot)
if total_triangles()!=original_triangles:
    raise RuntimeError("Opening original hood/trunk mutated author body geometry")

def world_sample_at_far_edge(obj,axis):
    return obj.matrix_world@Vector(max(obj.bound_box,key=lambda p:p[1] if axis=="trunk" else -p[1]))
original_points={"hood":world_sample_at_far_edge(hood_mesh,"hood"),
                 "trunk":world_sample_at_far_edge(trunk_mesh,"trunk")}
scene=bpy.context.scene
scene.render.engine="BLENDER_WORKBENCH"
scene.display.shading.light="STUDIO"
scene.display.shading.color_type="MATERIAL"
scene.display.shading.show_shadows=True
scene.display.shading.show_cavity=True
scene.render.resolution_x=1500
scene.render.resolution_y=900
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
if scene.world is None:
    scene.world=bpy.data.worlds.new("TRUE_ORIGINAL_FERRARI_SHELL_REVIEW_STUDIO")
scene.world.color=(.46,.53,.60)
camera_data=bpy.data.cameras.new("HOOD_AND_TRUNK_ORIGINAL_SOURCE_PROOF_CAMERA")
camera_data.type="ORTHO"
camera_data.ortho_scale=5.7
cam=bpy.data.objects.new("HOOD_AND_TRUNK_ORIGINAL_SOURCE_PROOF_CAMERA",camera_data)
scene.collection.objects.link(cam);scene.camera=cam

def look(vector):
    cam.location=Vector(vector)
    cam.rotation_euler=(Vector((0,0,.66))-cam.location).to_track_quat("-Z","Y").to_euler()
def capture(label):
    filename=OUT/(label+"_REAL_ORIGINAL_ARTIST_FERRARI_3D_BLENDER.png")
    scene.render.filepath=str(filename)
    bpy.ops.render.render(write_still=True)
    if filename.stat().st_size<45000:
        raise RuntimeError("No real Blender original hood/trunk geometry screenshot "+label)
    print("REAL_SOURCE_FERRARI_ROMA_HOOD_TRUNK_CAPTURE",label,flush=True)
    return filename.name

hood_pivot.rotation_euler.x=0.0
trunk_pivot.rotation_euler.x=0.0
bpy.context.view_layer.update()
look((5.6,-6.4,3.5))
closed_front=capture("01_FRONT_CLOSED")
look((5.6,6.4,3.5))
closed_rear=capture("02_REAR_CLOSED")
hood_pivot.rotation_euler.x=math.radians(-54)
trunk_pivot.rotation_euler.x=math.radians(56)
bpy.context.view_layer.update()
hood_moved=(world_sample_at_far_edge(hood_mesh,"hood")-original_points["hood"]).length
trunk_moved=(world_sample_at_far_edge(trunk_mesh,"trunk")-original_points["trunk"]).length
if hood_moved<.55 or trunk_moved<.20:
    raise RuntimeError("Original hood/trunk geometries did not visibly pivot "+str((hood_moved,trunk_moved)))
look((5.6,-6.4,3.5))
open_front=capture("03_FRONT_HOOD_OPEN")
look((5.6,6.4,3.5))
open_rear=capture("04_REAR_TRUNK_OPEN")
hood_pivot.rotation_euler.x=0.0
trunk_pivot.rotation_euler.x=0.0
bpy.context.view_layer.update()

# Preserve ALL original Ferrari meshes, both original doors, hood and trunk.
# The studio camera is a source-proof-only visualization.
bpy.ops.object.select_all(action="DESELECT")
for ob in bpy.data.objects:
    if ob!=cam:ob.select_set(True)
glb=OUT/"ferrari_roma_2020_REAL_AUTHOR_BODY_DOORS_HOOD_TRUNK.glb"
bpy.ops.export_scene.gltf(filepath=str(glb),export_format="GLB",use_selection=True,export_extras=True)
if glb.stat().st_size<8_500_000:
    raise RuntimeError("GLTF original author car source lost material/mesh payload")
blend=OUT/"ferrari_roma_2020_REAL_ALL_FOUR_SOURCE_HINGES.blend"
bpy.ops.wm.save_as_mainfile(filepath=str(blend))
if blend.stat().st_size<2_000_000:
    raise RuntimeError("Actual editable original Ferrari Blender source missing")
report={
 "artist":"Ddiaz Design",
 "original_art_source_rig_sha256":SOURCE_SHA,
 "owner_orange_lamborghini_sha256":"45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7",
 "original_artist_triangles":original_triangles,
 "source_triangles_after_all_splits":total_triangles(),
 "hood":hood_info,
 "trunk":trunk_info,
 "original_door_hinge_nodes":doors,
 "new_real_hood_hinge":"HOOD_FRONT_HINGE",
 "new_real_trunk_hinge":"TRUNK_REAR_HINGE",
 "movement_m":{"hood":round(hood_moved,4),"trunk":round(trunk_moved,4)},
 "bodywork_added_or_generated":False,
 "original_source_mesh_material_uv_retained":True,
 "four_authentic_blender_images":[closed_front,closed_rear,open_front,open_rear],
 "engine_bay_visual_art_approval":False,
 "trunk_storage_visual_art_approval":False,
 "owner_art_approved":False,
 "brand_commercial_rights_review_pending":True,
 "status":"SOURCE_REAL_AUTHOR_FERRARI_HOOD_AND_TRUNK_OPEN_IN_NATIVE_BLENDER__GODOT_QA_PENDING"
}
(OUT/"ferrari_roma_true_author_hood_trunk_audit.json").write_text(json.dumps(report,indent=2)+"\n")
print("FERRARI_ROMA_ORIGINAL_SOURCE_HOOD_TRUNK_BOTH_REAL_GEOMETRY_HINGES_GREEN",flush=True)
