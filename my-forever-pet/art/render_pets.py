import bpy, math, os, sys
from mathutils import Vector
from math import pi
OUT=sys.argv[sys.argv.index("--")+1]
os.makedirs(OUT,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=True;scene.cycles.max_bounces=4
scene.render.resolution_x=384;scene.render.resolution_y=384;scene.render.resolution_percentage=100;scene.render.film_transparent=True;scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.world.color=(.27,.28,.33)
def mat(n,rgb,rough=.36):
    m=bpy.data.materials.new(n);m.use_nodes=True;m.diffuse_color=(*rgb,1);b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*rgb,1);b.inputs['Roughness'].default_value=rough;return m
body=mat('tintable leaf green',(.20,.76,.10),.29);pink=mat('inner ears',(.91,.35,.52));cream=mat('cream',(.91,.77,.56));gold=mat('golden accents',(1,.57,.15));blue=mat('blue wings',(.26,.53,.92),.28);dark=mat('brown ears',(.39,.18,.11));violet=mat('purple fins',(.53,.28,.76));red=mat('rooster crest',(.88,.11,.25));white=mat('fairy wing',(.55,.79,1),.25)
def smooth(o,m):
    o.data.materials.append(m)
    for p in o.data.polygons:p.use_smooth=True
    return o
def ell(name,x,y,rx,ry,depth=.52,m=body,dy=0,ang=0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=20,radius=1,location=(x/16,dy,-y/16))
    o=bpy.context.object;o.name=name;o.scale=(rx/16,depth,ry/16);o.rotation_euler[1]=ang;return smooth(o,m)
def tri(name,points,m,dy=.08,thickness=.16):
    verts=[(x/16,dy,-y/16) for x,y in points]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],[list(range(len(verts)))]);mesh.update()
    obj=bpy.data.objects.new(name,mesh);scene.collection.objects.link(obj);obj.data.materials.append(m)
    q=obj.modifiers.new('volume','SOLIDIFY');q.thickness=thickness;q=obj.modifiers.new('soft edges','BEVEL');q.width=.075;q.segments=4
    return obj
def ears(x=12,y=-18,m=body):
    for s in [-1,1]:
        tri('pointed ear',[(s*(x-7),y+8),(s*(x+5),y-13),(s*(x+10),y+8)],m,dy=.05,thickness=.24)
        tri('ear inset',[(s*(x-3),y+4),(s*(x+4),y-8),(s*(x+6),y+5)],pink,dy=-.17,thickness=.06)
def feet(x=10,y=19,m=body):
    for s in [-1,1]:ell('little paw',s*x,y,8,5,.31,m,dy=-.17,ang=s*.25)
def light(n,loc,energy,color,size):
    d=bpy.data.lights.new(n,'AREA');d.energy=energy;d.color=color;d.shape='DISK';d.size=size;o=bpy.data.objects.new(n,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(0,-10,0));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=4.25;scene.camera=cam
light('soft key',(-3,-5,5),620,(1,.86,.72),4);light('blue rim',(3,2,3),480,(.46,.65,1),3);light('fill',(3,-4,1),260,(.72,.83,1),3)
static=set(bpy.data.objects)
for id in range(12):
    for o in list(bpy.data.objects):
        if o not in static:bpy.data.objects.remove(o,do_unlink=True)
    if id==0:
        ears();feet();ell('round moss body',0,0,19,19,.8)
    elif id==1:
        ell('curled tail',19,12,11,5,.35,body,dy=.45,ang=.5);ears(14,-17);feet(10,18);ell('cat head',0,0,20,17,.77)
    elif id==2:
        ell('puppy body',0,12,13,12,.59);feet(9,22)
        for s in [-1,1]:ell('floppy ear',s*17,-3,7,15,.36,dark,dy=.12,ang=-s*.22)
        ell('dog head',0,-3,17,16,.82);ell('cream muzzle',0,7,9,6,.27,cream,dy=-.64)
    elif id==3:
        for s in [-1,1]:
            tri('dragon wing',[(s*9,4),(s*30,-13),(s*24,14),(s*10,13)],blue,dy=.40,thickness=.16)
            tri('dragon horn',[(s*8,-13),(s*14,-28),(s*17,-13)],gold,dy=.02,thickness=.25)
        ell('dragon tail',20,16,10,5,.30,body,dy=.3,ang=.35);feet(9,21);ell('dragon head',0,0,17,18,.77)
    elif id==4:
        tri('fish tail',[(9,0),(30,-16),(29,16)],gold,dy=.28,thickness=.23);ell('dorsal fin',-3,-15,7,4,.2,gold,dy=.15);ell('fish body',0,0,21,14,.64)
    elif id==5:
        ell('alien body',0,14,9,12,.5)
        for s in [-1,1]:
            ell('antenna',s*13,-23,1.8,7,.12,dark,ang=s*.50);ell('antenna bulb',s*16,-29,4,4,.20,pink)
        ell('alien head',0,-7,21,17,.75)
    elif id==6:
        for x,y in [(-14,17),(0,20),(14,17)]:ell('floating ghost hem',x,y,7,8,.40,body,dy=.05)
        ell('ghost body',0,-3,19,23,.67)
    elif id==7:
        for i in range(5):ell('octopus tentacle',-19+i*9.5,17+(i%2)*3,6,9,.31,body,dy=.03,ang=(i-2)*.18)
        ell('octopus head',0,-3,19,17,.74)
    elif id==8:
        ell('rooster tail',21,6,12,15,.42,blue,dy=.55);ell('rooster body',0,11,15,12,.58)
        for i in range(3):ell('crest',-9+i*7,-20+(i%2)*2,5,7,.26,red,dy=.15)
        feet(8,22,gold);ell('rooster head',0,-4,15,15,.7)
    elif id==9:
        for s in [-1,1]:
            ell('fairy upper wing',s*20,0,9,15,.19,white,dy=.46,ang=-s*.40);ell('fairy lower wing',s*17,13,6,9,.18,blue,dy=.42,ang=s*.45)
        ell('fairy dress',0,16,13,10,.46,violet);ell('fairy head',0,-8,13,14,.61)
    elif id==10:
        for s in [-1,1]:tri('pixie ear',[(s*10,-10),(s*28,-15),(s*15,3)],body,dy=.12,thickness=.22)
        ell('pixie body',0,16,12,10,.45);ell('pixie head',0,-7,14,15,.65)
    else:
        ears(13,-18);feet(10,21,gold);ell('owl body',0,0,20,20,.75)
        for s in [-1,1]:ell('owl face patch',s*8,-2,8,10,.14,cream,dy=-.66)
    scene.render.filepath=os.path.join(OUT,'pet_%d.png'%id);bpy.ops.render.render(write_still=True)
    print('MASCOT_RENDER_OK',id)
