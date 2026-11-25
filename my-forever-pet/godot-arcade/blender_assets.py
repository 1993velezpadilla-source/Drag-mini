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
 segments,rings=(10,6) if detail<.24 else (14,8) if detail<.65 else (20,12)
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
clear()
box((0,-.23,0),(6.65,.45,18),wood)
for i in range(18):
 for j in range(3):
  box(((j-1)*2.12,.005,-8.5+i),(2.11,.065,.985),wood if (i+j)%3==0 else wood2,.012)
for side in [-1,1]:
 box((side,.055,0),(.065,.03,18),cream,.01)
 box((side*3.37,.12,0),(.38,.50,18),stone)
 box((side*3.5,1.26,0),(.20,.18,18),wood2)
 box((side*3.37,.41,0),(.43,.085,18),cream,.015)
 box((side*3.48,1.36,0),(.23,.045,18),gold,.008)
 for z in [-8,-4,0,4,8]:
  box((side*3.50,.76,z),(.14,1.03,.16),blue,.02)
  ball((side*3.50,.77,z+.10),(.22,.22,.06),gold)
 for j in range(3):
  z=-6+j*6;box((side*3.5,.73,z),(.39,1.46,.39),stone,.065);box((side*3.5,1.46,z),(.52,.17,.52),wood2)
  if j%2==0:
   box((side*3.5,1.92,z),(.12,1.0,.12),blue);box((side*3.5,2.40,z),(.43,.13,.43),blue)
   cyl((side*3.5,2.68,z),.21,.29,.48,amber)
   for dx in [-.18,.18]:
    for dz in [-.18,.18]:box((side*3.5+dx,2.68,z+dz),(.045,.49,.045),blue,.012)
   cyl((side*3.5,3.02,z),.34,.05,.24,blue)
   cyl((side*3.5,2.44,z),.28,.28,.07,gold)
   cyl((side*3.5,2.92,z),.29,.29,.07,gold)
   ball((side*3.5,3.17,z),(.14,.20,.14),gold)
   box((side*3.5,1.7,z-.35),(.08,.85,.48),blue)
   box((side*3.5,1.31,z-.35),(.095,.065,.51),gold)
   for dz in [-.20,.20]:box((side*3.5,1.7,z-.35+dz),(.095,.80,.035),gold)
   # A front-facing pennant badge reads from the gameplay camera.
   box((side*3.5,1.92,z+.16),(.44,.62,.035),blue,.025)
   paw((side*3.5,1.87,z+.19),gold,.55)
  else:
   cyl((side*3.67,.41,z),.32,.44,.56,stone)
   for k in range(5):
    a=k*2*pi/5;ball((side*3.67+.24*math.cos(a),.90,z+.24*math.sin(a)),(.58,.58,.58),leaf if k%2 else green)
   for k in range(3):flower((side*3.67+.22*math.cos(k*2.1),1.05+.08*(k%2),z+.28*math.sin(k*2.1)+.15),.95)
export('bridge',110000)
clear()
for side in [-1,1]:
 box((side*3.3,2,0),(.72,4,.78),stone,.10)
 for y in [.25,1.1,2.0,2.9,3.8]:box((side*3.3,y,0),(.83,.12,.89),cream,.025)
 for y in [.52,3.48]:box((side*3.3,y,.46),(.69,.12,.085),gold,.015)
 box((side*3.3,2.15,.41),(.35,1.55,.11),blue,.055)
 paw((side*3.3,2.55,.49),gold,.87)
for j in range(13):
 a=j*pi/12;o=box((3.3*math.cos(a),3.8+3.3*math.sin(a),0),(.76,.91,.89),cream,.035);o.rotation_euler.y=-a
 if j%2==0:
  for k in range(3):ball((3.3*math.cos(a)+.22*(k-1),4.03+3.3*math.sin(a),.25),(.60,.42,.61),green if k%2 else leaf)
cyl((0,7.15,.48),.43,.43,.14,violet,True);paw((0,7.13,.59),gold,.95)
for side in [-1,1]:
 for j in range(8):
  yy=.5+j*.45
  ball((side*(3.25+.10*math.sin(j)),yy,.46),(.34,.22,.28),leaf if j%2 else green)
  if j%3==0:flower((side*3.25,yy,.64),1.05)
