"""Forever Frequency / LA CALDERA RECORDS: original Blender 3D architecture.

All geometry generated in Blender from editable meshes/curves/text.  CC0-style
originals, no scraped game files. Run blender -b -t 2 --python tools/build_assets_blender.py
Export individual .glb for Godot and editable source .blend.
"""
from __future__ import annotations
import bpy, math, random
from mathutils import Vector
from pathlib import Path

random.seed(37)
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'; OUT.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
M={}
def material(name,rgb,metal=0,rough=.65,emission=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*rgb,1); m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*rgb,1)
    bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
    bs.inputs['Emission Color'].default_value=(*rgb,1)
    bs.inputs['Emission Strength'].default_value=emission
    M[name]=m;return m
stone=material('Limestone warm pearl',(.72,.68,.61),.02,.88)
concrete=material('Poured concrete',(.33,.36,.39),.03,.85)
brick=material('Terracotta red brick',(.40,.20,.21),.03,.85)
dark=material('Anodized midnight facade',(.066,.082,.115),.42,.43)
ink=material('Deep asphalt charcoal',(.025,.032,.050),.1,.8)
roof=material('Roof slate',(.16,.20,.24),.08,.78)
walnut=material('Dark walnut grain',(.31,.17,.11),.05,.68)
wood=material('Honey oak',(.66,.40,.23),.04,.64)
copper=material('Copper trim',(.64,.33,.18),.72,.36)
steel=material('Steel warm brushed',(.46,.50,.55),.66,.31)
black_metal=material('Metal black',(.075,.083,.09),.62,.36)
glass=material('Blue-grey glass',(.12,.22,.26),.42,.25)
glass_warm=material('Window amber',(.46,.30,.19),.28,.24,.14)
cream=material('Milk plaster',(.83,.78,.68),.01,.84)
rose=material('Dusty rose plaster',(.61,.36,.43),.02,.8)
navy=material('Deep indigo sign',(.17,.15,.32),.24,.55)
teal=material('Dark teal paint',(.14,.37,.37),.1,.6)
green=material('Leaf deep',(.095,.28,.15),.01,.89)
leaf=material('Leaf lively',(.17,.43,.27),.01,.87)
leaf2=material('Leaf light',(.25,.50,.28),.01,.9)
soil=material('Mulch',(.26,.18,.12),0,.98)
flower=material('Blossom pink',(.82,.38,.54),0,.8)
pink=material('Caldera hot coral neon',(.98,.20,.35),.12,.27,2.2)
cyan=material('Audio turquoise neon',(.10,.75,.79),.10,.28,2.0)
amber=material('Tungsten warm light',(.99,.68,.33),0,.44,1.45)
white=material('Warm offwhite lettering',(.92,.85,.71),0,.6,.15)
plum=material('Lavender accent',(.37,.27,.55),.12,.5)
cloth=material('Canvas clothing',(.18,.24,.34),0,.94)
skin=material('Warm skin',(.69,.43,.31),0,.88)
hair=material('Very dark hair',(.065,.053,.061),0,.96)
sneaker=material('Sneaker',(.83,.78,.67),0,.76)

