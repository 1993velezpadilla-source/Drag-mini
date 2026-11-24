"""City Zero SEDAN ONLY — repair source CC0 3D meshes, no synthetic car.
This script runs inside Blender on the original imported and mechanically rigged
CC0 .blend. It makes a controlled, measurable second-pass geometry repair to
the *original* rear-seat/headrest meshes, C-pillar linings, upper window trim
and rear-quarter surface. All moving door meshes keep their original hierarchy.

World convention in the sourced .blend: X=lateral, Y=longitudinal (+rear),
Z=height. Inspected against actual exported LOD1 glTF bounds in 2026-11.
"""
import math
import bpy
from mathutils import Vector

def smoothstep(a,b,value):
    if b <= a:
        raise ValueError("Bad smoothing interval")
    t=max(0.0,min(1.0,(value-a)/(b-a)))
    return t*t*(3.0-2.0*t)

def bounds(mesh):
    p=[mesh.matrix_world@v.co for v in mesh.data.vertices]
    return (Vector([min(v[i] for v in p) for i in range(3)]),
            Vector([max(v[i] for v in p) for i in range(3)]))

def local_smooth(obj,label,weight_fn,factor,iterations,minimum):
    """Smooth original mesh in a feathered zone; preserve topology/materials."""
    if obj is None or obj.type!='MESH':
        raise RuntimeError("Actual licensed mesh missing: "+label)
    initial=len(obj.data.polygons)
    original_materials=tuple(mat.name for mat in obj.data.materials)
    grp=obj.vertex_groups.new(name="CITYZERO_"+label)
    number=0
    for vertex in obj.data.vertices:
        p=obj.matrix_world@vertex.co
        weight=weight_fn(p)
        if weight>.025:
            grp.add([vertex.index],min(1.0,weight),"REPLACE")
            number+=1
    if number<minimum:
        raise RuntimeError("No actual "+label+" vertices inside repair region: "+str(number))
    modifier=obj.modifiers.new("CITYZERO_"+label+"_FEATHERED","SMOOTH")
    modifier.factor=factor
    modifier.iterations=iterations
    modifier.vertex_group=grp.name
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    if len(obj.data.polygons)!=initial:
        raise RuntimeError(label+" unexpectedly changed topology")
    if tuple(mat.name for mat in obj.data.materials)!=original_materials:
        raise RuntimeError(label+" unexpectedly changed materials")
    return {"selected":number,"faces":initial}

