import bpy, math, os, sys, json
from math import pi
OUT=os.path.abspath(sys.argv[sys.argv.index('--')+1]);os.makedirs(OUT,exist_ok=True)
def mat(name,rgb,metal=0,rough=.42):
 m=bpy.data.materials.new(name);m.diffuse_color=(*rgb,1);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*rgb,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough;return m
wood=mat('warm oak',(.25,.105,.045));wood2=mat('light oak',(.34,.163,.075));stone=mat('blue grey stone',(.35,.41,.49));cream=mat('sandstone',(.67,.54,.40));gold=mat('gold',(.98,.57,.07),.5,.26);green=mat('foliage',(.085,.36,.12));leaf=mat('leaf tips',(.30,.57,.12));blue=mat('navy blue',(.06,.13,.34));violet=mat('banner violet',(.25,.14,.52));amber=mat('amber',(.98,.51,.13));lime=mat('Mosskit body',(.13,.46,.024),0,.34);pink=mat('ear rose',(.95,.35,.49));dark=mat('deep plum',(.038,.024,.075),0,.20);white=mat('eye shine',(.97,.97,1));water=mat('water',(.13,.64,.89),.15,.21)
# Original wood texture baked into the GLB, not a painted screen.
def timber_texture():
 import random
 rng=random.Random(317)
 size=128
 im=bpy.data.images.new('Oak grain',width=size,height=size)
 pixels=[]
 for y in range(size):
  for x in range(size):
   g=.70+.095*math.sin(x*.47+2.0*math.sin(y*.12))+.065*math.sin(x*1.19+y*.018)+rng.uniform(-.025,.025)
   pixels.extend((g,g*.91,g*.79,1.0))
 im.pixels.foreach_set(pixels);im.pack()
 for m,tint in [(wood,(.52,.29,.13,1)),(wood2,(.65,.39,.19,1))]:
  # glTF base color texture supports direct Image Texture connections.
  node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=im
  m.node_tree.links.new(node.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
  # Keep materials distinct via separate tinted texture copies.
  copy=im.copy();copy.name=m.name+' baked grain'
  copy.pixels.foreach_set([v*tint[i%4] if i%4!=3 else 1.0 for i,v in enumerate(pixels)])
  copy.pack();node.image=copy
timber_texture()
def stone_texture(m,tint,seed):
 import random
 rng=random.Random(seed);size=128
 im=bpy.data.images.new(m.name+' patina',width=size,height=size)
 pixels=[]
 for y in range(size):
  for x in range(size):
   v=.84+.047*math.sin(x*.18+y*.11)+.042*math.sin(x*.51-y*.23)+rng.uniform(-.025,.025)
   pixels.extend((tint[0]*v,tint[1]*v,tint[2]*v,1))
 im.pixels.foreach_set(pixels);im.pack()
 node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=im
 m.node_tree.links.new(node.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
stone_texture(stone,(.57,.63,.71),91)
stone_texture(cream,(.84,.72,.53),93)
stats={}
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def finish(o,m,b=0):
 o.data.materials.append(m)
 if b:
  q=o.modifiers.new('bevel','BEVEL');q.width=b;q.segments=1 if b<=.025 else 2;q=o.modifiers.new('normals','WEIGHTED_NORMAL')
 for p in o.data.polygons:p.use_smooth=True
 return o
# input coordinates use Godot's x,y,z; convert to Blender x,-z,y.
def v(p):return (p[0],-p[2],p[1])
def box(p,size,m,b=.035):
 bpy.ops.mesh.primitive_cube_add(size=1,location=v(p));o=bpy.context.object;o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,m,b)
def ball(p,size,m):
 detail=max(size)
 segments,rings=(12,8) if detail<.24 else (20,12) if detail<.65 else (28,18)
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=v(p));o=bpy.context.object;o.scale=(size[0]/2,size[2]/2,size[1]/2);return finish(o,m)
def cyl(p,r1,r2,h,m,front=False):
 bpy.ops.mesh.primitive_cone_add(vertices=32,radius1=r1,radius2=r2,depth=h,location=v(p));o=bpy.context.object
 if front:o.rotation_euler.x=pi/2
 return finish(o,m,.022)
def ring(p,r,minor,m):
 bpy.ops.mesh.primitive_torus_add(major_segments=32,minor_segments=8,location=v(p),major_radius=r,minor_radius=minor);o=bpy.context.object;o.rotation_euler.x=pi/2;return finish(o,m)
