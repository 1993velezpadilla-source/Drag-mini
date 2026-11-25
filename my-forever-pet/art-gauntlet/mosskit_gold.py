"""Original sculpted Mosskit candidate, editable master + separately tessellated mobile LOD.
No external model, photo plane or AI-generated render. Candidate only."""
import bpy, math, json, sys, hashlib
from pathlib import Path
from mathutils import Vector
from math import pi, sin, cos, sqrt
out=Path(sys.argv[sys.argv.index('--')+1]).resolve();out.mkdir(parents=True,exist_ok=True)
def clean():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def material(name,color,rough,metal=0):
 m=bpy.data.materials.get(name) or bpy.data.materials.new(name)
 m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF')
 p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m
lime=material('Mosskit | spring green',(.19,.56,.045),.35)
leaf=material('Mosskit | leaf edge',(.38,.72,.08),.42)
mint=material('Mosskit | soft belly',(.61,.83,.30),.48)
pink=material('Mosskit | rose paw pads',(.87,.25,.36),.43)
eye=material('Mosskit | obsidian eyes',(.025,.018,.042),.16)
white=material('Mosskit | eye highlights',(.98,.97,1),.30)
deep=material('Mosskit | mouth',(.12,.034,.060),.46)
# Coordinate convention: Blender -Y is front (Godot +Z), Z up.
def sculpt(name,pos,size,mat,detail,shape='round',tilt=0):
 u,v=detail;verts=[(0,0,size[2]*.5)];faces=[]
 for j in range(1,v):
  t=pi*j/v;z=cos(t);r=sin(t)
  if shape=='body': r*=1+.12*z-.055*z*z
  if shape=='ear': r*=1-.27*z+.08*sin(t*2)
  if shape=='foot': r*=1-.10*z
  for i in range(u):
   p=2*pi*i/u;x=cos(p)*r;y=sin(p)*r
   if shape=='body': y*=1+.05*cos(p*2);zv=z+.025*r*cos(p*2)
   else:zv=z
   verts.append((size[0]*.5*x,size[1]*.5*y,size[2]*.5*zv))
 verts.append((0,0,-size[2]*.5));bottom=len(verts)-1
 for i in range(u):faces.append((0,1+i,1+(i+1)%u))
 for j in range(v-2):
  a=1+j*u;b=a+u
  for i in range(u):faces.append((a+i,b+i,b+(i+1)%u,a+(i+1)%u))
 for i in range(u):faces.append((bottom,1+(v-2)*u+(i+1)%u,1+(v-2)*u+i))
 me=bpy.data.meshes.new(name+' sculpted surface');me.from_pydata(verts,[],faces);me.update()
 obj=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(obj)
 obj.location=pos;obj.rotation_euler.y=tilt;me.materials.append(mat)
 for p in me.polygons:p.use_smooth=True
 return obj
def make(high):
 clean()
 body=(112,72) if high else (44,28)
 large=(72,46) if high else (32,20)
 small=(44,28) if high else (18,12)
 tiny=(28,18) if high else (12,8)
 # rounded pear body, softly integrated cheeks and a broad back/tail silhouette.
 sculpt('body',(0,0,.84),(1.49,1.24,1.47),lime,body,'body')
 sculpt('belly_patch',(0,-.48,.57),(.84,.28,.74),mint,large)
 for side,tag in [(-1,'L'),(1,'R')]:
  sculpt('ear_'+tag,(side*.48,.015,1.61),(.43,.37,.78),lime,large,'ear',side*.36)
  sculpt('ear_inset_'+tag,(side*.49,-.139,1.61),(.25,.085,.50),pink,small,'ear',side*.36)
  sculpt('cheek_'+tag,(side*.43,-.45,.79),(.30,.21,.31),lime,small)
  sculpt('eye_'+tag,(side*.285,-.554,1.025),(.30,.16,.39),eye,large)
  sculpt('eye_glint_'+tag,(side*.285-.048,-.625,1.115),(.105,.045,.125),white,tiny)
  sculpt('blush_'+tag,(side*.46,-.51,.72),(.19,.055,.105),pink,small)
  sculpt('arm_'+tag,(side*.66,-.10,.57),(.29,.39,.50),lime,large,'ear',side*-.29)
  foot=sculpt('foot_'+tag,(side*.36,.01,.20),(.60,.66,.40),lime,large,'foot')
  sculpt('paw_main_'+tag,(side*.36,.304,.15),(.27,.075,.21),pink,small)
  for i in range(3):
   sculpt('paw_toe_'+tag+str(i),(side*.36+(i-1)*.108,.307,.26+(.035 if i==1 else 0)),(.09,.058,.093),pink,tiny)
 sculpt('nose',(0,-.619,.782),(.16,.075,.105),deep,small)
 sculpt('smile',(0,-.605,.675),(.20,.065,.082),deep,small)
 sculpt('tail',(0,.595,.68),(.43,.43,.43),lime,large)
 sculpt('tail_tip',(0,.735,.74),(.25,.18,.22),leaf,small)
 sculpt('leaf_tuft',(0,.02,1.63),(.24,.26,.34),leaf,small,'ear',-.32)
 # Parent pads to articulated feet, preserving world transforms for Godot import.
 bpy.context.view_layer.update()
 for tag in ['L','R']:
  foot=bpy.data.objects['foot_'+tag]
  for o in list(bpy.context.scene.objects):
   if o.name.startswith('paw_') and ('_'+tag in o.name):
    m=o.matrix_world.copy();o.parent=foot;o.matrix_world=m
