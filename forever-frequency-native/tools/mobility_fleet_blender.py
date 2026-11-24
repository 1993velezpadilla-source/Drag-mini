"""Forever Frequency City Zero — Blender 4.x: 26 extra mobility models.

Models are original, unbranded parametric geometry. OEM names in metadata are
proportion references, not licensed assets or exact vehicle replicas.

Coordinate contract: front = -Y; right = +X; up = +Z.
Export: individual GLBs into assets/mobility_fleet/.
Test: FF_MOBILITY_LIMIT=3 blender -b -t 2 --python tools/mobility_fleet_blender.py
Full: blender -b -t 2 --python tools/mobility_fleet_blender.py
"""
import bpy, json, math, os, random
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
DATA=json.loads((ROOT/"data"/"mobility_fleet_catalog.json").read_text())
OUT=ROOT/"assets"/"mobility_fleet"
OUT.mkdir(parents=True,exist_ok=True)
PAINTS=[(.10,.14,.21),(.83,.83,.79),(.56,.05,.08),(.05,.34,.32),(.54,.27,.09),(.28,.11,.44)]
def mat(n,color,metal=0,rough=.47,emit=0):
    m=bpy.data.materials.get(n) or bpy.data.materials.new(n)
    m.use_nodes=True
    m.diffuse_color=(*color,1)
    p=m.node_tree.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value=(*color,1)
    p.inputs["Metallic"].default_value=metal
    p.inputs["Roughness"].default_value=rough
    if emit:
        p.inputs["Emission Color"].default_value=(*color,1)
        p.inputs["Emission Strength"].default_value=emit
    return m
rubber=mat("TIRE_RUBBER",(.032,.036,.045),rough=.88)
alloy=mat("FORGED_ALLOY",(.56,.63,.67),metal=.77,rough=.29)
dark=mat("MATTE_GRAPHITE",(.052,.065,.075),metal=.15,rough=.58)
seat=mat("INTERIOR_UPHOLSTERY",(.15,.16,.19),rough=.8)
glass=mat("BLUE_TINT_GLASS",(.08,.19,.26),metal=.12,rough=.18)
warm=mat("WARM_LED",(.97,.68,.37),emit=1.6,rough=.17)
white=mat("WHITE_LED",(.70,.88,.96),emit=1.7,rough=.18)
red=mat("REAR_RED_LED",(.83,.05,.09),emit=1.4,rough=.2)
safety=mat("RESCUE_WHITE",(.86,.87,.84),rough=.5)
def block(n,x,y,z,w,l,h,m,bevel=.02):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(x,y,z))
    o=bpy.context.object;o.name=n
    o.dimensions=(w,l,h)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(m)
    if bevel:
        b=o.modifiers.new("Edge radius","BEVEL");b.width=bevel;b.segments=2
        bpy.ops.object.modifier_apply(modifier=b.name)
    return o
def ball(n,x,y,z,r,m,sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=r,location=(x,y,z))
    o=bpy.context.object;o.name=n;o.data.materials.append(m)
    return o
def tube(n,pts,r,m):
    c=bpy.data.curves.new(n,"CURVE");c.dimensions="3D"
    c.resolution_u=6;c.bevel_depth=r;c.bevel_resolution=3
    s=c.splines.new("POLY");s.points.add(len(pts)-1)
    for i,p in enumerate(pts):s.points[i].co=(p[0],p[1],p[2],1)
    o=bpy.data.objects.new(n,c);bpy.context.collection.objects.link(o)
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.object.convert(target="MESH")
    o.data.materials.append(m)
    return o
def poly(n,verts,faces,m):
    mesh=bpy.data.meshes.new(n)
    mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(n,mesh);bpy.context.collection.objects.link(o)
    o.data.materials.append(m)
    for p in mesh.polygons:p.use_smooth=True
    return o
