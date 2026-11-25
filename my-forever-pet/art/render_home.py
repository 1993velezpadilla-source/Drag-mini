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
scene.cycles.samples=24
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
wall=material('mulberry plaster',(.26,.14,.42)); wood=material('warm wood',(.53,.24,.115),.39); dark=material('walnut',(.18,.075,.10)); blue=material('royal blue velvet',(.105,.16,.65),.67); cream=material('cream cotton',(.92,.82,.68),.75); lilac=material('lilac velvet',(.44,.34,.73),.73); gold=material('star gold',(1,.57,.10),.27,.15); pink=material('rose enamel',(.85,.25,.53),.3); green=material('leaf green',(.11,.43,.18)); leaf2=material('lime leaves',(.34,.63,.19)); purple=material('violet ceramic',(.36,.13,.65),.23); navy=material('deep blue',(.035,.04,.12),.26); glow=material('amber lamp',(1,.60,.13),.3,0,2.0); crystal=material('amethyst',(.63,.17,1),.22,.15,.8); screen=material('blue screen',(.04,.45,1),.3,0,1.3); sky=material('day window',(.10,.52,.90),.6,0,.65); nightSky=material('night window',(.028,.055,.20),.5,0,.35)
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
# Room: wall panels, timber flooring and actual geometry.
box('back wall',(0,3.8,3.1),(10,.22,6.3),wall,.025)
for x in [-4.9,-3.7,-2.5,-1.3,-.1,1.1,2.3,3.5,4.7]:box('wall moulding',(x,3.65,3.1),(.075,.10,6.2),dark,.02)
box('baseboard',(0,3.55,.22),(10,.2,.34),dark)
for i in range(14):
    mat=material('floor plank %d'%i,(.42+random.random()*.12,.21+random.random()*.045,.115+random.random()*.025),.48)
    box('floorboard',(i*.78-5.1,-1,-.095),(.77,10.1,.18),mat,.012)
# Round window with a separate outdoor layer.
window=cylinder('window sky',(0,3.53,3.7),1.52,.09,sky,rot=(pi/2,0,0))
torus('round window frame',(0,3.40,3.7),1.55,.13,wood,rot=(pi/2,0,0))
box('window crossbar',(0,3.31,3.7),(3.05,.16,.12),wood);box('window upright',(0,3.3,3.7),(.13,.16,3.05),wood)
box('window sill',(0,3.25,2.05),(3.25,.62,.16),wood)
sun=ball('sun',(0.75,3.43,4.45),(.40,.035,.40),glow)
clouds=[]
for x,z in [(-.75,4.15),(-.36,4.07),(-.9,3.98)]:
    clouds.append(ball('cloud',(x,3.43,z),(.35,.035,.15),cream))
for x,z,s in [(-.9,2.82,.62),(.75,2.81,.65),(-.15,2.72,.42)]:ball('distant foliage',(x,3.43,z),(s,.035,.28),leaf2)
plant(-1.10,3.1,2.15,.85)
# Left bed: wooden frame, ears, pillows, star blanket.
box('bed base',(-2.85,1.3,.43),(2.5,2.5,.42),wood,.15)
for x in [-3.85,-1.85]:
    for y in [.25,2.35]:box('bed foot',(x,y,.17),(.23,.23,.32),dark,.045)
box('headboard',(-2.85,2.65,1.26),(2.55,.30,1.65),wood,.22)
box('headboard upholstered',(-2.85,2.44,1.30),(2.16,.13,1.25),blue,.19)
for x,rot in [(-3.7,-.45),(-2.0,.45)]:
    o=box('cat ear',(x,2.63,2.07),(.57,.30,.66),wood,.13,rot=(0,rot,0));box('ear cushion',(x,2.45,2.08),(.35,.10,.42),pink,.07,rot=(0,rot,0))