def paw(p,m,s=1):
 x,y,z=p;ball((x,y,z),(.31*s,.24*s,.05*s),m)
 for i in range(4):ball((x+(i-1.5)*.11*s,y+.19*s+(.03*s if i in (1,2) else 0),z),(.095*s,.125*s,.05*s),m)
def flower(p,s=1):
 x,y,z=p
 for k in range(5):
  a=k*2*pi/5
  ball((x+.095*s*math.cos(a),y+.095*s*math.sin(a),z),(.14*s,.14*s,.055*s),white)
 ball((x,y,z+.032*s),(.115*s,.115*s,.065*s),gold)
def export(name,maxtri):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.convert(target='MESH')
 groups={}
 for o in list(bpy.context.scene.objects):
  if o.type=='MESH':groups.setdefault(o.data.materials[0].name,[]).append(o)
 for group in groups.values():
  bpy.ops.object.select_all(action='DESELECT')
  for o in group:o.select_set(True)
  bpy.context.view_layer.objects.active=group[0]
  if len(group)>1:bpy.ops.object.join()
  bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 total=0
 for o in bpy.context.scene.objects:
  if o.type=='MESH':
   o.data.calc_loop_triangles();total+=len(o.data.loop_triangles)
 assert 0<total<=maxtri,(name,total,maxtri)
 path=os.path.join(OUT,name+'.glb')
 result=bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',export_yup=True)
 assert 'FINISHED' in result and os.path.getsize(path)>1000,(name,result)
 stats[name]={'triangles':total,'materials':len(groups),'bytes':os.path.getsize(path),'triangle_cap':maxtri}
 print('GLB_OK',name,total,len(groups))

# The approved Mosskit and paws are never regenerated or modified here.
# New species use the exact same proportions, material shader and mesh primitives.
ROOT=OUT
OUT=os.path.join(ROOT,'creatures');os.makedirs(OUT,exist_ok=True)
accent_ink=mat('warm soft markings',(.18,.08,.07),0,.55)
palette=[(.13,.46,.024),(.65,.22,.36),(.47,.23,.075),(.07,.30,.54),(.055,.45,.68),(.23,.12,.52),(.37,.58,.66),(.67,.13,.31),(.80,.39,.075),(.15,.46,.23),(.30,.13,.63),(.42,.25,.13)]
def face(i):
 for side in [-1,1]:
  ball((side*.29,1.02,.54),(.33,.48,.16),dark)
  ball((side*.29-.05,1.13,.62),(.115,.14,.055),white)
  ball((side*.47,.78,.46),(.22,.12,.09),pink)
 if i==2:
  ball((0,.73,.60),(.51,.34,.25),cream)
  ball((0,.81,.735),(.18,.13,.08),dark)
  ball((0,.68,.735),(.15,.075,.045),dark)
 elif i in (8,11):
  o=cyl((0,.77,.65),.13,.025,.24,gold,True)
 else:
  ball((0,.72,.61),(.29,.25,.10),dark);ball((0,.65,.66),(.17,.085,.055),pink)
 if i in (1,11):
  for side in [-1,1]:
   for k in range(3):
    o=ball((side*(.51+k*.025),.72-k*.055,.48),(.20,.024,.035),accent_ink)
    o.rotation_euler.y=side*(.10+k*.13)
def paws(m):
 for side in [-1,1]:
  ball((side*.37,.20,.16),(.68,.40,.67),m)
  ball((side*.37,.24,.43),(.24,.16,.07),pink)
def ear(side,m):
 o=ball((side*.48,1.58,0),(.42,.72,.35),m);o.rotation_euler.y=side*.38
 o=ball((side*.48,1.60,.12),(.25,.49,.15),pink);o.rotation_euler.y=side*.38
