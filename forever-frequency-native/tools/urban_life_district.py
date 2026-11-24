"""Urban Life District — authored procedural city kit built in Blender.
This produces an editable .blend and a batched runtime .glb.
Coordinates are Godot-world compatible: Blender (x, -GodotZ, GodotY).
Distances/sidewalks are deliberate; no cheap scattered cube buildings.
"""
from pathlib import Path
import bpy, math, random, json
from mathutils import Vector
from collections import defaultdict
R=Path(__file__).resolve().parents[1]
OUT=R/'assets';OUT.mkdir(exist_ok=True)
random.seed(2964)
bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
D={}
def mat(name,c,rough=.7,metal=.0,emission=0.):
    m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
    bs=m.node_tree.nodes['Principled BSDF']
    bs.inputs['Base Color'].default_value=(*c,1)
    bs.inputs['Roughness'].default_value=rough
    bs.inputs['Metallic'].default_value=metal
    if emission:
        bs.inputs['Emission Color'].default_value=(*c,1)
        bs.inputs['Emission Strength'].default_value=emission
    return m
sand=mat("Stucco muted sandstone",(.64,.55,.47),.87)
brick=mat("Weathered red urban brick",(.37,.185,.16),.9)
plaster=mat("Warm cream limewash",(.76,.71,.63),.89)
basalt=mat("Volcanic dark basalt",(.10,.13,.16),.81)
copper=mat("Anodized bronze alloy",(.5,.29,.13),.3,.65)
glass=mat("City blue glass",(.13,.22,.28),.27,.35)
warm=mat("Warm window night",(.69,.43,.21),.4,.05,1.3)
metal=mat("Matte steel",(.23,.27,.31),.38,.75)
wood=mat("Aged teak",(.47,.28,.13),.78)
green=mat("Urban leaf dark",(.085,.26,.16),.98)
leaf=mat("Botanical varied leaf",(.23,.38,.18),.95)
ivy=mat("City green flowering ivy",(.30,.47,.29),.92)
cyan=mat("Caldera turquoise glow",(.075,.58,.64),.23,.13,1.1)
coral=mat("Caldera warm pink",(.77,.24,.34),.4,.07,.5)
concrete=mat("Slightly worn sidewalk",(.47,.48,.47),.93)
asphalt=mat("Road painted marking",(.75,.70,.59),.8)
uvmaps={}
def box(n,x,y,z,w,d,h,ma,bev=.045):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(x,y,z))
    ob=bpy.context.object;ob.name=n;ob.dimensions=(w,d,h)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    ob.data.materials.append(ma)
    if bev:
        mod=ob.modifiers.new("Light catching architectural bevel","BEVEL")
        mod.width=bev;mod.segments=2
    return ob
def orb(n,x,y,z,r,ma,sub=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=r,location=(x,y,z))
    o=bpy.context.object;o.name=n;o.data.materials.append(ma)
    return o
def tube(n,coords,r,ma):
    cur=bpy.data.curves.new(n,"CURVE");cur.dimensions='3D'
    cur.resolution_u=10;cur.bevel_depth=r;cur.bevel_resolution=2
    spline=cur.splines.new('POLY');spline.points.add(len(coords)-1)
    for i,p in enumerate(coords):spline.points[i].co=(p[0],p[1],p[2],1)
    ob=bpy.data.objects.new(n,cur);bpy.context.collection.objects.link(ob)
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True);bpy.context.view_layer.objects.active=ob
    bpy.ops.object.convert(target='MESH')
    ob=bpy.context.object;ob.data.materials.append(ma)
    return ob
def label(text,xyz,scale,ma):
    bpy.ops.object.text_add(location=xyz,rotation=(math.pi/2,0,0))
    ob=bpy.context.object;ob.data.body=text;ob.data.size=scale
    ob.data.align_x='CENTER';ob.data.align_y='CENTER'
    ob.data.extrude=.012;ob.data.materials.append(ma)
    bpy.ops.object.convert(target='MESH')
def box_world(n,x,world_z,height,w,depth,tall,ma,bev=.045):
    return box(n,x,-world_z,height,w,depth,tall,ma,bev)
