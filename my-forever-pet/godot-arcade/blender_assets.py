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
   if name in ('dungeon_coin','dungeon_chest'):
    import bmesh
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00003)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.00003)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
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
# The runner Mosskit export above is unchanged. A home-only sleeping body
# uses the identical silhouette, mouth, ears and markings with closed lids.
clear()
ball((0,.85,0),(1.48,1.52,1.2),lime)
for side in [-1,1]:
 o=ball((side*.48,1.58,0),(.42,.72,.35),lime);o.rotation_euler.y=side*.38
 o=ball((side*.48,1.60,.12),(.25,.49,.15),pink);o.rotation_euler.y=side*.38
 # Closed eyelid follows the curved cheek surface and replaces both eye and highlight.
 for j in range(9):
  dx=(j-4)*.034
  ball((side*.29+dx,1.02-.035*math.sin(pi*j/8),.56+(.025*(1-abs(dx)/.136))),(.051,.035,.047),dark)
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
root_out=OUT
OUT=os.path.join(root_out,'home_faces');os.makedirs(OUT,exist_ok=True)
export('mosskit_sleep',26000)
stats.pop('mosskit_sleep')
OUT=root_out
clear()
ball((0,0,0),(.68,.40,.67),lime)
# Pads are flattened along vertical Y, attached to the sole, not the heel.
ball((0,-.182,.035),(.24,.050,.23),pink)
for i in range(3):
 ball(((i-1)*.103,-.157,-.145+(.025 if i!=1 else 0)),(.088,.045,.100),pink)
export('foot',7000)
clear();box((0,.45,0),(1.3,.9,.9),wood,.07)
for x in [-.55,.55]:box((x,.45,.47),(.14,.86,.07),wood2)
for y in [.10,.80]:box((0,y,.47),(1.25,.12,.08),wood2)
for x in [-.57,.57]:
 for y in [.12,.78]:
  box((x,y,.525),(.19,.16,.045),stone,.025)
  ball((x,y,.555),(.055,.055,.025),gold)
for y in [.29,.60]:box((0,y,.468),(1.10,.018,.018),wood2,.005)
paw((0,.43,.52),cream,.8)
for obj in bpy.context.scene.objects:
 if obj.type=='MESH':
  obj.location.x*=1.10;obj.location.y*=1.22;obj.location.z*=1.17
  obj.scale.x*=1.10;obj.scale.y*=1.22;obj.scale.z*=1.17
export('crate',14000)
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
for obj in bpy.context.scene.objects:
 if obj.type=='MESH':
  obj.location.x*=1.08;obj.location.z*=1.13
  obj.scale.x*=1.08;obj.scale.z*=1.13
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
# Optional treasure lane: readable gold-and-jade arch, open center, ornate crown.
clear()
treasure_jade=mat('treasure jade',(.04,.38,.25),.28,.25)
treasure_glow=mat('treasure lantern',(.99,.71,.13),.12,.21)
bs=treasure_glow.node_tree.nodes.get('Principled BSDF')
bs.inputs['Emission Color'].default_value=(1,.59,.08,1);bs.inputs['Emission Strength'].default_value=.5
for side in [-1,1]:
 x=side*.77
 box((x,.11,0),(.24,.22,.46),gold,.035)
 cyl((x,.98,0),.12,.10,1.62,treasure_jade)
 for y in [.30,.88,1.62]:cyl((x,y,0),.16,.16,.10,gold)
 ball((x,1.83,0),(.24,.32,.24),treasure_glow)
for k in range(11):
 a=k*pi/10
 x=.78*math.cos(a);y=1.77+.64*math.sin(a)
 o=box((x,y,0),(.25,.22,.26),treasure_jade,.04);o.rotation_euler.y=-a
 if k%2==0:ball((x,y,.16),(.11,.11,.09),gold)
ring((0,2.46,.17),.20,.035,gold)
paw((0,2.43,.22),treasure_glow,.65)
export('treasure_gate',14000)
# Original wearable twin-engine jetpack, compact readable silhouette.
clear()
jetblue=mat('jetpack cobalt enamel',(.07,.23,.55),.34,.26)
jetcream=mat('jetpack ivory shell',(.79,.86,.93),.18,.28)
jetflame=mat('jetpack ion flame',(.12,.83,1),.12,.22)
jbs=jetflame.node_tree.nodes.get('Principled BSDF')
jbs.inputs['Emission Color'].default_value=(.12,.83,1,1)
jbs.inputs['Emission Strength'].default_value=1.8
box((0,.16,0),(.66,.64,.23),jetblue,.07)
for x in [-.39,.39]:
 ball((x,.19,-.06),(.35,.82,.36),jetcream)
 cyl((x,-.07,-.06),.18,.18,.14,gold)
 cyl((x,-.24,-.06),.13,.18,.18,jetblue)
 ball((x,-.43,-.06),(.19,.44,.19),jetflame)
 ball((x,.60,-.06),(.20,.15,.21),gold)
