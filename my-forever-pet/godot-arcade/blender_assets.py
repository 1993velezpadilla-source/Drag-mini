import bpy, math, os, sys
from math import pi
OUT=os.path.abspath(sys.argv[sys.argv.index('--')+1]);os.makedirs(OUT,exist_ok=True)
def mat(name,rgb,metal=0,rough=.42):
 m=bpy.data.materials.new(name);m.diffuse_color=(*rgb,1);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*rgb,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough;return m
wood=mat('warm oak',(.23,.087,.032));wood2=mat('light oak',(.33,.145,.057));stone=mat('blue grey stone',(.35,.41,.49));cream=mat('ivory',(.88,.77,.59));gold=mat('gold',(.98,.57,.07),.5,.26);green=mat('foliage',(.085,.36,.12));leaf=mat('leaf tips',(.30,.57,.12));blue=mat('navy blue',(.06,.13,.34));violet=mat('banner violet',(.25,.14,.52));amber=mat('amber',(.98,.51,.13));lime=mat('Mosskit body',(.13,.46,.024),0,.34);pink=mat('ear rose',(.95,.35,.49));dark=mat('deep plum',(.038,.024,.075),0,.20);white=mat('eye shine',(.97,.97,1));water=mat('water',(.13,.64,.89),.15,.21)
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def finish(o,m,b=0):
 o.data.materials.append(m)
 if b:
  q=o.modifiers.new('bevel','BEVEL');q.width=b;q.segments=2;q=o.modifiers.new('normals','WEIGHTED_NORMAL')
 for p in o.data.polygons:p.use_smooth=True
 return o
# input coordinates use Godot's x,y,z; convert to Blender x,-z,y.
def v(p):return (p[0],-p[2],p[1])
def box(p,size,m,b=.035):
 bpy.ops.mesh.primitive_cube_add(size=1,location=v(p));o=bpy.context.object;o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,m,b)
def ball(p,size,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=v(p));o=bpy.context.object;o.scale=(size[0]/2,size[2]/2,size[1]/2);return finish(o,m)
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
 for j in range(3):
  z=-6+j*6;box((side*3.5,.73,z),(.39,1.46,.39),stone,.065);box((side*3.5,1.46,z),(.52,.17,.52),wood2)
  if j%2==0:
   box((side*3.5,1.92,z),(.12,1.0,.12),blue);box((side*3.5,2.40,z),(.43,.13,.43),blue)
   cyl((side*3.5,2.68,z),.21,.29,.48,amber)
   for dx in [-.18,.18]:
    for dz in [-.18,.18]:box((side*3.5+dx,2.68,z+dz),(.045,.49,.045),blue,.012)
   cyl((side*3.5,3.02,z),.34,.05,.24,blue)
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
export('bridge',110000)
clear()
for side in [-1,1]:box((side*3.3,2,0),(.72,4,.78),stone,.10)
for j in range(13):
 a=j*pi/12;o=box((3.3*math.cos(a),3.8+3.3*math.sin(a),0),(.82,.72,.85),cream,.075);o.rotation_euler.y=-a
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
export('arch',85000)
clear()
cyl((0,-1.9,0),.50,2.7,3.8,stone);cyl((0,.05,0),2.69,2.69,.35,green)
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
export('island',50000)
clear()
ball((0,.85,0),(1.48,1.52,1.2),lime)
for side in [-1,1]:
 o=ball((side*.48,1.58,0),(.42,.72,.35),lime);o.rotation_euler.y=side*.38
 o=ball((side*.48,1.60,.12),(.25,.49,.15),pink);o.rotation_euler.y=side*.38
 ball((side*.29,1.02,.54),(.33,.48,.16),dark);ball((side*.29-.05,1.13,.62),(.115,.14,.055),white)
 ball((side*.47,.78,.46),(.22,.12,.09),pink)
ball((0,.72,.61),(.29,.25,.10),dark);ball((0,.65,.66),(.17,.085,.055),pink)
ball((0,.66,-.65),(.36,.36,.34),lime)
export('mosskit',26000)
clear();ball((0,0,0),(.68,.40,.67),lime);paw((0,-.08,.30),pink,.64);export('foot',7000)
clear();box((0,.45,0),(1.3,.9,.9),wood,.07)
for x in [-.55,.55]:box((x,.45,.47),(.14,.86,.07),wood2)
for y in [.10,.80]:box((0,y,.47),(1.25,.12,.08),wood2)
paw((0,.43,.52),cream,.8);export('crate',10000)
clear()
for x in [-.65,.65]:
 box((x,.75,0),(.2,1.5,.30),blue,.045);ball((x,1.82,0),(.24,.27,.24),gold)
box((0,1.42,0),(1.52,.48,.32),violet,.06)
for x in [-.50,.50]:
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
for z in [-.30,.30]:
 for side in [-1,1]:
  o=box((side*.19,.29,z),(.50,.045,.14),cyan,.02);o.rotation_euler.z=side*.65
export('boost',6000)