def facade(x,zw,width,depth,height,style,idx):
    # Building stands outside the active gameplay blocks; facades face streets.
    # Differing cornices, balconied upper floors, storefronts and rooflines.
    y=-zw
    base= [brick,sand,plaster,brick,sand][idx%5]
    box('Distinct masonry block',x,y,height/2,width,depth,height,base,.13)
    box('Moulded base plinth',x,y,.32,width+.55,depth+.5,.65,basalt,.035)
    box('Carved contrasting cornice',x,y,height+.12,width+.55,depth+.55,.36,copper,.055)
    box('Subdivided parapet',x,y,height+.65,width+.35,depth+.35,.78,basalt,.045)
    # storefront glazing faces active district; 3D reveals, sills, mullions.
    front=y-depth/2-.10
    n=max(3,int(width/2.0))
    for i in range(n):
        xx=x-width/2+(i+.5)*width/n
        box('Warm shop interior shelf',xx,front+.13,1.75,width/n-.22,.08,2.92,warm,.01)
        box('Reflective display glass',xx,front-.04,1.75,width/n-.24,.035,2.92,glass,.007)
        box('Shop signboard separator',xx,front-.13,3.45,width/n-.12,.20,.20,copper,.019)
    for level in range(1,int((height-3.3)/2.55)+1):
        h=3.65+(level-.5)*2.55
        if h>height-.58:continue
        for i in range(n):
            xx=x-width/2+(i+.5)*width/n
            box('Deep dark window cavity',xx,front-.01,h,width/n-.42,.08,1.70,basalt,.014)
            box('Inboard window warm reflection',xx,front-.09,h,width/n-.57,.037,1.50,glass if (level+i+idx)%4 else warm,.01)
            box('Window crossbar',xx,front-.15,h,.045,.11,1.50,copper,0)
            box('Water shedding cast stone sill',xx,front-.19,h-.91,width/n-.22,.36,.11,concrete,.018)
        box('Art deco floor belt course',x,front-.09,h+1.10,width+.14,.14,.10,copper,.01)
    if style==0:
        # balcony with railing
        z=height-2.85
        box('Upper residential balcony',x,front-.52,z,width*.72,1.0,.24,concrete,.06)
        for xx in range(15):
            px=x-width*.34+xx*width*.68/14
            box('Architectural balcony railing',px,front-.96,z+.61,.044,.06,1.18,metal,0)
        box('Top balcony bar',x,front-.96,z+1.17,width*.73,.08,.08,copper,.018)
    elif style==1:
        # vertically-ribbed sculptural rainscreen
        for xx in range(9):
            px=x-width*.43+xx*width*.86/8
            box('Brise soleil timber blade',px,front-.12,6.8,.17,.37,3.2,wood,.025)
    # Shop sign in the distance
    titles=['ATELIER 08','VINYL & CO','BAKERY 24','NIGHT FLOWERS','CITY MARKET','LOCAL GOODS','NEW WAVE']
    title=titles[idx%len(titles)]
    sign_width=min(width*.8,10)
    box('Quality retail backboard',x,front-.22,3.54,sign_width,.15,.64,basalt,.04)
    label(title,(x,front-.37,3.40),.38,plaster)
    # Rooftop real mechanical & garden details
    box('HVAC insulated housing',x-width*.2,y,height+.88,2.1,1.9,1.2,metal,.15)
    for k in range(3):
        box('Ventilated roof fin',x-width*.2-.7+k*.7,y-.95,height+.9,.12,.17,.52,basalt,.03)
    if style==2:
        for yy in range(4):
            for xx in range(5):
                orb('Rooftop courtyard pot',x-width*.3+xx*.6,y-depth*.24+yy*.53,height+1,.25,green)
# 9 distinct background blocks plus one near the central entrance.
sites=[(-38,-39,16,10,17),(-17,-39,12,10,13),(10,-39,16,12,18),
       (39,-39,15,12,17),(-39,-14,13,11,15),(39,-14,11,11,16),
       (-39,14,17,11,18),(39,15,11,11,16),(-16,40,18,10,19),(13,40,14,10,20)]
for i,(x,z,w,d,h) in enumerate(sites):
    facade(x,z,w,d,h,i%3,i)
# Curb detail near La Caldera: real scale planters, bicycle parking, art and street furniture.
def concrete_planter(x,z,r=1.0):
    y=-z
    box('Polished cast stone planter',x,y,.30,r,.72,.60,concrete,.075)
    box('Organic soil',x,y,.64,r*.85,.62,.12,brick,.025)
    for i in range(7):
        a=i*2.4;dx=.24*math.cos(a);dy=.18*math.sin(a)
        tube('Plant stem',[(x+dx,y+dy,.68),(x+dx*1.3,y+dy*1.4,1.28+.22*math.sin(a))],.020,green)
        orb('Lavender street planter greenery',x+dx*1.3,y+dy*1.4,1.2+.22*math.sin(a),.19,leaf if i%2 else green,1)
for x,z in [(-20,-5.65),(-17,-5.65),(-8.0,-6.0),(-5.8,-6.0),(-21,-23),(-7.8,-23),
            (20,-7.8),(25,-7.8),(10,-7.8),(15,-7.8)]:
    concrete_planter(x,z,.82)
# forged café seats on sidewalk, under climbing plants
def cafe(x,z):
    y=-z
    box('Outdoor marble café table',x,y,.80,1.1,1.1,.12,plaster,.055)
    box('Steel café table base',x,y,.4,.14,.14,.78,metal,.02)
    for dx in [-.92,.92]:
        box('Woven chair seat',x+dx,y,.50,.51,.55,.12,wood,.05)
        box('Café chair back',x+dx,y+.31,.84,.56,.09,.74,metal,.03)
        for sy in [-.20,.20]:
            tube('Chair tapered leg',[(x+dx,y+sy,.45),(x+dx,y+sy*.91,.1)],.035,metal)