box((0,.19,-.16),(.34,.28,.09),gold,.04)
ball((0,.19,-.23),(.16,.16,.08),jetflame)
export('jetpack',12000)
# Mystery dungeon kit v2: authored biome silhouettes, bevels, layered materials,
# deliberately distinct wall profiles and small decorative details.
import random
def rock_slab(p,size,m,seed,bevel=.045):
 rng=random.Random(seed)
 # irregular octagonal prism, with tapered sides and a beveled edge
 points=[(-.36,-.50),(.34,-.50),(.50,-.29),(.50,.29),(.30,.50),(-.32,.50),(-.50,.30),(-.50,-.30)]
 verts=[]
 for level in range(2):
  for x,z in points:
   s=1.0 if level==0 else rng.uniform(.78,.96)
   verts.append(v((p[0]+x*size[0]*s,p[1]+(level-.5)*size[1]+rng.uniform(-.025,.025),p[2]+z*size[2]*s)))
 faces=[tuple(range(8)),tuple(range(15,7,-1))]
 for j in range(8):faces.append((j,j+8,(j+1)%8+8,(j+1)%8))
 me=bpy.data.meshes.new('weathered stone slab');me.from_pydata(verts,[],faces);me.update()
 uv=me.uv_layers.new(name='Stone UV')
 for face in me.polygons:
  axis=max(range(3),key=lambda i:abs(face.normal[i]));axes=[i for i in range(3) if i!=axis]
  for li in face.loop_indices:
   co=me.vertices[me.loops[li].vertex_index].co;uv.data[li].uv=(co[axes[0]]*.9+.5,co[axes[1]]*.9+.5)
 o=bpy.data.objects.new('weathered stone slab',me);bpy.context.collection.objects.link(o)
 return finish(o,m,bevel)
def tube(points,radii,m,sides=8):
 # Parallel-transported circular cross sections: horizontal roots and branching
 # coral retain their volume rather than collapsing into horizontal discs.
 from mathutils import Vector
 import bmesh
 path=[Vector(v(p)) for p in points]
 verts=[];faces=[];frame=None
 for i,(p,r) in enumerate(zip(path,radii)):
  tangent=(path[min(i+1,len(path)-1)]-path[max(i-1,0)]).normalized()
  if frame is None:
   ref=Vector((0,0,1)) if abs(tangent.z)<.85 else Vector((1,0,0))
   frame=ref.cross(tangent).normalized()
  else:
   frame=frame-tangent*frame.dot(tangent)
   if frame.length<.001:frame=tangent.cross(Vector((1,0,0)) if abs(tangent.x)<.85 else Vector((0,1,0)))
   frame.normalize()
  cross=tangent.cross(frame).normalized()
  for j in range(sides):
   ang=j*2*pi/sides
   # Subtle longitudinal ridges; tapered organic sections, not straight cones.
   rad=r*(1+.045*math.sin(j*3*2*pi/sides+i*.6))
   verts.append(tuple(p+rad*(frame*math.cos(ang)+cross*math.sin(ang))))
 for i in range(len(path)-1):
  for j in range(sides):
   a=i*sides+j;c=i*sides+(j+1)%sides
   faces.append((a,c,c+sides,a+sides))
 faces.extend([tuple(reversed(range(sides))),tuple(range((len(path)-1)*sides,len(path)*sides))])
 me=bpy.data.meshes.new('tangent swept organic branch');me.from_pydata(verts,[],faces);me.update()
 bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
 me.update()
 o=bpy.data.objects.new('tangent swept organic branch',me);bpy.context.collection.objects.link(o);return finish(o,m)
def blades(p,a,length,width,m):
 verts=[];faces=[]
 for i in range(7):
  t=i/6;reach=t*length*.65;h=length*(.92*t-.42*t*t);w=width*max(.10,math.sin(pi*t)**.7)
  for side in [-1,1]:verts.append(v((p[0]+math.cos(a)*reach-side*w*math.sin(a),p[1]+h,p[2]+math.sin(a)*reach+side*w*math.cos(a))))
 for i in range(6):faces.append((i*2,i*2+1,i*2+3,i*2+2))
 me=bpy.data.meshes.new('curved leaf');me.from_pydata(verts,[],faces);me.update()
 o=bpy.data.objects.new('curved leaf',me);bpy.context.collection.objects.link(o);finish(o,m)
 mod=o.modifiers.new('leaf thickness','SOLIDIFY');mod.thickness=.018
def crystal(p,r,h,m,seed):
 rng=random.Random(seed);verts=[]
 for level in [0,.73,1]:
  for i in range(6):
   a=i*pi/3;rr=r*(1 if level<1 else .12)
   verts.append(v((p[0]+rr*math.cos(a)+level*r*.18,p[1]+h*level,p[2]+rr*math.sin(a))))
 faces=[tuple(range(6)),tuple(reversed(range(12,18)))]
 for k in range(2):
  for i in range(6):faces.append((k*6+i,(k+1)*6+i,(k+1)*6+(i+1)%6,k*6+(i+1)%6))
 me=bpy.data.meshes.new('faceted crystal');me.from_pydata(verts,[],faces);me.update()
 o=bpy.data.objects.new('faceted crystal',me);bpy.context.collection.objects.link(o);o.data.materials.append(m);return o
def emit_mat(name,c,strength):
 m=mat(name,c,0,.35);bs=m.node_tree.nodes.get('Principled BSDF')
 bs.inputs['Emission Color'].default_value=(*c,1);bs.inputs['Emission Strength'].default_value=strength
 return m