for j in range(1,13,2):
 a=j*pi/12;flower((3.3*math.cos(a),4.08+3.3*math.sin(a),.48),1.1)
 # Small golden hanging pennants below the arch, clear of the runner.
for side in [-1,1]:
 x=side*1.93
 box((x,5.62,.12),(.65,.88,.08),blue,.03)
 box((x,5.20,.18),(.70,.06,.04),gold,.01)
 paw((x,5.52,.18),gold,.72)
export('arch',85000)
clear()
cyl((0,-1.9,0),.50,2.7,3.8,stone);cyl((0,.05,0),2.69,2.69,.35,green)
# Irregular rock silhouettes and a raised sandstone terrace.
for j in range(8):
 a=j*pi/4
 ball((math.cos(a)*2.13,-.65-((j%3)*.18),math.sin(a)*2.13),(.95,1.75,.84),stone)
box((0,.28,-.30),(3.15,.32,2.30),cream,.09)
cyl((0,1.7,0),.92,.85,3.4,cream);cyl((0,3.88,0),1.16,.05,1.4,blue)
for i in range(4):
 a=i*pi/2;box((.89*math.cos(a),2.4,.89*math.sin(a)),(.22,.62,.22),gold)
for k in range(6):
 a=k*pi/3;ball((1.88*math.cos(a),.56,1.88*math.sin(a)),(.94,.83,.94),green if k%2 else leaf)
for i in range(3):
 x=1.2+i*.24;ball((x,-1.7,2.24-i*.19),(.31,3.1,.23),water)
for side in [-1,1]:
 cyl((side*1.15,1.02,-.65),.53,.48,2.0,cream)
 cyl((side*1.15,2.34,-.65),.68,.04,.85,blue)
 box((side*1.15,1.40,-.13),(.13,.35,.055),gold,.02)
for i in range(3):ball((-1.8+i*.8,-1.1,1.5), (1.7,.56,1.1),white)
for side in [-1,1]:
 for j in range(3):
  x=side*(1.55+j*.18);z=.67-j*.63
  cyl((x,.61,z),.065,.045,.78,wood)
  ball((x,1.16,z),(.64,.90,.65),green if j%2 else leaf)
  if j==1:flower((x,.49,z+.18),1.1)
export('island',55000)
clear()
ball((0,.85,0),(1.48,1.52,1.2),lime)
for side in [-1,1]:
 o=ball((side*.48,1.58,0),(.42,.72,.35),lime);o.rotation_euler.y=side*.38
 o=ball((side*.48,1.60,.12),(.25,.49,.15),pink);o.rotation_euler.y=side*.38
 ball((side*.29,1.02,.54),(.33,.48,.16),dark);ball((side*.29-.05,1.13,.62),(.115,.14,.055),white)
 ball((side*.47,.78,.46),(.22,.12,.09),pink)
ball((0,.72,.61),(.29,.25,.10),dark);ball((0,.65,.66),(.17,.085,.055),pink)
ball((0,.66,-.65),(.36,.36,.34),lime)
# Signature leafy ears/back tufts, subtle green gradient patches, and plush tail tip.
softlime=mat("Mosskit leaf highlights",(.32,.67,.07),0,.44)
for side in [-1,1]:
 o=ball((side*.39,1.34,-.44),(.29,.32,.16),softlime);o.rotation_euler.y=side*.30
 ball((side*.16,.47,-.55),(.18,.23,.08),softlime)
ball((0,.73,-.77),(.25,.25,.13),softlime)
ball((0,1.62,-.09),(.25,.38,.24),softlime)
export('mosskit',26000)
clear();ball((0,0,0),(.68,.40,.67),lime);paw((0,-.08,.30),pink,.64);export('foot',7000)
clear();box((0,.45,0),(1.3,.9,.9),wood,.07)
for x in [-.55,.55]:box((x,.45,.47),(.14,.86,.07),wood2)
for y in [.10,.80]:box((0,y,.47),(1.25,.12,.08),wood2)
for x in [-.57,.57]:
 for y in [.12,.78]:
  box((x,y,.525),(.19,.16,.045),stone,.025)
  ball((x,y,.555),(.055,.055,.025),gold)
for y in [.29,.60]:box((0,y,.468),(1.10,.018,.018),wood2,.005)
paw((0,.43,.52),cream,.8);export('crate',14000)
clear()
for x in [-.65,.65]:
 box((x,.75,0),(.2,1.5,.30),blue,.045);ball((x,1.82,0),(.24,.27,.24),gold)
