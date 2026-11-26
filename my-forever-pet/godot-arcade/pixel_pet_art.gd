extends RefCounted
# Original pixel artwork with stable companion identity; no full-scene pixelation.
static var cache:Dictionary={}
static func ellipse(im:Image,center:Vector2,radii:Vector2,c:Color)->void:
	for y in range(maxi(0,int(center.y-radii.y)),mini(im.get_height(),int(center.y+radii.y)+1)):
		for x in range(maxi(0,int(center.x-radii.x)),mini(im.get_width(),int(center.x+radii.x)+1)):
			if ((Vector2(x,y)-center)/radii).length_squared()<=1.0: im.set_pixel(x,y,c)

static func mosskit(pose:String)->Image:
	var im:=Image.create(48,48,false,Image.FORMAT_RGBA8)
	im.fill(Color.TRANSPARENT)
	var ink:=Color("#25421c")
	var deep:=Color("#478d27")
	var leaf:=Color("#76c438")
	var high:=Color("#a7e657")
	var pink:=Color("#f49ac2")
	var eye:=Color("#241c43")
	for side in [-1,1]:
		var foot:=Vector2(24+side*10,41)
		ellipse(im,foot,Vector2(9,5),ink)
		ellipse(im,foot+Vector2(0,-1),Vector2(7,3),deep)
		ellipse(im,foot+Vector2(-1,-2),Vector2(5,2),leaf)
		var ear:=Vector2(24+side*12,10)
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

# World-facing presentation only. The actor root still owns movement, hit
# effects, scale, visibility and game rules. Full 3D backgrounds are untouched.
static func world_sprite(parent:Node3D,id:int,height:float=1.65)->Sprite3D:
	var front:=portrait("res://assets/pet_%d.png"%id,true)
	if front==null: return null
	var rear:=portrait("res://assets/pet_rear_%d.png"%id,true)
	var sprite:=Sprite3D.new()
	sprite.name="PixelCompanion"
	sprite.texture=front
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded=false
	sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.position.y=height*.5
	sprite.pixel_size=height/float(front.get_height())
	sprite.set_meta("front",front)
	sprite.set_meta("rear",rear if rear!=null else front)
	sprite.set_meta("world_height",height)
	parent.add_child(sprite)
	return sprite

static func orient_world_sprite(actor:Node3D,camera:Camera3D)->void:
	if not is_instance_valid(actor) or not is_instance_valid(camera): return
	var sprite:=actor.get_node_or_null("PixelCompanion") as Sprite3D
	if sprite==null: return
	var to_camera:=camera.global_position-actor.global_position
	to_camera.y=0
	var forward:=actor.global_transform.basis.z
	forward.y=0
	var facing:=forward.normalized().dot(to_camera.normalized())
	var tex:Texture2D=sprite.get_meta("rear") if facing<-.15 else sprite.get_meta("front")
	if sprite.texture!=tex:
		sprite.texture=tex
		sprite.pixel_size=float(sprite.get_meta("world_height"))/float(tex.get_height())
