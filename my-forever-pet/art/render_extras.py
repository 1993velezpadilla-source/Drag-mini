# Original Blender assets for wearable layers and runner. No baked player, UI, or hazards in the bridge.
import bpy, math, sys, os
from mathutils import Vector
from math import pi
OUT=sys.argv[sys.argv.index("--")+1];os.makedirs(OUT,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=32;sc.cycles.use_denoising=True;sc.cycles.max_bounces=4
sc.world.color=(.26,.31,.42)
def mat(n,col,rough=.38,metal=0):
 m=bpy.data.materials.new(n);m.use_nodes=True;m.diffuse_color=(*col,1);b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*col,1);b.inputs['Roughness'].default_value=rough;b.inputs['Metallic'].default_value=metal;return m
navy=mat('navy',(.026,.05,.12));teal=mat('teal',(.05,.40,.45));cream=mat('cream',(.9,.85,.70));gold=mat('gold',(.98,.55,.055),.25,.55);wood=mat('timber',(.42,.20,.09));stone=mat('stone',(.48,.51,.58));green=mat('leaf',(.13,.46,.17));blue=mat('blue',(.08,.23,.63));red=mat('orange',(.83,.26,.09));black=mat('rubber',(.018,.02,.035));kibble=mat('kibble',(.52,.24,.055));glass=mat('tinted lenses',(.10,.22,.36),.18,.25)
def finish(o,m,bevel=0):
 o.data.materials.append(m)
 for p in o.data.polygons:p.use_smooth=True
 if bevel:
  q=o.modifiers.new('rounded','BEVEL');q.width=bevel;q.segments=3
  o.modifiers.new('normals','WEIGHTED_NORMAL')
 return o
def box(n,loc,d,m,b=.05,rot=None):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=n;o.dimensions=d
 if rot:o.rotation_euler=rot
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,m,b)
def ell(n,loc,s,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,location=loc);o=bpy.context.object;o.name=n;o.scale=s;return finish(o,m)
def cyl(n,loc,r,d,m,rot=None,r2=None):
 if r2 is None:bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=r,depth=d,location=loc)
 else:bpy.ops.mesh.primitive_cone_add(vertices=48,radius1=r,radius2=r2,depth=d,location=loc)
 o=bpy.context.object;o.name=n
 if rot:o.rotation_euler=rot
 return finish(o,m,.025)
def tor(n,loc,r,t,m,rot=None,scale=None):
 bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=12,location=loc,major_radius=r,minor_radius=t);o=bpy.context.object;o.name=n
 if rot:o.rotation_euler=rot
 if scale:o.scale=scale
 return finish(o,m)
def light(n,loc,power,col,size,target):
 d=bpy.data.lights.new(n,'AREA');d.energy=power;d.color=col;d.shape='DISK';d.size=size;o=bpy.data.objects.new(n,d);sc.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler();return o
bpy.ops.object.camera_add(location=(0,-8,0));cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=3.4;cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler();sc.camera=cam
light('warm key',(-3,-4,5),650,(1,.82,.65),4,(0,0,0));light('blue rim',(4,2,3),480,(.5,.72,1),3,(0,0,0));light('fill',(2,-4,0),260,(.9,.95,1),3,(0,0,0))
static=set(bpy.data.objects)
def clear():
 for o in list(bpy.data.objects):
  if o not in static:bpy.data.objects.remove(o,do_unlink=True)
def render(name,transparent=True,w=256,h=256):
 sc.render.resolution_x=w;sc.render.resolution_y=h;sc.render.resolution_percentage=100;sc.render.film_transparent=transparent
 sc.render.image_settings.file_format='PNG' if transparent else 'JPEG';sc.render.image_settings.color_mode='RGBA' if transparent else 'RGB';sc.render.filepath=os.path.join(OUT,name);bpy.ops.render.render(write_still=True)
def paw(x,y,z,m):
 ell('paw pad',(x,y,z),(.21,.06,.16),m)
 for i in range(4):ell('toe',(x+(i-1.5)*.14,y,z+.22+(.04 if i in [1,2] else 0)),(.065,.05,.08),m)
def shirt(formal=False,suit=False):
 m=navy if formal else teal if suit else cream
 box('body',(0,0,0),(1.45,.48,1.45),m,.20)
 for x in [-1,1]:box('sleeve',(x*.85,0,.38),(.63,.42,.65),m,.12,rot=(0,x*.35,0))
 if formal:
  box('dress shirt',(0,-.28,.18),(.49,.05,1.06),cream,.05)
  for x in [-1,1]:
   box('lapel',(x*.25,-.32,.35),(.19,.07,.65),black,.04,rot=(0,x*.40,0));ell('bow tie',(x*.15,-.36,.66),(.16,.06,.10),navy)
  for z in [.15,-.12,-.39]:ell('button',(0,-.35,z),(.05,.035,.05),gold)
 elif suit:
  box('control panel',(0,-.30,.17),(.62,.09,.48),navy,.07);ell('badge',(0,-.37,.17),(.13,.05,.13),gold)
 else:paw(0,-.32,.15,teal)