def disk(n,x,y,z,r,depth,m,segments=28):
    bpy.ops.mesh.primitive_cylinder_add(vertices=segments,radius=r,depth=depth,
        location=(x,y,z),rotation=(0,math.pi/2,0))
    o=bpy.context.object;o.name=n;o.data.materials.append(m)
    for p in o.data.polygons:p.use_smooth=True
    return o
def wheel(n,x,y,r,style):
    disk(n+" rubber",x,y,r,r,.23,rubber,32)
    side=1 if x>0 else -1
    disk(n+" brake",x+side*.126,y,r,r*.73,.022,dark,28)
    disk(n+" center",x+side*.150,y,r,r*.27,.044,alloy,24)
    spoke_count=6+(style%3)*2
    for i in range(spoke_count):
        a=math.tau*i/spoke_count
        yy=y+math.sin(a)*r*.47;zz=r+math.cos(a)*r*.47
        p=block(n+" alloy spoke",x+side*.149,yy,zz,.030,r*.34,r*.058,alloy,.006)
        p.rotation_euler.x=a
def motorcycle(rec,paint):
    cat=rec["category"];k=rec["id"].split("__")[-1]
    L=rec["length_m"];H=rec["height_m"];r=(.235 if cat=="escooter" else .29 if cat=="moped" else .34 if cat=="supermoto" or cat=="dirtbike" else .32 if cat=="ebike" else .31)
    fy=-L*.36;ry=L*.34
    wheel("Front wheel",0,fy,r,1);wheel("Rear wheel",0,ry,r,0)
    # Visible two-wheel frame geometry and suspension/axles.
    front_head=(0,fy+.19,H*.75)
    engine=(0,.02,r+.17)
    rear_top=(0,ry-.22,H*.70)
    for a,b in [(front_head,engine),(engine,rear_top),(rear_top,front_head)]:
        tube("Triangulated chassis tube",[a,b],.038 if cat not in ("ebike","escooter") else .025,alloy)
    for s in (-1,1):
        tube("Front telescopic fork",[(s*.11,fy,r),(s*.13,fy+.15,H*.85)],.031,alloy)
        tube("Rear articulated swingarm",[(s*.11,ry,r),(s*.08,.03,r+.21)],.042,dark)
    if cat=="escooter":
        block("Anti-slip deck",0,0,r+.075,.31,L*.54,.10,dark,.045)
        tube("Tall steering stem",[(0,fy,r+.22),(0,fy+.04,H*.98)],.033,alloy)
        tube("Rider control bar",[(-.28,fy+.04,H*.98),(.28,fy+.04,H*.98)],.037,dark)
        block("Battery below floor",0,.02,r+.015,.22,L*.38,.055,paint,.04)
    elif cat=="ebike":
        tube("Pedal axle",[(0,.05,r+.12),(.12,.05,r+.12)],.035,dark)
        disk("Chain crank wheel",.10,.05,r+.12,r*.26,.03,dark,24)
        tube("Seatpost",[(0,ry-.18,H*.62),(0,ry-.23,H*.78)],.026,alloy)
        block("Saddle",0,ry-.23,H*.79,.20,.38,.095,seat,.04)
        tube("Bicycle handlebar",[(-.30,fy+.13,H*.89),(.30,fy+.13,H*.89)],.024,alloy)
        block("Integrated downtube battery",0,.06,H*.49,.12,L*.29,.13,paint,.04)
        tube("Rear chainline",[(.13,.05,r+.12),(.13,ry,r)],.018,dark)
    elif cat=="moped":
        block("Step through floor",0,-.02,r+.15,.47,L*.39,.12,paint,.07)
        block("Rear sculpted curved moped body",0,ry-.18,r+.36,.59,L*.34,.48,paint,.11)
        block("Single touring seat",0,ry-.10,H*.72,.38,.57,.12,seat,.08)
        block("Moped front shield",0,fy+.23,H*.58,.56,.24,H*.57,paint,.09)
        tube("Moped upright bars",[(-.37,fy+.08,H*.93),(.37,fy+.08,H*.93)],.032,dark)
    else:
        # Superbike, supermoto and dirt bike have visibly different front profiles.
        bike_offroad=cat in ("supermoto","dirtbike")
        tank_height=H*.59 if bike_offroad else H*.55
        block("Tapered tank and fairing",0,-.13,tank_height,.45,L*.33,.34,paint,.08)
        block("Rider seat",0,ry-.19,H*.65,.36,L*.34,.12,seat,.05)
        block("Tail body",0,ry-.26,H*.70,.41,L*.27,.15,paint,.03)
        if not bike_offroad:
            block("Superbike aerodynamic nose",0,fy+.27,H*.70,.48,.46,.37,paint,.085)
            block("Clear front windscreen",0,fy+.15,H*.89,.35,.18,.27,glass,.06)
            block("Lower engine fairing",0,.05,r+.27,.42,L*.50,.33,paint,.07)
            ball("Front projector lamp",0,fy+.026,H*.74,.075,white)
        else:
            block("Motocross front numberboard",0,fy+.17,H*.73,.27,.11,.26,paint,.03)
            block("High mounted front mudguard",0,fy+.10,r*1.85,.35,.48,.10,paint,.06)
            tube("Elevated handlebar",[(-.42,fy+.07,H*.98),(.42,fy+.07,H*.98)],.032,alloy)
            block("Exposed engine",0,.05,r+.22,.31,.38,.31,dark,.05)
            tube("High exhaust pipe",[(.17,.12,r+.32),(.24,ry-.20,H*.58),(.24,ry+.22,H*.54)],.034,alloy)
    if cat not in ("escooter","ebike"):
        ball("Rear taillight",0,ry+.32,H*.59,.060,red)
        block("Front position lamp",0,fy-.045,H*.64,.22,.052,.070,white,.01)