box((0,1.42,0),(1.52,.48,.32),red if 'red' in globals() else mat('hazard red',(.58,.035,.055)),.06)
for x in [-.53,-.18,.18,.53]:
 o=box((x,1.42,.175),(.23,.43,.04),cream,.012);o.rotation_euler.y=.45
paw((0,1.37,.20),gold,.57);export('barrier',14000)
clear();cyl((0,.75,0),.31,.31,.12,gold,True);ring((0,.75,.075),.26,.025,gold);paw((0,.74,.10),cream,.55);export('coin',7000)
clear();cyl((0,.68,0),.30,.39,.28,violet);cyl((0,.83,0),.35,.35,.035,wood)
for i in range(8):
 a=i*2.4;r=.24*math.sqrt((i+1)/8);ball((r*math.cos(a),.88,r*math.sin(a)),(.16,.11,.15),amber)
export('snack',10000)

# Distinct power-up silhouettes. No gameplay art baked into background.
red=mat('magnet enamel',(.66,.035,.05),.1,.26)
cyan=mat('shield crystal',(.035,.46,.75),.15,.25)
clear()
for i in range(11):
 a=pi+i*pi/10
 ball((.37*math.cos(a),.90+.37*math.sin(a),0),(.22,.24,.22),red)
for side in [-1,1]:
 box((side*.37,1.04,0),(.22,.28,.22),red,.035)
 box((side*.37,1.22,0),(.24,.15,.24),cream,.035)
export('magnet',18000)
clear()
ball((0,.9,0),(.91,1.04,.25),cyan)
ring((0,.9,.12),.37,.045,gold)
paw((0,.88,.16),cream,.8)
export('shield',10000)
clear()
for side in [-1,1]:
 cyl((side*.22,.85+side*.12,0),.32,.32,.12,gold,True)
 ring((side*.22,.85+side*.12,.075),.26,.025,gold)
export('double',9000)
clear()
box((0,.13,0),(1.34,.26,1.55),blue,.12)
# Actual chevron vertices: point toward Godot -Z (away from player).
for z in [-.30,.30]:
 pts=[(-.48,z+.16),(0,z-.28),(.48,z+.16),(.35,z+.26),(0,z-.06),(-.35,z+.26)]
 me=bpy.data.meshes.new('forward turbo chevron')
 me.from_pydata([v((x,.29,zz)) for x,zz in pts],[],[(0,1,2,3,4,5)])
 me.update();o=bpy.data.objects.new('forward turbo chevron',me);bpy.context.collection.objects.link(o);o.data.materials.append(cyan)
 # Ensure upward-facing normals even after coordinate conversion.
 bpy.context.view_layer.objects.active=o
 if me.polygons[0].normal.z<0: me.polygons[0].flip()
export('boost',6000)

# Premium obstacle silhouettes, shared palette and explicit dimensions.
steel=mat('brushed gunmetal',(.105,.15,.22),.65,.29)
signal=mat('signal amber',(.98,.49,.045),.1,.20)
bs=signal.node_tree.nodes.get('Principled BSDF')
bs.inputs['Emission Color'].default_value=(1,.42,.035,1)
bs.inputs['Emission Strength'].default_value=.65
# Warm lantern glass and jewel-like pickups retain visible highlights.
for m, strength in [(amber,.28),(gold,.12),(water,.12)]:
 b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Emission Color'].default_value=m.diffuse_color;b.inputs['Emission Strength'].default_value=strength
def fittings(h,depth):
 for x in [-.67,.67]:
  for y in [.14,h-.13]:
   box((x,y,depth),(.18,.16,.06),steel,.025)
   ball((x,y,depth+.035),(.07,.07,.04),gold)
clear()
box((0,1.38,0),(1.48,2.76,1.72),steel,.08)
box((0,1.40,.89),(1.25,2.20,.06),wood,.04)
for y in [.43,.82,1.20,1.58,1.96,2.34]:
 box((0,y,.93),(1.15,.035,.035),wood2,.008)
for x in [-.56,.56]:
 for z in [-.57,.57]:cyl((x,.26,z),.26,.26,.24,dark)
 box((x,.53,.95),(.24,.20,.10),signal,.04)
