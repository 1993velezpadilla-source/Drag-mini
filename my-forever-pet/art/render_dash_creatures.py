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
# Anatomy is authored directly in Godot coordinates. NEVER read stale matrix_world
# after assigning a scale: that was the cause of giant unscaled face-blocking spheres.
from mathutils import Vector
fur=mat('warm ivory fur',(.95,.79,.63),0,.66)
tooth=mat('ivory teeth',(.99,.92,.79),0,.35)
eye_iris=mat('deep violet iris',(.10,.045,.22),0,.19)
palettes=[(.35,.69,.12),(.63,.58,.68),(.65,.36,.15),(.78,.16,.085),(.08,.52,.68),(.29,.64,.75),(.27,.55,.13),(.44,.21,.65),(.12,.36,.76),(.73,.35,.50),(.88,.71,.65),(.34,.22,.15)]
families=['sprout','cat','dog','dragon','fish','alien','dinosaur','jelly','bird','fairy','rabbit','owl']
def shape(name,p,size,material):
 o=ball(p,size,material);o.name=name
 # Bake transforms before another operator or matrix read.
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return o
def limb(name,a,b,w,material):
 a,b=Vector(a),Vector(b);d=b-a
 o=shape(name,(a+b)*.5,(w,d.length+w*.50,w),material)
 o.rotation_euler=Vector(v(d)).to_track_quat('Z','Y').to_euler()
 return o
def tip(name,p,h,r,material,tilt=0):
 o=cyl(p,r,.012,h,material);o.name=name;o.rotation_euler.y=tilt
 return o
def face(x,y,z,spread,scale=1,beak=False):
 # Eye whites and highlights remain in front of the head; named landmarks are
 # checked with actual geometry rays before material merging.
 eyes=[]
 for side in [-1,1]:
  xx=x+side*spread
  eye=shape('eye_%s'%side,(xx,y,z),(.35*scale,.45*scale,.15*scale),eye_iris)
  shape('pupil_%s'%side,(xx,y,z+.064*scale),(.24*scale,.32*scale,.055*scale),dark)
  shape('catchlight_%s'%side,(xx-.05*scale,y+.095*scale,z+.098*scale),(.10*scale,.12*scale,.045*scale),white)
  shape('blush',(xx+side*.16*scale,y-.22*scale,z-.05*scale),(.19*scale,.10*scale,.055*scale),pink)
  eyes.append((xx,y,z))
 if beak:
  shape('beak',(x,y-.20*scale,z+.025*scale),(.34*scale,.23*scale,.28*scale),gold)
  shape('beak line',(x,y-.23*scale,z+.15*scale),(.22*scale,.035*scale,.035*scale),dark)
 else:
  shape('mouth',(x,y-.28*scale,z+.025*scale),(.28*scale,.20*scale,.10*scale),dark)
  shape('tongue',(x,y-.32*scale,z+.072*scale),(.15*scale,.07*scale,.035*scale),pink)
 return eyes
def feet(m,y=.18,front=.22,spread=.35,sz=.56):
 for side in [-1,1]:
  shape('paw',(side*spread,y,front),(sz,.36,.58),m)
  for j in [-1,0,1]:shape('toe',(side*spread+j*.12,y-.015,front+.27),(.10,.11,.075),fur)
def ears(m,head_y,front,kind):
 for side in [-1,1]:
  if kind=='cat':
   tip('pointed ear',(side*.48,head_y+.52,front),.62,.30,m,side*.23)
   tip('inner ear',(side*.48,head_y+.53,front+.13),.40,.17,pink,side*.23)
  elif kind=='dog':
   limb('floppy ear',(side*.61,head_y+.20,front),(side*.76,head_y-.42,front+.12),.40,m)
  else:
   limb('long rabbit ear',(side*.36,head_y+.32,front),(side*.52,head_y+1.04,front-.08),.34,m)
   limb('inner rabbit ear',(side*.38,head_y+.39,front+.16),(side*.50,head_y+.91,front+.09),.19,pink)
def tail(m,points,w):
 for a,b in zip(points,points[1:]):limb('tail',a,b,w,m)