def buggy(rec,paint):
    L=rec["length_m"];W=rec["width_m"];H=rec["height_m"]
    r=H*.255;fw=-L*.33;rw=L*.33
    for sign in (-1,1):
        for yy in (fw,rw):wheel("All terrain buggy wheel",sign*W*.48,yy,r,1)
    block("Exposed ladder frame",0,0,.57,W*.70,L*.77,.18,dark,.04)
    block("Shaped hood",0,fw+.25,r+.55,W*.72,L*.22,.21,paint,.09)
    block("Rear engine bay",0,rw-.15,r+.42,W*.73,L*.22,.33,paint,.07)
    block("Twin racing seats",0,.12,r+.64,W*.70,L*.28,.38,seat,.085)
    # Open welded roll cage and working suspension geometry instead of a box body.
    corners=[(-W*.40,-L*.26,H*.73),(W*.40,-L*.26,H*.73),
             (-W*.40,L*.24,H*.76),(W*.40,L*.24,H*.76)]
    for x,y,z in corners:
        tube("Exposed rollover bar",[(x,y,.53),(x,y,z)],.06,alloy)
    for a,b in [(0,1),(2,3),(0,2),(1,3),(0,3),(1,2)]:
        tube("Cross-braced roof cage",[corners[a],corners[b]],.045,alloy)
    for sign in (-1,1):
        for y in (fw,rw):
            tube("Long travel double wishbone",[(sign*W*.32,y,.70),(sign*W*.49,y,r)],.041,alloy)
            tube("Damping coil-over",[(sign*W*.36,y,.80),(sign*W*.48,y,r*.88)],.054,dark)
    for x in (-W*.31,W*.31):
        block("Mudguard composite",x,fw,r*1.75,W*.22,L*.22,.10,paint,.07)
    for x in (-W*.22,W*.22):
        ball("LED offroad headlamp",x,fw-L*.12,r+.58,.13,white)
