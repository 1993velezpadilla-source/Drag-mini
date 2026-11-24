"""Photograph EXACT sourced CC0 Blender car meshes with their actual hinged doors.
Cycles CPU studio renders with native PBR materials. No generative image model.
"""
import bpy, math, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'assets'/'curated_rigged_polished'
OUT=ROOT/'real_cc0_open_door_pbr'
OUT.mkdir(exist_ok=True)
report=[]
for name,doors in [('curated_midengine_supercar',2),('curated_family_sedan',4)]:
    bpy.ops.wm.open_mainfile(filepath=str(SRC/(name+'.blend')))
    source_meshes=[o for o in bpy.data.objects if o.type=='MESH']
    assert len(source_meshes)>20
    tris=sum(len(p.vertices)-2 for o in source_meshes for p in o.data.polygons)
    if name=='curated_midengine_supercar':
        assert tris==44632,("Lambo must remain pristine",tris)
    else:
        assert 60300<=tris<=65000,("source sedan glass LOD exceeds budget",tris)
    hinges=[o for o in bpy.data.objects if o.name.startswith('DOOR_') and o.name.endswith('_HINGE')]
    assert len(hinges)==doors,(name,len(hinges))
    initial_rotations={}
    for h in hinges:
        h.rotation_mode='XYZ'
        initial_rotations[h.name]=h.rotation_euler.copy()
    bpy.context.view_layer.update()
    scene=bpy.context.scene
    scene.render.engine='CYCLES'
    scene.cycles.device='CPU'
    scene.cycles.samples=12
    scene.render.resolution_x=1280
    scene.render.resolution_y=840
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    scene.render.film_transparent=False
    scene.render.threads_mode='FIXED'
    scene.render.threads=2
    try:
        bpy.context.view_layer.cycles.use_denoising=True
    except AttributeError:
        pass
    scene.world=bpy.data.worlds.new('Studio HDR-equivalent neutral ambient')
    scene.world.use_nodes=True
    bg=scene.world.node_tree.nodes.get('Background')
    bg.inputs['Color'].default_value=(.72,.76,.82,1)
    bg.inputs['Strength'].default_value=.82
    floor_mat=bpy.data.materials.new('Real studio floor')
    floor_mat.use_nodes=True
    bs=floor_mat.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(.70,.73,.77,1)
    bs.inputs['Roughness'].default_value=.9
    bpy.ops.mesh.primitive_plane_add(size=25,location=(0,0,-.065))
    ground=bpy.context.object
    ground.name='STUDIO_FLOOR_NOT_PART_OF_CAR'
    ground.data.materials.append(floor_mat)
    def area(name,location,power,size):
        data=bpy.data.lights.new(name,'AREA')
        data.energy=power
        data.shape='DISK'
        data.size=size
        obj=bpy.data.objects.new(name,data)
        scene.collection.objects.link(obj)
        obj.location=location
        obj.rotation_euler=(-obj.location).to_track_quat('-Z','Y').to_euler()
    area('Wide softbox front left',(4,-5,7),1800,7)
    area('Wide softbox right',(-4,-1,5),1050,6)
    area('Rear roof stripbox',(0,5,6),1350,5)
    data=bpy.data.cameras.new('REAL_CAR_PBR_CAMERA')
    data.type='ORTHO'
    cam=bpy.data.objects.new('REAL_CAR_PBR_CAMERA',data)
    scene.collection.objects.link(cam)
    scene.camera=cam
    # For the problem sedan, review the full CAR BOTH closed and open. This
    # exposes floating rear seats, odd window frames and detached panels.
    modes=('closed','open') if name=='curated_family_sedan' else ('open',)
    for mode in modes:
        for h in hinges:
            h.rotation_euler=initial_rotations[h.name].copy()
            if mode=='open':
                h.rotation_euler.z+=math.radians(-66 if '_LEFT_' in h.name else 66)
        bpy.context.view_layer.update()
        points=[o.matrix_world@Vector(c) for o in source_meshes for c in o.bound_box]
        lo=Vector(tuple(min(p[k] for p in points) for k in range(3)))
        hi=Vector(tuple(max(p[k] for p in points) for k in range(3)))
        center=(lo+hi)*.5
        L=max(hi-lo)
        data.ortho_scale=L*1.43
        for view,loc in [('three_quarter',Vector((1.27,-1.45,.69))),('side',Vector((2.02,-.07,.42)))]:
            cam.location=center+loc*L
            cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
            file=OUT/(name+'-REAL-'+mode+'-'+view+'.png')
            scene.render.filepath=str(file)
            bpy.ops.render.render(write_still=True)
            assert file.stat().st_size>35000,(file,file.stat().st_size)
            report.append({'model':name,'view':view,'mode':mode,'file':file.name,
                           'bytes':file.stat().st_size,'triangles':tris,
                           'actual_moving_hinges':len(hinges),
                           'render_engine':'Blender Cycles CPU native PBR NOT AI'})
            print('REAL BLENDER CYCLES PBR',name,mode,view,file,flush=True)
(OUT/'real_pbr_render_evidence.json').write_text(json.dumps(report,indent=2)+'\n')
assert len(report)==6
print('REAL CC0 BLENDER CYCLES SEDAN V2 CLOSE/OPEN PBR PROOF GREEN',flush=True)
