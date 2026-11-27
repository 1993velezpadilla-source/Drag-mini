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
const ENEMY_PIXEL_PILOTS=["sporeling","coralcrab","nova_wisp","vinesnap","eelstrix","comet_hare","thornbeetle","marrowray","voidspider","rootgnawer","jellymancer","lunamoth"]
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
			var bark:=Color("#493b27")
			var moss:=Color("#64783a")
			var cap_y:=18+(2 if wind else -2 if attack else 0)
			for k in [-1,1]:
				var x:int=24+int(k)*6
				var foot_y:int=40+(step*int(k) if pose=="walk" else 0)
				enemy_dot(im,Vector2i(x,foot_y),Vector2i(5,4),ink)
				enemy_dot(im,Vector2i(x,foot_y-1),Vector2i(3,2),Color("#79804a"))
			enemy_dot(im,Vector2i(24,31),Vector2i(11,12),ink)
			enemy_dot(im,Vector2i(24,30),Vector2i(9,10),Color("#c2a38b"))
			enemy_dot(im,Vector2i(24,cap_y+5),Vector2i(20,9),ink)
			enemy_dot(im,Vector2i(24,cap_y+3),Vector2i(18,7),Color("#51442d"))
			enemy_dot(im,Vector2i(24,cap_y-3),Vector2i(19,13),ink)
			enemy_dot(im,Vector2i(24,cap_y-4),Vector2i(17,11),moss)
			enemy_dot(im,Vector2i(30,cap_y-1),Vector2i(8,6),Color("#53602f"))
			enemy_line(im,Vector2i(9,cap_y+1),Vector2i(14,cap_y+3),1,Color("#a8c56c"))
			enemy_line(im,Vector2i(34,cap_y+2),Vector2i(39,cap_y),1,Color("#53602f"))
			enemy_dot(im,Vector2i(19,cap_y-8),Vector2i(11,5),Color("#97b65a"))
			for spot in [Vector2i(13,-5),Vector2i(25,-10),Vector2i(34,-3)]:
				enemy_dot(im,Vector2i(spot.x,cap_y+spot.y),Vector2i(3,2),Color("#f2d6a0"))
			enemy_line(im,Vector2i(8,cap_y+5),Vector2i(39,cap_y+5),1,gold)
			for x in [11,18,25,32,37]:
				enemy_line(im,Vector2i(x,cap_y+7),Vector2i(x,cap_y+9),1,bark)
			if not back:
				enemy_line(im,Vector2i(20,cap_y+2),Vector2i(24,cap_y+5),1,gold)
				enemy_line(im,Vector2i(24,cap_y+5),Vector2i(28,cap_y+2),1,gold)
				im.set_pixel(24,cap_y+1,white)
			if not back:
				for x in ([29] if side else [19,29]):
					enemy_dot(im,Vector2i(x,31),Vector2i(4,5),ink)
					enemy_dot(im,Vector2i(x+1,30),Vector2i(2,2),pink)
			enemy_line(im,Vector2i(14,37),Vector2i(18,40),1,purple)
			enemy_line(im,Vector2i(30,40),Vector2i(34,37),1,purple)
			if attack:
				for i in range(3):
					enemy_dot(im,Vector2i(24+fx+i*4-4,8-i*2+frame),Vector2i(1,1),pink)
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
			var moss:=Color("#759343")
			var deep:=Color("#38502c")
			var petal:=Color("#d8a366")
			var root_y:=39
			var reach:=4 if attack else -2 if wind else 0
			var jaw_gap:=5 if wind else 2 if attack and frame==1 else 4
			for i in range(3):
				var sign_x:int=i-1
				var root_tip:=Vector2i(24+sign_x*13+step*(1 if i%2==0 else -1),43-abs(step))
				enemy_line(im,Vector2i(24+sign_x*3,root_y-7),root_tip,3,ink)
				enemy_line(im,Vector2i(24+sign_x*3,root_y-7),root_tip,2,deep)
				enemy_line(im,root_tip-Vector2i(sign_x*3,2),root_tip,1,moss)
			var mouth:=Vector2i(28+reach,20) if side else Vector2i(24,18+reach if not back else 18-reach)
			enemy_line(im,Vector2i(24,37),mouth+Vector2i(-3,8),5,ink)
			enemy_line(im,Vector2i(24,37),mouth+Vector2i(-3,8),3,moss)
			for k in [-1,1]:
				var leaf_pos:=Vector2i(24+int(k)*8,32+int(k)*step)
				enemy_line(im,Vector2i(24,35),leaf_pos,2,deep)
				enemy_dot(im,leaf_pos,Vector2i(6,3),deep)
				enemy_dot(im,leaf_pos-Vector2i(1,1),Vector2i(4,2),moss)
			if side:
				enemy_dot(im,mouth+Vector2i(-2,-jaw_gap),Vector2i(13,6),ink)
				enemy_dot(im,mouth+Vector2i(-2,-jaw_gap-1),Vector2i(11,4),petal)
				enemy_dot(im,mouth+Vector2i(-2,jaw_gap),Vector2i(12,5),ink)
				enemy_dot(im,mouth+Vector2i(-2,jaw_gap),Vector2i(10,3),deep)
				for i in range(3):
					im.set_pixel(mouth.x+2+i*3,mouth.y-jaw_gap+4,white)
				enemy_dot(im,mouth+Vector2i(-7,-jaw_gap-2),Vector2i(2,2),purple)
			else:
				enemy_dot(im,mouth,Vector2i(15,11),ink)
				enemy_dot(im,mouth-Vector2i(0,2),Vector2i(13,8),petal)
				if not back:
					enemy_dot(im,mouth+Vector2i(0,3),Vector2i(10,jaw_gap+2),ink)
					for i in range(5):
						im.set_pixel(mouth.x-6+i*3,mouth.y-jaw_gap+4,white)
					for k in [-1,1]:
						enemy_dot(im,mouth+Vector2i(int(k)*8,-3),Vector2i(2,2),purple)
				else:
					enemy_line(im,mouth-Vector2i(0,8),mouth+Vector2i(0,7),1,moss)
			enemy_line(im,Vector2i(20,35),Vector2i(28,35),1,gold)
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
			var deep:=Color("#514b8c")
			var fur:=Color("#b3a5e8")
			var shine:=Color("#ecf0ff")
			var jump:int=[0,-3,-5,-2][phase] if pose=="walk" else -4 if attack else 0
			var crouch:int=3 if wind else 0
			var body:=Vector2i(22,30+jump+crouch)
			var head:=Vector2i(29,21+jump+crouch) if side else Vector2i(24,20+jump+crouch)
			var tail:=body+Vector2i(-11,0) if side else body+Vector2i(0,5 if back else -1)
			enemy_dot(im,tail,Vector2i(5,4),ink)
			enemy_dot(im,tail-Vector2i(0,1),Vector2i(3,3),shine)
			for k in [-1,1]:
				var foot:=Vector2i(24+int(k)*8,40+int(k)*step if not attack else 40)
				if side:foot=Vector2i(24+int(k)*4+step,40+jump)
				enemy_dot(im,foot,Vector2i(7,4),ink)
				enemy_dot(im,foot-Vector2i(0,1),Vector2i(5,2),deep)
			enemy_dot(im,body,Vector2i(12,12),ink)
			enemy_dot(im,body-Vector2i(0,2),Vector2i(10,9),deep)
			enemy_dot(im,body-Vector2i(2,3),Vector2i(7,6),fur)
			for k in [-1,1]:
				var ear_base:=head+Vector2i(int(k)*5,-5)
				var ear_tip:=ear_base+Vector2i(-4 if side else int(k)*3,-10+step*int(k))
				enemy_line(im,ear_base,ear_tip,4,ink)
				enemy_line(im,ear_base,ear_tip,3,fur)
				enemy_line(im,ear_base,ear_tip+Vector2i(0,2),1,Color("#8877d0"))
			enemy_dot(im,head,Vector2i(10,9),ink)
			enemy_dot(im,head-Vector2i(0,1),Vector2i(8,7),fur)
			enemy_line(im,head+Vector2i(-4,-4),head+Vector2i(1,-5),1,shine)
			if not back:
				for x in ([4] if side else [-4,4]):
					enemy_dot(im,head+Vector2i(int(x),0),Vector2i(2,3),ink)
					im.set_pixel(head.x+int(x),head.y-1,pink)
				enemy_dot(im,head+Vector2i(7 if side else 0,4),Vector2i(2,1),deep)
			else:
				enemy_line(im,head+Vector2i(-3,2),head+Vector2i(3,2),1,deep)
			enemy_line(im,body+Vector2i(-5,4),body+Vector2i(5,4),1,gold)
			if attack:
				for i in range(3):
					enemy_line(im,Vector2i(17+i*7,42),Vector2i(15+i*9,45),1,shine)
		"thornbeetle":
			var bark:=Color("#53422d")
			var ochre:=Color("#ab9255")
			var moss:=Color("#799647")
			var center:=Vector2i(22,27) if side else Vector2i(24,25)
			var ram:int=3 if attack else -2 if wind else 0
			for k in [-1,1]:
				for i in range(3):
					var phase_shift:int=step*(-1 if (i+int(k))%2==0 else 1)
					var joint:=center+Vector2i(int(k)*8,i*5-3)
					var knee:=center+Vector2i(int(k)*(13+i%2),i*5+phase_shift)
					var foot:=center+Vector2i(int(k)*17,i*5+6+phase_shift)
					if side:
						joint=center+Vector2i(i*8-8,int(k)*3)
						knee=joint+Vector2i(phase_shift-2,7 if k==1 else -4)
						foot=knee+Vector2i(-3,4 if k==1 else -2)
					enemy_line(im,joint,knee,2,ink)
					enemy_line(im,knee,foot,2,ink)
					enemy_line(im,joint,knee,1,bark)
					enemy_line(im,knee,foot,1,ochre)
			enemy_dot(im,center,Vector2i(13,13) if side else Vector2i(13,15),ink)
			enemy_dot(im,center-Vector2i(0,1),Vector2i(11,11) if side else Vector2i(11,13),bark)
			enemy_dot(im,center-Vector2i(2,4),Vector2i(9,8),moss)
			enemy_line(im,center-Vector2i(0,11),center+Vector2i(0,7),1,ink)
			for i in range(3):
				var plate:=center+Vector2i(-8,i*5-6)
				enemy_line(im,plate,plate+Vector2i(5,-2),1,ochre)
				enemy_line(im,plate+Vector2i(11,-2),plate+Vector2i(16,0),1,ochre)
			var head:=center+Vector2i(10+ram,-4) if side else center+Vector2i(0,-12-ram if back else 12+ram)
			enemy_dot(im,head,Vector2i(7,6),ink)
			enemy_dot(im,head,Vector2i(5,4),bark)
			var tip:=head+Vector2i(8,-4) if side else head+Vector2i(0,-7 if back else 7)
			enemy_line(im,head,tip,3,ink)
			enemy_line(im,head,tip,2,ochre)
			enemy_line(im,head+Vector2i(0,-1),tip,1,Color("#d8c594"))
			if not back:
				for x in ([2] if side else [-3,3]):
					var eye:=head+Vector2i(int(x),-2)
					enemy_dot(im,eye,Vector2i(2,2),purple)
					im.set_pixel(eye.x,eye.y,pink)
			enemy_line(im,center+Vector2i(-4,5),center+Vector2i(4,5),1,gold)
		"marrowray":
			var sea:=Color("#294b70")
			var skin:=Color("#7598ad")
			var ivory:=Color("#d3dfd9")
			var flap:int=[0,4,0,-4][phase] if pose=="walk" else -3 if wind else 5 if attack else 0
			var center:=Vector2i(24,24)
			var head:=center+Vector2i(11,-2) if side else center+Vector2i(0,-9 if back else 9)
			var tail:=center+Vector2i(-13,3) if side else center+Vector2i(0,12 if back else -12)
			var tail_tip:=tail+Vector2i(-7,step) if side else tail+Vector2i(step,5 if back else -5)
			enemy_line(im,tail,tail_tip,2,ink)
			enemy_line(im,tail,tail_tip,1,skin)
			for k in [-1,1]:
				var wing:=center+Vector2i(int(k)*17,flap) if not side else center+Vector2i(-6 if k==-1 else 1,int(k)*7+flap)
				var lead:=center+Vector2i(int(k)*7,-7) if not side else center+Vector2i(6,int(k)*3)
				var trailing:=center+Vector2i(int(k)*5,6) if not side else center+Vector2i(-9,int(k)*5)
				for j in range(9):
					var a:=Vector2i(Vector2(lead).lerp(Vector2(trailing),float(j)/8.0).round())
					enemy_line(im,a,wing,2,ink)
				for j in range(7):
					var a:=Vector2i(Vector2(lead).lerp(Vector2(trailing),float(j+1)/8.0).round())
					enemy_line(im,a,wing-Vector2i(int(k)*2,0) if not side else wing-Vector2i(0,int(k)*2),1,sea)
				enemy_line(im,lead,wing,1,skin)
				enemy_line(im,center,wing-Vector2i(int(k)*4,1) if not side else wing,1,ivory)
			enemy_dot(im,center,Vector2i(11,8) if side else Vector2i(8,12),ink)
			enemy_dot(im,center-Vector2i(0,1),Vector2i(9,6) if side else Vector2i(6,10),skin)
			enemy_dot(im,head,Vector2i(5,4),ink)
			enemy_dot(im,head,Vector2i(4,3),sea)
			if not back:
				for x in ([2] if side else [-2,2]):
					var eye:=head+Vector2i(int(x),-1)
					enemy_dot(im,eye,Vector2i(1,1),pink)
			enemy_line(im,center+Vector2i(-3,1),center+Vector2i(3,1),1,gold)
			if attack:
				enemy_line(im,center+Vector2i(-14,7),center+Vector2i(13,9),1,ivory)
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
	if dir==2:im.flip_x()
	if recoil:
		for y in range(48):
			for x in range(48):
				var c:=im.get_pixel(x,y)
				if c.a>0:im.set_pixel(x,y,c.lerp(Color("#ff839f"),.35))
	if pose=="defeat":
		var fallen:=Image.create(48,48,false,Image.FORMAT_RGBA8)
		fallen.fill(Color.TRANSPARENT)
		im.resize(48,24,Image.INTERPOLATE_NEAREST)
		fallen.blit_rect(im,Rect2i(0,0,48,24),Vector2i(0,20))
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