box((0,.18,.98),(1.5,.20,.16),gold,.035)
paw((0,1.35,.97),cream,1.8)
fittings(2.76,.94)
export('cart',18000)
clear()
box((0,1.55,0),(1.52,3.10,.84),steel,.10)
box((0,1.55,.45),(1.24,2.72,.07),wood,.035)
for angle in [-.75,.75]:
 o=box((0,1.62,.51),(.24,1.46,.10),gold,.035);o.rotation_euler.y=angle
fittings(3.1,.49)
for x in [-.60,.60]:ball((x,2.98,.48),(.18,.18,.10),signal)
export('tall',15000)
clear()
for x in [-.65,.65]:
 box((x,.29,0),(.22,.58,.30),steel,.035)
 box((x,.08,0),(.34,.16,.46),steel,.035)
box((0,.57,0),(1.50,.32,.31),red,.055)
for x in [-.48,-.12,.24,.55]:
 o=box((x,.57,.18),(.20,.31,.035),white,.008);o.rotation_euler.y=.45
for x in [-.61,.61]:ball((x,.76,0),(.16,.13,.18),signal)
export('low_bar',12000)
# Fantasy sky decorations are separate, lightweight geometry.
clear()
ball((0,0,0),(3.6,1.45,1.50),cream)
for x in [-1.18,-.58,0,.58,1.18]:
 s=math.sqrt(max(.1,1-(x/1.8)**2))
 ball((x,0,0),(.28,1.50*s,1.54*s),gold if abs(x)>.1 else violet)
box((0,-.94,0),(1.6,.48,.70),wood2,.12)
for x in [-.58,.58]:
 box((x,-.52,.26),(.055,.78,.055),gold,.012)
 box((x,-.52,-.26),(.055,.78,.055),gold,.012)
box((1.48,.05,0),(.64,.82,.13),violet,.08)
paw((0,-.05,.79),violet,1.5)
export('airship',18000)
clear()
# Broad multicolour sky arch, seven continuous low-poly ribbons.
for j,c in enumerate([(1,.14,.16),(1,.48,.10),(1,.82,.16),(.20,.83,.31),(.12,.68,1),(.22,.30,.88),(.56,.23,.83)]):
 m=mat('rainbow band '+str(j),c,0,.7)
 b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Emission Color'].default_value=(*c,1);b.inputs['Emission Strength'].default_value=.18
 r=12-j*.21;verts=[];faces=[]
 for k in range(49):
  a=pi*k/48
  for rr in [r,r-.20]:verts.append(v((rr*math.cos(a),rr*math.sin(a),0)))
 for k in range(48):faces.append((k*2,k*2+1,k*2+3,k*2+2))
 me=bpy.data.meshes.new('rainbow ribbon');me.from_pydata(verts,[],faces);me.update()
 o=bpy.data.objects.new('rainbow ribbon',me);bpy.context.collection.objects.link(o);o.data.materials.append(m)
export('rainbow',1800)
clear()
timeblue=mat('time crystal',(.08,.62,.88),.15,.24)
ring((0,.92,0),.42,.065,gold)
ball((0,.92,0),(.69,.69,.22),timeblue)
box((0,1.04,.15),(.065,.28,.05),white,.02)
o=box((.12,.92,.15),(.26,.065,.05),white,.02)
export('time_orb',9000)
clear()
for j in range(5):
 ring((0,.36+j*.20,0),.28,.055,gold)
box((0,.26,0),(.77,.14,.77),blue,.07)
box((0,1.25,0),(.72,.16,.72),violet,.08)
export('spring',12000)
clear()
ring((0,2.05,0),.65,.075,gold)
ring((0,2.05,.035),.76,.026,cyan)
for a in [0,pi/2,pi,3*pi/2]:
 ball((.65*math.cos(a),2.05+.65*math.sin(a),.04),(.15,.15,.10),white)
export('sky_ring',7000)
clear()
gemmat=mat('violet crystal',(.50,.10,.88),.25,.20)
cyl((0,1.10,0),.37,.04,.40,gemmat)
cyl((0,.70,0),.04,.37,.40,gemmat)
ring((0,.90,0),.45,.035,gold)
export('gem',6000)
# Rescue creature: a tiny blue-winged original sky pet, also used as a temporary companion.
clear()
rescueblue=mat('sky pet blue',(.08,.45,.78),0,.27)
ball((0,.48,0),(.77,.72,.66),rescueblue)
for side in [-1,1]:
 ball((side*.31,.78,0),(.25,.44,.22),cream)
 ball((side*.39,.47,-.03),(.36,.37,.18),white)
 ball((side*.16,.54,.28),(.13,.18,.06),dark)
 ball((side*.16-.025,.59,.31),(.045,.055,.025),white)