def watercraft(rec,paint):
    L=rec["length_m"];W=rec["width_m"];H=rec["height_m"]
    jet=rec["id"].startswith("watercraft__jet")
    sections=15
    rings=[]
    for i in range(sections):
        u=i/(sections-1);y=-L*.5+L*u
        hw=W*.5*(.20+.80*math.sin(u*math.pi)**.35)
        if jet:hw*=.90
        rings.append((y,hw))
    v=[];f=[]
    # Hull rings: keel at -0.52, chine and bulwark at +.38.
    for y,hw in rings:
        v.extend([(0,y,-.62),(-hw*.77,y,-.24),(-hw,y,.12),
                  (-hw*.92,y,.36),(hw*.92,y,.36),(hw,y,.12),(hw*.77,y,-.24)])
    for i in range(sections-1):
        a=i*7;b=(i+1)*7
        for j in range(6):f.append((a+j,a+j+1,b+j+1,b+j))
    geom=poly("V-hull planing nautical mesh",v,f,paint)
    block("Deck walk surface",0,0,.33,W*.78,L*.79,.09,dark,.08)
    if jet:
        block("Personal watercraft sculpted seat",0,.11,.67,W*.41,L*.38,.23,seat,.12)
        block("Jet runner nose cowling",0,-L*.27,.47,W*.65,L*.22,.30,paint,.10)
        tube("Watercraft steering bars",[(-W*.19,-L*.09,.94),(W*.19,-L*.09,.94)],.031,alloy)
        block("Rear jet exhaust vent",0,L*.42,.05,W*.26,.07,.19,alloy,.035)
        # Real molded watersport details: handlebar console, boarding grips and
        # spray deflectors -- formerly an unacceptable eight-mesh placeholder.
        block("Jet gauge cluster",0,-L*.08,.95,.31,.19,.14,dark,.045)
        block("Jet instrument face",0,-L*.10,1.025,.22,.15,.018,glass,.01)
        for sign in (-1,1):
            tube("Polymer side splash rail",[(sign*W*.37,-L*.30,.30),
                 (sign*W*.43,-L*.04,.32),(sign*W*.35,L*.32,.28)],.033,alloy)
            block("Rear boarding hand grip",sign*W*.29,L*.34,.50,
                  .065,.25,.05,dark,.025)
        block("Textured rear swim footrest",0,L*.34,.37,W*.55,L*.15,.04,seat,.02)
    else:
        block("Helm windshield",0,-L*.15,1.11,W*.62,.075,.64,glass,.06)
        block("Navigation console",0,-L*.14,.74,W*.39,L*.15,.38,paint,.07)
        block("Rider upholstered cabin seat",0,L*.12,.74,W*.43,L*.25,.24,seat,.07)
        if "cruiser" in rec["id"]:
            block("Hardtop cabin roof",0,L*.14,H*.84,W*.59,L*.34,.15,paint,.08)
            block("Side passenger glazing",W*.27,L*.16,H*.61,.035,L*.24,.39,glass,.02)
        else:
            # RIB hull must include recognizable REAL geometry: inflatable
            # segmented tubes, pilot/crew hardware, passenger restraints and
            # usable outboard. Previously 9 plain meshes was rejected by CI.
            for sign in (-1,1):
                tube("Inflatable rescue tube",[(sign*W*.48,y,.29) for y,_ in rings],.12,dark)
                tube("Upper rigid rub-rail",[(sign*W*.44,y,.39) for y,_ in rings],.025,alloy)
                block("Bow mooring cleat",sign*W*.31,-L*.35,.43,
                      .10,.15,.04,alloy,.016)
                block("Aft passenger handrail",sign*W*.29,L*.27,.65,
                      .035,L*.26,.035,alloy,.012)
            block("Marine instrument panel",0,-L*.16,.91,W*.31,.065,.13,dark,.027)
            block("Glass GPS navigation display",0,-L*.171,.93,W*.20,.016,.07,glass,.008)
            block("Outboard engine cowling",0,L*.47,.27,W*.25,L*.115,.43,dark,.09)
            block("Outboard propeller guard",0,L*.535,-.20,W*.30,.052,.20,alloy,.045)
            block("RIB nonslip bow step",0,-L*.35,.40,W*.49,L*.13,.045,seat,.015)
    for sign in (-1,1):
        ball("Nav sidelight",sign*W*.36,-L*.25,.47,.045,white if sign>0 else red)
