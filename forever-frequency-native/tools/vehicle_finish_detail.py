"""City Zero original hard-surface automotive finishing. Mobile GLB geometry."""
import math
import bpy
from mathutils import Vector

VERSION = 2

def sculpt_door_skin(name, side, index, ya, yb, half, zlo, top, paint, accent, geom):
    """Watertight, gently cambered five-station moving door, not a box."""
    n = 6
    levels = (0., .12, .45, .78, 1.)
    verts, faces, slots = [], [], []
    for wall in (0, 1):
        for i in range(n + 1):
            t = i / n
            for f in levels:
                crown = (.007 + .019*math.sin(math.pi*f))*math.sin(math.pi*t)
                verts.append((side*(half+.004+crown-.010*f-.065*wall),
                    ya+(yb-ya)*t, zlo+(top-zlo)*f))
    stride = (n+1)*len(levels)
    for wall in (0, 1):
        for i in range(n):
            for j in range(len(levels)-1):
                a = wall*stride+i*len(levels)+j
                face = (a,a+1,a+1+len(levels),a+len(levels))
                faces.append(tuple(reversed(face)) if ((side>0) != bool(wall)) else face)
                slots.append(wall)
    for i in range(n):
        a,b = i*len(levels),(i+1)*len(levels)
        faces.extend(((a,b,b+stride,a+stride),
                      (a+len(levels)-1,a+stride+len(levels)-1,
                       b+stride+len(levels)-1,b+len(levels)-1)))
        slots.extend((1,0))
    for j in range(len(levels)-1):
        faces.append((j,j+stride,j+stride+1,j+1));slots.append(1)
        i=n*len(levels)+j
        faces.append((i,i+1,i+stride+1,i+stride));slots.append(1)
    return geom('DOOR_%s_%s_SCULPTED_SKIN'%('LEFT' if side<0 else 'RIGHT',index),
                verts,faces,[paint,accent],slots)

def wheel_finish(cx,y,r,style,alloy,rubber,trim,disk,box):
    side=1 if cx>0 else -1
    bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=6,
        major_radius=r*.83,minor_radius=r*.10,
        location=(cx+side*.133,y,r),rotation=(0,math.pi/2,0))
    ring=bpy.context.object
    ring.name='TIRE_ROUNDED_SHOULDER'
    ring.data.materials.append(rubber)
    disk('VENTED_BRAKE_ROTOR',(cx+side*.172,y,r),r*.59,.014,trim,28)
    disk('FORGED_WHEEL_CENTRE',(cx+side*.230,y,r),r*.135,.030,alloy,20)
    spokes=5 if style%2 else 6
    for i in range(spokes):
        for offset in (-.060,.060):
            a=i*math.tau/spokes+offset
            o=box('TWIN_FORGED_ALLOY_SPOKE',
                (cx+side*.224,y+math.cos(a)*r*.42,r+math.sin(a)*r*.42),
                (.025,r*.40,r*.045),alloy,.005)
            o.rotation_euler.x=a
    for i in range(5):
        a=i*math.tau/5
        disk('WHEEL_LUG',(cx+side*.250,y+math.cos(a)*r*.11,
            r+math.sin(a)*r*.11),r*.027,.007,trim,10)