ball((0,.42,.32),(.14,.10,.05),pink)
ball((0,.40,-.32),(.20,.20,.20),cream)
export('rescue',14000)
clear()
# Three-charge impact power, recognizable gold star in a purple shell.
star=mat('impact gold',(.99,.55,.04),.25,.24)
verts=[];faces=[]
for z in [-.10,.10]:
 for i in range(10):
  a=pi/2+i*pi/5;r=.46 if i%2==0 else .23
  verts.append(v((r*math.cos(a),.94+r*math.sin(a),z)))
faces.append(tuple(range(9,-1,-1)));faces.append(tuple(range(10,20)))
for i in range(10): faces.append((i,(i+1)%10,(i+1)%10+10,i+10))
me=bpy.data.meshes.new('impact star');me.from_pydata(verts,[],faces);me.update()
o=bpy.data.objects.new('impact star',me);bpy.context.collection.objects.link(o);o.data.materials.append(star)
ring((0,.94,0),.56,.055,violet)
export('smash',4000)
# Original premium world-expansion models. All scenery remains real mesh geometry.
clear()
surfmetal=mat('surf midnight alloy',(.07,.13,.29),.48,.26)
surflight=mat('surf ion rails',(.035,.75,.98),.18,.21)
b=surflight.node_tree.nodes.get('Principled BSDF');b.inputs['Emission Color'].default_value=(.035,.75,.98,1);b.inputs['Emission Strength'].default_value=.8
def deck(y):
 ball((0,y,0),(1.18,.20,2.35),surfmetal)
 box((0,y+.10,0),(.73,.07,1.45),blue,.035)
 for x in [-.48,.48]:
  ball((x,y,-.05),(.10,.13,1.84),surflight)
 for z in [-.84,.84]:
  ball((0,y-.06,z),(.52,.10,.40),surflight)
 for z in [-.37,.05,.47]:
  for side in [-1,1]:
   o=box((side*.13,y+.15,z),(.30,.025,.07),gold,.008);o.rotation_euler.z=side*.55
deck(.69);export('surf_board',12000)
clear();deck(.85)
ring((0,.88,.12),.73,.045,surflight)
export('surf_pickup',15000)
clear()
portalstone=mat('portal blue stone',(.18,.22,.38),.12,.32)
for side in [-1,1]:
 x=side*3.48
 box((x,1.2,0),(.66,2.4,.8),portalstone,.07)
 for yy in [.22,1.15,2.18]:box((x,yy,0),(.83,.18,.93),gold,.035)
for k in range(17):
 a=pi*k/16
 x=3.48*math.cos(a);y=2.35+3.48*math.sin(a)
 o=box((x,y,0),(.74,.70,.74),portalstone,.065);o.rotation_euler.y=-a
 ball((x,y,.40),(.35,.35,.14),surflight)
# Inner continuous glowing half-ring (open path underneath).
verts=[];faces=[]
for k in range(65):
 a=pi*k/64
 for r in [3.08,3.19]:verts.append(v((r*math.cos(a),2.35+r*math.sin(a),.46)))
for k in range(64):faces.append((k*2,k*2+1,k*2+3,k*2+2))
me=bpy.data.meshes.new('portal ribbon');me.from_pydata(verts,[],faces);me.update()
o=bpy.data.objects.new('portal ribbon',me);bpy.context.collection.objects.link(o);o.data.materials.append(surflight)
paw((0,5.88,.45),gold,1.4)
export('portal',20000)
# Biome A: floating crystal gardens, faceted quartz and blue vegetation.
clear()
crystal=mat('quartz amethyst',(.43,.14,.78),.24,.23)
mint=mat('crystal garden mint',(.12,.52,.43))
cyl((0,-1.25,0),.42,2.55,2.8,portalstone)
cyl((0,.08,0),2.48,2.48,.24,mint)
for i in range(7):
 a=i*2.399
 x=math.cos(a)*(1.4 if i else 0);z=math.sin(a)*(1.4 if i else 0)
 h=2.9 if i==0 else 1.05+(i%3)*.4
 bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=.38 if i else .72,radius2=.27 if i else .47,depth=h,location=v((x,h*.5+.2,z)))
 finish(bpy.context.object,crystal if i%2 else surflight)
 bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=.27 if i else .47,radius2=0,depth=.55,location=v((x,h+.47,z)))
 finish(bpy.context.object,crystal if i%2 else surflight)
