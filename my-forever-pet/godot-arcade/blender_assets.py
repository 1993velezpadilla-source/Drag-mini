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
 # Fit the four measured oversize woodland singles to their cell, preserving Z/Y silhouette.
 if name=='dungeon_forest_wall' or name.startswith('dungeon_forest_rock_') or name=='dungeon_forest_span':
  extent=max(abs(vertex.co.x) for ob in bpy.context.scene.objects if ob.type=='MESH' for vertex in ob.data.vertices)
  limit=1.39 if name.endswith('_span') else .70
  if extent>limit:
   factor=limit/extent
   for ob in bpy.context.scene.objects:
    if ob.type=='MESH':
     for vertex in ob.data.vertices:vertex.co.x*=factor
     ob.data.update()
 total=0
 for o in bpy.context.scene.objects:
  if o.type=='MESH':
   if name in ('dungeon_coin','dungeon_chest','dungeon_star_floor_detail'):
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
 # Preserve longitudinal grain along the swept branch, including the UV seam.
 uv=me.uv_layers.new(name='Organic grain UV')
 for face in me.polygons:
  ring_indices=[me.loops[li].vertex_index%sides for li in face.loop_indices]
  seam=0 in ring_indices and sides-1 in ring_indices
  for li in face.loop_indices:
   idx=me.loops[li].vertex_index
   u=(idx%sides)/sides
   if seam and idx%sides==0:u=1.0
   uv.data[li].uv=(u,(idx//sides)/max(1,len(path)-1))
 o=bpy.data.objects.new('tangent swept organic branch',me);bpy.context.collection.objects.link(o);return finish(o,m)
def blades(p,a,length,width,m):
 verts=[];faces=[]
 for i in range(7):
  t=i/6;reach=t*length*.65;h=length*(.92*t-.42*t*t);w=width*max(.10,math.sin(pi*t)**.7)
  for side in [-1,1]:verts.append(v((p[0]+math.cos(a)*reach-side*w*math.sin(a),p[1]+h,p[2]+math.sin(a)*reach+side*w*math.cos(a))))
 for i in range(6):faces.append((i*2,i*2+1,i*2+3,i*2+2))
 me=bpy.data.meshes.new('curved leaf');me.from_pydata(verts,[],faces);me.update()
 uv=me.uv_layers.new(name='Leaf UV')
 for face in me.polygons:
  for li in face.loop_indices:
   idx=me.loops[li].vertex_index;uv.data[li].uv=(idx%2,(idx//2)/6)
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
# Original baked material maps for the dungeon kit only. Keep Pet Dash materials unchanged.
# Periodic multi-scale height fields encode relief, strata, bark and coral pores.
def dungeon_surface(m,tint,seed,kind):
 import numpy as np
 rng=np.random.default_rng(seed)
 size=256
 yy,xx=np.mgrid[0:size,0:size].astype(np.float32)*(2*pi/size)
 def waves(freq,count):
  field=np.zeros_like(xx)
  for i in range(count):
   kx,ky=rng.integers(-freq,freq+1,2)
   if not kx and not ky:kx=1
   field+=np.sin(kx*xx+ky*yy+rng.uniform(0,2*pi))
  return field/count
 broad=waves(3,10);medium=waves(12,12);fine=waves(32,16)
 if kind=='bark':
  grain=np.sin(14*xx+1.25*np.sin(2*yy)+.45*np.sin(5*yy+xx))
  split=np.power(.5+.5*grain,8)
  height=.42+.19*broad+.12*medium-.28*split+.025*fine
  tone=.81+.20*broad-.22*split+.08*medium
 elif kind=='coral':
  pores=np.power(.5+.5*np.sin(17*xx+2*np.sin(11*yy))*np.sin(19*yy+np.sin(7*xx)),9)
  height=.48+.12*broad+.12*medium-.23*pores+.035*fine
  tone=.87+.17*broad-.22*pores+.06*medium
 elif kind=='reef':
  strata=np.sin(8*yy+1.15*np.sin(3*xx)+.25*np.sin(9*xx))
  cracks=np.power(.5+.5*strata,10)
  height=.45+.22*broad+.10*medium-.13*cracks+.045*fine
  tone=.86+.18*broad-.14*cracks+.12*medium
 elif kind=='moss':
  height=.44+.21*broad+.14*medium+.065*fine
  tone=.83+.25*broad+.16*medium+.08*fine
 else:
  veins=np.power(.5+.5*np.sin(7*xx+3*yy+2*broad+medium),12)
  height=.46+.20*broad+.11*medium-.13*veins+.045*fine
  tone=.85+.22*broad-.13*veins+.10*medium
 rgba=np.ones((size,size,4),dtype=np.float32)
 for channel in range(3):
  rgba[:,:,channel]=np.clip(tint[channel]*tone,0,1)
 # Tangent-space normals, sampled periodically for seamless tiling.
 dx=np.roll(height,-1,axis=1)-np.roll(height,1,axis=1)
 dy=np.roll(height,-1,axis=0)-np.roll(height,1,axis=0)
 vec=np.stack((-dx*3.6,-dy*3.6,np.ones_like(height)),axis=-1)
 vec/=np.linalg.norm(vec,axis=-1,keepdims=True)
 normal=np.ones_like(rgba);normal[:,:,:3]=vec*.5+.5
 nodes=m.node_tree.nodes;links=m.node_tree.links;bs=nodes.get('Principled BSDF')
 for node in list(nodes):
  if node.type in ('TEX_IMAGE','NORMAL_MAP'):nodes.remove(node)
 def image_node(name,pixels,space):
  im=bpy.data.images.new(m.name+' '+name,width=size,height=size,alpha=True)
  im.colorspace_settings.name=space;im.pixels.foreach_set(pixels.ravel());im.pack()
  node=nodes.new('ShaderNodeTexImage');node.image=im;return node
 albedo=image_node('baked albedo',rgba,'sRGB')
 normal_node=image_node('baked normal',normal,'Non-Color')
 nm=nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.62
 links.new(albedo.outputs['Color'],bs.inputs['Base Color'])
 links.new(normal_node.outputs['Color'],nm.inputs['Color']);links.new(nm.outputs['Normal'],bs.inputs['Normal'])
for m,c,seed,kind in [(foreststone,(.32,.37,.24),431,'stone'),(forestedge,(.38,.41,.27),432,'stone'),(reefstone,(.14,.30,.36),433,'reef'),(reefedge,(.22,.43,.47),434,'reef'),(astralstone,(.25,.20,.34),435,'stone'),(astraledge,(.35,.30,.47),436,'stone'),(bark,(.40,.23,.12),437,'bark'),(moss,(.19,.34,.10),438,'moss'),(coral,(.70,.29,.24),439,'coral'),(coral2,(.44,.20,.43),440,'coral')]:
 dungeon_surface(m,c,seed,kind)
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
def fern_frond(p,a,length,m,pairs=5):
 # Compound fern: a curved central rachis and eight individually shaped pinnae.
 # Double-sided mesh leaves replace the broad, artificial star-shaped ribbons.
 verts=[];faces=[]
 def point(t,offset=0,lift=0):
  reach=length*(.84*t)
  return (p[0]+math.cos(a)*reach-math.sin(a)*offset,
          p[1]+length*(1.24*t-.76*t*t)+lift,
          p[2]+math.sin(a)*reach+math.cos(a)*offset)
 def leaflet(t,side,width):
  j=len(verts)
  for q in [point(t),point(t+.05,side*width*.68),point(t+.17,side*width),point(t+.19,side*width*.30),point(t+.09,side*width*.47,width*.12)]:
   verts.append(v(q))
  faces.extend([(j,j+1,j+4),(j+1,j+2,j+4),(j+2,j+3,j+4),(j+3,j,j+4)])
 for i in range(pairs):
  t=.12+i*.60/max(1,pairs-1)
  width=length*(.22-.096*i/max(1,pairs-1))
  for side in [-1,1]:leaflet(t,side,width)
 start=len(verts)
 for i in range(7):
  t=i/6
  for side in [-1,1]:verts.append(v(point(t,side*length*.014)))
 for i in range(6):faces.append((start+2*i,start+2*i+1,start+2*i+3,start+2*i+2))
 me=bpy.data.meshes.new('compound fern foliage');me.from_pydata(verts,[],faces);me.update()
 o=bpy.data.objects.new('compound fern foliage',me);bpy.context.collection.objects.link(o);finish(o,m)
 m.use_backface_culling=False
def leaf_rosette(p,seed,m1,m2,length=.58,fronds=7,pairs=5):
 rng=random.Random(seed)
 for i in range(fronds):
  ang=i*2*pi/fronds+rng.uniform(-.22,.22)
  span=length*rng.uniform(.76,1.23)
  if m1==leafdark and m2==leafbright:fern_frond(p,ang,span,m1 if i%2 else m2,pairs)
  else:blades(p,ang,span,.12,m1 if i%2 else m2)
# DUNGEON ARCHITECTURE V3: independent sculpted profiles, no stacked rock walls.
# All coordinates are Godot-space. The gameplay grid remains unchanged.
def architectural_mesh(name,verts,faces,m):
 import bmesh
 me=bpy.data.meshes.new(name);me.from_pydata([v(p) for p in verts],[],faces);me.update()
 bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free();me.update()
 uv=me.uv_layers.new(name='Architecture UV')
 for poly in me.polygons:
  axis=max(range(3),key=lambda k:abs(poly.normal[k]));axes=[k for k in range(3) if k!=axis]
  for li in poly.loop_indices:
   co=me.vertices[me.loops[li].vertex_index].co
   uv.data[li].uv=(co[axes[0]]*.85,co[axes[1]]*.85)
 ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);ob.data.materials.append(m)
 for f in me.polygons:f.use_smooth=True
 return ob
def profile_wall(name,width,profile,m,seed,amplitude=.06):
 # Vary a closed cross section along X without making it a row of separate props.
 rng=random.Random(seed);verts=[];faces=[];n=len(profile);steps=17
 for i in range(steps):
  t=i/(steps-1);x=(t-.5)*width
  wave=math.sin(t*pi*2+seed)*amplitude
  for y,z in profile:
   verts.append((x,y*(1+wave),z+amplitude*.45*math.sin(t*pi*4+y*3+seed)))
 for i in range(steps-1):
  for j in range(n):
   a=i*n+j;c=i*n+(j+1)%n;faces.append((a,c,c+n,a+n))
 faces.extend([tuple(reversed(range(n))),tuple(range((steps-1)*n,steps*n))])
 return architectural_mesh(name,verts,faces,m)
def hollow_trunk(x,z,r,h,seed):
 # Annular bark shell with an actual hollow top, irregular root flare and growth rim.
 verts=[];faces=[];n=20
 for k,(yy,rr) in enumerate([(0,1.27),(.17,1.07),(.72,.91),(1,1),(.98,.68),(.54,.55)]):
  for i in range(n):
   a=i*2*pi/n;flute=1+.09*math.sin(a*5+seed)+.04*math.cos(a*9)
   verts.append((x+math.cos(a)*r*rr*flute,h*yy+(.04*math.sin(a*3+seed) if k in (3,4) else 0),z+math.sin(a)*r*rr*flute))
 for k in range(5):
  for i in range(n):
   a=k*n+i;c=k*n+(i+1)%n;faces.append((a,c,c+n,a+n))
 faces.extend([tuple(reversed(range(n))),tuple(range(5*n,6*n))])
 architectural_mesh('hollow ancient bark shell',verts,faces,bark)
 # Raised lip is a separate material so the hollow reads clearly from above.
 rim=[]
 for i in range(n+1):
  a=i*2*pi/n;rim.append((x+r*.83*math.cos(a),h+.018+.04*math.sin(a*3+seed),z+r*.83*math.sin(a)))
 # Use individual short arcs, not a closed sweep with duplicate endpoint.
 for i in range(0,n,4):tube(rim[i:i+5],[r*.075]*5,forestedge,6)
def forest_architecture(width,seed,style=0):
 # Living forest edge: asymmetrical bank with ONE branching tree on long
 # segments. Short segments use exposed roots, not a row of identical stumps.
 half=width*.5
 profile_wall('forest exposed earth',width,[(0,.56),(.20,.48),(.39,.29),(.53,.18),(.59,-.18),(.42,-.48),(0,-.49)],foreststone,seed,.15)
 profile_wall('overhanging moss lip',width,[(.43,.23),(.58,.33),(.65,.10),(.62,-.36),(.44,-.43)],moss,seed+1,.12)
 x=-width*.18 if width>2 else 0.0
 for side in [-1,1]:
  end=side*(half-.09)
  tube([(x,.53,-.16),(x+side*.12,.38,.16),((x+end)*.5,.15,.39),(end,.06,.50)],[.16,.13,.085,.029],bark,12)
 if width>2 or style==0:
  h=1.27 if width>2 else 1.05
  tube([(x,.28,-.14),(x-.07,.66,-.18),(x+.04,h-.21,-.17),(x+.12,h,-.15)],[.20,.17,.12,.065],bark,12)
  for k in range(3):
   a=k*2*pi/3+.40
   rx=x+.29*math.cos(a);rz=-.14+.20*math.sin(a)
   tube([(x,h-.27,-.16),(rx*.6+x*.4,h-.09,rz),(rx,h+.10,rz)],[.075,.052,.025],bark,8)
   ball((rx,h+.13,rz),(.54,.36,.48),moss if k%2 else leafdark)
   leaf_rosette((rx,h+.22,rz),seed+80+k,leafdark,leafbright,.27)
 for k in range(4 if width>2 else 2):
  xx=(k/(3 if width>2 else 1)-.5)*width*.66
  leaf_rosette((xx,.55,-.08),seed+40+k,leafdark,leafbright,.31)
 if style!=2:
  xx=width*.19
  cyl((xx,.26,.42),.035,.027,.16,cream)
  ball((xx,.37,.42),(.22,.11,.20),cap)
def reef_architecture(width,seed,style=0):
 # A cavern face with carved concavity and three overhanging scalloped strata.
 profile_wall('undercut limestone cavern',width,[(0,.52),(.18,.47),(.38,.17),(.62,.12),(.84,.40),(1.07,.42),(1.18,-.06),(.8,-.47),(0,-.49)],reefstone,seed,.09)
 for j in range(2):
  y=.25+j*.53
  profile_wall('continuous mineral shelf',width,[(y-.09,.20),(y,.46+.035*j),(y+.12,.36),(y+.19,-.25),(y-.09,-.33)],reefedge,seed+j*7,.17)
 # Broad folded fan mesh, with scalloped ribs instead of stick-shaped coral.
 for k in range(2 if width>2 else 1):
  x=(-.26+k*.52)*width if width>2 else (style-1)*.12
  verts=[];faces=[];segments=14
  for j in range(3):
   radius=[.09,.33,.55][j]*(1.1 if width>2 else .85)
   for i in range(segments+1):
    a=-1.12+2.24*i/segments
    r=radius*(1+.10*math.cos(i*pi))
    verts.append((x+r*math.sin(a),.85+r*math.cos(a),.08+.09*math.sin(i*.9)*j/2))
  for j in range(2):
   for i in range(segments):
    a=j*(segments+1)+i;faces.append((a,a+1,a+segments+2,a+segments+1))
  ob=architectural_mesh('scalloped sea fan',verts,faces,coral2 if (seed+k)%2 else coral)
  ob.modifiers.new('fan shell thickness','SOLIDIFY').thickness=.018
  for i in range(0,segments+1,3):
   a=-1.12+2.24*i/segments
   tube([(x,.85,.10),(x+.19*math.sin(a),.85+.19*math.cos(a),.15),(x+.44*math.sin(a),.85+.44*math.cos(a),.16)],[.030,.022,.010],coral,6)
 for k in range(3):
  x=(k-1)*width*.24
  ball((x,.43,.28),(.14,.14,.14),pearl)
def temple_arch(cx,base,radius,depth,m,seed):
 # Closed solid arch with inner opening, shaped as one mesh with a keystone.
 verts=[];faces=[];n=17
 for i in range(n):
  a=i*pi/(n-1)
  for rr,z in [(radius,.29),(radius*.73,.29),(radius*.73,.29-depth),(radius,.29-depth)]:
   verts.append((cx+rr*math.cos(a),base+rr*math.sin(a),z))
 for i in range(n-1):
  for j in range(4):
   a=i*4+j;c=i*4+(j+1)%4;faces.append((a,c,c+4,a+4))
 faces.extend([(0,3,2,1),tuple(range((n-1)*4,n*4))])
 architectural_mesh('carved voussoir arch',verts,faces,m)
def star_architecture(width,seed,style=0):
 # Actual temple wall, projecting cornice and blind arched recesses.
 box((0,.18,-.06),(width,.32,.92),astralstone,.035)
 box((0,.64,-.27),(width,.66,.36),astraledge,.035)
 count=2 if width>2 else 1
 for k in range(count):
  bay=width/count;cx=(k-(count-1)*.5)*bay;r=bay*.35
  box((cx,.57,.01),(r*1.40,.60,.05),astralstone,.014)
  temple_arch(cx,.69,r,.25,astraledge,seed+k)
  temple_arch(cx,.69,r*.70,.04,rune,seed+k)
  for side in [-1,1]:
   x=cx+side*r*.86
   box((x,.48,.17),(.13,.55,.27),astraledge,.021)
   for y in [.24,.71]:box((x,y,.18),(.19,.09,.32),rune,.012)
  if style!=1:
   crystal((cx,.35,.21),.10,.28,violetglow,seed+k)
  else:
   ob=box((cx,.48,.09),(.19,.19,.065),rune,.014);ob.rotation_euler.y=pi*.25
 top=1.32 if width>2 else 1.24
 box((0,top,-.10),(width,.14,.72),astraledge,.022)
 box((0,top-.09,.24),(width,.055,.07),rune,.009)
 # Split-height crown: avoid the uninterrupted flat purple block silhouette.
 if style==2:
  box((-width*.28,top+.09,-.20),(width*.26,.08,.39),astralstone,.022)
 elif width>2:
  box((width*.25,top+.10,-.20),(width*.18,.12,.39),astralstone,.022)
architecture={'forest':forest_architecture,'reef':reef_architecture,'star':star_architecture}
for biome,build in architecture.items():
 for variant in range(3):
  clear();build(1.34,2000+variant*13,variant)
  export('dungeon_%s_rock_%d'%(biome,variant),10500)
 clear();build(1.34,2050,1);export('dungeon_%s_wall'%biome,10500)
# Replace small edge clusters with the new language; these do not serve as walls.
clear()
for k in range(4):
 a=k*pi*.5;leaf_rosette((.18*math.cos(a),.05,.18*math.sin(a)),2100+k,leafdark,leafbright,.52)
for x in [-.21,.19]:
 cyl((x,.16,.16),.035,.028,.22,cream);ball((x,.29,.16),(.28,.13,.28),cap)
export('dungeon_forest_cluster',5500)
clear()
for k in range(7):
 a=k*2*pi/7
 tube([(.13*math.cos(a),.04,.13*math.sin(a)),(.26*math.cos(a),.26,.26*math.sin(a)),(.39*math.cos(a),.43,.39*math.sin(a))],[.07,.05,.025],coral if k%2 else coral2)
 ball((.39*math.cos(a),.44,.39*math.sin(a)),(.10,.08,.10),pearl)
export('dungeon_reef_cluster',3500)
clear()
box((0,.12,0),(.76,.22,.75),astralstone,.045)
temple_arch(0,.30,.31,.25,astraledge,2110)
crystal((0,.21,.22),.13,.34,violetglow,2111)
export('dungeon_star_cluster',3500)
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
# Replace long sections with the new continuous architecture, not old rocks.
for biome,build in architecture.items():
 clear();build(2.72,2200,0);export('dungeon_%s_span'%biome,18000)
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
# Junctions are distinct sculpted end pieces, not rotated single walls.
clear()
hollow_trunk(-.08,-.10,.39,1.30,2301)
for a in [0,pi*.5,pi,pi*1.5]:
 tube([(-.08,.48,-.10),(.29*math.cos(a),.23,.29*math.sin(a)),(.60*math.cos(a),.04,.60*math.sin(a))],[.19,.11,.04],bark,12)
leaf_rosette((-.25,.62,.14),2302,leafdark,leafbright,.45)
leaf_rosette((.16,.24,-.28),2303,leafdark,leafbright,.38)
export('dungeon_forest_corner',6000)
clear()
# Spiralling cave buttress with the same continuous stratum language.
for j in range(3):
 y=.19+j*.31
 profile_wall('curved reef buttress shelf',1.10,[(y-.12,.49),(y,.56),(y+.12,.40),(y+.15,-.35),(y-.12,-.42)],reefedge if j%2 else reefstone,2310+j,.12)
for a in [0,pi*.5,pi,pi*1.5]:
 tube([(0,.45,0),(.22*math.cos(a),.76,.22*math.sin(a)),(.40*math.cos(a),1.10,.40*math.sin(a))],[.12,.08,.032],coral2 if a else coral)
ball((.20,.52,.26),(.29,.27,.29),pearl)
export('dungeon_reef_corner',5500)
clear()
# Octagonal temple tower, recessed dark panels and gold cornice.
cyl((0,.14,0),.56,.51,.25,astralstone)
cyl((0,.69,0),.40,.36,.88,astraledge)
for i in range(8):
 a=i*pi/4
 ob=box((.39*math.cos(a),.66,.39*math.sin(a)),(.22,.53,.065),astralstone,.012)
 ob.rotation_euler.z=-a
for y in [.30,1.13]:cyl((0,y,0),.47,.47,.09,rune)
cyl((0,1.26,0),.51,.43,.16,astraledge)
crystal((0,1.34,0),.15,.26,violetglow,2317)
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
# An asymmetric reef ledge that tapers into the sand, not a circular plinth.
# Broad connected limestone shelves and coral colonies grow from the ridge.
natural_rock((-.20,.18,.04),(1.83,.40,1.68),reefstone,1401)
natural_rock((.49,.24,-.24),(1.35,.50,1.53),reefstone,1402)
natural_rock((-.45,.42,-.32),(1.31,.37,1.04),reefedge,1410)
natural_rock((.49,.49,-.30),(1.26,.30,1.03),reefedge,1411)
natural_rock((.08,.29,.52),(1.16,.21,.72),reefedge,1412)
terrace_coral=mat('terrace warm coral',(.72,.21,.15),0,.73)
terrace_tip=mat('terrace peach coral tips',(.94,.45,.25),0,.70)
terrace_fan=mat('terrace mauve sea fans',(.45,.16,.42),0,.70)
for i,(x,y,z,h,m) in enumerate([(-.56,.58,-.28,.52,terrace_coral),(.47,.62,-.36,.69,terrace_fan),(.13,.39,.43,.32,terrace_coral)]):
 tube([(x,y,z),(x-.045,y+h*.55,z+.025),(x+.06,y+h,z)],[.075,.046,.014],m,8)
 for j in range(4):
  angle=j*2.39+i*.7;dx=math.cos(angle);dz=math.sin(angle)
  start=y+h*(.20+j*.11)
  tip=(x+.22*dx,start+h*.56,z+.19*dz)
  tube([(x,start,z),(x+.10*dx,start+h*.24,z+.10*dz),tip],[.044,.026,.009],m,7)
  tube([tip,(tip[0]+.085*dx,tip[1]+.10,tip[2]+.07*dz)],[.019,.006],terrace_tip if i!=1 else m,6)
for i,(x,z,y) in enumerate([(-.79,.33,.33),(.65,.26,.47),(.11,-.67,.38)]):
 for j in range(4):
  blades((x,y,z),i*.9+j*1.7,.32+.07*(j%3),.07,kelp)
for x,z in [(-.27,.66),(.36,.58),(.83,-.04)]:
 ball((x,.28,z),(.16,.10,.12),pearl)
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
# Fallen forked twig, deliberately small and flat to preserve traversal readability.
tube([(-.36,.04,-.24),(-.09,.05,-.16),(.17,.04,-.11),(.34,.035,.07)],[.030,.025,.019,.010],bark,6)
tube([(-.09,.05,-.16),(-.03,.04,-.32),(.09,.03,-.38)],[.018,.014,.008],bark,6)
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
o=cyl((0,.018,0),.49,.49,.028,astralstone)
o.modifiers.get('bevel').width=.003
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
# Exterior world v1: composed landscape groups, no gameplay collision.
# Every group is original modeled geometry and shares existing biome materials.
clear()
# Woodland grove: sculpted lobed crowns with leaf clusters, not spheres.
# Shared material and low segment count keep the silhouette economical.
def woodland_crown(p,dimensions,seed,m):
 rng=random.Random(seed);verts=[];faces=[];n=16;rings=7
 rx,ry,rz=[a*.5 for a in dimensions]
 verts.append((p[0],p[1]-ry,p[2]))
 for j in range(1,rings):
  t=j*pi/rings
  for i in range(n):
   a=i*2*pi/n
   lobes=1+.13*math.sin(a*5+seed*.13+t*2)+.08*math.cos(a*3-t*5)
   wrinkle=1+rng.uniform(-.045,.045)
   verts.append((p[0]+rx*math.sin(t)*math.cos(a)*lobes*wrinkle,p[1]-ry*math.cos(t)+.07*ry*math.sin(a*4+t*3)*math.sin(t),p[2]+rz*math.sin(t)*math.sin(a)*lobes*wrinkle))
 top=len(verts);verts.append((p[0]+rx*.08,p[1]+ry,p[2]))
 for i in range(n):faces.append((0,1+(i+1)%n,1+i))
 for j in range(rings-2):
  for i in range(n):
   a=1+j*n+i;c=1+j*n+(i+1)%n
   faces.append((a,c,c+n,a+n))
 for i in range(n):faces.append((top,1+(rings-2)*n+i,1+(rings-2)*n+(i+1)%n))
 return architectural_mesh('sculpted foliage crown',verts,faces,m)
def crown_leaf(p,a,length,width,m):
 # Closed pointed foliage with an arched midrib and visible thickness.
 # Six triangles per leaflet surface; no costly subdivision or sphere.
 dx=math.cos(a);dz=math.sin(a);sx=-dz;sz=dx
 verts=[p,(p[0]+dx*length*.36+sx*width,p[1]+length*.12,p[2]+dz*length*.36+sz*width),
 (p[0]+dx*length,p[1]+length*.16,p[2]+dz*length),
 (p[0]+dx*length*.36-sx*width,p[1]+length*.12,p[2]+dz*length*.36-sz*width),
 (p[0]+dx*length*.40,p[1]+length*.24,p[2]+dz*length*.40)]
 ob=architectural_mesh('pointed canopy leaflet',verts,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],m)
 m.use_backface_culling=False
 return ob

for k,(x,z,h,r) in enumerate([(-.36,-.18,2.23,.24),(.65,.32,1.48,.14)]):
 tube([(x,0,z),(x-.09,h*.32,z+.08),(x+.12,h*.68,z),(x+.20,h*.88,z-.10)],[r*1.35,r,r*.69,r*.25],bark,12)
 for i in range(4):
  ang=i*pi/2+k*.5
  tube([(x,.24,z),(x+.36*math.cos(ang),.12,z+.36*math.sin(ang)),(x+.62*math.cos(ang),.02,z+.62*math.sin(ang))],[r*.65,r*.4,.025],bark,8)
  xx=x+.42*math.cos(ang);zz=z+.42*math.sin(ang)
  tube([(x+.05,h*.58,z),(xx,h*.78,zz),(xx+.12,h*.91,zz)],[r*.45,r*.27,.025],bark,8)
  dims=(1.03,.64,.96) if k==0 else (.69,.47,.65)
  woodland_crown((xx,h*.89,zz),dims,2400+k*20+i,moss if i%2 else leafdark)
  for j in range(7):
   a2=j*2*pi/7+i*.4
   reach=dims[0]*.26
   crown_leaf((xx+reach*math.cos(a2),h*.96,zz+reach*math.sin(a2)),a2,.24 if k==0 else .18,.09 if k==0 else .065,leafbright if j%3==0 else leafdark)
 woodland_crown((x+.15,h,z),(1.13,.57,1.07) if k==0 else (.72,.45,.68),2440+k,moss)
 for j in range(8):
  a2=j*pi/4
  crown_leaf((x+.15+.22*math.cos(a2),h+.19,z+.22*math.sin(a2)),a2,.27 if k==0 else .19,.105 if k==0 else .075,leafbright)
for i in range(5):
 a=i*2*pi/5;leaf_rosette((.80*math.cos(a),.06,.72*math.sin(a)),2450+i,leafdark,leafbright,.44)
tube([(-.80,.09,.65),(-.35,.11,.55),(.20,.07,.78)],[.09,.075,.025],bark,8)
for x in [-.65,-.36]:
 cyl((x,.13,.68),.045,.035,.19,cream);ball((x,.25,.68),(.24,.12,.23),cap)
export('dungeon_forest_exterior',14000)
clear()
# Reef garden: continuous limestone base, tall ribbon kelp and broad sea fans.
profile_wall('submerged limestone ridge',2.5,[(0,.52),(.28,.48),(.46,.22),(.51,-.15),(.35,-.51),(0,-.52)],reefstone,2501,.15)
# Tall, twisting kelp ribbons. Wider midsections and tapered tips form
# a readable silhouette against the deep-water background.
for i in range(7):
 a=i*2*pi/7;x=.76*math.cos(a);z=.64*math.sin(a)
 h=1.10+.29*(i%3);verts=[];faces=[]
 for j in range(13):
  t=j/12
  reach=.29*t+.10*math.sin(t*pi*2+i)*t
  twist=a+.85*t
  width=.14*max(.06,math.sin(t*pi)**.65)
  for side in [-1,1]:
   verts.append((x+math.cos(a)*reach+side*math.cos(twist)*width,.26+h*t,z+math.sin(a)*reach+side*math.sin(twist)*width))
 for j in range(12):faces.append((j*2,j*2+1,j*2+3,j*2+2))
 ob=architectural_mesh('twisting tall sea kelp',verts,faces,kelp)
 ob.modifiers.new('ribbon thickness','SOLIDIFY').thickness=.012
for k in range(2):
 x=-.56+k*1.10;verts=[];faces=[];n=16
 for j in range(3):
  rad=[.09,.43,.79][j]
  for i in range(n+1):
   ang=-1.12+2.24*i/n;rr=rad*(1+.09*math.cos(i*pi))
   verts.append((x+rr*math.sin(ang),.55+k*.24+rr*math.cos(ang),.05+.12*math.sin(i*.7)*j/2))
 for j in range(2):
  for i in range(n):
   q=j*(n+1)+i;faces.append((q,q+1,q+n+2,q+n+1))
 o=architectural_mesh('large living sea fan',verts,faces,coral if k==0 else coral2)
 o.modifiers.new('fan thickness','SOLIDIFY').thickness=.022
 for i in range(0,n+1,2):
  ang=-1.12+2.24*i/n
  tube([(x,.55+k*.24,.09),(x+.35*math.sin(ang),.55+k*.24+.35*math.cos(ang),.14),(x+.72*math.sin(ang),.55+k*.24+.72*math.cos(ang),.16)],[.035,.021,.008],coral2 if k==0 else coral,6)
for i in range(5):
 a=i*2*pi/5
 ball((.68*math.cos(a),.27,.64*math.sin(a)),(.25,.22,.27),pearl if i%2 else reefedge)
export('dungeon_reef_exterior',9500)
clear()
# Celestial ruin skyline: tall fractured arch over a stepped platform and crystal garden.
rock_slab((0,.12,0),(2.55,.24,1.9),astralstone,2601)
for side in [-1,1]:
 x=side*.82
 box((x,.29,-.18),(.65,.18,.68),astraledge,.035)
 cyl((x,.91,-.18),.24,.21,1.12,astraledge)
 for y in [.42,1.42]:cyl((x,y,-.18),.30,.30,.10,rune)
 for k in range(6):
  a=k*pi/3;ob=box((x+.22*math.cos(a),.93,-.18+.22*math.sin(a)),(.048,.83,.048),astralstone,.007);ob.rotation_euler.z=a
temple_arch(0,1.49,.88,.38,astraledge,2610)
temple_arch(0,1.49,.61,.045,rune,2611)
for x,h in [(-1.0,.46),(-.4,.60),(.37,.83),(.92,.32)]:
 crystal((x,.22,.51),.13,h,star if x<0 else violetglow,2620+int(x*10))
for x in [-.62,.62]:
 rock_slab((x,.27,.73),(.42,.18,.30),astraledge,2630+int(x*10))
export('dungeon_star_exterior',8500)
# Animated exterior inhabitants: geometry is modeled in Blender, motion in Godot.
clear()
# Butterfly with four curved wings and small body; not a glowing sphere.
ball((0,.12,0),(.09,.12,.30),bark)
for side in [-1,1]:
 ball((side*.16,.14,-.06),(.31,.065,.34),cap)
 ball((side*.12,.13,.13),(.23,.05,.23),gold)
 ball((side*.22,.18,-.08),(.08,.026,.10),cream)
export('dungeon_forest_life',2500)
clear()
# Small reef fish, tapered body, distinct tail and fins, horizontal +X direction.
ball((0,.14,0),(.42,.25,.18),reefedge)
ball((.14,.16,.065),(.08,.08,.04),pearl)
ball((.15,.165,.087),(.033,.034,.022),astralstone)
ob=ball((-.24,.14,0),(.22,.27,.058),coral2);ob.rotation_euler.y=.22
ball((-.02,.27,0),(.15,.14,.045),coral)
export('dungeon_reef_life',2500)
clear()
# Suspended astral fragment, narrow brass frame and smaller orbiting shard.
crystal((0,.04,0),.12,.32,star,2701)
crystal((.20,.10,.04),.05,.14,violetglow,2702)
for x in [-.13,.13]:box((x,.16,0),(.035,.25,.035),rune,.006)
export('dungeon_star_life',1600)
# Scenic focal points inspired by the approved visual brief. Built as actual
# three-dimensional meshes, not reference-image billboards.
clear()
# Mossy brook with a sculpted cascade, layered rock ledges and flowering banks.
stream=mat('woodland turquoise stream',(.055,.44,.48),.12,.27)
foam=mat('cascade pale highlights',(.56,.87,.90),.05,.32)
fall_stream=mat('woodland falling sheet',(.07,.48,.51),.12,.24)
fall_foam=mat('woodland falling foam',(.69,.91,.91),.02,.30)
natural_rock((0,.16,.08),(2.72,.32,2.38),foreststone,2800)
# Tall fractured escarpment, connected ledges and a moss-covered upper lip.
natural_rock((-.59,1.12,-.50),(1.30,2.25,1.25),forestedge,2801)
natural_rock((.60,1.00,-.53),(1.23,2.02,1.28),foreststone,2802)
natural_rock((0,1.89,-.68),(1.58,.55,.84),foreststone,2803)
natural_rock((-.63,2.13,-.55),(1.10,.23,.91),moss,2804)
natural_rock((.68,1.78,-.51),(1.02,.30,.88),moss,2805)
natural_rock((-.99,.42,.20),(.54,.66,1.21),moss,2806)
natural_rock((1.00,.38,.20),(.52,.56,1.18),moss,2807)
# Keep the verified staging shoreline, widened to meet the taller waterfall.
ball((0,.27,.46),(2.19,.12,1.65),forestedge)
ball((0,.32,.46),(2.02,.11,1.52),stream)
ball((0,2.20,-.64),(1.02,.07,.62),stream)
# Continuous scalloped water sheet with a broad crest, curved drop and
# widening splash apron. Thin surface geometry instead of four pipe meshes.
def cascade_point(t,u):
 # The crest turns over the cliff, then drops vertically and flares into the pool.
 y=.34+1.88*(1-t**1.24)
 z=-.52+.46*(1-math.exp(-9*t))+.70*t**4
 width=.45+.32*t**3
 # Broad curved sheet with asymmetric channels and a flared impact apron.
 scallop=.012*math.sin(u*19+t*11)*math.sin(t*pi)
 return (u*width+.035*math.sin(t*pi),y+.012*math.sin(u*17+t*11),z+.014*math.cos(u*9+t*4)+scallop)
verts=[];faces=[];rows=19;cols=13
for j in range(rows):
 t=j/(rows-1)
 for i in range(cols):
  u=i/(cols-1)*2-1
  verts.append(cascade_point(t,u))
for j in range(rows-1):
 for i in range(cols-1):
  a=j*cols+i;faces.append((a,a+1,a+cols+1,a+cols))
waterfall=architectural_mesh('continuous cascade sheet',verts,faces,fall_stream)
waterfall.modifiers.new('water sheet depth','SOLIDIFY').thickness=.012
# Long narrow foamy streaks conform to the falling sheet.
for k in range(5):
 u=(k-2)*.30
 points=[]
 for j in range(7):
  t=.04+j*.146
  x,y,z=cascade_point(t,u);points.append((x,y+.006,z+.024))
 tube(points,[.012,.014,.012,.013,.011,.010,.007],fall_foam,6)
for k in range(12):
 a=k*2*pi/12
 ball((.66*math.cos(a),.39,.64+.22*math.sin(a)),(.14+.035*(k%3),.045,.10),foam)
# Fallen log with visible branching and richly planted bank, rather than bare rock.
tube([(-1.01,.28,.18),(-.80,.34,.43),(-.58,.32,.65),(-.31,.25,.78)],[.13,.12,.10,.06],bark,10)
tube([(-.80,.34,.43),(-.65,.48,.38),(-.54,.53,.33)],[.055,.037,.018],bark,8)
for k in range(4):leaf_rosette((-.92+k*.16,.35,.51+k*.06),2820+k,leafdark,leafbright,.22,fronds=4,pairs=3)
for x in [-.78,.78]:
 leaf_rosette((x,.27,.25),2810+int(x*10),leafdark,leafbright,.42,fronds=6,pairs=4)
 for j in range(2):
  xx=x+j*.12
  cyl((xx,.23,.61),.035,.029,.15,cream)
  ball((xx,.33,.61),(.21,.12,.20),cap)
# Daisy petals have a raised curved midrib instead of 20 tiny spheres.
# The flowers retain all five visible petals and golden centers.
for x,z in [(-.71,-.51),(.79,-.44),(.52,.65),(-.49,.68)]:
 for k in range(5):
  ang=k*2*pi/5
  crown_leaf((x+.022*math.cos(ang),.30,z+.022*math.sin(ang)),ang,.095,.039,white)
 ball((x,.34,z),(.075,.05,.075),gold)
# Vegetation on the cliff itself, not merely on the flat floor below it.
for i,(x,y,z) in enumerate([(-.88,1.02,-.22),(.80,1.34,-.30),(-.57,2.22,-.43),(.66,1.88,-.31)]):
 leaf_rosette((x,y,z),2840+i,leafdark,leafbright,.38,fronds=4,pairs=3)
export('dungeon_forest_vista',9500)
clear()
# Hollow sponge tubes, layered plate coral and shell bed; no solid cylinders.
natural_rock((0,.17,0),(2.75,.40,2.20),reefstone,2900)
natural_rock((-.72,.56,-.49),(1.12,1.10,1.04),reefedge,2902)
natural_rock((.65,.48,-.38),(1.19,.87,1.18),reefstone,2903)
# A branching coral silhouette above the sponge bed; asymmetric branches,
# contrasting warm and cool species, with one connected limestone foundation.
for k,(x,z,h) in enumerate([(-.77,-.52,1.45),(.68,-.38,1.80)]):
 m=coral if k==0 else coral2
 tube([(x,.48,z),(x-.06,h*.68,z),(x+.08,h,z)],[.14,.095,.035],m,9)
 for j in range(4):
  side=-1 if j%2==0 else 1
  y=.75+j*.15
  tube([(x,y,z),(x+side*.26,y+.24,z+.07),(x+side*.42,y+.42,z+.03)],[.074,.047,.017],m,7)
def sponge(x,z,h,r,material,seed):
 verts=[];faces=[];n=14
 for y,rr in [(0,r*.82),(h*.47,r*.94),(h,r),(h,r*.61),(h*.33,r*.48)]:
  for i in range(n):
   ang=i*2*pi/n;rad=rr*(1+.06*math.sin(ang*5+seed))
   verts.append((x+rad*math.cos(ang)+y*.10,y+.22,z+rad*math.sin(ang)))
 for k in range(4):
  for i in range(n):
   a=k*n+i;c=k*n+(i+1)%n;faces.append((a,c,c+n,a+n))
 faces.extend([tuple(reversed(range(n))),tuple(range(n*4,n*5))])
 architectural_mesh('hollow reef sponge',verts,faces,material)
 for j in range(6):
  ang=j*2*pi/6
  ball((x+h*.10+r*.88*math.cos(ang),h*.72+.22,z+r*.88*math.sin(ang)),(.065,.09,.065),coral2 if material==coral else coral)
sponge_violet=mat('luminous violet sponge',(.48,.21,.68),0,.49)
sponge_orange=mat('warm tangerine sponge',(.95,.37,.095),0,.54)
for x,z,h,r,m in [(-.69,-.20,.96,.23,sponge_violet),(-.35,-.42,1.28,.25,sponge_violet),(.06,-.20,.72,.20,sponge_orange),(.65,.04,.86,.25,sponge_orange)]:
 sponge(x,z,h,r,m,2901)
for j in range(3):
 ball((.37,.36+j*.17,.37),(.80-j*.13,.095,.65-j*.08),coral2 if j%2 else reefedge)
for k in range(5):
 a=k*2*pi/5;x=-.54+.25*math.cos(a);z=.46+.22*math.sin(a)
 tube([(x,.22,z),(x+.07*math.cos(a),.46,z+.07*math.sin(a)),(x+.17*math.cos(a),.64,z+.17*math.sin(a))],[.065,.042,.022],coral,8)
 ball((x+.17*math.cos(a),.66,z+.17*math.sin(a)),(.07,.065,.07),pearl)
for x,z in [(-.74,.46),(-.26,.63),(.72,.48)]:
 ball((x,.24,z),(.22,.16,.20),pearl)
 for k in range(3):blades((x,.22,z),k*2*pi/3,.42,.09,kelp)
export('dungeon_reef_vista',9500)
clear()
# Suspended observatory island: faceted tapered rock, gilded armillary and crystals.
# Base extends down to the exterior floor, never into playable cells.
verts=[];faces=[];n=12
for y,r in [(0,.16),(.32,.56),(.63,1.04),(.82,.97)]:
 for i in range(n):
  ang=i*2*pi/n;rr=r*(1+.10*math.sin(i*2.7))
  verts.append((rr*math.cos(ang),y,rr*.78*math.sin(ang)))
for k in range(3):
 for i in range(n):
  a=k*n+i;c=k*n+(i+1)%n;faces.append((a,c,c+n,a+n))
faces.extend([tuple(reversed(range(n))),tuple(range(n*3,n*4))])
architectural_mesh('tapered celestial island',verts,faces,astralstone)
for i in range(5):
 a=i*2*pi/5
 x=.72*math.cos(a);z=.55*math.sin(a)
 rock_slab((x,.53,z),(.48,.50,.44),astraledge,2955+i)
 crystal((x,.82,z),.085,.24+.07*(i%3),violetglow,2970+i)
cyl((0,.91,0),.62,.58,.17,astraledge)
cyl((0,1.03,0),.46,.46,.085,rune)
for a in [0,pi/3,2*pi/3]:
 ob=ring((0,1.67,0),.58,.035,rune);ob.rotation_euler.y=a;ob.rotation_euler.z=a*.44
crystal((0,1.31,0),.16,.52,violetglow,2950)
for x,z in [(-.71,.30),(.66,.29),(.42,-.47),(-.40,-.44)]:
 crystal((x,.83,z),.10,.28+.10*abs(x),star,2960+int(x*10))
export('dungeon_star_vista',6500)
# Habitat layers: distinct silhouettes for the wild landscape, economical
# foliage and reef geometry. Designed for non-walkable exterior cells only.
clear()
autumn=mat('amber woodland canopy',(.46,.20,.045),0,.78)
# Ancient split-trunk oak with asymmetric, overlapping sprays. The canopy
# silhouettes use visible leaf tips on outer edges, not only on the top.
spring_leaf=mat('woodland spring leaf',(.18,.34,.065),0,.82)
gold_leaf=mat('woodland golden leaf',(.54,.29,.045),0,.82)
tube([(0,.02,0),(-.12,.58,.06),(-.07,1.18,-.07),(.10,1.78,-.11),(.22,2.23,.04)],[.29,.25,.19,.13,.045],bark,12)
for i in range(6):
 a=i*2*pi/6+.23;dx=math.cos(a);dz=math.sin(a)
 tube([(0,.39,0),(.31*dx,.23,.31*dz),(.59*dx,.09,.59*dz),(.99*dx,.02,.99*dz)],[.15,.12,.075,.018],bark,8)
 # Different branch elevations create open windows through the canopy.
 h=1.65+.14*(i%3)+.09*math.sin(i*2.2)
 x=.62*dx;z=.62*dz
 tube([(-.06,1.10,0),(.32*dx,h-.19,.30*dz),(x,h+.26,z)],[.12,.076,.024],bark,9)
 tube([(.32*dx,h-.19,.30*dz),(x-.18*dz,h+.04,z+.18*dx),(x-.27*dz,h+.13,z+.27*dx)],[.075,.045,.017],bark,7)
 woodland_crown((x,h+.30,z),(.96,.48,.90),3000+i,leafdark if i%2 else moss)
 woodland_crown((x-.25*dz,h+.13,z+.25*dx),(.58,.34,.54),3040+i,spring_leaf)
 for j in range(11):
  ang=j*2*pi/11+i*.5
  reach=.31+.035*math.sin(j*3.1)
  y=h+.27+.13*math.sin(j*1.6)
  crown_leaf((x+reach*math.cos(ang),y,z+reach*math.sin(ang)),ang,.30+.04*(j%3),.10,leafbright if j%3==0 else spring_leaf)
woodland_crown((.18,2.63,.02),(1.25,.58,1.15),3010,moss)
for j in range(14):
 a=j*2*pi/14
 crown_leaf((.18+.40*math.cos(a),2.70+.06*math.sin(j*2),.02+.36*math.sin(a)),a,.31,.11,spring_leaf if j%2 else leafbright)
# A different tree species: narrow fork, tiered hanging sprays, warm leaf edges.
tube([(-.93,0,.39),(-1.00,.48,.39),(-.90,.92,.40),(-.77,1.55,.34)],[.15,.11,.075,.022],bark,9)
for i in range(4):
 ang=i*2*pi/4+.35;dx=math.cos(ang);dz=math.sin(ang)
 x=-.84+.29*dx;z=.37+.29*dz;y=1.20+.13*i
 tube([(-.92,.78,.39),(x,y-.18,z),(x+.14*dx,y,z+.14*dz)],[.064,.045,.012],bark,7)
 woodland_crown((x,y,z),(.66,.38,.60),3020+i,autumn)
 for j in range(7):
  a=j*2*pi/7+ang
  crown_leaf((x+.20*math.cos(a),y+.04,z+.20*math.sin(a)),a,.22,.075,gold_leaf if j%3 else autumn)
for i in range(4):
 ang=i*2*pi/4+.27
 leaf_rosette((.57*math.cos(ang),.06,.57*math.sin(ang)),3030+i,leafdark,leafbright,.46,fronds=4,pairs=3)
export('dungeon_forest_habitat',6500)
clear()
# Woodland ground cover: no pedestal or raised square. Leaf litter and
# low flowering plants join the spaces between mature trees.
for i in range(5):
 a=i*2*pi/5;x=.43*math.cos(a);z=.40*math.sin(a)
 leaf_rosette((x,.035,z),3100+i,leafdark,leafbright,.32+.07*(i%2),fronds=4,pairs=3)
 for j in range(3):
  ang=a+j*1.7;crown_leaf((x+.20*math.cos(ang),.022,z+.20*math.sin(ang)),ang,.17,.055,autumn)
for x,z in [(-.29,.19),(.32,-.12)]:
 for j in range(5):
  a=j*2*pi/5;crown_leaf((x,.20,z),a,.11,.044,white)
 ball((x,.22,z),(.08,.035,.08),gold)
tube([(-.59,.04,-.33),(-.16,.07,-.21),(.18,.05,-.36)],[.053,.039,.012],bark,6)
export('dungeon_forest_understory',2600)
clear()
# Broad sloping limestone shelves, with coral colonies rooted on real ledges.
# Layered irregular profiles replace the isolated upright dark stone towers.
coral_salmon=mat('reef salmon branching coral',(.94,.26,.20),0,.72)
coral_sun=mat('reef golden coral tips',(.96,.56,.13),0,.68)
coral_lilac=mat('reef orchid plate coral',(.64,.24,.62),0,.64)
natural_rock((0,.21,0),(2.58,.45,1.91),reefstone,3198)
natural_rock((-.42,.43,-.11),(1.85,.45,1.36),reefedge,3199)
natural_rock((.54,.51,-.27),(1.42,.73,1.39),reefstone,3200)
natural_rock((.56,.79,-.29),(1.30,.27,1.03),reefedge,3201)
natural_rock((-.53,.64,-.33),(1.32,.32,1.12),reefedge,3202)
def reef_plate(x,y,z,rx,rz,seed,m):
 # Closed, scalloped plate with curved cup and a thicker support center.
 n=18;verts=[(x,y-.055,z)];faces=[]
 for ring_index,(scale,dy) in enumerate([(.38,-.025),(1,.045),(1,.085),(.43,.055)]):
  for j in range(n):
   a=j*2*pi/n;lobes=1+.14*math.sin(a*5+seed*.3)+.07*math.cos(a*3)
   verts.append((x+rx*scale*lobes*math.cos(a),y+dy+.035*scale*math.sin(a*3+seed),z+rz*scale*lobes*math.sin(a)))
 for j in range(n):faces.append((0,1+(j+1)%n,1+j))
 for k in range(3):
  for j in range(n):
   a=1+k*n+j;b=1+k*n+(j+1)%n;faces.append((a,b,b+n,a+n))
 top=len(verts);verts.append((x,y+.055,z))
 for j in range(n):faces.append((top,1+3*n+j,1+3*n+(j+1)%n))
 return architectural_mesh('scalloped living plate coral',verts,faces,m)
for i,(x,y,z,rx,rz) in enumerate([(-.63,.61,-.12,.64,.45),(-.70,.89,-.26,.45,.37),(.58,.82,-.27,.57,.42),(.70,1.04,-.33,.40,.32),(.08,.43,.57,.46,.32)]):
 reef_plate(x,y,z,rx,rz,3220+i,coral_lilac if i%2==0 else coral_salmon)
# Branching antler colonies: forks at varied heights and visible warm tips.
for i,(x,y,z,h,m) in enumerate([(-.65,.84,-.39,1.03,coral_salmon),(.61,1.02,-.39,1.18,coral2),(.10,.37,.48,.83,coral_salmon)]):
 tube([(x,y,z),(x-.04,y+h*.44,z+.04),(x+.05,y+h*.82,z),(x+.12,y+h,z-.03)],[.105,.076,.044,.019],m,9)
 for j in range(5):
  ang=j*2.39+i*.6;dx=math.cos(ang);dz=math.sin(ang);base=y+h*(.24+.09*j)
  tip=(x+.34*dx,base+h*.45,z+.30*dz)
  tube([(x,base,z),(x+.18*dx,base+h*.24,z+.13*dz),tip],[.063,.043,.018],m,7)
  fork=(tip[0]+.13*math.cos(ang+.8),tip[1]+.16,tip[2]+.12*math.sin(ang+.8))
  tube([(x+.18*dx,base+h*.24,z+.13*dz),tip,fork],[.038,.025,.009],coral_sun if j%2==0 else m,6)
for i in range(5):
 a=i*2*pi/5;x=.88*math.cos(a);z=.65*math.sin(a)
 h=1.75+.19*(i%3);verts=[];faces=[]
 for j in range(11):
  t=j/10;reach=.24*t+.14*math.sin(t*2*pi+i)*t;width=.13*max(.08,math.sin(pi*t)**.65)
  for side in [-1,1]:
   verts.append((x+reach*math.cos(a)+side*width*math.cos(a+t),.05+h*t,z+reach*math.sin(a)+side*width*math.sin(a+t)))
 for j in range(10):faces.append((2*j,2*j+1,2*j+3,2*j+2))
 ob=architectural_mesh('deep water ribbon kelp',verts,faces,kelp);ob.modifiers.new('kelp membrane','SOLIDIFY').thickness=.012
export('dungeon_reef_habitat',5400)
clear()
# Seafloor garden: shells, sea stars, branched coral and hollow sponges.
for i in range(3):
 a=i*2*pi/3;x=.36*math.cos(a);z=.36*math.sin(a)
 sponge(x,z,.30+.12*i,.12,sponge_violet if i%2 else sponge_orange,3300+i)
for i in range(5):
 a=i*2*pi/5
 tube([(0,.035,0),(.14*math.cos(a),.08,.14*math.sin(a)),(.30*math.cos(a),.025,.30*math.sin(a))],[.062,.047,.014],sponge_orange,6)
for x,z in [(-.47,.30),(.40,-.35)]:
 for j in range(3):
  a=j*2*pi/3
  tube([(x,.02,z),(x+.08*math.cos(a),.16,z+.08*math.sin(a)),(x+.17*math.cos(a),.33,z+.17*math.sin(a))],[.045,.035,.014],coral,6)
 ball((x,.055,z),(.22,.10,.18),pearl)
export('dungeon_reef_understory',4200)
clear()
# Hanging astral garden island. The rock is broad above and narrow below;
# the top carries carved ruins, a small flowing stream and luminous plants.
verts=[];faces=[];n=12
# Keep the base at the GLB support origin; runtime elevation is separate.
for y,r in [(-.065,.10),(.25,.45),(.76,.91),(1.42,1.28),(1.56,1.20)]:
 for i in range(n):
  a=i*2*pi/n;rr=r*(1+.08*math.sin(i*2.9+y))
  verts.append((rr*math.cos(a),y,rr*.76*math.sin(a)))
for j in range(4):
 for i in range(n):
  a=j*n+i;c=j*n+(i+1)%n;faces.append((a,c,c+n,a+n))
faces.extend([tuple(reversed(range(n))),tuple(range(4*n,5*n))])
architectural_mesh('hanging garden island',verts,faces,astralstone)
# Architectural crown remains below the independent 3.1-unit height gate.
for x in [-.48,.48]:
 cyl((x,1.93,.16),.17,.13,.74,astraledge)
 cyl((x,1.61,.16),.24,.22,.12,rune)
temple_arch(0,2.30,.57,.24,astraledge,3400)
for x,z in [(-.82,.32),(.69,.42),(.27,-.49)]:
 crystal((x,1.56,z),.14,.46,star,3410+int(x*10))
 for i in range(5):
  a=i*2*pi/5;crown_leaf((x,1.58,z),a,.25,.09,violetglow if i%2 else leafdark)
# Reuse the named animated stream material. A continuous curved sheet
# spills over the island edge, not an image or a cylinder.
verts=[];faces=[]
for j in range(10):
 t=j/9
 for i in range(6):
  u=i/5*2-1
  # Water begins above the rim, travels past the widest island shelf
  # before dropping, and ends just above the GLB support origin.
  verts.append((.43*u*(1+.25*t),1.60-1.66*t**2.6,.77+.39*(1-math.exp(-7*t))+.12*t*t))
for j in range(9):
 for i in range(5):
  a=j*6+i;faces.append((a,a+1,a+7,a+6))
o=architectural_mesh('astral garden waterfall',verts,faces,stream);o.modifiers.new('water membrane','SOLIDIFY').thickness=.012
# A shallow luminous source and two narrow flow highlights connect the sheet to the garden.
ball((0,1.58,.63),(.92,.07,.52),stream)
for k in [-1,1]:
 points=[]
 for j in range(9):
  t=j/8
  points.append((k*.18*(1+.25*t),1.612-1.66*t**2.6,.785+.39*(1-math.exp(-7*t))+.12*t*t))
 tube(points,[.012]*8+[.006],foam,6)
export('dungeon_star_habitat',5500)
clear()
# Crystal sanctuary: asymmetric suspended rock with a radiant crystal crown,
# distinct from the arch-and-waterfall island. All geometry is original.
def celestial_island(seed,wide,depth,top):
 n=14;verts=[];faces=[]
 for level,(y,r) in enumerate([(0,.09),(.24,.31),(.65,.66),(top-.18,1),(top,.88)]):
  for i in range(n):
   ang=i*2*pi/n;rr=r*(1+.11*math.sin(i*2.1+seed)+.07*math.cos(i*3.8+level))
   verts.append((rr*wide*math.cos(ang)+.13*(1-r),y+.025*r*math.sin(i*2.7),rr*depth*math.sin(ang)))
 for j in range(4):
  for i in range(n):
   k=j*n+i;l=j*n+(i+1)%n;faces.append((k,l,l+n,k+n))
 faces.extend([tuple(reversed(range(n))),tuple(range(4*n,5*n))])
 return architectural_mesh('fractured celestial island',verts,faces,astralstone)
celestial_island(3600,1.19,.88,1.02)
for i,(x,z,h,r) in enumerate([(-.26,-.12,1.55,.24),(.40,.03,1.02,.18),(-.70,.14,.63,.13),(.22,.54,.48,.12),(.71,-.28,.54,.12)]):
 crystal((x,1.01+h*.20,z),r,h,star if i%2 else violetglow,3610+i)
 rock_slab((x,.99,z),(.43,.16,.35),astraledge,3620+i)
for i in range(9):
 ang=i*2*pi/9
 box((.83*math.cos(ang),1.025,.58*math.sin(ang)),(.13,.045,.065),rune,.009)
 crown_leaf((.78*math.cos(ang),1.05,.60*math.sin(ang)),ang,.21,.07,leafdark if i%2 else violetglow)
export('dungeon_star_crystal_habitat',3900)
clear()
# Broken observatory island: terraces, fractured columns and inset gilding,
# no duplicate waterfall or identical arch silhouette.
celestial_island(3700,1.25,.91,.83)
rock_slab((0,.84,0),(1.85,.18,1.30),astraledge,3701)
for i in range(3):
 box((0,.92+i*.10,.54-i*.16),(1.03,.12,.31),astraledge,.022)
for i,(x,z,h) in enumerate([(-.63,-.35,1.18),(.63,-.35,.70),(-.62,.40,.42)]):
 cyl((x,1.02+h*.5,z),.15,.115,h,astraledge)
 cyl((x,1.00,z),.22,.20,.10,rune)
 cyl((x,1.04+h,z),.17,.14,.10,rune)
 for j in range(3):
  ang=j*2*pi/3
  box((x+.135*math.cos(ang),1.04+h*.45,z+.135*math.sin(ang)),(.035,h*.64,.035),rune,.004)
# Tilted celestial instrument on its own pedestal.
cyl((.14,1.05,-.12),.30,.26,.25,astraledge)
ob=ring((.14,1.63,-.12),.42,.035,rune);ob.rotation_euler.y=.55
crystal((.14,1.38,-.12),.11,.40,violetglow,3720)
for i,(x,z) in enumerate([(-.92,.10),(.88,.35),(.30,-.70)]):
 crystal((x,.86,z),.10,.32,star,3730+i)
export('dungeon_star_ruin_habitat',4400)
clear()
# Low celestial understory, scattered carved fragments with luminous blossoms.
for i in range(3):
 a=i*2*pi/3;x=.35*math.cos(a);z=.35*math.sin(a)
 rock_slab((x,.10,z),(.38,.19,.32),astraledge,3500+i)
 crystal((x,.15,z),.07,.18+.05*i,star,3510+i)
 for j in range(5):
  ang=j*2*pi/5
  crown_leaf((x,.07,z),ang,.23,.078,violetglow if j%2 else leafdark)
for i in range(4):
 a=i*pi/2
 box((.19*math.cos(a),.04,.19*math.sin(a)),(.12,.045,.05),rune,.007)
export('dungeon_star_understory',2400)
clear()
# Original sculpted atmospheric bank: soft overlapping lobes at different
# heights, two tonal layers, with a flattened trailing base.
cloud_shadow=mat('astral cloud lavender shade',(.27,.28,.48),0,.93)
cloud_light=mat('astral cloud pearl lavender',(.61,.62,.82),0,.91)
for p,sz,m in [
 ((-.53,.30,.02),(1.58,.55,1.13),cloud_shadow),
 ((.48,.27,-.12),(1.64,.50,1.08),cloud_shadow),
 ((-.92,.45,.04),(.86,.54,.83),cloud_light),
 ((-.41,.62,-.14),(1.13,.89,.96),cloud_light),
 ((.20,.54,.13),(1.12,.76,1.10),cloud_light),
 ((.79,.43,-.09),(1.0,.57,.82),cloud_light)]:
 ob=ball(p,sz,m)
 for poly in ob.data.polygons:poly.use_smooth=True
export('dungeon_star_cloud_habitat',3800)
with open(os.path.join(OUT,'mesh-metrics.json'),'w') as out: json.dump(stats,out,indent=2)
