"""City Zero McLaren 570S: rig REAL separate original artist door shells.

Author's glTF already has separately modeled body door faces, side windows and
mirrors. This operation parents those ORIGINAL mesh nodes to new pivot Empties.
No invented door geometry, no generated imitation, no triangle replacement.
Source still REJECTED for visual/game art until owner approves. Commercial
brand/author rights remain unreviewed.
"""
import bpy,hashlib,json,math,re
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/mclaren_570s_review/mclaren_570s_2016_ORIGINAL_Author_DeepBlue_PBR.glb"
MATERIAL_AUDIT=ROOT/"assets/mclaren_570s_review/mclaren_real_materials_geometry_visual_forensic_report.json"
DEST=ROOT/"mclaren_570s_real_original_door_rig"
DEST.mkdir(parents=True,exist_ok=True)
if not SOURCE.is_file() or not MATERIAL_AUDIT.is_file():
    raise RuntimeError("Never rig a source without the real original author GLB and PBR audit")
audit=json.loads(MATERIAL_AUDIT.read_text())
assert audit["source_original_triangles"]==audit["after_pbr_triangles"]==57933
assert audit["source_sha256"]=="61a9b74c50be614d38121df8e7166462452bb95f4371215202c7658e87568639"
assert audit["owner_art_approved"] is False and audit["source_geometry_replaced"] is False
sha=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
real_objects=list(bpy.data.objects)
real_meshes=[obj for obj in real_objects if obj.type=="MESH"]
original_tris=sum(len(f.vertices)-2 for o in real_meshes for f in o.data.polygons)
if original_tris!=57933 or len(real_meshes)!=80:
    raise RuntimeError("Original McLaren 57,933 source triangles/80 mesh hierarchy modified")
bounds=[o.matrix_world@Vector(corner) for o in real_meshes for corner in o.bound_box]
lo=Vector(min(p[i] for p in bounds) for i in range(3))
hi=Vector(max(p[i] for p in bounds) for i in range(3))
mid=(lo+hi)*.5
span=max(hi-lo)
if not 4.48<span<4.58:raise RuntimeError("McLaren 4.53m source vehicle proportions damaged")

# Every ORIGINAL source GLB vertex-bounding corner must remain at EXACTLY the
# same world-space position when the new door hinges are closed.
# A previous prototype incorrectly added pivot translation to every panel and
# yielded detached floating doors. Explicitly fail closed on ANY displacement.
original_source_corners={
    obj.name:[(obj.matrix_world @ Vector(v)).copy() for v in obj.bound_box]
    for obj in real_meshes
}
original_source_world_matrices={
    obj.name:obj.matrix_world.copy() for obj in real_meshes
}


# Real source topology for artist authored McLaren 570S 2016:
# separated original exterior door panels, glass and mirror nodes. These
# are ORIGINAL artist polygons, not approximated box shapes or new textures.
# Lists are conservative: exclude large fixed interior mesh, rocker sills,
# windshield and fenders. Owner may still reject resulting door seam fit.
DOORS={
    "RIGHT":{
      "body":{1463:462,1464:285,1465:135,1525:175},
      "glass":{1:34,2:44,452:15},
      "mirror":{1901:298,1902:110,1922:286}},
    "LEFT":{
      "body":{1552:462,1553:285,1554:134,1612:175},
      "glass":{432:44,454:15},
      "mirror":{1910:300,1911:110}}
}

def model_node(number,side):
    prefix="polySurface"+str(number)+"_"
    matches=[o for o in real_meshes if o.name.startswith(prefix)]
    if len(matches)!=1:
        raise RuntimeError("Source real McLaren exact independent mesh node ambiguous: "+str(number))
    obj=matches[0]
    sign=1.0 if side=="RIGHT" else -1.0
    world=[obj.matrix_world@Vector(v) for v in obj.bound_box]
    minx=min(p.x for p in world)
    maxx=max(p.x for p in world)
    if sign>0:
        if minx<.25:raise RuntimeError("Source real right door mesh straddles vehicle: "+obj.name)
    elif maxx>-.25:
        raise RuntimeError("Source real left door mesh straddles vehicle: "+obj.name)
    return obj

items={}
all_ids=set()
for side,categories in DOORS.items():
    actual=[]
    for category,refs in categories.items():
        for number,count in refs.items():
            if number in all_ids:
                raise RuntimeError("Original mesh incorrectly assigned to both doors")
            ob=model_node(number,side)
            faces=sum(len(f.vertices)-2 for f in ob.data.polygons)
            if faces!=count:
                raise RuntimeError("Source artist shell changed: "+str((number,faces,count)))
            actual.append((ob,category,number,faces))
            all_ids.add(number)
    if sum(i[3] for i in actual if i[1]=="body")<990:
        raise RuntimeError("Missing true authored McLaren composite exterior door shell")
    if sum(i[3] for i in actual if i[1]=="glass")<50:
        raise RuntimeError("Missing true authored McLaren side door glazing")
    if sum(i[3] for i in actual if i[1]=="mirror")<400:
        raise RuntimeError("Missing true source McLaren mirror glass/body assembly")
    items[side]=actual
