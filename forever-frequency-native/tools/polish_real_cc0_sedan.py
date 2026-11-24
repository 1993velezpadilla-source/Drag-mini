"""Small, reversible physical mesh corrections to the sourced CC0 sedan.
No generated images, replacement car bodies, or changes to moving door meshes.
Call on loaded .blend; compare the geometry against original in real Blender.
"""
import bpy
from mathutils import Vector

def smoothstep(a,b,value):
    t=max(0.0,min(1.0,(value-a)/(b-a)))
    return t*t*(3.0-2.0*t)

def polish_loaded_sedan():
    seats=bpy.data.objects.get("belts_headrests")
    body=bpy.data.objects.get("body")
    if seats is None or seats.type!="MESH" or body is None or body.type!="MESH":
        raise RuntimeError("REAL SEDAN BODY/REAR SEATS MISSING: refusing guessed edits")
    bpy.context.view_layer.update()

    # Rear headrests visibly invade the rear side-glass sightline in the source.
    # Re-profile the rear-most headrest tops below 1.24m; preserve cushion
    # surfaces, individual seat components, door geometry and the cabin floor.
    adjusted=0
    maximum_before=-100.0
    maximum_after=-100.0
    inv=seats.matrix_world.inverted()
    for vert in seats.data.vertices:
        world=seats.matrix_world@vert.co
        if world.y < .55 or world.z < 1.09:
            continue
        maximum_before=max(maximum_before,float(world.z))
        old=world.copy()
        if world.z>1.135:
            world.z=1.135+(world.z-1.135)*.40
        # Rear headrests should not appear wider than the seat back below.
        if abs(world.x)>.43:
            world.x*=.982
        if (world-old).length>.00001:
            vert.co=inv@world
            adjusted+=1
        maximum_after=max(maximum_after,float(world.z))
    seats.data.update()
    if adjusted<12 or maximum_before<1.24 or maximum_after>1.25:
        raise RuntimeError("Rear headrest correction did not affect expected real geometry: "+
                           str((adjusted,maximum_before,maximum_after)))

    # Subtle surface relaxation on the outer C-pillar/rear-quarter bulge, using
    # a feathered vertex group. The 2x 0.15 Smooth does not replace mesh,
    # touch door cutouts, subdivide triangles, or flatten wheel arches.
    group=body.vertex_groups.new(name="C_PILLAR_REAR_QUARTER_LOCAL_REPAIR")
    selected=0
    for v in body.data.vertices:
        p=body.matrix_world@v.co
        weight=(smoothstep(.72,.84,abs(p.x)) *
                smoothstep(.28,.68,p.y) *
                (1.0-smoothstep(1.66,1.98,p.y)) *
                smoothstep(.40,.58,p.z) *
                (1.0-smoothstep(1.01,1.18,p.z)))
        if weight>.025:
            group.add([v.index],min(1.0,weight),"REPLACE")
            selected+=1
    if selected<15:
        raise RuntimeError("Did not locate source sedan rear-quarter problem region")
    initial_faces=len(body.data.polygons)
    modifier=body.modifiers.new("FEATHERED_REAR_QUARTER_POLISH","SMOOTH")
    modifier.factor=.15
    modifier.iterations=2
    modifier.vertex_group=group.name
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active=body
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    if len(body.data.polygons)!=initial_faces:
        raise RuntimeError("Polish changed original body topology")
    return {"source":"sourced_CC0_sedan", "rear_seat_vertices_moved":adjusted,
            "rear_headrest_peak_before_m":round(maximum_before,4),
            "rear_headrest_peak_after_m":round(maximum_after,4),
            "rear_quarter_vertices_feathered":selected,
            "body_faces_preserved":initial_faces,
            "verification":"REQUIRES_REAL_BLENDER_RENDER_REVIEW"}