foreststone=mat('weathered olive limestone',(.11,.16,.095),0,.8)
forestedge=mat('forest layered stone',(.19,.23,.14),0,.84)
moss=mat('deep moss',(.045,.17,.025),0,.9)
leafdark=mat('forest leaf shadow',(.025,.115,.045),0,.8)
leafbright=mat('fern lime',(.16,.31,.06),0,.7)
bark=mat('weathered roots',(.17,.065,.025),0,.88)
cap=mat('mushroom ochre',(.63,.24,.055),0,.68)
reefstone=mat('deep reef basalt',(.045,.13,.19),0,.78)
reefedge=mat('reef slate',(.085,.23,.28),0,.74)
coral=mat('salmon coral',(.56,.15,.16),0,.72)
coral2=mat('violet coral',(.29,.12,.36),0,.7)
kelp=mat('sea grass',(.035,.19,.115),0,.78)
pearl=mat('iridescent pearl',(.61,.82,.83),.12,.22)
astralstone=mat('indigo ruin stone',(.10,.075,.17),0,.79)
astraledge=mat('violet layered stone',(.19,.14,.29),0,.76)
rune=mat('brushed brass inlay',(.56,.30,.09),.55,.33)
star=mat('amethyst crystal',(.26,.15,.57),.18,.26)
glow=emit_mat('warm lantern core',(.95,.49,.11),.75)
blueglow=emit_mat('azure magic',(.11,.55,.83),.45)
violetglow=emit_mat('violet magic',(.45,.25,.85),.45)
for m,c,seed in [(foreststone,(.25,.32,.19),431),(forestedge,(.33,.36,.24),432),(reefstone,(.095,.24,.32),433),(reefedge,(.18,.35,.42),434),(astralstone,(.20,.14,.31),435),(astraledge,(.30,.23,.43),436)]:
 stone_texture(m,c,seed)
# Organic rock silhouette: irregular profiles, rounded bevels and outward normals.
def natural_rock(p,size,m,seed):
 rng=random.Random(seed)
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=v(p))
 o=bpy.context.object
 for vertex in o.data.vertices:
  co=vertex.co
  co*=rng.uniform(.86,1.13)
  co.z=max(-.75,co.z)
  co.z=min(.78,co.z)
 o.scale=(size[0]*.55,size[2]*.55,size[1]*.62)
 o.rotation_euler.z=rng.uniform(-.35,.35)
 o.data.materials.append(m)
 if not o.data.uv_layers:o.data.uv_layers.new(name='Rock UV')
 uv=o.data.uv_layers.active
 for face in o.data.polygons:
  axis=max(range(3),key=lambda i:abs(face.normal[i]));axes=[i for i in range(3) if i!=axis]
  for li in face.loop_indices:
   co=o.data.vertices[o.data.loops[li].vertex_index].co;uv.data[li].uv=(co[axes[0]]*.45+.5,co[axes[1]]*.45+.5)
 return o
def leaf_rosette(p,seed,m1,m2,length=.58):
 rng=random.Random(seed)
 for i in range(7):
  ang=i*2*pi/7+rng.uniform(-.22,.22)
  blades(p,ang,length*rng.uniform(.76,1.23),.12,m1 if i%2 else m2)
# Each biome has three different wall silhouettes, not recolored spheres.
for variant in range(3):
 clear()
 # Whisperwood: intertwined roots over irregular moss-covered boulders.
 natural_rock((0,.27,0),(1.36,.56,1.30),foreststone,40+variant)
 for i in range(3):
  x=(i-1)*.39
  natural_rock((x,.45+.13*((i+variant)%3),.04),(.58,.48,.90),forestedge,60+i+variant*8)
  natural_rock((x,.76+.10*((i+variant)%2),-.05),(.48,.18,.60),moss,90+i+variant*5)
 tube([(-.62,.39,.42),(-.35,.65,.45),(.04,.82,.36),(.39,.64,.32),(.62,.45,.18)],[.11,.12,.095,.07,.035],bark)
 if variant!=1:
  leaf_rosette((-.29,.68,.02),41+variant,leafdark,leafbright,.48)
 else:
  for x in [-.30,.24]:
   cyl((x,.80,.12),.045,.035,.23,bark);ball((x,.96,.12),(.26,.15,.25),cap)
 export('dungeon_forest_rock_%d'%variant,6500)
 clear()
 # Coral Depths: basalt terraces with branching, contrasting reef silhouettes.
 natural_rock((0,.27,0),(1.38,.55,1.36),reefstone,110+variant)
 for i in range(2):
  natural_rock(((i-.5)*.66,.47+.11*((i+variant)%2),.02),(.78,.44,1.03),reefedge,140+i+variant*9)
 for i in range(2+variant%2):
  x=(i-.5)*.52-.1;h=.43+.16*((variant+i)%3)
  tube([(x,.56,0),(x+.03,.78,.03),(x+.13,.56+h,.05)],[.09,.073,.038],coral if i else coral2)
  for side in [-1,1]:
   tube([(x,.77,0),(x+side*.13,.85,.04),(x+side*.23,.96,.07)],[.052,.04,.022],coral2 if i else coral)
 if variant==2:leaf_rosette((-.24,.50,.1),100+variant,kelp,leafdark,.62)
 else:
  for x in [-.42,.39]:ball((x,.57,.20),(.16,.14,.17),pearl)
 export('dungeon_reef_rock_%d'%variant,6500)
 clear()
 # Starfall: broken masonry, brass traces and tall crystal growth.
 rock_slab((0,.23,0),(1.40,.50,1.35),astralstone,210+variant)
 if variant==0:
  for i in range(3):
   rock_slab(((i-1)*.41,.58+.055*(i%2),.02),(.49,.35,.90),astraledge,240+i)
  box((0,.57,.50),(.72,.055,.04),rune,.01)
  crystal((0,.76,.02),.16,.42,violetglow,1)
 elif variant==1:
  rock_slab((-.35,.62,0),(.59,.75,.83),astraledge,251)
  rock_slab((.32,.39,.1),(.59,.31,.83),astraledge,252)
  box((-.35,.63,.43),(.085,.48,.035),rune,.012)
  crystal((.34,.58,.10),.18,.45,star,4)
 else:
  for i in range(3):
   natural_rock(((i-1)*.4,.46,.03),(.53,.35,.80),astraledge,268+i)
   crystal(((i-1)*.29,.63,.05),.13+.025*i,.31+.18*(i%2),star if i%2 else violetglow,i)
 export('dungeon_star_rock_%d'%variant,6500)
