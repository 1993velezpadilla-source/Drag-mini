"""Porsche 911 Turbo 1975: rig real artist-authored detached car door triangles.

Topology came from the exact source Porsche original CC-BY GLB (Karol Miklas),
not AI reconstruction: 42,738-triangle paint / 43,713-triangle clearcoat /
462-triangle glass / 38,854-triangle plastic sources. Existing LEFT and RIGHT
door panels, upper side windows, pillar chrome and mirrors are disconnected
source surface islands. Extract ONLY checked true artist polygons; preserve UVs,
materials and 241258 total real car triangles exactly. Open from original front
hinge locations, no fake boxes, no fabricated undercarriage. Never art approve.
"""
import bpy,bmesh,json,hashlib,math
from pathlib import Path
from mathutils import Vector,Matrix

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"assets"/"porsche_930_review"/"porsche_911_930_1975_SOURCE_REAL_Artist_ClassicRed_PBR.glb"
QA=ROOT/"assets"/"porsche_930_review"/"porsche_930_original_source_adversarial_report.json"
OUT=ROOT/"porsche_930_real_author_mechanical_doors"
OUT.mkdir(parents=True,exist_ok=True)
if not SRC.is_file() or not QA.is_file():
    raise RuntimeError("Porsche original source PBR GLB and source QA not ready; refuse fake car")
qa=json.loads(QA.read_text())
assert qa["original_author_porsche_body_triangles"]==qa["exported_true_car_triangles"]==241258
assert qa["original_source_triangles_with_showroom_floor"]==241260
assert qa["excluded_only_authored_noncar_floor_faces"]==2
assert qa["artist_original_sha256"]=="e1d7de07dda7d42aa9d87da33af4d4b05ed344e9c0222d571dce19e3658436ac"
assert not qa["owner_approved"] and not qa["geometry_generated_or_replaced"]
source_hash=hashlib.sha256(SRC.read_bytes()).hexdigest()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SRC))
bpy.context.view_layer.update()
source_objects=list(bpy.data.objects)
source_meshes=[obj for obj in source_objects if obj.type=="MESH"]
tri=lambda o:sum(len(face.vertices)-2 for face in o.data.polygons)
original_faces=sum(tri(obj) for obj in source_meshes)
if original_faces!=241258 or len(source_meshes)!=74:
    raise RuntimeError("Source Porsche real body triangles/mesh objects changed: "+str((original_faces,len(source_meshes))))
by_faces={}
for count in (42738,43713,462,38854):
    hit=[obj for obj in source_meshes if tri(obj)==count]
    if len(hit)!=1:
        raise RuntimeError("Exact original Porsche paint/coat/glass/plastic shell missing "+str(count))
    by_faces[count]=hit[0]
paint,coat,glass,window_trim=[by_faces[x] for x in (42738,43713,462,38854)]

def bounds(objects):
    coords=[obj.matrix_world@Vector(corner) for obj in objects for corner in obj.bound_box]
    return (Vector(min(p[i] for p in coords) for i in range(3)),
            Vector(max(p[i] for p in coords) for i in range(3)))
car_lo,car_hi=bounds(source_meshes)
# Cache true 125k-face BODY shell bounds BEFORE splitting the source paint
# and coat into original moving panels. Those shells lose face counts once
# correctly separated; camera framing must never rely on post-split counts.
review_shell_lo,review_shell_hi=bounds([paint,coat,window_trim])
review_mid=(review_shell_lo+review_shell_hi)*.5
review_span=max(review_shell_hi-review_shell_lo)
span=max(car_hi-car_lo)
if not 4.20<span<4.65:raise RuntimeError("Incorrect original Porsche source length before door extraction")

# PROVEN ACTUAL independent connected face islands from the source author.
# Plane of original car is Blender X lateral, Y longitudinal, Z upward.
# All source polygon components are checked by face count+side+3D world bounds.
SPEC={
    "paint":{1136,636,524},
    "coat":{976,636,524},
    "glass":{80,31},
    "glass_window_frame":{265,188,137},
}
objs={"paint":paint,"coat":coat,"glass":glass,"glass_window_frame":window_trim}
def islands(obj):
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    bm.faces.index_update()
    rest=set(bm.faces)
    out=[]
    matrix=obj.matrix_world.copy()
    while rest:
        current=rest.pop()
        group=[current]
        todo=[current]
        while todo:
            face=todo.pop()
            for edge in face.edges:
                for other in edge.link_faces:
                    if other in rest:
                        rest.remove(other)
                        group.append(other)
                        todo.append(other)
        vert=[matrix@v.co for f in group for v in f.verts]
        lo=Vector(min(p[i] for p in vert) for i in range(3))
        hi=Vector(max(p[i] for p in vert) for i in range(3))
        out.append({"indices":[f.index for f in group],
                    "faces":len(group),"low":lo,"high":hi,
                    "extent":hi-lo})
    bm.free()
    return out