for species in range(1,24):
 clear()
 i=species%12; secret=species>=12
 rgb=palette[i]
 if secret:rgb=tuple(min(1,c*.75+.09) for c in rgb)
 m=mat('plush body %d'%species,rgb,0,.34)
 accent=mat('plush highlight %d'%species,tuple(min(1,c*1.3+.06) for c in rgb),0,.44)
 ball((0,.85,0),(1.48,1.52,1.2),m)
 face(i)
 if i in [0,1,2,3,8,10,11]:paws(m)
 if i in [0,1,11]:
  for side in [-1,1]:ear(side,m)
  ball((0,.66,-.65),(.36,.36,.34),accent)
 elif i==2:
  for side in [-1,1]:
   o=ball((side*.69,1.20,-.03),(.40,.83,.40),accent);o.rotation_euler.y=side*.22
 elif i==3:
  for side in [-1,1]:
   o=cyl((side*.42,1.64,-.05),.17,.02,.50,gold);o.rotation_euler.y=side*.25
   o=ball((side*.80,.89,-.43),(.70,1.02,.23),blue);o.rotation_euler.y=side*.40
  ball((0,.50,-.71),(.36,.31,.70),accent)
 elif i==4:
  for side in [-1,1]:ball((side*.73,.81,-.16),(.55,.48,.21),gold)
  ball((0,.81,-.70),(.58,.75,.24),accent)
 elif i==5:
  for side in [-1,1]:
   o=ball((side*.42,1.66,0),(.13,.43,.13),accent);o.rotation_euler.y=side*.35
   ball((side*.52,1.86,0),(.23,.23,.23),pink)
 elif i==6:
  for side in [-1,0,1]:ball((side*.41,.20,0),(.48,.49,.59),accent)
 elif i==7:
  for k in range(8):
   a=k*pi/4
   ball((.57*math.cos(a),.18,.44*math.sin(a)),(.44,.34,.44),accent)
 elif i==8:
  for k in range(3):ball(((k-1)*.17,1.65-.09*abs(k-1),.03),(.24,.37,.24),pink)
  for side in [-1,1]:ball((side*.68,.77,-.15),(.32,.68,.43),gold)
 elif i==9:
  for side in [-1,1]:
   o=ball((side*.82,1.05,-.38),(.70,1.15,.16),white);o.rotation_euler.y=side*.43
   ball((side*.78,.55,-.33),(.54,.62,.16),water)
 elif i==10:
  for side in [-1,1]:
   o=ball((side*.79,1.12,0),(.64,.33,.26),accent);o.rotation_euler.y=side*.35
 # Distinct anatomical features and silhouette, not just recolors of one sphere.
 if i==1:
  for k in range(5):
   a=k*.48
   ball((.55+.33*math.sin(a),.30+.29*(1-math.cos(a)),-.50-k*.06),(.26,.26,.28),accent)
 elif i==2:
  ball((0,.43,.30),(.70,.55,.34),cream)
  for side in [-1,1]:ball((side*.58,.46,.09),(.34,.43,.40),m)
 elif i==3:
  for k in range(4):cyl((0,1.52-k*.23,-.57-k*.025),.13,.015,.25,gold)
  for side in [-1,1]:
   for k in range(3):ball((side*(.75+k*.13),.91-k*.19,-.48),(.29,.40,.15),accent)
 elif i==4:
  for side in [-1,1]:
   for k in range(3):ball((side*(.56-k*.10),.53+k*.19,.39),(.12,.17,.055),accent)
  ball((0,1.40,-.04),(.25,.40,.52),gold)
 elif i==6:
  for side in [-1,1]:ball((side*.60,.55,.03),(.43,.40,.32),accent)
 elif i==7:
  for k in range(8):
   a=k*pi/4
   for j in range(2):ball(((.58+j*.09)*math.cos(a),.19,.48*math.sin(a)+j*.05),(.12,.10,.12),pink)
 elif i==8:
  for k in range(5):
   o=ball(((k-2)*.18,.96+abs(k-2)*.08,-.64),(.30,.70,.23),[gold,accent,blue][k%3])
   o.rotation_euler.y=(k-2)*.22
 elif i==9:
  for side in [-1,1]:
   for j in range(3):ball((side*(.75+j*.12),1.30-j*.15,-.30),(.18,.20,.08),gold)
  flower((0,1.48,.31),1.8)
 elif i==10:
  for side in [-1,1]:flower((side*.43,1.46,.29),1.1)
 elif i==11:
  for side in [-1,1]:
   for j in range(3):ball((side*(.60-j*.10),.42+j*.19,.30),(.24,.24,.10),accent)
 if secret:
  if i in (0,2,3,8):
   for side in [-1,1]:
    o=cyl((side*.43,1.71,-.06),.14,.025,.59,gold);o.rotation_euler.y=side*.33
    if i==0:ball((side*.63,1.88,-.04),(.33,.24,.20),accent)
  elif i in (4,7):
   for side in [-1,1]:
    for k in range(3):ball((side*(.63+k*.12),1.21-k*.16,-.32),(.30,.36,.17),gold)
  else:
   for side in [-1,1]:
    o=ball((side*.82,1.15,-.42),(.65,.95,.20),accent);o.rotation_euler.y=side*.30
    ball((side*.88,1.38,-.35),(.22,.30,.08),gold)
  ball((0,1.38,.47),(.20,.25,.10),gold)
 # Apply species-specific proportions to the complete sculpt, keeping features aligned.
 profiles=[(1,1,1),(1.05,.94,.91),(.94,1.04,1.08),(1.04,1.12,1.12),(1.22,.78,1.02),(.90,1.17,.92),(.94,1.12,.92),(1.18,.82,1.08),(.94,1.13,1.05),(.91,1.17,.86),(.87,1.19,.94),(1.06,1.02,1.02)]
 from mathutils import Matrix
 sx,sy,sz=profiles[i]
 deform=Matrix.Diagonal((sx,sz,sy,1))
 for ob in list(bpy.context.scene.objects):
  if ob.type=='MESH':ob.matrix_world=deform@ob.matrix_world
 export('species_%02d'%species,42000)