for i in range(8):
 clear()
 if i==0:
  ell('cap dome',(0,0,.22),(1.04,.57,.65),blue);box('bill',(0,-.63,-.23),(1.8,.76,.14),navy,.065);paw(0,-.55,.31,cream)
 elif i in [1,5]:
  for x in [-.65,.65]:
   tor('rim',(x,0,0),.55,.085,black if i==1 else gold,rot=(pi/2,0,0),scale=(1,.82,1));box('temple',(x*1.85,.23,.09),(.13,.55,.13),black,.04)
  box('bridge',(0,0,.03),(.32,.13,.12),black,.04)
 elif i in [2,3,7]:shirt(i==3,i==7)
 elif i==4:
  for x in [-.65,.65]:
   ell('shoe upper',(x,0,.05),(.54,.68,.37),blue);box('sole',(x,-.06,-.27),(1.05,1.15,.16),cream,.07)
   for z in [.07,.19,.31]:box('lace',(x,-.50,z),(.49,.065,.055),cream,.02)
 else:
  ell('knit cap',(0,0,.15),(.99,.53,.78),teal);box('cuff',(0,-.05,-.29),(1.9,.92,.34),navy,.13);ell('pom',(0,0,.92),(.21,.22,.23),cream)
 render('clothes_%d.png'%i,w=320,h=240)
clear();box('crate',(0,0,0),(1.78,1.3,1.65),wood,.09)
for x in [-.72,.72]:box('frame',(x,-.68,0),(.18,.12,1.65),gold,.025)
for z in [-.68,.68]:box('frame',(0,-.68,z),(1.78,.12,.15),gold,.025)
paw(0,-.77,0,cream);render('dash_crate.png')
clear()
for x in [-.76,.76]:box('upright',(x,0,-.20),(.24,.42,1.65),navy,.06)
box('hazard bar',(0,-.08,.56),(2.55,.42,.57),red,.08)
for x in [-.8,0,.8]:box('stripe',(x,-.31,.56),(.29,.05,.47),cream,.02,rot=(0,.5,0))
for x in [-.90,.90]:ell('warning light',(x,0,.97),(.17,.17,.20),gold)
render('dash_barrier.png')
clear();cyl('coin',(0,0,0),1.02,.22,gold,(pi/2,0,0));tor('rim',(0,-.15,0),.83,.075,gold,(pi/2,0,0));paw(0,-.24,-.04,cream);render('dash_coin.png')
clear();cyl('bowl',(0,0,-.27),.86,.53,blue,r2=1.05);tor('lip',(0,0,.02),.93,.09,teal)
for i in range(15):
 a=i*2.4;r=.75*math.sqrt((i+1)/15);ell('kibble',(r*math.cos(a),r*math.sin(a),.14),(.16,.14,.12),kibble)