box('mattress',(-2.85,1.24,.77),(2.35,2.34,.38),cream,.19)
for x in [-3.4,-2.28]:ball('pillow',(x,2.03,1.03),(.51,.42,.16),lilac)
box('star duvet',(-2.85,.89,.99),(2.32,1.55,.31),blue,.18)
box('duvet drop',(-2.85,.09,.68),(2.35,.16,.67),blue,.08)
for i in range(8):
    x=-3.77+(i%4)*.59;y=.44+(i//4)*.64
    star('blanket embroidery',(x,y,1.16),.15,gold,(0,0,random.uniform(-.5,.5)))
# Rug and scattered soft accessories, no pet baked in.
cylinder('rug edge',(0,-1.3,.027),2.42,.05,blue,scale=(1,.69,1));cylinder('rug woven cream',(0,-1.3,.058),2.17,.045,cream,scale=(1,.69,1));torus('rug inner braid',(0,-1.3,.083),1.81,.065,lilac,scale=(1,.69,1))
for i in range(28):
    a=i*2*pi/28;ball('rug tassel',(2.3*math.cos(a),-1.3+1.57*math.sin(a),.07),(.14,.09,.045),blue,16)
# Shelves and books at right.
for z in [2.70,4.15]:box('floating shelf',(2.98,3.14,z),(2.45,.82,.15),wood,.055)
plant(2.15,3.1,4.24,.9)
for i in range(5):box('book',(1.98+i*.20,3.12,3.04),(.16,.42,.54+(i%3)*.12),[blue,pink,gold,lilac,leaf2][i],.025)
box('monitor',(3.30,3.09,3.29),(1.17,.28,.92),navy,.11);box('monitor glow',(3.30,2.93,3.29),(.92,.045,.65),screen,.07)
cylinder('crystal pedestal',(3.65,3.1,4.28),.36,.15,navy)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.42,location=(3.65,3.1,4.84));o=bpy.context.object;o.name='faceted crystal';o.scale=(.82,.82,1.35);assign(o,crystal)
plant(1.77,2.35,0,1.05)
# Play items, bowls, console.
ball('toy ball',(-1.72,-1.24,.32),(.32,.32,.32),blue);torus('yellow ball stripe',(-1.72,-1.24,.32),.302,.065,gold,rot=(.72,.5,.5))
box('handheld console',(-3.4,-1.03,.20),(1.11,.66,.25),purple,.13,rot=(.13,0,.18))
box('console screen',(-3.4,-1.05,.345),(.54,.37,.04),screen,.04,rot=(.13,0,.18))
for i in range(2):ball('console buttons',(-3.01+i*.13,-1.05,.36),(.055,.055,.045),gold)
cylinder('food bowl',(2.98,-.78,.15),.54,.3,purple,r2=.69);torus('bowl lip',(2.98,-.78,.31),.64,.07,purple);cylinder('kibble surface',(2.98,-.78,.30),.54,.065,dark)
for i in range(22):
    a=i*2.4;r=.46*math.sqrt((i+1)/22);ball('kibble',(2.98+r*math.cos(a),-.78+r*math.sin(a),.37),(.105,.085,.075),gold,16)
# Tiny toy dinosaur on right, distinct from living pet.
ball('dinosaur toy body',(3.62,1.48,.58),(.40,.32,.58),green)
ball('toy belly',(3.62,1.18,.58),(.27,.15,.40),cream)
ball('toy head',(3.62,1.42,1.20),(.43,.35,.39),leaf2)
ball('toy muzzle',(3.62,1.12,1.06),(.33,.24,.20),green)
for dx in [-.19,.19]:ball('toy eye',(3.62+dx,1.13,1.30),(.065,.035,.085),navy)
for dx in [-.29,.29]:ball('toy foot',(3.62+dx,1.30,.18),(.20,.23,.15),leaf2)
for i in range(4):ball('toy spines',(3.62,1.68+i*.06,1.33-i*.22),(.12,.16,.16),gold)
# Hanging lights and foreground greenery.
for x,z in [(-2.15,4.72),(-1.25,5.22),(1.22,4.86)]:
    box('pendant cord',(x,2.9,(6.15+z)/2),(.025,.025,6.15-z),dark,.005)
    star('pendant star',(x,2.9,z),.28,glow)
    d=bpy.data.lights.new('pendant amber','POINT');d.energy=35;d.color=(1,.51,.16);o=bpy.data.objects.new('pendant light',d);scene.collection.objects.link(o);o.location=(x,2.7,z)
plant(-4.15,-2.75,0,1.8)
# Camera: stage backdrop only, with an open floor in the middle for a live pet.
bpy.ops.object.camera_add(location=(0,-13.2,6.9));cam=bpy.context.object;cam.rotation_euler=(Vector((0,.1,2.6))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=9.4;scene.camera=cam
key=light('warm window key',(-3,-4,6),850,(1,.72,.48),5,(0,1,1));fill=light('soft blue fill',(4,-1,5),550,(.40,.59,1),4,(0,1,2));top=light('ceiling bounce',(0,2,6.6),430,(.75,.6,1),4,(0,0,0))
scene.render.filepath=os.path.join(OUT,'home_day.jpg');bpy.ops.render.render(write_still=True)
window.data.materials[0]=nightSky;sun.hide_render=True
for o in clouds:o.hide_render=True
for i in range(12):
    a=i*2.4;r=.25+(.9*((i*7)%13)/13);star('night window star',(math.cos(a)*r,3.42,3.7+math.sin(a)*r),.045,glow)
key.data.energy=90;key.data.color=(.34,.47,1);fill.data.energy=180;top.data.energy=145
scene.render.filepath=os.path.join(OUT,'home_night.jpg');bpy.ops.render.render(write_still=True)
print('FOREVER_PET_BLENDER_RENDER_OK',OUT)
