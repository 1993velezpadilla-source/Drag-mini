extends SceneTree
# Lossless original animation strips, generated with the same renderer as gameplay.
const Dungeon=preload("res://dungeon_view.gd")
const FOLDER="res://generated_combat_frames"

func _initialize()->void:
	call_deferred("bake")

func bake()->void:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))!=OK:
		quit(1)
		return
	var pack:=FileAccess.open(FOLDER+"/frames.bin",FileAccess.WRITE)
	if pack==null:
		quit(1)
		return
	var view:=Dungeon.new()
	var catalog:Dictionary=Dungeon.Rules.MOVE_LIBRARY.duplicate()
	catalog.merge(Dungeon.Rules.DEV_NATIVE_MOVES)
	var ids:Array=catalog.keys()
	if not ids.has("basic_strike"):ids.append("basic_strike")
	for species in Dungeon.Rules.SIGNATURE_SKILLS:
		var signature:String=str(Dungeon.Rules.SIGNATURE_SKILLS[species][6])
		if not ids.has(signature):ids.append(signature)
		var secondary:String="alt_"+str(species)
		if not ids.has(secondary):ids.append(secondary)
	ids.sort()
	var entries:Dictionary={}
	var digests:Dictionary={}
	var size:int=Dungeon.FX_FRAME_SIZE
	var count:int=Dungeon.FX_FRAME_COUNT
	var failures:int=0
	for id in ids:
		var strip:=Image.create(size*count,size,false,Image.FORMAT_RGBA8)
		strip.fill(Color.TRANSPARENT)
		for frame in range(count):
			var image:=view.combat_frame_image(str(id),frame)
			if image.get_width()!=size or image.get_height()!=size:
				failures+=1
				continue
			if image.get_format()!=Image.FORMAT_RGBA8:image.convert(Image.FORMAT_RGBA8)
			strip.blit_rect(image,Rect2i(0,0,size,size),Vector2i(frame*size,0))
		var bytes:=strip.save_png_to_buffer()
		if bytes.is_empty():failures+=1
		digests[id]=hash(strip.get_data())
		entries[id]=[pack.get_position(),bytes.size()]
		pack.store_buffer(bytes)
	var total:int=pack.get_position()
	pack.close()
	view.free()
	var index:=FileAccess.open(FOLDER+"/index.json",FileAccess.WRITE)
	if index==null:
		quit(1)
		return
	index.store_string(JSON.stringify({"version":1,"size":size,"frames":count,"bytes":total,"entries":entries}))
	index.close()
	var reader:=Dungeon.new()
	for id in ids:
		var strip:=reader.combat_frame_pack_image(str(id))
		if strip==null or hash(strip.get_data())!=int(digests[id]):
			failures+=1
			continue
		var before:int=reader.fx_atlas_uploads
		var first:Texture2D=reader.combat_animated_texture(str(id),0)
		for frame in range(count):
			var texture:Texture2D=reader.combat_animated_texture(str(id),frame)
			if not texture is AtlasTexture:
				failures+=1
				continue
			var region:Rect2=texture.region
			if region!=Rect2(frame*size,0,size,size) or texture.atlas!=first.atlas or not texture.filter_clip:failures+=1
		if reader.fx_atlas_uploads!=before+1 or reader.combat_animated_texture(str(id),0)!=first or reader.fx_atlas_cache.size()>Dungeon.FX_ATLAS_CACHE_CAP:failures+=1
	if reader.fx_frame_builds!=0 or reader.fx_atlas_uploads!=ids.size():failures+=1
	print("KINDRIA_FRAME_PACK moves=",ids.size()," frames=",ids.size()*count," bytes=",total," atlas_uploads=",reader.fx_atlas_uploads," procedural_builds=",reader.fx_frame_builds," failures=",failures)
	reader.free()
	quit(0 if failures==0 else 1)
