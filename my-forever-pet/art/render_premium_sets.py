import bpy, math, os, sys, random
from mathutils import Vector
from math import pi
OUT=sys.argv[sys.argv.index("--")+1] if "--" in sys.argv else "/tmp/pet-art"
os.makedirs(OUT,exist_ok=True)
random.seed(42)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.render.engine='CYCLES'
scene.cycles.samples=64
scene.cycles.use_denoising=True
scene.cycles.max_bounces=5
scene.render.resolution_x=760
scene.render.resolution_y=912
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='JPEG'
scene.render.image_settings.quality=92
scene.render.film_transparent=False
scene.world.color=(.24,.22,.35)
def material(name,rgb,rough=.5,metal=0,emit=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*rgb,1); m.use_nodes=True
    b=m.node_tree.nodes.get('Principled BSDF'); b.inputs['Base Color'].default_value=(*rgb,1); b.inputs['Roughness'].default_value=rough; b.inputs['Metallic'].default_value=metal
    if emit:
        slot=b.inputs.get('Emission Color') or b.inputs.get('Emission')
        if slot is not None: slot.default_value=(*rgb,1)
        strength=b.inputs.get('Emission Strength')
        if strength is not None: strength.default_value=emit
    return m
wall=material('mulberry plaster',(.095,.17,.24)); wood=material('warm wood',(.53,.24,.115),.39); dark=material('walnut',(.18,.075,.10)); blue=material('royal blue velvet',(.105,.16,.65),.67); cream=material('cream cotton',(.92,.82,.68),.75); lilac=material('lilac velvet',(.24,.35,.48),.73); gold=material('star gold',(1,.57,.10),.27,.15); pink=material('rose enamel',(.85,.25,.53),.3); green=material('leaf green',(.11,.43,.18)); leaf2=material('lime leaves',(.34,.63,.19)); purple=material('violet ceramic',(.36,.13,.65),.23); navy=material('deep blue',(.035,.04,.12),.26); glow=material('amber lamp',(1,.60,.13),.3,0,2.0); crystal=material('amethyst',(.63,.17,1),.22,.15,.8); screen=material('blue screen',(.04,.45,1),.3,0,1.3); sky=material('day window',(.10,.52,.90),.6,0,.65); nightSky=material('night window',(.028,.055,.20),.5,0,.35)
def assign(o,m):o.data.materials.append(m);return o
def box(name,loc,dim,m,b=.07,rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=dim
    if rot:o.rotation_euler=rot
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);assign(o,m)
    if b:
        q=o.modifiers.new('soft crafted edge','BEVEL');q.width=b;q.segments=3
        q=o.modifiers.new('weighted corner normals','WEIGHTED_NORMAL')
    return o
def ball(name,loc,scale,m,segments=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=16,radius=1,location=loc);o=bpy.context.object;o.name=name;o.scale=scale;assign(o,m)
    for p in o.data.polygons:p.use_smooth=True
    return o
def cylinder(name,loc,r,depth,m,scale=(1,1,1),rot=None,r2=None):
    if r2 is None:bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=r,depth=depth,location=loc)
    else:bpy.ops.mesh.primitive_cone_add(vertices=48,radius1=r,radius2=r2,depth=depth,location=loc)
    o=bpy.context.object;o.name=name;o.scale=scale
    if rot:o.rotation_euler=rot
    assign(o,m)
    for p in o.data.polygons:p.use_smooth=True
    q=o.modifiers.new('rounded rim','BEVEL');q.width=.035;q.segments=3
    return o
def torus(name,loc,major,minor,m,rot=None,scale=None):
    bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=12,location=loc,major_radius=major,minor_radius=minor);o=bpy.context.object;o.name=name
    if rot:o.rotation_euler=rot
    if scale:o.scale=scale
    assign(o,m)
    for p in o.data.polygons:p.use_smooth=True
    return o