for i in range(5):
 a=i*2*pi/5
 ball((2.06*math.cos(a),.29,2.06*math.sin(a)),(.55,.38,.55),leaf)
export('crystal_island',17000)
# Biome B: floating moon observatory with golden crescent and telescope.
clear()
moonrock=mat('moon slate',(.16,.19,.34))
moonroof=mat('observatory violet',(.26,.12,.46),.18,.25)
cyl((0,-1.35,0),.48,2.6,3.0,moonrock)
cyl((0,.08,0),2.51,2.51,.32,stone)
cyl((0,1.05,0),1.16,1.16,1.8,cream)
ball((0,2.0,0),(2.32,1.55,2.32),moonroof)
box((0,1.10,1.12),(.58,.91,.12),blue,.06)
for x in [-.77,.77]:box((x,1.23,.84),(.20,.40,.07),surflight,.025)
for k in range(13):
 a=-pi*.65+k*pi*1.3/12
 ball((.72*math.cos(a),3.03+.72*math.sin(a),0),(.28,.28,.22),gold)
for i in range(5):
 a=i*2*pi/5
 x=1.91*math.cos(a);z=1.91*math.sin(a)
 box((x,.34,z),(.28,.55,.28),portalstone,.035);ball((x,.65,z),(.30,.30,.30),surflight)
export('moon_island',18000)
# Distant palace landmark: pointed turrets, layered terraces, windows, flying flags.
clear()
cyl((0,-1.65,0),.70,4.1,3.7,stone)
cyl((0,.12,0),4.04,4.04,.38,green)
box((0,.45,0),(5.9,.48,4.8),cream,.12)
box((0,1.50,0),(3.2,2.05,2.60),cream,.08)
box((0,2.63,0),(3.44,.28,2.84),gold,.04)
cyl((0,3.55,0),1.73,.06,1.75,blue)
for side in [-1,1]:
 for z in [-1.65,1.65]:
  x=side*2.18
  cyl((x,1.91,z),.72,.65,3.2,cream)
  cyl((x,3.58,z),.81,.81,.19,gold)
  cyl((x,4.38,z),.92,.04,1.55,blue)
  ball((x,5.20,z),(.16,.21,.16),gold)
  box((x,2.35,z+.66),(.21,.55,.07),blue,.04)
 for y in [1.12,1.78,2.32]:
  box((side*.62,y,1.32),(.29,.37,.06),blue,.035)
  box((side*.62,y-.24,1.36),(.34,.07,.09),gold,.012)
box((0,.94,1.34),(.65,1.08,.08),blue,.075)
for x in [-2.8,2.8]:
 ball((x,.62,2.1),(.68,.72,.68),leaf)
 box((x,1.45,2.12),(.065,1.0,.065),gold,.01)
 box((x+.30,1.74,2.12),(.56,.32,.035),violet,.02)
export('palace',35000)
# Soft low-poly cloud islands add layered motion against baked distant sky.
clear()
cloudwhite=mat('cloud cream',(.92,.94,1),0,.87)
cloudshade=mat('cloud blue shadow',(.67,.78,.94),0,.87)
for x,y,z,s in [(-1.7,0,0,1.2),(-.65,.24,0,1.45),(.45,.45,-.1,1.75),(1.55,.12,.12,1.3),(2.1,-.05,0,.85),(-.2,-.29,.05,1.7)]:
 ball((x,y,z),(s*1.4,s*.88,s),cloudwhite if y>=0 else cloudshade)
