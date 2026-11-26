"""Independent Blender reimport and three-view model review. No automatic art approval."""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:]
root=Path(args[0]); output=Path(args[1]);output.mkdir(parents=True,exist_ok=True)
catalog=json.loads((root/'catalog-audit.json').read_text())['assets']
expected={f'dungeon_{biome}_{part}' for biome in ('forest','reef','star') for part in ('wall','shrine','cluster','rock_0','rock_1','rock_2','landmark','detail','span','dais','corner','terrace','floor_detail','threshold','exterior','life','vista','habitat','understory')}
expected.update('dungeon_'+name for name in ('chest','stairs','berry','material','spring','coin','star_crystal_habitat','star_ruin_habitat','star_cloud_habitat'))
assert expected=={p.stem for p in root.glob('dungeon_*.glb')},'dungeon catalog mismatch'
report={}
for name in sorted(expected):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 assert 'FINISHED' in bpy.ops.import_scene.gltf(filepath=str(root/(name+'.glb')))
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
 assert objects,name
 bounds=[];triangles=0;materials=set();tiny_faces=0
 for obj in objects:
  mesh=obj.data;mesh.calc_loop_triangles()
  triangles+=len(mesh.loop_triangles)
  materials.update(m.name for m in mesh.materials if m)
  for vert in mesh.vertices:
   pos=obj.matrix_world@vert.co
   assert all(math.isfinite(x) for x in pos),name
   bounds.append(pos)
  tiny_faces+=sum(1 for f in mesh.polygons if f.area<1e-9)
 low=Vector(tuple(min(p[i] for p in bounds) for i in range(3)))
 high=Vector(tuple(max(p[i] for p in bounds) for i in range(3)))
 size=high-low;center=(high+low)*.5
 assert 0<triangles<=catalog[name]['cap'],(name,triangles)
 assert triangles==catalog[name]['triangles'],(name,triangles,catalog[name]['triangles'])
 assert len(materials)>=2,(name,'single material')
 assert tiny_faces==0,(name,'degenerate exported faces',tiny_faces)
 normal_materials=set()
 for obj in objects:
  for material in obj.data.materials:
   if material and material.use_nodes and any(n.type=='NORMAL_MAP' for n in material.node_tree.nodes):normal_materials.add(material.name)
 if name.endswith('_span'):
  assert len(normal_materials)>=2,(name,'missing imported normal maps',normal_materials)
 limit=3.4 if name.endswith(('_landmark','_span','_terrace','_exterior','_vista','_habitat')) else 2.5
 assert all(.02<x<limit for x in size),(name,list(size))
 assert low.z>=-.12 and high.z<=(3.1 if name.endswith(('_landmark','_exterior','_vista','_habitat')) else 1.8),(name,list(low),list(high))
 scene=bpy.context.scene
 scene.render.engine='BLENDER_WORKBENCH'
 scene.render.resolution_x=384;scene.render.resolution_y=384;scene.render.resolution_percentage=100
 scene.render.image_settings.file_format='PNG'
 sh=scene.display.shading;sh.light='STUDIO';sh.color_type='TEXTURE';sh.show_shadows=True;sh.show_cavity=True;sh.cavity_type='BOTH';sh.show_specular_highlight=True
 sh.background_type='WORLD'
 if scene.world is None:scene.world=bpy.data.worlds.new('review backdrop')
 scene.world.color=(.075,.085,.10)
 cam_data=bpy.data.cameras.new('Review camera');cam=bpy.data.objects.new('Review camera',cam_data);scene.collection.objects.link(cam);scene.camera=cam
 cam_data.type='ORTHO';cam_data.ortho_scale=max(size)*1.85
 for view,direction in [('front',(2,-3,2)),('reverse',(-2,3,1.8)),('overhead',(0,-.6,4))]:
  cam.location=center+Vector(direction).normalized()*4
  cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
  scene.render.filepath=str(output/(name+'-'+view+'.png'))
  bpy.ops.render.render(write_still=True)
  assert Path(scene.render.filepath).stat().st_size>1000,(name,view)
 if name.endswith('_span'):
  scene.render.engine='CYCLES';scene.cycles.samples=16
  scene.render.resolution_x=640;scene.render.resolution_y=480
  scene.world.use_nodes=True
  scene.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.18,.22,.29,1)
  scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.35
  for label,offset,power,color,light_size in [('key',(2,-3,4),450,(1,.88,.72),3),('fill',(-3,-1,2),180,(.65,.81,1),3),('rim',(0,3,3),300,(.8,.85,1),2)]:
   light_data=bpy.data.lights.new(label,'AREA');light_data.energy=power;light_data.color=color;light_data.shape='DISK';light_data.size=light_size
   light=bpy.data.objects.new(label,light_data);scene.collection.objects.link(light);light.location=center+Vector(offset)
   light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
  cam.location=center+Vector((1,-3,1.9)).normalized()*4
  cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
  cam_data.ortho_scale=max(high-low)*1.5
  scene.render.filepath=str(output/(name+'-pbr.png'))
  bpy.ops.render.render(write_still=True)
  assert Path(scene.render.filepath).stat().st_size>1000,(name,'PBR render')
 report[name]={'triangles':triangles,'materials':sorted(materials),'bounds':[list(low),list(high)],'tiny_faces':tiny_faces,'normal_mapped_materials':sorted(normal_materials),'three_views':True,'technical_pass':True,'art_approved':False}
 print('DUNGEON_BLENDER_REIMPORT_PASS',name,triangles,len(materials),'tiny_faces',tiny_faces)
(output/'asset-review.json').write_text(json.dumps({'assets':report,'count':len(report),'art_approved':False,'note':'Independent geometry checks and render evidence; aesthetic and Android device approval remain separate.'},indent=2))
print('DUNGEON_ART_REVIEW_PASS',len(report))
