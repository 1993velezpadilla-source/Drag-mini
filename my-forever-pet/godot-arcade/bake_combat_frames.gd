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
		var first:=reader.combat_animated_texture(str(id),0) as AtlasTexture
		if first==null:
			failures+=1
			continue
		for frame in range(count):
			var texture:Texture2D=reader.combat_animated_texture(str(id),frame)
			if not texture is AtlasTexture:
				failures+=1
				continue
			var atlas_frame:=texture as AtlasTexture
			var region:Rect2=atlas_frame.region
			if region!=Rect2(frame*size,0,size,size) or atlas_frame.atlas!=first.atlas or not atlas_frame.filter_clip:failures+=1
		if reader.fx_atlas_uploads!=before+1 or reader.combat_animated_texture(str(id),0)!=first or reader.fx_atlas_cache.size()>Dungeon.FX_ATLAS_CACHE_CAP:failures+=1
	if reader.fx_frame_builds!=0 or reader.fx_atlas_uploads!=ids.size():failures+=1
	# Force an eviction while an animation still owns all original frames.
	var pinned_id:String=str(ids[0])
	var pinned:Array=reader.combat_cast_frames(pinned_id)
	var pinned_uploads:int=reader.fx_atlas_uploads
	reader.fx_atlas_cache.clear()
	for frame in range(count):
		if pinned.size()!=count or reader.combat_cast_frame(pinned_id,pinned,frame)!=pinned[frame]:failures+=1
	if reader.fx_atlas_uploads!=pinned_uploads or reader.fx_frame_builds!=0:failures+=1
	var warm_ids:=reader.combat_floor_warm_ids(["eos_308","eos_308","eos_135"],[])
	if warm_ids.count("eos_308")!=1 or not warm_ids.has("eos_135") or not warm_ids.has("basic_strike") or warm_ids.size()>Dungeon.FX_ATLAS_CACHE_CAP:failures+=1
	print("KINDRIA_FRAME_PACK moves=",ids.size()," frames=",ids.size()*count," bytes=",total," atlas_uploads=",reader.fx_atlas_uploads," procedural_builds=",reader.fx_frame_builds," failures=",failures)
	reader.free()
	failures+=bake_secondary(ids,catalog)
	quit(0 if failures==0 else 1)

# Sample real combat choreography and retain exact CPU source images before upload.
# Unknown runtime combinations retain the renderer's original fallback.
func bake_secondary(ids:Array,catalog:Dictionary)->int:
	var view:=Dungeon.new()
	var scene:=Node3D.new()
	root.add_child(scene)
	view.fx_secondary_pack_checked=true
	view.fx_secondary_capture=true
	view.combat_fx_setup(scene)
	view.fx_audio.clear()
	var tile:=Vector2i(2,0)
	for id in ids:
		var move:Dictionary=catalog.get(id,{})
		var row:Dictionary={"effects":1} if str(move.get("category",""))=="status" else {"damage":8}
		var event:Dictionary={"fx":id,"from":Vector2i.ZERO,"to":tile,"path":[Vector2i(1,0),tile],"tiles":[tile],"results":{tile:row},"damage":int(row.get("damage",0))}
		view.combat_fx_spawn(event)
		var duration:float=float(view.combat_bursts[-1].duration)
		for step in range(16):view.combat_fx_update(duration/15.0)
		for step in range(8):view.combat_fx_update(.12)
	var images:Dictionary=view.fx_secondary_images
	scene.free()
	view.free()
	var pack:=FileAccess.open(FOLDER+"/particles.bin",FileAccess.WRITE)
	if pack==null:return 1
	var entries:Dictionary={}
	var failures:int=0
	var keys:Array=images.keys()
	keys.sort()
	for key in keys:
		var image:Image=images[key]
		if image.get_format()!=Image.FORMAT_RGBA8:image.convert(Image.FORMAT_RGBA8)
		entries[key]=[pack.get_position(),image.get_width(),image.get_height()]
		pack.store_buffer(image.get_data())
	var size:int=pack.get_position()
	pack.close()
	var index:=FileAccess.open(FOLDER+"/particles.json",FileAccess.WRITE)
	if index==null:return 1
	index.store_string(JSON.stringify({"version":1,"bytes":size,"entries":entries}))
	index.close()
	var reader:=Dungeon.new()
	for key in keys:
		var image:=reader.secondary_pack_image(str(key))
		var source:Image=images[key]
		if image==null or image.get_data()!=source.get_data():failures+=1
	if keys.is_empty():failures+=1
	reader.free()
	print("KINDRIA_SECONDARY_PACK textures=",keys.size()," bytes=",size," failures=",failures)
	return failures
