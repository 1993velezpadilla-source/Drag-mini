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
import bmesh
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

def repair_original_rear_windscreen(body):
    """Fit original rear glass to the ACTUAL body roofline, not a guessed car.

    Source CC0 rear glass uses very large quads; sparse high points reflect
    like a detached bubble. Subdivide that mesh with its own materials/UVs
    and keep its upper vertices just below the sampled original roofline.
    """
    glass=bpy.data.objects.get("glass_rear")
    if glass is None or glass.type!="MESH":
        raise RuntimeError("Original rear windscreen mesh missing")
    before_faces=len(glass.data.polygons)
    roof_vertices=[body.matrix_world@v.co for v in body.data.vertices]
    roof_stations=[]
    for i in range(11):
        y=.75+i*.10
        samples=[p.z for p in roof_vertices if abs(p.y-y)<.12
                 and abs(p.x)<.76 and p.z>1.06]
        if len(samples)<10:
            raise RuntimeError("Cannot derive real sedan roofline "+str(y))
        roof_stations.append((y,max(samples)))

    def roof_limit(y):
        if y<=roof_stations[0][0]:
            return roof_stations[0][1]-.008
        for i in range(len(roof_stations)-1):
            y0,z0=roof_stations[i]
            y1,z1=roof_stations[i+1]
            if y<=y1:
                t=(y-y0)/(y1-y0)
                return z0*(1-t)+z1*t-.008
        return roof_stations[-1][1]-.008

    bm=bmesh.new()
    bm.from_mesh(glass.data)
    bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=1,use_grid_fill=True)
    bm.to_mesh(glass.data)
    bm.free()
    glass.data.update()
    after_faces=len(glass.data.polygons)
    if after_faces<before_faces*2:
        raise RuntimeError("Did not retessellate rear windscreen")
    inv=glass.matrix_world.inverted_safe()
    corrected=0
    old_excess=0.0
    new_excess=0.0
    for vertex in glass.data.vertices:
        p=glass.matrix_world@vertex.co
        cap=roof_limit(p.y)
        extra=p.z-cap
        old_excess=max(old_excess,extra)
        if extra>0:
            p.z=cap
            vertex.co=inv@p
            corrected+=1
        new_excess=max(new_excess,p.z-cap)
    glass.data.update()
    if corrected<12 or old_excess<.012 or new_excess>.002:
        raise RuntimeError("Rear glass still passes through roof: "+
                           str((corrected,old_excess,new_excess)))

    slots=glass.data.materials
    glass_indices=[i for i,m in enumerate(slots) if m and m.name=="glass"]
    if len(glass_indices)!=1:
        raise RuntimeError("Source sedan glass material not uniquely identifiable")
    rear_glass=slots[glass_indices[0]].copy()
    rear_glass.name="CITYZERO_SEDAN_REAR_PRIVACY_GLASS"
    shader=rear_glass.node_tree.nodes.get("Principled BSDF") if rear_glass.use_nodes else None
    if shader is None:
        raise RuntimeError("Native Blender rear PBR shader missing")
    # Avoid the huge silver/milky reflection across the rear roof. Give
    # only rear/quarter glass a realistic dark privacy tint; front door and
    # windshield glass retain the original material and transparency.
    shader.inputs["Base Color"].default_value=(.021,.029,.043,1)
    shader.inputs["Roughness"].default_value=.19
    transmission=shader.inputs.get("Transmission Weight")
    if transmission is not None:
        transmission.default_value=.08
    specular=shader.inputs.get("Specular IOR Level")
    if specular is not None:
        specular.default_value=.16
    slots[glass_indices[0]]=rear_glass
    quarter_count=0
    for side in ("L","R"):
        quarter=bpy.data.objects.get("glass_side_"+side)
        if quarter is None or quarter.type!="MESH":
            raise RuntimeError("Source fixed quarter window missing "+side)
        for i,mat in enumerate(quarter.data.materials):
            if mat and mat.name=="glass":
                quarter.data.materials[i]=rear_glass
                quarter_count+=1
    if quarter_count!=2:
        raise RuntimeError("Could not match both real sedan fixed quarter windows")

    # Distinct source material: most of the silver 'bubble' is not glass,
    # but the broad glass_rear trim_gloss primitive (~0.88 m2 in the
    # exported original). Give the existing gasket a real low-glare rubber
    # finish rather than changing its mesh or painting over a screenshot.
    trim_source=next((m for m in glass.data.materials
                      if m and m.name=="trim_gloss"),None)
    if trim_source is None:
        raise RuntimeError("Original oversized rear-glass gloss frame missing")
    rubber=trim_source.copy()
    rubber.name="CITYZERO_SEDAN_REAR_WINDOW_BLACK_GASKET"
    rubber_bs=rubber.node_tree.nodes.get("Principled BSDF") if rubber.use_nodes else None
    if rubber_bs is None:
        raise RuntimeError("Cannot adjust actual rear frame PBR material")
    rubber_bs.inputs["Base Color"].default_value=(.012,.014,.018,1)
    rubber_bs.inputs["Roughness"].default_value=.57
    specular=rubber_bs.inputs.get("Specular IOR Level")
    if specular is not None:
        specular.default_value=.065
    material_changes=0
    for obj in (glass,bpy.data.objects["glass_side_L"],bpy.data.objects["glass_side_R"]):
        for i,m in enumerate(obj.data.materials):
            if m and m.name=="trim_gloss":
                obj.data.materials[i]=rubber
                material_changes+=1
    if material_changes!=3:
        raise RuntimeError("Failed to update actual rear window gasket/quarter seals")
    return {"original_glass_faces":before_faces,
            "retessellated_glass_faces":after_faces,
            "glass_vertices_corrected":corrected,
            "maximum_old_roof_protrusion_m":round(old_excess,4),
            "maximum_new_roof_protrusion_m":round(new_excess,4),
            "roof_station_count":len(roof_stations),
            "rear_privacy_glass_material_only":rear_glass.name,
            "rear_quarter_windows_consistent_tint":quarter_count,
            "rear_gasket_and_quarter_seals_matte":material_changes}