export('cloud_bank',6000)
# Distinct silhouettes: royal gate, botanical island and floating windmill.
jade=mat('jade enamel',(.045,.31,.25),.12,.34)
rose=mat('petal rose',(.89,.20,.43),0,.48)
terracotta=mat('warm terracotta',(.66,.27,.13),0,.46)
def leaf_mesh(p,scale,angle,m):
 # Folded pointed leaf: broad midsection, central ridge, tapered ends.
 pts=[(0,-.5,0),(-.28,-.15,0),(-.35,.16,0),(0,.58,0),(.35,.16,0),(.28,-.15,0),(0,.08,.13)]
 ca,sa=math.cos(angle),math.sin(angle)
 verts=[v((p[0]+scale*(x*ca-y*sa),p[1]+scale*(x*sa+y*ca),p[2]+scale*z)) for x,y,z in pts]
 faces=[(i,(i+1)%6,6) for i in range(6)]
 me=bpy.data.meshes.new('folded foliage');me.from_pydata(verts,[],faces);me.update()
 o=bpy.data.objects.new('folded foliage',me);bpy.context.collection.objects.link(o);o.data.materials.append(m)
 return o
clear()
# Taller but open central raceway; decorative side towers stay outside lanes.
for side in [-1,1]:
 x=side*3.65
 box((x,.24,0),(.96,.48,1.10),stone,.06)
 cyl((x,2.0,0),.43,.36,3.2,cream)
 for y in [.62,1.15,3.15,3.62]:cyl((x,y,0),.49,.49,.11,gold)
 box((x,2.1,.39),(.32,1.55,.08),blue,.04)
 paw((x,2.4,.45),gold,.8)
 cyl((x,4.10,0),.76,.04,1.22,blue)
 ball((x,4.76,0),(.13,.22,.13),gold)
 for j in range(7):
  leaf_mesh((x+side*.17,.78+j*.33,.50),.61,side*(.65 if j%2 else -.7),leaf if j%2 else green)
for k in range(15):
 a=pi*k/14
 x=3.60*math.cos(a);y=3.70+2.55*math.sin(a)
 o=box((x,y,0),(.77,.73,.78),cream,.07);o.rotation_euler.y=-a
 if k%2==0:
  for j in range(3):leaf_mesh((x+.19*(j-1),y+.18,.48),.64,(j-1)*.85,leaf if j%2 else green)
  flower((x,y+.10,.66),1.2)
cyl((0,6.24,.47),.55,.55,.18,blue,True)
ring((0,6.24,.58),.48,.048,gold);paw((0,6.15,.63),gold,1.45)
export('royal_gate',32000)
clear()
cyl((0,-1.55,0),.40,2.85,3.3,stone)
cyl((0,.10,0),2.8,2.8,.30,jade)
# garden pavilion with fluted columns and blue glass roof.
cyl((0,.35,0),1.58,1.58,.28,cream)
for i in range(6):
 a=i*pi/3;x=1.26*math.cos(a);z=1.26*math.sin(a)
 cyl((x,1.18,z),.13,.12,1.48,cream)
 cyl((x,.49,z),.21,.21,.16,gold)
 cyl((x,1.86,z),.21,.21,.15,gold)
cyl((0,2.06,0),1.59,1.59,.20,cream)
ball((0,2.48,0),(2.89,1.21,2.89),blue)
ball((0,3.13,0),(.20,.30,.20),gold)
for j in range(8):
 a=j*pi/4;x=2.05*math.cos(a);z=2.05*math.sin(a)
 ball((x,.42,z),(.66,.58,.68),green)
 for k in range(3):
  leaf_mesh((x+.14*(k-1),.70,z+.29),.54,(k-1)*.83,leaf)
 flower((x,.80,z+.35),1.35)
for j in range(3):
 x=-.54+j*.54
 ball((x,-1.5,2.55),(.28,3.0,.22),water)
export('garden_island',30000)
clear()
cyl((0,-1.55,0),.46,2.60,3.3,stone)
cyl((0,.10,0),2.55,2.55,.34,green)
cyl((0,1.44,0),.85,.61,2.65,cream)
cyl((0,3.16,0),1.03,.06,1.25,terracotta)
box((0,.75,.82),(.53,.87,.085),wood2,.055)
for x in [-.41,.41]:
 box((x,1.67,.68),(.20,.48,.10),blue,.035)
cyl((0,2.55,.79),.27,.27,.30,gold,True)
for j in range(4):
 a=j*pi/2+.40
 x=math.cos(a);y=2.55+math.sin(a)
 o=box((x,y,1.02),(.36,1.61,.12),wood2,.03);o.rotation_euler.y=pi/2-a
 for k in range(3):
  xx=(.63+.39*k)*math.cos(a);yy=2.55+(.63+.39*k)*math.sin(a)
  o=box((xx,yy,1.10),(.27,.31,.06),cream,.025);o.rotation_euler.y=pi/2-a