def helicopter(rec,paint):
    L=rec["length_m"];W=rec["width_m"];H=rec["height_m"]
    cabin=L*.33
    block("Composite flight cabin",0,-L*.19,H*.44,W*.95,cabin,H*.48,paint,.37)
    block("Curved windscreens",0,-L*.36,H*.52,W*.80,.045,H*.28,glass,.04)
    block("Tailboom taper",0,L*.19,H*.60,W*.27,L*.48,.25,paint,.09)
    block("Tail vertical stabilizer",0,L*.42,H*.72,.10,L*.18,H*.42,paint,.04)
    for sign in (-1,1):
        tube("Skid strut",[(sign*W*.35,-L*.2,H*.29),(sign*W*.43,-L*.2,.20)],.047,alloy)
        tube("Skid strut",[(sign*W*.35,L*.03,H*.28),(sign*W*.43,L*.03,.20)],.047,alloy)
        tube("Long tubular landing skid",[(sign*W*.43,-L*.36,.20),
             (sign*W*.43,L*.17,.20)],.069,dark)
    block("Rotor tower",0,-L*.15,H*.82,.16,.18,.32,alloy,.03)
    blade_count=4 if "city_air" in rec["id"] else 3
    for i in range(blade_count):
        a=math.tau*i/blade_count
        o=block("Main rotor articulated blade",
                (math.cos(a)*L*.21,-L*.15+math.sin(a)*L*.21,H*.98),
                (L*.45,.13,.034),dark,.028)
        o.rotation_euler.z=a
    # Tail antitorque rotor, visually separate plane from main mast
    for i in range(3):
        a=i*math.tau/3
        o=block("Tail anti torque rotor",(.07,L*.40,H*.70),
                (.02,.12,L*.18),dark,.02)
        o.rotation_euler.x=a
    ball("Medical or patrol light",0,-L*.48,H*.40,.09,white)
def airplane(rec,paint):
    L=rec["length_m"];span=rec["width_m"];H=rec["height_m"]
    sections=16
    vs=[];fs=[]
    for i in range(sections):
        u=i/(sections-1);y=-L*.5+L*u
        w=(.22+.78*math.sin(math.pi*u)**.55)*min(1.18,L*.10)
        z=H*.42
        vs.extend([(-w,y,z),(-w*.70,y,z+w*.65),(w*.70,y,z+w*.65),
                   (w,y,z),(w*.70,y,z-w*.55),(-w*.70,y,z-w*.55)])
    for i in range(sections-1):
        a=i*6;b=(i+1)*6
        for j in range(6):fs.append((a+j,a+(j+1)%6,b+(j+1)%6,b+j))
    poly("Aerodynamic tubular fuselage",vs,fs,paint)
    # Monoplane wings have airfoil-like thickness and tip geometry.
    wing_z=H*.73 if "sky_train" in rec["id"] else H*.48
    for sign in (-1,1):
        poly("3D main wing",[(0,-L*.07,wing_z),(sign*span*.5,-L*.04,wing_z+.09),
             (sign*span*.45,L*.19,wing_z-.03),(0,L*.18,wing_z)],
             [(0,1,2,3)],paint)
        poly("Rear horizontal elevator",[(0,L*.39,H*.49),
             (sign*span*.17,L*.42,H*.49),(sign*span*.17,L*.48,H*.49),
             (0,L*.47,H*.49)],[(0,1,2,3)],paint)
    poly("Vertical tail fin",[(0,L*.35,H*.48),(0,L*.46,H*.89),
         (0,L*.49,H*.91),(0,L*.49,H*.48)],[(0,1,2,3)],paint)
    block("Panoramic pilot windscreen",0,-L*.27,H*.61,min(1.55,L*.14),L*.10,.21,glass,.13)
    for sign in (-1,1):
        wheel("Landing gear",sign*.65,-L*.03,.31,0)
    wheel("Nose wheel",0,-L*.29,.24,1)
    if "express" in rec["id"]:
        for sign in (-1,1):
            ball("Turboprop nacelle",sign*span*.25,-L*.05,H*.48,.50,dark)
            block("Aircraft propeller blade",sign*span*.25,-L*.085,H*.52,.07,.05,1.90,alloy,.03)
    else:
        ball("Piston engine cowling",0,-L*.47,H*.45,.53,dark)
        block("Propeller radial blade",0,-L*.52,H*.46,.09,.055,1.8,alloy,.03)