def cube(name, loc, scale, mat, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    ob=bpy.context.object;ob.name=name;ob.dimensions=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    ob.data.materials.append(mat)
    if bevel>0:
        m=ob.modifiers.new('Soft manufactured edges','BEVEL');m.width=bevel;m.segments=2
        ob.modifiers.new('Normal smoothing','WEIGHTED_NORMAL')
    return ob

def cyl(name, loc, radius, depth, mat, verts=12, rotation=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=radius,depth=depth,location=loc,rotation=rotation)
    ob=bpy.context.object;ob.name=name;ob.data.materials.append(mat)
    for p in ob.data.polygons: p.use_smooth=True
    return ob

def sphere(name,loc,scale,mat,segments=16,rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=loc)
    ob=bpy.context.object;ob.name=name;ob.scale=scale;ob.data.materials.append(mat)
    for p in ob.data.polygons:p.use_smooth=True
    return ob

def label(name,phrase,loc,size,mat,rotation=(math.pi/2,0,0)):
    bpy.ops.object.text_add(location=loc,rotation=rotation)
    ob=bpy.context.object; ob.name=name;ob.data.body=phrase
    ob.data.align_x='CENTER';ob.data.align_y='CENTER'
    ob.data.size=size;ob.data.extrude=.012;ob.data.bevel_depth=.003
    ob.data.materials.append(mat)
    bpy.ops.object.convert(target='MESH')
    return bpy.context.object

def rod(name, a, b, radius, mat, seg=10):
    a,b=Vector(a),Vector(b); d=b-a
    ob=cyl(name,(a+b)/2,radius,d.length,mat,verts=seg)
    ob.rotation_euler=d.to_track_quat('Z','Y').to_euler()
    return ob

def ring(name,loc,major,minor,mat,rotation=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_segments=36,minor_segments=6,
        location=loc,major_radius=major,minor_radius=minor,rotation=rotation)
    ob=bpy.context.object;ob.name=name;ob.data.materials.append(mat)
    return ob

def foliage(x,y,z,k=1):
    cube('Concrete flower planter',(x,y,z+.18*k),(.82*k,.75*k,.36*k),concrete,.05*k)
    cube('Mulch bed',(x,y,z+.38*k),(.71*k,.63*k,.065*k),soil)
    for n in range(5):
        a=n*2.4; r=.14*k
        sphere('Leaf volume',(x+math.cos(a)*r,y+math.sin(a)*r,z+(.60+random.random()*.16)*k),(.16*k,.16*k,.22*k),[green,leaf,leaf2][n%3])

def shop_window(x,z,y=-5.09,w=1.32,h=1.5,frame=dark):
    cube('Warm recessed interior',(x,y+.17,z),(w+.07,.06,h+.1),glass_warm,.01)
    cube('Window tinted glass',(x,y-.017,z),(w,.055,h),glass,.01)
    for sx in (-1,1):cube('Steel jamb',(x+sx*w*.52,y-.08,z),(.10,.18,h+.10),frame,.02)
    for sz in (-1,1):cube('Steel lintel',(x,y-.08,z+sz*h*.53),(w+.17,.18,.10),frame,.02)
    cube('Sash mullion',(x,y-.13,z),(.045,.16,h),steel)
    cube('Window inner sill',(x,y-.27,z-h*.56),(w+.27,.24,.09),stone,.025)

def hanging_lamps(y,span_x,z):
    for x in span_x:
        rod('Suspended shop lamp',(x,y,z+.36),(x,y,z+1.0),.035,black_metal)
        sphere('Soft lamp globe',(x,y,z+.25),(.19,.19,.19),amber)

def build_caldera():
    # Stylish recording-company headquarters; positive Blender Z=Godot Y.
    cube('La Caldera red-brown brick headquarters',(0,0,5.0),(12,10,10),brick,.11)
    cube('Deep roof parapet',(0,0,10.1),(12.4,10.4,.55),dark,.07)
    cube('Cornice copper edge',(0,-.04,9.86),(12.6,10.6,.18),copper,.045)
    cube('Recessed dark storefront',(0,-5.095,2.1),(11.7,.20,4.25),dark,.045)
    cube('Foundation plinth',(0,-.20,.25),(12.2,10.4,.50),concrete,.07)
    # Storefront architectural glazing, kept away from center door.
    for x in (-4.15,-2.70,2.70,4.15):shop_window(x,1.9,-5.22,1.22,2.70)
    for x in (-4.45,-2.65,-.85,.95,2.75,4.55):
        shop_window(x,6.78,-5.07,1.35,2.05)
    cube('First floor separation',(0,-5.17,4.05),(12.15,.30,.31),copper,.035)
    cube('Studio facade upper band',(0,-5.14,8.38),(12.25,.21,.45),dark,.07)
    # Architectural real door in middle, with landing and bevel.
    cube('Sound-lock entry black frame',(0,-5.27,1.68),(2.7,.28,3.17),black_metal,.05)
    cube('Left glass entrance door',(-.60,-5.438,1.65),(1.13,.06,2.79),glass,.01)
    cube('Right glass entrance door',(.60,-5.438,1.65),(1.13,.06,2.79),glass,.01)
    cube('Door center brass line',(0,-5.50,1.65),(.06,.10,2.7),copper)
    for x in (-.60,.60):cube('Brass handles',(x,-5.52,1.65),(.055,.14,.52),copper,.015)
    cube('Entrance three-level stone steps',(0,-5.7,.17),(4.5,1.15,.30),stone,.035)
    cube('Floating canopy',(0,-5.75,3.65),(8.5,1.65,.23),black_metal,.06)
    cube('Canopy underglow',(0,-5.78,3.51),(7.9,1.38,.045),amber,.01)
    for x in (-3.95,3.95):rod('Canopy suspension',(x,-5.85,3.75),(x,-5.15,4.7),.045,steel)
    # Audio disc is a sculptural logomark rather than giant flashing text.
    ring('La Caldera record-vinyl-sign',(0,-5.33,8.92),.70,.095,cyan,rotation=(math.pi/2,0,0))
    ring('Record-label center',(0,-5.39,8.92),.25,.07,pink,rotation=(math.pi/2,0,0))
    sphere('Record-spindle',(0,-5.45,8.92),(.07,.035,.07),white)
    cube('Lettering backboard',(0,-5.22,5.25),(11.3,.30,1.18),ink,.05)
    label('Actual brand LA CALDERA','LA CALDERA',(0,-5.48,5.43),.91,white)
    label('Actual brand RECORDS','R E C O R D S',(0,-5.49,4.81),.25,amber)
    # Audio energy bars on both sides of the main logo.
    for n,hh in enumerate((.27,.51,.78,.42,.57)):
        for side in (-1,1):
            x=side*(4.20+n*.22)
            cube('Equalizer sculptural led',(x,-5.51,5.28),(0.09,.075,hh),cyan,.018)
    # Brick shadow lines and projecting vertical piers.
    for xx in (-5.88,-4.98,4.98,5.88):
        cube('Masonry structural pier',(xx,-5.18,6.45),(.16,.30,4.2),stone,.03)
    for z in (4.55,8.0):
        cube('Brick course belt',(0,-5.13,z),(11.85,.16,.10),copper,.017)
    # Rooftop music garden and believable HVAC/recording engineering.
    cube('Rooftop studio terrace',(0,-.6,10.36),(11.0,8.65,.17),walnut,.04)
    for xx in (-5.25,5.25):
        cube('Roof handrail',(xx,-4.3,11.20),(.07,.07,1.5),steel)
        cube('Roof handrail',(xx,3.25,11.20),(.07,.07,1.5),steel)
        rod('Roof length railing',(xx,-4.3,11.9),(xx,3.25,11.9),.04,steel)
    cube('Air handling unit',(3.6,2.3,11.08),(2.1,2.35,1.15),steel,.15)
    for x in (2.85,3.6,4.35):cube('HVAC air ventilation',(x,-.06,11.10),(.40,.055,.51),black_metal)
    cube('Sound-damped booth rooftop',(-2.4,1.35,11.55),(4.1,3.2,2.35),glass,.13)
    for x in (-3.6,-1.2):cube('Roof booth vertical structural',(x,-.26,11.55),(.1,.14,2.15),dark,.02)
    foliage(-4.72,-3.32,10.35,.82);foliage(4.68,-3.32,10.35,.82)
    # Brick sidewall grooves / balconies
    for side in (-1,1):
        for f in (5.85,8.0):
            cube('Side loft glazing',(side*6.02,-1.1,f),(.07,3.65,1.4),glass,.02)
        for z in (3.1,6.1,8.35):
            cube('Stone balcony shelf',(side*6.0,-1.1,z),(.55,4.2,.18),stone,.04)
    for z in (5.45,7.2):
        for x in (-4.3,4.3):cube('Lit studio vertical moulding',(x,-5.31,z),(.09,.08,1.22),copper,.012)

def build_market():
    cube('Market warm masonry building',(0,0,3.15),(11,10,6.3),cream,.1)
    cube('Storefront ceramic accent',(0,-5.13,2.3),(11.1,.20,4.65),brick,.05)
    cube('Flat terracotta roof',(0,0,6.42),(11.5,10.4,.4),roof,.08)
    cube('Shop front wooden inlay',(0,-5.24,2.33),(10.5,.14,3.45),walnut,.04)
    for x in (-4.05,-2.68,2.68,4.05): shop_window(x,2.5,-5.3,1.2,2.4,frame=copper)
    cube('Double market door',(0,-5.38,1.65),(2.2,.18,2.8),glass,.04)
    cube('Market canopy main',(0,-6.06,3.81),(11.8,2.1,.25),pink,.07)
    for n in range(13):
        x=-5.5+n*.92
        cube('Market scalloped striped valance',(x,-7.02,3.56),(.48,.09,.59),rose if n%2 else cream,.02)
    cube('Sign inset backing',(0,-5.24,5.32),(8.7,.16,1.04),teal,.03)
    label('Moon Market sign','MOON MARKET',(0,-5.42,5.37),.73,white)
    label('Market subtitle','CAFE  -  GOODS  -  MUSIC',(0,-5.42,4.89),.20,amber)
    for x in (-5.2,5.2):foliage(x,-6.2,0,.85)
    for x in (-3.5,3.5):
        cube('Cafe table',(x,-8.1,1.12),(1.0,1.0,.085),walnut,.06)
        rod('Table base',(x,-8.1,.08),(x,-8.1,1.10),.07,steel)
    for x in (-3.9,-2.0,1.9,3.8):
        cube('Rooftop solar wood garden',(x,2.9,6.8),(1.2,1.2,.35),walnut,.05)
        sphere('Rooftop planted rose',(x,2.9,7.15),(.52,.52,.44),[leaf,green,flower][int(abs(x))%3])

def build_home():
    cube('Warm family villa',(0,0,4.25),(11,11,8.5),stone,.14)
    cube('Painted vertical accent',(3.9,-5.54,4.2),(2.7,.26,8.0),rose,.06)
    cube('Villa cantilever roof',(0,0,8.73),(11.9,11.9,.30),dark,.09)
    for x in (-4.3,-2.5,.3,2.1):
        shop_window(x,2.4,-5.55,1.6,2.9,frame=wood)
        shop_window(x,6.6,-5.54,1.6,2.5,frame=wood)
    cube('Family front door',(3.95,-5.65,1.48),(1.35,.13,2.75),walnut,.06)
    cube('Family entrance window stripe',(3.9,-5.77,1.60),(.16,.05,2.3),amber,.01)
    cube('Home outdoor terrace',(0,-6.25,.20),(11,1.70,.32),wood,.03)
    cube('Entrance porch',(2.8,-6.04,3.34),(4.1,2.2,.16),wood,.045)
    label('Home facade name','FOREVER HOME',(-2.45,-5.70,7.94),.38,dark)
    cube('Home terrace railing',(0,-5.60,8.95),(10.2,.08,.38),glass,.025)
    for x in (-4.7,0,4.7):foliage(x,-4.5,8.8,.82)
    for x in (-4.8,4.8):foliage(x,-6.40,0,.9)

def build_garden():
    cube('Masonry garden plot',(0,0,.21),(11,.42,11),stone,.06)
    for x in (-3.5,0,3.5):
        for y in (-3,1.5):
            cube('Raised reclaimed wood vegetable bed',(x,y,.6),(2.8,3.2,.65),wood,.035)
            cube('Real cultivated soil',(x,y,.95),(2.53,2.93,.12),soil,.016)
            for n in range(4):
                sphere('Leaf crop',(x+(.38 if n%2 else -.38),y-1.0+(n//2)*1.6,1.28),(.32,.3,.29),[leaf,leaf2,green][n%3])
    # Conservatory/greenhouse on back half (frame-only for transparency).
    for x in (-4.85,4.85):
        for y in (-4.8,-.2):
            rod('Glasshouse corner post',(x,y,.6),(x,y,4.0),.07,steel)
    for yy in (-4.8,-.2):
        rod('Glasshouse pitched roof L',(-4.85,yy,4.0),(0,yy,5.9),.07,steel)
        rod('Glasshouse pitched roof R', (4.85,yy,4.0),(0,yy,5.9),.07,steel)
    for xx in (-4.85,0,4.85):rod('Glasshouse roof ridge',(xx,-4.8,5.9 if xx==0 else 4.0),(xx,-.2,5.9 if xx==0 else 4.0),.07,steel)
    label('Garden entrance sign','PIXEL GARDEN',(0,-5.35,2.45),.55,green)

def build_stage():
    cube('Nova Stage raised charcoal deck',(0,0,.52),(13,8,1.05),dark,.12)
    cube('Stage plank top',(0,0,1.1),(12.5,7.5,.12),walnut,.03)
    cube('Back concert mural',(0,3.78,4.15),(12.9,.18,5.7),navy,.04)
    for xx in (-6.1,6.1):
        for yy in (-3.7,3.7):rod('Main truss support',(xx,yy,1.12),(xx,yy,7.65),.09,steel)
    for x in (-6.1,6.1):rod('Stage roof edge depth',(x,-3.7,7.65),(x,3.7,7.65),.11,steel)
    for y in (-3.7,3.7):rod('Stage overhead light truss',(-6.2,y,7.65),(6.2,y,7.65),.11,steel)
    for xx in (-5,-3,-1,1,3,5):
        sphere('Concert PAR lamp',(xx,-3.58,7.15),(.23,.26,.28),cyan if xx%2==0 else pink)
    cube('Stage performance panel',(0,3.60,4.2),(9.8,.20,3.8),ink,.03)
    label('Festival sign','NOVA STAGE',(0,3.37,5.75),1.02,white,rotation=(math.pi/2,0,0))
    for xx in (-5.65,5.65):
        cube('Line array speaker stack',(xx,3.2,4.2),(1.07,.92,3.25),black_metal,.055)
        for zz in (3.3,4.2,5.1):cube('Speaker grille',(xx,2.70,zz),(.78,.05,.42),ink,.015)
    # DJ setup center front: screen and mixer, two vinyl turntables
    cube('DJ console',(0,.20,2.0),(3.5,1.2,1.3),black_metal,.11)
    for xx in (-.92,.92):
        ring('DJ turntable platter',(xx,-.57,2.72),.42,.065,steel)
        sphere('DJ label',(xx,-.57,2.72),(.15,.15,.05),pink)

def build_radio():
    cube('Radio booth',(0,0,2.6),(5.8,5.8,5.2),dark,.12)
    cube('Radio tinted broadcast glazing',(0,-2.99,2.98),(5.2,.06,3.55),glass,.04)
    for x in (-1.6,0,1.6):cube('Radio studio mullion',(x,-3.1,3.0),(.10,.20,3.45),copper,.02)
    cube('Radio roof',(0,0,5.3),(6.15,6.2,.35),roof,.05)
    for h in range(4):
        z=6.0+h*1.55
        rod('Radio mast',(0,0,z),(0,0,z+1.55),.13,steel)
        rod('Radio tower crossbar',(-1.1+h*.2,0,z+.65),(1.1-h*.2,0,z+.65),.055,copper)
    sphere('Radio transmitting light',(0,0,12.5),(.25,.25,.25),pink)
    label('Radio station lettering','RADIO ONE',(0,-3.18,4.5),.62,white)

def build_tree():
    cyl('Natural trunk',(0,0,1.70),.26,3.4,walnut,9)
    for n in range(10):
        a=n*2.4;rr=.78+(n%3)*.17
        sphere('Hand-made lobed leafy crown',(math.cos(a)*rr,math.sin(a)*rr,3.4+(n%4)*.3),(.72,.74,.69),[green,leaf,leaf2][n%3])
    sphere('Crown main',(0,0,4.35),(1.17,1.08,.96),leaf)

def build_lamp():
    cyl('Street cast-metal column',(0,0,1.6),.095,3.2,black_metal,12)
    cyl('Lamp stepped foot',(0,0,.2),.25,.40,black_metal)
    rod('Street overhang',(0,0,3.19),(.70,0,3.19),.07,black_metal)
    sphere('Warm lamp lantern globe',(.72,0,3.0),(.21,.21,.24),amber)
    cube('Lamp hood',(.72,0,3.22),(.5,.50,.12),black_metal,.035)
    for n in range(3):rod('Street light ornament',(0,0,3.0),(math.cos(n*2.1)*.18,math.sin(n*2.1)*.18,3.33),.03,copper)

def build_bench():
    for z in (.45,.9):
        for xx in (-.82,.82):cyl('Bench forged leg',(xx,0,z*.60),.06,z*1.1,black_metal)
    for yy in (-.30,0,.3):cube('Bench wood slat',(0,yy,.86),(1.95,.24,.11),wood,.035)
    for zz in (1.05,1.31):cube('Bench back slat',(0,.44,zz),(1.95,.12,.19),wood,.03)
    for xx in (-.82,.82):cube('Bench arm rest',(xx,.13,1.15),(.12,.78,.09),black_metal,.03)

def build_car():
    # Stylized compact European hatchback with glass, frames, headlamps, wheels.
    cube('Realistic compact car chassis',(0,0,.75),(2.05,4.00,.80),teal,.19)
    cube('Streamlined cabin',(0,.16,1.37),(1.83,2.3,.65),glass,.21)
    cube('Cabin painted roof',(0,.15,1.76),(1.58,1.9,.16),teal,.11)
    for x in (-1.0,1.0):
        for y in (-1.29,1.29):
            ob=cyl('Rubber tire',(x,y,.46),.43,.23,ink,14,rotation=(0,math.pi/2,0))
            cyl('Wheel alloy rim',(x+(0.13 if x>0 else -.13),y,.46),.24,.05,steel,12,rotation=(0,math.pi/2,0))
    for x in (-.68,.68):
        cube('Front LED headlight',(x,-2.03,.77),(.38,.10,.15),amber,.03)
        cube('Rear brake light',(x,2.02,.87),(.36,.08,.19),pink,.03)
    cube('Front car number plate',(0,-2.08,.45),(.85,.07,.21),cream,.01)

def build_artist():
    # Game-sized character 2.35m tall, higher quality than box/capsule primitives.
    sphere('Stylized artist rounded head',(0,0,1.78),(.34,.29,.40),skin,20,12)
    sphere('Black sweeping hair',(0,.085,2.04),(.355,.30,.20),hair)
    for xx in (-.21,.21):
        sphere('Sideburns',(xx,-.04,1.9),(.14,.22,.24),hair)
        sphere('Eyes',(xx*.68,-.271,1.84),(.033,.024,.035),ink,12,8)
    sphere('Nose',(0,-.297,1.72),(.045,.045,.06),skin)
    sphere('Hoodie oversized torso',(0,.04,1.19),(.52,.31,.64),cloth,20,12)
    cube('Hoodie zip accent',(0,-.29,1.20),(.055,.034,.66),copper,.012)
    sphere('Jacket hood',(0,.24,1.58),(.40,.28,.26),navy)
    for xx in (-.55,.55):
        rod('Jacket sleeves',(xx*.72,0,1.53),(xx,0,1.03),.18,cloth)
        sphere('Hands',(xx,0,1.0),(.135,.125,.15),skin)
        rod('Jogger trouser leg',(xx*.40,0,.75),(xx*.41,0,.23),.19,navy)
        sphere('Training sneakers',(xx*.43,-.12,.16),(.25,.40,.13),sneaker)
    # Headphones, bag and backpack straps; hints at music-producer protagonist.
    ring('Headphone halo',(0,0,2.01),.40,.055,black_metal,rotation=(math.pi/2,0,0))
    for xx in (-.35,.35):
        cube('Over-ear neon headphone cup',(xx,0,1.87),(.15,.20,.31),cyan,.045)
    cube('Producer messenger bag',(.50,.27,1.0),(.50,.19,.56),walnut,.09)
    rod('Cross-body bag strap',(-.34,-.31,1.49),(.52,-.25,1.0),.035,copper)

def build_pet():
    sphere('Nova fuzzy round body',(0,0,.50),(.49,.46,.46),cream,20,12)
    sphere('Little pet head',(0,-.24,.77),(.42,.36,.38),cream,20,12)
    for xx in (-.29,.29):
        sphere('Cat-shaped ear',(xx,-.17,1.06),(.17,.16,.32),cream)
        sphere('Deep vivid eyes',(xx*.65,-.54,.83),(.07,.05,.092),navy)
        sphere('Paws',(xx,-.27,.19),(.14,.21,.13),cream)
        sphere('Rear paws',(xx,.31,.18),(.14,.18,.11),cream)
    sphere('Pink nose',(0,-.59,.71),(.08,.06,.055),pink)
    for n in range(5):
        a=n*math.pi/6
        sphere('Curled magical tail',(.40+n*.11,.23+n*.06,.40+n*.11),(.17,.17,.17),cream)
    ring('Audio-powered halo',(0,0,1.30),.42,.035,cyan)

ASSETS=[
    ('la_caldera_records.glb',build_caldera),
    ('moon_market.glb',build_market),
    ('forever_home.glb',build_home),
    ('pixel_garden.glb',build_garden),
    ('nova_stage.glb',build_stage),
    ('radio_one.glb',build_radio),
    ('street_tree.glb',build_tree),
    ('street_lamp.glb',build_lamp),
    ('city_bench.glb',build_bench),
    ('city_car.glb',build_car),
    ('artist_avatar.glb',build_artist),
    ('companion_nova.glb',build_pet),
]
asset_objects=[]
for i,(name,fn) in enumerate(ASSETS):
    before=set(bpy.data.objects)
    fn()
    parts=list(set(bpy.data.objects)-before)
    if not parts: raise ValueError('No geometry made for '+name)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in parts:ob.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.export_scene.gltf(filepath=str(OUT/name),export_format='GLB',use_selection=True,
                              export_apply=True,export_materials='EXPORT')
    assert (OUT/name).stat().st_size>1000,name
    # Store each original object separated into easy-to-inspect collections in .blend.
    col=bpy.data.collections.new(name.replace('.glb',''))
    bpy.context.scene.collection.children.link(col)
    for ob in parts:
        for c in list(ob.users_collection):c.objects.unlink(ob)
        col.objects.link(ob)
        ob.location.x += i*24.0
    asset_objects.extend(parts)
    print('FOREVER ASSET:',name,'meshes:',len(parts),'bytes:',(OUT/name).stat().st_size,flush=True)
# Previous workflow expects these two names. Export genuine custom pieces, no fake placeholders.
for legacy, modern in [('studio_entrance.glb','la_caldera_records.glb'),('street_kiosk.glb','moon_market.glb')]:
    (OUT/legacy).write_bytes((OUT/modern).read_bytes())
bpy.ops.object.select_all(action='DESELECT')
for ob in asset_objects:ob.select_set(True)
bpy.context.view_layer.objects.active=asset_objects[0]
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'city_zero_modular.blend'))
print('LA CALDERA ASSET KIT GREEN',len(ASSETS),'original editable Blender models')
