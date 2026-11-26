extends RefCounted
# Original pixel artwork with stable companion identity; no full-scene pixelation.
static var cache:Dictionary={}
static func ellipse(im:Image,center:Vector2,radii:Vector2,c:Color)->void:
	for y in range(maxi(0,int(center.y-radii.y)),mini(im.get_height(),int(center.y+radii.y)+1)):
		for x in range(maxi(0,int(center.x-radii.x)),mini(im.get_width(),int(center.x+radii.x)+1)):
			if ((Vector2(x,y)-center)/radii).length_squared()<=1.0: im.set_pixel(x,y,c)

static func mosskit(pose:String,step:int=0)->Image:
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
		var ear:=Vector2(24+side*12,10+step*side/2.0)
		ellipse(im,ear,Vector2(6,9),ink)
		ellipse(im,ear,Vector2(4,7),leaf)
		ellipse(im,ear+Vector2(0,1),Vector2(3,5),pink)
	ellipse(im,Vector2(24,9),Vector2(4,6),ink)
	ellipse(im,Vector2(24,8),Vector2(2,4),high)
	ellipse(im,Vector2(24,26),Vector2(19,16),ink)
	ellipse(im,Vector2(24,26),Vector2(17,14),deep)
	ellipse(im,Vector2(23,23),Vector2(16,12),leaf)
	ellipse(im,Vector2(18,16),Vector2(8,3),high)
	for side in [-1,1]:
		var p:=Vector2(24+side*9,25)
		if pose in ["sleep","blink"]:
			# Closed eyelid: small hand-placed stepped line.
			for x in range(-4,5):
				var y:int=1-absi(x)/3 if pose=="sleep" else 0
				im.set_pixel(int(p.x)+x,int(p.y)+int(y),eye)
		else:
			ellipse(im,p,Vector2(5,7),eye)
			ellipse(im,p+Vector2(-1,-3),Vector2(2,2),Color("#fff3ef"))
			im.set_pixel(int(p.x)+2,int(p.y)+4,Color("#655b9a"))
		ellipse(im,Vector2(24+side*13,32),Vector2(3,2),pink)
	ellipse(im,Vector2(24,34),Vector2(4,3 if pose!="eat" else 4),eye)
	ellipse(im,Vector2(24,35),Vector2(2,1),pink)
	return im

static func mosskit_back(step:int)->Image:
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
		var ear:=Vector2(24+side*12,11)
		ellipse(img,ear,Vector2(6,10),outline)
		ellipse(img,ear+Vector2(0,-1),Vector2(4,8),mid)
		ellipse(img,ear+Vector2(-1,-3),Vector2(2,4),light)
	ellipse(img,Vector2(24,10),Vector2(5,6),outline)
	ellipse(img,Vector2(24,9),Vector2(3,4),light)
	ellipse(img,Vector2(24,26),Vector2(19,17),outline)
	ellipse(img,Vector2(24,26),Vector2(17,15),shade)
	ellipse(img,Vector2(23,23),Vector2(16,13),mid)
	ellipse(img,Vector2(18,17),Vector2(9,4),light)
	for side in [-1,1]:
		ellipse(img,Vector2(24+side*11,23),Vector2(4,4),shade)
		ellipse(img,Vector2(23+side*11,22),Vector2(3,3),light)
	ellipse(img,Vector2(24,36),Vector2(6,6),outline)
	ellipse(img,Vector2(24,35),Vector2(5,5),shade)
	ellipse(img,Vector2(23,34),Vector2(3,3),light)
	return img


static func source_image(path:String)->Image:
	if path=="res://assets/pet_rear_0.png": return mosskit_back(0)
	if path=="res://assets/pet_0.png": return mosskit("idle")
	if path=="res://assets/pet_sleep_0.png": return mosskit("sleep")
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
	var im:Image=mosskit(pose) if not pose.is_empty() and path=="res://assets/pet_0.png" else source_image(path)
	if im==null: return null
	if trim:
		var bounds:=im.get_used_rect()
		if bounds.has_area(): im=im.get_region(bounds)
	var tex:=ImageTexture.create_from_image(im)
	cache[key]=tex
	return tex

# Directional 48x48 sprite atlas. All frames keep one canvas and ground anchor.
# The rear is the original Pet Dash drawing; front and profile use the same palette.
static func mosskit_side(step:int,blink:bool=false,attack:bool=false)->Image:
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
	ellipse(im,Vector2(10,33),Vector2(6,6),ink)
	ellipse(im,Vector2(10,32),Vector2(4,4),leaf)
	ellipse(im,Vector2(23,9),Vector2(4,6),ink)
	ellipse(im,Vector2(23,8),Vector2(2,4),high)
	ellipse(im,Vector2(24,26),Vector2(17,16),ink)
	ellipse(im,Vector2(24,26),Vector2(15,14),deep)
	ellipse(im,Vector2(24,23),Vector2(14,12),leaf)
	ellipse(im,Vector2(20,17),Vector2(8,3),high)
	ellipse(im,Vector2(19,10+step*.5),Vector2(6,9),ink)
	ellipse(im,Vector2(19,10+step*.5),Vector2(4,7),leaf)
	ellipse(im,Vector2(20,10+step*.5),Vector2(2,5),pink)
	ellipse(im,Vector2(28-step,42+step),Vector2(8,4),ink)
	ellipse(im,Vector2(28-step,41+step),Vector2(6,3),deep)
	ellipse(im,Vector2(27-step,40+step),Vector2(4,2),leaf)
	if blink:
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

static func adventure_frame(dir:int,pose:String,frame:int=0)->Texture2D:
	var key:="adventure:%d:%s:%d"%[dir,pose,frame]
	if cache.has(key):return cache[key] as Texture2D
	var stride:int=0
	if pose in ["walk","burst"]:stride=[0,2,0,-2][posmod(frame,4)]
	elif pose=="attack":stride=2 if frame%2==0 else -2
	var im:Image
	match dir:
		1:im=mosskit_back(stride)
		2,3:
			im=mosskit_side(stride,pose=="blink",pose=="attack")
			if dir==2:im.flip_x()
		_:im=mosskit("blink" if pose=="blink" else "eat" if pose=="attack" else "idle",stride)
	var tex:=ImageTexture.create_from_image(im)
	cache[key]=tex
	return tex

static func frame_for(dir:int,pose:String,clock:float)->Texture2D:
	var frame:int=posmod(int(floor(clock*(14.0 if pose=="burst" else 10.0))),4) if pose in ["walk","burst"] else posmod(int(floor(clock*14.0)),2) if pose=="attack" else 0
	var actual:String="blink" if pose=="idle" and fposmod(clock,3.8)>3.62 else pose
	return adventure_frame(dir,actual,frame)

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
	var tex:=frame_for(dir,state,clock)
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