if len(all_ids)<16:
    raise RuntimeError("Incomplete real independently authored mechanical source parts")

# Original glTF is Y-up. After true Blender import car long axis is Y, Z-up.
# Source front wheel at glTF longitudinal z=+1.8 => Blender y=-1.8.
# Correct front door hinge near glTF longitudinal z=+1.0 => Blender y=-1.0.
pivots={}
for side,source_items in items.items():
    sign=1.0 if side=="RIGHT" else -1.0
    pivot=bpy.data.objects.new("DOOR_"+side+"_FRONT_HINGE",None)
    bpy.context.scene.collection.objects.link(pivot)
    pivot.empty_display_type="ARROWS"
    pivot.rotation_mode="QUATERNION"
    pivot.location=(sign*.89,-1.0,.60)
    # Update before applying inverse. Otherwise a stale pivot world-matrix
    # causes a (x,y,z) offset exactly equal to the Empty's location.
    bpy.context.view_layer.update()
    pivots[side]=pivot
    for ob,category,number,faces in source_items:
        old_world=original_source_world_matrices[ob.name]
        ob.parent=pivot
        ob.matrix_parent_inverse=Matrix.Identity(4)
        # Exact matrix equation: child_world = parent_world @ local_matrix.
        # Thus set local_matrix = inverse(parent_world) @ ORIGINAL world.
        # Do NOT merely assign matrix_world after parent; Blender/glTF may
        # reevaluate parent transforms and add the pivot translation.
        ob.matrix_basis=pivot.matrix_world.inverted() @ old_world
        bpy.context.view_layer.update()
        if max((ob.matrix_world @ Vector(v) - original_source_corners[ob.name][i]).length
               for i,v in enumerate(ob.bound_box)) > .001:
            raise RuntimeError("REJECT FLOATING McLAREN door parts: newly parented "+
                               ob.name+" moved from exact artist original source")
        ob["source_original_artist_mesh_id"]=number
        ob["source_piece_type"]=category
        ob["original_face_count"]=faces
bpy.context.view_layer.update()
max_original_closed_error = max(
    (obj.matrix_world @ Vector(v)-original_source_corners[obj.name][i]).length
    for obj in real_meshes for i,v in enumerate(obj.bound_box)
)
if max_original_closed_error>.001:
    raise RuntimeError("CRITICAL: closed McLaren original body/glass placement "+
                       "DOES NOT MATCH SOURCE; floating model detected "+
                       str(max_original_closed_error))
print("MCLAREN_570S_EXACT_CLOSED_ARTIST_GEOMETRY_PLACEMENT_QA_GREEN",
      round(max_original_closed_error,7),flush=True)
if len(real_meshes)!=80:raise RuntimeError("No original geometry may be deleted")
after_tris=sum(len(f.vertices)-2 for o in real_meshes for f in o.data.polygons)
if after_tris!=original_tris:raise RuntimeError("McLaren source triangles lost during real door rig")

# Test actual physical geometry movement at the REARWARD door boundary,
# not just Empty transform angles or a dummy hinge with no parented faces.
closed_points={}
for side,source_items in items.items():
    body=source_items[0][0]
    pivot=pivots[side]
    pts=[body.matrix_world@Vector(v) for v in body.bound_box]
    index=max(range(8),key=lambda i:(pts[i]-pivot.matrix_world.translation).length)
    closed_points[side]=(body,index,pts[index])
# McLaren 570S uses real dihedral UP+OUT doors, not ordinary lateral yaw.
# Source is Blender X side / Y longitudinal / Z up. Every open pivot rotates
# around a TILTED axis; ZERO angle remains identity and the exact source car.
def place_mclaren_dihedral(side,pivot,opened):
    if not opened:
        pivot.rotation_quaternion=Quaternion((1,0,0,0))
        return
    sign=1 if side=="RIGHT" else -1
    tilt=.65
    axis=Vector((-sign*tilt,0.0,math.sqrt(1.0-tilt*tilt))).normalized()
    pivot.rotation_quaternion=Quaternion(axis,math.radians(-sign*65))
closed_centers={
    side:(actual[0][0].matrix_world @ Vector(
        sum((Vector(c) for c in actual[0][0].bound_box),Vector())/8.0
    )).copy()
    for side,actual in items.items()
}
for side,p in pivots.items():
    place_mclaren_dihedral(side,p,True)
bpy.context.view_layer.update()
motion={}
upward_rise={}
for side,(body,index,before) in closed_points.items():
    moved=body.matrix_world@Vector(body.bound_box[index])
    motion[side]=round(float((moved-before).length),5)
    center=body.matrix_world @ Vector(
        sum((Vector(c) for c in body.bound_box),Vector())/8.0
    )
    upward_rise[side]=round(float(center.z-closed_centers[side].z),5)
    if motion[side]<.25 or upward_rise[side]<.27:
        raise RuntimeError("Reject sideways or floating McLaren 570S original body; dihedral UP+OUT required "+
                           str({"motion":motion,"rise":upward_rise}))