def selected(obj,side,kind):
    target=SPEC[kind]
    matches=[]
    for component in islands(obj):
        # Source side coordinates are about +/-0.7m to +/-0.95m for the
        # authentic 4.291m-widebody Porsche; no central hood/windshield.
        low,high=component["low"],component["high"]
        side_center=(low.x+high.x)*.5
        if side*side_center<.53 or side*side_center>1.13:
            continue
        if component["faces"] not in target:continue
        if low.z<.1 or high.z>1.8:
            raise RuntimeError("Original Porsche hinge component lies outside actual car body")
        matches.append(component)
    got={c["faces"] for c in matches}
    if got!=target or len(matches)!=len(target):
        raise RuntimeError("Porsche creator door component topology mismatch; NO INVENTED DOOR "+
                           str({"side":side,"kind":kind,"want":sorted(target),
                                "got":sorted(c["faces"] for c in matches)}))
    return matches

# Non-destructive discovery of actual front luggage lid and rear engine cover.
# Never claim a mechanical hinge merely because a connected island exists.
central_candidates={}
for kind in ("paint","coat","glass_window_frame"):
    found=[]
    for c in islands(objs[kind]):
        lo,hi,ex=c["low"],c["high"],c["extent"]
        if not (lo.x<-.20 and hi.x>.20 and ex.x>.40 and ex.y>.18):
            continue
        if hi.z<.35 or c["faces"]<16:
            continue
        fraction=((lo.y+hi.y)*.5-review_shell_lo.y)/(review_shell_hi.y-review_shell_lo.y)
        region="front_luggage_lid_candidate" if fraction<.38 else ("rear_engine_cover_candidate" if fraction>.62 else "central_roof_or_shell")
        found.append({"region":region,"faces":c["faces"],
                      "world_low_m":[round(float(v),5) for v in lo],
                      "world_high_m":[round(float(v),5) for v in hi],
                      "center_longitudinal_fraction":round(float(fraction),5)})
    central_candidates[kind]=sorted(found,key=lambda c:(c["region"],-c["faces"]))
panel_discovery={"source_sha256":source_hash,"front_axis":"negative_blender_y",
    "source_real_triangle_count":original_faces,"candidate_islands":central_candidates,
    "lid_hinges_verified":False,"requires_source_geometry_visual_review":True}
(OUT/"porsche_930_original_luggage_engine_cover_topology.json").write_text(json.dumps(panel_discovery,indent=2)+"\n")
print("PORSCHE930_REAL_CENTRAL_PANEL_TOPOLOGY_RECORDED",json.dumps(central_candidates),flush=True)

# Fail BEFORE mutation unless every left/right original side source island
# matches exact recorded face counts, materials and physical car location.
plan={}
for side in (-1,1):
    key="LEFT" if side<0 else "RIGHT"
    plan[key]={kind:selected(obj,side,kind) for kind,obj in objs.items()}
    main=next(c for c in plan[key]["paint"] if c["faces"]==1136)
    if not .90<main["extent"].y<1.55 or not .45<main["extent"].z<.85:
        raise RuntimeError("Original Porsche main real side door doesn't have physical car-door dimensions")
    if sum(x["faces"] for m in plan[key].values() for x in m)!=(
        1136+636+524+976+636+524+80+31+265+188+137):
        raise RuntimeError("Inconsistent original authored door+mirror+glass topology")
    print("PORSCHE930_TRUE_ORIGINAL_SOURCE_DOOR_POLYGON_GROUPS_GREEN",key,
          {kind:sorted(r["faces"] for r in group) for kind,group in plan[key].items()},flush=True)