def star(name,loc,r,m,rotation=(pi/2,0,0)):
    pts=[]
    for i in range(10):
        a=pi/2+i*pi/5;rad=r*(1 if i%2==0 else .45);pts.append((rad*math.cos(a),rad*math.sin(a),0))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(pts,[],[list(range(10))]);mesh.update()
    o=bpy.data.objects.new(name,mesh);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=rotation;assign(o,m)
    q=o.modifiers.new('thick star','SOLIDIFY');q.thickness=.055;q=o.modifiers.new('round edges','BEVEL');q.width=.035;q.segments=3
    return o
def light(name,loc,energy,color,size,target):
    d=bpy.data.lights.new(name,'AREA');d.energy=energy;d.color=color;d.shape='DISK';d.size=size
    o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler();return o
def plant(x,y,z,s=1):
    cylinder('plant pot',(x,y,z+.18*s),.22*s,.36*s,wood,r2=.29*s)
    for i in range(7):
        a=i*2*pi/7; o=ball('wax leaf',(x+math.cos(a)*.19*s,y+math.sin(a)*.19*s,z+.56*s),(.115*s,.24*s,.31*s),green if i%2 else leaf2);o.rotation_euler=(.6*math.cos(a),.6*math.sin(a),a)

# Dedicated original sets. All geometry, materials, lighting and hit anchors are
# generated here; the living creature and interaction UI are never baked in.
import json
from bpy_extras.object_utils import world_to_camera_view
scene.cycles.samples=24
scene.render.resolution_x=960
scene.render.resolution_y=640
scene.render.image_settings.quality=94
mint=material('sea glass',(.12,.59,.48),.29)
ivory=material('porcelain',(.83,.90,.86),.25)
terra=material('terracotta',(.59,.20,.10),.45)
water=material('bath water',(.10,.55,.78),.2,.15)
rose=material('rose upholstery',(.68,.21,.32),.48)
moss=material('garden moss',(.10,.30,.085),.67)
neon=material('rose neon',(.86,.055,.35),.35,0,2.2)
neonblue=material('blue neon',(.09,.35,.95),.35,0,1.6)
velvet=material('midnight plum textile',(.13,.065,.21),.82)
richwood=material('dark warm oak',(.18,.072,.032),.54)
cityglass=material('night skyline',(.016,.035,.105),.36,0,.4)
citylight=material('lit windows',(.95,.52,.22),.45,0,1.6)
layout={}
def clear_set():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def room_base(tint):
    box('plaster',(0,3.5,3.7),(12,.24,7.6),tint,.05)
    for side in [-1,1]:box('side wall',(side*5.92,.1,3.7),(.22,7.1,7.6),tint,.045)
    box('floor foundation',(0,-1.9,-.20),(12,11.6,.25),dark,.02)
    for x in range(-5,6):box('wall inset',(x,3.33,2.8),(.06,.1,5.5),dark,.014)
    box('baseboard',(0,3.29,.19),(12,.17,.25),wood,.03)
    for side in [-1,1]:
        x=side*5.25
        box('architectural column',(x,3.04,2.75),(.48,.52,5.5),cream,.08)
        for z in [.35,2.8,5.18]:box('gold column trim',(x,2.99,z),(.61,.62,.13),gold,.035)
    box('ceiling cornice',(0,3.04,5.22),(11.2,.52,.25),wood,.07)
    for side in [-1,1]:
        x=side*2.7
        box('lantern bracket',(x,3.04,4.55),(.12,.45,.12),gold)
        cylinder('lantern shade',(x,2.82,4.28),.23,.38,glow,r2=.32)
        cylinder('lantern cap',(x,2.82,4.51),.35,.08,gold)
        cylinder('lantern base',(x,2.82,4.03),.26,.08,gold)
    for i in range(15):
        box('floor plank',(-5.6+i*.8,-1.8,-.10),(.79,11.3,.18),richwood if i%3 else dark,.012)
    cylinder('window',(0,3.30,3.75),1.22,.12,sky,rot=(pi/2,0,0))
    torus('brass window rim',(0,3.19,3.75),1.25,.10,gold,rot=(pi/2,0,0))
    for x in [-.65,.65]:ball('cloud',(x,3.20,3.93),(.40,.02,.15),cream)
    box('window cross',(0,3.10,3.75),(2.4,.12,.09),wood,.02)
    box('window upright',(0,3.10,3.75),(.09,.12,2.4),wood,.02)
    for x in [-4.7,4.7]:plant(x,2.5,0,1.35)
    cylinder('rug',(0,-1.65,.025),1.7,.05,lilac,scale=(1,.65,1))
    torus('rug embroidery',(0,-1.65,.06),1.48,.035,gold,scale=(1,.65,1))