def railcar(rec,paint):
    L=rec["length_m"];W=rec["width_m"];H=rec["height_m"]
    n=3 if "regional" in rec["id"] else 2
    block("Modern railcar aluminum side shell",0,0,H*.49,W*.91,L*.93,H*.64,paint,.22)
    block("Black framed panoramic roof",0,0,H*.84,W*.86,L*.91,.16,dark,.08)
    for sign in (-1,1):
        for i in range(13):
            y=-L*.41+L*.82*(i+.5)/13
            block("Continuous rail window glazing",sign*W*.462,y,H*.64,
                  .042,L*.054,H*.19,glass,.018)
        for i in (3,10):
            y=-L*.41+L*.82*(i+.5)/13
            block("Rail double sliding doorway",sign*W*.468,y,H*.43,
                  .05,L*.075,H*.46,alloy,.022)
    for y in (-L*.33,L*.33):
        for sign in (-1,1):
            wheel("Track railway bogie",sign*W*.39,y,.46,2)
    # Top pantograph on electric city lines
    tube("Pantograph single arm",[(0,0,H*.9),(.25,0,H*1.04),(-.10,0,H*1.16)],.055,alloy)
    tube("Pantograph electricity head",[(-.52,0,H*1.16),(.52,0,H*1.16)],.057,dark)
    block("Aerodynamic cab face",0,-L*.47,H*.52,W*.83,.18,H*.60,glass,.13)
    for s in (-1,1):
        ball("Train cab headlamp",s*W*.30,-L*.475,H*.32,.10,white)
def create(rec):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    paint=mat("AURA_BODY_PAINT",PAINTS[sum(map(ord,rec["id"]))%len(PAINTS)],metal=.54,rough=.31)
    family=rec["category"]
    if family in ("hypersport","supermoto","dirtbike","moped","escooter","ebike"):
        motorcycle(rec,paint)
    elif family=="buggy":buggy(rec,paint)
    elif family=="watercraft":watercraft(rec,paint)
    elif family=="helicopter":helicopter(rec,paint)
    elif family=="airplane":airplane(rec,paint)
    elif family=="rail":railcar(rec,paint)
    else:raise AssertionError("unrecognized type "+family)
    objects=[o for o in bpy.data.objects if o.type=="MESH"]
    tris=sum(len(p.vertices)-2 for o in objects for p in o.data.polygons)
    assert len(objects)>=12,(rec["id"],len(objects))
    assert tris<90000,(rec["id"],tris)
    output=OUT/(rec["id"]+".glb")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(output),export_format="GLB",
        use_selection=True,export_materials="EXPORT",export_apply=True)
    assert output.stat().st_size>=10000,(rec["id"],output.stat().st_size)
    return dict(id=rec["id"],category=family,meshes=len(objects),
                triangles=tris,glb_bytes=output.stat().st_size)
limit=int(os.environ.get("FF_MOBILITY_LIMIT",str(len(DATA["models"]))))
metrics=[]
for rec in DATA["models"][:limit]:
    value=create(rec);metrics.append(value)
    print("MOBILITY EXPORTED",len(metrics),limit,value,flush=True)
(OUT/"metrics.json").write_text(json.dumps(metrics,indent=2))
if limit==26:
    assert len({m["category"] for m in metrics})==11
    assert len(metrics)==26
    print("MOBILITY BLENDER GAUNTLET GREEN: 26 unique models in 11 families",flush=True)
else:
    print("MOBILITY PROTOTYPE ONLY: NOT PRODUCTION APPROVED",flush=True)