def polish_loaded_sedan():
    bpy.context.view_layer.update()
    body=bpy.data.objects.get("body")
    pillar=bpy.data.objects.get("pillar_lining")
    if body is None or pillar is None:
        raise RuntimeError("Original sedan body/pillar-lining mesh missing")
    seat_meshes=[o for o in bpy.data.objects if o.type=="MESH" and
                 o.name.startswith("belts_headrests")]
    # Blender retains one authored object with multiple material primitives.
    # Its exported glTF splits those into three MeshInstance3D nodes. Do not
    # confuse glTF primitive count with actual Blender object count.
    if not seat_meshes:
        raise RuntimeError("Actual authored rear-seat/headrest mesh missing")
    hinge_names=[o.name for o in bpy.data.objects if
                 o.name.startswith('DOOR_') and o.name.endswith('_HINGE')]
    if len(hinge_names)!=4:
        raise RuntimeError("Sedan original four-door hierarchy was lost")
    originals={o.name:(len(o.data.vertices),len(o.data.polygons),
                       tuple(m.name for m in o.data.materials))
               for o in seat_meshes}
    initial_hinges={n:bpy.data.objects[n].matrix_world.copy() for n in hinge_names}

    # The earlier pass changed only 'belts_headrests' and left the other two
    # rear-seat objects uncorrected. Apply a continuous fix across ALL of the
    # source rear-seat upholstery/headrest pieces, not through the door glass.
    # High shoulder/headrest vertices also retract from the sloping windows.
    adjusted=0
    highest_before=-1.0
    highest_after=-1.0
    outer_before=0.0
    outer_after=0.0
    stats={}
    for seat in seat_meshes:
        inv=seat.matrix_world.inverted_safe()
        n=0
        for v in seat.data.vertices:
            p=seat.matrix_world@v.co
            if p.y < .32 or p.z < .985:
                continue
            rear=smoothstep(.32,.58,p.y)
            original=p.copy()
            highest_before=max(highest_before,p.z)
            outer_before=max(outer_before,abs(p.x))
            # Physically move and lower protruding headrests rather than
            # blacking out the glass or hiding a problematic mesh in renders.
            if p.z > 1.012:
                lowered=1.012+(p.z-1.012)*.245
                p.z += rear*(lowered-p.z)
            # Upper cabin width tapers in real sedans.  Leave the seat base
            # broad, taper only shoulders near the rear glazing.
            at_height=smoothstep(.985,1.09,p.z)
            allowed=.620-.110*at_height
            if abs(p.x)>allowed:
                p.x += rear*(math.copysign(allowed,p.x)-p.x)
            if (p-original).length>1e-5:
                v.co=inv@p
                adjusted+=1
                n+=1
            highest_after=max(highest_after,p.z)
            outer_after=max(outer_after,abs(p.x))
        seat.data.update()
        stats[seat.name]=n
        counts=(len(seat.data.vertices),len(seat.data.polygons),
                tuple(m.name for m in seat.data.materials))
        if counts!=originals[seat.name]:
            raise RuntimeError("Modified sourced seat topology/material "+seat.name)
    if adjusted<150 or highest_before<1.23 or highest_after>1.14:
        raise RuntimeError("Insufficient actual rear-seat repair "+
                           str((adjusted,highest_before,highest_after)))

    # Rework the rear shoulder bulge, but keep the wheel lip, tail-lamps,
    # door cutlines and roof crease as hard edges. Replaces weak v1 0.15 x2
    # smoothing with 0.29 x3 in exactly the affected CC0 body zone.
    body_fix=local_smooth(
        body,"REAR_QUARTER",
        lambda p:(smoothstep(.73,.84,abs(p.x))*
                  smoothstep(.35,.68,p.y)*
                  (1-smoothstep(1.53,1.92,p.y))*
                  smoothstep(.45,.61,p.z)*
                  (1-smoothstep(1.005,1.15,p.z))),
        .29,3,350)

    # The C-pillar lining and over-window pieces are real separate meshes.
    # Their sharp, triangular highlights read like a broken top door frame.
    # Relax only the rear/upper lining; do NOT dissolve the door frames.
    pillar_fix=local_smooth(
        pillar,"C_PILLAR_LINING",
        lambda p:(smoothstep(.55,.66,abs(p.x))*
                  smoothstep(.40,.72,p.y)*
                  (1-smoothstep(1.47,1.82,p.y))*
                  smoothstep(1.012,1.15,p.z)*
                  (1-smoothstep(1.365,1.43,p.z))),
        .20,2,50)
    trims={}
    for side in ("L","R"):
        obj=bpy.data.objects.get("window_trim_"+side)
        if obj is None:
            raise RuntimeError("Original upper window trim missing "+side)
        trims[side]=local_smooth(
            obj,"UPPER_WINDOW_TRIM_"+side,
            lambda p:(smoothstep(1.24,1.29,p.z)*
                      (1-smoothstep(1.385,1.43,p.z))*
                      smoothstep(.22,.40,p.y)*
                      (1-smoothstep(.87,1.16,p.y))),
            .14,2,12)

    bpy.context.view_layer.update()
    for name,original in initial_hinges.items():
        current=bpy.data.objects[name].matrix_world
        if max(abs(current[row][col]-original[row][col])
               for row in range(4) for col in range(4))>1e-6:
            raise RuntimeError("Sedan door pivot changed during visual repair "+name)
    result={
        "source":"original CC0 sedan LOD1, not procedural",
        "repair_version":2,
        "rear_seat_vertices_moved":adjusted,
        "rear_seat_meshes_edited":stats,
        "rear_headrest_peak_before_m":round(highest_before,4),
        "rear_headrest_peak_after_m":round(highest_after,4),
        "rear_shoulder_half_width_before_m":round(outer_before,4),
        "rear_shoulder_half_width_after_m":round(outer_after,4),
        "rear_quarter_vertices_feathered":body_fix["selected"],
        "body_faces_preserved":body_fix["faces"],
        "rear_pillar_vertices_feathered":pillar_fix["selected"],
        "upper_window_trim_vertices_feathered":trims,
        "door_hinges_preserved":sorted(hinge_names),
        "verification":"PENDING_AUTHENTIC_BLENDER_PBR_VISUAL_COMPARISON"
    }
    print("CITYZERO ACTUAL SEDAN V2 SOURCE MESH REPAIR",result,flush=True)
    return result
