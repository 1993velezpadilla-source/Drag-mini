"""Rig actual third-party CC0 automotive meshes as independent Godot doors.
Inputs: pinned decoded source GLBs, not procedural approximations.
Outputs: CC0 GLBs/Blender source with functional hinges, no art approval.
"""
import bpy, json, math
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'curated_rigged'
OUT.mkdir(parents=True,exist_ok=True)
models=json.loads((ROOT/'data'/'curated_vehicle_candidates.json').read_text())['candidate_models']
DOOR_MAP={
  'curated_family_sedan': [('FL','FRONT'),('FR','FRONT'),('RL','REAR'),('RR','REAR')],
  'curated_midengine_supercar': [('L','FRONT'),('R','FRONT')],
}

def world_bounds(objects):
    points=[o.matrix_world@Vector(p) for o in objects if o.type=='MESH' for p in o.bound_box]
    return (Vector([min(v[k] for v in points) for k in range(3)]),
            Vector([max(v[k] for v in points) for k in range(3)]))

def moved_vertices(group):
    points=[]
    for mesh in group:
        if mesh.type!='MESH':continue
        for i in range(0,len(mesh.data.vertices),max(1,len(mesh.data.vertices)//60)):
            points.append((mesh,mesh.data.vertices[i].co.copy()))
    return points

all_reports=[]
for rec in models:
    name=rec['id']
    bpy.ops.wm.read_factory_settings(use_empty=True)
    original=ROOT/'assets'/'curated_cars'/(name+'.glb')
    assert original.is_file(),original
    bpy.ops.import_scene.gltf(filepath=str(original))
    bpy.context.view_layer.update()
    meshes=[o for o in bpy.data.objects if o.type=='MESH']
    assert meshes,len(meshes)
    baseline_bounds=world_bounds(meshes)
    # These assets ALREADY contain genuine parent door pivot nodes: door_FL,
    # door_FR, door_RL, door_RR, door_L and door_R. Do not invent pivots.
    def descendant_meshes(parent):
        children=[]
        for child in parent.children:
            if child.type=='MESH':children.append(child)
            children.extend(descendant_meshes(child))
        return children

    hinges=[];used=set()
    for token,location in DOOR_MAP[name]:
        native_name='door_'+token
        hinge=next((o for o in bpy.data.objects if o.name.lower()==native_name.lower()),None)
        if hinge is None:raise RuntimeError('MISSING ORIGINAL SOURCE HINGE '+name+' '+native_name)
        group=descendant_meshes(hinge)
        if not group:raise RuntimeError('SOURCE HINGE OWNS NO REAL MESH '+native_name)
        if any(o in used for o in group):raise RuntimeError('DUPLICATE SOURCE HINGE GEOMETRY')
        used.update(group)
        side='LEFT' if token in ('FL','RL','L') else 'RIGHT'
        door_id='DOOR_'+side+'_'+location+'_HINGE'
        if any(h['hinge']==door_id for h in hinges):raise RuntimeError('DUPLICATE HINGE '+door_id)
        original_pivot=hinge.matrix_world.translation.copy()
        hinge.name=door_id
        hinge['original_source_node']=native_name
        hinge['original_source_pivot_reused']=True
        hinge['origin_model_id']=name
        hinge.rotation_mode='XYZ'
        original_angle=hinge.rotation_euler.z
        bpy.context.view_layer.update()
        checkpoints=moved_vertices(group)
        initial=[o.matrix_world@v for o,v in checkpoints]
        hinge.rotation_euler.z=original_angle+math.radians(65 if side=='LEFT' else -65)
        bpy.context.view_layer.update()
        opened=[o.matrix_world@v for o,v in checkpoints]
        displacement=max((a-b).length for a,b in zip(initial,opened))
        if displacement<.12:
            raise RuntimeError('NATIVE DOOR PIVOT NOT MOVING REAL MESH '+door_id+' '+str(displacement))
        hinge.rotation_euler.z=original_angle
        bpy.context.view_layer.update()
        restored=[o.matrix_world@v for o,v in checkpoints]
        close_error=max((a-b).length for a,b in zip(initial,restored))
        if close_error>.005:raise RuntimeError('NATIVE HINGE CANNOT RESET '+door_id)
        hinges.append({'hinge':door_id,'source_node':native_name,'source_pivot_preserved':True,
                       'mesh_count':len(group),'open_motion_m':round(displacement,4),
                       'close_error_m':round(close_error,6),
                       'pivot_m':[round(float(v),3) for v in original_pivot]})
    if len(hinges)!=rec['expected_doors']:raise RuntimeError('INVALID DOOR COUNT '+name)
    assert len([o for o in bpy.data.objects if o.type=='MESH'])==len(meshes)
    assert all(h['mesh_count']>=1 for h in hinges)
    new_bounds=world_bounds(meshes)
    if max(abs(new_bounds[j][k]-baseline_bounds[j][k])
           for j in (0,1) for k in range(3))>.01:
        raise RuntimeError('REAL SOURCE BODY CHANGED '+name)
    tris=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
    if tris>65000:raise RuntimeError('MOBILE LOD BUDGET EXCEEDED '+name+' '+str(tris))
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(name+'.blend')))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),
        export_format='GLB',use_selection=True,export_materials='EXPORT',export_apply=True)
    assert (OUT/(name+'.glb')).stat().st_size>100000
    result={'id':name,'triangles':tris,'real_source_meshes':len(meshes),
        'source_url':rec['source_url'],'license':'CC0 1.0',
        'expected_doors':rec['expected_doors'],
        'functional_door_hinges':hinges,
        'status':'MECHANICAL_PROTOTYPE_PENDING_GODOT_ART_REVIEW'}
    all_reports.append(result)
    print('REAL CC0 CAR HINGE RIG BUILT',name,repr(result),flush=True)
(OUT/'rig_metrics.json').write_text(json.dumps(all_reports,indent=2)+'\n')
assert len(all_reports)==2
print('REAL CC0 RIGGED CAR BLENDER PROTOTYPES COMPLETE - NOT ART APPROVED',flush=True)