# Legacy asset names are replaced, not kept as low-quality fallback art.
for region,base,accent in [('forest',foreststone,forestedge),('reef',reefstone,reefedge),('star',astralstone,astraledge)]:
 clear()
 for i in range(2):rock_slab(((i-.5)*.69,.32,0),(.75,.68,1.37),base,i+82)
 rock_slab((0,.72,0),(1.37,.21,1.10),accent,86)
 export('dungeon_%s_wall'%region,2800)
clear()
rock_slab((0,.10,0),(.92,.20,.80),foreststone,24)
for i in range(7):
 a=i*2*pi/7;blades((0,.12,0),a,.65+.18*(i%2),.12,leafbright if i%2 else leafdark)
for i in range(3):
 x=(i-1)*.24;cyl((x,.25,.13),.045,.035,.29,bark);ball((x,.42,.13),(.25,.15,.25),cap)
export('dungeon_forest_cluster',5500)
clear()
rock_slab((0,.10,0),(.90,.20,.81),reefstone,32)
for i in range(6):
 a=i*2*pi/6;blades((0,.12,0),a,.7+.18*(i%2),.095,kelp)
for i in range(3):
 x=(i-1)*.24
 tube([(x,.13,.05),(x,.38,.05),(x+.12,.58,.07)],[.075,.05,.035],coral if i%2 else coral2)
 tube([(x,.31,.05),(x-.11,.42,.05),(x-.17,.53,.05)],[.04,.032,.018],coral)
export('dungeon_reef_cluster',5500)
clear()
rock_slab((0,.10,0),(.90,.20,.81),astralstone,33)
for i in range(5):
 a=i*2*pi/5;crystal((.25*math.cos(a),.2,.25*math.sin(a)),.11,.38+.17*(i%3),star if i%2 else violetglow,i)
export('dungeon_star_cluster',4200)
# Three genuinely different landmarks with readable profiles.
clear()
rock_slab((0,.12,0),(.94,.24,.84),foreststone,50)
box((0,.33,0),(.48,.19,.48),forestedge,.06)
box((0,.58,0),(.33,.37,.33),glow,.035)
for x in [-.22,.22]:
 for z in [-.22,.22]:box((x,.59,z),(.085,.44,.085),foreststone,.02)
rock_slab((0,.87,0),(.65,.22,.65),forestedge,57)
for i in range(5):blades((0,.98,0),i*2*pi/5,.30,.07,leafbright)
export('dungeon_forest_shrine',5000)
clear()
rock_slab((0,.11,0),(.90,.22,.84),reefstone,73)
# Open stylized fan shell: ribbed radial silhouette and pearl.
for i in range(9):
 a=(i-4)*.18
 o=ball((math.sin(a)*.35,.48+.17*math.cos(a),-.12),(.14,.55,.18),pearl);o.rotation_euler.y=-a
ball((0,.36,.18),(.36,.36,.36),blueglow)
for i in range(4):blades((.28,.15,.10),i*2*pi/4,.40,.07,kelp)
export('dungeon_reef_shrine',6500)
clear()
rock_slab((0,.10,0),(.90,.20,.84),astralstone,83)
cyl((0,.29,0),.35,.29,.15,rune)
for i in range(4):
 a=i*pi/2;crystal((.28*math.cos(a),.39,.28*math.sin(a)),.105,.40,star,i)
crystal((0,.39,0),.22,.77,violetglow,6)
export('dungeon_star_shrine',4200)
# Treasure and functional objects.
berry_red=mat('ripe ruby berry',(.58,.018,.045),0,.24)
clear()
box((0,.22,0),(.87,.43,.59),wood,.055)
box((0,.48,0),(.89,.23,.61),wood2,.07)
for x in [-.32,.32]:
 box((x,.25,.305),(.085,.50,.045),gold,.018)
 box((x,.57,0),(.08,.06,.58),gold,.012)
 for y in [.09,.41]:ball((x,y,.345),(.075,.075,.035),gold)
for x in [-.42,.42]:
 for z in [-.28,.28]:box((x,.09,z),(.10,.16,.10),gold,.022)
for y in [.13,.43]:box((0,y,.314),(.68,.035,.045),gold,.008)
box((0,.33,.33),(.24,.20,.07),gold,.022)
ball((0,.34,.38),(.082,.09,.045),dark)
export('dungeon_chest',5500)
clear()
rock_slab((0,.08,0),(1.09,.16,1.03),foreststone,28)
for i in range(4):box((0,.11+i*.115,-.32+i*.22),(.86,.18,.24),stone,.03)
for x in [-.48,.48]:
 box((x,.22,0),(.14,.37,.87),cream,.035)
 box((x,.51,.29),(.21,.49,.23),stone,.035)
 ball((x,.79,.29),(.17,.17,.17),glow)
