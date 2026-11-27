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

# Production strips must be explicitly approved and provide attribution.
static func load_part_sheet(path:String)->Image:
	if not path.begins_with("res://assets/") or not ResourceLoader.exists(path):return null
	var tex:=load(path) as Texture2D
	if tex==null:return null
	var image:=tex.get_image()
	if image==null or image.is_empty():return null
	if image.is_compressed() and image.decompress()!=OK:return null
	if image.get_width()%64!=0 or not image.get_height() in [64,256]:return null
	image.convert(Image.FORMAT_RGBA8)
	return image

static func parse_offsets(raw:Variant,directional:bool)->Dictionary:
	var parsed:Dictionary={}
	if not raw is Dictionary:return parsed
	for key in raw:
		var pair=raw[key]
		if not pair is Array or pair.size()!=2:continue
		if directional:
			if not str(key).is_valid_int() or int(key)<0 or int(key)>3:continue
			parsed[int(key)]=Vector2i(clampi(int(pair[0]),-32,32),clampi(int(pair[1]),-32,32))
		else:
			if not str(key) in MOODS:continue
			parsed[str(key)]=Vector2i(clampi(int(pair[0]),-32,32),clampi(int(pair[1]),-32,32))
	return parsed

static func load_manifest(path:String)->Dictionary:
	var result:Dictionary={}
	if not FileAccess.file_exists(path):return result
	var data=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:return result
	var species_map=data.get("species",{})
	if not species_map is Dictionary:return result
	for id in species_map:
		var entries=species_map[id]
		if not entries is Array:continue
		var approved:Array=[]
		for entry in entries:
			if not entry is Dictionary:continue
			if not bool(entry.get("approved",false)) or str(entry.get("license","")).strip_edges().is_empty() or str(entry.get("source","")).strip_edges().is_empty():continue
			if not str(entry.get("slot","")) in SLOTS:continue
			var part:Dictionary={"slot":entry.slot,"size":clampi(int(entry.get("size",48)),8,96)}
			var offset=entry.get("offset",[0,0])
			if offset is Array and offset.size()==2:part["offset"]=Vector2i(int(offset[0]),int(offset[1]))
			part["direction_offsets"]=parse_offsets(entry.get("direction_offsets",{}),true)
			part["mood_offsets"]=parse_offsets(entry.get("mood_offsets",{}),false)
			for layer in ["back","front"]:
				var sheet:=load_part_sheet(str(entry.get(layer,"")))
				if sheet!=null:part[layer]=sheet
			var clips:Dictionary={}
			var source_clips=entry.get("clips",{})
			if source_clips is Dictionary:
				for key in source_clips:
					if not source_clips[key] is Dictionary:continue
					var layers:Dictionary={}
					for layer in ["back","front"]:
						var sheet:=load_part_sheet(str(source_clips[key].get(layer,"")))
						if sheet!=null:layers[layer]=sheet
					if not layers.is_empty():clips[key]=layers
			part["clips"]=clips
			if part.has("back") or part.has("front") or not clips.is_empty():approved.append(part)
		if not approved.is_empty():result[str(id)]=approved
	return result