with open(os.path.join(OUT,'creature-metrics.json'),'w') as f:json.dump(stats,f,indent=2)
# Render the actual approved GLB plus feet, and each new mesh, for 2D arcade and Petpedia.
# Orthographic portrait is rendered from the GLB itself; no alternate Mosskit mesh.
OUT=ROOT
from mathutils import Vector
for species in range(24):
 clear()
 if species==0:
  bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT,'mosskit.glb'))
  for side in [-1,1]:
   bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT,'foot.glb'))
   for ob in bpy.context.selected_objects:
    if ob.parent is None:
     ob.location+=Vector((side*.37,-.16,.20))
 else:bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT,'creatures','species_%02d.glb'%species))
 sc=bpy.context.scene
 sc.render.engine='CYCLES';sc.cycles.samples=20;sc.cycles.use_denoising=True
 sc.render.resolution_x=384;sc.render.resolution_y=384;sc.render.resolution_percentage=100
 sc.render.film_transparent=True;sc.render.image_settings.file_format='PNG';sc.render.image_settings.color_mode='RGBA'
 sc.world.color=(.30,.33,.44)
 # Frame actual evaluated imported geometry, including tails, wings and ears.
 bpy.context.view_layer.update()
 deps=bpy.context.evaluated_depsgraph_get()
 points=[ob.matrix_world@Vector(corner) for original in sc.objects if original.type=='MESH' for ob in [original.evaluated_get(deps)] for corner in ob.bound_box]
 assert points,('empty creature',species)
 lower=Vector(tuple(min(v[k] for v in points) for k in range(3)))
 upper=Vector(tuple(max(v[k] for v in points) for k in range(3)))
 center=(lower+upper)*.5
 direction=Vector((0,-6.8,1.15)).normalized()
 bpy.ops.object.camera_add(location=center+direction*8);cam=bpy.context.object
 cam.rotation_euler=(-direction).to_track_quat('-Z','Y').to_euler()
 bpy.context.view_layer.update()
 local=[cam.matrix_world.inverted()@v for v in points]
 xmin,xmax=min(v.x for v in local),max(v.x for v in local)
 ymin,ymax=min(v.y for v in local),max(v.y for v in local)
 cam.location+=cam.matrix_world.to_3x3()@Vector(((xmin+xmax)*.5,(ymin+ymax)*.5,0))
 cam.data.type='ORTHO';cam.data.ortho_scale=max(xmax-xmin,ymax-ymin)/.80;sc.camera=cam
 bpy.context.view_layer.update()
 from bpy_extras.object_utils import world_to_camera_view
 projected=[world_to_camera_view(sc,cam,v) for v in points]
 assert all(.085<=v.x<=.915 and .085<=v.y<=.915 for v in projected),('portrait framing',species)
 print('PORTRAIT_FRAME_OK',species,round(cam.data.ortho_scale,3),flush=True)
 for loc,power,col in [((-3,-4,5),550,(1,.85,.70)),((3,-3,2),300,(.65,.82,1)),((2,3,4),650,(.65,.80,1))]:
  d=bpy.data.lights.new('studio','AREA');d.energy=power;d.color=col;d.shape='DISK';d.size=4
  ob=bpy.data.objects.new('studio',d);sc.collection.objects.link(ob);ob.location=loc
  ob.rotation_euler=(center-ob.location).to_track_quat('-Z','Y').to_euler()
 sc.render.filepath=os.path.join(ROOT,'pet_%d.png'%species)
 bpy.ops.render.render(write_still=True)
 print('DASH_STYLE_PORTRAIT_OK',species,flush=True)