for j in range(5):
 a=j*2*pi/5;x=1.85*math.cos(a);z=1.85*math.sin(a)
 ball((x,.55,z),(.75,.84,.75),leaf if j%2 else green)
 flower((x,.72,z+.40),1.0)
export('windmill_island',28000)
# Courier vehicle, separate canopy, payload, chassis, wheel hubs, luminous lamps.
clear()
courierpaint=mat('courier turquoise enamel',(.035,.29,.33),.24,.27)
courierglass=mat('courier sapphire glass',(.035,.095,.19),.32,.15)
box((0,.37,0),(1.46,.44,1.78),steel,.12)
box((0,1.04,-.37),(1.34,.92,.94),courierpaint,.13)
box((0,1.70,-.40),(1.22,.62,.77),courierglass,.10)
box((0,2.13,-.40),(1.42,.17,.91),gold,.05)
box((0,1.32,.47),(1.34,1.65,.68),courierpaint,.12)
box((0,1.37,.83),(1.16,1.22,.08),wood,.06)
for x in [-.59,.59]:
 for z in [-.59,.59]:
  wheel=cyl((x,.36,z),.32,.32,.21,dark);wheel.rotation_euler.y=pi/2
  hub=cyl((x+(.12 if x>0 else -.12),.36,z),.18,.18,.065,gold);hub.rotation_euler.y=pi/2
 ball((x,.60,.90),(.22,.19,.10),signal)
box((0,.36,.94),(1.45,.19,.14),gold,.045)
paw((0,1.35,.90),cream,1.65)
export('courier',20000)
# Rotating obstacle: centered mesh around its axle so rotation never changes its height.
clear()
barrelwood=mat('barrel burnt oak',(.30,.12,.05),.08,.43)
# exported origin is at ground; runner rotates visual around axle via separate offset
for j in range(12):
 a=j*2*pi/12
 o=box((0,.65+.51*math.cos(a),.51*math.sin(a)),(1.25,.23,.18),barrelwood,.025);o.rotation_euler.x=-a
for x in [-.52,.52]:
 o=cyl((x,.65,0),.64,.64,.16,steel);o.rotation_euler.y=pi/2
 o=cyl((x+(.095 if x>0 else -.095),.65,0),.42,.42,.055,gold);o.rotation_euler.y=pi/2
 o=cyl((x+(.13 if x>0 else -.13),.65,0),.14,.14,.045,signal);o.rotation_euler.y=pi/2
export('roller',13000)
clear()
cardmat=mat('chronicle sapphire',(.055,.16,.46),.28,.32)
box((0,.92,0),(.72,.94,.09),gold,.055)
box((0,.92,.055),(.62,.82,.045),cardmat,.035)
ring((0,1.04,.085),.21,.026,gold)
paw((0,1.02,.11),cream,.8)
for y in [.65,.73]:box((0,y,.09),(.33,.025,.022),gold,.006)
export('story_card',6500)
# Original faceted luminous reward spark, shared in bounded particle pools.
clear()
sparkmat=mat('spark warm light',(.95,.66,.15),0,.28)
b=sparkmat.node_tree.nodes.get('Principled BSDF')
b.inputs['Emission Color'].default_value=(1,.75,.25,1);b.inputs['Emission Strength'].default_value=.75
pts=[]
for z in [-.018,.018]:
 for i in range(8):
  a=pi/2+i*pi/4;r=.10 if i%2==0 else .035
  pts.append(v((r*math.cos(a),r*math.sin(a),z)))
faces=[tuple(range(7,-1,-1)),tuple(range(8,16))]
for i in range(8):faces.append((i,(i+1)%8,(i+1)%8+8,i+8))
me=bpy.data.meshes.new('faceted reward spark');me.from_pydata(pts,[],faces);me.update()
o=bpy.data.objects.new('faceted reward spark',me);bpy.context.collection.objects.link(o);o.data.materials.append(sparkmat)
export('reward_spark',500)
with open(os.path.join(OUT,'mesh-metrics.json'),'w') as out: json.dump(stats,out,indent=2)