def finish_car(car, *, length,width,height,half,front,rear,belt,roof,
               front_window,rear_window,roof_width,front_axle,rear_axle,
               wheel_radius,hinges,paint,accent,alloy,trim,glass,dark,
               headlamp,tail_lamp,box,tube,disk,geom):
    """Real body hardware; all door-side finish follows the moving hinges."""
    before=set(bpy.data.objects)
    sporty=car['category'] in ('exotic_supercar','exotic_coupe','japanese_sport','tuner_coupe')
    hood_end=front_window-.08
    if hood_end>front+.20:
        for s in (-1,1):
            tube('PRESSED_HOOD_SHOULDER_LINE',[
                (s*half*.56,front+length*.035,belt*.91),
                (s*half*.65,(front+hood_end)*.5,belt*.987),
                (s*half*.60,hood_end,belt*.995)],.0095,trim)
            tube('HOOD_PANEL_REVEAL',[
                (s*half*.88,front+length*.055,belt*.905),
                (s*half*.91,hood_end,belt*.97)],.008,dark)
    for s in (-1,1):
        sx=s*half*.70
        box('HEADLIGHT_RECESSED_BEZEL',(sx,front-.076,belt*.73),
            (width*.235,.024,.12),dark,.025)
        box('HEADLIGHT_PROJECTOR_LENS',(s*half*.76,front-.095,belt*.735),
            (.095,.018,.070),headlamp,.015)
        box('HEADLIGHT_LED_EYEBROW',(sx,front-.098,belt*.797),
            (width*.225,.016,.016),headlamp,.005)
        box('BUMPERS_AIR_CURTAIN',(s*half*.81,front-.085,belt*.39),
            (.105,.036,.20),dark,.027)
        box('FRONT_SPLITTER_CORNER',(s*half*.83,front-.09,.215),
            (.16,.19,.033),accent,.009)
        box('TAILLIGHT_RECESSED_BEZEL',(sx,rear+.079,belt*.70),
            (width*.25,.035,.16),dark,.016)
        box('TAILLIGHT_MULTI_LENS',(sx,rear+.103,belt*.72),
            (width*.216,.018,.071),tail_lamp,.012)
        box('REAR_BUMPER_REFLECTOR',(s*half*.77,rear+.076,belt*.34),
            (.19,.02,.039),tail_lamp,.009)
        for axle in (front_axle,rear_axle):
            for a in (-1.10,-.70,.70,1.10):
                box('ARCH_FASTENER',(s*(half+.023),
                    axle+wheel_radius*1.08*math.sin(a),
                    wheel_radius+wheel_radius*.96*math.cos(a)),
                    (.013,.023,.023),trim,.004)
        tube('FRONT_GLASS_WEATHERSEAL',[
            (s*half*.90,front_window,belt+.017),
            (s*roof_width,front_window+length*.092,roof-.022)],.012,trim)
        tube('WINDSCREEN_WIPER',[
            (s*half*.16,front_window+.030,belt+.018),
            (s*half*.53,front_window+.046,belt+.035),
            (s*half*.70,front_window+.090,belt+.055)],.008,dark)
    for col in range(-4,5):
        for row in range(2):
            box('INTAKE_GRID_CELL',(col*width*.069,front-.083,
                belt*(.415+row*.063)),(.010,.022,.035),
                alloy if sporty else trim,.003)
    for col in range(-2,3):
        box('REAR_DIFFUSER_VANE',(col*width*.106,rear+.073,.219),
            (.027,.25,.12),dark,.010)
    box('INTERIOR_DASHBOARD',(0,front_window+length*.045,belt*.91),
        (width*.71,.22,.09),dark,.032)
    box('INTERIOR_CLUSTER',(width*.12,front_window+length*.072,belt*.96),
        (.26,.028,.12),glass,.016)
    for s in (-1,1):
        box('INTERIOR_HEADREST',(s*.28,front_window+length*.18,roof*.78),
            (.20,.13,.26),trim,.05)
    attached=0
    for name in hinges:
        hinge=bpy.data.objects[name]
        s=-1 if '_LEFT_' in name else 1
        skins=[o for o in hinge.children if 'SCULPTED_SKIN' in o.name]
        if len(skins)!=1:
            raise AssertionError('No sculpted moving door: '+name)
        vertices=[skins[0].matrix_world@v.co for v in skins[0].data.vertices]
        ya=min(v.y for v in vertices);yb=max(v.y for v in vertices)
        if yb-ya<.35:
            raise AssertionError('Door width bad: '+name)
        x=s*(half+.042)
        objects=[
            tube('DOOR_CHROME_BELTLINE',[(x,ya+.042,belt*.955),
                (x,yb-.042,belt*.955)],.009,alloy),
            tube('DOOR_STAMPED_LOWER_CREASE',[(x,ya+.056,.405),
                (x,yb-.056,.402)],.006,dark),
            box('DOOR_LOCK_CYLINDER',(s*(half+.065),yb-.225,belt*.847),
                (.019,.027,.027),alloy,.005)]
        for obj in objects:
            matrix=obj.matrix_world.copy()
            obj.parent=hinge
            obj.matrix_world=matrix
            attached+=1
    count=sum(o.type=='MESH' for o in bpy.data.objects if o not in before)
    if count<65 or attached!=3*len(hinges):
        raise AssertionError('Incomplete car finishing: '+str((count,attached)))
    return {'detail_version':VERSION,'finish_meshes':count,
            'movable_trim_parts':attached,
            'features':['sculpted doors','forged twin spokes','brake rotor',
                'layered lights','hood creases','air curtains','window seals',
                'hinge-mounted trim','diffuser vanes','dashboard']}
