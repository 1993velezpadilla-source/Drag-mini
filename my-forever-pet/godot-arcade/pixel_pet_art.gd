extends RefCounted
# Original pixel artwork with stable companion identity; no full-scene pixelation.
static var cache:Dictionary={}
const Parts=preload("res://pet_part_rig.gd")
const ExternalFx=preload("res://pet_external_fx.gd")
# Editable skin contract: four direction rows, ten pose columns, 48px cells.
const SKIN_PATH="res://assets/mosky/sprites.png"
const CELL=48
const POSE_COLUMNS=10
static var skin_image:Image
static var skin_checked=false
static func ellipse(im:Image,center:Vector2,radii:Vector2,c:Color)->void:
	for y in range(maxi(0,int(center.y-radii.y)),mini(im.get_height(),int(center.y+radii.y)+1)):
		for x in range(maxi(0,int(center.x-radii.x)),mini(im.get_width(),int(center.x+radii.x)+1)):
			if ((Vector2(x,y)-center)/radii).length_squared()<=1.0: im.set_pixel(x,y,c)

static func mosskit(pose:String,step:int=0,mood:String="healthy")->Image:
	var im:=Image.create(48,48,false,Image.FORMAT_RGBA8)
	im.fill(Color.TRANSPARENT)
	var ink:=Color("#25421c")
	var deep:=Color("#478d27")
	var leaf:=Color("#76c438")
	var high:=Color("#a7e657")
	var pink:=Color("#f49ac2")
	var eye:=Color("#241c43")
	for side in [-1,1]:
		var foot:=Vector2(24+side*10,41+step*side)
		ellipse(im,foot,Vector2(9,5),ink)
		ellipse(im,foot+Vector2(0,-1),Vector2(7,3),deep)
		ellipse(im,foot+Vector2(-1,-2),Vector2(5,2),leaf)
		var droop:bool=mood in ["sad","weak","sick"]
		var ear:=Vector2(24+side*(15 if droop else 12),15 if droop else 10+step*side/2.0)
		ellipse(im,ear,Vector2(8,5) if droop else Vector2(6,9),ink)
		ellipse(im,ear,Vector2(6,4) if droop else Vector2(4,7),leaf)
		ellipse(im,ear+Vector2(0,1),Vector2(4,2) if droop else Vector2(3,5),pink)
	ellipse(im,Vector2(24,9),Vector2(4,6),ink)
	ellipse(im,Vector2(24,8),Vector2(2,4),high)
	ellipse(im,Vector2(24,26),Vector2(19,16),ink)
	ellipse(im,Vector2(24,26),Vector2(17,14),deep)
	ellipse(im,Vector2(23,23),Vector2(16,12),leaf)
	ellipse(im,Vector2(18,16),Vector2(8,3),high)
	for side in [-1,1]:
		var p:=Vector2(24+side*9,25)
		if pose in ["sleep","blink"] or mood in ["weak","sick"]:
			# Closed eyelid: small hand-placed stepped line.
			for x in range(-4,5):
				var y:int=1-absi(x)/3 if pose=="sleep" else 0
				im.set_pixel(int(p.x)+x,int(p.y)+int(y),eye)
		else:
			ellipse(im,p,Vector2(5,7),eye)
			ellipse(im,p+Vector2(-1,-3),Vector2(2,2),Color("#fff3ef"))
			im.set_pixel(int(p.x)+2,int(p.y)+4,Color("#655b9a"))
		ellipse(im,Vector2(24+side*13,32),Vector2(3,2),pink)
	if mood in ["sad","weak","sick"] and pose=="idle":
		for x in range(-4,5):
			im.set_pixel(24+x,34+absi(x)/2,eye)
	else:
		ellipse(im,Vector2(24,34),Vector2(4,3 if pose!="eat" else 4),eye)
		ellipse(im,Vector2(24,35),Vector2(2,1),pink)
	return im