def wing(side,m,accent,y=.95,dragon=False):
 # A separate shaped membrane, rather than another spherical body part.
 if dragon:
  outline=[(.49,0),(.66,.58),(1.22,.83),(1.48,.62),(1.25,.23),(1.02,.34),(.96,-.10),(.76,.05),(.65,-.27)]
 else:
  outline=[(.49,0),(.65,.42),(1.02,.64),(1.36,.50),(1.30,.14),(1.01,-.02),(1.10,-.33),(.82,-.40),(.60,-.21)]
 mesh=bpy.data.meshes.new('wing outline')
 coords=[v((side*x,y+dy,-.36-.16*(x-.49))) for x,dy in outline]
 mesh.from_pydata(coords,[],[list(range(len(coords)))]);mesh.update()
 ob=bpy.data.objects.new('sculpted wing membrane',mesh);bpy.context.scene.collection.objects.link(ob);finish(ob,accent)
 mod=ob.modifiers.new('membrane thickness','SOLIDIFY');mod.thickness=.055
 mod=ob.modifiers.new('soft edges','BEVEL');mod.width=.025;mod.segments=3
 for j in ([2,4,6,8] if dragon else [2,4,7]):
  x,dy=outline[j]
  limb('wing rib',(side*.49,y,-.32),(side*x,y+dy,-.36-.16*(x-.49)),.075,m)
def validate_eyes(eyes,species):
 bpy.context.view_layer.update()
 scene=bpy.context.scene;deps=bpy.context.evaluated_depsgraph_get()
 for x,y,z in eyes:
  origin=Vector(v((x,y,z+4)))
  hit,loc,n,index,obj,matrix=scene.ray_cast(deps,origin,Vector((0,1,0)),distance=8)
  assert hit and obj.name.startswith(('eye_','pupil_','catchlight_')),('occluded eye',species,obj.name if hit else 'no hit')
 print('FACE_VISIBILITY_OK',species,flush=True)