def detach_original_faces(obj,side,kind):
    regions=selected(obj,side,kind)
    mask={i for r in regions for i in r["indices"]}
    before=set(bpy.data.objects)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    for face in obj.data.polygons:
        face.select=face.index in mask
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    actual=[ob for ob in bpy.data.objects if ob not in before and ob.type=="MESH"]
    if len(actual)!=1:
        raise RuntimeError("Original source disconnected shell not separately extracted")
    door=actual[0]
    expected=sum(c["faces"] for c in regions)
    if tri(door)!=expected:
        raise RuntimeError("Artist original car source polygon loss during source separation")
    door.name="ORIGINAL_PORSCHE_930_"+("LEFT" if side<0 else "RIGHT")+"_"+kind.upper()+"_AUTHOR_PANELS"
    return door,regions

hinges={}
source_parts={}
base_positions={}
for side in (-1,1):
    key="LEFT" if side<0 else "RIGHT"
    main=next(r for r in plan[key]["paint"] if r["faces"]==1136)
    world_center=(main["low"]+main["high"])*.5
    # Base motion origin is measured from the actual DETACHED original
    # artist door body after extraction and parent matrix preservation.
    # Do not compare an all-panel centroid to just the largest face island.
    # This avoids reporting fake motion from a mismatched reference point.
    # Hinge at genuine original FRONT door panel edge on car, not hood.
    pivot=bpy.data.objects.new("DOOR_"+key+"_FRONT_HINGE",None)
    bpy.context.scene.collection.objects.link(pivot)
    pivot.empty_display_type="ARROWS"
    pivot.location=(world_center.x,main["low"].y-.02,main["low"].z+.38)
    bpy.context.view_layer.update()
    hinges[key]=pivot
    source_parts[key]=[]
    for kind,obj in objs.items():
        actual,regions=detach_original_faces(obj,side,kind)
        matrix=actual.matrix_world.copy()
        actual.parent=pivot
        actual.matrix_parent_inverse=Matrix.Identity(4)
        actual.matrix_basis=pivot.matrix_world.inverted()@matrix
        bpy.context.view_layer.update()
        # All eight original bounding corners are evaluated in TRUE world
        # coordinates against BMesh provenance bounds before the source faces
        # were separated. Check the complete panel/glass placement, not only
        # the Blender object origin (which can stay fixed while pieces float).
        expected_low=Vector(min(r["low"][i] for r in regions) for i in range(3))
        expected_high=Vector(max(r["high"][i] for r in regions) for i in range(3))
        post_low,post_high=bounds([actual])
        error=max(abs(float(post_low[i]-expected_low[i])) for i in range(3))
        error=max(error,max(abs(float(post_high[i]-expected_high[i])) for i in range(3)))
        if error>.004:
            raise RuntimeError("REJECT FLOATING Porsche creator-side door/glass/mirror mesh "+
                               actual.name+" discrepancy="+str(error))
        if kind=="paint":
            base_positions[key]=actual.matrix_world @ Vector(
                sum((Vector(vertex) for vertex in actual.bound_box),Vector())/8.0
            )
        source_parts[key].append({
            "name":actual.name,"kind":kind,"original_source_triangle_count":tri(actual),
            "component_triangle_counts":sorted(r["faces"] for r in regions),
            "hinge_pivot_world":[round(float(v),5) for v in pivot.location]
        })
# Prove no polygon was generated, lost, replaced, or transferred from owner car.
actual_meshes=[ob for ob in bpy.data.objects if ob.type=="MESH"]
after_faces=sum(tri(o) for o in actual_meshes)
if after_faces!=original_faces:
    raise RuntimeError("Porsche original 241258 source mesh triangles were lost or fabricated")
if len([ob for ob in bpy.data.objects if ob.name.startswith("DOOR_") and ob.type=="EMPTY"])!=2:
    raise RuntimeError("Two physical original Porsche front door hinges not generated")
# Animate outward around genuine front seam; this vintage Porsche uses ordinary
# outward side doors (not McLaren dihedral). Original source closed = zero.
for side,pivot in hinges.items():
    pivot.rotation_euler.z=math.radians(60 if side=="LEFT" else -60)