static func mosskit_back(step:int,mood:String="healthy")->Image:
	var img:=Image.create(48,48,false,Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var outline:=Color("#24421d")
	var shade:=Color("#4b912d")
	var mid:=Color("#78c83d")
	var light:=Color("#a4e85b")
	for side in [-1,1]:
		var foot_y:=41.0+float(step*side)
		var foot:=Vector2(24+side*10,foot_y)
		ellipse(img,foot,Vector2(8,5),outline)
		ellipse(img,foot+Vector2(0,-1),Vector2(6,3),shade)
		ellipse(img,foot+Vector2(-1,-2),Vector2(4,2),mid)
		var droop:bool=mood in ["sad","weak","sick"]
		var ear:=Vector2(24+side*(15 if droop else 12),16 if droop else 11)
		ellipse(img,ear,Vector2(8,5) if droop else Vector2(6,10),outline)
		ellipse(img,ear+Vector2(0,-1),Vector2(6,3) if droop else Vector2(4,8),mid)
		ellipse(img,ear+Vector2(-1,-3),Vector2(3,1) if droop else Vector2(2,4),light)
	ellipse(img,Vector2(24,10),Vector2(5,6),outline)
	ellipse(img,Vector2(24,9),Vector2(3,4),light)
	ellipse(img,Vector2(24,26),Vector2(19,17),outline)
	ellipse(img,Vector2(24,26),Vector2(17,15),shade)
	ellipse(img,Vector2(23,23),Vector2(16,13),mid)
	ellipse(img,Vector2(18,17),Vector2(9,4),light)
	for side in [-1,1]:
		ellipse(img,Vector2(24+side*11,23),Vector2(4,4),shade)
		ellipse(img,Vector2(23+side*11,22),Vector2(3,3),light)
	var tail_y:float=40.0 if mood in ["sad","weak","sick"] else 35.0 if mood=="happy" else 36.0
	ellipse(img,Vector2(24,tail_y),Vector2(6,4) if tail_y==40.0 else Vector2(6,6),outline)
	ellipse(img,Vector2(24,tail_y-1),Vector2(5,3) if tail_y==40.0 else Vector2(5,5),shade)
	ellipse(img,Vector2(23,tail_y-2),Vector2(3,2) if tail_y==40.0 else Vector2(3,3),light)
	return img


static func source_image(path:String)->Image:
	if path=="res://assets/pet_rear_0.png": return skin_cell(1,"idle",0)
	if path=="res://assets/pet_0.png": return skin_cell(0,"idle",0)
	if path=="res://assets/pet_sleep_0.png": return skin_cell(0,"sleep",0)
	if not ResourceLoader.exists(path): return null
	var src:=load(path) as Texture2D
	if src==null: return null
	var im:=src.get_image()
	if im==null or im.is_empty(): return null
	if im.is_compressed() and im.decompress()!=OK: return null
	im.convert(Image.FORMAT_RGBA8)
	im.resize(64,64,Image.INTERPOLATE_LANCZOS)
	for y in range(64):
		for x in range(64):
			var c:=im.get_pixel(x,y)
			if c.a<0.5: c=Color.TRANSPARENT
			else: c=Color(roundf(c.r*15.0)/15.0,roundf(c.g*15.0)/15.0,roundf(c.b*15.0)/15.0,1.0)
			im.set_pixel(x,y,c)
	return im

static func portrait(path:String,trim:bool=false,pose:String="")->Texture2D:
	var key:=path+":"+str(trim)+":"+pose
	if cache.has(key): return cache[key] as Texture2D
	var im:Image=skin_cell(0,pose,0) if not pose.is_empty() and path=="res://assets/pet_0.png" else source_image(path)
	if im==null: return null
	if trim:
		var bounds:=im.get_used_rect()
		if bounds.has_area(): im=im.get_region(bounds)
	var tex:=ImageTexture.create_from_image(im)
	cache[key]=tex
	return tex

# Directional 48x48 sprite atlas. All frames keep one canvas and ground anchor.
# The rear is the original Pet Dash drawing; front and profile use the same palette.
static func mosskit_side(step:int,blink:bool=false,attack:bool=false,mood:String="healthy")->Image:
	var im:=Image.create(48,48,false,Image.FORMAT_RGBA8)
	im.fill(Color.TRANSPARENT)
	var ink:=Color("#25421c")
	var deep:=Color("#478d27")
	var leaf:=Color("#76c438")
	var high:=Color("#a7e657")
	var pink:=Color("#f49ac2")
	var eye:=Color("#241c43")
	# Far ear and far foot, then body, near ear, cheek and snout.
	ellipse(im,Vector2(27,11-step*.5),Vector2(5,9),ink)
	ellipse(im,Vector2(27,11-step*.5),Vector2(3,7),deep)
	ellipse(im,Vector2(18+step,41-step),Vector2(8,4),ink)
	ellipse(im,Vector2(18+step,40-step),Vector2(6,3),deep)
	var tail_y:float=39.0 if mood in ["sad","weak","sick"] else 31.0 if mood=="happy" else 33.0
	ellipse(im,Vector2(10,tail_y),Vector2(6,6),ink)
	ellipse(im,Vector2(10,tail_y-1),Vector2(4,4),leaf)
	ellipse(im,Vector2(23,9),Vector2(4,6),ink)
	ellipse(im,Vector2(23,8),Vector2(2,4),high)
	ellipse(im,Vector2(24,26),Vector2(17,16),ink)
	ellipse(im,Vector2(24,26),Vector2(15,14),deep)
	ellipse(im,Vector2(24,23),Vector2(14,12),leaf)
	ellipse(im,Vector2(20,17),Vector2(8,3),high)
	var droop:bool=mood in ["sad","weak","sick"]
	var ear:=Vector2(15,16) if droop else Vector2(19,10+step*.5)
	ellipse(im,ear,Vector2(8,5) if droop else Vector2(6,9),ink)
	ellipse(im,ear,Vector2(6,3) if droop else Vector2(4,7),leaf)
	ellipse(im,ear+Vector2(1,0),Vector2(4,2) if droop else Vector2(2,5),pink)
	ellipse(im,Vector2(28-step,42+step),Vector2(8,4),ink)
	ellipse(im,Vector2(28-step,41+step),Vector2(6,3),deep)
	ellipse(im,Vector2(27-step,40+step),Vector2(4,2),leaf)
	if blink or mood in ["weak","sick"]:
		for x in range(28,36):im.set_pixel(x,25,eye)
	else:
		ellipse(im,Vector2(32,24),Vector2(5,7),eye)
		ellipse(im,Vector2(33,21),Vector2(2,2),Color("#fff3ef"))
	ellipse(im,Vector2(32,32),Vector2(3,2),pink)
	ellipse(im,Vector2(39,31),Vector2(3,3 if attack else 2),eye)
	if attack:ellipse(im,Vector2(39,32),Vector2(1,1),pink)
	return im

static func direction_for(delta:Vector2,previous:int=0)->int:
	# Screen/world axes: +X right, +Y/+Z down (toward camera).
	if delta.length_squared()<0.00000001:return previous
	if absf(delta.x)>absf(delta.y):return 3 if delta.x>0 else 2
	return 0 if delta.y>0 else 1

# Animation logic is independent from character art. An artist can replace one
# lossless PNG, without modifying movement, combat, navigation or camera code.
static func pose_column(pose:String,frame:int)->int:
	match pose:
		"walk","burst":return 1+posmod(frame,4)
		"attack":return 5+posmod(frame,2)
		"blink":return 7
		"sleep":return 8
		"eat":return 9
	return 0

static func authored_cell(dir:int,pose:String,frame:int,mood:String="healthy")->Image:
	var stride:int=0
	if pose in ["walk","burst"]:stride=[0,2,0,-2][posmod(frame,4)]
	elif pose=="attack":stride=2 if frame%2==0 else -2
	var im:Image
	match dir:
		1:im=mosskit_back(stride,mood)
		2,3:
			im=mosskit_side(stride,pose in ["blink","sleep"],pose in ["attack","eat"],mood)
			if dir==2:im.flip_x()
		_:im=mosskit("sleep" if pose=="sleep" else "blink" if pose=="blink" else "eat" if pose in ["attack","eat"] else "idle",stride,mood)
	return im

static func skin_cell(dir:int,pose:String,frame:int)->Image:
	if not skin_checked:
		skin_checked=true
		if ResourceLoader.exists(SKIN_PATH):
			var tex:=load(SKIN_PATH) as Texture2D
			if tex!=null:
				var candidate:=tex.get_image()
				if candidate!=null and (not candidate.is_compressed() or candidate.decompress()==OK) and candidate.get_size()==Vector2i(CELL*POSE_COLUMNS,CELL*4):
					skin_image=candidate
	if skin_image!=null:
		return skin_image.get_region(Rect2i(pose_column(pose,frame)*CELL,clampi(dir,0,3)*CELL,CELL,CELL))
	return authored_cell(dir,pose,frame)

static func editable_atlas()->Image:
	var sheet:=Image.create(CELL*POSE_COLUMNS,CELL*4,false,Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	var poses=["idle","walk","walk","walk","walk","attack","attack","blink","sleep","eat"]
	var frames=[0,0,1,2,3,0,1,0,0,0]
	for dir in range(4):
		for column in range(POSE_COLUMNS):
			var cell:=skin_cell(dir,poses[column],frames[column])
			sheet.blit_rect(cell,Rect2i(0,0,CELL,CELL),Vector2i(column*CELL,dir*CELL))
	return sheet

static func adventure_frame(dir:int,pose:String,frame:int=0,mood:String="healthy")->Texture2D:
	var key:="adventure:%d:%s:%d:%s"%[dir,pose,frame,mood]
	if cache.has(key):return cache[key] as Texture2D
	var original:=skin_cell(dir,pose,frame)
	if skin_image==null and mood!="healthy":original=authored_cell(dir,pose,frame,mood)
	var tex:=ImageTexture.create_from_image(original)
	cache[key]=tex
	return tex

static func frame_for(dir:int,pose:String,clock:float,mood:String="healthy")->Texture2D:
	var frame:int=posmod(int(floor(clock*(14.0 if pose=="burst" else 10.0))),4) if pose in ["walk","burst"] else posmod(int(floor(clock*14.0)),2) if pose=="attack" else 0
	var actual:String="blink" if pose=="idle" and fposmod(clock,3.8)>3.62 else pose
	return adventure_frame(dir,actual,frame,mood)

static func world_sprite(parent:Node3D,id:int,height:float=1.65)->Sprite3D:
	# Single live companion; no runtime GLB fallback or retired species.
	var sprite:=Sprite3D.new()
	sprite.name="PixelCompanion"
	sprite.texture=adventure_frame(0,"idle")
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded=false
	sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.position.y=height*.5
	sprite.pixel_size=height/48.0
	sprite.set_meta("world_height",height)
	sprite.set_meta("facing",0)
	sprite.set_meta("anim_clock",0.0)
	sprite.set_meta("anim_state","idle")
	parent.add_child(sprite)
	return sprite

static func animate_world_sprite(actor:Node3D,delta:Vector2,moving:bool,dt:float,pose:String="idle",water:bool=false)->void:
	if not is_instance_valid(actor):return
	var sprite:=actor.get_node_or_null("PixelCompanion") as Sprite3D
	if sprite==null:return
	var dir:int=direction_for(delta,int(sprite.get_meta("facing",0)))
	var state:String=pose if pose!="idle" else "walk" if moving else "idle"
	var clock:float=float(sprite.get_meta("anim_clock",0.0))
	if state!=str(sprite.get_meta("anim_state","idle")) or dir!=int(sprite.get_meta("facing",0)):clock=0.0
	clock+=maxf(0.0,dt)
	sprite.set_meta("facing",dir)
	sprite.set_meta("anim_clock",clock)
	sprite.set_meta("anim_state",state)
	var mood:String=str(actor.get_meta("pet_mood","healthy"))
	var tex:=frame_for(dir,state,clock,mood)
	ExternalFx.world_effect(actor,"heart-pickup",clock,state=="reward",float(sprite.get_meta("world_height"))*.75)
	if sprite.texture!=tex:sprite.texture=tex
	# Grounded squash/stretch with continuous, not teleporting, motion.
	var cycle:float=sin(clock*TAU*(5.0 if state=="burst" else 3.5))
	var stretch:float=1.0+cycle*.045 if moving else 1.0+sin(clock*2.5)*.018
	var lift:float=absf(cycle)*(.13 if state=="burst" else .075) if moving else .012*sin(clock*2.5)
	if water:lift+=.045+.025*sin(clock*5.0)
	if state=="reward":lift+=absf(sin(clock*TAU*2.0))*.15
	if state=="attack":stretch=1.0+.11*sin(clock*TAU*3.0)
	if state=="hurt":stretch=.88+.06*sin(clock*35.0)
	var height:float=float(sprite.get_meta("world_height"))
	sprite.scale=Vector3(1.0/stretch,stretch,1.0)
	sprite.position.y=height*.5*stretch+lift
	sprite.modulate=Color("#ff9b9b") if state=="hurt" and int(clock*22.0)%2==0 else Color("#d3fff1") if state=="burst" else Color.WHITE

# Volnox enemies are authored 2D pixels, never rendered 3D creature meshes.
const ENEMY_PIXEL_PILOTS=["sporeling","coralcrab","nova_wisp","vinesnap","eelstrix","comet_hare","thornbeetle","marrowray","voidspider","rootgnawer","jellymancer","lunamoth","leafwisp","shellguard","crystarok","bramble_pup","anemoneye","nebulwing"]
const ENEMY_POSES=["idle","walk","walk","walk","walk","windup","attack","attack","recover","hurt","defeat"]
static func enemy_dot(im:Image,p:Vector2i,r:Vector2i,c:Color)->void:
	ellipse(im,Vector2(p),Vector2(r),c)
static func enemy_line(im:Image,a:Vector2i,b:Vector2i,width:int,c:Color)->void:
	var steps:=maxi(absi(b.x-a.x),absi(b.y-a.y))
	for i in range(steps+1):
		var q:=Vector2i(Vector2(a).lerp(Vector2(b),float(i)/maxi(1,steps)).round())
		enemy_dot(im,q,Vector2i(width,width),c)
# Integer-grid filled polygons allow faceted material clusters rather than circles alone.
static func enemy_poly(im:Image,points:Array,c:Color)->void:
	var polygon:=PackedVector2Array()
	for point in points:polygon.append(Vector2(point))
	for y in range(48):
		for x in range(48):
			if Geometry2D.is_point_in_polygon(Vector2(x+.5,y+.5),polygon):im.set_pixel(x,y,c)
static func enemy_patch(im:Image,origin:Vector2i,points:Array,c:Color)->void:
	var shifted:Array=[]
	for point in points:shifted.append(origin+Vector2i(point))
	enemy_poly(im,shifted,c)
# Authored clusters at native resolution. The near/far layers are explicit.
static func enemy_cluster(im:Image,o:Vector2i,outline:Array,body:Array,highlight:Array,ink:Color,base:Color,lit:Color)->void:
	enemy_patch(im,o,outline,ink)
	enemy_patch(im,o,body,base)
	enemy_patch(im,o,highlight,lit)
static func enemy_eye(im:Image,o:Vector2i,ink:Color,iris:Color,shine:Color,angry:bool=false)->void:
	enemy_dot(im,o,Vector2i(3,4),ink)
	enemy_dot(im,o+Vector2i(0,1),Vector2i(2,2),iris)
	im.set_pixelv(o+Vector2i(-1,-1),shine)
	if angry:enemy_line(im,o+Vector2i(-2,-3),o+Vector2i(2,-1),1,ink)
static func enemy_pincer(im:Image,shoulder:Vector2i,palm:Vector2i,forward:Vector2i,pinch:int,ink:Color,shade:Color,purple:Color,brass_dark:Color,gold:Color)->void:
	var lateral:=Vector2i(-forward.y,forward.x)
	enemy_line(im,shoulder,palm,3,ink)
	enemy_line(im,shoulder,palm,2,shade)
	enemy_dot(im,palm,Vector2i(6,5) if forward.x!=0 else Vector2i(5,6),ink)
	enemy_dot(im,palm,Vector2i(4,4),purple)
	enemy_line(im,palm-forward*2-lateral*3,palm-forward*2+lateral*3,1,gold)
	for k in [-1,1]:
		var start:=palm+forward*2+lateral*int(k)*3
		var bend:=palm+forward*5+lateral*int(k)*maxi(1,3+int(pinch/2.0))
		var tip:=palm+forward*7+lateral*int(k)*maxi(0,pinch)
		enemy_line(im,start,bend,2,ink)
		enemy_line(im,bend,tip,2,ink)
		enemy_line(im,start,bend,1,brass_dark)
		enemy_line(im,bend,tip,1,gold)
static func enemy_pixel_cell(id:String,dir:int,pose:String,frame:int=0)->Image:
	var im:=Image.create(48,48,false,Image.FORMAT_RGBA8)
	im.fill(Color.TRANSPARENT)
	var ink:=Color("#21152e")
	var purple:=Color("#69329b")
	var bright:=Color("#a952db")
	var gold:=Color("#e0a34c")
	var pink:=Color("#f78dda")
	var white:=Color("#ffe5f7")
	var phase:=posmod(frame,4)
	var step:int=[0,2,0,-2][phase] if pose=="walk" else 0
	var wind:=pose=="windup"
	var attack:=pose=="attack"
	var recoil:=pose=="hurt"
	var back:=dir==1
	var side:=dir>=2
	var fx:=3 if side else 0
	match id:
		"sporeling":
			# A timid fungal courier: short root feet, scalloped cap, gill scarf and expressive eyes.
			var bark:=Color("#493b27")
			var moss:=Color("#64783a")
			var shadow:=Color("#46532f")
			var leaf:=Color("#97b65a")
			var shine:=Color("#c3d38a")
			var flesh:=Color("#c2a38b")
			var cream:=Color("#f2d6a0")
			var cx:int=22 if side else 24
			var cap_y:int=18+(3 if wind else -2 if attack else 1 if recoil else 0)
			var tilt:int=2 if side else 0
			var fallen:bool=pose=="defeat"
			if fallen:cap_y=28
			for k in [-1,1]:
				var x:int=cx+int(k)*6+(2 if side else 0)
				var y:int=40+step*int(k)
				var foot:=Vector2i(x,y)
				enemy_patch(im,foot,[Vector2i(-5,-2),Vector2i(-3,-5),Vector2i(3,-5),Vector2i(5,0),Vector2i(3,3),Vector2i(-4,3)],ink)
				enemy_patch(im,foot,[Vector2i(-3,-2),Vector2i(2,-3),Vector2i(3,1),Vector2i(-3,1)],shadow)
				enemy_line(im,foot+Vector2i(-2,-2),foot+Vector2i(1,-2),1,moss)
			var body:=Vector2i(cx,32)
			enemy_patch(im,body,[Vector2i(-10,-6),Vector2i(-7,-12),Vector2i(7,-12),Vector2i(10,-5),Vector2i(9,7),Vector2i(4,10),Vector2i(-6,10),Vector2i(-10,5)],ink)
			enemy_patch(im,body,[Vector2i(-8,-5),Vector2i(-5,-10),Vector2i(5,-10),Vector2i(8,-4),Vector2i(7,6),Vector2i(3,8),Vector2i(-5,8),Vector2i(-8,4)],flesh)
			enemy_patch(im,body,[Vector2i(-7,-3),Vector2i(-3,-7),Vector2i(0,5),Vector2i(-4,7),Vector2i(-7,3)],cream)
			for k in [-1,1]:
				var arm:=body+Vector2i(int(k)*9,2+step*int(k))
				enemy_line(im,body+Vector2i(int(k)*6,-1),arm,2,ink)
				enemy_dot(im,arm,Vector2i(2,3),shadow)
				enemy_line(im,arm+Vector2i(-1,-1),arm+Vector2i(1,-1),1,leaf)
			var cap:=Vector2i(cx+tilt,cap_y)
			enemy_patch(im,cap,[Vector2i(-20,5),Vector2i(-19,-2),Vector2i(-15,-10),Vector2i(-8,-14),Vector2i(5,-14),Vector2i(13,-11),Vector2i(18,-5),Vector2i(20,3),Vector2i(17,9),Vector2i(8,11),Vector2i(-9,10),Vector2i(-17,8)],ink)
			enemy_patch(im,cap,[Vector2i(-18,4),Vector2i(-17,-2),Vector2i(-13,-9),Vector2i(-7,-12),Vector2i(5,-12),Vector2i(12,-9),Vector2i(16,-4),Vector2i(18,3),Vector2i(15,7),Vector2i(7,9),Vector2i(-9,8),Vector2i(-15,6)],moss)
			enemy_patch(im,cap,[Vector2i(-16,-1),Vector2i(-12,-8),Vector2i(-6,-11),Vector2i(4,-11),Vector2i(11,-8),Vector2i(8,-4),Vector2i(-4,-2),Vector2i(-12,2)],leaf)
			enemy_patch(im,cap,[Vector2i(8,-4),Vector2i(13,-8),Vector2i(16,-2),Vector2i(18,3),Vector2i(14,6),Vector2i(5,6)],shadow)
			enemy_line(im,cap+Vector2i(-10,-8),cap+Vector2i(-4,-10),1,shine)
			for spot in [Vector2i(-11,-4),Vector2i(1,-8),Vector2i(11,0)]:
				var q:Vector2i=cap+spot
				enemy_patch(im,q,[Vector2i(-3,0),Vector2i(-1,-3),Vector2i(2,-2),Vector2i(3,1),Vector2i(0,2)],cream)
				im.set_pixel(q.x,q.y-1,white)
			enemy_patch(im,cap,[Vector2i(-18,5),Vector2i(-9,7),Vector2i(0,8),Vector2i(9,7),Vector2i(18,4),Vector2i(15,8),Vector2i(7,11),Vector2i(-9,10),Vector2i(-16,8)],bark)
			for i in range(7):
				var q:=cap+Vector2i(-14+i*4,7)
				enemy_line(im,q,q+Vector2i(1,2),1,flesh)
			enemy_line(im,cap+Vector2i(-14,5),cap+Vector2i(0,7),1,gold)
			enemy_line(im,cap+Vector2i(0,7),cap+Vector2i(14,5),1,gold)
			if not back and not fallen:
				for x in ([5] if side else [-5,5]):
					var eye:=body+Vector2i(int(x),-1)
					enemy_dot(im,eye,Vector2i(4,5),ink)
					if wind:
						enemy_line(im,eye+Vector2i(-2,0),eye+Vector2i(2,0),1,pink)
					else:
						enemy_dot(im,eye,Vector2i(2,3),Color("#ab6fd0"))
						im.set_pixel(eye.x-1,eye.y-2,white)
						im.set_pixel(eye.x+1,eye.y+1,pink)
				enemy_dot(im,body+Vector2i(3 if side else 0,6),Vector2i(2,2) if attack else Vector2i(2,1),bark)
			elif back and not fallen:
				enemy_line(im,body+Vector2i(0,-3),body+Vector2i(0,7),1,bark)
			if attack:
				var out:=Vector2i(40,28) if side else Vector2i(24,8 if back else 44)
				for i in range(3):
					var q:=out+Vector2i(-3+i*3,-2+i%2*3-frame)
					enemy_dot(im,q,Vector2i(1,1),cream)
		"coralcrab":
			# Four projected anatomies, not a face pasted on the front silhouette.
			var coral:=Color("#bf655f")
			var coral_hi:=Color("#ffc49b")
			var shade:=Color("#193e50")
			var reef_mid:=Color("#30888c")
			var reef_hi:=Color("#6bc7bf")
			var brass_dark:=Color("#935522")
			var shell_center:=Vector2i(19,25) if side else Vector2i(24,25)
			var pinch:int=3 if attack and frame==0 else -2 if attack else 4 if wind else 1
			if side:
				# Far legs, far claw; shell occludes the far shoulder.
				for i in range(3):
					var hip:=Vector2i(10+i*7,27)
					var knee:=Vector2i(7+i*8,33+step*(-1 if i%2==0 else 1))
					var foot:=knee+Vector2i(-2,7)
					enemy_line(im,hip,knee,2,ink)
					enemy_line(im,knee,foot,2,ink)
					enemy_line(im,hip,knee,1,shade)
				enemy_pincer(im,Vector2i(26,22),Vector2i(36,23),Vector2i(1,0),pinch,ink,shade,coral,brass_dark,gold)
			else:
				for k in [-1,1]:
					for i in range(3):
						var hip:=Vector2i(24+int(k)*10,25+i*4)
						var knee:=Vector2i(24+int(k)*(14+i%2),30+i*4)
						var foot:=Vector2i(24+int(k)*(20-i),34+i*4+step*(-1 if (i+int(k))%2==0 else 1))
						enemy_line(im,hip,knee,2,ink)
						enemy_line(im,knee,foot,2,ink)
						enemy_line(im,hip,knee,1,coral)
						enemy_line(im,knee,foot,1,shade)
				if back:
					for k in [-1,1]:
						enemy_pincer(im,Vector2i(24+int(k)*10,23),Vector2i(24+int(k)*15,15),Vector2i(0,-1),pinch,ink,shade,coral,brass_dark,gold)
			enemy_dot(im,shell_center,Vector2i(14,12),ink)
			enemy_dot(im,shell_center+Vector2i(0,-1),Vector2i(12,10),shade)
			enemy_dot(im,shell_center+Vector2i(0,-3),Vector2i(11,8),reef_mid)
			enemy_dot(im,shell_center+Vector2i(-3,-6),Vector2i(7,3),reef_hi)
			# Angular gold crown-shaped shell seam and coral branches.
			for k in [-1,1]:
				var branch:=shell_center+Vector2i(int(k)*6,-7)
				enemy_line(im,branch,branch+Vector2i(int(k)*2,-8),2,ink)
				enemy_line(im,branch,branch+Vector2i(int(k)*2,-8),1,coral)
				enemy_line(im,branch+Vector2i(int(k),-4),branch+Vector2i(int(k)*5,-7),1,coral_hi)
				enemy_dot(im,branch+Vector2i(int(k)*2,-8),Vector2i(2,1),coral_hi)
			enemy_dot(im,shell_center+Vector2i(-5,-2),Vector2i(3,2),Color("#e0dbc0"))
			enemy_dot(im,shell_center+Vector2i(4,-3),Vector2i(2,2),Color("#91dfcf"))
			enemy_line(im,shell_center+Vector2i(-10,0),shell_center+Vector2i(-5,4),1,brass_dark)
			enemy_line(im,shell_center+Vector2i(-5,4),shell_center+Vector2i(5,4),2,purple)
			enemy_line(im,shell_center+Vector2i(5,4),shell_center+Vector2i(10,0),1,gold)
			if side:
				# The head and BOTH claws point right; left mirrors the full anatomy.
				enemy_dot(im,Vector2i(28,27),Vector2i(5,5),ink)
				enemy_dot(im,Vector2i(30,26),Vector2i(2,2),pink)
				im.set_pixel(31,25,white)
				for i in range(3):
					var hip:=Vector2i(12+i*7,31)
					var knee:=Vector2i(9+i*8,37+step*(-1 if i%2==0 else 1))
					var foot:=knee+Vector2i(-2,5)
					enemy_line(im,hip,knee,2,ink)
					enemy_line(im,knee,foot,2,ink)
					enemy_line(im,hip,knee,1,coral)
					enemy_line(im,knee,foot,1,coral_hi)
				enemy_pincer(im,Vector2i(24,31),Vector2i(36+(2 if attack else 0),34),Vector2i(1,0),pinch,ink,shade,coral,brass_dark,gold)
			elif not back:
				for x in [19,29]:
					enemy_dot(im,Vector2i(x,30),Vector2i(4,4),ink)
					enemy_line(im,Vector2i(x-1,29),Vector2i(x+1,30),1,pink)
				# Foreground claws overlay the shell and occupy the forward half.
				for k in [-1,1]:
					enemy_pincer(im,Vector2i(24+int(k)*9,30),Vector2i(24+int(k)*14,36+(2 if attack else 0)),Vector2i(0,1),pinch,ink,shade,coral,brass_dark,gold)
			else:
				enemy_line(im,Vector2i(24,17),Vector2i(24,31),1,bright)
				for y in [21,25,29]:
					enemy_line(im,Vector2i(17,y),Vector2i(31,y),1,shade)
		"nova_wisp":
			var cy:=24+(step if pose=="walk" else 0)
			enemy_dot(im,Vector2i(24,cy),Vector2i(11,11),ink)
			enemy_dot(im,Vector2i(24,cy),Vector2i(9,9),Color("#34376e"))
			enemy_dot(im,Vector2i(21,cy-4),Vector2i(5,3),Color("#8997e8"))
			enemy_line(im,Vector2i(14,cy-1),Vector2i(20,cy-9),1,Color("#c5d8ff"))
			enemy_line(im,Vector2i(27,cy+8),Vector2i(33,cy+3),1,Color("#242352"))
			for j in range(3):
				var offset:=Vector2i(j*3-3,-12-j%2*2)
				enemy_line(im,Vector2i(24,cy)+offset,Vector2i(24,cy)+offset+Vector2i(0,3),1,gold)
			var orbit:float=float(phase)*PI*.5 if pose=="walk" else float(frame)*.8 if attack else .2
			for i in range(3):
				var a:=orbit+float(i)*TAU/3.0
				var r:=17.0 if attack else 12.0 if wind else 15.0
				var q:=Vector2i(24+roundi(cos(a)*r),cy+roundi(sin(a)*r*.55))
				enemy_line(im,q+Vector2i(0,-4),q+Vector2i(0,4),1,gold)
				enemy_line(im,q+Vector2i(-3,0),q+Vector2i(3,0),1,gold)
				enemy_dot(im,q,Vector2i(2,2),Color("#b9d7ff"))
				im.set_pixel(q.x,q.y,white)
			if not back:
				for x in ([28] if side else [20,28]):
					enemy_dot(im,Vector2i(x,cy),Vector2i(3,4),ink)
					enemy_dot(im,Vector2i(x,cy-1),Vector2i(2,2),white)
		"vinesnap":
			# A squat carnivorous bloom, leafy collar and root tendrils; no stick figure.
			var deep:=Color("#263b29")
			var leaf:=Color("#63873c")
			var lime:=Color("#a8c76b")
			var rose:=Color("#a94d75")
			var petal:=Color("#df8398")
			var throat:=Color("#532c4b")
			var bite:int=3 if attack else -2 if wind else 0
			var gape:int=7 if wind else 2 if attack and frame==1 else 5
			var c:=Vector2i(22,24) if side else Vector2i(24,23)
			if side:c.x+=bite
			else:c.y+=(-bite if back else bite)
			for i in range(3):
				var a:=Vector2i(24+(i-1)*5,34)
				var b:=Vector2i(24+(i-1)*12+step*(1 if i%2==0 else -1),40)
				var t:=b+Vector2i((i-1)*4,3-abs(step))
				enemy_line(im,a,b,4,ink);enemy_line(im,b,t,3,ink)
				enemy_line(im,a,b,2,deep);enemy_line(im,b,t,1,leaf)
				enemy_line(im,b-Vector2i(1,1),t-Vector2i(0,1),1,lime)
			enemy_dot(im,Vector2i(24,34),Vector2i(11,9),ink)
			enemy_dot(im,Vector2i(24,33),Vector2i(9,7),deep)
			for k in [-1,1]:
				var q:=Vector2i(24+int(k)*8,32+int(k)*step)
				enemy_cluster(im,q,[Vector2i(-10,1),Vector2i(-6,-5),Vector2i(3,-6),Vector2i(10,1),Vector2i(3,7),Vector2i(-6,6)],[Vector2i(-8,1),Vector2i(-5,-3),Vector2i(3,-4),Vector2i(8,1),Vector2i(2,5),Vector2i(-5,4)],[Vector2i(-6,0),Vector2i(-2,-3),Vector2i(5,0),Vector2i(-1,1)],ink,leaf,lime)
			enemy_cluster(im,c,[Vector2i(-17,-3),Vector2i(-15,-12),Vector2i(-8,-17),Vector2i(6,-16),Vector2i(15,-11),Vector2i(18,-2),Vector2i(16,10),Vector2i(7,15),Vector2i(-9,13),Vector2i(-16,8)],[Vector2i(-15,-3),Vector2i(-13,-10),Vector2i(-7,-15),Vector2i(5,-14),Vector2i(13,-10),Vector2i(16,-2),Vector2i(14,8),Vector2i(6,13),Vector2i(-8,11),Vector2i(-14,7)],[Vector2i(-12,-7),Vector2i(-6,-13),Vector2i(4,-12),Vector2i(9,-8),Vector2i(3,-6),Vector2i(-7,-5)],ink,rose,petal)
			if back:
				enemy_line(im,c+Vector2i(0,-13),c+Vector2i(-1,10),2,deep)
				for k in [-1,1]:enemy_line(im,c+Vector2i(0,-5),c+Vector2i(int(k)*10,-9),1,leaf)
				enemy_dot(im,c+Vector2i(0,9),Vector2i(3,2),gold)
			else:
				var mouth:=c+Vector2i(6,3) if side else c+Vector2i(0,5)
				if side:
					enemy_patch(im,mouth,[Vector2i(-8,-2),Vector2i(10,-gape),Vector2i(12,0),Vector2i(8,gape),Vector2i(-6,6)],ink)
					enemy_patch(im,mouth,[Vector2i(-5,-1),Vector2i(8,-gape+2),Vector2i(9,0),Vector2i(6,gape-1),Vector2i(-5,4)],throat)
					enemy_line(im,mouth+Vector2i(-3,-3),mouth+Vector2i(9,-gape),1,petal)
					for i in range(3):
						var t:=mouth+Vector2i(i*4-1,-gape+2)
						enemy_patch(im,t,[Vector2i(-1,0),Vector2i(2,0),Vector2i(0,3)],white)
					enemy_eye(im,c+Vector2i(0,-6),ink,pink,white,attack)
				else:
					enemy_dot(im,mouth,Vector2i(12,gape+2),ink)
					enemy_dot(im,mouth+Vector2i(0,1),Vector2i(9,maxi(1,gape-1)),throat)
					for i in range(5):
						var t:=mouth+Vector2i(-8+i*4,-gape+1)
						enemy_patch(im,t,[Vector2i(-1,0),Vector2i(2,0),Vector2i(0,3)],white)
					for k in [-1,1]:enemy_eye(im,c+Vector2i(int(k)*8,-6),ink,pink,white,attack)
				enemy_line(im,c+Vector2i(-5,-14),c+Vector2i(5,-14),1,gold)
		"eelstrix":
			var deep:=Color("#21495f")
			var aqua:=Color("#4ba5ad")
			var shine:=Color("#c4e0bd")
			var points:Array[Vector2i]=[]
			var surge:int=3 if attack else -2 if wind else 0
			for i in range(10):
				var wave:=roundi(sin(float(i)*.72-float(phase)*PI*.5)*float(3+i%3))
				if pose!="walk":wave=roundi(sin(float(i)*.72+float(frame)*.8)*float(6 if attack else 3))
				if side:
					points.append(Vector2i(37-i*3+surge,20+i+wave))
				else:
					points.append(Vector2i(24+wave,34-i*2+surge if not back else 13+i*2-surge))
			for i in range(9,0,-1):
				var radius:=maxi(2,6-int(i/2.0))
				enemy_line(im,points[i],points[i-1],radius,ink)
				enemy_line(im,points[i],points[i-1],radius-1,deep)
				enemy_line(im,points[i]-Vector2i(0,1),points[i-1]-Vector2i(0,1),maxi(1,radius-2),aqua)
				if i in [3,6]:
					enemy_dot(im,points[i],Vector2i(2,3),gold)
			var tail:=points[9]
			enemy_line(im,tail,tail+Vector2i(-4,-5) if side else tail+Vector2i(-4,-3),2,aqua)
			enemy_line(im,tail,tail+Vector2i(-4,5) if side else tail+Vector2i(4,-3),2,deep)
			var head:=points[0]
			enemy_dot(im,head,Vector2i(8,6),ink)
			enemy_dot(im,head-Vector2i(0,1),Vector2i(7,4),aqua)
			enemy_line(im,head+Vector2i(-3,-3),head+Vector2i(2,-3),1,shine)
			if not back:
				for x in ([2] if side else [-3,3]):
					enemy_dot(im,head+Vector2i(int(x),-1),Vector2i(2,2),ink)
					im.set_pixel(head.x+int(x),head.y-2,pink)
				if side:
					enemy_line(im,head+Vector2i(1,3),head+Vector2i(6,2 if not attack else 4),1,ink)
					if attack:im.set_pixel(head.x+4,head.y+2,white)
				else:
					enemy_line(im,head+Vector2i(-3,3),head+Vector2i(3,3),1,ink)
			if attack:
				for i in range(2,8,2):
					var spark:=points[i]+Vector2i(0,-7-frame)
					enemy_line(im,spark,spark+Vector2i(2,-2),1,shine)
					enemy_line(im,spark+Vector2i(2,-2),spark+Vector2i(4,0),1,purple)
		"comet_hare":
			# A compact moon hare with oversized ears, folded forepaws and powerful haunches.
			var deep:=Color("#494472")
			var fur:=Color("#a59ad7")
			var pale:=Color("#ded9fa")
			var shade:=Color("#7163ab")
			var rise:int=[0,-3,-5,-2][phase] if pose=="walk" else -4 if attack else 0
			var crouch:int=3 if wind else 0
			var body:=Vector2i(21,30+rise+crouch) if side else Vector2i(24,30+rise+crouch)
			var head:=Vector2i(30,20+rise+crouch) if side else Vector2i(24,19+rise+crouch)
			var tail:=body+Vector2i(-12,1) if side else body+Vector2i(0,7)
			if side or back:
				enemy_dot(im,tail,Vector2i(6,5),ink)
				enemy_dot(im,tail-Vector2i(0,1),Vector2i(4,3),pale)
			for k in [-1,1]:
				var foot:=body+Vector2i(int(k)*8,11+step*int(k))
				if side:foot=body+Vector2i(-2+int(k)*4,11+step*int(k))
				enemy_dot(im,foot,Vector2i(6,4),ink)
				enemy_dot(im,foot-Vector2i(0,1),Vector2i(4,2),shade)
				enemy_line(im,foot+Vector2i(-2,-1),foot+Vector2i(2,-1),1,fur)
			enemy_cluster(im,body,[Vector2i(-12,0),Vector2i(-9,-9),Vector2i(5,-11),Vector2i(12,-4),Vector2i(12,8),Vector2i(4,13),Vector2i(-9,10)],[Vector2i(-10,0),Vector2i(-7,-7),Vector2i(5,-9),Vector2i(10,-3),Vector2i(10,7),Vector2i(4,11),Vector2i(-7,8)],[Vector2i(-8,-2),Vector2i(-5,-6),Vector2i(3,-7),Vector2i(6,-2),Vector2i(2,6),Vector2i(-6,5)],ink,shade,fur)
			if not back:
				var chest:=body+Vector2i(6,1) if side else body+Vector2i(0,3)
				enemy_dot(im,chest,Vector2i(5,7),pale)
				for k in [-1,1]:
					var paw:=chest+Vector2i(int(k)*5,3)
					if side:paw=chest+Vector2i(2+int(k)*2,5)
					enemy_dot(im,paw,Vector2i(3,4),ink)
					enemy_dot(im,paw-Vector2i(0,1),Vector2i(2,2),fur)
			for k in [-1,1]:
				var ear:=head+Vector2i(int(k)*5,-5)
				if side:ear=head+Vector2i(-2+int(k)*3,-6)
				var tip:=ear+Vector2i(int(k)*3 if not side else -5,-13+step*int(k))
				enemy_poly(im,[ear+Vector2i(-4,2),tip+Vector2i(-4,4),tip+Vector2i(-2,-1),tip+Vector2i(2,-1),tip+Vector2i(4,4),ear+Vector2i(3,2)],ink)
				enemy_poly(im,[ear+Vector2i(-2,0),tip+Vector2i(-2,4),tip+Vector2i(0,1),tip+Vector2i(2,4),ear+Vector2i(2,0)],fur)
				enemy_line(im,ear,tip+Vector2i(0,4),1,Color("#bd82c0"))
			enemy_cluster(im,head,[Vector2i(-10,-3),Vector2i(-7,-9),Vector2i(6,-9),Vector2i(10,-5),Vector2i(12,3),Vector2i(6,9),Vector2i(-6,9),Vector2i(-11,4)],[Vector2i(-8,-3),Vector2i(-6,-7),Vector2i(5,-7),Vector2i(8,-4),Vector2i(10,3),Vector2i(5,7),Vector2i(-5,7),Vector2i(-9,3)],[Vector2i(-6,-5),Vector2i(2,-6),Vector2i(6,-3),Vector2i(2,0),Vector2i(-5,-1)],ink,fur,pale)
			if not back:
				for x in ([4] if side else [-5,5]):
					var q:=head+Vector2i(int(x),1)
					enemy_eye(im,q,ink,Color("#b36cb7"),white,attack)
					enemy_line(im,q+Vector2i(-2,4),q+Vector2i(1,4),1,Color("#d9a0cf"))
				var nose:=head+Vector2i(9,4) if side else head+Vector2i(0,5)
				enemy_dot(im,nose,Vector2i(2,1),deep)
				enemy_line(im,nose+Vector2i(0,1),nose+Vector2i(-1,2),1,deep)
			else:
				enemy_line(im,head+Vector2i(-4,-2),head+Vector2i(2,-4),1,pale)
			enemy_dot(im,body+Vector2i(1,0),Vector2i(2,2),gold)
			if attack:enemy_line(im,body+Vector2i(-8,14),body+Vector2i(8,14+frame),1,pale)
		"thornbeetle":
			# Rhinoceros beetle with sloped carapace, six segmented legs and a curved horn.
			var dark:=Color("#3a3829")
			var bark:=Color("#655337")
			var green:=Color("#718c44")
			var lime:=Color("#b0bd72")
			var ivory:=Color("#e0c793")
			var c:=Vector2i(20,24) if side else Vector2i(24,24)
			var ram:int=3 if attack else -2 if wind else 0
			for k in [-1,1]:
				for i in range(3):
					var gait:int=step*(-1 if (i+int(k))%2==0 else 1)
					var a:=c+Vector2i(int(k)*9,i*5-4)
					var b:=a+Vector2i(int(k)*5,3+gait)
					var t:=b+Vector2i(int(k)*4,6-gait)
					if side:
						a=c+Vector2i(i*7-7,int(k)*3+3)
						b=a+Vector2i(gait-2,6 if k==1 else -3)
						t=b+Vector2i(-3,5 if k==1 else -2)
					enemy_line(im,a,b,3,ink);enemy_line(im,b,t,2,ink)
					enemy_line(im,a,b,1,bark);enemy_line(im,b,t,1,ivory)
			enemy_cluster(im,c,[Vector2i(-15,3),Vector2i(-14,-7),Vector2i(-8,-13),Vector2i(5,-15),Vector2i(12,-9),Vector2i(15,1),Vector2i(10,10),Vector2i(-6,13),Vector2i(-13,8)],[Vector2i(-13,3),Vector2i(-12,-6),Vector2i(-7,-11),Vector2i(5,-13),Vector2i(10,-8),Vector2i(13,1),Vector2i(8,8),Vector2i(-6,11),Vector2i(-11,7)],[Vector2i(-11,-4),Vector2i(-7,-10),Vector2i(2,-12),Vector2i(8,-8),Vector2i(5,-2),Vector2i(-7,2)],ink,green,lime)
			enemy_patch(im,c,[Vector2i(6,-9),Vector2i(11,-5),Vector2i(13,1),Vector2i(8,8),Vector2i(-2,10),Vector2i(2,4)],dark)
			enemy_line(im,c+Vector2i(-1,-12),c+Vector2i(1,8),1,bark)
			for i in range(3):
				enemy_line(im,c+Vector2i(-10,i*4-7),c+Vector2i(-5,i*4-5),1,green)
			var head:=c+Vector2i(12+ram,3) if side else c+Vector2i(0,-12-ram if back else 10+ram)
			enemy_dot(im,head,Vector2i(8,7),ink)
			enemy_dot(im,head-Vector2i(1,1),Vector2i(6,5),bark)
			var horn:=head+Vector2i(3,0) if side else head+Vector2i(0,-2 if back else 2)
			var tip:=horn+Vector2i(8,-10) if side else horn+Vector2i(0,-9 if back else 9)
			enemy_poly(im,[horn+Vector2i(-4,2),horn+Vector2i(-2,-3),tip+Vector2i(-2,1),tip,tip+Vector2i(2,2),horn+Vector2i(4,4)],ink)
			enemy_line(im,horn,tip,2,ivory)
			enemy_line(im,horn+Vector2i(-1,-1),tip,1,white)
			if not back:
				for x in ([1] if side else [-5,5]):enemy_eye(im,head+Vector2i(int(x),-2),ink,pink,white,attack)
			enemy_line(im,c+Vector2i(-7,5),c+Vector2i(7,5),1,gold)
		"marrowray":
			# Broad manta with a continuous diamond mantle and visible near fin in profile.
			var deep:=Color("#233d59")
			var sea:=Color("#467d99")
			var skin:=Color("#83b6c2")
			var ivory:=Color("#d4e6df")
			var flap:int=[0,4,0,-4][phase] if pose=="walk" else -4 if wind else 5 if attack else 0
			var c:=Vector2i(24,24)
			var tail_base:=c+Vector2i(-8,3) if side else c+Vector2i(0,9 if back else -9)
			var tail_mid:=c+Vector2i(-15,5+step) if side else c+Vector2i(step,15 if back else -15)
			var tail_tip:=c+Vector2i(-21,3+step) if side else c+Vector2i(step*2,20 if back else -20)
			enemy_line(im,tail_base,tail_mid,2,ink);enemy_line(im,tail_mid,tail_tip,1,ink)
			enemy_line(im,tail_base,tail_mid,1,sea);enemy_line(im,tail_mid,tail_tip,1,skin)
			if side:
				var far:=c+Vector2i(-3,-12+flap)
				enemy_cluster(im,c,[Vector2i(-10,1),Vector2i(-8,-6),far-c,Vector2i(7,-4),Vector2i(8,1)],[Vector2i(-8,0),Vector2i(-6,-5),far-c+Vector2i(0,2),Vector2i(5,-3),Vector2i(6,0)],[Vector2i(-5,-2),far-c+Vector2i(0,3),Vector2i(3,-3)],ink,deep,sea)
				enemy_cluster(im,c,[Vector2i(-12,0),Vector2i(-6,-7),Vector2i(6,-9),Vector2i(14,-4),Vector2i(17,1),Vector2i(12,6),Vector2i(2,8),Vector2i(-8,5)],[Vector2i(-10,0),Vector2i(-5,-5),Vector2i(6,-7),Vector2i(12,-3),Vector2i(15,1),Vector2i(10,4),Vector2i(2,6),Vector2i(-7,3)],[Vector2i(-7,-1),Vector2i(-3,-4),Vector2i(7,-6),Vector2i(11,-3),Vector2i(3,-1)],ink,sea,skin)
				var near:=Vector2i(-2,16+flap)
				enemy_cluster(im,c,[Vector2i(-9,2),Vector2i(5,2),Vector2i(8,7),near,Vector2i(-9,10)],[Vector2i(-7,3),Vector2i(4,3),Vector2i(6,7),near-Vector2i(0,2),Vector2i(-7,9)],[Vector2i(-4,4),Vector2i(4,5),near-Vector2i(0,5),Vector2i(-4,9)],ink,sea,skin)
				enemy_line(im,c+Vector2i(2,4),c+near-Vector2i(0,3),1,ivory)
				enemy_eye(im,c+Vector2i(10,0),ink,pink,white,attack)
				enemy_line(im,c+Vector2i(12,4),c+Vector2i(15,3),1,ink)
			else:
				var nose:int=-10 if back else 11
				for k in [-1,1]:
					var sign_x:int=int(k)
					var tip:=Vector2i(sign_x*21,flap)
					enemy_cluster(im,c,[Vector2i(0,-9),Vector2i(sign_x*8,-8),tip,Vector2i(sign_x*12,9),Vector2i(0,12)],[Vector2i(0,-7),Vector2i(sign_x*8,-6),tip-Vector2i(sign_x*2,0),Vector2i(sign_x*11,7),Vector2i(0,10)],[Vector2i(0,-6),Vector2i(sign_x*7,-4),tip-Vector2i(sign_x*4,0),Vector2i(sign_x*9,3)],ink,sea,skin)
					enemy_line(im,c+Vector2i(sign_x*5,2),c+tip-Vector2i(sign_x*4,0),1,ivory)
				enemy_cluster(im,c,[Vector2i(-7,-10),Vector2i(7,-10),Vector2i(9,5),Vector2i(5,12),Vector2i(-5,12),Vector2i(-9,5)],[Vector2i(-5,-8),Vector2i(5,-8),Vector2i(7,5),Vector2i(4,10),Vector2i(-4,10),Vector2i(-7,5)],[Vector2i(-4,-7),Vector2i(3,-7),Vector2i(4,0),Vector2i(-3,2)],ink,sea,skin)
				if not back:
					for k in [-1,1]:
						enemy_eye(im,c+Vector2i(int(k)*5,6),ink,pink,white,attack)
						enemy_line(im,c+Vector2i(int(k)*6,10),c+Vector2i(int(k)*9,13),2,deep)
						enemy_line(im,c+Vector2i(int(k)*6,10),c+Vector2i(int(k)*8,12),1,skin)
				else:enemy_line(im,c+Vector2i(0,nose),c+Vector2i(0,6),1,deep)
			enemy_dot(im,c+Vector2i(-1,-3),Vector2i(2,2),gold)
			if attack:enemy_line(im,c+Vector2i(-10,13),c+Vector2i(10,13+frame),1,ivory)
		"voidspider":
			var deep:=Color("#292848")
			var moon:=Color("#6d79ae")
			var glint:=Color("#d2c8ff")
			var abdomen:=Vector2i(15,23) if side else Vector2i(24,29 if back else 19)
			var head:=Vector2i(30,29) if side else Vector2i(24,17 if back else 30)
			for k in [-1,1]:
				for i in range(4):
					var gait:int=step*(-1 if (i+int(k))%2==0 else 1)
					var root_leg:=head+Vector2i(int(k)*4,i*3-4)
					var knee:=Vector2i(24+int(k)*(13+i%2),12+i*7+gait)
					var tip:=knee+Vector2i(int(k)*5,4)
					if side:
						root_leg=head+Vector2i(-i*5,int(k)*2)
						knee=root_leg+Vector2i(gait-3,int(k)*7)
						tip=knee+Vector2i(4 if i==0 else -3,int(k)*5)
					enemy_line(im,root_leg,knee,2,ink)
					enemy_line(im,knee,tip,2,ink)
					enemy_line(im,root_leg,knee,1,moon)
					enemy_line(im,knee,tip,1,deep)
					enemy_dot(im,knee,Vector2i(1,1),gold)
			enemy_dot(im,abdomen,Vector2i(11,10),ink)
			enemy_dot(im,abdomen-Vector2i(0,1),Vector2i(9,8),deep)
			enemy_line(im,abdomen+Vector2i(-5,-5),abdomen+Vector2i(0,-8),1,moon)
			enemy_line(im,abdomen+Vector2i(0,-8),abdomen+Vector2i(5,-5),1,moon)
			enemy_line(im,abdomen+Vector2i(-4,0),abdomen+Vector2i(4,0),1,purple)
			enemy_dot(im,head,Vector2i(7,6),ink)
			enemy_dot(im,head,Vector2i(5,4),moon)
			if not back:
				for x in ([-2,1] if side else [-3,3]):
					var eye:=head+Vector2i(int(x),-1)
					enemy_dot(im,eye,Vector2i(2,1),pink)
			var reach:int=3 if attack else -1 if wind else 0
			for k in [-1,1]:
				var fang:=head+Vector2i(int(k)*4,2)
				var tip:=fang+Vector2i(5+reach,int(k)*2) if side else fang+Vector2i(-int(k),-4-reach if back else 4+reach)
				enemy_line(im,fang,tip,1,glint)
			if attack:
				var web:=head+Vector2i(9,0) if side else head+Vector2i(0, -9 if back else 9)
				enemy_line(im,web-Vector2i(4,3),web+Vector2i(4,3),1,glint)
				enemy_line(im,web+Vector2i(4,-3),web-Vector2i(4,-3),1,glint)
				enemy_line(im,web-Vector2i(4,0),web+Vector2i(4,0),1,purple)
		"rootgnawer":
			# Low, stocky boar. The muzzle and tusks project ahead of the shoulders.
			var bark:=Color("#5b4835")
			var fur:=Color("#a18a60")
			var ivory:=Color("#d0b77c")
			var dark_fur:=Color("#3c3028")
			var center:=Vector2i(20,29) if side else Vector2i(24,27)
			var charge:int=4 if attack else -2 if wind else 0
			for i in range(4):
				var stride:int=step*(-1 if i%2==0 else 1)
				var hip:=center+Vector2i(-8+(i%2)*15,3+int(i/2.0)*3) if side else center+Vector2i(-8+(i%2)*16,4+int(i/2.0)*5)
				var foot:=hip+Vector2i(stride,9-abs(stride))
				enemy_line(im,hip,foot,3,ink)
				enemy_line(im,hip,foot,2,dark_fur)
				enemy_dot(im,foot,Vector2i(3,2),ink)
				enemy_line(im,foot-Vector2i(1,1),foot+Vector2i(1,-1),1,fur)
			enemy_patch(im,center,[Vector2i(-14,1),Vector2i(-13,-8),Vector2i(-8,-13),Vector2i(6,-13),Vector2i(13,-7),Vector2i(14,6),Vector2i(7,11),Vector2i(-10,10)],ink)
			enemy_patch(im,center,[Vector2i(-12,0),Vector2i(-11,-7),Vector2i(-7,-11),Vector2i(5,-11),Vector2i(11,-6),Vector2i(12,5),Vector2i(6,9),Vector2i(-9,8)],bark)
			enemy_patch(im,center,[Vector2i(-11,-7),Vector2i(-7,-12),Vector2i(0,-10),Vector2i(7,-9),Vector2i(6,-4),Vector2i(-6,-3)],fur)
			for i in range(4):
				var p:=center+Vector2i(-9+i*5,-9-i%2*2)
				enemy_patch(im,p,[Vector2i(-3,3),Vector2i(0,-5),Vector2i(3,2)],Color("#718347"))
			enemy_line(im,center+Vector2i(-8,0),center+Vector2i(8,0),1,purple)
			enemy_dot(im,center,Vector2i(2,2),gold)
			var head:=center+Vector2i(12+charge,-1) if side else center+Vector2i(0,-9-charge if back else 9+charge)
			for k in [-1,1]:
				var ear:=head+Vector2i(int(k)*6,-5)
				enemy_patch(im,ear,[Vector2i(-4,2),Vector2i(-3,-6),Vector2i(2,-4),Vector2i(4,2)],ink)
				enemy_patch(im,ear,[Vector2i(-2,1),Vector2i(-2,-4),Vector2i(2,1)],fur)
			if back:
				enemy_dot(im,center+Vector2i(0,9),Vector2i(4,3),dark_fur)
				enemy_line(im,center+Vector2i(0,9),center+Vector2i(3,6),1,ivory)
			else:
				enemy_dot(im,head,Vector2i(9,8),ink)
				enemy_dot(im,head-Vector2i(1,1),Vector2i(7,6),bark)
				var snout:=head+Vector2i(6,3) if side else head+Vector2i(0,4)
				enemy_dot(im,snout,Vector2i(5,4),ink)
				enemy_dot(im,snout,Vector2i(4,3),Color("#a77f79"))
				for k in [-1,1]:
					im.set_pixel(clampi(snout.x+int(k)*2,0,47),snout.y,ink)
					var tusk:=snout+Vector2i(-2 if side else int(k)*5,2)
					enemy_patch(im,tusk,[Vector2i(-2,0),Vector2i(3,1),Vector2i(4,-5),Vector2i(1,-2)],ivory)
				for x in ([1] if side else [-5,5]):
					var eye:=head+Vector2i(int(x),-2)
					enemy_line(im,eye-Vector2i(2,1),eye+Vector2i(2,1),1,ink)
					im.set_pixel(eye.x,eye.y,pink)
		"jellymancer":
			# Bell propulsion, curved trailing tentacles and articulated contraction.
			var deep:=Color("#437e96")
			var gel:=Color("#83c8d3")
			var frost:=Color("#e0f9f1")
			var pulse:int=[0,2,-2,-1][phase] if pose=="walk" else 3 if wind else -3 if attack else 0
			var center:=Vector2i(24,20+pulse)
			var skirt:int=4 if wind else -2 if attack else pulse
			for i in range(6):
				var x:=12+i*5
				var bend:=roundi(sin(float(i)*1.1+float(phase)*1.57)*3.0) if pose=="walk" else (i-3)*2 if attack else 0
				var a:=Vector2i(x,center.y+7)
				var b:=Vector2i(x+bend,32+skirt)
				var c:=Vector2i(x+bend*2,40-skirt+i%2*3)
				if side:
					a.x+=3;b.x-=2;c.x-=5
				enemy_line(im,a,b,2,ink)
				enemy_line(im,b,c,2,ink)
				enemy_line(im,a,b,1,deep)
				enemy_line(im,b,c,1,gel)
				enemy_dot(im,c,Vector2i(1,2),pink if attack else frost)
			enemy_patch(im,center,[Vector2i(-17,5),Vector2i(-16,-4),Vector2i(-10,-12),Vector2i(0,-15),Vector2i(10,-12),Vector2i(16,-4),Vector2i(17,5),Vector2i(10,9),Vector2i(-10,9)],ink)
			enemy_patch(im,center,[Vector2i(-15,4),Vector2i(-14,-3),Vector2i(-9,-10),Vector2i(0,-13),Vector2i(9,-10),Vector2i(14,-3),Vector2i(15,4),Vector2i(9,7),Vector2i(-9,7)],deep)
			enemy_patch(im,center,[Vector2i(-13,0),Vector2i(-9,-8),Vector2i(-1,-11),Vector2i(7,-8),Vector2i(11,-2),Vector2i(3,2),Vector2i(-8,2)],gel)
			enemy_line(im,center+Vector2i(-9,-7),center+Vector2i(-3,-10),1,frost)
			enemy_line(im,center+Vector2i(-13,5),center+Vector2i(13,5),1,purple)
			for i in range(3):
				enemy_dot(im,center+Vector2i(-8+i*8,5),Vector2i(2,1),gold)
			if not back:
				for x in ([6] if side else [-5,5]):
					var eye:=center+Vector2i(int(x),1)
					enemy_dot(im,eye,Vector2i(3,3),ink)
					enemy_line(im,eye-Vector2i(1,0),eye+Vector2i(1,-1),1,pink)
			else:
				enemy_line(im,center+Vector2i(0,-6),center+Vector2i(0,3),1,frost)
			if attack:
				for i in range(3):
					var arc:=Vector2i(9+i*14,40-frame*2)
					enemy_line(im,arc-Vector2i(2,2),arc,1,frost)
					enemy_line(im,arc,arc+Vector2i(2,-2),1,gel)
		"lunamoth":
			# Four separately drawn wings; profile folds instead of copying a frontal wing span.
			var deep:=Color("#43375e")
			var lilac:=Color("#a894e5")
			var moon:=Color("#f1dbf7")
			var flap:int=[0,5,0,-5][phase] if pose=="walk" else 6 if wind else -5 if attack else 0
			var center:=Vector2i(24,25)
			for k in [-1,1]:
				var sign_x:int=int(k)
				var span:int=17-abs(flap)
				if side:span=10-int(abs(flap)/2.0)
				var tip:=center+Vector2i(sign_x*span,-14+flap) if not side else center+Vector2i(-8+sign_x*3,-14+flap*sign_x)
				var lower:=center+Vector2i(sign_x*(span-3),12-flap) if not side else center+Vector2i(-7+sign_x*2,12-flap*sign_x)
				var mid:=center+Vector2i(sign_x*6,0) if not side else center+Vector2i(-3,sign_x*5)
				enemy_poly(im,[center,tip,tip+Vector2i(sign_x*3,6),mid+Vector2i(sign_x*5,4),lower,lower+Vector2i(-sign_x*5,4)],ink)
				enemy_poly(im,[center,tip+Vector2i(-sign_x*2,2),tip+Vector2i(0,6),mid+Vector2i(sign_x*3,3),lower+Vector2i(-sign_x*2,0),lower+Vector2i(-sign_x*5,2)],deep)
				enemy_poly(im,[center,tip+Vector2i(-sign_x*3,4),mid+Vector2i(sign_x*3,2),lower+Vector2i(-sign_x*4,-1)],lilac)
				enemy_line(im,center,tip+Vector2i(-sign_x*2,3),1,moon)
				enemy_line(im,center,lower+Vector2i(-sign_x*3,0),1,moon)
				enemy_dot(im,mid+Vector2i(sign_x*4,-4),Vector2i(3,3),purple)
				enemy_dot(im,mid+Vector2i(sign_x*4,-4),Vector2i(1,2),gold)
			enemy_dot(im,center+Vector2i(0,5),Vector2i(5,11),ink)
			enemy_dot(im,center+Vector2i(0,4),Vector2i(3,8),deep)
			for y in [26,30,34]:
				enemy_line(im,Vector2i(22,y),Vector2i(26,y),1,lilac)
			var head:=center+Vector2i(5,-5) if side else center+Vector2i(0,-7)
			enemy_dot(im,head,Vector2i(6,5),ink)
			enemy_dot(im,head,Vector2i(4,4),lilac)
			for k in [-1,1]:
				var antenna:=head+Vector2i(int(k)*3,-4)
				var tip:=antenna+Vector2i(int(k)*3,-7)
				enemy_line(im,antenna,tip,1,deep)
				enemy_dot(im,tip,Vector2i(1,1),gold)
			if not back:
				for x in ([2] if side else [-2,2]):
					var eye:=head+Vector2i(int(x),0)
					enemy_dot(im,eye,Vector2i(1,2),ink)
					im.set_pixel(eye.x,eye.y,pink)
			if attack:
				for i in range(5):
					var dust:=Vector2i(8+i*8,39-frame*3-i%2*3)
					enemy_dot(im,dust,Vector2i(1,1),moon)
		"leafwisp":
			# A shy woodland spirit with three independently folding leaves, not a recolored Nova Wisp.
			var dark:=Color("#355032")
			var leaf:=Color("#527e42")
			var light:=Color("#a9d36c")
			var cream:=Color("#dbe88e")
			var flutter:int=[0,-3,0,3][phase] if pose=="walk" else 3 if wind else -4 if attack else 0
			var c:=Vector2i(24,26)
			var head:=c+Vector2i(4,-1) if side else c
			var top:=c+Vector2i(-3+flutter,-19)
			var left:=c+Vector2i(-17, -7+flutter)
			var right:=c+Vector2i(17,-9-flutter)
			if side:
				left=c+Vector2i(-16,-6+flutter)
				right=c+Vector2i(-6,-15-flutter)
			for tip in [top,left,right]:
				var q:Vector2i=tip
				var axis:=Vector2(q-c).normalized()
				var n:=Vector2i(Vector2(-axis.y,axis.x)*7.0)
				var mid:=Vector2i(Vector2(c).lerp(Vector2(q),.55))
				enemy_poly(im,[c,mid+n,q,mid-n],ink)
				enemy_poly(im,[c,mid+Vector2i(Vector2(n)*.67),q-Vector2i(axis*2),mid-Vector2i(Vector2(n)*.67)],leaf)
				enemy_poly(im,[c,mid+Vector2i(Vector2(n)*.5),q-Vector2i(axis*3),mid],light)
				enemy_line(im,c,q-Vector2i(axis*4),1,dark)
				enemy_line(im,mid,mid+Vector2i(Vector2(n)*.5),1,cream)
			enemy_patch(im,c,[Vector2i(-10,-4),Vector2i(-7,-10),Vector2i(5,-10),Vector2i(11,-3),Vector2i(9,8),Vector2i(2,14),Vector2i(-6,10)],ink)
			enemy_patch(im,c,[Vector2i(-8,-4),Vector2i(-5,-8),Vector2i(4,-8),Vector2i(9,-3),Vector2i(7,6),Vector2i(2,11),Vector2i(-4,8)],dark)
			enemy_dot(im,head-Vector2i(1,3),Vector2i(6,5),leaf)
			if not back:
				for x in ([2] if side else [-4,4]):
					var eye:=head+Vector2i(int(x),0)
					enemy_dot(im,eye,Vector2i(3,4),ink)
					enemy_dot(im,eye,Vector2i(2,3),pink)
					im.set_pixel(eye.x-1,eye.y-1,white)
				enemy_line(im,head+Vector2i(-1,5),head+Vector2i(1,5),1,ink)
			else:
				enemy_line(im,c+Vector2i(0,-7),c+Vector2i(0,8),1,light)
			enemy_dot(im,c+Vector2i(0,9),Vector2i(3,2),gold)
			enemy_dot(im,c+Vector2i(0,9),Vector2i(1,1),purple)
			if attack:
				var target:=Vector2i(41,26) if side else Vector2i(24,7 if back else 42)
				enemy_poly(im,[target+Vector2i(-4,0),target+Vector2i(0,-3-frame),target+Vector2i(4,0),target+Vector2i(0,3)],cream)
		"shellguard":
			# Heavy reef turtle. Withdraws head into shell, then leads with its armored shoulder.
			var dark:=Color("#355757")
			var green:=Color("#718f79")
			var cream:=Color("#e4ddbd")
			var plate:=Color("#a4b792")
			var c:=Vector2i(21,24) if side else Vector2i(24,24)
			var extension:int=-5 if wind else 3 if attack else 0
			for i in range(4):
				var sign_x:int=-1 if i%2==0 else 1
				var fore:bool=i<2
				var paddle:int=step*(1 if (i+1)%2==0 else -1)
				var joint:=c+Vector2i(sign_x*9,8 if fore else -5)
				var tip:=joint+Vector2i(sign_x*6,5+paddle if fore else -4-paddle)
				if side:
					joint=c+Vector2i(7 if fore else -8,4 if sign_x==1 else -3)
					tip=joint+Vector2i(3+paddle if fore else -5+paddle,9 if sign_x==1 else -3)
				enemy_line(im,joint,tip,4,ink)
				enemy_line(im,joint,tip,3,green)
				enemy_line(im,tip-Vector2i(2,0),tip+Vector2i(1,-1),1,cream)
			var tail:=c+Vector2i(-16,4) if side else c+Vector2i(0,14 if back else -14)
			enemy_line(im,c,tail,3,ink)
			enemy_line(im,c,tail,2,green)
			enemy_patch(im,c,[Vector2i(-15,3),Vector2i(-14,-7),Vector2i(-8,-14),Vector2i(7,-14),Vector2i(14,-7),Vector2i(15,4),Vector2i(8,12),Vector2i(-9,12)],ink)
			enemy_patch(im,c,[Vector2i(-13,3),Vector2i(-12,-7),Vector2i(-7,-12),Vector2i(6,-12),Vector2i(12,-6),Vector2i(13,3),Vector2i(7,10),Vector2i(-8,10)],dark)
			for offset in [Vector2i(-6,-5),Vector2i(5,-5),Vector2i(0,4)]:
				var q:Vector2i=c+offset
				enemy_patch(im,q,[Vector2i(-5,-2),Vector2i(0,-5),Vector2i(5,-2),Vector2i(4,3),Vector2i(-3,4)],plate)
				enemy_line(im,q+Vector2i(-3,-2),q+Vector2i(0,-4),1,cream)
				enemy_line(im,q+Vector2i(2,2),q+Vector2i(4,0),1,green)
			enemy_line(im,c+Vector2i(-10,6),c+Vector2i(10,6),2,purple)
			enemy_line(im,c+Vector2i(-8,6),c+Vector2i(8,6),1,gold)
			var head:=c+Vector2i(14+extension,3) if side else c+Vector2i(0,-13-extension if back else 13+extension)
			enemy_dot(im,head,Vector2i(7,6),ink)
			enemy_dot(im,head-Vector2i(0,1),Vector2i(5,4),green)
			enemy_line(im,head+Vector2i(-2,-2),head+Vector2i(2,-3),1,plate)
			if not back and not wind:
				for x in ([2] if side else [-3,3]):
					var eye:=head+Vector2i(int(x),0)
					enemy_dot(im,eye,Vector2i(2,2),ink)
					im.set_pixel(eye.x,eye.y-1,pink)
				enemy_line(im,head+Vector2i(-2,3),head+Vector2i(2,3),1,ink)
		"crystarok":
			# A stubborn crystal animal, carried by two huge knuckles and short rear legs.
			var dark:=Color("#343d68")
			var mid:=Color("#8e9ed0")
			var ice:=Color("#d7e5ff")
			var c:=Vector2i(20,26) if side else Vector2i(24,26)
			var lunge:int=3 if attack else -2 if wind else 0
			for k in [-1,1]:
				var sign_x:int=int(k)
				var foot:=c+Vector2i(sign_x*8,13+step*sign_x)
				if side:foot=c+Vector2i(-9+sign_x*4,13+step*sign_x)
				enemy_patch(im,foot,[Vector2i(-4,-5),Vector2i(4,-5),Vector2i(6,1),Vector2i(2,4),Vector2i(-5,3)],ink)
				enemy_patch(im,foot,[Vector2i(-3,-3),Vector2i(3,-3),Vector2i(4,1),Vector2i(-4,2)],dark)
			enemy_patch(im,c,[Vector2i(-12,-5),Vector2i(-8,-14),Vector2i(7,-15),Vector2i(13,-6),Vector2i(12,8),Vector2i(3,13),Vector2i(-10,9)],ink)
			enemy_patch(im,c,[Vector2i(-10,-5),Vector2i(-7,-12),Vector2i(6,-13),Vector2i(11,-5),Vector2i(10,7),Vector2i(3,11),Vector2i(-8,7)],dark)
			for i in range(3):
				var q:=c+Vector2i(-7+i*7,-8-i%2*3)
				var tip:=q+Vector2i(i-1,-10)
				enemy_poly(im,[q+Vector2i(-5,4),tip+Vector2i(-2,3),tip,tip+Vector2i(3,4),q+Vector2i(5,4)],ink)
				enemy_poly(im,[q+Vector2i(-3,3),tip+Vector2i(-1,3),tip+Vector2i(1,2),q+Vector2i(0,3)],mid)
				enemy_poly(im,[q+Vector2i(0,3),tip+Vector2i(1,2),tip+Vector2i(2,4),q+Vector2i(4,3)],Color("#596d9a"))
				enemy_line(im,tip+Vector2i(0,3),q+Vector2i(-1,1),1,ice)
			for k in [-1,1]:
				var sign_x:int=int(k)
				var fist:=c+Vector2i(sign_x*13,8+step*sign_x+lunge)
				if side:fist=c+Vector2i(11+lunge,sign_x*4+8+step*sign_x)
				enemy_line(im,c+Vector2i(sign_x*6,1),fist,4,ink)
				enemy_patch(im,fist,[Vector2i(-5,-5),Vector2i(3,-6),Vector2i(7,-1),Vector2i(5,5),Vector2i(-4,6),Vector2i(-7,1)],ink)
				enemy_patch(im,fist,[Vector2i(-4,-4),Vector2i(2,-4),Vector2i(5,-1),Vector2i(3,3),Vector2i(-3,4),Vector2i(-5,1)],mid)
				enemy_line(im,fist+Vector2i(-2,-2),fist+Vector2i(2,-3),1,ice)
				enemy_line(im,fist+Vector2i(-4,1),fist+Vector2i(3,3),1,dark)
			if not back:
				var head:=c+Vector2i(7,-1) if side else c+Vector2i(0,2)
				enemy_dot(im,head,Vector2i(7,5),ink)
				for x in ([2] if side else [-3,3]):
					var eye:=head+Vector2i(int(x),0)
					enemy_line(im,eye-Vector2i(1,-1),eye+Vector2i(1,0),1,pink)
				enemy_dot(im,head+Vector2i(0,4),Vector2i(2,1),gold)
			else:
				enemy_line(im,c+Vector2i(-4,3),c+Vector2i(4,3),1,gold)
		"bramble_pup":
			# Small woodland quadruped, fox-like wedge head, leafy ruff and curled thorn tail.
			var bark:=Color("#51432c")
			var moss:=Color("#748d46")
			var leaf:=Color("#a5bc64")
			var cream:=Color("#e6d5a4")
			var c:=Vector2i(21,29) if side else Vector2i(24,29)
			var lunge:int=3 if attack else -2 if wind else 0
			var head:=c+Vector2i(11+lunge,-7) if side else c+Vector2i(0,-9-lunge if back else -6+lunge)
			var tail:=c+Vector2i(-13,-5) if side else c+Vector2i(0,10 if back else -11)
			enemy_line(im,c,tail,4,ink)
			enemy_line(im,c,tail,2,bark)
			enemy_cluster(im,tail,[Vector2i(-6,-2),Vector2i(-4,-7),Vector2i(1,-12),Vector2i(5,-7),Vector2i(4,3),Vector2i(0,5)],[Vector2i(-4,-2),Vector2i(-2,-7),Vector2i(1,-9),Vector2i(3,-6),Vector2i(2,2),Vector2i(0,3)],[Vector2i(-2,-5),Vector2i(1,-8),Vector2i(1,-1)],ink,moss,leaf)
			for i in range(4):
				var k:int=-1 if i%2==0 else 1
				var stride:int=step*(-1 if i in [0,3] else 1)
				var hip:=c+Vector2i(k*7,5 if i<2 else -2)
				if side:hip=c+Vector2i(7 if i<2 else -8,k*3+4)
				var knee:=hip+Vector2i(stride,4)
				var foot:=knee+Vector2i(stride,5-absi(stride))
				enemy_line(im,hip,knee,3,ink);enemy_line(im,knee,foot,3,ink)
				enemy_line(im,hip,knee,2,bark);enemy_line(im,knee,foot,2,moss)
				enemy_dot(im,foot,Vector2i(3,2),ink)
				enemy_line(im,foot+Vector2i(-1,-1),foot+Vector2i(1,-1),1,cream)
			enemy_cluster(im,c,[Vector2i(-13,-2),Vector2i(-10,-9),Vector2i(3,-11),Vector2i(12,-6),Vector2i(14,4),Vector2i(8,10),Vector2i(-8,11)],[Vector2i(-11,-2),Vector2i(-8,-7),Vector2i(3,-9),Vector2i(10,-5),Vector2i(12,3),Vector2i(7,8),Vector2i(-7,9)],[Vector2i(-9,-5),Vector2i(-5,-8),Vector2i(5,-7),Vector2i(8,-3),Vector2i(-5,0)],ink,bark,moss)
			for i in range(3):
				var q:=c+Vector2i(-8+i*6,-7)
				enemy_patch(im,q,[Vector2i(-3,2),Vector2i(0,-5),Vector2i(4,2)],leaf)
			for k in [-1,1]:
				var ear:=head+Vector2i(int(k)*6,-6)
				if side:ear=head+Vector2i(-4+int(k)*3,-6)
				var tip:=ear+Vector2i(int(k)*3,-8)
				enemy_poly(im,[ear+Vector2i(-4,4),tip,ear+Vector2i(4,4)],ink)
				enemy_poly(im,[ear+Vector2i(-2,2),tip+Vector2i(0,3),ear+Vector2i(2,2)],moss)
				enemy_line(im,ear,tip+Vector2i(0,3),1,leaf)
			enemy_cluster(im,head,[Vector2i(-10,-3),Vector2i(-7,-8),Vector2i(6,-8),Vector2i(10,-3),Vector2i(12,3),Vector2i(5,9),Vector2i(-6,8),Vector2i(-11,3)],[Vector2i(-8,-3),Vector2i(-6,-6),Vector2i(5,-6),Vector2i(8,-2),Vector2i(10,3),Vector2i(4,7),Vector2i(-5,6),Vector2i(-9,3)],[Vector2i(-5,-5),Vector2i(4,-5),Vector2i(6,-1),Vector2i(0,2),Vector2i(-6,0)],ink,moss,leaf)
			if not back:
				var muzzle:=head+Vector2i(8,4) if side else head+Vector2i(0,5)
				enemy_dot(im,muzzle,Vector2i(4,3),cream)
				enemy_dot(im,muzzle+Vector2i(2 if side else 0,0),Vector2i(1,1),ink)
				for x in ([3] if side else [-4,4]):enemy_eye(im,head+Vector2i(int(x),0),ink,pink,white,attack)
			else:enemy_line(im,head+Vector2i(-4,-1),head+Vector2i(4,-1),1,bark)
			enemy_dot(im,c+Vector2i(0,6),Vector2i(2,2),gold)
		"anemoneye":
			# Radial sea anemone; muscular foot, tentacles around a single pearl eye.
			var deep:=Color("#65354e")
			var coral:=Color("#c87591")
			var pale:=Color("#f1b6b3")
			var aqua:=Color("#6dada8")
			var c:=Vector2i(24,26)
			var spread:int=3 if attack else -3 if wind else step
			var foot:=Vector2i(24,39)
			enemy_cluster(im,foot,[Vector2i(-13,-3),Vector2i(-9,-8),Vector2i(9,-8),Vector2i(13,-3),Vector2i(11,4),Vector2i(-11,4)],[Vector2i(-11,-2),Vector2i(-8,-6),Vector2i(8,-6),Vector2i(11,-2),Vector2i(9,2),Vector2i(-9,2)],[Vector2i(-8,-4),Vector2i(7,-4),Vector2i(4,-1),Vector2i(-6,-1)],ink,deep,coral)
			for i in range(9):
				var angle:float=float(i)*TAU/9.0
				var root:=c+Vector2i(roundi(cos(angle)*8.0),roundi(sin(angle)*5.0))
				var bend:=c+Vector2i(roundi(cos(angle)*float(13+spread)),roundi(sin(angle)*9.0)-5+step*(1 if i%2==0 else -1))
				var tip:=bend+Vector2i(roundi(cos(angle)*5.0),-4+roundi(sin(angle)*3.0))
				if side:root.x-=3; bend.x-=3; tip.x-=3
				enemy_line(im,root,bend,3,ink);enemy_line(im,bend,tip,3,ink)
				enemy_line(im,root,bend,2,deep);enemy_line(im,bend,tip,2,coral)
				enemy_dot(im,tip,Vector2i(2,2),pale)
				enemy_line(im,bend-Vector2i(1,1),tip,1,pale)
			enemy_dot(im,c,Vector2i(12,11),ink)
			enemy_dot(im,c,Vector2i(10,9),deep)
			enemy_line(im,c+Vector2i(-7,-5),c+Vector2i(6,-6),1,gold)
			if not back:
				var eye:=c+Vector2i(4,1) if side else c+Vector2i(0,1)
				enemy_dot(im,eye,Vector2i(8,7),ink)
				enemy_dot(im,eye,Vector2i(6,5),pale)
				enemy_dot(im,eye+Vector2i(1 if side else 0,0),Vector2i(3,4),aqua)
				enemy_dot(im,eye+Vector2i(1 if side else 0,0),Vector2i(2,3),ink)
				im.set_pixelv(eye+Vector2i(-1,-2),white)
			else:
				enemy_dot(im,c,Vector2i(5,6),coral)
				enemy_line(im,c+Vector2i(0,-4),c+Vector2i(0,4),1,pale)
			if attack:
				var target:=Vector2i(40,26) if side else Vector2i(24,5 if back else 43)
				enemy_line(im,c,target,1,pink)
				enemy_dot(im,target,Vector2i(2+frame,2),aqua)
		"nebulwing":
			# No bird skeleton: bat membrane wings, hooked ears, inverted wing-fold.
			var deep:=Color("#303150")
			var mid:=Color("#7666aa")
			var pale:=Color("#cab7ed")
			var c:=Vector2i(24,24)
			var flap:int=[0,5,0,-5][phase] if pose=="walk" else 5 if wind else -4 if attack else 0
			for k in [-1,1]:
				var sign_x:int=int(k)
				var shoulder:=c+Vector2i(sign_x*4,-2)
				var tip:=c+Vector2i(sign_x*20,-10+flap)
				var elbow:=c+Vector2i(sign_x*12,1+flap)
				var notch:=c+Vector2i(sign_x*10,11-flap)
				if side:
					shoulder=c+Vector2i(-2,sign_x*2)
					tip=c+Vector2i(-15,-12*sign_x+flap)
					elbow=c+Vector2i(-9,sign_x*4+flap)
					notch=c+Vector2i(-5,sign_x*13-flap)
				enemy_poly(im,[shoulder,tip,elbow,tip+Vector2i(0,7),notch,c+Vector2i(sign_x*3,8)],ink)
				enemy_poly(im,[shoulder,tip+Vector2i(-sign_x*2,2),elbow,tip+Vector2i(-sign_x*2,5),notch,c+Vector2i(sign_x*3,6)],mid)
				enemy_line(im,shoulder,elbow,1,deep)
				enemy_line(im,shoulder,notch,1,deep)
				enemy_line(im,shoulder,tip+Vector2i(-sign_x*2,2),1,pale)
			enemy_dot(im,c+Vector2i(0,7),Vector2i(8,10),ink)
			enemy_dot(im,c+Vector2i(0,6),Vector2i(6,8),deep)
			var head:=c+Vector2i(5,-3) if side else c+Vector2i(0,-5)
			for k in [-1,1]:
				var ear:=head+Vector2i(int(k)*5,-5)
				var tip:=ear+Vector2i(int(k)*3,-8)
				enemy_poly(im,[ear+Vector2i(-4,3),tip,ear+Vector2i(4,3)],ink)
				enemy_poly(im,[ear+Vector2i(-2,1),tip+Vector2i(0,3),ear+Vector2i(2,1)],mid)
			enemy_dot(im,head,Vector2i(8,7),ink)
			enemy_dot(im,head-Vector2i(0,1),Vector2i(6,5),mid)
			enemy_line(im,head+Vector2i(-4,-3),head+Vector2i(1,-4),1,pale)
			if not back:
				for x in ([3] if side else [-3,3]):enemy_eye(im,head+Vector2i(int(x),0),ink,pink,white,attack)
				var mouth:=head+Vector2i(4 if side else 0,5)
				enemy_dot(im,mouth,Vector2i(2,2),ink)
				im.set_pixelv(mouth+Vector2i(-1,0),white)
			else:enemy_line(im,head+Vector2i(-2,1),head+Vector2i(2,1),1,deep)
			enemy_dot(im,c+Vector2i(0,8),Vector2i(2,2),gold)
			if attack:
				var out:=Vector2i(42,25) if side else Vector2i(24,5 if back else 43)
				for i in range(2):
					enemy_line(im,out+Vector2i(-3-i*2,-3),out+Vector2i(2+i*2,0),1,pale)
					enemy_line(im,out+Vector2i(2+i*2,0),out+Vector2i(-3-i*2,3),1,pale)
	if dir==2:im.flip_x()
	if recoil:
		for y in range(48):
			for x in range(48):
				var c:=im.get_pixel(x,y)
				if c.a>0:im.set_pixel(x,y,c.lerp(Color("#ff839f"),.35))
	if pose=="defeat" and id!="sporeling":
		# Keep source proportions. Floating creatures disperse, swimmers bank,
		# ground animals fall onto their side. These are prototype key poses.
		var fallen:=Image.create(48,48,false,Image.FORMAT_RGBA8)
		fallen.fill(Color.TRANSPARENT)
		if id in ["nova_wisp","leafwisp","jellymancer"]:
			for y in range(48):
				for x in range(48):
					var pixel:=im.get_pixel(x,y)
					if pixel.a>0.0 and posmod(x*11+y*7,5)<2:
						var q:=Vector2i(clampi(x+signi(x-24)*3,0,47),clampi(y+6,0,47))
						fallen.set_pixelv(q,pixel)
		else:
			var bounds:=im.get_used_rect()
			var cropped:=im.get_region(bounds)
			if id in ["shellguard","coralcrab","thornbeetle","voidspider"]:
				cropped.flip_y()
			else:
				cropped.rotate_90(CLOCKWISE if dir!=2 else COUNTERCLOCKWISE)
			fallen.blit_rect(cropped,Rect2i(Vector2i.ZERO,cropped.get_size()),Vector2i(int((48-cropped.get_width())/2.0),maxi(0,44-cropped.get_height())))
		return fallen
	return im
# External production atlases take priority over unapproved procedural studies.
static var enemy_atlas_cache:Dictionary={}
static func enemy_asset_cell(id:String,dir:int,pose:String,frame:int)->Image:
	if not enemy_atlas_cache.has(id):
		var path:="res://assets/enemies/%s.png"%id
		var img:Image=null
		if ResourceLoader.exists(path):
			var tex:=load(path) as Texture2D
			if tex!=null:
				var candidate:=tex.get_image()
				if candidate!=null and (not candidate.is_compressed() or candidate.decompress()==OK) and candidate.get_size()==Vector2i(528,192):
					img=candidate
		enemy_atlas_cache[id]=img
	var sheet:Image=enemy_atlas_cache[id]
	if sheet==null:return enemy_pixel_cell(id,dir,pose,frame) if id in ENEMY_PIXEL_PILOTS else null
	var col:int=1+posmod(frame,4) if pose=="walk" else 6+posmod(frame,2) if pose=="attack" else ENEMY_POSES.find(pose)
	return sheet.get_region(Rect2i(maxi(col,0)*48,clampi(dir,0,3)*48,48,48))
static func enemy_pixel_texture(id:String,dir:int,pose:String,frame:int)->Texture2D:
	var key:="enemy:%s:%d:%s:%d"%[id,dir,pose,frame]
	if not cache.has(key):
		var image:=enemy_asset_cell(id,dir,pose,frame)
		if image==null:return null
		cache[key]=ImageTexture.create_from_image(image)
	return cache[key] as Texture2D
static func enemy_pixel_atlas(id:String)->Image:
	var im:=Image.create(48*ENEMY_POSES.size(),192,false,Image.FORMAT_RGBA8)
	im.fill(Color.TRANSPARENT)
	for dir in range(4):
		for col in range(ENEMY_POSES.size()):
			var frame:int=col-1 if col in [1,2,3,4] else col-6 if col in [6,7] else 0
			im.blit_rect(enemy_pixel_cell(id,dir,ENEMY_POSES[col],frame),Rect2i(0,0,48,48),Vector2i(col*48,dir*48))
	return im
