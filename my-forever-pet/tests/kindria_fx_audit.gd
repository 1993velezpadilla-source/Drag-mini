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
	if field.combat_path_sample(p,0.0)!=p[0] or field.combat_path_sample(p,1.0)!=p[-1] or not field.combat_path_sample(p,1.0/3.0).is_equal_approx(p[1]) or not field.combat_path_sample(p,.5).is_equal_approx(Vector3(1,.5,0)):errors.append("path endpoints or waypoint")
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
	# Every profile's leading travel reaches the end at the same instant as
	# damage reaction. Trailing particles finish inside the effect lifetime.
	for row in reports:
		var peak:float=float(row.impact_fraction)
		var first:float=field.combat_travel_progress(0.0,peak)
		var impact:float=field.combat_travel_progress(peak,peak)
		if absf(first)>.001 or absf(impact-1.0)>.001:errors.append("travel impact sync "+str(row.id))
		var last:float=0.0
		for step in range(101):
			var progress:float=field.combat_travel_progress(float(step)/100.0,peak,.65)
			if progress<last or progress>1.0:errors.append("travel monotonic "+str(row.id))
			last=progress
		if absf(last-1.0)>.001:errors.append("travel tail incomplete "+str(row.id))
	print("KINDRIA_TRAVEL_IMPACT_AUDIT 468")
	# World launch sockets and actual target endpoints, including self-casts.
	var route:Array=field.combat_waypoints(Vector2i.ZERO,Vector2i(3,0),[Vector2i.ZERO,Vector2i(1,0),Vector2i(1,0)],.66,.8)
	if route.size()!=3 or not route[0].is_equal_approx(Vector3(0,.66,0)) or not route[-1].is_equal_approx(Vector3(4.2,.8,0)):errors.append("world socket path")
	var uneven:Array=[Vector3.ZERO,Vector3.RIGHT,Vector3.RIGHT*4.0]
	if not field.combat_path_sample(uneven,.5).is_equal_approx(Vector3.RIGHT*2.0):errors.append("distance weighted travel")
	var self_path:Array=field.combat_waypoints(Vector2i.ZERO,Vector2i.ZERO,[Vector2i.ZERO],.13,.13)
	if self_path.size()!=2 or not field.combat_path_sample(self_path,.5).is_equal_approx(Vector3(0,.13,0)):errors.append("self cast anchor")
	if absf(field.combat_socket_height("head",1.45,.13)-1.087)>.001 or absf(field.combat_socket_height("ground",1.45,.13)-.13)>.001:errors.append("scaled socket height")
	print("KINDRIA_WORLD_SOCKET_PASS")
	# Electrical beam extensions retain intermediate path corners.
	var corner:Array=[Vector3.ZERO,Vector3.RIGHT*2.0,Vector3(2,0,2)]
	for step in range(101):
		var progress:float=float(step)/100.0
		var prefix:Array=field.combat_path_prefix(corner,progress)
		if prefix.size()<2 or not prefix[-1].is_equal_approx(field.combat_path_sample(corner,progress)):errors.append("beam path prefix")
		if progress>.5 and prefix.size()!=3:errors.append("beam corner dropped")
	var full:Array=field.combat_path_prefix(corner,1.0)
	if full!=corner:errors.append("beam final endpoint")
	print("KINDRIA_ELECTRIC_PATH_PASS")
	# No stale attack timing for unrelated damage; tracked targets keep their
	# own hit counts, including targets moved away from the original tile.
	var reaction_profile:Dictionary={"duration":.8,"impact":.5}
	var direct:Dictionary=field.damage_reaction_spec(reaction_profile,true,3,true,Vector3.RIGHT)
	var displaced:Dictionary=field.damage_reaction_spec(reaction_profile,true,2,false,Vector3.LEFT)
	var unrelated:Dictionary=field.damage_reaction_spec(reaction_profile,true,0,false,Vector3.RIGHT)
	var old_cast:Dictionary=field.damage_reaction_spec(reaction_profile,false,4,true,Vector3.RIGHT)
	for spec in [direct,displaced]:
		if absf(float(spec.delay)-.4)>.001 or absf(float(spec.span)-.4)>.001:errors.append("linked reaction timing")
	if int(direct.count)!=3 or int(displaced.count)!=2:errors.append("per target reaction count")
	for spec in [unrelated,old_cast]:
		if float(spec.delay)!=0.0 or float(spec.span)!=0.0 or int(spec.count)!=1 or spec.direction!=Vector3.ZERO:errors.append("stale reaction timing")
	print("KINDRIA_TARGET_REACTION_PASS")
	# Response-turn snapshots distinguish removed, damaged and healed UIDs.
	var losses:Dictionary=Rules.visual_hp_losses({1:10,2:8,3:4,4:2},{1:7,3:5,4:2,5:9})
	if losses.size()!=2 or int(losses[1].before)!=10 or int(losses[1].after)!=7 or bool(losses[1].removed) or not bool(losses[2].removed):errors.append("response turn damage ledger")
	var mixed:=Node3D.new()
	mixed.set_meta("species","sporeling")
	field.queue_enemy_reaction(mixed,true,.84,Vector3.ZERO)
	field.queue_enemy_reaction(mixed,false,.4,Vector3.RIGHT,.4,3)
	if field.fx_reactions.size()!=4:errors.append("mixed reaction queue count")
	field.update_combat_reactions(.75)
	if str(mixed.get_meta("enemy_phase",""))!="hurt" or not mixed.get_meta("pending_defeat",false):errors.append("mixed reaction direct phase")
	field.update_combat_reactions(.12)
	if str(mixed.get_meta("enemy_phase",""))!="defeat":errors.append("mixed reaction terminal phase")
	mixed.free()
	print("KINDRIA_RESPONSE_DAMAGE_LEDGER_PASS")
	# Exact periodic events preserve separate causes and clamp overkill.
	var ledger=Rules.new()
	ledger.visual_response_active=true
	ledger.visual_record_response({"uid":7,"hp":5},2,"poison")
	ledger.visual_record_response({"uid":7,"hp":3},8,"nightmare")
	ledger.visual_record_response({"uid":8,"hp":0},8,"burn")
	ledger.visual_response_active=false
	ledger.visual_record_response({"uid":7,"hp":5},2,"wrap")
	var recorded:Array=ledger.visual_response_events.get(7,[])
	if recorded.size()!=2 or recorded[0].source!="poison" or int(recorded[1].amount)!=3 or ledger.visual_response_events.has(8):errors.append("periodic damage source ledger")
	print("KINDRIA_PERIODIC_SOURCE_LEDGER_PASS")
	ledger.visual_response_active=true
	ledger.visual_record_response({"uid":9,"hp":20},4,"sleep_counter",40,"eos_025")
	ledger.visual_record_response({"uid":9,"hp":16},5,"sleep_counter",41,"eos_025")
	ledger.visual_record_response({"uid":9,"hp":11},2,"poison")
	var sleep_events:Array=ledger.visual_response_events.get(9,[])
	var remaining:Array=field.remaining_response_events(sleep_events,41)
	if sleep_events.size()!=3 or remaining.size()!=2 or int(remaining[0].cast_serial)!=40 or remaining[1].source!="poison":errors.append("counter serial event attribution")
	if field.remaining_response_events(sleep_events,-1).size()!=3:errors.append("counter event preservation")
	print("KINDRIA_COUNTER_SERIAL_PASS")
	# Counter visuals use their own profile and true recorded route.
	var counter_plan:Array[Dictionary]=field.response_fx_plan([{"source":"sleep_counter","move_id":"eos_025","from":Vector2i.ZERO,"to":Vector2i(2,0),"path":[Vector2i(1,0),Vector2i(2,0)]},{"source":"poison"}],.3)
	var counter_profile:Dictionary=field.combat_profile("eos_025")
	if counter_plan.size()!=2 or absf(float(counter_plan[0].hit)-(.3+float(counter_profile.duration)*float(counter_profile.impact)))>.001 or counter_plan[0].event.path.size()!=2 or float(counter_plan[1].hit)<=float(counter_plan[0].hit):errors.append("counter effect plan")
	print("KINDRIA_COUNTER_FX_PLAN_PASS")
	# Body pose uses the same clock, role and aim as each replayed effect.
	var pose_profile:Dictionary=field.combat_profile("eos_025")
	var cast_sample:Dictionary=field.player_cast_sample("eos_025",Vector2i(2,2),Vector2i(1,2),.1)
	if not cast_sample.direction.is_equal_approx(Vector3.LEFT) or absf(float(cast_sample.remaining)-(float(pose_profile.duration)-.1))>.001 or absf(float(cast_sample.impact_delay)-maxf(0.0,float(pose_profile.duration)*float(pose_profile.impact)-.1))>.001:errors.append("counter body clock")
	if cast_sample.motion!=field.cast_motion_kind("eos_025",pose_profile):errors.append("counter body motion")
	print("KINDRIA_COUNTER_BODY_CLOCK_PASS")
	# A second target must wait for the already reserved body animation.
	var first_event:Dictionary={"source":"sleep_counter","move_id":"eos_025","from":Vector2i.ZERO,"to":Vector2i(2,0)}
	var other_event:Dictionary={"source":"sleep_counter","move_id":"eos_025","from":Vector2i.ZERO,"to":Vector2i(0,2)}
	field.delayed_combat_fx.clear()
	field.attack_time=.2
	var first_plan:Array[Dictionary]=field.response_fx_plan([first_event],0.0,field.response_cast_available_at())
	field.delayed_combat_fx.append({"delay":float(first_plan[0].launch),"event":first_plan[0].event})
	var second_plan:Array[Dictionary]=field.response_fx_plan([other_event,{"source":"poison"}],0.0,field.response_cast_available_at())
	var first_end:float=float(first_plan[0].launch)+float(pose_profile.duration)
	if float(first_plan[0].launch)<.199 or float(second_plan[0].launch)<first_end+.039:errors.append("cross-target body overlap")
	if second_plan[0].event.to!=Vector2i(0,2) or absf(float(second_plan[0].hit)-float(second_plan[0].launch)-float(pose_profile.duration)*float(pose_profile.impact))>.001:errors.append("cross-target impact timing")
	if float(second_plan[1].hit)<=float(second_plan[0].hit):errors.append("cross-target periodic ordering")
	var poison_only:Array[Dictionary]=field.response_fx_plan([{"source":"poison"}],0.0,field.response_cast_available_at())
	if float(poison_only[0].hit)!=0.0:errors.append("unrelated periodic damage delayed")
	field.delayed_combat_fx.clear()
	field.attack_time=0.0
	print("KINDRIA_CROSS_TARGET_BODY_TIMELINE_PASS")
	# Exhaustion preserves earlier effects and never reserves phantom animations.
	var crowded_events:Array=[]
	for i in range(Field.DELAYED_COMBAT_FX_CAP+3):
		crowded_events.append({"source":"sleep_counter","move_id":"eos_025","from":Vector2i.ZERO,"to":Vector2i(i+1,0)})
	var crowded_plan:Array[Dictionary]=field.response_fx_plan(crowded_events,.2,.5,2)
	var reserved:int=0
	for i in range(crowded_plan.size()):
		var item:Dictionary=crowded_plan[i]
		if not item.event.is_empty():
			reserved+=1
			if i>=2 or item.event.to!=Vector2i(i+1,0):errors.append("counter queue priority")
		elif float(item.launch)!=-1.0:errors.append("phantom counter launch")
		if i>0 and float(item.hit)<float(crowded_plan[i-1].hit):errors.append("counter overflow reaction order")
	if reserved!=2 or crowded_plan.size()!=crowded_events.size():errors.append("counter saturation accounting")
	var full_plan:Array[Dictionary]=field.response_fx_plan([first_event],.2,99.0,0)
	if not full_plan[0].event.is_empty() or absf(float(full_plan[0].hit)-.2)>.001:errors.append("saturated counter phantom delay")
	print("KINDRIA_COUNTER_QUEUE_SATURATION_PASS")
	# Slow frames cannot allow a delayed attack to interrupt the prior body pose.
	if field.delayed_cast_can_replay(.6,.15,.2,.1):errors.append("counter interrupts at historical launch")
	if not field.delayed_cast_can_replay(.6,.15,.2,.04):errors.append("counter rejects valid launch")
	if field.delayed_cast_can_replay(.1,.15,.2,0.0):errors.append("counter resurrects expired pose")
	if not field.delayed_cast_can_replay(.6,0.0,.2,.2):errors.append("counter rejects frame boundary")
	var tiny_actor:=Node3D.new()
	field.fx_reactions.clear()
	field.queue_enemy_reaction(tiny_actor,false,.0002)
	if field.fx_reactions.size()!=1 or absf(float(field.fx_reactions[0].delay)-.0002)>.000001:errors.append("submillisecond reaction clock")
	field.fx_reactions.clear()
	tiny_actor.free()
	print("KINDRIA_COUNTER_SUBFRAME_CLOCK_PASS")
	# Simulation serial order wins even when actors are traversed backwards.
	var early_counter:Dictionary=first_event.duplicate()
	early_counter["cast_serial"]=70
	var middle_counter:Dictionary=other_event.duplicate()
	middle_counter["cast_serial"]=71
	var late_counter:Dictionary=first_event.duplicate()
	late_counter["cast_serial"]=72
	var counter_responses:Dictionary={9:{"events":[middle_counter]},2:{"events":[early_counter,{"source":"poison"},late_counter]}}
	var slots:Dictionary=field.global_counter_slots(counter_responses,-1,.3,3)
	var reversed_slots:Dictionary=field.global_counter_slots({2:counter_responses[2],9:counter_responses[9]},-1,.3,3)
	if slots!=reversed_slots or not (float(slots[70])<float(slots[71]) and float(slots[71])<float(slots[72])):errors.append("global counter serial order")
	var early_plan:Array[Dictionary]=field.response_fx_plan(counter_responses[2].events,0.0,99.0,3,slots)
	var middle_plan:Array[Dictionary]=field.response_fx_plan(counter_responses[9].events,0.0,99.0,3,slots)
	if absf(float(early_plan[0].launch)-float(slots[70]))>.001 or absf(float(early_plan[2].launch)-float(slots[72]))>.001 or absf(float(middle_plan[0].launch)-float(slots[71]))>.001:errors.append("global counter reservation consumed")
	var scarce_slots:Dictionary=field.global_counter_slots(counter_responses,72,.3,1)
	if scarce_slots.has(72) or float(scarce_slots[70])<0.0 or float(scarce_slots[71])!=-1.0:errors.append("global counter capacity and immediate exclusion")
	print("KINDRIA_GLOBAL_COUNTER_ORDER_PASS")
	# Invisible targets cannot consume the last available render reservation.
	var visible_responses:Dictionary=field.eligible_counter_responses(counter_responses,{9:true})
	var visible_slots:Dictionary=field.global_counter_slots(visible_responses,-1,.3,1)
	if visible_responses.size()!=1 or visible_slots.size()!=1 or not visible_slots.has(71) or absf(float(visible_slots[71])-.3)>.001:errors.append("invisible counter reservation")
	# Equal-time hit and defeat must leave a terminal pose and no pending impact.
	var tied_actor:=Node3D.new()
	tied_actor.set_meta("species","sporeling")
	field.fx_reactions.clear()
	field.queue_enemy_reaction(tied_actor,true,.2,Vector3.RIGHT)
	field.queue_enemy_reaction(tied_actor,false,.2,Vector3.LEFT)
	field.update_combat_reactions(.3)
	if str(tied_actor.get_meta("enemy_phase",""))!="defeat" or tied_actor.get_meta("pending_impact",false) or tied_actor.get_meta("pending_defeat",false):errors.append("tied terminal reaction")
	if tied_actor.get_meta("enemy_hit_direction",Vector3.ZERO)!=Vector3.RIGHT:errors.append("tied terminal direction")
	field.fx_reactions.clear()
	tied_actor.free()
	print("KINDRIA_VISIBLE_COUNTER_TERMINAL_PASS")
	# A new floor may reuse a defeated enemy UID, but never its old combat ledger.
	var floor_rules=Rules.new()
	floor_rules.visual_turn_damage={0:{"events":[early_counter]}}
	floor_rules.visual_turn_damage_turn=12
	floor_rules.visual_response_events={0:[early_counter]}
	floor_rules.visual_response_active=true
	floor_rules.visual_response_cast_serial=70
	floor_rules.visual_response_cast_uid=0
	floor_rules.player_visual_hits={0:2}
	floor_rules.player_visual_hit_serial=70
	floor_rules.player_attack_cells.append(Vector2i(1,1))
	floor_rules.player_attack_path.append(Vector2i(1,1))
	floor_rules.reset_floor_combat_presentation()
	if not floor_rules.visual_turn_damage.is_empty() or floor_rules.visual_turn_damage_turn!=-1 or not floor_rules.visual_response_events.is_empty() or floor_rules.visual_response_active:errors.append("floor damage ledger leaked")
	if floor_rules.visual_response_cast_serial!=-1 or floor_rules.visual_response_cast_uid!=-1 or floor_rules.player_visual_hit_serial!=-1 or not floor_rules.player_visual_hits.is_empty():errors.append("floor counter identity leaked")
	if not floor_rules.player_attack_cells.is_empty() or not floor_rules.player_attack_path.is_empty() or not floor_rules.enemy_actions.is_empty():errors.append("floor attack geometry leaked")
	print("KINDRIA_FLOOR_COUNTER_ISOLATION_PASS")
	# Every motion family returns to its resting scale and crosses impact smoothly.
	for motion in ["rush","contact","aerial","down","lash","spin","focus","gesture","cast"]:
		for peak in [.12,.35,.5,.88]:
			var body_start:Dictionary=PixelArt.attack_body_sample(0.0,peak,motion)
			var body_end:Dictionary=PixelArt.attack_body_sample(1.0,peak,motion)
			var body_before:Dictionary=PixelArt.attack_body_sample(peak-.0001,peak,motion)
			var body_after:Dictionary=PixelArt.attack_body_sample(peak+.0001,peak,motion)
			if absf(float(body_start.stretch)-1.0)>.001 or absf(float(body_end.stretch)-1.0)>.001 or absf(float(body_end.lift))>.001:errors.append("body rest boundary "+motion)
			if absf(float(body_before.stretch)-float(body_after.stretch))>.002:errors.append("body impact discontinuity "+motion)
	var rush_body:Dictionary=PixelArt.attack_body_sample(.25,.5,"rush")
	var focus_body:Dictionary=PixelArt.attack_body_sample(.25,.5,"focus")
	if float(rush_body.stretch)>=float(focus_body.stretch):errors.append("body motion distinction")
	print("KINDRIA_BODY_CONTINUITY_PASS")
	# Aerial and downward attacks land at the move's own impact beat.
	for peak in [.12,.25,.48,.7,.88]:
		for motion in ["aerial","down"]:
			var apex:Vector3=field.cast_motion_offset(motion,peak*.5,peak)
			var landing:Vector3=field.cast_motion_offset(motion,peak,peak)
			var recovery:Vector3=field.cast_motion_offset(motion,peak+(1.0-peak)*.5,peak)
			if apex.y<.29 or absf(landing.y)>.001 or absf(recovery.y)>.001:errors.append("airborne landing timing "+motion)
			if landing.x<.19 or recovery.x>=landing.x:errors.append("landing forward recovery "+motion)
	print("KINDRIA_AERIAL_LANDING_PASS")
	# The live enemy sprite and transformed companion consume the shared body curve.
	var body_actor:=Node3D.new()
	body_actor.set_meta("species","sporeling")
	var body_sprite:=Sprite3D.new()
	body_sprite.name="EnemyPixel"
	body_actor.add_child(body_sprite)
	field.player_cast_motion="rush"
	field.player_cast_duration=.8
	field.player_cast_impact=.5
	field.attack_time=.6
	field.sync_disguise_pose(body_actor,"attack",Vector2.RIGHT)
	field.update_enemy_pixel(body_actor,0.0,Vector3.ZERO)
	var expected_body:Dictionary=PixelArt.attack_body_sample(.25,.5,"rush")
	if absf(body_sprite.scale.y-float(expected_body.stretch))>.001 or body_actor.get_meta("enemy_cast_motion")!="rush":errors.append("disguise body runtime curve")
	field.sync_disguise_pose(body_actor,"idle",Vector2.RIGHT)
	field.update_enemy_pixel(body_actor,0.0,Vector3.ZERO)
	if not body_sprite.scale.is_equal_approx(Vector3.ONE):errors.append("enemy body scale recovery")
	body_actor.free()
	print("KINDRIA_SHARED_BODY_RUNTIME_PASS")
	# Shadows track the attack direction without floating with the body.
	var ground_shadow:Dictionary=field.enemy_shadow_sample(Vector3.ZERO,0.0,0.0,1.0,false)
	var jump_shadow:Dictionary=field.enemy_shadow_sample(Vector3(.3,.6,-.2),0.0,0.0,1.0,false)
	var disguise_shadow:Dictionary=field.enemy_shadow_sample(Vector3.ZERO,.1,.6,1.45,true)
	if not Vector3(jump_shadow.position).is_equal_approx(Vector3(.3,.035,-.2)):errors.append("jump shadow ground projection")
	if float(jump_shadow.scale.x)>=float(ground_shadow.scale.x):errors.append("jump shadow altitude")
	if absf(float(disguise_shadow.position.y)+.6-.035)>.001:errors.append("disguise shadow ground height")
	if absf(float(disguise_shadow.scale.x)/float(disguise_shadow.scale.y)-1.15/.8)>.001:errors.append("wide shadow proportions")
	print("KINDRIA_COMBAT_SHADOW_PASS")
	# Socket altitude follows actual flight, not sprite squash/stretch.
	var socket_actor:=Node3D.new()
	var socket_sprite:=Sprite3D.new()
	socket_sprite.name="EnemyPixel"
	socket_actor.add_child(socket_sprite)
	socket_actor.set_meta("enemy_size_multiplier",1.45)
	socket_sprite.scale.y=1.12
	socket_sprite.position.y=.54*1.45*1.12+.2
	if absf(field.combat_actor_socket(socket_actor,"head")-(.66*1.45+.2))>.001:errors.append("deformed socket altitude")
	socket_actor.set_meta("companion_disguise",true)
	socket_actor.position.y=.6
	if absf(field.combat_actor_socket(socket_actor,"head")-(.66*1.45+.8))>.001:errors.append("transformed aerial socket")
	if absf(field.combat_actor_socket(socket_actor,"ground")-.13)>.001:errors.append("ground socket altitude")
	socket_actor.free()
	print("KINDRIA_DYNAMIC_SOCKET_PASS")
	# Deferred geometry is immutable even when actor nodes or source arrays change.
	var frozen_source:=Node3D.new()
	var frozen_target:=Node3D.new()
	frozen_target.set_meta("enemy_size_multiplier",1.45)
	var historical_event:Dictionary={"fx":"eos_025","from":Vector2i.ZERO,"to":Vector2i(2,0),"path":[Vector2i(1,0),Vector2i(2,0)]}
	var frozen:Dictionary=field.snapshot_counter_geometry(historical_event,frozen_source,frozen_target)
	frozen_target.set_meta("enemy_size_multiplier",.5)
	historical_event.path.clear()
	frozen_source.free()
	frozen_target.free()
	if absf(float(frozen.target_height)-.45*1.45)>.001 or frozen.path.size()!=2:errors.append("historical counter geometry")
	var frozen_points:Array=field.combat_waypoints(frozen.from,frozen.to,frozen.path,float(frozen.source_height),float(frozen.target_height))
	if frozen_points.size()!=3 or absf(float(frozen_points[-1].y)-.45*1.45)>.001:errors.append("historical counter endpoint")
	print("KINDRIA_FROZEN_COUNTER_GEOMETRY_PASS")
	# Reverse render order must not replace a later impact with an earlier hit.
	var older_hit:Dictionary={"age":.65,"duration":1.0,"profile":{"impact":.5},"points":[Vector3.ZERO,Vector3.RIGHT]}
	var newer_hit:Dictionary={"age":.53,"duration":1.0,"profile":{"impact":.5},"points":[Vector3.ZERO,Vector3.FORWARD]}
	var latest:Dictionary=field.latest_player_impact({},newer_hit)
	latest=field.latest_player_impact(latest,older_hit)
	if absf(float(latest.age)-.03)>.001 or latest.direction!=Vector3.FORWARD:errors.append("player impact reverse iteration")
	var reversed:Dictionary=field.latest_player_impact(field.latest_player_impact({},older_hit),newer_hit)
	if reversed!=latest:errors.append("player impact iteration dependence")
	older_hit.age=.9
	if not field.latest_player_impact({},older_hit).is_empty():errors.append("expired player hurt resurrected")
	field.hit_time=.24+.1-float(latest.age)
	field.advance_player_combat_clock(.1)
	if absf(field.hit_time-.21)>.001:errors.append("player hit subframe duration")
	print("KINDRIA_LATEST_PLAYER_IMPACT_PASS")
	# An impact near the end of a slow frame starts its reaction at the correct age.
	var subframe_actor:=Node3D.new()
	subframe_actor.set_meta("species","sporeling")
	var subframe_sprite:=Sprite3D.new()
	subframe_sprite.name="EnemyPixel"
	subframe_actor.add_child(subframe_sprite)
	field.fx_reactions.clear()
	field.queue_enemy_reaction(subframe_actor,false,.09,Vector3.RIGHT)
	field.update_combat_reactions(.1)
	field.update_enemy_pixel(subframe_actor,.1,Vector3.ZERO)
	if absf(float(subframe_actor.get_meta("enemy_clock"))-.01)>.001 or subframe_actor.get_meta("enemy_phase")!="hurt":errors.append("enemy subframe hurt age")
	field.enemy_pose(subframe_actor,"attack",.2,Vector2.RIGHT)
	field.update_enemy_pixel(subframe_actor,.25,Vector3.ZERO)
	if subframe_actor.get_meta("enemy_phase")!="recover" or absf(float(subframe_actor.get_meta("enemy_clock"))-.05)>.001:errors.append("enemy recovery overshoot")
	field.update_enemy_pixel(subframe_actor,.10,Vector3.ZERO)
	if subframe_actor.get_meta("enemy_phase")!="idle" or absf(float(subframe_actor.get_meta("enemy_clock"))-.03)>.001:errors.append("enemy idle overshoot")
	subframe_actor.free()
	print("KINDRIA_ENEMY_SUBFRAME_REACTION_PASS")
	# Retired visual bursts retain their impact time without retaining textures.
	field.retired_impacts.clear()
	var evicted:Dictionary={"id":"basic_strike","age":.1,"duration":.6,"profile":field.combat_profile("basic_strike").duplicate(),"points":[Vector3.ZERO,Vector3.RIGHT],"target_player":true,"damage":3,"impacted":false,"texture":null,"results":{},"impact_waves":[{}],"impact_times":[.3],"impact_cursor":0}
	evicted.profile.impact=.5
	field.retire_combat_burst(evicted)
	if field.retired_impacts.size()!=1 or field.retired_impacts[0].has("texture"):errors.append("retired impact storage")
	if not field.update_retired_impacts(.1).is_empty() or field.retired_impacts.size()!=1:errors.append("retired impact early")
	var retired_hit:Dictionary=field.update_retired_impacts(.15)
	if retired_hit.is_empty() or absf(float(retired_hit.get("age",-1))-.05)>.001 or retired_hit.get("direction")!=Vector3.RIGHT or not field.retired_impacts.is_empty():errors.append("retired impact clock")
	evicted.impacted=true
	evicted.impact_cursor=1
	field.retire_combat_burst(evicted)
	if not field.retired_impacts.is_empty():errors.append("retired impact duplicated")
	print("KINDRIA_RETIRED_IMPACT_PASS")
	# A cast created by path movement after the frame clock must start at zero age.
	field.attack_time=.4
	field.player_impact_delay=.2
	field.advance_player_combat_clock(.016)
	if absf(field.attack_time-.384)>.001 or absf(field.player_impact_delay-.184)>.001:errors.append("existing cast clock step")
	var fresh_event:Dictionary={"fx":"eos_025","from":Vector2i.ZERO,"to":Vector2i.RIGHT}
	field.begin_player_cast_pose(fresh_event)
	var fresh_profile:Dictionary=field.combat_profile("eos_025")
	if absf(field.attack_time-float(fresh_profile.duration))>.001 or absf(field.player_impact_delay-float(fresh_profile.duration)*float(fresh_profile.impact))>.001:errors.append("fresh movement cast clock")
	field.advance_player_combat_clock(.016)
	if absf(field.attack_time-float(fresh_profile.duration)+.016)>.001:errors.append("next movement cast clock")
	field.attack_time=0.0
	field.player_impact_delay=0.0
	print("KINDRIA_MOVEMENT_CAST_CLOCK_PASS")
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