for species in range(1,28):
 clear()
 i=species%12;secret=12<=species<24
 family=families[i] if species<24 else ["devil","ghost","robot","mushroom"][species-24];rgb=palettes[i] if species<24 else [(0.68,.065,.12),(.46,.76,.92),(.28,.40,.56),(.78,.26,.17)][species-24]
 if secret:
  secret_palette=[(.18,.60,.25),(.20,.28,.53),(.45,.20,.10),(.95,.35,.07),(.27,.73,.74),(.36,.15,.67),(.19,.53,.57),(.08,.62,.75),(.85,.46,.12),(.43,.20,.78),(.67,.48,.77),(.20,.23,.42)]
  rgb=secret_palette[i]
 m=mat('skin_%02d'%species,rgb,0,.44)
 a=mat('accent_%02d'%species,tuple(min(1,c*.68+.28) for c in rgb),0,.53)
 if family=='devil':
  shape('imp body',(0,.66,-.12),(.94,1.06,1.02),m)
  shape('imp chest',(0,.64,.34),(.60,.74,.25),a)
  shape('imp head',(0,1.40,.13),(1.35,1.18,1.12),m)
  for side in [-1,1]:
   tip('curved horn',(side*.45,2.05,.08),.50,.19,dark,side*.24)
   shape('horn base',(side*.45,1.91,.08),(.35,.23,.28),a)
   limb('imp arm',(side*.38,.88,.09),(side*.58,.49,.25),.26,m)
   wing(side,dark,a,.86,True)
  feet(m,.18,.38,.32,.51)
  tail(m,[(0,.41,-.55),(.56,.41,-.78),(.85,.75,-.85),(.90,1.05,-.82)],.15)
  tip('arrow tail',(.90,1.17,-.82),.28,.19,a)
  eyes=face(0,1.47,.69,.30,.87)
 elif family=='ghost':
  # One continuous scalloped ghost shell, tapering toward the tail.
  verts=[]; faces=[]; rings=20; steps=40
  for k in range(rings+1):
   theta=pi*k/rings; yy=1.12+.91*math.cos(theta)
   radius=.72*math.sin(theta)
   if k>rings*.6: radius*=1.0+.14*math.sin(theta)
   for j in range(steps):
    ang=2*pi*j/steps; r=radius*(1+.075*math.cos(5*ang)*max(0,(k/rings-.48)*2))
    verts.append(v((r*math.cos(ang),yy+.07*math.sin(5*ang)*math.sin(theta)**3,r*.77*math.sin(ang))))
  for k in range(rings):
   for j in range(steps): faces.append((k*steps+j,k*steps+(j+1)%steps,(k+1)*steps+(j+1)%steps,(k+1)*steps+j))
  mesh=bpy.data.meshes.new('ghost flowing shell');mesh.from_pydata(verts,[],faces);mesh.update()
  ob=bpy.data.objects.new('ghost flowing shell',mesh);bpy.context.scene.collection.objects.link(ob);finish(ob,m)
  for side in [-1,1]:
   limb('floating sleeve',(side*.51,.98,0),(side*.83,.76,.08),.27,a)
   shape('spectral glow spot',(side*.43,.59,.30),(.16,.21,.10),water)
  eyes=face(0,1.38,.57,.29,.90)
 elif family=='robot':
  # Mechanical body, joints, antenna and panel lights.
  shape('robot chassis',(0,.70,-.06),(1.02,1.12,.91),m)
  shape('robot head',(0,1.43,.12),(1.44,1.10,.98),a)
  shape('visor',(0,1.45,.54),(1.24,.69,.24),dark)
  for side in [-1,1]:
   shape('ear speaker',(side*.70,1.43,.05),(.24,.44,.41),gold)
   limb('robot articulated arm',(side*.49,.84,0),(side*.69,.48,.19),.24,m)
   shape('elbow bearing',(side*.59,.65,.10),(.25,.25,.25),gold)
  feet(m,.18,.32,.34,.60)
  limb('antenna',(0,1.90,0),(0,2.22,0),.10,m)
  shape('signal beacon',(0,2.22,0),(.24,.24,.24),water)
  shape('power core',(0,.70,.40),(.38,.36,.14),water)
  eyes=face(0,1.45,.70,.30,.82)
 elif family=='mushroom':
  shape('mushroom stalk',(0,.86,0),(.94,1.30,.90),fur)
  shape('cap dome',(0,1.83,-.02),(1.92,.90,1.60),m)
  shape('cap underside',(0,1.53,-.02),(1.71,.23,1.43),a)
  for j in range(9):
   ang=j*2.4;r=.22+.40*(j%3)/2
   shape('cap speckle',(r*math.cos(ang),2.16-.25*r,r*.78*math.sin(ang)),(.19,.10,.20),fur)
  feet(fur,.17,.27,.25,.48)
  for side in [-1,1]:limb('little arm',(side*.36,.83,.06),(side*.61,.52,.18),.23,fur)
  eyes=face(0,1.09,.46,.23,.72)
 elif family in ('cat','dog','rabbit'):
  shape('torso',(0,.65,-.18),(1.05,1.12,1.12),m)
  shape('chest',(0,.67,.32),(.70,.79,.30),fur)
  shape('head',(0,1.41,.16),(1.42,1.22,1.15),m)
  ears(a,1.48,.15,family)
  feet(m,.19,.45,.35,.55)
  for side in [-1,1]:shape('haunch',(side*.50,.47,-.22),(.56,.61,.67),m)
  tail(a,[(0,.42,-.66),(.48,.54,-.78),(.80,.88,-.78),(.75,1.12,-.73)],.27 if family!='rabbit' else .20)
  eyes=face(0,1.50,.72,.29,.85)
  shape('muzzle',(0,1.16,.72),(.45,.25,.22),fur)
  shape('nose',(0,1.26,.86),(.18,.10,.09),dark)
  shape('smile',(0,1.11,.86),(.19,.07,.06),pink)
 elif family in ('dragon','dinosaur'):
  shape('body',(0,.69,-.18),(1.07,1.22,1.24),m)
  shape('belly',(0,.70,.37),(.66,.89,.33),fur)
  shape('head',(0,1.50,.20),(1.36,1.16,1.12),m)
  shape('snout',(0,1.27,.70),(.78,.43,.62),a)
  shape('jaw',(0,1.09,.72),(.69,.20,.48),fur)
  shape('grin',(0,1.17,.95),(.48,.10,.07),dark)
  for side in [-1,1]:
   shape('nostril',(side*.18,1.37,.98),(.075,.055,.04),dark)
   shape('fang',(side*.22,1.14,.99),(.075,.13,.05),tooth)
   limb('arm',(side*.43,.90,.20),(side*.53,.56,.43),.25,m)
   if family=='dragon':
    tip('horn',(side*.46,2.16,.10),.55,.17,gold,side*.25)
    wing(side,m,a,1.02,True)
  feet(m,.20,.45,.38,.61)
  tail(m,[(0,.50,-.65),(.35,.38,-1.0),(.82,.46,-1.17),(1.12,.70,-1.13)],.33)
  for j in range(5):tip('dorsal spike',(0,1.63-j*.22,-.48-j*.13),.23,.12,gold)
  eyes=face(0,1.64,.72,.34,.77)
 elif family=='fish':
  shape('fish body',(0,.97,0),(1.40,1.30,1.34),m)
  shape('fish belly',(0,.54,.36),(.72,.40,.47),fur)
  for side in [-1,1]:
   limb('pectoral fin',(side*.58,.91,-.04),(side*.97,.60,-.25),.32,a)
   limb('tail lobe',(0,.98,-.65),(side*.43,1.25,-1.04),.36,a)
  shape('dorsal fin',(0,1.64,-.21),(.19,.52,.64),a)
  eyes=face(0,1.12,.65,.30,.88)
 elif family=='alien':
  shape('alien torso',(0,.52,-.04),(.85,.88,.78),m)
  shape('oversize head',(0,1.30,.07),(1.53,1.17,1.14),a)
  for side in [-1,1]:
   limb('antenna',(side*.35,1.75,-.03),(side*.57,2.14,-.06),.12,m)
   shape('antenna tip',(side*.57,2.14,-.06),(.22,.22,.22),gold)
   limb('alien arm',(side*.35,.75,0),(side*.61,.44,.15),.23,m)
  feet(m,.16,.30,.25,.43)
  shape('chest crystal',(0,.61,.39),(.25,.30,.12),water)
  eyes=face(0,1.39,.61,.32,1.05)
 elif family=='jelly':
  shape('jelly dome',(0,1.32,0),(1.65,1.08,1.35),a)
  shape('jelly rim',(0,.92,0),(1.52,.25,1.20),m)
  for j in range(8):
   angle=j*pi/4;x=.52*math.cos(angle);z=.40*math.sin(angle)
   limb('tentacle',(x,.92,z),(x*1.15,.50,z*1.15),.20,m)
   limb('tentacle curl',(x*1.15,.50,z*1.15),(x*1.45,.18,z*1.45),.16,a)
  eyes=face(0,1.32,.67,.31,.85)
 elif family in ('bird','owl'):
  shape('feathered torso',(0,.76,-.10),(1.08,1.24,1.02),m)
  shape('chest plumage',(0,.75,.42),(.81,.83,.32),fur)
  shape('head',(0,1.42,.14),(1.22,1.08,1.00),m)
  for side in [-1,1]:
   shape('folded wing',(side*.56,.83,-.09),(.46,.85,.50),a)
   for j in range(3):limb('primary feather',(side*.55,.88,-.06),(side*(.70+j*.13),.45,-.27),.19,a)
   for j in range(3):shape('bird toe',(side*.28+j*.12,.10,.42),(.14,.18,.32),gold)
   if family=='owl':tip('owl tuft',(side*.40,1.94,.05),.35,.19,a,side*.20)
  if family=='bird':
   for j in range(3):limb('crest',(0,1.76,-.07),((j-1)*.18,2.10,-.20),.16,gold)
  eyes=face(0,1.50,.64,.28,.82,True)
 else:
  shape('mystic body',(0,.71,-.09),(1.00,1.18,1.04),m)
  shape('mystic head',(0,1.43,.10),(1.31,1.15,1.07),a)
  feet(m,.18,.31,.31,.51)
  for side in [-1,1]:
   wing(side,m,fur,1.0)
   limb('petal ear',(side*.45,1.68,.06),(side*.76,1.98,-.06),.27,a)
  flower((0,1.97,.34),1.3)
  eyes=face(0,1.50,.63,.28,.85)
 # Each secret evolution changes the silhouette in a family-specific manner.
 if secret:
  if family in ('cat','dog','rabbit'):
   for side in [-1,1]:
    limb('moon fur plume',(side*.35,.52,-.54),(side*.87,1.02,-.82),.23,a)
   shape('chest jewel',(0,.65,.55),(.18,.23,.12),gold)
  elif family in ('dragon','dinosaur'):
   for j in range(4):tip('evolved spine',(0,1.84-j*.24,-.40-j*.14),.36,.15,gold)
   for side in [-1,1]:shape('arm armor',(side*.53,.71,.40),(.18,.25,.12),gold)
  elif family in ('fish','jelly'):
   for side in [-1,1]:
    limb('reef streamer',(side*.48,.81,-.31),(side*.89,.26,-.62),.18,a)
   for j in range(3):shape('bioluminescent mark',((j-1)*.16,1.62,.41),(.09,.09,.07),gold)
  elif family=='alien':
   for side in [-1,1]:
    limb('stellar antenna branch',(side*.44,1.94,-.08),(side*.76,2.18,-.14),.095,a)
    shape('antenna jewel',(side*.76,2.18,-.14),(.14,.14,.14),water)
  elif family in ('bird','owl'):
   for j in range(5):limb('royal tail feather',((j-2)*.11,.68,-.45),((j-2)*.25,1.28,-.91),.19,gold)
  else:
   for side in [-1,1]:
    limb('flower crown leaf',(side*.36,1.92,-.05),(side*.62,2.18,-.21),.18,green)
   flower((0,2.12,.08),1.3)
 validate_eyes(eyes,species)
 export('species_%02d'%species,42000)
with open(os.path.join(OUT,'creature-metrics.json'),'w') as f:json.dump(stats,f,indent=2)
if '--mesh-only' in sys.argv:
 print('CREATURE_FACE_GATE_PASS',len(stats),flush=True)
 sys.exit(0)
# Render the actual approved GLB plus feet, and each new mesh, for 2D arcade and Petpedia.
# Orthographic portrait is rendered from the GLB itself; no alternate Mosskit mesh.
OUT=ROOT
from mathutils import Vector
for species in range(28):
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
