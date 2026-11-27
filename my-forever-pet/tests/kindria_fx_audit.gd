extends SceneTree
const Field=preload("res://dungeon_view.gd")
const Rules=preload("res://dungeon_rules.gd")
const OUT="/tmp/kindria-full-fx"
func _initialize():
	call_deferred("run")

func digest(data:PackedByteArray)->String:
	var ctx:=HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish().hex_encode()

func run()->void:
	var field=Field.new()
	var audit:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://eos_move_audit.json"))
	var errors:Array[String]=[]
	var reports:Array=[]
	var roles:Dictionary={}
	var signatures:Dictionary={}
	var seen_ids:Dictionary={}
	var total_frames:int=0
	var blank_interior:int=0
	var repeated_adjacent:int=0
	var timing_usec:int=0
	DirAccess.make_dir_recursive_absolute(OUT)
	for row in audit.rows:
		if row.get("range")==null or str(row.range).is_empty():continue
		var id:String="eos_%03d"%int(row.id)
		var profile:Dictionary=field.combat_profile(id)
		if seen_ids.has(id):errors.append("duplicate ID "+id)
		seen_ids[id]=true
		if not Rules.MOVE_LIBRARY.has(id):errors.append("missing runtime "+id)
		if roles.has(profile.role):errors.append("duplicate role "+id+" "+str(roles[profile.role]))
		roles[profile.role]=id
		if float(profile.duration)<=0.0 or float(profile.impact)<0.0 or float(profile.impact)>1.0:errors.append("invalid timing "+id)
		var sheet:=Image.create(Field.FX_FRAME_SIZE*Field.FX_FRAME_COUNT,Field.FX_FRAME_SIZE,false,Image.FORMAT_RGBA8)
		sheet.fill(Color.TRANSPARENT)
		var hashes:Dictionary={}
		var empty:Array[int]=[]
		var areas:Array[int]=[]
		var previous:String=""
		var repeated:int=0
		for frame in range(Field.FX_FRAME_COUNT):
			var begin:int=Time.get_ticks_usec()
			var im:Image=field.combat_frame_image(id,frame)
			timing_usec+=Time.get_ticks_usec()-begin
			total_frames+=1
			if im.get_size()!=Vector2i(Field.FX_FRAME_SIZE,Field.FX_FRAME_SIZE):errors.append("bad size "+id)
			var signature:String=digest(im.get_data())
			hashes[signature]=true
			if signature==previous:repeated+=1
			previous=signature
			var rect:Rect2i=im.get_used_rect()
			areas.append(rect.size.x*rect.size.y)
			if not rect.has_area():
				empty.append(frame)
				if frame>0 and frame<Field.FX_FRAME_COUNT-1:blank_interior+=1
			sheet.blit_rect(im,Rect2i(Vector2i.ZERO,im.get_size()),Vector2i(frame*Field.FX_FRAME_SIZE,0))
		repeated_adjacent+=repeated
		if empty.size()==Field.FX_FRAME_COUNT:errors.append("fully empty "+id)
		if hashes.size()<3:errors.append("fewer than three distinct frames "+id)
		var sequence:String=digest(sheet.get_data())
		if signatures.has(sequence):errors.append("duplicate sequence "+id+" "+str(signatures[sequence]))
		signatures[sequence]=id
		if sheet.save_png(OUT+"/"+id+".png")!=OK:errors.append("PNG export failed "+id)
		reports.append({"id":id,"symbol":row.symbol,"type":row.type,"role":profile.role,"pattern":profile.pattern,"reach":profile.range,"duration_seconds":profile.duration,"impact_fraction":profile.impact,"distinct_frames":hashes.size(),"blank_frames":empty,"adjacent_repeats":repeated,"bounding_box_areas":areas,"sequence_sha256":sequence})
	# All frames and IDs must be covered; no GPU texture creation during this pass.
	if seen_ids.size()!=468 or total_frames!=5616:errors.append("reference coverage count")
	var p:Array=[Vector3.ZERO,Vector3(1,0,0),Vector3(1,2,0)]
	if field.combat_path_sample(p,0.0)!=p[0] or field.combat_path_sample(p,1.0)!=p[-1] or field.combat_path_sample(p,.5)!=p[1]:errors.append("path endpoints or waypoint")
	if field.combat_path_sample([],0.5)!=Vector3.ZERO or field.combat_path_sample([Vector3.ONE],.5)!=Vector3.ONE:errors.append("degenerate path")
	# Exercise more frames than the cache cap, then verify hot hits and exact normalization.
	for row in reports.slice(0,40):
		for frame in range(Field.FX_FRAME_COUNT):field.combat_animated_texture(str(row.id),frame)
	if field.fx_animated_cache.size()!=Field.FX_ANIMATED_CACHE_CAP or field.fx_animated_order.size()!=Field.FX_ANIMATED_CACHE_CAP:errors.append("animated cache cap")
	var probe:String=str(reports[39].id)
	if field.combat_animated_texture(probe,-1)!=field.combat_animated_texture(probe,Field.FX_FRAME_COUNT-1):errors.append("frame wrap or cache hit")
	if field.combat_animated_texture(probe,-1).get_image().get_data()!=field.combat_frame_image(probe,Field.FX_FRAME_COUNT-1).get_data():errors.append("normalized texture differs from frame")
	var report:Dictionary={"moves":seen_ids.size(),"frames":total_frames,"distinct_roles":roles.size(),"distinct_sequences":signatures.size(),"blank_interior_frames":blank_interior,"adjacent_repeats":repeated_adjacent,"cpu_render_usec":timing_usec,"animated_cache_entries":field.fx_animated_cache.size(),"raw_cache_bytes_upper_bound":Field.FX_ANIMATED_CACHE_CAP*Field.FX_FRAME_SIZE*Field.FX_FRAME_SIZE*4,"errors":errors,"moves_detail":reports}
	var output:=FileAccess.open(OUT+"/audit.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t"))
	output.close()
	field.free()
	print("KINDRIA_FULL_FX_AUDIT moves=",seen_ids.size()," frames=",total_frames," sequences=",signatures.size()," interior_blanks=",blank_interior," adjacent_repeats=",repeated_adjacent," errors=",errors)
	if errors.is_empty():
		print("KINDRIA_FULL_FX_AUDIT_PASS")
		quit(0)
	else:quit(1)
