"""Forever Frequency contemporary vehicle kit (2020s design language).

Original, unbranded Blender geometry. Six materially different silhouettes,
not 1990s cars resized. Front = local -Y, right = +X, up = +Z.
Exports individual GLBs so Godot can stream/recolor instances independently.
"""
import bpy, math, json, random
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'; OUT.mkdir(parents=True,exist_ok=True)
random.seed(20261124)
def material(name,color,metal=0,rough=.45,emit=0):
    m=bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.diffuse_color=(*color,1)
    m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Metallic'].default_value=metal
    bs.inputs['Roughness'].default_value=rough
    if emit:
        bs.inputs['Emission Color'].default_value=(*color,1)
        bs.inputs['Emission Strength'].default_value=emit
    return m
black=material('Ceramic shadow',(.035,.046,.061),.12,.68)
rubber=material('Modern rubber compound',(.045,.048,.052),0,.87)
glass=material('Dark automotive panoramic glass',(.085,.15,.21),.38,.16)
chrome=material('Brushed satin chrome',(.46,.52,.58),.78,.3)
red=material('Continuous rear LED',(.95,.055,.075),.03,.2,1.0)
white=material('High intensity front LED',(.83,.92,1),0,.22,1.3)
indicators=material('Amber indicator LED',(1,.38,.07),0,.22,1.0)
number=material('Neutral license plate',(.77,.81,.84),.1,.68)
paints=[
    ('Pearl White',(.71,.77,.80)),('Graphite Blue',(.13,.19,.28)),
    ('Copper Bronze',(.48,.26,.17)),('Midnight Teal',(.11,.34,.33)),
    ('Slate Silver',(.47,.52,.56)),('Caldera Crimson',(.48,.085,.11))
]
def mesh(name,verts,faces,mats,face_mat=None):
    data=bpy.data.meshes.new(name)
    data.from_pydata(verts,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
    for m in mats:data.materials.append(m)
    for i,p in enumerate(data.polygons):
        p.use_smooth=True
        if face_mat:p.material_index=face_mat[i]
    return obj
def block(n,loc,dim,mat,bevel=.06):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    o=bpy.context.object;o.name=n;o.dimensions=dim
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat)
    if bevel:
        mod=o.modifiers.new('Automotive edge highlights','BEVEL');mod.width=bevel;mod.segments=3
        bpy.context.view_layer.objects.active=o
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return o
def cyl(n,loc,r,depth,mat,verts=24,rotation=(0,math.pi/2,0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts,radius=r,depth=depth,location=loc,rotation=rotation)
    ob=bpy.context.object;ob.name=n;ob.data.materials.append(mat)
    for poly in ob.data.polygons:poly.use_smooth=True
    return ob
def rounded_surface(name, sections, paint, inside):
    # Each section: (Y, half-width at belt, bottom height, belt height).
    v=[];f=[];fm=[]
    for y,w,b,h in sections:
        v.extend([(-w*.83,y,b),(-w,y,b+.34),(-w,y,h-.09),
                  (-w*.90,y,h),(w*.90,y,h),(w,y,h-.09),
                  (w,y,b+.34),(w*.83,y,b)])
    for k in range(len(sections)-1):
        for j in range(8):
            f.append((8*k+j,8*k+(j+1)%8,8*(k+1)+(j+1)%8,8*(k+1)+j))
            fm.append(0)
    f.extend([tuple(reversed(range(8))),tuple(8*(len(sections)-1)+j for j in range(8))])
    fm.extend([1,1])
    return mesh(name,v,f,[paint,inside],fm)
def canopy(name, rings, paint, window):
    # Triangulated continuous modern cabin, proper front/rear windshield rake.
    v=[];f=[];fm=[]
    for y,w,z1,z2 in rings:
        v.extend([(-w,y,z1),(-w*.86,y,z2),(w*.86,y,z2),(w,y,z1)])
    for k in range(len(rings)-1):
        for j in range(3):
            f.append((k*4+j,k*4+j+1,(k+1)*4+j+1,(k+1)*4+j))
            fm.append(1 if j in (0,2) else 0)
    f.extend([(0,1,2,3),tuple(4*(len(rings)-1)+j for j in range(4))])
    fm.extend([1,1])
    return mesh(name,v,f,[paint,window],fm)
def lightbar(n,y,halfwidth,z,m,depth=.075):
    block(n,(0,y,z),(2*halfwidth,depth,.075),m,.034)
def build_one(key,style,paint,width,length,height):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    half=width*.5
    front=-length*.5;rear=length*.5
    wheelbase=length*.57
    # Front is sculpted/recessed. Body tapers at both ends; not cubes.
    sections=[(front,half*.80,.33,height*.73),
              (front+.24,half*.94,.29,height*.91),
              (-length*.19,half,.29,height),
              (length*.18,half,.29,height),
              (rear-.29,half*.96,.30,height*.91),
              (rear,half*.77,.37,height*.74)]
    rounded_surface(key+' sculpted body shell',sections,paint,black)
    for xx in (-half*.98,half*.98):
        for yy in (-wheelbase*.5,wheelbase*.5):
            cyl(key+' high performance tyre',(xx,yy,.44),.43,.24,rubber)
            side_x=xx+(.14 if xx>0 else -.14)
            cyl(key+' aerodynamic alloy rim',(side_x,yy,.44),.255,.047,chrome,24)
            cyl(key+' central wheel hub',(side_x+(.03 if xx>0 else -.03),yy,.44),.075,.07,black,16)
            for a in range(6):
                angle=a*math.tau/6
                # Spokes on visible outside, not full wire wheels.
                block(key+' alloy turbine blade',
                      (side_x+(.035 if xx>0 else -.035),yy+math.cos(angle)*.16,.44+math.sin(angle)*.16),
                      (.024,.065,.055),chrome,.006)
    roof=height+.72 if style not in ('van','suv') else height+1.0
    if style=='sedan':
        rings=[(front+.73,half*.83,height*.93,height+.03),(-.45,half*.79,height*.99,roof),(.80,half*.73,height*.99,roof-.03),(rear-.62,half*.85,height*.94,height+.03)]
    elif style=='sportback':
        rings=[(front+.63,half*.84,height*.95,height+.02),(-.67,half*.79,height*.98,roof),(.49,half*.74,height*.99,roof-.04),(rear-.26,half*.85,height*.93,height+.01)]
    elif style=='hatch':
        rings=[(front+.64,half*.81,height*.92,height+.02),(-.46,half*.8,height*.98,roof),(.72,half*.78,height*.98,roof),(rear-.34,half*.80,height*.94,height+.01)]
    elif style=='suv':
        rings=[(front+.67,half*.82,height*.91,height+.04),(-.37,half*.77,height*.97,roof),(.92,half*.77,height*.97,roof),(rear-.37,half*.82,height*.92,height+.03)]
    elif style=='pickup':
        rings=[(front+.6,half*.82,height*.92,height+.01),(-.7,half*.8,height*.98,roof),(.28,half*.78,height*.98,roof),(.51,half*.83,height*.93,height+.02)]
        # Open, visibly deep pickup bed; not a plain box.
        block('Pickup raised bed side left',(-half*.83,(.65+rear)*.5,height+.14),(.15,rear-.64,.39),paint,.05)
        block('Pickup raised bed side right',(half*.83,(.65+rear)*.5,height+.14),(.15,rear-.64,.39),paint,.05)
        block('Pickup bed textured floor',(0,(.65+rear)*.5,height-.18),(width*.78,rear-.64,.06),black,.02)
    else: # current-generation electric urban van / delivery
        rings=[(front+.34,half*.81,height*.90,height+.03),(-.50,half*.81,height*.98,roof),(.92,half*.81,height*.98,roof),(rear-.23,half*.82,height*.95,roof-.04)]
    canopy(key+' panoramic cabin roof',rings,paint,glass)
    block(key+' roof glass',(0,(rings[1][0]+rings[-2][0])*.5,roof-.02),
          (width*.64,max(.55,rings[-2][0]-rings[1][0]),.035),glass,.025)
    # Sharply modern full-width running lights with corner DRLs and vertical reflector.
    lightbar(key+' full width DRL',front+.006,half*.74,height*.65,white)
    lightbar(key+' continuous rear light',rear-.005,half*.74,height*.69,red)
    for xx in (-half*.69,half*.69):
        block(key+' signature front hook', (xx,front-.012,height*.58),(.06,.04,.17),white,.018)
        block(key+' rear turn signal', (xx,rear+.012,height*.53),(.13,.04,.08),indicators,.016)
        block(key+' aerodynamic door handle', (xx*1.28,0.0,height*.86),(.025,.34,.05),chrome,.012)
        block(key+' foldaway wing mirror',(xx*.98,front+length*.28,height+.14),(.20,.27,.13),paint,.04)
        block(key+' dark mirror inset',(xx*1.02,front+length*.28,height+.145),(.025,.2,.08),glass,.005)
    # Black lower diffuser, closed EV-style front face, dual license panels.
    block(key+' lower front air duct',(0,front-.03,.50),(width*.60,.09,.18),black,.03)
    block(key+' body color front bumper',(0,front+.12,.40),(width*.65,.15,.16),paint,.05)
    block(key+' clean front registration',(0,front-.066,.73),(.68,.025,.16),number,.009)
    block(key+' clean rear registration',(0,rear+.075,.69),(.68,.025,.16),number,.008)
    # Cockpit readability through panoramic windows
    block(key+' minimalist dashboard',(0,front+length*.31,height*.88),(width*.73,.38,.08),black,.04)
    # Export original car in Blender coordinates.
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(OUT/(key+'.glb')),export_format='GLB',export_apply=True,export_materials='EXPORT')
    count=len([o for o in bpy.data.objects if o.type=='MESH'])
    assert count>=36,(key,count)
    return {'type':style,'meshes':count,'bytes':(OUT/(key+'.glb')).stat().st_size,'length_m':length,'width_m':width}
spec=[
    ('car_2026_ev_sedan','sedan',2.03,4.83,1.12),
    ('car_2026_crossover','suv',2.10,4.72,1.35),
    ('car_2026_hatchback','hatch',1.86,4.22,1.10),
    ('car_2026_sportback','sportback',2.04,4.67,1.10),
    ('car_2026_pickup','pickup',2.17,5.35,1.22),
    ('car_2026_delivery','van',2.05,5.07,1.38)]
results={}
for i,(name,style,w,l,h) in enumerate(spec):
    paint=material('Contemporary original metallic paint '+name,paints[i][1],.66,.27)
    results[name]=build_one(name,style,paint,w,l,h)
    print('CAR MODERN PASS',name,results[name],flush=True)
assert len(results)==6 and len({x['type'] for x in results.values()})==6
(OUT/'modern_vehicle_metrics.json').write_text(json.dumps(results,indent=2))
print('MODERN VEHICLE GAUNTLET GREEN — six unique 2020s silhouettes',flush=True)