export('dungeon_stairs',5500)
clear()
for i in range(4):
 a=i*2*pi/4
 ball((.15*math.cos(a),.18+.05*(i%2),.15*math.sin(a)),(.27,.28,.27),berry_red)
for i in range(3):blades((0,.33,0),i*2*pi/3,.30,.10,leafbright)
for i in range(4):
 a=i*pi/2;ball((.15*math.cos(a)+.04,.27+.05*(i%2),.15*math.sin(a)+.08),(.038,.055,.026),cream)
export('dungeon_berry',4000)
clear()
for i in range(3):
 a=i*2*pi/3;crystal((.15*math.cos(a),.02,.15*math.sin(a)),.13,.42+.12*i,blueglow if i==1 else star,i)
export('dungeon_material',1800)
clear()
rock_slab((0,.08,0),(1.0,.16,1.0),reefstone,98)
cyl((0,.17,0),.39,.39,.09,blueglow)
for i in range(8):
 a=i*pi/4;rock_slab((.44*math.cos(a),.18,.44*math.sin(a)),(.23,.22,.23),reefedge,100+i,.025)
export('dungeon_spring',4000)
# Large backdrop silhouettes. These are placed ONLY beyond the walkable boundary.
# Forest: branching ancient trunk, root flares and layered leaf canopy.
clear()
tube([(0,0,0),(-.12,.58,.06),(.08,1.20,.02),(.14,1.95,-.08)],[.37,.28,.23,.14],bark,12)
for i in range(5):
 a=i*2*pi/5
 tube([(0,.34,0),(.36*math.cos(a),.14,.36*math.sin(a)),(.78*math.cos(a),.04,.78*math.sin(a))],[.18,.13,.035],bark)
for i in range(4):
 a=i*pi/2+.3;x=.64*math.cos(a);z=.64*math.sin(a)
 tube([(.05,1.15,0),(x*.55,1.63,z*.55),(x,2.15,z)],[.15,.11,.045],bark)
 ball((x,2.13,z),(.97,.70,.98),leafdark if i%2 else moss)
 leaf_rosette((x,2.16,z),70+i,leafdark,leafbright,.58)
ball((.10,2.30,0),(1.05,.70,1.05),moss)
for i in range(7):
 a=i*2*pi/7
 x=.77*math.cos(a);z=.77*math.sin(a)
 ball((x,1.97+.11*(i%3),z),(.72,.46,.73),leafdark if i%3==0 else moss)
 leaf_rosette((x,2.06+.10*(i%3),z),180+i,leafdark,leafbright,.38)
for i in range(5):
 a=i*2*pi/5
 tube([(.31*math.cos(a),.16,.31*math.sin(a)),(.23*math.cos(a)-.07,.67,.23*math.sin(a)),(.19*math.cos(a)+.04,1.12,.19*math.sin(a))],[.045,.035,.016],forestedge)
export('dungeon_forest_landmark',14000)
# Reef: tall coral fans and tiered reef outcrop, not a forest asset recolored.
clear()
natural_rock((0,.30,0),(1.65,.65,1.34),reefstone,385)
natural_rock((-.35,.68,.08),(.88,.58,.82),reefedge,386)
for i in range(5):
 x=(i-2)*.27;h=1.05+.16*(2-abs(i-2))
 tube([(0,.58,0),(x*.48,.93,.04),(x,h+.43,.08),(x*1.21,h+.62,.10)],[.11,.09,.07,.035],coral if i%2 else coral2)
 for side in [-1,1]:
  tube([(x*.65,h+.02,.04),(x+side*.22,h+.24,-.03),(x+side*.29,h+.39,-.05)],[.06,.044,.022],coral if i%2 else coral2)
for i in range(5):
 a=i*2*pi/5;blades((.42*math.cos(a),.39,.42*math.sin(a)),a,.85,.13,kelp)
ball((.38,.62,.38),(.27,.25,.27),pearl)
export('dungeon_reef_landmark',7500)
# Astral ruin: broken monumental arch and brass trim with a suspended crystal.
clear()
for side in [-1,1]:
 x=side*.72
 rock_slab((x,.13,0),(.55,.26,.64),astralstone,500+side)
 for i in range(3):
  rock_slab((x,.41+i*.35,0),(.43,.34,.48),astraledge,510+i+side)
 box((x, .80,.255),(.075,.92,.035),rune,.012)
for i in range(7):
 ang=i*pi/6
 x=.72*math.cos(ang);y=1.24+.72*math.sin(ang)
 o=box((x,y,0),(.37,.34,.52),astraledge,.045);o.rotation_euler.y=ang-pi/2
