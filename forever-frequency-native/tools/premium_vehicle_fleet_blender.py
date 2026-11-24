"""Forever Frequency City Zero — authored 60-vehicle Blender fleet.
9 conventional car classes + basic/luxury trucks + future EVs.
Visual geometry is ORIGINAL; manufacturers are research references, never assets.
60 base GLBs share eight player-editable color presets, no geometry duplication.
Example: blender -b -t 2 --python tools/premium_vehicle_fleet_blender.py
Optional: FF_CAR_LIMIT=3 to test selected first models (not an approval build).
"""
import bpy, json, math, random, os, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(Path(__file__).resolve().parent))
from vehicle_finish_detail import sculpt_door_skin, wheel_finish, finish_car
CAR_DIR=ROOT/'assets'/'premium_fleet'
CAR_DIR.mkdir(parents=True,exist_ok=True)
catalog=json.loads((ROOT/'data'/'vehicle_fleet_catalog.json').read_text())
models=catalog['models']
PHOTO_SOURCES=json.loads((ROOT/'data'/'real_vehicle_photo_references.json').read_text())['vehicle_references']
PHOTO_PROFILES={r['id']:r['photo_traced_profile'] for r in PHOTO_SOURCES}
assert len(models)==59 and len({m['id'] for m in models})==59
assert not any('REVULSE' in (m['id']+' '+m.get('name','')).upper() for m in models), 'Rejected prototype must never be exported'
palette={
'Obsidian Black':(.028,.035,.048),'Pearl White':(.85,.88,.88),
'Graphite Silver':(.34,.40,.44),'Midnight Blue':(.045,.095,.20),
'Caldera Red':(.56,.040,.071),'Emerald Teal':(.045,.35,.32),
'Sunset Copper':(.55,.22,.09),'Champagne Gold':(.56,.42,.25),
'Electric Violet':(.28,.11,.43),'Storm Grey':(.28,.32,.34)}
def mat(n,rgb,metal=0,rough=.40,emit=0):
 m=bpy.data.materials.get(n) or bpy.data.materials.new(n)
 m.diffuse_color=(*rgb,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF')
 bs.inputs['Base Color'].default_value=(*rgb,1)
 bs.inputs['Metallic'].default_value=metal
 bs.inputs['Roughness'].default_value=rough
 if emit:
  bs.inputs['Emission Color'].default_value=(*rgb,1)
  bs.inputs['Emission Strength'].default_value=emit
 return m
rubber=mat('FF_TIRE_RUBBER',(.030,.033,.038),0,.9)
alloy=mat('FF_ALLOY_MACHINED',(.45,.50,.52),.75,.30)
dark=mat('FF_FACIA_GRAPHITE',(.02,.028,.038),.28,.52)
glass=mat('FF_GLASS_SMOKE',(.085,.17,.22),.20,.23)
glass_light=mat('FF_WINDSCREEN',(.12,.235,.30),.24,.23)
trim=mat('FF_TRIM_BLACK',(.07,.07,.08),.49,.34)
headlamp=mat('FF_LED_FRONT',(.72,.88,1),.05,.14,1.5)
tail_lamp=mat('FF_LED_REAR',(.87,.02,.032),.0,.20,1.2)
turn_lamp=mat('FF_LED_AMBER',(.98,.41,.03),.05,.23,1.0)
seat=mat('FF_CABIN_SEATS',(.22,.22,.24),.1,.78)
def box(n,loc,dims,m,bev=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
 o=bpy.context.object;o.name=n;o.dimensions=dims
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(m)
 if bev:
  mod=o.modifiers.new('Soft manufactured edge','BEVEL')
  mod.width=bev;mod.segments=2
  bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def geom(n,verts,faces,mats,inds=None):
 mesh=bpy.data.meshes.new(n);mesh.from_pydata(verts,[],faces);mesh.update()
 o=bpy.data.objects.new(n,mesh);bpy.context.collection.objects.link(o)
 for m in mats:mesh.materials.append(m)
 for i,face in enumerate(mesh.polygons):
  face.material_index=inds[i] if inds else 0
  face.use_smooth=True
 return o
def tube(n,points,r,m):
 c=bpy.data.curves.new(n,'CURVE');c.dimensions='3D';c.bevel_depth=r
 c.resolution_u=4;c.bevel_resolution=2
 p=c.splines.new('POLY');p.points.add(len(points)-1)
 for i,v in enumerate(points):p.points[i].co=(v[0],v[1],v[2],1)
 o=bpy.data.objects.new(n,c);bpy.context.collection.objects.link(o)
 bpy.ops.object.select_all(action='DESELECT')
 o.select_set(True);bpy.context.view_layer.objects.active=o
 bpy.ops.object.convert(target='MESH')
 o.data.materials.append(m);return o
def disk(n,center,r,depth,m,vertices=32):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,
 location=center,rotation=(0,math.pi/2,0))
 o=bpy.context.object;o.name=n;o.data.materials.append(m)
 for f in o.data.polygons:f.use_smooth=True
 return o
def section_wheels(y,axle,r):
 d=abs(y-axle)
 if d>r*1.09:return .19
 return max(.19,r+math.sqrt(max(0,(r*1.09)**2-d*d))*.72)
def wheel(cx,y,r,mount,style):
 sign=1 if cx>0 else -1
 disk('Michelin-style unbranded tire rubber', (cx,y,r),r,.265,rubber,40)
 disk('Vented brake and wheel alloy', (cx+sign*.151,y,r),r*.72,.036,alloy,32)
 disk('Centre wheel hub', (cx+sign*.188,y,r),r*.18,.057,trim,20)
 for i in range((5,6,7,8,10)[style%5]):
  a=i*math.tau/(5,6,7,8,10)[style%5]
  radius=r*.43
  blade=box('Turbine wheel spoke',
   (cx+sign*.193,y+math.cos(a)*radius,r+math.sin(a)*radius),
   (.032,r*.33,r*.078),trim,.007)
  blade.rotation_euler.x=a
 wheel_finish(cx,y,r,style,alloy,rubber,trim,disk,box)
def line_light(n,y,z,hw,material):
 box(n,(0,y,z),(hw*2,.056,.045),material,.012)
def pane(n,coords,m):
 geom(n,coords,[(0,1,2,3)],[m])
def door_plan(car,front_ax,rear_ax,r,L):
    """Independent movable entry apertures, no static shell behind any door."""
    count=4 if car['category'] in ('flagship','german_sedan','luxury_suv','compact_sedan','hatchback','basic_pickup','luxury_pickup','electric_future') else 2
    # Most real cars have 4 doors except sporty 2-door roadsters.
    start=front_ax+r*1.19+.08
    end=rear_ax-r*1.14-.06
    # For individually photographed cars, front/rear door panel breaks come
    # from the saved real-car reference sheet, not generic wheelbase guessing.
    p=PHOTO_PROFILES.get(car['id'])
    if p:
        start=-L*.5+L*p['door_front']
        end=-L*.5+L*p['door_rear']
        if not (-L*.5<start<end<L*.5):
            raise ValueError('Invalid photo-traced panel cut '+car['id'])
    # Long-wheelbase vehicles keep a useful entry corridor.
    if end-start<.90:
        start=-L*.16;end=L*.16
    if count==4:
        mid=(start+end)*.5
        return [("FRONT",start,mid-.032),("REAR",mid+.032,end)],count
    return [("FRONT",start,end)],count

def make_working_door(name,side,index,ystart,yend,half,belt,roof,roof_w,
                      front_window,rear_window,front_roof,rear_roof,paint,accent):
    """Export a real Blender Empty hinge and its rigid door mesh, window,
    physical frame, handle and interior surface. Godot animates hinge.rotation.y.
    Blender local positive Z maps to Godot positive Y."""
    hinge_name="DOOR_%s_%s_HINGE"%("LEFT" if side<0 else "RIGHT",index)
    bpy.ops.object.empty_add(type='PLAIN_AXES',location=(side*half*.99,ystart,0))
    hinge=bpy.context.object;hinge.name=hinge_name
    def attach(obj):
        matrix=obj.matrix_world.copy()
        obj.parent=hinge
        obj.matrix_world=matrix
        return obj
    gap=.026
    ya=ystart+gap
    yb=yend-gap
    if yb-ya<.23: raise ValueError("Unusable passenger entry "+name+" "+str(yb-ya))
    x=side*(half+.004)
    zlow=.29
    panel_top=belt*.975
    # Outer door, nonzero thickness. This moves INSTEAD of the cut-out shell.
    attach(sculpt_door_skin(name,side,index,ya,yb,half,zlow,panel_top,paint,accent,geom))
    attach(box("DOOR_%s_%s_INNER"%("LEFT" if side<0 else "RIGHT",index),
        (x-side*.075,(ya+yb)*.5,(zlow+panel_top)*.5),
        (.055,yb-ya-.035,panel_top-zlow-.07),accent,.02))
    attach(box("DOOR_%s_%s_HANDLE"%("LEFT" if side<0 else "RIGHT",index),
        (side*(half+.072),yb-.14,belt*.85),(.022,.15,.042),alloy,.012))
    attach(box("DOOR_%s_%s_LOWER_TRIM"%("LEFT" if side<0 else "RIGHT",index),
        (side*(half+.049),(ya+yb)*.5,zlow+.070),
        (.018,yb-ya-.08,.024),accent,.006))
    # Glass is fixed TO THE OPENING DOOR, not left hanging in space.
    # Upper window stays strictly inside cabin and inside door extents.
    window_low=belt+.018
    window_top=roof-.080
    window_mid=(ya+yb)*.5
    if window_top>window_low+.12:
        y_win0=max(ya+.08,front_roof)
        y_win1=min(yb-.07,rear_roof)
        if y_win1-y_win0>.17:
            attach(box("DOOR_%s_%s_MOVING_GLASS"%("LEFT" if side<0 else "RIGHT",index),
                (side*roof_w*.995,(y_win0+y_win1)*.5,(window_low+window_top)*.5),
                (.035,y_win1-y_win0,window_top-window_low),glass,.019))
            for y_edge in (y_win0,y_win1):
                attach(tube("DOOR_WINDOW_RIGID_FRAME",[
                     (side*half*.95,y_edge,window_low),
                     (side*roof_w,y_edge,window_top)],.016,accent))
    hinge["door_side"]= "LEFT" if side<0 else "RIGHT"
    hinge["door_location"]=index
    hinge["door_open_degrees"]=float(65 if side<0 else -65)
    hinge["interactive"]=True
    return hinge_name

def build_car(car):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 name=car['id'];seed=sum(ord(c)*i for i,c in enumerate(name,1))
 rnd=random.Random(seed)
 category=car['category'];style=int(car['body_style'])
 L=car['length_m'];W=car['width_m'];H=car['height_m'];half=W*.5
 front=-L*.5;rear=L*.5;wheel_radius=car['wheel_radius_m']
 axle=L*min(.68,max(.56,car['wheelbase_ratio']))*.5
 front_ax=-axle;rear_ax=axle
 whitecaps=category in ('flagship','luxury_pickup')
 paint=mat('FF_BODY_PAINT',palette[car['colors'][car['color_default_index']]],.58,.27)
 accent=mat('FF_BODY_ACCENT',(.30,.30,.33) if whitecaps else (.08,.10,.12),.45,.30)
 if style==6:
  paint=mat('FF_BODY_PAINT',(.37,.41,.45),.74,.27)
 high=category in ('basic_pickup','luxury_pickup','luxury_suv')
 sport=category in ('exotic_supercar','exotic_coupe','japanese_sport','tuner_coupe')
 bonnet=H*(.59 if high else .68 if sport else .66)
 belt=H*(.80 if high else .69)
 # Main metal fenders are sculpted around arches, not solid big boxes.
 segments=48
 yy=[front+(rear-front)*i/segments for i in range(segments+1)]
 widths=[half*(.80+.20*math.sin(i/segments*math.pi)**.50) for i in range(segments+1)]
 # Doors are separated into actual mechanical meshes and hinges.
 door_intervals,number_of_doors=door_plan(car,front_ax,rear_ax,wheel_radius,L)
 # Each movable panel replaces the exact side-shell band beneath it.
 door_ranges=[(a,b) for _,a,b in door_intervals]
 # side body with real wheel openings
 for sign in (-1,1):
  vertices=[]
  for i,y in enumerate(yy):
   w=widths[i]
   z=max(section_wheels(y,front_ax,wheel_radius),section_wheels(y,rear_ax,wheel_radius))
   vertices.extend([(sign*w*.99,y,z),(sign*w,y,belt*.91),
                    (sign*w*.945,y,belt)])
  faces=[]
  for k in range(segments):
   q=k*3
   ycenter=(yy[k]+yy[k+1])*.5
   if any(a<=ycenter<=b for a,b in door_ranges):
    continue
   faces.extend([(q,q+1,q+4,q+3),(q+1,q+2,q+5,q+4)])
  geom('FIXED metal fenders NO DOOR SHELL OVERLAY',vertices,faces,[paint])
  for axle_y in (front_ax,rear_ax):
   arch=[(sign*(half+.014),axle_y-wheel_radius*1.09*math.cos(i*math.pi/32),
     wheel_radius+wheel_radius*.94*math.sin(i*math.pi/32)) for i in range(33)]
   tube('Wheel arch moulding',arch,.015,accent)
  # The door panels and handles are moved independently by their hinge nodes.
  # No fake static shut lines or repeated handles in fixed architecture.
  box('Side skirt',(sign*(half*.96),0,.29),(.07,L*.61,.08),accent,.02)
 # Upper bonnet and boot — sculpted dual shoulder profile.
 vertices=[]
 for i,y in enumerate(yy):
  w=widths[i]
  z=belt*(.91 if i<6 or i>segments-6 else .98)
  vertices.extend([(-w,y,z),(-w*.64,y,z+.023),(0,y,z+.068),
                  (w*.64,y,z+.023),(w,y,z)])
 faces=[]
 for k in range(segments):
  q=k*5
  # Only real bonnets/decks are metal: do not skin over the passenger cabin
  # or cover the visibly hollow pickup bed with a solid slab.
  center_y=(yy[k]+yy[k+1])*.5
  cockpit_front=front+L*(.24 if sport else .25)
  cockpit_rear=rear-L*(.24 if sport else .22)
  if style in (4,5):
   cockpit_front=front+L*.27;cockpit_rear=rear+.1
  elif style==6:
   cockpit_front=front+L*.19;cockpit_rear=rear+.1
  # Never leave the generic roof/bonnet split for the photographed cars.
  guide=PHOTO_PROFILES.get(name)
  if guide:
   cockpit_front=front+L*guide['front_glass']
   if style not in (4,5,6):
    cockpit_rear=front+L*guide['rear_glass']
  if cockpit_front<center_y<cockpit_rear:continue
  for i in range(4):faces.append((q+i,q+i+1,q+i+6,q+i+5))
 geom('Gently curved bonnet rear deck',vertices,faces,[paint])
 # A proper glass cabin with sloped front windshield, actual roof
 front_window=front+L*(.24 if sport else .25)
 rear_window=rear-L*(.24 if sport else .22)
 front_roof=front_window+L*(.09 if high else .11)
 rear_roof=rear_window-L*(.07 if high else .095)
 roof=H-.035
 roof_w=half*(.78 if sport else .82 if high else .83)
 if style in (4,5):
  # A realistic pickup cab; rear cargo bed is hollow and clearly defined.
  front_window=front+L*.27
  front_roof=front_window+L*.08
  rear_roof=front+L*.53
  rear_window=front+L*.59
  roof_w=half*.86
 elif style==6:
  # angular wedge EV pickup: deliberately original but recognizable body class
  front_window=front+L*.19;front_roof=front+L*.42
  rear_roof=front+L*.59;rear_window=front+L*.76
  roof_w=half*.86
 # The exact greenhouse key stations are derived from saved reference-photo
 # briefs. Their visual fit is deliberately unapproved until comparison.
 guide=PHOTO_PROFILES.get(name)
 if guide:
  front_window=front+L*guide['front_glass']
  front_roof=front+L*guide['roof_front']
  rear_roof=front+L*guide['roof_rear']
  rear_window=front+L*guide['rear_glass']
  if not front_window<front_roof<rear_roof<rear_window:
   raise ValueError('Photo greenhouse station ordering invalid '+name)
 cab=[(-roof_w,front_roof,roof),(roof_w,front_roof,roof),
      (roof_w,rear_roof,roof),(-roof_w,rear_roof,roof)]
 pane('Painted manufactured roof panel',cab,paint)
 # separate front windscreen & rear glazing, with frame border
 pane('Sloped proper front windshield',[
  (-half*.91,front_window,belt), (half*.91,front_window,belt),
  (roof_w,front_roof,roof),(-roof_w,front_roof,roof)],glass_light)
 pane('Rear windshield',[
  (-roof_w,rear_roof,roof),(roof_w,rear_roof,roof),
  (half*.91,rear_window,belt),( -half*.91,rear_window,belt)],glass)
 for sign in (-1,1):
  # Side glazing is created as a child of each moving door hinge.
  # Never leave a flat window behind after someone opens the door.
  tube('Front A pillar',[(sign*half*.91,front_window,belt),
       (sign*roof_w,front_roof,roof)],.027,accent)
  tube('Rear C pillar',[(sign*roof_w,rear_roof,roof),
       (sign*half*.91,rear_window,belt)],.026,accent)
  if style not in (4,5,6):
   tube('B-pillar',[(sign*roof_w,(front_roof+rear_roof)*.47,roof),
      (sign*half*.91,(front_window+rear_window)*.47,belt)],.033,accent)
  box('Wing mirror in body paint',(sign*(half+.11),front_window+.12,belt+.015),
      (.20,.22,.085),paint,.034)
  box('Mirror glass inset',(sign*(half+.215),front_window+.12,belt+.016),
      (.014,.13,.052),glass,.005)
 # Fabricate all independently animated doors AFTER cabin dimensions exist.
 hinges=[]
 for side in (-1,1):
  for index,ya,yb in door_intervals:
   hinges.append(make_working_door(name,side,index,ya,yb,half,belt,roof,roof_w,
       front_window,rear_window,front_roof,rear_roof,paint,accent))
 assert len(hinges)==number_of_doors and len(set(hinges))==number_of_doors
 # seating visible through windows
 for i in (-1,1):
  box('Front contoured driver/passenger seats',
   (i*.26,front+L*.42,belt+.024),(.38,.31,.27),seat,.055)
 if style in (4,5,6):
  # Two separate visibly raised wheelbase length cargo-side bed walls.
  bed_front=rear_window+.12
  bed_len=max(.6,rear-bed_front-.08)
  bed_mid=(rear+bed_front)*.5
  box('Truck cargo bed floor',(0,bed_mid,belt-.30),(W*.83,bed_len,.10),trim,.028)
  for sign in (-1,1):
   box('Distinct pickup box sidewall',
       (sign*half*.89,bed_mid,belt+.04),
       (.15,bed_len,.51),paint,.04)
  box('Tailgate outer panel',(0,rear-.08,belt-.12),(W*.87,.15,.45),paint,.045)
  for i in range(5):
   box('Pickup cargo floor anti-slip bead',
       (-W*.33+W*.165*i,bed_mid,belt-.235),
       (.035,bed_len*.96,.026),accent,.012)
 if style==6:
  # separate angular tonneau cover over open bed, distinctive sloping wedge
  pane('Faceted EV armored tonneau cover',[
   (-half*.93,rear_window,belt+.20),(half*.93,rear_window,belt+.20),
   (half*.92,rear-.15,belt+.08),(-half*.92,rear-.15,belt+.08)],paint)
 elif style==3:
  tube('Retractable convertible roof seam',[
   (-roof_w,rear_roof,roof),(roof_w,rear_roof,roof)],.028,accent)
 # Performance/era-specific aero: wings are separate hardware.
 if car['spoiler']:
  for sign in (-1,1):
   box('Spoiler bracket',(sign*half*.53,rear-.27,belt+.15),
       (.09,.20,.39),accent,.012)
  box('Aerodynamic rear wing',(0,rear-.27,belt+.37),
      (W*.79,.29,.062),accent,.026)
 # Nose and rear differentiated by category + custom lamp split pattern
 box('Sculpted front intake / closed EV grille',(0,front-.03,.40),
     (W*.72,.063,.19),trim,.025)
 box('Lower front lip splitter',(0,front-.05,.24),
     (W*.88,.18,.07),accent,.02)
 box('Rear black diffuser',(0,rear+.02,.28),
     (W*.65,.11,.14),trim,.023)
 light_type=int(car['signature_light_style'])%3
 if light_type==2:
  box('Continuous futuristic headlamp bar',(0,front-.056,belt*.73),
      (W*.78,.055,.040),headlamp,.008)
 elif light_type==1:
  for sign in (-1,1):
   box('Segmented LED headlight', (sign*half*.71,front-.055,belt*.72),
       (W*.19,.05,.056),headlamp,.015)
   box('Vertical DRL signature',(sign*half*.79,front-.065,belt*.63),
       (.045,.045,.15),headlamp,.009)
 else:
  for sign in (-1,1):
   box('Warm luxury rectangular headlight', (sign*half*.68,front-.055,belt*.71),
       (W*.23,.05,.105),headlamp,.012)
 box('Rear continuous light signature',(0,rear+.055,belt*.70),
     (W*.82,.055,.055),tail_lamp,.012)
 for sign in (-1,1):
  box('Amber front side marker',(sign*half*.86,front+.17,belt*.54),
      (.045,.08,.055),turn_lamp,.010)
  box('Amber rear turn signal',(sign*half*.83,rear+.059,belt*.61),
      (.10,.050,.04),turn_lamp,.009)
 box('Front license mount',(0,front-.070,belt*.49),
     (.52,.029,.11),alloy,.012)
 box('Rear license mount',(0,rear+.070,belt*.47),
     (.52,.029,.11),alloy,.012)
 if whitecaps:
  for i in range(7):
   box('Flagship grille individual vertical blade',
       ((i-3)*W*.082,front-.063,belt*.49),
       (W*.013,.060,.22),alloy,.007)
 else:
  for i in range(5):
   box('Active lower intake dark slat',
       ((i-2)*W*.10,front-.073,belt*.41),
       (W*.053,.044,.015),accent,.003)
 # Tires+spokes mechanically match wheelbase (not toy disconnected wheels)
 for x in (-half*.98,half*.98):
  for yy_w in (front_ax,rear_ax):
   wheel(x,yy_w,wheel_radius,half,int(car['signature_light_style'])+(0 if x>0 else 2))
 # The detailing pass adds real geometry and parents chrome/body reveals to the
 # SAME moving hinges; this is not a material-only or screenshot-only upgrade.
 finishing=finish_car(car,length=L,width=W,height=H,half=half,
  front=front,rear=rear,belt=belt,roof=roof,front_window=front_window,
  rear_window=rear_window,roof_width=roof_w,front_axle=front_ax,
  rear_axle=rear_ax,wheel_radius=wheel_radius,hinges=hinges,paint=paint,
  accent=accent,alloy=alloy,trim=trim,glass=glass,dark=dark,
  headlamp=headlamp,tail_lamp=tail_lamp,box=box,tube=tube,disk=disk,geom=geom)
 # Rigid door-kinematics adversarial proof: opening pivots must move panel vertices.
 for node_name in hinges:
  h=bpy.data.objects[node_name]
  children=[o for o in h.children if o.type=='MESH']
  if len(children)<4:raise ValueError(name+' door has too few movable pieces '+node_name)
  # The first vertex of a sculpted skin is next to the hinge, so it can
  # barely move even when the opposite door edge opens fully. Check ALL
  # actual moving mesh corners and require an outer-edge displacement.
  reference_points=[(child,tuple(v.co)) for child in children
                    for v in child.data.vertices]
  before=[obj.matrix_world @ Vector(co) for obj,co in reference_points]
  original=h.rotation_euler.z
  h.rotation_euler.z+=math.radians(h.get('door_open_degrees',0))
  bpy.context.view_layer.update()
  after=[obj.matrix_world @ Vector(co) for obj,co in reference_points]
  actual_delta=max((post-pre).length for pre,post in zip(before,after))
  if actual_delta<.13:raise ValueError(name+' door outer edge does not physically articulate '+node_name+' '+str(actual_delta))
  h.rotation_euler.z=original
  bpy.context.view_layer.update()
 # Geometry quality metrics — used as build gate, not visual proof.
 total_meshes=len([o for o in bpy.data.objects if o.type=='MESH'])
 triangles=sum(len(p.vertices)-2 for o in bpy.data.objects if o.type=='MESH' for p in o.data.polygons)
 if total_meshes<55:raise ValueError('Vehicle too primitive '+name+' '+str(total_meshes))
 if triangles>45000:raise ValueError('Unbudgeted Android vehicle '+name)
 file=CAR_DIR/(name+'.glb')
 bpy.ops.object.select_all(action='SELECT')
 bpy.ops.export_scene.gltf(filepath=str(file),export_format='GLB',
                             use_selection=True,export_materials='EXPORT',export_apply=True)
 if file.stat().st_size<14000:raise ValueError('Tiny GLB '+str(file))
 return {'id':name,'category':category,'meshes':total_meshes,'triangles':triangles,
   'bytes':file.stat().st_size,'wheelbase':car['wheelbase_ratio'],
   'length_m':L,'width_m':W,'height_m':H,
   'wheel_arches_cut':True,'separate_glass_panes':True,
   'open_truck_bed':style in (4,5),
   'functional_door_hinges':hinges,'door_count':len(hinges),
   'angular_future_electric':style==6,'paint_material':'FF_BODY_PAINT',
   'paint_options':len(car['colors']),'cost':car['game_price'],
   'finish_detail_version':finishing['detail_version'],
   'finish_meshes':finishing['finish_meshes'],
   'movable_trim_parts':finishing['movable_trim_parts'],
   'finish_features':finishing['features'],
   'photo_profile_reference':PHOTO_PROFILES.get(name,{}).get('photo_source',''),
   'photo_traced_body_prototype':name in PHOTO_PROFILES}
selected_ids=[v.strip() for v in os.environ.get('FF_CAR_IDS','').split(',') if v.strip()]
if selected_ids:
 assert len(selected_ids)==len(set(selected_ids))
 assert all(any(x['id']==n for x in models) for n in selected_ids)
 selected_models=[next(x for x in models if x['id']==n) for n in selected_ids]
else:
 selected_models=models[:int(os.environ.get('FF_CAR_LIMIT',str(len(models))))]
lim=len(selected_models)
results=[]
for idx,rec in enumerate(selected_models):
 data=build_car(rec);results.append(data)
 print('FLEET 3D',idx+1,lim,rec['id'],data['triangles'],'triangles',flush=True)
summary={'count':len(results),'available_paints':8,'vehicles':results}
(CAR_DIR/'fleet_metrics.json').write_text(json.dumps(summary,indent=2))
if lim==59:
 assert len({r['category'] for r in results})==12
 assert all(r['meshes']>=55 and r['paint_options']>=8 for r in results)
 assert all(r['door_count'] in (2,4) for r in results)
 assert sum(r['door_count'] for r in results)>=178
 assert sum(r['open_truck_bed'] for r in results)==10
 assert sum(r['angular_future_electric'] for r in results)==1
 print('PREMIUM FLEET GEOMETRY GAUNTLET GREEN: 59 distinct authored GLBs / 472 playable colorways; rejected REVULSE excluded',flush=True)
else:
 print('PROTOTYPE ONLY — NOT FULL FLEET APPROVAL',len(results),flush=True)