cam.location=(0,-8,3);cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler();render('dash_snack.png')
clear()
# Perspective bridge, sky islands and arch. Moving gameplay entities are composited at runtime.
cam.location=(0,-7.6,3.5);cam.rotation_euler=(Vector((0,11,1.6))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='PERSP';cam.data.lens=25
sc.world.color=(.38,.52,.78)
light('sun',(-5,0,12),1700,(1,.87,.66),7,(0,8,0))
box('bridge deck',(0,10,-.26),(6.2,37,.5),wood,.08)
for j in range(36):box('deck plank',(0,j-7,.005),(6.0,.95,.06),wood,.018)
for side in [-1,1]:
 box('stone edge',(side*3.15,10,.05),(.33,37,.4),stone,.07)
 box('rail',(side*3.23,10,1.10),(.19,37,.18),wood,.05)
 for j in range(10):
  y=j*3.6-5;box('post',(side*3.22,y,.65),(.38,.38,1.45),stone,.07);box('post cap',(side*3.22,y,1.43),(.52,.52,.18),wood,.05)
  if j%2==0:
   cyl('planter',(side*3.75,y,.25),.32,.5,stone,r2=.44)
   for k in range(5):
    a=k*2*pi/5;ell('foliage',(side*3.75+.23*math.cos(a),y+.23*math.sin(a),.72),(.28,.22,.33),green)
  else:
   box('lantern stand',(side*3.24,y,2),(.12,.12,1.3),navy,.03);ell('lantern',(side*3.24,y,2.55),(.26,.26,.35),gold)
for side in [-1,1]:
 box('arch pillar',(side*3.16,12,2.0),(.70,.75,4.0),stone,.15)
for j in range(13):
 a=j*pi/12;box('arch stone',(3.16*math.cos(a),12,3.8+3.16*math.sin(a)),(.74,.85,.70),stone,.10,rot=(0,-a,0))
for i in range(7):
 x=(-1 if i%2 else 1)*(7+i%3*2.5);y=12+i*4
 cyl('floating island',(x,y,-1.6),1.6,3.4,stone,r2=2.6)
 cyl('grass top',(x,y,.23),2.5,.35,green)
 cyl('tower',(x,y,2),.82,3.4,cream)
 cyl('roof',(x,y,4.05),1.05,1.0,blue,r2=.15)
 for k in range(3):ell('cloud',(x+k*.8,y-2,-.5+i%2),(.9,.7,.38),cream)
render('dash_bridge.jpg',False,760,912)
# Reusable 3D props for all the other arcades and furniture inventory.
cam.location=(0,-8,2.0);cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3.5
for i in range(7):
 clear()
 if i==0:
  cyl('trunk',(0,0,-.5),.20,1.5,wood)
  for j in range(5):
   a=j*2*pi/5;ell('tree canopy',(.47*math.cos(a),.47*math.sin(a),.48),(.60,.49,.66),green)
 elif i==1:
  box('stall counter',(0,0,-.5),(2.1,.9,.83),wood,.08)
  for x in [-.85,.85]:box('stall post',(x,0,.25),(.12,.12,1.3),wood,.025)
  box('awning',(0,-.1,.98),(2.3,1.15,.23),blue,.07)
  for j in range(3):box('stripe',(-.74+j*.74,-.10,1.11),(.28,1.12,.035),cream,.01)
 elif i==2:
  pts=[((1 if k%2==0 else .44)*math.cos(pi/2+k*pi/5),0,(1 if k%2==0 else .44)*math.sin(pi/2+k*pi/5)) for k in range(10)]
  me=bpy.data.meshes.new('star');me.from_pydata(pts,[],[list(range(10))]);me.update();o=bpy.data.objects.new('star',me);sc.collection.objects.link(o);o.data.materials.append(gold);q=o.modifiers.new('depth','SOLIDIFY');q.thickness=.25;q=o.modifiers.new('round','BEVEL');q.width=.08;q.segments=3
 elif i==3:box('treasure chest',(0,0,-.1),(1.8,1.1,1.3),wood,.18);box('lock',(0,-.58,.13),(.42,.1,.40),gold,.06)
 elif i==4:ell('pond',(0,0,-.48),(1.4,.85,.17),teal);ell('rock',(.8,.1,-.35),(.36,.3,.23),stone)
 elif i==5:cyl('pillar',(0,0,0),.74,2.8,teal);cyl('pillar rim',(0,0,1.12),.85,.32,cream);cyl('pillar rim',(0,0,-1.12),.85,.32,cream)
 else:
  for j in range(5):ell('cloud',(-.9+j*.45,0,0),(.54,.45,.36+.1*(j%2)),cream)
 render('prop_%d.png'%i,True,192,192)
for i in range(6):
 clear()
 if i==0:ell('cap',(0,0,.18),(.88,.55,.65),gold);box('brim',(0,-.52,-.22),(1.8,.66,.15),navy,.07)
 elif i==1:
  for x in [-.43,.43]:ell('bow',(x,0,0),(.49,.20,.32),red)
  ell('knot',(0,-.16,0),(.19,.15,.19),gold)
 elif i==2:tor('halo',(0,0,0),.85,.12,gold,(pi/2,0,0),scale=(1,.70,1))
 elif i==3:cyl('bath',(0,0,-.25),1,.65,blue,r2=1.19);tor('rim',(0,0,.11),1.1,.09,cream);ell('water',(0,0,.12),(.92,.92,.06),teal)
 elif i==4:box('bed frame',(0,0,-.45),(2.1,1.6,.50),wood,.13);box('blanket',(0,0,-.10),(1.98,1.52,.35),blue,.16);ell('pillow',(0,.52,.12),(.72,.35,.19),cream);box('headboard',(0,.78,.25),(2.1,.2,1.14),wood,.13)
 else:
  cyl('planter',(0,0,-.7),.44,.7,wood,r2=.57)
  for j in range(5):
   a=j*2*pi/5;ell('leaf',(.45*math.cos(a),.45*math.sin(a),.30),(.30,.28,.48),green)
 render('item_%d.png'%i,True,192,192)
print('EXTRAS_RENDER_OK')