crystal((0,1.30,0),.18,.48,violetglow,11)
for side in [-1,1]:crystal((side*.91,.08,.35),.11,.48,star,side+7)
export('dungeon_star_landmark',7000)
# Reward medallion: actual double-sided embossed paw, bevelled rim and inner field.
clear()
coin_core=mat('rich antique coin gold',(.70,.31,.025),.62,.24)
coin_rim=mat('polished coin rim',(.95,.64,.11),.72,.22)
coin_face=mat('coin recessed honey',(.51,.20,.018),.45,.32)
cyl((0,.38,0),.30,.30,.10,coin_core,True)
for z in [-.064,.064]:
 o=cyl((0,.38,z),.278,.278,.025,coin_rim,True)
 o.modifiers.get('bevel').width=.004
 o=cyl((0,.38,z*1.30),.225,.225,.018,coin_face,True)
 o.modifiers.get('bevel').width=.003
 paw((0,.34,z*1.56),coin_rim,.58)
for i in range(16):
 ang=i*2*pi/16
 ball((.262*math.cos(ang),.38+.262*math.sin(ang),.086),(.029,.029,.020),coin_rim)
export('dungeon_coin',4500)
# Low silhouette room ornaments: unique ground-level detail per biome.
clear()
rock_slab((0,.07,0),(.92,.14,.76),foreststone,701)
for i in range(5):
 ang=i*2*pi/5
 x=.30*math.cos(ang);z=.28*math.sin(ang)
 leaf_rosette((x,.14,z),710+i,leafdark,leafbright,.30)
 if i%2==0:
  cyl((x,.24,z),.045,.035,.22,bark)
  ball((x,.37,z),(.23,.13,.23),cap)
  for j in range(3):
   a=j*2*pi/3;ball((x+.055*math.cos(a),.43,z+.055*math.sin(a)),(.035,.022,.035),cream)
export('dungeon_forest_detail',7500)
clear()
natural_rock((0,.08,0),(.90,.20,.80),reefstone,731)
# Open fan of sea anemone tentacles and shell fragments.
for i in range(10):
 a=i*2*pi/10;x=.22*math.cos(a);z=.22*math.sin(a)
 tube([(x,.15,z),(x*1.25,.27,z*1.25),(x*1.65,.40,z*1.65)],[.035,.045,.025],coral if i%2 else coral2)
 ball((x*1.65,.40,z*1.65),(.07,.07,.07),pearl)
ball((0,.22,0),(.26,.12,.26),blueglow)
for i in range(5):
 a=i*2*pi/5;blades((.25,.12,-.18),a,.35,.08,kelp)
export('dungeon_reef_detail',5500)
clear()
rock_slab((0,.07,0),(.93,.14,.83),astralstone,752)
for i in range(8):
 a=i*pi/4
 o=box((.32*math.cos(a),.18,.32*math.sin(a)),(.24,.20,.15),astraledge,.025)
 o.rotation_euler.z=a
for i in range(4):
 a=i*pi/2;crystal((.20*math.cos(a),.17,.20*math.sin(a)),.08,.25+.07*(i%2),star,i)
crystal((0,.16,0),.10,.48,violetglow,9)
export('dungeon_star_detail',4000)
# Distinct architectural silhouettes for multi-tile boundary runs.
# Local X is the span; local +Z faces into the room.
clear()
natural_rock((0,.25,0),(2.68,.55,1.22),foreststone,820)
tube([(-1.21,.22,.23),(-.80,.47,.29),(-.42,.75,.18),(.02,.60,.32),(.48,.35,.40),(1.18,.20,.27)],[.19,.24,.23,.20,.15,.065],bark,12)
tube([(-.82,.32,-.23),(-.62,.83,-.20),(-.50,1.25,-.10),(-.32,1.56,-.06)],[.32,.27,.20,.12],bark,12)
for i in range(4):
 ang=i*pi/2
 tube([(-.51,1.04,-.09),(-.51+.27*math.cos(ang),1.34,-.09+.27*math.sin(ang)),(-.51+.54*math.cos(ang),1.52,-.09+.54*math.sin(ang))],[.12,.085,.035],bark)
 leaf_rosette((-.51+.40*math.cos(ang),1.48,-.09+.40*math.sin(ang)),851+i,leafdark,leafbright,.50)
for i in range(4):
 x=.11+i*.28
 natural_rock((x,.39+.07*(i%2),-.10),(.45,.40,.71),forestedge,872+i)
 leaf_rosette((x,.57,.06),880+i,leafdark,leafbright,.30)
export('dungeon_forest_span',8500)
clear()
# Asymmetric coral shelf with curved branch fans and pearl pockets.
natural_rock((0,.24,0),(2.65,.48,1.18),reefstone,901)
for i in range(3):
 x=(i-1)*.76
 natural_rock((x,.46+.09*i,-.13),(.98,.43,.90),reefedge,910+i)
for i in range(5):
 x=(i-2)*.27+.30
 h=.58+.12*(2-abs(i-2))
 tube([(x*.60,.51,-.02),(x*.85,.78,0),(x, .56+h,.08),(x+.12,.76+h,.16)],[.13,.10,.075,.035],coral if i%2 else coral2)
 for side in [-1,1]:
  tube([(x*.85,.78,0),(x+side*.13,.96,.05),(x+side*.22,1.12,.10)],[.065,.047,.023],coral2 if i%2 else coral)
for i in range(4):
 a=i*pi/2;blades((-.77,.53,.17),a,.58,.10,kelp)
ball((-.78,.52,.28),(.24,.21,.24),pearl)
export('dungeon_reef_span',7500)
clear()
# Broken colonnade: visible horizontal lintel, relief panels and a crystal break.
rock_slab((0,.15,0),(2.70,.30,1.17),astralstone,941)
for x in [-.95,-.10]:
 rock_slab((x,.37,0),(.57,.17,.74),astralstone,943)
 cyl((x,.84,0),.20,.17,.83,astraledge)
 for y in [.48,1.18]:cyl((x,y,0),.27,.27,.11,rune)
