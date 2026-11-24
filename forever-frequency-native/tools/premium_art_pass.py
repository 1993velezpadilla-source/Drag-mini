"""Forever Frequency premium art pass: Blender geometry, not billboard/sprite tricks.

Works on the editable .blend source BEFORE PBR batching.
Provides sculpted awning surfaces, music waveform sculpture, architectural detail,
rainscreens, planters, foliage, balcony, stage rigging and prop silhouettes.
Original generated meshes remain editable; Godot receives optimized GLBs.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]
SOURCE=R/"assets"/"city_zero_modular.blend"
assert SOURCE.exists(), "Blender authoring source missing"
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
random.seed(20261124)
M=bpy.data.materials
def mat(name, fallback):
    m=M.get(name)
    if m: return m
    m=M.new(name);m.diffuse_color=(*fallback,1);m.use_nodes=True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(*fallback,1)
    return m
copper=mat("Copper trim",(.64,.33,.18))
dark=mat("Anodized midnight facade",(.066,.082,.115))
ink=mat("Deep asphalt charcoal",(.025,.032,.05))
stone=mat("Limestone warm pearl",(.72,.68,.61))
glass=mat("Blue-grey glass",(.12,.22,.26))
wood=mat("Honey oak",(.66,.40,.23))
brick=mat("Terracotta red brick",(.40,.20,.21))
leaf=mat("Leaf lively",(.17,.43,.27))
leaf2=mat("Leaf light",(.25,.50,.28))
green=mat("Leaf deep",(.095,.28,.15))
white=mat("Warm offwhite lettering",(.92,.85,.71))
cyan=mat("Audio turquoise neon",(.10,.75,.79))
amber=mat("Tungsten warm light",(.99,.68,.33))
pink=mat("Caldera hot coral neon",(.98,.20,.35))
rose=mat("Dusty rose plaster",(.61,.36,.43))
black=mat("Metal black",(.075,.083,.09))
cream=mat("Milk plaster",(.83,.78,.68))
plum=mat("Lavender accent",(.37,.27,.55))
COLL=None;SHIFT=0.0
def choose(name,idx):
    global COLL,SHIFT
    COLL=bpy.data.collections[name];SHIFT=idx*24.0
def link(o,ma):
    for c in list(o.users_collection):c.objects.unlink(o)
    COLL.objects.link(o)
    o.data.materials.append(ma)
    return o
def block(name,x,y,z,sx,sy,sz,ma,bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(x+SHIFT,y,z))
    o=bpy.context.object;o.name=name
    o.dimensions=(sx,sy,sz)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    link(o,ma)
    if bevel:
        mod=o.modifiers.new("Architectural micro-bevel","BEVEL")
        mod.width=bevel;mod.segments=3
    return o
def sphere(name,x,y,z,r,ma):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=r,location=(x+SHIFT,y,z))
    o=bpy.context.object;o.name=name
    link(o,ma)
    for face in o.data.polygons:face.use_smooth=True
    return o
def tube(name,pts,r,ma,res=5):
    cu=bpy.data.curves.new(name,"CURVE");cu.dimensions='3D';cu.resolution_u=16
    cu.bevel_depth=r;cu.resolution_u=12;cu.bevel_resolution=res
    spline=cu.splines.new('POLY');spline.points.add(len(pts)-1)
    for i,p in enumerate(pts):spline.points[i].co=(p[0]+SHIFT,p[1],p[2],1)
    o=bpy.data.objects.new(name,cu);COLL.objects.link(o)
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.object.convert(target='MESH')
    o=bpy.context.object;o.data.materials.append(ma)
    return o
def surface(name,verts,faces,ma):
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata([(x+SHIFT,y,z) for x,y,z in verts],[],faces)
    mesh.update()
    o=bpy.data.objects.new(name,mesh);COLL.objects.link(o);o.data.materials.append(ma)
    for poly in mesh.polygons:poly.use_smooth=True
    mod=o.modifiers.new("Fabric thickness","SOLIDIFY");mod.thickness=.055
    return o
def awning(name,left,right,yfront,yback,top,drop,ma):
    n=28;d=8;verts=[];faces=[]
    for j in range(d+1):
        v=j/d;y=yback+(yfront-yback)*v
        for i in range(n+1):
            u=i/n;x=left+(right-left)*u
            sag=.16*math.sin(math.pi*v)+.045*math.sin(u*math.pi*10)*v*v
            verts.append((x,y,top-drop*v-sag))
    for j in range(d):
        for i in range(n):
            a=j*(n+1)+i
            faces.append((a,a+1,a+1+n+1,a+n+1))
    surface(name,verts,faces,ma)
    for x in [left,(left+right)/2,right]:
        tube(name+" forged awning rib",[(x,yback,top+.05),(x,yfront,top-drop)],.022,copper)
def planter(x,y,z,size=.9):
    block("Basalt raised planter",x,y,z+.24,size,.8,.48,dark,.06)
    block("Topsoil",x,y,z+.50,size*.83,.68,.07,brick,.01)
    for j in range(9):
        a=j*2.399963;rad=.23*math.sqrt((j+1)/9)
        h=.75+.40*random.random()
        tube("Climbing shrub stem",[(x+rad*math.cos(a),y+rad*math.sin(a),z+.48),
             (x+rad*math.cos(a)*1.3,y+rad*math.sin(a)*1.3,z+h)],.02,green,3)
        sphere("Small leafy natural plant",x+rad*math.cos(a)*1.3,y+rad*math.sin(a)*1.3,z+h,.15,leaf if j%2 else leaf2)
counts={}
def start(name,idx):
    choose(name,idx);return len([o for o in COLL.objects if o.type=='MESH'])
def finish(name,initial):
    counts[name]=len([o for o in COLL.objects if o.type=='MESH'])-initial
# LA CALDERA: a distinctive landmark. Professional building needs silhouette,
# glazing depth, scale references and acoustic identity, not another flat box.
first=start("la_caldera_records",0)
for floor in (5.85,6.9,7.95):
    for x in (-5.30,5.30):
        block("Finned facade acoustic baffle",x,-5.56,floor,.20,.50,.98,copper,.045)
for xx in [-4.7,-3.9,-3.1,3.1,3.9,4.7]:
    tube("Recessed electric window ribbon",[(xx,-5.57,5.75),(xx,-5.57,7.7)],.028,amber,3)
# sculpted circular record rim and a variable waveform.
wave=[]
for n in range(65):
    x=-2.5+5*n/64
    z=9.32 + .24*math.sin(n*.48)*math.sin(n*.096) + .07*math.sin(n*.14)
    wave.append((x,-5.53,z))
tube("La Caldera signature soundwave sculpture",wave,.035,cyan)
for y in (-4.2,2.7):
    for x in (-5.2,5.2):
        planter(x,y,10.25,.88)
for x in [-4.45,4.45]:
    tube("Entrance canopy hanging downlight",[(x,-5.85,3.58),(x,-5.85,3.39)],.09,amber)
for x in [-5.6,-4.2,-2.8,2.8,4.2,5.6]:
    block("Entrance fluted limestone pier",x,-5.19,1.45,.10,.18,2.95,stone,.035)
# Warm modern timber acoustic balcony grid and rooftop pergola.
for x in [-4.3,-2.3,-.3,1.7,3.7]:
    block("Rooftop pergola overhead beam",x,0.8,11.48,.12,7.8,.13,copper,.02)
for y in (-3.1,3.1):
    block("Pergola longitudinal brass rail",0,y,11.46,9,.10,.10,copper)
for x in (-5.45,5.45):
    for y in (-4.45,-2.2,.05,2.3,4.45):
        block("Parapet screen pilaster",x,y,11.16,.12,.12,1.25,dark,.02)
for x in [-4.9,-3.4,3.4,4.9]:
    for z in [4.53,4.77]:
        block("Neon bounce light strip",x,-5.52,z,1.10,.07,.025,amber,.009)
finish("la_caldera_records",first)
# MOON MARKET: upscale corner market, carved awnings, outdoor café, retail depth.
first=start("moon_market",1)
awning("Moon Market flowing fabric canopy",-5.1,5.1,-5.8,-4.95,4.15,.73,rose)
for x in (-4.1,-2.7,-1.3,1.3,2.7,4.1):
    block("Market carved sandstone facade pilaster",x,-4.96,2.05,.12,.23,3.55,stone,.025)
for x in (-4.25,-2.9,2.9,4.25):
    block("Night market window recessed frame",x,-5.17,1.60,.98,.075,1.64,copper,.02)
for x in (-3.5,3.5):
    planter(x,-6.20,0,.7)
for x in (-2.5,2.5):
    block("Outdoor café terrazzo tabletop",x,-7.05,.77,1.16,.86,.11,stone,.035)
    block("Café table leg",x,-7.05,.38,.1,.10,.72,dark)
    for dx in (-.87,.87):
        block("Café chair padded seat",x+dx,-7.05,.49,.48,.52,.09,wood,.06)
        block("Café wrought chair back",x+dx,-6.80,.88,.48,.08,.79,black,.04)
for x in [-4.35,-3.3,-2.25,-1.2,1.2,2.25,3.3,4.35]:
    block("Warm shop marquee bulbs",x,-5.74,3.34,.105,.10,.12,amber,.025)
finish("moon_market",first)
# FOREVER HOME: furnishing, balconies, terraces, vertical planting.
first=start("forever_home",2)
for floor in (3.25,6.45):
    block("Architectural balcony slab",0,-5.35,floor,8.85,1.4,.22,stone,.055)
    for x in [-4.2,-2.8,-1.4,0,1.4,2.8,4.2]:
        block("Balcony black wrought baluster",x,-5.96,floor+.68,.045,.05,1.20,black)
    block("Continuous brass guardrail",0,-5.95,floor+1.2,8.7,.08,.08,copper,.015)
for floor in (3.25,6.45):
    planter(-4.2,-5.6,floor+.1,.6)
    planter(4.2,-5.6,floor+.1,.6)
for x in [-4.8,-3.35,-1.9,1.9,3.35,4.8]:
    block("Vertical slatted cedar rainscreen",x,-5.10,7.65,.14,.16,1.95,wood,.02)
for i in range(24):
    x=-4.1+i*.35
    z=8.95+.18*math.cos(i*.58)
    tube("Garden rooftop ivy tendril",[(x,-4.78,8.82),(x+.12,-4.85,z+.28)],.026,green)
    sphere("Garden leaf",x+.12,-4.85,z+.28,.13,leaf if i%2 else leaf2)
finish("forever_home",first)
# NOVA STAGE: actual truss, overhead fixtures, side wings and DJ station.
first=start("nova_stage",4)
for x in (-6.3,6.3):
    for z in (2.8,4.1,5.4):
        tube("Stage side triangular truss",[(x,-3.7,z),(x,-2.9,z+.7),(x,-3.7,z+1.4)],.055,stone)
for x in [-5,-3,-1,1,3,5]:
    block("Focused stage par-64 lamp body",x,-3.55,6.12,.30,.38,.28,black,.05)
    sphere("Par lamp tungsten lens",x,-3.8,6.05,.16,pink if x%2 else cyan)
for y in (-2.8,2.9):
    for x in (-5.6,5.6):
        block("Stage suspension line",x,y,6.3,.06,.06,3.5,black)
block("Stage analog console desk",0,-.6,1.12,2.8,1.0,.44,black,.09)
for x in [-.83,-.28,.28,.83]:
    block("DJ channel fader",x,-1.12,1.36,.08,.05,.18,cyan)
for x in (-4.2,4.2):
    block("Floor stage monitor wedge",x,-3.35,.60,1.65,1.0,.76,black,.05)
finish("nova_stage",first)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
report=R/'assets'/'premium_detail_metrics.json'
report.write_text(json.dumps(counts,indent=2),encoding='utf-8')
for k,v in counts.items():
    assert v>18,(k,v)
print("PREMIUM BLENDER ART PASS GREEN",counts,flush=True)