def metrics():
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 bpy.context.view_layer.update()
 bb=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
 low=[min(p[i] for p in bb) for i in range(3)];high=[max(p[i] for p in bb) for i in range(3)]
 tris=0
 for o in meshes:
  o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
  assert all(math.isfinite(c) for v in o.data.vertices for c in v.co)
  assert len(o.data.materials)>0 and len(o.data.polygons)>0
 return {'triangles':tris,'mesh_objects':len(meshes),'materials':len({m.name for o in meshes for m in o.data.materials}),'bounds':[low,high],'parts':sorted(o.name for o in meshes),'dimensions':[high[i]-low[i] for i in range(3)]}
def export(label):
 m=metrics()
 blend=out/(label+'.blend');glb=out/(label+'.glb')
 bpy.ops.wm.save_as_mainfile(filepath=str(blend))
 bpy.ops.export_scene.gltf(filepath=str(glb),export_format='GLB',export_yup=True)
 m['sha256']=hashlib.sha256(glb.read_bytes()).hexdigest()
 m['bytes']=glb.stat().st_size
 return m
def render_views(label, m):
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=20
 scene.render.resolution_x=960;scene.render.resolution_y=960;scene.render.resolution_percentage=100
 scene.render.film_transparent=True;scene.render.image_settings.file_format='PNG'
 scene.world.color=(.25,.25,.25)
 scene.view_settings.view_transform='AgX'
 def light(name,pos,power,size,color):
  d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color
  o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,.9))-o.location).to_track_quat('-Z','Y').to_euler()
 light('Key',(-3,-4,5),420,3.0,(1,.87,.70))
 light('Fill',(3,-2,3),190,3.0,(.72,.87,1))
 light('Rim',(1,3,4),350,2.4,(.64,.82,1))
 cam_data=bpy.data.cameras.new('Gold review camera');cam_data.type='ORTHO';cam_data.ortho_scale=2.65
 cam=bpy.data.objects.new('Gold review camera',cam_data);scene.collection.objects.link(cam);scene.camera=cam
 center=Vector((0,0,(m['bounds'][0][2]+m['bounds'][1][2])*.5))
 for name,d in {'front':(0,-5,.12),'rear':(0,5,.12),'side':(5,0,.12),'front34':(3,-5,1.25),'rear34':(3,5,1.25)}.items():
  cam.location=center+Vector(d);cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
  scene.render.filepath=str(out/(label+'-'+name+'.png'));bpy.ops.render.render(write_still=True)
make(True);master=export('mosskit-master');render_views('mosskit-master',master)
make(False);mobile=export('mosskit-mobile');render_views('mosskit-mobile',mobile)
assert 30000<=master['triangles']<=350000,master['triangles']
assert 3000<=mobile['triangles']<=26000,mobile['triangles']
assert mobile['triangles']<master['triangles']*.40
assert master['parts']==mobile['parts']
for a,b in zip(master['dimensions'],mobile['dimensions']):assert abs(a-b)<.04
(out/'asset-report.json').write_text(json.dumps({'asset':'mosskit','source':'original authored parametric sculpt script; no third party source','master':master,'mobile':mobile,'art_approved':False,'android_approved':False},indent=2))
print('MOSSKit_MASTER_MOBILE_TECHNICAL_PASS_NOT_ART_APPROVED')