def bowl(x,y,z):
    cylinder('bowl',(x,y,z+.17),.43,.34,purple,r2=.60)
    torus('rim',(x,y,z+.34),.55,.055,gold)
    for i in range(12):
        a=i*2.4;r=.34*math.sqrt((i+1)/12)
        ball('grain',(x+r*math.cos(a),y+r*math.sin(a),z+.33),(.09,.08,.07),gold,12)
def shelf(x,z,w=2.7):
    box('shelf',(x,2.94,z),(w,.75,.13),wood,.05)
def bottle(x,y,z,m):
    cylinder('bottle',(x,y,z+.28),.20,.55,m)
    cylinder('neck',(x,y,z+.63),.09,.15,ivory)
    cylinder('cork',(x,y,z+.74),.12,.10,gold)
def cabinet(x,y,w=2.5):
    box('cabinet',(x,y,.65),(w,1.1,1.25),mint,.13)
    box('counter',(x,y,1.32),(w+.15,1.2,.16),ivory,.06)
    for dx in [-w/4,w/4]:
        box('door',(x+dx,y-.57,.65),(w/2-.10,.10,1.03),cream,.065)
        ball('knob',(x+dx,y-.65,.74),(.07,.05,.07),gold)
def bed():
    box('bed frame',(-2.95,1.2,.39),(2.9,2.35,.45),wood,.14)
    box('headboard',(-2.95,2.45,1.24),(2.9,.25,1.55),wood,.18)
    box('velvet inset',(-2.95,2.29,1.25),(2.52,.15,1.22),blue,.17)
    box('mattress',(-2.95,1.2,.78),(2.7,2.18,.32),cream,.14)
    for x in [-3.57,-2.34]:ball('pillow',(x,1.97,1.02),(.50,.37,.18),lilac)
    box('duvet',(-2.95,.82,1.0),(2.73,1.40,.28),blue,.15)
    for i in range(8):star('embroidered star',(-4.0+(i%4)*.68,.36+(i//4)*.65,1.16),.17,gold,(0,0,0))
def remove_parts(prefixes):
    for ob in list(scene.objects):
        if ob.name.startswith(prefixes):bpy.data.objects.remove(ob,do_unlink=True)
def tiled_floor(m1,m2):
    for ob in list(scene.objects):
        if ob.name.startswith('floor plank'):bpy.data.objects.remove(ob,do_unlink=True)
    for i in range(12):
        for j in range(8):
            box('ceramic tile',(-5.5+i,-3.8+j,.0),(.97,.97,.12),m1 if (i+j)%2 else m2,.012)
def banner(x,z,m):
    box('banner cloth',(x,3.03,z),(.72,.09,1.45),m,.04)
    box('banner brass rail',(x,2.97,z+.75),(.91,.14,.12),gold,.03)
    star('banner badge',(x,2.94,z),.24,gold)
def camera_render(key,anchors,pet=(0,-1.7,.18),night=False):
    bpy.ops.object.camera_add(location=(0,-12.7,7.8));cam=bpy.context.object
    cam.rotation_euler=(Vector((0,.35,2.1))-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=11.6;scene.camera=cam
    light('warm key',(-4,-4,7),1050,(1,.80,.60),5,(0,0,1))
    light('blue fill',(5,-2,5),680,(.53,.73,1),5,(0,1,1))
    light('rim',(0,4,7),900,(.80,.91,1),4,(0,0,0))
    bpy.context.view_layer.update()
    def project(p):
        q=world_to_camera_view(scene,cam,Vector(p))
        return [round(q.x,4),round(1-q.y,4)]
    points={n:project(p) for n,p in anchors.items()}
    points['pet']=project(pet)
    for n,p in points.items():
        assert .03<p[0]<.97 and .03<p[1]<.97,(key,n,p)
    layout[key]=points
    layout[key]['world_pet']=[pet[0],pet[2],-pet[1]]
    layout[key]['world_targets']={n:[p[0],p[2],-p[1]] for n,p in anchors.items()}
    # Export actual room geometry for Godot; no camera-facing flat background.
    path=os.path.join(OUT,'rooms');os.makedirs(path,exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in scene.objects:
        if ob.type=='MESH': ob.select_set(True)
    # Material batching keeps live room draw calls bounded.
    bpy.context.view_layer.objects.active=next(ob for ob in scene.objects if ob.type=='MESH')
    bpy.ops.object.convert(target='MESH')
    groups={}
    for ob in list(scene.objects):
        if ob.type=='MESH':groups.setdefault(ob.data.materials[0].name,[]).append(ob)
    for group in groups.values():
        bpy.ops.object.select_all(action='DESELECT')
        for ob in group:ob.select_set(True)
        bpy.context.view_layer.objects.active=group[0]
        if len(group)>1:bpy.ops.object.join()
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in scene.objects:
        if ob.type=='MESH':ob.select_set(True)
    result=bpy.ops.export_scene.gltf(filepath=os.path.join(path,key+'.glb'),export_format='GLB',use_selection=True)
    assert 'FINISHED' in result
    scene.render.filepath=os.path.join(OUT,key+'.jpg');bpy.ops.render.render(write_still=True)
    print('PREMIUM_SET_RENDER_OK',key,points,flush=True)
# Kitchen
clear_set();room_base(mint)
tiled_floor(cream,ivory)
for x in [-3.4,3.4]:
    box('kitchen upper cupboard',(x,3.12,4.15),(2.3,.58,1.02),mint,.10)
    for dx in [-.54,.54]:
        box('framed cupboard door',(x+dx,2.78,4.15),(.98,.12,.84),cream,.05)
        ball('cupboard pull',(x+dx,2.69,4.05),(.07,.06,.07),gold)
cabinet(-3.05,1.65,3.2);cabinet(3.05,1.65,2.8)
box('oven',(-3.05,1.03,.73),(1.1,.2,.86),navy,.08)
box('oven window',(-3.05,.9,.70),(.77,.06,.51),screen,.05)
for x in [-3.65,-2.45]:torus('stove burner',(x,1.65,1.44),.28,.06,dark)
cylinder('cooking pot',(-3.65,1.65,1.73),.34,.46,rose);cylinder('lid',(-3.65,1.65,1.98),.38,.08,gold)
for i in range(4):bottle(2.1+i*.44,2.02,1.42,[rose,green,water,purple][i])
shelf(-2.9,2.75);shelf(2.9,2.75)
for i in range(3):cylinder('cup',(-3.5+i*.55,2.85,2.99),.18,.35,[rose,blue,gold][i])
bowl(3.15,-.85,.06)
camera_render('room_kitchen',{'food':(3.15,-.85,.48),'cook':(-3.65,1.65,1.85),'snack':(3,2,1.9)})
# Bathroom
clear_set();room_base(lilac)
remove_parts(('window','brass window rim','cloud','wall inset'))
box('spa mirror',(0,3.13,3.60),(2.35,.12,2.45),water,.18)
for x in [-1.25,1.25]:box('mirror light',(x,3.01,3.60),(.10,.13,2.35),neonblue,.035)
for i in range(6):box('spa mosaic',(-2.25+i*.9,3.22,4.95),(.83,.09,.48),mint if i%2 else ivory,.025)
tiled_floor(ivory,water)
for x in [-3.0,3.0]:
    for i in range(4):
        for j in range(3):box('bath wall tile',(x-1.2+i*.75,3.12,1.0+j*.75),(.72,.08,.72),ivory if (i+j)%2 else mint,.025)
for x in [-3.2,3.2]:
    box('towel rail',(x,2.9,3.15),(1.2,.12,.12),gold)
    box('folded towel',(x,2.79,2.87),(.85,.18,.70),blue if x<0 else rose,.08)
box('tub outer',(-2.9,1.0,.65),(3.1,1.85,1.0),ivory,.27)
box('tub inset',(-2.9,1.0,1.11),(2.65,1.44,.15),water,.22)
for i in range(9):ball('bath bubbles',(-4+i*.27,1.05+random.uniform(-.3,.3),1.27),(.15,.15,.15),cream,12)
torus('faucet',(-3.9,1.65,1.55),.27,.065,gold,rot=(pi/2,0,0))
cabinet(3,1.65,2.6);cylinder('sink',(3,1.65,1.48),.53,.22,ivory);torus('sink rim',(3,1.65,1.60),.46,.045,gold)
bottle(3.85,1.65,1.45,rose);box('soap',(-1.6,.45,1.20),(.38,.24,.13),rose,.06)
cylinder('toilet pedestal',(3.35,-.9,.34),.32,.63,ivory)
ball('toilet bowl',(3.35,-.9,.66),(.55,.68,.32),ivory)
torus('toilet seat',(3.35,-.9,.9),.43,.07,navy,scale=(1,1.18,1))
box('cistern',(3.35,-.35,1.20),(.95,.35,.72),ivory,.13)
camera_render('room_bathroom',{'soap':(-1.6,.45,1.28),'rinse':(-2.9,1.0,1.2),'toilet':(3.35,-.9,.94)})
# Bedroom
clear_set();room_base(velvet);bed()
# Bedroom: a furnished night loft, not a recycled generic wall.
for ob in list(scene.objects):
    if ob.name.startswith(('window','brass window rim','cloud','wall inset')):bpy.data.objects.remove(ob,do_unlink=True)
box('panoramic window',(0,3.29,3.75),(4.3,.16,3.55),cityglass,.10)
for i in range(13):
    x=-1.93+i*.32;h=.40+(i*7%9)*.18
    box('skyline tower',(x,3.16,2.15+h/2),(.26,.06,h),navy,.018)
    for z in range(1,int(h/.23)+1):
        for dx in [-.065,.065]:box('lit apartment',(x+dx,3.105,2.16+z*.21),(.065,.025,.09),citylight,.005)
ball('moon',(1.36,3.13,4.75),(.37,.025,.37),cream,24)
for i in range(18):star('night star',(-1.8+(i*13%19)*.20,3.12,3.95+(i*7%11)*.12),.045,glow)
for x in [-2.15,0,2.15]:box('window mullion',(x,3.04,3.75),(.10,.18,3.55),richwood,.035)
for z in [2.0,3.75,5.5]:box('window rail',(0,3.03,z),(4.4,.18,.12),richwood,.035)
for side in [-1,1]:
    for i in range(6):
        x=side*(2.13+i*.11)
        ball('curtain fold',(x,2.89,3.76),(.14,.18,1.78),purple,16)
    box('curtain tie',(side*2.45,2.65,3.12),(.68,.12,.12),gold,.04)
    box('indirect strip',(side*4.65,3.02,.42),(.10,.12,.45),neonblue,.02)
# Neon paw sign, upholstered bench and plush room accessories.
for x,z in [(-3.95,3.65),(3.95,4.45)]:
    ball('paw neon palm',(x,2.98,z),(.30,.06,.22),neon)
    for i in range(4):ball('paw neon toe',(x+(i-1.5)*.17,2.98,z+.33+(.06 if i in [1,2] else 0)),(.10,.05,.13),neon)
box('desk',(3.15,1.63,1.38),(2.75,1.3,.20),richwood,.09)
for x in [2,4.3]:box('desk leg',(x,1.63,.66),(.17,.17,1.30),richwood,.04)
box('monitor casing',(3.32,2.07,2.05),(1.58,.20,.98),navy,.10)
box('monitor screen',(3.32,1.94,2.05),(1.40,.06,.80),neonblue,.065)
box('keyboard',(3.32,1.35,1.54),(1.15,.40,.08),navy,.04)
for i in range(10):box('keyboard key',(2.86+i*.10,1.31,1.59),(.075,.16,.04),neon,.01)
box('chair seat',(3.2,.36,.72),(.92,.82,.23),velvet,.12)
box('chair back',(3.2,-.05,1.28),(.95,.22,1.16),velvet,.15)
cylinder('chair foot',(3.2,.36,.28),.36,.55,navy)
for i in range(12):star('rug stitch',(-1.30+i*.24,-1.65,.075),.065,gold,(0,0,0))
torus('rug light trim',(0,-1.65,.07),1.55,.035,neon,scale=(1,.65,1))
star('bedside star lamp',(-1.55,1.15,.63),.40,glow)
banner(-4.35,4.95,blue);banner(4.35,5.25,purple)
for i in range(7):star('ceiling constellation',(-2.4+i*.8,3.06,4.85-.23*(i%2)),.12,gold)
cabinet(4.55,2.48,1.1)
cylinder('lamp stem',(4.55,2.48,1.82),.09,.75,gold)
cylinder('lamp shade',(4.55,2.48,2.29),.45,.53,glow,r2=.25)
shelf(3.85,3.1,1.8)
for i in range(6):box('book',(2.24+i*.24,2.9,3.43),(.18,.36,.48),[blue,rose,gold,mint][i%4],.03)
camera_render('room_bedroom',{'lamp':(4.55,2.48,2.29),'sleep':(-2.95,1.05,1.24)})
# Toy room
clear_set();room_base(rose)
remove_parts(('window','brass window rim','cloud'))
box('arcade wall marquee',(0,3.14,3.93),(3.3,.22,1.38),navy,.16)
for i in range(7):star('arcade marquee star',(-1.2+i*.4,2.99,4.0),.14,neon if i%2 else glow)
for x in [-3.0,3.0]:banner(x,3.9,blue if x<0 else purple)
for i in range(4):
    box('toy train carriage',(-3.9+i*.48,-2.1,.24),(.44,.52,.38),[blue,gold,mint,rose][i],.07)
    for side in [-1,1]:cylinder('train wheel',(-3.9+i*.48,-2.1+side*.27,.15),.13,.09,dark,rot=(pi/2,0,0))
cabinet(-3,1.8,2.7);cabinet(3,1.8,2.7)
box('arcade console',(3,1.6,2.15),(1.4,1.0,1.65),purple,.18)
box('screen',(3,1.04,2.4),(1.06,.08,.82),screen,.08)
for i in range(3):ball('buttons',(2.62+i*.30,1.0,1.84),(.10,.10,.08),gold)
for i in range(5):
    box('toy block',(-3.9+i*.43,1.5,1.61),(.4,.4,.40),[blue,gold,mint,rose,purple][i],.07)
ball('play ball',(-2.75,-1,.55),(.54,.54,.54),blue);torus('ball stripe',(-2.75,-1,.55),.52,.08,gold,rot=(.6,.6,.2))
camera_render('room_toy',{'toy':(-2.75,-1,.55),'arcade':(3,1.2,2.15)})
# Garden
clear_set();room_base(moss)
# A real conservatory: glass arches, open sky and stone paths.
remove_parts(('plaster','wall inset','window','brass window rim','cloud','ceiling cornice','floor plank','rug','architectural column','gold column trim','baseboard','lantern'))
box('garden earth',(0,-1.8,-.07),(12,11.3,.16),moss,.025)
for side in [-1,1]:
    box('garden side hedge',(side*5.45,.1,.75),(.88,6.8,1.5),green,.18)
for i in range(7):
    y=-4.2+i*1.23
    box('garden path',(0,y,.025),(2.8,1.12,.08),cream,.12)
for i in range(9):
    x=-5.2+i*1.3
    box('greenhouse mullion',(x,3.31,3.1),(.13,.19,6.1),richwood,.025)
    box('sky panel',(x,3.48,3.1),(1.21,.10,5.95),sky,.015)
    if i%2==0:
        for j in range(3):ball('distant treetop',(x+.27*(j-1),3.34,1.6+j*.32),(.43,.07,.48),leaf2,16)
for z in [1.4,3.0,4.8,6.0]:box('greenhouse crossbeam',(0,3.25,z),(10.8,.22,.13),richwood,.02)
# Garden gets real stone terraces, trellis and flowering foliage rather than empty wall.
for side in [-1,1]:
    x=side*3.7
    box('trellis upright',(x,2.8,2.4),(.16,.23,4.8),wood)
    for z in [1.5,2.2,2.9,3.6,4.3]:
        box('trellis rung',(x,2.8,z),(1.65,.14,.10),wood)
        for j in range(3):
            ball('vine leaf',(x-.6+j*.55,2.69,z+.10),(.22,.11,.18),leaf2,16)
            if j==1:ball('vine blossom',(x,2.56,z),(.13,.09,.13),rose,16)
for side in [-1,1]:
    x=side*3.1
    box('raised planter',(x,1,.45),(2.8,2.3,.86),wood,.12)
    box('soil',(x,1,.90),(2.5,2.0,.12),dark,.045)
    for i in range(6):
        xx=x-.8+(i%3)*.8; yy=.5+(i//3)*.9
        for j in range(4):
            a=j*pi/2;ball('seedling leaf',(xx+.18*math.cos(a),yy+.18*math.sin(a),1.17),(.22,.16,.28),leaf2,12)
        for j in range(3):ball('berry',(xx+.15*math.cos(j*2),yy+.15*math.sin(j*2),1.2),(.10,.10,.10),rose,12)
cylinder('watering can',(-3.1,-1.2,.42),.36,.65,mint)
torus('handle',(-3.1,-.92,.55),.32,.06,gold,rot=(pi/2,0,0))
camera_render('room_garden',{'plant':(-3.1,1,1.2),'harvest':(3.1,1,1.2)})
# Potion lab
clear_set();room_base(purple)
for x in [-4.3,4.3]:
    cylinder('alchemist column',(x,2.45,1.8),.27,3.4,navy)
    for z in [.2,1.8,3.5]:cylinder('brass collar',(x,2.45,z),.36,.14,gold)
    ball('glowing orb',(x,2.45,3.82),(.33,.33,.33),crystal)
for i in range(5):star('arcane constellation',(-1.6+i*.8,3.0,4.85),.16,glow)
cabinet(-3,1.65,3.1);cabinet(3,1.65,3.1)
for x in [-3,3]:
    for z in [2.55,3.55]:
        shelf(x,z)
        for i in range(4):bottle(x-.8+i*.53,2.8,z+.06,[water,rose,green,crystal][i])
cylinder('cauldron',(-3,1.45,1.80),.60,.75,navy,r2=.7)
torus('cauldron rim',(-3,1.45,2.20),.68,.07,gold)
for i in range(6):ball('magic bubble',(-3+random.uniform(-.4,.4),1.4,2.22+i*.09),(.1,.1,.1),crystal,12)
cylinder('crystal stand',(3,1.4,1.57),.52,.28,gold)
for i in range(3):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.43,location=(2.55+i*.45,1.4,2.02))
    o=bpy.context.object;o.scale=(.64,.64,1.4);assign(o,crystal)
camera_render('room_lab',{'medicine':(-3,1.4,2.0),'craft':(3,1.4,2.02)})
with open(os.path.join(OUT,'room_layout.json'),'w') as f:json.dump(layout,f,indent=2)
# Render four arcade backdrops as actual 3D sets.
scene.render.resolution_x=540;scene.render.resolution_y=810
for key,tint,accent in [('star',navy,gold),('flappy',sky,cream),('cloud',lilac,cream),('find',moss,leaf2)]:
    clear_set()
    box('stage', (0,3.8,3),(9,.15,9),tint,.03)
    # Layered miniature sky kingdom and garden edges, leaving the playfield readable.
    for side in [-1,1]:
        for j in range(4):
            x=side*(2.9+.23*(j%2));z=.2+j*1.9;y=3.20
            if key in ('flappy','cloud'):
                ball('floating island',(x,y,z),(.65,.25,.45),stone if 'stone' in globals() else dark,16)
                ball('grassy crown',(x,y-.08,z+.21),(.65,.26,.18),green,16)
                box('tiny tower',(x,y-.08,z+.52),(.29,.26,.56),cream,.045)
                cylinder('tower roof',(x,y-.08,z+.92),.22,.27,blue,r2=.02)
            elif key=='find':
                for k in range(3):ball('border foliage',(x+.18*k,y,z),(.36,.18,.38),green,16)
            else:
                star('outer constellation',(x,y,z),.18,gold)
                ball('distant jewel',(x,y,z+.27),(.08,.04,.08),crystal,12)
    for i in range(24):
        x=random.uniform(-4.2,4.2);z=random.uniform(-.6,6.4);y=3.35
        if key=='star':
            star('gold constellation',(x,y,z),random.uniform(.06,.23),accent)
        elif key=='find':
            ball('garden foliage',(x,y,z),(.48,.19,.46),accent,16)
            if i%3==0:ball('blossom',(x,y-.2,z),(.18,.08,.18),rose,12)
        else:
            ball('cloud puff',(x,y,z),(.58,.18,.27),accent,16)
            ball('cloud crest',(x+.24,y-.04,z+.16),(.34,.18,.31),accent,16)
    bpy.ops.object.camera_add(location=(0,-11,3));cam=bpy.context.object
    cam.rotation_euler=(Vector((0,3.0,3))-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=9;scene.camera=cam
    light('arcade key',(-3,-5,7),1100,(1,.88,.69),6,(0,3,3));light('arcade fill',(4,-3,2),500,(.5,.7,1),5,(0,3,3))
    scene.render.filepath=os.path.join(OUT,'arcade_'+key+'.jpg');bpy.ops.render.render(write_still=True)
    print('PREMIUM_ARCADE_RENDER_OK',key,flush=True)
# Transparent Blender props, used at runtime as moving collision-aligned sprites.
scene.render.resolution_x=256;scene.render.resolution_y=256;scene.render.film_transparent=True
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
for name in ['egg','star','platform','pipe','coin','snack','crystal','medicine']:
    clear_set()
    if name=='egg':
        ball('shell',(0,0,0),(.76,.60,1.0),cream)
        for x,z in [(-.3,.4),(.36,.05),(-.2,-.48)]:ball('shell speckle',(x,-.48,z),(.15,.055,.12),mint)
    elif name=='star':star('reward star',(0,0,0),.93,gold)
    elif name=='platform':
        box('platform stone core',(0,0,-.08),(1.88,.55,.44),blue,.13)
        box('platform brass band',(0,-.02,.03),(1.94,.58,.12),gold,.045)
        box('platform landing surface',(0,0,.15),(1.85,.55,.20),mint,.075)
        for x in [-.67,.67]:ball('platform jewel',(x,-.29,-.09),(.10,.05,.10),crystal)
    elif name=='pipe':
        cylinder('pipe body',(0,0,0),.54,1.8,mint)
        for z in [-.78,.78]:torus('brass end',(0,0,z),.55,.075,gold)
    elif name=='coin':cylinder('gold coin',(0,0,0),.78,.22,gold,rot=(pi/2,0,0));torus('rim',(0,-.14,0),.65,.05,cream,rot=(pi/2,0,0))
    elif name=='snack':bowl(0,0,-.28)
    elif name=='medicine':bottle(0,0,-.45,rose)
    else:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.78);o=bpy.context.object;o.scale=(.68,.68,1.2);assign(o,crystal)
    bpy.ops.object.camera_add(location=(0,-6,1.0));cam=bpy.context.object;cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.45;scene.camera=cam
    light('prop key',(-3,-4,4),400,(1,.83,.62),4,(0,0,0));light('prop fill',(3,-2,2),270,(.5,.7,1),3,(0,0,0))
    if name=='platform':cam.location=(0,-6,2.6);cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=os.path.join(OUT,'premium_'+name+'.png');bpy.ops.render.render(write_still=True)
    print('PREMIUM_PROP_RENDER_OK',name,flush=True)
