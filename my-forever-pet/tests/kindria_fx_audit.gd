extends SceneTree
const Field=preload("res://dungeon_view.gd")
const Rules=preload("res://dungeon_rules.gd")
const PixelArt=preload("res://pixel_pet_art.gd")
const Parts=preload("res://pet_part_rig.gd")
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
	# Actor pose contracts: no movement at boundaries, exact contact peak, rotated directions.
	var motion_counts:Dictionary={}
	for row in reports:
		var id:String=str(row.id)
		var profile:Dictionary=field.combat_profile(id)
		var kind:String=field.cast_motion_kind(id,profile)
		motion_counts[kind]=int(motion_counts.get(kind,0))+1
		var peak:float=clampf(float(profile.impact),.12,.88)
		var pre:Dictionary=PixelArt.attack_pose_sample(peak-.001,peak)
		var hit:Dictionary=PixelArt.attack_pose_sample(peak,peak)
		var end:Dictionary=PixelArt.attack_pose_sample(1.0,peak)
		if pre.phase!="windup" or hit.phase!="strike" or end.phase!="recover" or int(hit.frame)!=1 or absf(float(hit.pulse)-1.0)>.001:errors.append("actor frame timing "+id)
		var order:int=0
		for sample_index in range(101):
			var sample:Dictionary=PixelArt.attack_pose_sample(float(sample_index)/100.0,peak)
			var phase_index:int=["windup","strike","recover"].find(sample.phase)
			if phase_index<order:errors.append("actor phase reversed "+id)
			order=phase_index
		row["actor_motion"]=kind
		row["actor_pose_phases"]=["windup","strike","recover"]
		var start:Vector3=field.cast_motion_offset(kind,0.0,float(profile.impact))
		var finish:Vector3=field.cast_motion_offset(kind,1.0,float(profile.impact))
		if start.length()>.001 or finish.length()>.001:errors.append("actor motion boundary "+id)
		for frame in range(13):
			var offset:Vector3=field.cast_motion_offset(kind,float(frame)/12.0,float(profile.impact))
			if not offset.is_finite() or offset.length()>1.0:errors.append("invalid actor motion "+id)
	var contact:Vector3=field.cast_motion_offset("contact",.48,.48)
	if absf(contact.x-.40)>.001:errors.append("contact not synchronized")
	if field.cast_offset_world(Vector3(1,0,0),Vector3(0,0,-1))!=Vector3(0,0,-1):errors.append("north facing")
	if field.cast_offset_world(Vector3(1,0,0),Vector3(-1,0,0))!=Vector3(-1,0,0):errors.append("west facing")
	if motion_counts.size()<6:errors.append("too few actor motion families")
	print("KINDRIA_ACTOR_MOTION_AUDIT ",motion_counts)
	# Multi-hit presentation must preserve timing order and remain within the cast.
	for row in reports:
		for count in [1,2,5,10]:
			var times:Array[float]=field.reaction_times(float(row.duration_seconds),float(row.impact_fraction),count)
			if times.size()!=count or absf(times[0]-float(row.duration_seconds)*float(row.impact_fraction))>.001:errors.append("reaction timing "+str(row.id))
			for i in range(1,times.size()):
				if times[i]<times[i-1] or times[i]>float(row.duration_seconds)+.001:errors.append("reaction order "+str(row.id))
	var actor:=Node3D.new()
	actor.set_meta("species","sporeling")
	field.queue_enemy_reaction(actor,false,.1,Vector3.RIGHT,.2,3)
	field.queue_enemy_reaction(actor,true,.1,Vector3.RIGHT,.2,3)
	if field.fx_reactions.size()!=3 or not actor.get_meta("pending_defeat",false):errors.append("defeat promotion")
	field.update_combat_reactions(.15)
	if str(actor.get_meta("enemy_phase"))!="hurt" or not actor.get_meta("pending_impact",false):errors.append("first hit phase")
	field.update_combat_reactions(.4)
	if str(actor.get_meta("enemy_phase"))!="defeat" or actor.get_meta("pending_impact",true):errors.append("final defeat phase")
	actor.free()
	print("KINDRIA_REACTION_TIMING_AUDIT 468")
	# Synthetic colored fixtures validate the layer contract, not production artwork.
	var body:=Image.create(64,64,false,Image.FORMAT_RGBA8)
	body.fill(Color.TRANSPARENT)
	body.fill_rect(Rect2i(28,28,8,8),Color.WHITE)
	var strip:=Image.create(128,256,false,Image.FORMAT_RGBA8)
	for dir in range(4):
		for frame in range(2):
			strip.fill_rect(Rect2i(frame*64,dir*64,64,64),Color(float(dir+1)/5.0,float(frame+1)/3.0,.25,1.0))
	var hurt:=Image.create(64,64,false,Image.FORMAT_RGBA8)
	hurt.fill(Color.BLUE)
	var part:Dictionary={"slot":"tail","back":strip,"size":64,"clips":{"attack:weak":{"back":hurt}}}
	for dir in range(4):
		var first:Image=Parts.composite_pose(body,[part],dir,"attack","healthy",0.0)
		var last:Image=Parts.composite_pose(body,[part],dir,"attack","healthy",1.0)
		var weak:Image=Parts.composite_pose(body,[part],dir,"attack","weak",.5)
		if first.get_data()==last.get_data() or weak.get_pixel(1,1)!=Color.BLUE or weak.get_pixel(32,32)!=Color.WHITE:errors.append("anatomy layer contract "+str(dir))
		var expected:Image=Parts.lpc_frame(strip,dir,0)
		if first.get_pixel(1,1)!=expected.get_pixel(1,1):errors.append("anatomy direction "+str(dir))
	if Parts.clip_index(strip,1.0,true)!=0 or Parts.clip_index(strip,1.0,false)!=1:errors.append("anatomy loop vs one-shot")
	print("KINDRIA_PART_RIG_CONTRACT_PASS")
	# Exercise the exact texture composition path with a fixture, then restore
	# production registry. No synthetic fixture is installed into game assets.
	var saved_manifest:Dictionary=PixelArt.part_manifest
	var saved_checked:bool=PixelArt.part_manifest_checked
	PixelArt.part_manifest_checked=true
	PixelArt.part_manifest={"fixture":[part]}
	var unchanged:Image=PixelArt.compose_creature_cell("missing",body,0,"attack",1)
	var layered:Image=PixelArt.compose_creature_cell("fixture",body,0,"attack",1,"weak")
	if unchanged.get_data()!=body.get_data() or layered.get_pixel(1,1)!=Color.BLUE:errors.append("runtime part registry")
	if not Parts.load_manifest("res://nonexistent_parts_fixture.json").is_empty():errors.append("missing manifest fallback")
	PixelArt.part_manifest=saved_manifest
	PixelArt.part_manifest_checked=saved_checked
	var offsets:Dictionary=Parts.parse_offsets({"0":[4,8],"3":[-4,8],"9":[1,1],"bad":[0,0]},true)
	if offsets.size()!=2 or offsets.get(0)!=Vector2i(4,8) or offsets.get(3)!=Vector2i(-4,8):errors.append("direction manifest offsets")
	var mood_offsets:Dictionary=Parts.parse_offsets({"weak":[0,3],"unknown":[0,0],"happy":[1]},false)
	if mood_offsets.size()!=1 or mood_offsets.get("weak")!=Vector2i(0,3):errors.append("mood manifest offsets")
	print("KINDRIA_PART_RUNTIME_ROUTE_PASS")
	# Reuse actual native anatomical cells, not synthetic external overlays.
	var native_checks:int=0
	for species in PixelArt.NATIVE_HOVER_CYCLES:
		var hz:float=float(PixelArt.NATIVE_HOVER_CYCLES[species])
		for dir in range(4):
			var sheet:=Image.create(192,48,false,Image.FORMAT_RGBA8)
			sheet.fill(Color.TRANSPARENT)
			var distinct:Dictionary={}
			for frame in range(4):
				var time:float=(float(frame)+.25)/hz
				var idle:Dictionary=PixelArt.enemy_locomotion_sample(species,"idle",time)
				var moving:Dictionary=PixelArt.enemy_locomotion_sample(species,"walk",time)
				if idle!=moving or idle.pose!="walk" or int(idle.frame)!=frame:errors.append("native hover phase "+species)
				var native:Image=PixelArt.enemy_asset_cell(species,dir,"walk",frame)
				distinct[digest(native.get_data())]=true
				sheet.blit_rect(native,Rect2i(0,0,48,48),Vector2i(frame*48,0))
				native_checks+=1
			if distinct.size()<2:errors.append("static native hover "+species+" "+str(dir))
			if sheet.save_png(OUT+"/native-hover-"+species+"-"+str(dir)+".png")!=OK:errors.append("native hover PNG")
		for state in ["windup","attack","recover","hurt","defeat"]:
			if PixelArt.enemy_locomotion_sample(species,state,.5).pose!=state:errors.append("native hover overrides combat "+species)
	if PixelArt.enemy_locomotion_sample("bramble_pup","idle",.6).pose!="idle":errors.append("grounded creature idle changed")
	print("KINDRIA_NATIVE_HOVER_AUDIT species=",PixelArt.NATIVE_HOVER_CYCLES.size()," frames=",native_checks)
	# Grounded companion cadence and health-driven native mood variants.
	for mood_name in ["healthy","happy","weak","sick","sad"]:
		var speed:float=6.5 if mood_name in ["weak","sick","sad"] else 10.0
		for frame in range(4):
			var gait:Dictionary=PixelArt.grounded_gait_sample((float(frame)+.25)/speed,mood_name)
			if int(gait.frame)!=frame or float(gait.lift)>.016 or float(gait.stretch)<1.0:errors.append("grounded gait "+mood_name)
	if PixelArt.dungeon_mood(5,30,false,false)!="weak" or PixelArt.dungeon_mood(30,30,true,true)!="sick" or PixelArt.dungeon_mood(30,30,false,true)!="happy":errors.append("dungeon mood priority")
	var companion:=Node3D.new()
	companion.set_meta("dungeon_grounded_gait",true)
	var sprite:=PixelArt.world_sprite(companion,0)
	PixelArt.animate_world_sprite(companion,Vector2.RIGHT,true,.15)
	var before:float=float(sprite.get_meta("anim_clock"))
	PixelArt.animate_world_sprite(companion,Vector2.UP,true,.02)
	if float(sprite.get_meta("anim_clock"))<=before or int(sprite.get_meta("facing"))!=1:errors.append("companion corner gait reset")
	companion.free()
	print("KINDRIA_GROUNDED_GAIT_PASS")
	# Transformed companions use the same exact clock across short/long casts.
	var disguise:=Node3D.new()
	disguise.set_meta("species","nebulwing")
	for duration in [.18,.44,1.2]:
		field.player_cast_duration=duration
		field.player_cast_impact=.56
		for progress in [.1,.56,.9]:
			field.attack_time=duration*(1.0-progress)
			if not field.sync_disguise_pose(disguise,"attack",Vector2.LEFT):errors.append("disguise attack clock")
			if absf(float(disguise.get_meta("enemy_clock"))/duration-progress)>.001 or int(disguise.get_meta("enemy_facing"))!=2:errors.append("disguise phase direction")
			if absf(float(disguise.get_meta("enemy_cast_impact"))-.56)>.001:errors.append("disguise impact fraction")
	field.hit_time=.12
	if not field.sync_disguise_pose(disguise,"hurt",Vector2.DOWN) or absf(float(disguise.get_meta("enemy_clock"))-.12)>.001:errors.append("disguise hurt clock")
	if field.sync_disguise_pose(disguise,"idle",Vector2.DOWN) or disguise.get_meta("enemy_phase")!="idle":errors.append("disguise recovery")
	disguise.free()
	print("KINDRIA_DISGUISE_CLOCK_PASS")
	# Charged visual states follow the rules' actual release and impact.
	for impact in [.2,.48,.8]:
		for phase in ["airborne","underground","vanish","gather"]:
			var hold:Dictionary=field.charge_visual_sample(phase,false,0.0,impact)
			var start:Dictionary=field.charge_visual_sample(phase,true,0.0,impact)
			var hit:Dictionary=field.charge_visual_sample(phase,true,impact,impact)
			var end:Dictionary=field.charge_visual_sample(phase,true,1.0,impact)
			if bool(hold.visible)!=(phase not in ["underground","vanish"]) or bool(start.visible)!=bool(hold.visible):errors.append("charge visibility "+phase)
			if not bool(hit.visible) or not bool(end.visible) or absf(float(hit.height))>.001 or absf(float(end.height))>.001:errors.append("charge impact "+phase)
			if phase=="airborne" and absf(float(start.height)-.95)>.001:errors.append("airborne release continuity")
	print("KINDRIA_CHARGE_VISUAL_PASS")
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
