"""Blender urban street infrastructure, diverse avatar silhouettes & distant skyline.
Original modular assets, editable in Blender, physically scaled for Godot.
Every nationality can share any appearance; these are visual character options, not labels.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[1]; O=R/'assets';O.mkdir(exist_ok=True)
random.seed(8675309)
def mat(name,c,metal=0.0,rough=.65,glow=0):
    m=bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.diffuse_color=(*c,1);m.use_nodes=True
    bs=m.node_tree.nodes['Principled BSDF']
    bs.inputs['Base Color'].default_value=(*c,1);bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
    if glow:
        bs.inputs['Emission Color'].default_value=(*c,1);bs.inputs['Emission Strength'].default_value=glow
    return m
metal=mat("Traffic powder-coated steel",(.075,.10,.13),.65,.43)
chrome=mat("Brushed traffic chrome",(.43,.48,.54),.7,.35)
black=mat("Black polymer",(.038,.047,.06),.0,.74)
concrete=mat("Poured civic concrete",(.43,.44,.43),0,.93)
stone=mat("Light granite",(.65,.61,.54),0,.84)
red=mat("Stop reflective red",(.68,.035,.042),0,.38)
white=mat("High retroreflective white",(.94,.93,.84),0,.39)
amber=mat("Amber traffic lamp",(.93,.53,.048),0,.22,1.1)
green=mat("Green traffic lamp",(.06,.72,.26),0,.22,1.1)
night=mat("Urban midnight blue",(.084,.13,.21),.1,.64)
glass=mat("Reflective skyline glass",(.12,.21,.29),.28,.25)
windows=mat("Window warm amber",(.80,.53,.26),0,.36,.9)
def clear():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def b(n,loc,dim,m,bevel=.04):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);ob=bpy.context.object
    ob.name=n;ob.dimensions=dim;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    ob.data.materials.append(m)
    if bevel:
        mod=ob.modifiers.new('Smooth edge detail','BEVEL');mod.width=bevel;mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return ob
def cy(n,loc,r,dep,m,vertices=24,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=dep,location=loc,rotation=rot)
    ob=bpy.context.object;ob.name=n;ob.data.materials.append(m)
    for p in ob.data.polygons:p.use_smooth=True
    return ob
def orb(n,loc,size,m,seg=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=10,location=loc)
    ob=bpy.context.object;ob.name=n;ob.scale=size;ob.data.materials.append(m)
    for p in ob.data.polygons:p.use_smooth=True
    return ob
def text(label,n,loc,size,m):
    bpy.ops.object.text_add(location=loc,rotation=(math.pi/2,0,0))
    ob=bpy.context.object;ob.name=n;ob.data.body=label;ob.data.align_x='CENTER'
    ob.data.align_y='CENTER';ob.data.size=size;ob.data.extrude=.007;ob.data.materials.append(m)
    bpy.ops.object.convert(target='MESH')
    return bpy.context.object
def export(n):
    bpy.ops.object.select_all(action='SELECT')
    path=O/(n+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_apply=True)
    count=len([o for o in bpy.data.objects if o.type=='MESH'])
    assert path.stat().st_size>1800,(n,path)
    return {'mesh_count':count,'bytes':path.stat().st_size}
report={}
# Three-lamp signal with pedestrian button and realistic signal visors.
clear()
cy('Traffic galvanized tubular mast',(0,0,2.65),.09,5.3,metal)
cy('Mast base reinforcement',(0,0,.17),.18,.34,chrome)
b('Cross-street cantilever',(0,-.42,4.90),(.12,1.10,.12),metal)
b('Three signal head rounded',(0,-1.07,4.38),(.57,.38,1.68),black,.11)
for j,color in enumerate([red,amber,green]):
    zz=4.92-j*.53
    cy('Inset colored signal lens',(0,-1.286,zz),.188,.055,color,32,(math.pi/2,0,0))
    cy('Lens weather hood',(0,-1.23,zz+.11),.23,.07,metal,32,(math.pi/2,0,0))
b('Accessible pedestrian button',(.14,-.10,1.21),(.18,.18,.30),chrome)
b('Pedestrian signal square',(.0,-.13,3.12),(.60,.22,.64),black,.05)
text('WALK','Signal pedestrian lettering',(0,-.30,3.05),.16,white)
report['traffic_signal']=export('traffic_signal')
# Stop sign. Octagonal mesh not rectangle.
clear()
cy('Stop post',(0,0,1.12),.065,2.24,chrome)
verts=[]
for offset in [0,.043]:
    for i in range(8):
        angle=math.tau*(i+.5)/8
        verts.append((1.0*math.sin(angle),-offset,2.23+1.0*math.cos(angle)))
faces=[tuple(range(8)),tuple(range(8,16))]
data=bpy.data.meshes.new('octagonal stop geometry');data.from_pydata(verts,[],faces);data.materials.append(red)
ob=bpy.data.objects.new('Octagonal authentic STOP face',data);bpy.context.collection.objects.link(ob)
text('STOP','Stop octagonal type',(0,-.12,2.14),.42,white)
report['stop_sign']=export('stop_sign')
# Comfortable glass bus stop shelter with roof, seats, timetable.
clear()
b('Bus platform kerb',(0,0,.09),(4.0,2.1,.18),concrete,.07)
for x in (-1.75,1.75):
    for y in (-.75,.75):
        cy('Bus shelter aluminum post',(x,y,1.50),.055,3.0,metal)
b('Elegant sloped steel shelter canopy',(0,0,3.02),(4.2,2.4,.13),metal,.07)
b('Rear protective glass wall',(0,.80,1.70),(3.5,.07,2.30),mat('Tempered glass',(.22,.38,.41),.16,.24),.012)
for x in (-1.05,1.05):b('Bus bench oak seat',(x,.20,.55),(1.65,.58,.12),stone)
b('Bus route display',(-1.53,-.70,2.32),(.6,.18,.7),black)
text('C 2','Bus route text',(-1.53,-.83,2.21),.25,green)
report['bus_shelter']=export('bus_shelter')
# Fire hydrant and waste receptacle.
clear()
cy('Hydrant cast body',(0,0,.49),.21,.76,red,20)
cy('Hydrant domed top',(0,0,.89),.27,.16,red,20)
cy('Hydrant nozzle L',(-.25,0,.61),.14,.26,chrome,20,(0,math.pi/2,0))
cy('Hydrant nozzle R',(.25,0,.61),.14,.26,chrome,20,(0,math.pi/2,0))
report['fire_hydrant']=export('fire_hydrant')
clear()
b('Smart street recycling bin',(0,0,.68),(.7,.61,1.30),metal,.08)
b('Trash lid',(0,0,1.37),(.76,.66,.12),black,.055)
b('Recycling panel',(0,-.315,.76),(.42,.016,.36),green,.013)
text('RECYCLE','Recycling symbol label',(0,-.333,.71),.11,white)
report['street_bin']=export('street_bin')
# Distinct 3D character lineup, not one clone texture-swapped.
skintones=[(.25,.145,.095),(.66,.40,.25),(.84,.62,.47),(.48,.30,.21),(.93,.72,.56),
           (.38,.22,.145),(.74,.50,.37),(.56,.39,.30)]
hair_colors=[(.045,.038,.040),(.16,.095,.055),(.073,.068,.070),(.21,.14,.095),(.08,.053,.035),
             (.27,.18,.09),(.11,.075,.065),(.16,.085,.035)]
wardrobes=[(.24,.34,.46),(.58,.20,.27),(.35,.44,.25),(.67,.55,.32),(.31,.27,.46),
           (.55,.37,.21),(.18,.50,.51),(.42,.31,.39)]
def avatar(i):
    clear()
    skin=mat('Person %d skin'%i,skintones[i],0,.85)
    hair=mat('Person %d hair'%i,hair_colors[i],0,.92)
    jacket=mat('Person %d jacket'%i,wardrobes[i],0,.86)
    pants=mat('Person %d trousers'%i,(.10+.035*(i%3),.13+.015*(i%4),.18+.017*(i%3)),0,.92)
    shoe=mat('Person %d shoes'%i,(.60,.58,.51) if i%2 else (.10,.11,.14),0,.79)
    body_h=[.93,1.02,1.10,.99,1.07,1.0,.96,1.13][i]
    body_w=[.35,.41,.33,.47,.32,.38,.42,.35][i]
    orb('Character shape head',(0,-.02,1.66*body_h),(.235,.22,.285),skin)
    # Render different hair shapes rather than stereotyping nationality.
    if i%4==0:
        for k in range(14):
            a=math.tau*k/14
            orb('Textured close curls',(.19*math.cos(a),.18*math.sin(a),1.84*body_h+.06*math.sin(k)),(.10,.10,.11),hair)
    elif i%4==1:
        orb('Shoulder length styled hair',(0,.095,1.68*body_h),(.285,.23,.38),hair)
        orb('Side swept fringe',(-.06,-.19,1.86*body_h),(.24,.11,.11),hair)
    elif i%4==2:
        orb('Sculpted cropped hair',(0,.05,1.88*body_h),(.25,.21,.12),hair)
    else:
        orb('High swept bun',(0,.12,2.01*body_h),(.16,.16,.18),hair)
        orb('Side fringe',(.10,-.14,1.86*body_h),(.18,.10,.095),hair)
    for x in [-.095,.095]:
        orb('Open animated expressive eyes',(x,-.232,1.68*body_h),(.023,.014,.027),black,12)
    orb('Character upper garment',(0,.02,1.16*body_h),(body_w,.24,.45),jacket)
    # Variant jacket collar and hems
    b('Layered inner shirt',(0,-.243,1.35*body_h),(.23,.035,.28),white,.013)
    for sign in (-1,1):
        cy('Articulated sleeve',(sign*(body_w+.095),0,1.18*body_h),.115,.57,jacket,16,(0,math.pi/2.7,sign*.27))
        orb('Hand',(sign*(body_w+.22),-.04,.92*body_h),(.09,.09,.12),skin)
        cy('Trouser pant leg',(sign*.17,.025,.47*body_h),.14,.78,pants,16)
        orb('2020s running shoe',(sign*.17,-.13,.13*body_h),(.18,.31,.12),shoe)
    if i%3==0:
        # Modern headphones
        cy('Headphone earcup left',(-.28,-.015,1.69*body_h),.11,.12,black,16,(0,math.pi/2,0))
        cy('Headphone earcup right',(.28,-.015,1.69*body_h),.11,.12,black,16,(0,math.pi/2,0))
    elif i%3==1:
        b('Crossbody bag',(.27,.18,.96*body_h),(.28,.23,.39),shoe)
    else:
        b('Modern sling backpack',(0,.31,1.12*body_h),(.45,.23,.52),pants)
    return export('citizen_%02d'%i)
for i in range(8):report['citizen_%02d'%i]=avatar(i)
# Distant backdrop: irregular skyline with windows; no infinite flat horizon.
clear()
for idx in range(58):
    a=math.tau*idx/58
    radius=72+random.random()*12
    x,z=radius*math.cos(a),radius*math.sin(a)
    h=14+random.random()*19
    w=4.1+random.random()*5.1
    dep=4.2+random.random()*4.1
    base=night if idx%4 else metal
    b('Distinct distant skyline mass', (x,z,h*.5), (w,dep,h),base,.12)
    b('Skyline roof mechanical',(x,z,h+.48),(w*.43,dep*.42,.94),black,.05)
    # sparse windows to limit draw calls later; face toward city for visibility
    sx=-1 if x>0 else 1
    for floor in range(3,int(h//2.6)):
        for col in range(3):
            if (floor+col+idx)%4==0: continue
            xx=x+sx*w*.5
            zz=(floor+.4)*2.6
            yy=z+(col-1)*dep*.26
            b('Warm lit skyline glazing',(xx,yy,zz),(.065,dep*.12,1.05),windows if floor%3 else glass,.01)
# Batch skyline windows by material: no thousands of imported Godot nodes.
# Save the fully separate Blender authoring scene first for future modding.
bpy.ops.wm.save_as_mainfile(filepath=str(O/'skyline_dusk_editable.blend'))
from collections import defaultdict
grouped=defaultdict(list)
for ob in list(bpy.context.scene.objects):
    if ob.type != 'MESH': continue
    # Material identity, with consistent geometry transforms applied.
    grouped[tuple(m.name for m in ob.data.materials if m)].append(ob)
for signature,objects in grouped.items():
    if len(objects)<2: continue
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objects: ob.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
skyline_batches=len([ob for ob in bpy.context.scene.objects if ob.type=='MESH'])
assert skyline_batches<=12,skyline_batches
print('SKYLINE BATCHING GREEN',skyline_batches,flush=True)
report['skyline_dusk']=export('skyline_dusk')
( O/'city_life_asset_metrics.json').write_text(json.dumps(report,indent=2))
print('CITY LIFE BLENDER GAUNTLET GREEN',len(report),'original modular city props/NPCs/skyline',flush=True)