rock_slab((-.52,1.38,0),(1.47,.27,.67),astraledge,948)
box((-.52,1.38,.34),(1.22,.055,.045),rune,.012)
for x,h in [(.38,.45),(.71,.81),(1.03,.37)]:
 rock_slab((x,.31,0),(.52,.38,.79),astralstone,955+int(x*10))
 crystal((x,.48,.02),.15,h,star if x<.7 else violetglow,960)
export('dungeon_star_span',6500)
# Ground-level treasure chamber focal points. No collision or path changes.
for biome,base,trim,light in [('forest',foreststone,forestedge,glow),('reef',reefstone,reefedge,blueglow),('star',astralstone,astraledge,violetglow)]:
 clear()
 rock_slab((0,.055,0),(1.23,.11,1.23),base,981,.018)
 cyl((0,.115,0),.49,.49,.055,trim)
 for i in range(8):
  angle=i*pi/4;x=.51*math.cos(angle);z=.51*math.sin(angle)
  o=box((x,.14,z),(.16,.04,.065),rune,.009);o.rotation_euler.z=-angle
 for x in [-.49,.49]:
  if biome=='forest':leaf_rosette((x,.12,.18),987+int(x*10),leafdark,leafbright,.21)
  else:crystal((x,.13,.18),.065,.19,light,3)
 export('dungeon_%s_dais'%biome,4000)
# Junction modules break the repeated wall silhouette at room turns.
# Local +X and +Z face the walkable corner. Footprint stays inside one cell.
clear()
natural_rock((0,.20,0),(1.32,.42,1.25),foreststone,1101)
tube([(-.29,.10,-.30),(-.23,.48,-.24),(-.14,.91,-.19),(-.20,1.37,-.17)],[.34,.29,.23,.13],bark,12)
for a in [0,pi*.5,pi,pi*1.5]:
 x=.52*math.cos(a);z=.52*math.sin(a)
 tube([(-.20,.42,-.17),(x*.55,.20,z*.55),(x,.07,z)],[.16,.10,.035],bark,10)
for i in range(5):
 a=i*2*pi/5
 leaf_rosette((.32*math.cos(a),.42,.32*math.sin(a)),1120+i,leafdark,leafbright,.32)
for i in range(3):
 a=i*2*pi/3
 ball((-.14+.28*math.cos(a),1.34+.09*(i%2),-.17+.28*math.sin(a)),(.50,.37,.50),moss if i%2 else leafdark)
export('dungeon_forest_corner',8500)
clear()
natural_rock((0,.21,0),(1.28,.46,1.28),reefstone,1150)
# Ridged spiral shell: curved ribs around a nacre center, different from branching coral.
for i in range(9):
 a=(i-4)*.25
 x=.42*math.sin(a);y=.36+.52*math.cos(a)
 o=ball((x,y,-.14),(.16,.54,.21),pearl if i%2 else reefedge)
 o.rotation_euler.y=-a
ball((0,.37,.19),(.38,.34,.34),blueglow)
for i in range(3):
 a=i*2*pi/3
 x=.35*math.cos(a);z=.35*math.sin(a)
 tube([(x,.28,z),(x*1.15,.49,z),(x*1.25,.76,z+.07)],[.077,.065,.030],coral if i%2 else coral2,10)
export('dungeon_reef_corner',5500)
clear()
# Carved octagonal pillar with recessed bands and a broken crystal crown.
rock_slab((0,.12,0),(1.22,.24,1.22),astralstone,1200)
cyl((-.13,.27,-.13),.40,.37,.12,astraledge)
cyl((-.13,.71,-.13),.29,.25,.78,astraledge)
for i in range(8):
 a=i*pi/4;x=-.13+.262*math.cos(a);z=-.13+.262*math.sin(a)
 o=box((x,.70,z),(.065,.60,.075),astralstone,.012);o.rotation_euler.z=a
for y in [.35,1.08]:cyl((-.13,y,-.13),.33,.33,.075,rune)
rock_slab((-.13,1.17,-.13),(.79,.14,.74),astralstone,1201)
crystal((-.13,1.26,-.13),.17,.31,violetglow,1202)
for i in range(2):crystal((.30,.15,.15+i*.22),.10,.28+i*.10,star,i)
export('dungeon_star_corner',6500)
# Exterior landscape modules occupy two-by-two nonwalkable cells, not the room perimeter.
# Layered terrain creates continuity behind the wall instead of empty colored planes.
clear()
natural_rock((0,.30,0),(2.45,.65,2.35),foreststone,1301)
natural_rock((-.42,.51,.21),(1.40,.48,1.28),forestedge,1302)
for i in range(6):
 a=i*pi/3
 x=.78*math.cos(a);z=.78*math.sin(a)
 natural_rock((x,.32,z),(.71,.41,.65),moss,1310+i)
 leaf_rosette((x,.51,z),1320+i,leafdark,leafbright,.48)
for i in range(3):
 a=i*2*pi/3
 x=.50*math.cos(a);z=.50*math.sin(a)
 tube([(x,.45,z),(x-.10,.68,z+.14),(x-.21,.87,z+.24)],[.10,.065,.028],bark,10)
 ball((x-.21,.93,z+.24),(.53,.28,.50),cap)
