extends RefCounted
# Existing LPC layer format; composition is separate from gameplay and species.
const SLOTS=["tail","wing_left","wing_right","ears","eyes","mouth","fins","crest","horns","limbs","aura","flame","accessory"]
const DIR_ROWS=[2,0,1,3] # Game front/rear/left/right -> LPC down/up/left/right
const MOODS=["healthy","happy","sad","weak","sick"]
static func mood(happiness:float,energy:float,hunger:float,germs:int)->String:
	if germs>0:return "sick"
	if energy<=20 or hunger<=1:return "weak"
	if happiness<=3:return "sad"
	if happiness>=8 and energy>=60:return "happy"
	return "healthy"
static func lpc_frame(sheet:Image,direction:int,index:int)->Image:
	if sheet==null or sheet.is_empty() or sheet.get_width()%64!=0 or sheet.get_height()%64!=0:return null
	var row:int=DIR_ROWS[clampi(direction,0,3)] if sheet.get_height()>=256 else 0
	var count:int=sheet.get_width()/64
	return sheet.get_region(Rect2i(posmod(index,maxi(1,count))*64,row*64,64,64))
static func composite(body:Image,parts:Array,dir:int,frame:int)->Image:
	var result:=Image.create(body.get_width(),body.get_height(),false,Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	for pass_id in [0,1]:
		for part in parts:
			var sheet:Image=part.get("back" if pass_id==0 else "front")
			if sheet==null:continue
			var cell:=lpc_frame(sheet,dir,frame)
			if cell==null:continue
			cell.convert(Image.FORMAT_RGBA8)
			var size_px:int=clampi(int(part.get("size",48)),8,96)
			cell.resize(size_px,size_px,Image.INTERPOLATE_NEAREST)
			var offset:Vector2i=part.get("offset",Vector2i.ZERO)
			var at:=Vector2i((body.get_width()-size_px)/2,(body.get_height()-size_px)/2)+offset
			result.blend_rect(cell,Rect2i(0,0,size_px,size_px),at)
		if pass_id==0:result.blend_rect(body,Rect2i(Vector2i.ZERO,body.get_size()),Vector2i.ZERO)
	return result

# Choose an existing authored strip per slot, pose and mood. Missing variants
# fall back to the supplied base sheet, never synthesize replacement anatomy.
static func select_clip(part:Dictionary,layer:String,pose:String,mood_name:String)->Image:
	var clips:Dictionary=part.get("clips",{})
	for key in [pose+":"+mood_name,pose,"idle:"+mood_name,"idle"]:
		var clip:Dictionary=clips.get(key,{})
		var sheet=clip.get(layer)
		if sheet is Image and not sheet.is_empty():return sheet
	var fallback=part.get(layer)
	return fallback if fallback is Image else null

static func clip_index(sheet:Image,progress:float,loop:bool=false)->int:
	if sheet==null or sheet.is_empty():return 0
	var count:int=maxi(1,int(sheet.get_width()/64))
	var t:float=fposmod(progress,1.0) if loop else clampf(progress,0.0,1.0)
	return mini(count-1,floori(t*count))

# Every slot may have its own clip, pivot, frame count and directional offset.
# Back -> base body -> front; nearest-neighbor scaling preserves pixel edges.
static func composite_pose(body:Image,parts:Array,dir:int,pose:String,mood_name:String,progress:float)->Image:
	var result:=Image.create(body.get_width(),body.get_height(),false,Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var loop:bool=pose in ["idle","walk","burst"]
	for layer in ["back","front"]:
		for part in parts:
			if not str(part.get("slot","")) in SLOTS:continue
			var sheet:Image=select_clip(part,layer,pose,mood_name)
			if sheet==null:continue
			var cell:=lpc_frame(sheet,dir,clip_index(sheet,progress,loop))
			if cell==null:continue
			cell.convert(Image.FORMAT_RGBA8)
			var size_px:int=clampi(int(part.get("size",48)),8,96)
			cell.resize(size_px,size_px,Image.INTERPOLATE_NEAREST)
			var offset:Vector2i=part.get("offset",Vector2i.ZERO)
			var directions:Dictionary=part.get("direction_offsets",{})
			offset+=Vector2i(directions.get(dir,Vector2i.ZERO))
			var moods:Dictionary=part.get("mood_offsets",{})
			offset+=Vector2i(moods.get(mood_name,Vector2i.ZERO))
			var at:=Vector2i((body.get_width()-size_px)/2,(body.get_height()-size_px)/2)+offset
			result.blend_rect(cell,Rect2i(0,0,size_px,size_px),at)
		if layer=="back":result.blend_rect(body,Rect2i(Vector2i.ZERO,body.get_size()),Vector2i.ZERO)
	return result