def repair_original_door_upper_frames():
    """Reprofile ALL FOUR physical door-window frames to the original roof rail.

    The old 'upper window trim' fix only smoothed the chrome roof trim. It
    never touched the door's actual chrome-and-glass frame mesh, leaving its
    top corners disconnected/bent. Operate on those original hinge children.
    """
    results={}
    for side in ("L","R"):
        roof=bpy.data.objects.get("window_trim_"+side)
        if roof is None or roof.type!="MESH":
            raise RuntimeError("Source sedan roofline surround missing "+side)
        roof_points=[roof.matrix_world@v.co for v in roof.data.vertices]
        roof_points=[p for p in roof_points if p.z>1.22]
        if len(roof_points)<80:
            raise RuntimeError("Insufficient original roofline sample "+side)
        # The upper crown of this real authored trim is our reference curve;
        # this uses no imagined/new car design and leaves A/C pillars fixed.
        def roof_height(y):
            samples=[p.z for p in roof_points if abs(p.y-y)<.092]
            if len(samples)<3:
                # nearest source trim stations
                nearest=sorted(roof_points,key=lambda p:abs(p.y-y))[:8]
                samples=[p.z for p in nearest]
            return max(samples)

        for location,token in (("FRONT","F"),("REAR","R")):
            name="door_"+token+side+"_glass_side_"+side
            obj=bpy.data.objects.get(name)
            if obj is None or obj.type!="MESH":
                raise RuntimeError("Source moving upper door frame missing "+name)
            hinges=[]
            parent=obj.parent
            while parent is not None:
                if parent.name.startswith("DOOR_") and parent.name.endswith("_HINGE"):
                    hinges.append(parent.name)
                parent=parent.parent
            if len(hinges)!=1:
                raise RuntimeError("Upper door frame not parented to original hinge "+name)
            old_count=len(obj.data.vertices)
            old_faces=len(obj.data.polygons)
            material_names=[m.name for m in obj.data.materials]
            if not ("trim_gloss" in material_names and "glass" in material_names):
                raise RuntimeError("Original door frame is missing trim and glass "+name)
            vertices=[(v,obj.matrix_world@v.co) for v in obj.data.vertices]
            # Group sparse original top frame stations, not the vertical B-post
            # and not the bottom horizontal weatherstrip.
            adjusted=0
            max_shift=0.0
            inverse=obj.matrix_world.inverted_safe()
            for vert,p in vertices:
                if p.z<1.19 or abs(p.x)<.58:
                    continue
                nearby=[q.z for _,q in vertices if abs(q.y-p.y)<.13 and q.z>1.19]
                if not nearby:
                    continue
                top=max(nearby)
                intended=roof_height(p.y)-.024
                correction=max(-.029,min(.028,intended-top))
                weight=smoothstep(top-.086,top-.009,p.z)
                dz=weight*correction
                if abs(dz)>.00005:
                    updated=p.copy()
                    updated.z+=dz
                    vert.co=inverse@updated
                    adjusted+=1
                    max_shift=max(max_shift,abs(dz))
            obj.data.update()
            if len(obj.data.vertices)!=old_count or len(obj.data.polygons)!=old_faces:
                raise RuntimeError("Upper door repair must not replace source mesh "+name)
            if adjusted<4 or max_shift>.0295:
                raise RuntimeError("Upper door curve repair failed "+name+" "+str((adjusted,max_shift)))

            # The original oversized silver roof-edge chrome read like a
            # broken wire above the door. Keep the physical metal edge,
            # give it realistic dark satin trim without changing glass.
            original=obj.data.materials[material_names.index("trim_gloss")]
            material=original.copy()
            material.name="CITYZERO_SEDAN_"+name+"_SATIN_WINDOW_FRAME"
            shader=material.node_tree.nodes.get("Principled BSDF") if material.use_nodes else None
            if shader is None:
                raise RuntimeError("Original sourced trim shader missing "+name)
            shader.inputs["Base Color"].default_value=(.041,.051,.064,1)
            shader.inputs["Metallic"].default_value=.48
            shader.inputs["Roughness"].default_value=.34
            obj.data.materials[material_names.index("trim_gloss")]=material
            results[name]={"upper_vertices_reprofiled":adjusted,
                           "maximum_coordinate_change_m":round(max_shift,5),
                           "source_faces_untouched":old_faces,
                           "original_hinge":hinges[0]}

        # Roofline must also match dark door-frame edge; do not turn ALL
        # chrome on the car black, only the two original upper window rails.
        original_chrome=next((m for m in roof.data.materials if m and m.name.startswith("chrome")),None)
        if original_chrome is None:
            raise RuntimeError("Actual upper roof trim chromium missing "+side)
        roof_mat=original_chrome.copy()
        roof_mat.name="CITYZERO_SEDAN_"+side+"_SATIN_ROOFLINE_EDGE"
        shader=roof_mat.node_tree.nodes.get("Principled BSDF") if roof_mat.use_nodes else None
        if shader is None:
            raise RuntimeError("Actual upper rail shader missing "+side)
        shader.inputs["Base Color"].default_value=(.052,.063,.077,1)
        shader.inputs["Metallic"].default_value=.53
        shader.inputs["Roughness"].default_value=.39
        for i,material in enumerate(roof.data.materials):
            if material==original_chrome:
                roof.data.materials[i]=roof_mat
    if len(results)!=4:
        raise RuntimeError("Did not repair all four genuine upper door frames")
    return results

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
            rear=smoothstep(.22,.36,p.y)
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

    door_frame_fix=repair_original_door_upper_frames()
    rear_glass_fix=repair_original_rear_windscreen(body)
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
        "real_moving_upper_door_frames_reprofiled":door_frame_fix,
        "original_rear_glass_reprofile":rear_glass_fix,
        "door_hinges_preserved":sorted(hinge_names),
        "verification":"PENDING_AUTHENTIC_BLENDER_PBR_VISUAL_COMPARISON"
    }
    print("CITYZERO ACTUAL SEDAN V2 SOURCE MESH REPAIR",result,flush=True)
    return result