export('dungeon_forest_terrace',9500)
clear()
natural_rock((0,.22,0),(2.44,.49,2.38),reefstone,1401)
for i in range(4):
 a=i*pi/2;x=.58*math.cos(a);z=.58*math.sin(a)
 natural_rock((x,.39,z),(1.12,.44,.94),reefedge,1410+i)
# Low fan shelves, bulb sponges, eel grass and a pearl bed.
for i in range(6):
 a=i*pi/3;x=.76*math.cos(a);z=.76*math.sin(a)
 ball((x,.54,z),(.42,.36,.37),coral2 if i%2 else coral)
 for j in range(3):
  aa=a+j*.8;blades((x,.49,z),aa,.42,.10,kelp)
for i in range(4):
 a=i*pi/2;ball((.26*math.cos(a),.55,.26*math.sin(a)),(.21,.18,.21),pearl)
export('dungeon_reef_terrace',8500)
clear()
rock_slab((0,.15,0),(2.38,.30,2.36),astralstone,1501)
for i in range(3):
 x=(i-1)*.74
 rock_slab((x,.36,-.26+i*.14),(.85,.43+.08*i,1.12),astraledge,1510+i)
 for j in range(2):
  box((x,.53+.045*i,-.43+j*.36),(.58,.045,.055),rune,.009)
for i in range(5):
 a=i*2*pi/5
 crystal((.72*math.cos(a),.42,.72*math.sin(a)),.12,.35+.13*(i%3),star if i%2 else violetglow,i)
export('dungeon_star_terrace',5500)
# Low floor ornaments: underfoot decoration that does not resemble a blocking rock.
clear()
for i in range(4):
 a=i*pi/2
 leaf_rosette((.25*math.cos(a),.012,.25*math.sin(a)),1600+i,leafdark,leafbright,.17)
for i in range(3):
 a=i*2*pi/3
 x=.23*math.cos(a);z=.23*math.sin(a)
 ball((x,.025,z),(.15,.046,.10),forestedge)
export('dungeon_forest_floor_detail',3000)
clear()
for i in range(5):
 a=i*2*pi/5
 x=.24*math.cos(a);z=.24*math.sin(a)
 # Tiny sculpted shell halves rather than identical crystals or coins.
 o=ball((x,.047,z),(.19,.09,.13),pearl if i%2 else reefedge)
 o.rotation_euler.z=a
for i in range(3):
 a=i*2*pi/3;blades((.13*math.cos(a),.02,.13*math.sin(a)),a,.19,.06,kelp)
export('dungeon_reef_floor_detail',2500)
clear()
# Inlaid constellation medallion, almost flush with the floor.
cyl((0,.018,0),.49,.49,.028,astralstone)
for i in range(8):
 a=i*pi/4;x=.40*math.cos(a);z=.40*math.sin(a)
 box((x,.035,z),(.11,.022,.11),rune,.004)
 o=box((.25*math.cos(a),.035,.25*math.sin(a)),(.28,.022,.032),rune,.004)
 o.rotation_euler.z=-a
crystal((0,.032,0),.075,.05,star,1701)
export('dungeon_star_floor_detail',2500)
# Passage entrance trim. Flat traversable middle, asymmetric lantern pillars on
# both sides. Models are aligned along local X and face the room along +Z.
clear()
for side in [-1,1]:
 x=side*.65
 natural_rock((x,.09,0),(.32,.19,.85),foreststone,1800+side)
 tube([(x,.13,-.24),(x+side*.08,.40,-.14),(x+side*.08,.72,.08)],[.105,.09,.045],bark,10)
 ball((x+side*.07,.70,.12),(.19,.22,.19),glow)
 for j in range(3):
  blades((x,.16,-.16+j*.16),j*2.1+side,.26,.065,leafbright)
for i in range(3):
 rock_slab(((i-1)*.33,.015,0),(.30,.04,.68),forestedge,1810+i,.008)
export('dungeon_forest_threshold',3500)
clear()
for side in [-1,1]:
 x=side*.65
 natural_rock((x,.09,0),(.32,.19,.85),reefstone,1820+side)
 for j in range(3):
  tube([(x,.10,-.20+j*.20),(x+side*.08,.30,-.18+j*.20),(x+side*.13,.46+j*.08,-.12+j*.20)],[.065,.048,.021],coral if j%2 else coral2)
 ball((x,.26,.19),(.21,.19,.21),pearl)
for i in range(3):
 o=ball(((i-1)*.33,.022,0),(.27,.045,.31),reefedge)
export('dungeon_reef_threshold',3500)
clear()
for side in [-1,1]:
 x=side*.65
 rock_slab((x,.10,0),(.31,.20,.79),astralstone,1840+side,.018)
 rock_slab((x,.31,0),(.27,.28,.31),astraledge,1842+side,.02)
 crystal((x,.47,0),.105,.28,violetglow,1844+side)
 for z in [-.26,.26]:box((x,.20,z),(.22,.045,.08),rune,.008)
for i in range(3):
 rock_slab(((i-1)*.33,.018,0),(.31,.045,.70),astraledge,1850+i,.008)
 box(((i-1)*.33,.044,0),(.24,.025,.05),rune,.004)
export('dungeon_star_threshold',3500)
with open(os.path.join(OUT,'mesh-metrics.json'),'w') as out: json.dump(stats,out,indent=2)