bpy.context.view_layer.update()
outward={}
for side,pivot in hinges.items():
    body=next(o for o in actual_meshes if o.name.startswith("ORIGINAL_PORSCHE_930_"+side+"_PAINT_"))
    center=body.matrix_world@Vector(sum((Vector(c) for c in body.bound_box),Vector())/8.0)
    delta=center.x-base_positions[side].x
    outward[side]=round(float(delta),5)
    if (side=="LEFT" and delta>-.17) or (side=="RIGHT" and delta<.17):
        raise RuntimeError("Porsche 911 real original body door not actually opening OUTWARD: "+str(outward))
for pivot in hinges.values():pivot.rotation_euler.z=0
bpy.context.view_layer.update()

# RENDER SOURCE model, not an invented car:
bpy.ops.object.select_all(action="DESELECT")
for ob in bpy.data.objects:ob.select_set(True)
rigged=OUT/"porsche_930_1975_real_artist_BODY_GLASS_MIRRORS_DOOR_HINGES.glb"
bpy.ops.export_scene.gltf(filepath=str(rigged),export_format="GLB",use_selection=True,export_extras=True)
if rigged.stat().st_size<13000000:
    raise RuntimeError("Exporter lost artist 3D Porsche textures/UVs")
editable=OUT/"porsche_930_1975_real_artist_DOOR_SOURCE_EDITABLE.blend"
bpy.ops.wm.save_as_mainfile(filepath=str(editable))
if editable.stat().st_size<14000000:
    raise RuntimeError("Original Porsche artist editable source not saved")
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
cam_data=bpy.data.cameras.new("True artist Porsche mechanic real 3D reviewer")
cam_data.type="ORTHO"
camera=bpy.data.objects.new("True artist Porsche mechanic real 3D reviewer",cam_data)
scene.collection.objects.link(camera)
scene.camera=camera
# True main body view from global source meshes, skip noncar plinth
mid=review_mid
span=review_span
cam_data.ortho_scale=span*1.25
camera.location=mid+Vector((1.3,-1.6,.60))*span
camera.rotation_euler=(mid-camera.location).to_track_quat("-Z","Y").to_euler()
screens=[]
for mode in ("CLOSED","OPENED"):
    for side,pivot in hinges.items():
        pivot.rotation_euler.z=math.radians(60 if side=="LEFT" else -60) if mode=="OPENED" else 0.0
    bpy.context.view_layer.update()
    image=OUT/("PORSCHE930_REAL_ARTIST_SOURCE_DOORS_"+mode+"_BLENDER.png")
    scene.render.filepath=str(image)
    bpy.ops.render.render(write_still=True)
    if not image.is_file() or image.stat().st_size<45000:
        raise RuntimeError("Native Blender screenshot of actual Porsche author hinges failed")
    screens.append(image.name)
for pivot in hinges.values():pivot.rotation_euler.z=0.0
bpy.context.view_layer.update()

report={
    "car":"1975 Porsche 911 (930) Turbo","artist":"Karol Miklas",
    "source_original_artist_glb_sha256":qa["artist_original_sha256"],
    "input_real_pbr_car_sha256":source_hash,
    "original_source_triangles_with_external_showroom_floor":241260,
    "original_true_car_triangles":original_faces,
    "real_car_triangles_after_rig":after_faces,
    "source_material_original_3d_objects":len(source_meshes),
    "two_actual_source_car_door_hinges":True,
    "original_body_mirror_glass_window_frame_move_together":True,
    "original_artist_detached_polygons_by_side":source_parts,
    "actual_sideways_source_original_door_x_displacement_m":outward,
    "original_author_geometry_regenerated":False,
    "original_source_car_interior_preserved":True,
    "hood_and_trunk_pivots_ready":False,
    "owner_art_approved":False,
    "brand_commercial_rights_cleared":False,
    "approved_orange_lamborghini_sha256":"45cdbfd70dc4e6c64b6bbbe5e24a2107044e2008928ab01c27fa8fbb91a25bd7",
    "real_native_blender_source_closed_open_images":screens,
    "status":"SOURCE_ORIGINAL_PORSCHE_930_TWO_REAL_HINGED_BODY_GLASS_MIRROR_FRAMES_NOT_YET_APPROVED"
}
(OUT/"porsche_930_real_artist_polygon_hinge_forensics.json").write_text(json.dumps(report,indent=2)+"\n")
print("CITYZERO_PORSCHE930_AUTHOR_ORIGINAL_BODY_GLASS_WINDOW_FRAME_TWO_HINGES_BLENDER_GREEN_NOT_APPROVED",flush=True)
