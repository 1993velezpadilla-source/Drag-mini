"""Original Blender anatomy pilots; never label as approved production art."""
import bpy, math, sys, pathlib
from mathutils import Vector
OUT=pathlib.Path(sys.argv[sys.argv.index("--")+1])
OUT.mkdir(parents=True,exist_ok=True)
def mat(name,c):
    m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);return m
def part(name,kind,xyz,scale,material,parent=None):
    if kind=="sphere": bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=xyz)
    elif kind=="cone": bpy.ops.mesh.primitive_cone_add(vertices=12,location=xyz)
    elif kind=="torus": bpy.ops.mesh.primitive_torus_add(major_segments=20,minor_segments=6,location=xyz)
    else: bpy.ops.mesh.primitive_cube_add(location=xyz)
    o=bpy.context.object;o.name=name;o.scale=scale;o.data.materials.append(material)
    if parent:o.parent=parent
    return o
def pivot(name,xyz,parent=None):
    o=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(o);o.location=xyz
    if parent:o.parent=parent
    return o
def key(o,frame):
    for field in ("location","rotation_euler","scale"):o.keyframe_insert(data_path=field,frame=frame)
def setup():
    bpy.ops.object.select_all(action="SELECT");bpy.ops.object.delete(use_global=False)
    scene=bpy.context.scene
    scene.render.engine="BLENDER_WORKBENCH";scene.render.resolution_x=96;scene.render.resolution_y=96;scene.render.resolution_percentage=100;scene.render.film_transparent=True
    scene.display.shading.light="STUDIO";scene.display.shading.color_type="MATERIAL";scene.display.shading.show_shadows=True;scene.display.shading.show_cavity=True
    scene.render.image_settings.file_format="PNG";scene.render.image_settings.color_mode="RGBA"
    scene.frame_start=1;scene.frame_end=9;scene.render.fps=12
    bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type="ORTHO";cam.data.ortho_scale=3.2;scene.camera=cam
    return scene,cam
def palette():
    return [mat("velvet",(.23,.035,.42)),mat("brass",(.95,.63,.12)),mat("heart-thread",(.98,.08,.65)),mat("shadow",(.035,.016,.065)),mat("biome",(.22,.42,.18)),mat("shell",(.39,.16,.3))]
def mushroom(p):
    purple,gold,pink,dark,green,shell=p
    root=pivot("Sporeling", (0,0,0));cap=pivot("cap", (0,0,1.45),root)
    part("stalk","sphere",(0,0,.83),(.39,.32,.66),shell,root)
    part("cap","sphere",(0,0,0),(.85,.66,.36),purple,cap)
    for i in range(7):
        a=i*math.tau/7
        part("spore spot "+str(i),"sphere",(.58*math.cos(a),.45*math.sin(a),.23),(.13,.13,.06),pink,cap)
    part("cap rim","torus",(0,0,-.05),(.8,.62,.16),gold,cap)
    for x in (-.13,.13):part("eye","sphere",(x,-.295,.94),(.085,.05,.12),pink,root)
    feet=[]
    for i,x in enumerate((-.23,.23)):
        f=pivot("root foot "+str(i),(x,0,.19),root);part("toe","sphere",(0,-.09,0),(.18,.24,.13),green,f);feet.append(f)
    for f in range(1,10):
        t=(f-2)*math.pi/2 if f<=5 else 0
        for i,o in enumerate(feet):
            o.location.y=.18*math.sin(t+i*math.pi) if 2<=f<=5 else 0
            o.location.z=.19+.12*max(0,math.cos(t+i*math.pi)) if 2<=f<=5 else .19;key(o,f)
        cap.scale=(1,1,1) if f<6 else [(1,1,1),(1.15,1.15,.8),(.85,.85,1.2),(1,1,1)][f-6]
        cap.rotation_euler.x=0 if f<6 else [0,-.23,.27,0][f-6];key(cap,f)
    return root