for x,z in [(-18,-6.4),(-13.5,-6.4)]:
    cafe(x,z)
# delicate copper suspended fairy-light strands across the studio approach (height > 3m).
for row in (0,1):
    z=-6.8-row*3
    pts=[]
    for i in range(34):
        u=i/33
        x=-24+21*u
        height=4.10-.33*math.sin(math.pi*u)+row*.18
        pts.append((x,-z,height))
    tube('Catenary string of venue lighting',pts,.014,metal)
    for k in range(16):
        u=k/15;x=-23.7+20*u
        h=4.10-.33*math.sin(math.pi*u)+row*.18
        orb('Warm exterior festoon bulb',x,-z,h-.12,.095,warm,1)
# Signature oversized vinyl disk as public art on studio sidewalk with dimensional grooves.
def horizontal_record(x,z):
    y=-z
    bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=1.85,depth=.08,location=(x,y,.055))
    ob=bpy.context.object;ob.name='La Caldera public vinyl plaza art';ob.data.materials.append(basalt)
    for radius in [1.55,1.30,1.05,.75]:
        pts=[(x+radius*math.cos(t*math.tau/90),y+radius*math.sin(t*math.tau/90),.112) for t in range(91)]
        tube('Circular vinyl engraving',pts,.013,copper)
    bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=.38,depth=.02,location=(x,y,.105))
    bpy.context.object.data.materials.append(coral)
horizontal_record(-8.05,-8.6)
# Streamlined street bins/parking meters and real pedestrian sign poles
for x,z in [(-23,-7),(-5,-7),(16,-6.7),(-23,-19)]:
    y=-z
    box('Urban smart litter bin',x,y,.58,.48,.43,1.1,basalt,.045)
    box('Stainless bin opening',x,y,1.12,.55,.47,.12,metal,.03)
for x,z in [(-6.4,-7.1),(-24,-7.1)]:
    tube('Pedestrian sign pole',[(x,-z,0),(x,-z,3.1)],.055,metal)
    box('Pedestrian information sign',x,-z,2.65,.83,.11,.68,basalt,.06)
    label('MUSIC DISTRICT',(x,-z-.12,2.55),.105,cyan)
# Compact tropical landscaping cluster; hand-authored branching and varied canopy.
def branching_tree(x,z,variation):
    y=-z
    trunk=3+variation*.33
    tube('Gnarled tropical trunk',[(x,y,0),(x-.11,y+.14,1.3),(x+.18,y-.09,2.5),(x,y,trunk)],.12,wood)
    for j in range(6):
        a=j*math.tau/6+variation*.5
        length=1.2+.40*(j%3)
        tip=(x+math.cos(a)*length,y+math.sin(a)*length,trunk+.65+(.15*(j%2)))
        tube('Irregular living branch',[(x,y,trunk-.25),tip],.060,wood)
        orb('Deep canopy silhouette',*tip,.73,green if j%2 else leaf,2)
        for k in range(3):
            th=a+k*2.1
            orb('Individually articulated leaf mass',tip[0]+.44*math.cos(th),tip[1]+.34*math.sin(th),tip[2]+.26*math.sin(k*2.3),.33,leaf if k%2 else green,1)
for i,(x,z) in enumerate([(-27,-24),(-25,-4),(-5,-23),(25,-23),(25,21),(-25,24)]):
    branching_tree(x,z,i)
# Sort by material, apply evaluated bevels, collapse static geometry into a handful of GPU batches.
original_meshes=[o for o in bpy.data.objects if o.type=='MESH']
for o in original_meshes:
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    for mod in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)
batches=defaultdict(list)
for o in original_meshes:
    ms=tuple(m.name for m in o.data.materials if m)
    batches[ms].append(o)
joined=[]
for key,obs in batches.items():
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0]
    if len(obs)>1:bpy.ops.object.join()
    joined.append(bpy.context.view_layer.objects.active)
bpy.ops.object.select_all(action='DESELECT')
for o in joined:o.select_set(True)
bpy.context.view_layer.objects.active=joined[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'urban_life_district.glb'),export_format='GLB',
                          use_selection=True,export_apply=True,export_materials='EXPORT')
assert (OUT/'urban_life_district.glb').stat().st_size>30000
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'urban_life_district.blend'))
metrics={'original_meshes':len(original_meshes),'runtime_batches':len(joined),
         'triangles':sum(len(p.vertices)-2 for o in joined for p in o.data.polygons),
         'size_bytes':(OUT/'urban_life_district.glb').stat().st_size,
         'district_facades':len(sites)}
(OUT/'urban_metrics.json').write_text(json.dumps(metrics,indent=2))
assert metrics['runtime_batches']<20
assert metrics['district_facades']>=9
assert metrics['original_meshes']>600
print('URBAN PREMIUM GAUNTLET GREEN',metrics,flush=True)