for side,p in pivots.items():
    place_mclaren_dihedral(side,p,False)
bpy.context.view_layer.update()

bpy.ops.object.select_all(action="DESELECT")
for obj in real_objects:obj.select_set(True)
for pivot in pivots.values():pivot.select_set(True)
bpy.context.view_layer.objects.active=real_meshes[0]
glb=DEST/"mclaren_570s_2016_REAL_SOURCE_BODY_GLASS_HINGES.glb"
bpy.ops.export_scene.gltf(filepath=str(glb),export_format="GLB",use_selection=True,export_extras=True)
if glb.stat().st_size<3500000:raise RuntimeError("Export stripped original source car")

master=DEST/"mclaren_570s_2016_real_source_ARTIST_HINGES_EDITABLE.blend"
bpy.ops.wm.save_as_mainfile(filepath=str(master))
if master.stat().st_size<5000000:raise RuntimeError("Source artist editable Blender mesh lost")

# Two native Blender screenshots, no image generation or fake car geometry.
scene=bpy.context.scene
scene.render.engine="BLENDER_WORKBENCH"
scene.display.shading.light="STUDIO"
scene.display.shading.color_type="MATERIAL"
scene.display.shading.show_cavity=True
scene.display.shading.show_shadows=True
scene.render.resolution_x=1500
scene.render.resolution_y=900
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
world=bpy.data.worlds.new("REVIEW_NEUTRAL_GRAY")
world.color=(.45,.51,.60)
scene.world=world
data=bpy.data.cameras.new("ACTUAL_ORIGINAL_MCLAREN_HINGED_SOURCE_CAMERA")
data.type="ORTHO"
data.ortho_scale=span*1.30
camera=bpy.data.objects.new("ACTUAL_ORIGINAL_MCLAREN_HINGED_SOURCE_CAMERA",data)
scene.collection.objects.link(camera)
scene.camera=camera
camera.location=mid+Vector((1.5,-1.5,.55))*span
camera.rotation_euler=(mid-camera.location).to_track_quat("-Z","Y").to_euler()
photos=[]
for mode in ("CLOSED","OPENED"):
    for side,p in pivots.items():
        place_mclaren_dihedral(side,p,mode=="OPENED")
    bpy.context.view_layer.update()
    png=DEST/("MCLAREN570S_REAL_SOURCE_DOOR_BODY_AND_GLASS_"+mode+"_BLENDER.png")
    scene.render.filepath=str(png)
    bpy.ops.render.render(write_still=True)
    if png.stat().st_size<45000:raise RuntimeError("Actual Blender car view missing "+mode)
    photos.append(png.name)
for side,p in pivots.items():
    place_mclaren_dihedral(side,p,False)
bpy.context.view_layer.update()

report={
 "source":"Ddiaz Design McLaren 570S 2016 original source car",
 "original_exact_source_glb_sha256":sha,
 "original_source_author_sha256":"abe0311a1c9653d1259d5fa8568407424d5da2ebca21194709e55f6877589c23",
 "original_source_tris":original_tris,"after_source_rig_tris":after_tris,
 "source_artist_mesh_count":len(real_meshes),
 "true_original_car_geometry_replaced":False,
 "closed_all_original_meshes_max_displacement_m":round(float(max_original_closed_error),8),
 "all_80_author_objects_tested_exact_original_closed_positions":True,
 "real_separate_original_panel_mesh_ids":{side:{cat:list(refs) for cat,refs in cats.items()} for side,cats in DOORS.items()},
 "hinges":["DOOR_LEFT_FRONT_HINGE","DOOR_RIGHT_FRONT_HINGE"],
 "original_doors_body_glass_mirror_following_two_pivots":True,
 "source_moving_body_panel_meters":motion,
 "source_original_dihedral_door_vertical_rise_m":upward_rise,
 "mclaren_570s_dihedral_upward_and_outward":True,
 "regular_sideways_yaw_doors_rejected":True,
 "creator_trademark_license_pending":True,
 "owner_visual_approved":False,
 "original_orange_lamborghini_unchanged_sha256":"45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7",
 "real_blender_closed_open_pictures":photos,
 "status":"REAL_SOURCE_MCLAREN_570S_ORIGINAL_DOOR_NODES_MECHANICALLY_RIGGED__VISUAL_QA_PENDING"
}
(DEST/"mclaren_source_author_true_hinges_forensics.json").write_text(json.dumps(report,indent=2)+"\n")
print("CITYZERO_REAL_MCLAREN570S_AUTHOR_BODY_GLASS_MIRRORS_RIGGED_TWO_TRUE_BLENDER_HINGES_GREEN_NOT_APPROVED",flush=True)