def crab(p):
    purple,gold,pink,dark,green,shell=p
    root=pivot("Coralcrab",(0,0,0))
    part("shell","sphere",(0,0,.78),(.78,.57,.48),purple,root)
    part("shell ridge","sphere",(0,0,1.05),(.59,.42,.25),gold,root)
    for x in (-.24,.24):
        part("eye stalk","sphere",(x,-.48,.99),(.12,.13,.2),dark,root)
        part("eye","sphere",(x,-.58,1.02),(.08,.055,.08),pink,root)
    legs=[];claws=[]
    for side in (-1,1):
        for i in range(3):
            o=pivot("walking joint "+str(side)+"_"+str(i),(side*.54,.27-i*.28,.52),root)
            part("upper leg","sphere",(side*.22,0,-.1),(.29,.095,.1),shell,o)
            part("foot","sphere",(side*.42,0,-.31),(.12,.085,.25),purple,o);legs.append((o,side,i))
        arm=pivot("claw shoulder "+str(side),(side*.5,-.37,.73),root)
        part("claw palm","sphere",(side*.26,-.22,0),(.27,.27,.18),purple,arm)
        jaws=[]
        for sign in (-1,1):
            j=pivot("jaw "+str(side)+"_"+str(sign),(side*.26+sign*.15,-.4,0),arm)
            part("pincer","cone",(0,-.15,0),(.15,.14,.27),gold,j).rotation_euler.x=math.pi/2
            jaws.append((j,sign))
        claws.append((arm,side,jaws))
    for f in range(1,10):
        t=(f-2)*math.pi/2
        for o,side,i in legs:
            o.rotation_euler.z=.38*math.sin(t+i*math.pi+side) if 2<=f<=5 else 0;key(o,f)
        for arm,side,jaws in claws:
            arm.rotation_euler.z=side*[0,.55,-.32,0][f-6] if f>=6 else 0;key(arm,f)
            for j,sign in jaws:
                j.rotation_euler.z=sign*[.1,.65,0,.1][f-6] if f>=6 else sign*.1;key(j,f)
    return root
def wisp(p):
    purple,gold,pink,dark,green,shell=p
    root=pivot("NovaWisp",(0,0,0));core=pivot("core",(0,0,1.05),root)
    part("heart","sphere",(0,0,0),(.36,.36,.36),purple,core)
    for x in (-.11,.11):part("eye","sphere",(x,-.32,.03),(.075,.04,.1),pink,core)
    ring=part("orbital brass hoop","torus",(0,0,0),(.68,.68,.32),gold,core);ring.rotation_euler.x=.6
    satellites=[]
    for i in range(3):
        sat=pivot("orbit "+str(i),(0,0,0),core)
        part("shard","cone",(.74,0,0),(.13,.13,.29),pink,sat);satellites.append(sat)
    for f in range(1,10):
        phase=(f-2)*math.tau/4 if 2<=f<=5 else 0
        core.location.z=1.05+.08*math.sin(phase) if f<6 else 1.05+[0,.13,-.12,0][f-6];key(core,f)
        for i,sat in enumerate(satellites):
            sat.rotation_euler.z=i*math.tau/3+phase if f<6 else i*math.tau/3+[0,.7,2.3,math.tau][f-6]
            sat.scale=(1,)*3 if f<6 else ((1,)*3,(.65,)*3,(1.35,)*3,(1,)*3)[f-6];key(sat,f)
        ring.rotation_euler.y=.35*math.sin(phase) if f<6 else [0,.5,-.5,0][f-6];key(ring,f)
    return root
for name,build in (("sporeling",mushroom),("coralcrab",crab),("nova_wisp",wisp)):
    scene,cam=setup();root=build(palette())
    folder=OUT/name;folder.mkdir(exist_ok=True)
    for d,angle in (("front",0),("back",math.pi),("left",-math.pi/2),("right",math.pi/2)):
        cam.location=(5*math.sin(angle),-5*math.cos(angle),3.25)
        cam.rotation_euler=(Vector((0,0,.9))-cam.location).to_track_quat("-Z","Y").to_euler()
        for frame in range(1,10):
            scene.frame_set(frame);scene.render.filepath=str(folder/f"{d}_{frame:02}.png");bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/(name+".blend")))
    print("VOLNOX_BLENDER_PILOT",name,flush=True)
