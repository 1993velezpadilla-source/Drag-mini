extends SceneTree
# Run after import: godot --headless --path . --script res://cinematic_gauntlet.gd
const Art=preload("res://pixel_pet_art.gd")
const Dungeon=preload("res://dungeon_view.gd")
const Home=preload("res://live_pet_stage.gd")

func _initialize()->void:
	call_deferred("run_checks")

# V20.1: compact, amplitude-normalized descriptors for review, not a
# perceptual equivalence claim. Exact PCM digest is tracked separately.
func audio_quality_metrics(pcm:PackedByteArray)->Dictionary:
	var count:int=int(pcm.size()/2)
	var energy:float=0.0
	var mean:float=0.0
	var peak:float=0.0
	var max_step:float=0.0
	var crossings:int=0
	var last:float=0.0
	var bins:Array[float]=[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
	for i in range(count):
		var value:float=float(pcm.decode_s16(i*2))/32767.0
		energy+=value*value
		mean+=value
		peak=maxf(peak,absf(value))
		max_step=maxf(max_step,absf(value-last))
		if i>0 and (value>=0.0)!=(last>=0.0):crossings+=1
		last=value
		bins[mini(7,int(float(i)*8.0/maxi(1,count)))]+=value*value
	var descriptor:Array[int]=[]
	for bin in bins:descriptor.append(roundi(20.0*bin/maxf(.000001,energy)))
	var rms:float=sqrt(energy/maxi(1,count))
	return {"rms":rms,"dc":mean/maxi(1,count),"peak":peak,"max_step":max_step,"crossings_per_second":float(crossings)*22050.0/maxi(1,count),"descriptor":str(descriptor)+":"+str(roundi(float(crossings)*22050.0/maxi(1,count)/100.0))+":"+str(roundi(float(count)/22050.0*20.0)),"pcm_sha256":pcm.hex_encode().sha256_text()}

func run_checks()->void:
	var checks:int=0
	var failures:Array[String]=[]
	var view:=Dungeon.new()
	# V25.6: stage diagnostics use exactly the same accepted intervals.
	var frame_probe:=Dungeon.new()
	frame_probe.fx_diag_sample(1000000,100,true,200,300,650)
	frame_probe.fx_diag_sample(1016667,110,true,220,330,710)
	if frame_probe.fx_diag_intervals!=PackedInt64Array([16667]):failures.append("V25.6 interval")
	if frame_probe.fx_diag_cpu!=PackedInt64Array([110]):failures.append("V25.6 combat CPU")
	if frame_probe.fx_diag_world!=PackedInt64Array([220]):failures.append("V25.6 world CPU")
	if frame_probe.fx_diag_actor!=PackedInt64Array([330]):failures.append("V25.6 actor CPU")
	if frame_probe.fx_diag_full!=PackedInt64Array([710]):failures.append("V25.6 full CPU")
	frame_probe.fx_diag_sample(1500000,120,true,240,360,750)
	if frame_probe.fx_diag_gaps!=1 or frame_probe.fx_diag_full.size()!=1:failures.append("V25.6 suspended interval excluded")
	frame_probe.fx_diag_sample(1516667,130,false,260,390,800)
	frame_probe.fx_diag_sample(1533334,140,false,280,420,850)
	if frame_probe.fx_diag_full!=PackedInt64Array([710,800]):failures.append("V25.6 inactive interval excluded")
	var frame_stats:Dictionary=frame_probe.fx_diag_stats(frame_probe.fx_diag_full)
	if int(frame_stats.get("samples",0))!=2 or int(frame_stats.get("max_usec",0))!=800:failures.append("V25.6 summary")
	checks+=8
	frame_probe.free()
	# V25.5: compare prebuilt quad topology against the original append order.
	var quad_probe:=Dungeon.new()
	quad_probe.warm_fx_quad_indices()
	var quad_expected:=PackedInt32Array()
	for quad_count in range(1002):
		if quad_probe.fx_quad_indices(quad_count*4)!=quad_expected:failures.append("V25.5 topology "+str(quad_count))
		checks+=1
		var quad_base:int=quad_count*4
		quad_expected.append_array(PackedInt32Array([quad_base,quad_base+1,quad_base+2,quad_base,quad_base+2,quad_base+3]))
	var quad_overflow:int=int(quad_probe.fx_quad_index_prefix.size()/6)+1
	var quad_overflow_expected:=PackedInt32Array()
	for quad_i in range(quad_overflow):
		var quad_b:int=quad_i*4
		quad_overflow_expected.append_array(PackedInt32Array([quad_b,quad_b+1,quad_b+2,quad_b,quad_b+2,quad_b+3]))
	if quad_probe.fx_quad_indices(quad_overflow*4)!=quad_overflow_expected:failures.append("V25.5 topology overflow")
	checks+=1
	quad_probe.free()
	# V25.4: every fixed particle layout must reproduce the old scalar math.
	var layout_probe:=Dungeon.new()
	layout_probe.warm_particle_layouts()
	if layout_probe.fx_particle_layouts.size()!=27:failures.append("V25.4 layout table size")
	checks+=1
	for layout_count in range(27):
		var layout_values:PackedFloat64Array=layout_probe.combat_particle_layout(layout_count)
		if layout_values.size()!=layout_count*4:failures.append("V25.4 layout length")
		checks+=1
		for layout_i in range(layout_count):
			var layout_fraction:float=float(layout_i)/maxi(1,layout_count-1)
			var layout_angle:float=layout_fraction*TAU+float(layout_i)*2.399
			var layout_offset:int=layout_i*4
			if layout_values[layout_offset]!=layout_fraction:failures.append("V25.4 fraction")
			if layout_values[layout_offset+1]!=layout_angle:failures.append("V25.4 angle")
			if layout_values[layout_offset+2]!=cos(layout_angle):failures.append("V25.4 cosine")
			if layout_values[layout_offset+3]!=sin(layout_angle):failures.append("V25.4 sine")
			checks+=4
	var layout_repeat:PackedFloat64Array=layout_probe.combat_particle_layout(14)
	if layout_repeat!=layout_probe.build_particle_layout(14):failures.append("V25.4 layout cache changed")
	if layout_probe.combat_particle_layout(28)!=layout_probe.build_particle_layout(28):failures.append("V25.4 layout fallback")
	checks+=2
	layout_probe.free()
	# V25.3: identical cue values, shared immutable storage and local playback state.
	var launch_probe:=Dungeon.new()
	for launch_id in ["basic_strike","eos_008","eos_156","eos_477","leaf_dart"]:
		var launch_expected:Array=launch_probe.combat_environment_audio_plan(launch_id,launch_probe.combat_profile(launch_id))
		var launch_cached:Array=launch_probe.combat_cached_environment_audio_plan(launch_id)
		if launch_cached!=launch_expected:failures.append("V25.3 cue equivalence "+launch_id)
		if not is_same(launch_cached,launch_probe.combat_cached_environment_audio_plan(launch_id)):failures.append("V25.3 cue reuse "+launch_id)
		if not launch_cached.is_read_only():failures.append("V25.3 mutable cue array "+launch_id)
		for launch_cue in launch_cached:
			if not launch_cue.is_read_only():failures.append("V25.3 mutable cue record "+launch_id)
			checks+=1
		var launch_a:Dictionary={"environment_audio":launch_cached,"environment_audio_cursor":0}
		var launch_b:Dictionary={"environment_audio":launch_cached,"environment_audio_cursor":0}
		launch_a.environment_audio_cursor=1
		if launch_b.environment_audio_cursor!=0:failures.append("V25.3 shared cursor "+launch_id)
		checks+=4
	launch_probe.free()
	# V25.2: warming predicts playback keys without advancing variant counters.
	var audio_warm_probe:=Dungeon.new()
	audio_warm_probe.fx_audio_counter["probe_a:launch"]=2
	audio_warm_probe.fx_audio_counter["probe_a:impact"]=0
	audio_warm_probe.fx_audio_counter["probe_a:miss"]=1
	var audio_warm_before:Dictionary=audio_warm_probe.fx_audio_counter.duplicate()
	var audio_warm_keys:Array[String]=audio_warm_probe.combat_floor_audio_keys(["probe_a","probe_b"])
	if audio_warm_keys!=["probe_a:launch:0","probe_a:impact:1","probe_a:miss:2","probe_a:status:0","probe_b:launch:0","probe_b:impact:0","probe_b:miss:0","probe_b:status:0"]:failures.append("V25.2 predicted PCM variants")
	if audio_warm_probe.fx_audio_counter!=audio_warm_before:failures.append("V25.2 playback rotation altered")
	var audio_warm_ids:Array[String]=[]
	for audio_warm_i in range(100):audio_warm_ids.append("probe_"+str(audio_warm_i))
	if audio_warm_probe.combat_floor_audio_keys(audio_warm_ids).size()!=Dungeon.FX_AUDIO_CACHE_CAP:failures.append("V25.2 warm cap")
	audio_warm_probe.fx_audio_pack_checked=true
	audio_warm_probe.combat_warm_floor_audio(audio_warm_ids)
	if not audio_warm_probe.fx_audio_cache.is_empty() or audio_warm_probe.fx_floor_audio_warm_count!=0:failures.append("V25.2 missing pack synthesized")
	checks+=4
	audio_warm_probe.free()
	# V24.9: shared world math must preserve deterministic spawn and response selection.
	var world_probe:=Dungeon.new()
	var world_rng:=RandomNumberGenerator.new()
	world_probe.ambient_origins.resize(1)
	world_probe.ambient_ages.resize(1)
	for world_seed in [7,42,731]:
		world_rng.seed=world_seed
		world_probe.ambient_rng.seed=world_seed
		for world_initial in [true,false,true,false]:
			var world_center:=Vector3(2.5,0,-3.0)
			var world_expected_origin:Vector3=world_center+Vector3(world_rng.randf_range(-5.5,5.5),0,world_rng.randf_range(-6.0,5.0))
			var world_expected_age:float=world_rng.randf_range(0.0,4.5) if world_initial else 0.0
			world_probe.ambient_spawn_at(0,world_center,world_initial)
			if world_probe.ambient_origins[0]!=world_expected_origin:failures.append("V24.9 deterministic ambient origin")
			if not is_equal_approx(world_probe.ambient_ages[0],world_expected_age):failures.append("V24.9 deterministic ambient age")
			checks+=2
	for world_trial in range(20):
		var world_marks:Array=[]
		for world_index in range(8):
			world_marks.append({"at":Vector3(world_index,0,world_trial),"age":float((world_index*7+world_trial)%13)*.1,"life":1.0,"element":["fire","water","flying","ice"][world_index%4],"terrain_only":world_index%2==0,"color":Color(float(world_index)/8.0,.5,.8)})
		if world_trial%2==0:world_marks.reverse()
		var world_expected:Dictionary={}
		var world_score:float=0.0
		for world_mark in world_marks:
			var world_phase:float=clampf(float(world_mark.age)/maxf(.001,float(world_mark.life)),0.0,1.0)
			if world_phase>=1.0:continue
			var world_response:Vector4=world_probe.environmental_response_sample(str(world_mark.element),world_phase,bool(world_mark.terrain_only))
			var world_weight:float=maxf(absf(world_response.y),maxf(world_response.z,world_response.w))
			if world_weight<=world_score:continue
			world_score=world_weight
			var world_at:Vector3=world_mark.at
			world_expected={"pulse":Vector4(world_at.x,world_at.z,world_phase,1.0),"response":world_response,"tint":Color(world_mark.color)}
		if world_probe.exterior_response_pick(world_marks)!=world_expected:failures.append("V24.9 exterior selection parity")
		checks+=1
	world_probe.free()
	# V24.8: reused budgets must match a fresh allocation across changing demand.
	var living_memory_probe:=Dungeon.new()
	var living_memory_reused:Array[int]=[]
	for living_memory_case in [[],[0],[3],[1,8,2],[20,20,20,20],[0,3,0,4],[1],[0,0],[]]:
		var living_memory_demands:Array[int]=[]
		living_memory_demands.assign(living_memory_case)
		for living_memory_capacity in [0,1,4,16,64,100]:
			var living_memory_expected:Array[int]=[]
			living_memory_expected.resize(living_memory_demands.size())
			living_memory_expected.fill(0)
			var living_memory_remaining:int=living_memory_capacity
			while living_memory_remaining>0:
				var living_memory_progress:bool=false
				for living_memory_index in range(living_memory_demands.size()):
					if living_memory_expected[living_memory_index]>=living_memory_demands[living_memory_index]:continue
					living_memory_expected[living_memory_index]+=1
					living_memory_remaining-=1
					living_memory_progress=true
					if living_memory_remaining==0:break
				if not living_memory_progress:break
			living_memory_probe.fill_living_particle_budgets(living_memory_demands,living_memory_capacity,living_memory_reused)
			if living_memory_reused!=living_memory_expected:failures.append("V24.8 reused budget parity")
			checks+=1
	var living_memory_actor:=Node3D.new()
	living_memory_probe.append_living_particle_actor(living_memory_actor,["sleep","burn"],1.08)
	living_memory_probe.append_living_particle_actor(living_memory_actor,["poison"],1.12)
	if living_memory_probe.fx_living_actors.size()!=2 or living_memory_probe.fx_living_status_rows[0]!=["sleep","burn"]:failures.append("V24.8 actor row order")
	if not is_equal_approx(living_memory_probe.fx_living_heights[1],1.12):failures.append("V24.8 actor height parity")
	var living_memory_expected_demand:int=int(living_memory_probe.living_status_palette("sleep")[3])+int(living_memory_probe.living_status_palette("burn")[3])
	if living_memory_probe.fx_living_demands[0]!=living_memory_expected_demand:failures.append("V24.8 demand parity")
	living_memory_probe.clear_living_particle_actors()
	if not living_memory_probe.fx_living_actors.is_empty() or not living_memory_probe.fx_living_status_rows.is_empty() or not living_memory_probe.fx_living_heights.is_empty() or not living_memory_probe.fx_living_demands.is_empty():failures.append("V24.8 stale actor rows")
	checks+=4
	living_memory_actor.free()
	living_memory_probe.free()
	# V24.7: compare stable compaction and pending actor indexing with the old queue.
	var reaction_probe:=Dungeon.new()
	var reaction_actor_a:=Node3D.new()
	var reaction_actor_b:=Node3D.new()
	for reaction_step in [0.0,.05,.20,.60,1.0]:
		reaction_probe.fx_reactions.clear()
		var reaction_reference:Array[Dictionary]=[]
		for reaction_index in range(48):
			var reaction_actor:Node3D=reaction_actor_a if reaction_index%3==0 else reaction_actor_b
			var reaction_record:Dictionary={"actor":reaction_actor,"delay":float(reaction_index%7)*.10,"defeated":false,"direction":Vector3.ZERO,"weight":1.0,"serial":reaction_index}
			reaction_probe.fx_reactions.append(reaction_record.duplicate())
			reaction_reference.append(reaction_record.duplicate())
		var reaction_expected_due:Array[Dictionary]=[]
		for reaction_index in range(reaction_reference.size()-1,-1,-1):
			reaction_reference[reaction_index].delay-=reaction_step
			if float(reaction_reference[reaction_index].delay)<=0.0:
				reaction_expected_due.append(reaction_reference[reaction_index])
				reaction_reference.remove_at(reaction_index)
		reaction_probe.collect_due_enemy_reactions(reaction_step)
		if reaction_probe.fx_reactions!=reaction_reference:failures.append("V24.7 future order")
		if reaction_probe.fx_due_reactions!=reaction_expected_due:failures.append("V24.7 due order")
		checks+=2
		for reaction_actor in [reaction_actor_a,reaction_actor_b]:
			var reaction_expected_pending:bool=false
			for reaction_record in reaction_reference:
				if reaction_record.actor==reaction_actor:reaction_expected_pending=true;break
			if reaction_probe.fx_pending_reaction_actors.has(reaction_actor.get_instance_id())!=reaction_expected_pending:failures.append("V24.7 pending actor index")
			checks+=1
	reaction_probe.fx_reactions.clear()
	reaction_probe.queue_enemy_reaction(reaction_actor_a,false,.2,Vector3.ZERO,.1,3)
	reaction_probe.queue_enemy_reaction(reaction_actor_b,false,.4)
	reaction_probe.queue_enemy_reaction(reaction_actor_a,true,.3)
	if reaction_probe.fx_reactions.size()!=2:failures.append("V24.7 terminal compaction count")
	elif reaction_probe.fx_reactions[0].actor!=reaction_actor_b or reaction_probe.fx_reactions[1].actor!=reaction_actor_a or not reaction_probe.fx_reactions[1].defeated:failures.append("V24.7 terminal compaction order")
	checks+=2
	reaction_probe.fx_reactions.clear()
	reaction_probe.fx_due_reactions.clear()
	reaction_actor_a.free()
	reaction_actor_b.free()
	reaction_probe.free()
	# V24.6: no idle fast path while any combat producer or cleanup is pending.
	var idle_probe:=Dungeon.new()
	if not idle_probe.combat_fx_can_idle():failures.append("V24.6 empty idle")
	checks+=1
	for queue_name in ["combat_bursts","delayed_combat_fx","retired_impacts","fx_reactions","fx_reaction_sparks","fx_residues","fx_frame_audio"]:
		var idle_queue:Array=idle_probe.get(queue_name)
		idle_queue.append({})
		if idle_probe.combat_fx_can_idle():failures.append("V24.6 pending "+queue_name)
		idle_queue.clear()
		if not idle_probe.combat_fx_can_idle():failures.append("V24.6 drained "+queue_name)
		checks+=2
	for count_name in ["fx_cast_particles_used","fx_lights_used","fx_halos_used","fx_arc_segments"]:
		idle_probe.set(count_name,1)
		if idle_probe.combat_fx_can_idle():failures.append("V24.6 cleanup "+count_name)
		idle_probe.set(count_name,0)
		if not idle_probe.combat_fx_can_idle():failures.append("V24.6 clean "+count_name)
		checks+=2
	for flag_name in ["fx_trail_had_geometry","fx_arc_had_geometry","fx_trail_started","fx_collect_audio","fx_flushing_audio"]:
		idle_probe.set(flag_name,true)
		if idle_probe.combat_fx_can_idle():failures.append("V24.6 active "+flag_name)
		idle_probe.set(flag_name,false)
		checks+=1
	idle_probe.fx_ground_shake=.18
	idle_probe.fx_contact_camera_age=.05
	idle_probe.combat_fx_update(.02)
	if not is_equal_approx(idle_probe.fx_ground_shake,.12) or not is_equal_approx(idle_probe.fx_contact_camera_age,.07):failures.append("V24.6 idle camera clocks")
	if not idle_probe.combat_fx_can_idle():failures.append("V24.6 idle stays quiet")
	checks+=2
	idle_probe.free()
	# V24.5: final-state writes must preserve transform/visibility and detect external changes.
	var pose_probe:=Dungeon.new()
	for pose_node in [Sprite3D.new(),MeshInstance3D.new()]:
		for pose_target in [Vector3.ZERO,Vector3(.2,.54,-.3),Vector3(1.5,.02,2.0)]:
			for pose_scale in [Vector3.ONE,Vector3(.8,1.25,1.0),Vector3(.32,.12,1.0)]:
				for pose_visibility in [true,false]:
					pose_probe.apply_enemy_body_transform(pose_node,pose_target,pose_scale,pose_visibility)
					if not pose_node.position.is_equal_approx(pose_target) or not pose_node.scale.is_equal_approx(pose_scale) or pose_node.visible!=pose_visibility:failures.append("V24.5 final pose parity")
					var pose_repeat:int=pose_probe.apply_enemy_body_transform(pose_node,pose_target,pose_scale,pose_visibility)
					if pose_repeat!=0:failures.append("V24.5 redundant pose writes")
					pose_node.position+=Vector3.RIGHT
					if pose_probe.apply_enemy_body_transform(pose_node,pose_target,pose_scale,pose_visibility)!=1 or not pose_node.position.is_equal_approx(pose_target):failures.append("V24.5 external position writer")
					checks+=3
		pose_node.free()
	pose_probe.free()
	# V24.4: memoized keys retain the exact legacy pack/cache identity.
	var texture_probe:=Dungeon.new()
	for texture_mode in ["impact_star","bubble","contact:critical:1"]:
		for texture_light in [Color.WHITE,Color.BLACK,Color(.125,.25,.5,.75),Color(.125,.25,.5,1.0)]:
			for texture_dark in [Color.BLACK,Color.WHITE,Color(.2,.3,.4,.5)]:
				var texture_expected:String=texture_mode+str(texture_light)+str(texture_dark)
				for texture_repeat in range(3):
					if texture_probe.combat_secondary_key(texture_mode,texture_light,texture_dark)!=texture_expected:failures.append("V24.4 exact key parity")
					checks+=1
	var atlas_image:=Image.create(2,2,false,Image.FORMAT_RGBA8)
	atlas_image.fill(Color.WHITE)
	var atlas_probe_a:=ImageTexture.create_from_image(atlas_image)
	atlas_image.fill(Color.BLACK)
	var atlas_probe_b:=ImageTexture.create_from_image(atlas_image)
	var atlas_probe_frames_a:Array[Texture2D]=[]
	var atlas_probe_frames_b:Array[Texture2D]=[]
	for atlas_frame in range(12):
		atlas_probe_frames_a.append(atlas_probe_a)
		atlas_probe_frames_b.append(atlas_probe_b)
	texture_probe.fx_atlas_cache["probe_a"]=atlas_probe_frames_a
	texture_probe.fx_atlas_cache["probe_b"]=atlas_probe_frames_b
	texture_probe.fx_atlas_newest="probe_b"
	var atlas_expected_order:Array=["probe_a","probe_b"]
	for atlas_id in ["probe_b","probe_b","probe_a","probe_a","probe_b","probe_a"]:
		var atlas_expected:Texture2D=atlas_probe_a if atlas_id=="probe_a" else atlas_probe_b
		atlas_expected_order.erase(atlas_id);atlas_expected_order.append(atlas_id)
		if texture_probe.combat_packed_frame(atlas_id,5)!=atlas_expected:failures.append("V24.4 atlas reference parity")
		if texture_probe.fx_atlas_cache.keys()!=atlas_expected_order:failures.append("V24.4 atlas LRU order")
		checks+=2
	texture_probe.free()
	# V24.3: exact geometry parity for three-layer electrical segments.
	var geometry_probe:=Dungeon.new()
	for geometry_start in [Vector3.ZERO,Vector3(1.5,-.2,3.0)]:
		for geometry_delta in [Vector3.ZERO,Vector3(.0001,0,0),Vector3.RIGHT,Vector3.UP,Vector3(0,.8,.6),Vector3(-2,.7,1.4)]:
			var geometry_end:Vector3=geometry_start+geometry_delta
			geometry_probe.fx_arc_positions.clear();geometry_probe.fx_arc_colors.clear();geometry_probe.fx_arc_segments=0
			geometry_probe.arc_segment(geometry_start,geometry_end,.072,Color(.18,.47,1.0,.36))
			geometry_probe.arc_segment(geometry_start,geometry_end,.035,Color("#4edbff"))
			geometry_probe.arc_segment(geometry_start,geometry_end,.016,Color("#fffbd3"))
			var expected_geometry_positions:PackedVector3Array=geometry_probe.fx_arc_positions.duplicate()
			var expected_geometry_colors:PackedColorArray=geometry_probe.fx_arc_colors.duplicate()
			var expected_geometry_indices:PackedInt32Array=geometry_probe.fx_quad_indices(geometry_probe.fx_arc_positions.size())
			var expected_geometry_segments:int=geometry_probe.fx_arc_segments
			geometry_probe.fx_arc_positions.clear();geometry_probe.fx_arc_colors.clear();geometry_probe.fx_arc_segments=0
			geometry_probe.electric_arc_layers(geometry_start,geometry_end)
			if geometry_probe.fx_arc_positions!=expected_geometry_positions:failures.append("V24.3 vertex parity")
			if geometry_probe.fx_arc_colors!=expected_geometry_colors:failures.append("V24.3 color parity")
			if geometry_probe.fx_quad_indices(geometry_probe.fx_arc_positions.size())!=expected_geometry_indices:failures.append("V24.3 winding parity")
			if geometry_probe.fx_arc_segments!=expected_geometry_segments:failures.append("V24.3 segment parity")
			checks+=4
	geometry_probe.free()
	# V24.2: reuse independent audio records without dropping overflow cues.
	var audio_pool_probe:=Dungeon.new()
	for audio_round in range(3):
		audio_pool_probe.begin_combat_audio_frame()
		for cue_index in range(80):
			audio_pool_probe.play_combat_sound("probe_"+str(cue_index),"impact" if cue_index%2==0 else "miss",Vector3(cue_index,audio_round,0),cue_index%3==0,float(cue_index)*.001)
		if audio_pool_probe.fx_frame_audio.size()!=80 or audio_pool_probe.fx_audio_cue_pool.size()!=64:failures.append("V24.2 bounded retained storage")
		checks+=1
		for cue_index in range(80):
			var cue_probe:Dictionary=audio_pool_probe.fx_frame_audio[cue_index]
			if cue_probe.id!="probe_"+str(cue_index) or cue_probe.at!=Vector3(cue_index,audio_round,0) or not is_equal_approx(float(cue_probe.age),float(cue_index)*.001):failures.append("V24.2 cue aliasing")
			checks+=1
		audio_pool_probe.fx_frame_audio.sort_custom(audio_pool_probe.combat_audio_event_before)
		if audio_pool_probe.fx_frame_audio[0].id!="probe_79":failures.append("V24.2 chronological order")
		audio_pool_probe.flush_combat_audio_frame()
		if not audio_pool_probe.fx_frame_audio.is_empty() or audio_pool_probe.fx_collect_audio:failures.append("V24.2 stale cues")
		checks+=2
	for audio_power in [-1,0,40,120,250]:
		for audio_critical in [false,true]:
			if audio_pool_probe.combat_audio_mix(audio_power,"miss",audio_critical)!=Vector3(-19,1,0):failures.append("V24.2 miss mix parity")
			if audio_pool_probe.combat_audio_mix(audio_power,"status",audio_critical)!=Vector3(-16,1,1):failures.append("V24.2 status mix parity")
			checks+=2
	audio_pool_probe.free()
	# V24.1: retain bounded request storage while committing only active winners.
	var lighting_probe:=Dungeon.new()
	for i in range(2):lighting_probe.fx_lights.append(OmniLight3D.new())
	lighting_probe.cinematic_light(Vector3.ONE,Color.RED,.5,2.0,1.5,1)
	lighting_probe.cinematic_light(Vector3.ZERO,Color.BLUE,.4,1.5,2.0,0)
	var saved_request:Dictionary=lighting_probe.fx_light_requests[1]
	lighting_probe.cinematic_light(Vector3(2,0,0),Color.GREEN,.9,3.0,1.2,2)
	if saved_request.color!=Color.GREEN or lighting_probe.fx_light_requests.size()!=2:failures.append("V24.1 winning request reuse")
	lighting_probe.commit_cinematic_lights()
	if lighting_probe.fx_lights[1].light_color!=Color.GREEN or not is_equal_approx(lighting_probe.fx_lights[1].light_energy,.9):failures.append("V24.1 winning light parity")
	lighting_probe.fx_lights_used=0;lighting_probe.fx_light_scores.clear()
	lighting_probe.fx_lights[1].light_color=Color.WHITE
	lighting_probe.cinematic_light(Vector3.ZERO,Color.YELLOW,.6,2.0,1.5,1)
	lighting_probe.commit_cinematic_lights()
	if lighting_probe.fx_light_requests.size()!=2 or lighting_probe.fx_lights_used!=1:failures.append("V24.1 bounded storage across frames")
	if lighting_probe.fx_lights[0].light_color!=Color.YELLOW or lighting_probe.fx_lights[1].light_color!=Color.WHITE:failures.append("V24.1 stale request committed")
	lighting_probe.fx_lights_used=0;lighting_probe.fx_light_scores.clear()
	lighting_probe.commit_cinematic_lights()
	if lighting_probe.fx_lights[0].light_color!=Color.YELLOW:failures.append("V24.1 idle commit")
	for probe_light in lighting_probe.fx_lights:probe_light.free()
	lighting_probe.fx_lights.clear()
	var halo_cache_material:=ShaderMaterial.new()
	var halo_cache_shader:=Shader.new()
	halo_cache_shader.code="shader_type spatial; uniform float phase = 0.0; uniform float intensity = 0.0; void fragment(){ALBEDO=vec3(phase); ALPHA=intensity;}"
	halo_cache_material.shader=halo_cache_shader
	var halo_cache_probe:Dictionary=lighting_probe.fx_uniform_cache(halo_cache_material)
	if not lighting_probe.set_fx_uniform_cached(halo_cache_material,halo_cache_probe,&"phase",.4):failures.append("V24.1 initial cached write")
	if lighting_probe.set_fx_uniform(halo_cache_material,&"phase",.4):failures.append("V24.1 shared cache duplicate")
	if not lighting_probe.set_fx_uniform(halo_cache_material,&"phase",.7):failures.append("V24.1 updated shared value")
	if lighting_probe.set_fx_uniform_cached(halo_cache_material,halo_cache_probe,&"phase",.7):failures.append("V24.1 reverse cache consistency")
	if not lighting_probe.set_fx_uniform_cached(halo_cache_material,halo_cache_probe,&"intensity",.3) or not is_equal_approx(float(halo_cache_material.get_shader_parameter(&"intensity")),.3):failures.append("V24.1 independent parameter")
	lighting_probe.free()
	checks+=10
	# V24.0: compare prefix cleanup with a full scan across growth, shrink,
	# independent persistent status particles and optional batching hides.
	var pool_probe:=Dungeon.new()
	var pool_capacity:int=Dungeon.FX_PARTICLE_CAP+Dungeon.LIVING_PARTICLE_CAP
	for i in range(pool_capacity):
		var pool_sprite:=Sprite3D.new()
		pool_sprite.hide()
		pool_probe.combat_particles.append(pool_sprite)
	for pool_counts in [Vector2i(0,0),Vector2i(144,64),Vector2i(7,3),Vector2i(0,3),Vector2i(12,0),Vector2i(12,5),Vector2i(0,0),Vector2i(0,0)]:
		for i in range(pool_counts.x):pool_probe.combat_particles[i].show()
		for i in range(pool_counts.y):pool_probe.combat_particles[Dungeon.FX_PARTICLE_CAP+i].show()
		# Batching is permitted to hide a submitted sprite, not an unused one.
		if pool_counts.x>2:pool_probe.combat_particles[1].hide()
		pool_probe.fx_cast_particles_used=pool_probe.finish_particle_range(0,pool_counts.x,pool_probe.fx_cast_particles_used,Dungeon.FX_PARTICLE_CAP)
		pool_probe.fx_living_particles_used=pool_probe.finish_particle_range(Dungeon.FX_PARTICLE_CAP,pool_counts.y,pool_probe.fx_living_particles_used,Dungeon.LIVING_PARTICLE_CAP)
		if pool_probe.fx_cast_particles_used!=pool_counts.x or pool_probe.fx_living_particles_used!=pool_counts.y:failures.append("V24.0 active counts")
		checks+=1
		for i in range(pool_capacity):
			var pool_expected:bool=(i<pool_counts.x and not (i==1 and pool_counts.x>2)) or (i>=Dungeon.FX_PARTICLE_CAP and i<Dungeon.FX_PARTICLE_CAP+pool_counts.y)
			if pool_probe.combat_particles[i].visible!=pool_expected:failures.append("V24.0 visibility parity "+str([pool_counts,i]))
			checks+=1
		for i in range(pool_counts.x+pool_counts.y):
			var pool_expected_index:int=i if i<pool_counts.x else Dungeon.FX_PARTICLE_CAP+i-pool_counts.x
			if pool_probe.active_particle_pool_index(i)!=pool_expected_index:failures.append("V24.0 pool index parity")
			checks+=1
	for pool_sprite in pool_probe.combat_particles:pool_sprite.free()
	pool_probe.combat_particles.clear()
	pool_probe.free()
	# V23.9: the shared particle peak must give exactly the direct trajectory.
	for render_impact in [-.1,0.0,.001,.12,.5,.88,.999,1.0,1.1]:
		var render_peak:float=clampf(render_impact,.001,.999)
		for render_time in [-.1,0.0,.001,.15,.5,.999,1.0,1.1]:
			for render_trail in [-.1,0.0,.18,.30,.35,.5,.65,.9,1.0]:
				if view.combat_travel_progress_from_peak(render_time,render_peak,render_trail)!=view.combat_travel_progress(render_time,render_impact,render_trail):
					failures.append("V23.9 trajectory parity "+str([render_time,render_impact,render_trail]))
				checks+=1
	# V23.8: count-only path must preserve the full impact ledger's wave count.
	for wave_count_probe in [0,1,2,5,12,16]:
		var wave_probe_attempts:Array=[]
		for i in range(wave_count_probe):wave_probe_attempts.append({"damage":i+1})
		var wave_probe_results:Dictionary={Vector2i.ZERO:{"attempts":wave_probe_attempts},Vector2i.ONE:{"damage":1}}
		var wave_probe_expected:int=clampi(wave_count_probe,1,12)
		if view.cast_impact_wave_count(wave_probe_results)!=wave_probe_expected or view.cast_impact_waves(wave_probe_results).size()!=wave_probe_expected:failures.append("V23.8 wave count parity "+str(wave_count_probe))
		var wave_probe_times:Array[float]=view.caster_wave_times({"results":wave_probe_results},1.0,.5)
		if wave_probe_times.size()!=(wave_probe_expected if wave_probe_expected>1 else 0):failures.append("V23.8 caster timeline parity "+str(wave_count_probe))
		checks+=2
	if view.cast_impact_wave_count({})!=1:failures.append("V23.8 empty ledger")
	var idle_wave_probe:Dictionary={"impact_times":[.5],"age":.25}
	var idle_wave_counter:int=view.fx_dispatched_waves
	view.dispatch_cast_waves(idle_wave_probe)
	if int(idle_wave_probe.get("impact_cursor",-1))!=0 or view.fx_dispatched_waves!=idle_wave_counter:failures.append("V23.8 future impact mutated")
	var completed_wave_probe:Dictionary={"impact_times":[.5],"impact_cursor":1,"age":1.0}
	view.dispatch_cast_waves(completed_wave_probe)
	if int(completed_wave_probe.impact_cursor)!=1 or view.fx_dispatched_waves!=idle_wave_counter:failures.append("V23.8 completed impact replay")
	var prior_reaction_probe:Dictionary={"age":.1,"damage":7}
	if view.latest_player_impact(prior_reaction_probe,{"target_player":true,"impact_cursor":1,"impact_waves":[{}],"impact_times":[.5]},1)!=prior_reaction_probe:failures.append("V23.8 unchanged reaction")
	checks+=4
	# V23.7: queue compaction preserves retained order and chronological FIFO.
	view.delayed_combat_fx.assign([{"delay":.5,"event":{"id":"a"}},{"delay":.125,"event":{"id":"b"}},{"delay":.0625,"event":{"id":"c"}},{"delay":.5,"event":{"id":"d"}},{"delay":.125,"event":{"id":"e"}}])
	view.collect_due_combat_casts(.125)
	var due_ids:Array=[]
	for queued in view.fx_due_delayed_casts:due_ids.append(queued.event.id)
	if due_ids!=["c","b","e"]:failures.append("V23.7 due order")
	if view.delayed_combat_fx.size()!=2 or view.delayed_combat_fx[0].event.id!="a" or view.delayed_combat_fx[1].event.id!="d":failures.append("V23.7 retained order")
	if float(view.fx_due_delayed_casts[0].delay)!=-.0625 or float(view.delayed_combat_fx[0].delay)!=.375:failures.append("V23.7 exact elapsed time")
	view.collect_due_combat_casts(.375)
	if view.fx_due_delayed_casts.size()!=2 or not view.delayed_combat_fx.is_empty():failures.append("V23.7 exact boundary")
	elif view.fx_due_delayed_casts[0].event.id!="a" or view.fx_due_delayed_casts[1].event.id!="d":failures.append("V23.7 boundary FIFO")
	view.collect_due_combat_casts(.125)
	if not view.fx_due_delayed_casts.is_empty():failures.append("V23.7 duplicate dispatch")
	checks+=5
	# V23.5: exact nearest-rank percentiles and honest pause-gap accounting.
	var diagnostic_samples:=PackedInt64Array([40000,10000,16667,20000,33333])
	var diagnostic_stats:=view.fx_diag_stats(diagnostic_samples)
	if int(diagnostic_stats.samples)!=5 or int(diagnostic_stats.p50_usec)!=20000 or int(diagnostic_stats.p95_usec)!=40000 or int(diagnostic_stats.p99_usec)!=40000:failures.append("V23.5 percentile math")
	if int(diagnostic_stats.over_60hz_budget)!=3 or int(diagnostic_stats.over_30hz_budget)!=1 or diagnostic_samples[0]!=40000:failures.append("V23.5 threshold or sample mutation")
	if not view.fx_diag_stats(PackedInt64Array()).is_empty():failures.append("V23.5 empty sample")
	view.fx_diag_sample(1000000,400,true)
	view.fx_diag_sample(1016667,500,true)
	view.fx_diag_sample(1400000,700,true)
	view.fx_diag_sample(1416667,600,false)
	view.fx_diag_sample(1433334,800,false)
	if view.fx_diag_intervals!=PackedInt64Array([16667,16667]) or view.fx_diag_cpu!=PackedInt64Array([500,600]) or view.fx_diag_gaps!=1:failures.append("V23.5 active interval and gap accounting")
	view.fx_diag_previous_usec=0;view.fx_diag_was_active=false;view.fx_diag_intervals.clear();view.fx_diag_cpu.clear();view.fx_diag_gaps=0
	checks+=4
	# V22.7: allocation-free oldest-key selection preserves the old eviction order.
	var empty_fx_cache:Dictionary={}
	if view.evict_oldest_fx_cache_entry(empty_fx_cache) or not empty_fx_cache.is_empty():failures.append("V22.7 empty eviction")
	checks+=1
	for capacity in [1,3,32,192,384]:
		var old_cache:Dictionary={}
		var new_cache:Dictionary={}
		for i in range(capacity):
			old_cache["entry_"+str(i)]=i
			new_cache["entry_"+str(i)]=i
		for i in range(capacity*2):
			var hot:String="entry_"+str(i%capacity)
			if old_cache.has(hot):
				var old_value:Variant=old_cache[hot]
				var new_value:Variant=new_cache[hot]
				old_cache.erase(hot);old_cache[hot]=old_value
				new_cache.erase(hot);new_cache[hot]=new_value
			old_cache.erase(old_cache.keys()[0])
			if not view.evict_oldest_fx_cache_entry(new_cache):failures.append("V22.7 unexpected empty cache")
			var next_key:String="replacement_"+str(i)
			old_cache[next_key]=i
			new_cache[next_key]=i
			if old_cache!=new_cache or old_cache.keys()!=new_cache.keys():failures.append("V22.7 eviction parity "+str(capacity))
			checks+=1
	var singleton_fx_cache:Dictionary={"only":42}
	if not view.evict_oldest_fx_cache_entry(singleton_fx_cache) or not singleton_fx_cache.is_empty():failures.append("V22.7 singleton eviction")
	checks+=1
	# V22.6: parameter caches must be independent per material and exact.
	var uniform_shader:=Shader.new()
	uniform_shader.code="shader_type spatial; uniform float phase = 0.0; uniform float intensity = 0.0; void fragment(){ALBEDO=vec3(phase); ALPHA=intensity;}"
	var uniform_a:=ShaderMaterial.new()
	var uniform_b:=ShaderMaterial.new()
	uniform_a.shader=uniform_shader
	uniform_b.shader=uniform_shader
	if not view.set_fx_uniform(uniform_a,&"phase",.25):failures.append("V22.6 first uniform write")
	if view.set_fx_uniform(uniform_a,&"phase",.25):failures.append("V22.6 redundant uniform")
	if not view.set_fx_uniform(uniform_a,&"intensity",.25):failures.append("V22.6 distinct uniform key")
	if not view.set_fx_uniform(uniform_b,&"phase",.25):failures.append("V22.6 distinct material")
	if not view.set_fx_uniform(uniform_a,&"phase",.75):failures.append("V22.6 changed uniform")
	if not is_equal_approx(float(uniform_a.get_shader_parameter(&"phase")),.75) or not is_equal_approx(float(uniform_b.get_shader_parameter(&"phase")),.25):failures.append("V22.6 material value parity")
	var halo_probe:=MeshInstance3D.new()
	var halo_at:=Vector3(1.0,.065,2.0)
	view.apply_cinematic_halo_transform(halo_probe,halo_at,1.25,true)
	if not halo_probe.position.is_equal_approx(halo_at) or not halo_probe.rotation.is_equal_approx(Vector3(-PI*.5,0,0)) or not halo_probe.scale.is_equal_approx(Vector3.ONE*1.25):failures.append("V22.6 ground halo state")
	# Exact equality is used for skipping; engine decomposition may round rotation.
	var repeated_halo_writes:int=view.apply_cinematic_halo_transform(halo_probe,halo_at,1.25,true)
	if repeated_halo_writes>1:failures.append("V22.6 repeated halo transform")
	view.apply_cinematic_halo_transform(halo_probe,halo_at,.5,false)
	if not halo_probe.rotation.is_equal_approx(Vector3.ZERO) or not halo_probe.scale.is_equal_approx(Vector3.ONE*.5):failures.append("V22.6 halo reuse")
	halo_probe.free()
	checks+=9
	# V22.5: actual sprite properties remain authoritative across pool reuse.
	var probe:=Sprite3D.new()
	var probe_texture:=ImageTexture.create_from_image(Image.create(2,2,false,Image.FORMAT_RGBA8))
	var probe_at:=Vector3(2.0,.5,3.0)
	probe.hide()
	view.apply_environment_particle_state(probe,probe_at,probe_texture,.5,.75,false)
	if probe.position!=probe_at or probe.texture!=probe_texture or probe.scale!=Vector3.ONE*.5 or probe.modulate!=Color(1,1,1,.75) or not probe.visible:failures.append("V22.5 initial particle state")
	if view.apply_environment_particle_state(probe,probe_at,probe_texture,.5,.75,false)!=0:failures.append("V22.5 redundant particle writes")
	probe.hide()
	if view.apply_environment_particle_state(probe,probe_at,probe_texture,.5,.75,false)!=1 or not probe.visible:failures.append("V22.5 hidden pooled sprite")
	probe.position=Vector3.ZERO
	probe.modulate=Color.WHITE
	if view.apply_environment_particle_state(probe,probe_at,probe_texture,.5,.75,false)!=2:failures.append("V22.5 external pool mutation")
	view.apply_environment_particle_state(probe,probe_at,probe_texture,.5,2.0,true)
	if probe.billboard!=BaseMaterial3D.BILLBOARD_DISABLED or not probe.rotation.is_equal_approx(Vector3(-PI*.5,0,0)) or probe.modulate!=Color.WHITE:failures.append("V22.5 flat particle transition")
	view.apply_environment_particle_state(probe,probe_at,probe_texture,.5,-1.0,false)
	if probe.billboard!=BaseMaterial3D.BILLBOARD_ENABLED or not probe.rotation.is_equal_approx(Vector3.ZERO) or probe.modulate.a!=0.0:failures.append("V22.5 billboard transition")
	probe.free()
	checks+=6
	# V22.1: delayed launch, retired contact and active environmental cues
	# share one chronology even when collected in reversed traversal order.
	var audio_events:Array[Dictionary]=[
		{"id":"eos_001","phase":"impact","at":Vector3.RIGHT,"critical":false,"age":.03},
		{"id":"eos_002","phase":"launch","at":Vector3.ZERO,"critical":false,"age":.08},
		{"id":"eos_003","phase":"impact","at":Vector3.FORWARD,"critical":true,"age":.03},
		{"id":"eos_004","phase":"env_water","at":Vector3.ZERO,"critical":false,"age":.05},
		{"id":"eos_005","phase":"miss","at":Vector3.ZERO,"critical":false,"age":.03}]
	var expected_order:Array[String]=["eos_002","eos_004","eos_003","eos_001","eos_005"]
	for reverse_audio in [false,true]:
		var input:Array[Dictionary]=audio_events.duplicate()
		if reverse_audio:input.reverse()
		view.begin_combat_audio_frame()
		for cue in input:view.play_combat_sound(str(cue.id),str(cue.phase),cue.at,bool(cue.critical),float(cue.age))
		if view.fx_frame_audio.size()!=expected_order.size():failures.append("V22.1 lost queued audio")
		view.fx_frame_audio.sort_custom(view.combat_audio_event_before)
		var ordered:Array[String]=[]
		for cue in view.fx_frame_audio:ordered.append(str(cue.id))
		if ordered!=expected_order:failures.append("V22.1 chronological audio order")
		view.flush_combat_audio_frame()
		if view.fx_collect_audio or not view.fx_frame_audio.is_empty():failures.append("V22.1 stale frame audio")
		checks+=3
	# Outside the visual update, sound playback stays immediate.
	view.play_combat_sound("eos_001","launch",Vector3.ZERO)
	if not view.fx_frame_audio.is_empty():failures.append("V22.1 immediate audio regression")
	checks+=1
	# V19.5: volume/pitch remain bounded and critical voices retain priority.
	for power in range(61):
		var normal_mix:=view.combat_audio_mix(power,"impact",false)
		var critical_mix:=view.combat_audio_mix(power,"impact",true)
		var launch_mix:=view.combat_audio_mix(power,"launch")
		var miss_mix:=view.combat_audio_mix(power,"miss")
		var status_mix:=view.combat_audio_mix(power,"status")
		if not normal_mix.is_finite() or normal_mix.x> -8.0 or normal_mix.x< -14.00001 or normal_mix.y<.91999 or normal_mix.y>1.04001:failures.append("impact audio bounds")
		if critical_mix.x<normal_mix.x or critical_mix.z!=3.0 or normal_mix.z!=2.0:failures.append("critical audio priority")
		if launch_mix.x>=normal_mix.x or launch_mix.z!=1.0 or miss_mix.z!=0.0 or status_mix.z!=1.0:failures.append("audio phase mix")
		checks+=3
	# V22.2: the cheap admission key must match the full authored mixer.
	for power in [0,1,40,80,120,250]:
		for phase in ["env_water","env_ground","status_blocked","status_poison","status","miss","launch","impact","other"]:
			for critical in [false,true]:
				if view.combat_audio_phase_priority(phase,critical)!=int(view.combat_audio_mix(power,phase,critical).z):failures.append("V22.2 audio priority parity "+phase)
				checks+=1
	var voices:Array[int]=[3,2,1,0]
	if view.combat_audio_voice_slot(voices,0,0)!=-1:failures.append("miss voice eviction")
	if view.combat_audio_voice_slot(voices,0,2)!=3:failures.append("weakest voice selection")
	var critical_voices:Array[int]=[3,3,3]
	if view.combat_audio_voice_slot(critical_voices,1,2)!=-1:failures.append("protect critical voice")
	if view.combat_audio_voice_slot(critical_voices,1,3)!=1:failures.append("critical round robin")
	var idle_voices:Array[int]=[0,1,-1,3]
	if view.combat_audio_voice_slot(idle_voices,0,2)!=2:failures.append("prefer idle audio voice")
	checks+=5
	# V22.3: simultaneous equal-priority sounds must not restart a voice
	# before the mixer has rendered the earlier admission.
	if view.combat_audio_voice_slot(critical_voices,1,3,7)!=-1:failures.append("V22.3 same-frame critical restart")
	if view.combat_audio_voice_slot(critical_voices,1,3,2)!=2:failures.append("V22.3 old critical voice available")
	if view.combat_audio_voice_slot(voices,0,3,15)!=3:failures.append("V22.3 critical cannot replace weak cue")
	if view.combat_audio_voice_slot(idle_voices,0,2,3)!=2:failures.append("V22.3 idle voice admission")
	var crowded_impacts:Array[int]=[2,2,2]
	if view.combat_audio_voice_slot(crowded_impacts,0,2,7)!=-1:failures.append("V22.3 same-frame normal restart")
	if view.combat_audio_voice_slot(crowded_impacts,0,2,0)!=0:failures.append("V22.3 next-frame reuse")
	view.begin_combat_audio_frame()
	view.fx_frame_voice_mask=7
	view.flush_combat_audio_frame()
	if view.fx_flushing_audio or view.fx_frame_voice_mask!=0:failures.append("V22.3 flush state leak")
	checks+=7
	# V19.3: bounded optical profiles, distinct material identity and quality fallback.
	var optical_profiles:Dictionary={}
	for element in ["normal","fire","water","electric","grass","ice","fighting","poison","ground","flying","psychic","bug","rock","ghost","dragon","dark","steel","fairy"]:
		var initial:=view.elemental_atmosphere_sample(element,0.0,false,0)
		var ground:=view.elemental_atmosphere_sample(element,0.0,true,0)
		var medium:=view.elemental_atmosphere_sample(element,0.0,false,1)
		var low:=view.elemental_atmosphere_sample(element,0.0,false,2)
		if optical_profiles.has(initial):failures.append("duplicate optical profile "+element)
		optical_profiles[initial]=true
		if ground.z!=0.0 or ground.x>initial.x+.00001:failures.append("floor optical profile "+element)
		if medium.distance_to(initial*.55)>.00001 or low!=Vector3.ZERO:failures.append("optical quality fallback "+element)
		checks+=3
		var previous:=initial
		for step in range(101):
			var sample:=view.elemental_atmosphere_sample(element,float(step)/100.0,false,0)
			if not sample.is_finite() or sample.x<0.0 or sample.y<0.0 or sample.z<0.0 or sample.x>1.0 or sample.y>1.0 or sample.z>1.0:failures.append("optical bounds "+element)
			if sample.x>previous.x+.00001 or sample.y>previous.y+.00001 or sample.z>previous.z+.00001:failures.append("optical dissipation "+element)
			previous=sample
			checks+=2
		if previous.length()>.00001:failures.append("optical terminal fade "+element)
		checks+=1
	# V19.2: verify analytic flight apex, landing, bounce and ground clearance.
	for landing in [.35,.58,.72,.90]:
		for height in [.2,.6,1.1]:
			for bounce in [0.0,.12,.20]:
				var start:=view.material_flight_sample(0.0,landing,height,bounce)
				var apex:=view.material_flight_sample(landing*.5,landing,height,bounce)
				var contact:=view.material_flight_sample(landing,landing,height,bounce)
				var end:=view.material_flight_sample(1.0,landing,height,bounce)
				if start.distance_to(Vector3.ZERO)>.00001:failures.append("material flight start")
				if absf(apex.x-height)>.00001 or apex.z!=0.0:failures.append("material flight apex")
				if absf(contact.x)>.00001 or absf(contact.y-1.0)>.00001 or contact.z!=1.0:failures.append("material landing")
				if absf(end.x)>.00001 or end.z!=1.0:failures.append("material settling")
				checks+=4
				var previous:float=0.0
				for step in range(101):
					var sample:=view.material_flight_sample(float(step)/100.0,landing,height,bounce)
					if not sample.is_finite() or sample.x<-.00001 or sample.y<previous-.00001:failures.append("material flight continuity")
					previous=sample.y
					checks+=1
	# V19 power scaling is monotonic, bounded and neutral for variable-power moves.
	var previous_power:=Vector3.ZERO
	for power in range(1,61):
		var sample:=view.cinematic_power_sample(power)
		if not sample.is_finite() or sample.x<.78-.00001 or sample.x>1.48+.00001 or sample.y<.80-.00001 or sample.y>1.40+.00001 or sample.z<.85-.00001 or sample.z>1.30+.00001:
			failures.append("cinematic power bounds "+str(power))
		if sample.x<previous_power.x or sample.y<previous_power.y or sample.z<previous_power.z:
			failures.append("cinematic power monotonicity "+str(power))
		previous_power=sample
		checks+=2
	if view.cinematic_power_sample(0)!=Vector3.ONE:failures.append("variable power visual neutrality")
	if view.cinematic_power_sample(8).distance_to(Vector3.ONE)>.0001:failures.append("baseline power visual scale")
	if view.cinematic_power_sample(60,true)!=view.cinematic_power_sample(0,true):failures.append("status power must not amplify lighting")
	if view.cinematic_power_sample(44).x<=view.cinematic_power_sample(6).x:failures.append("strong attack visual differentiation")
	checks+=4
	for species in Art.ENEMY_PIXEL_PILOTS:
		for dir in range(8):
			var idle:=Art.enemy_pixel_texture(species,dir,"idle",0)
			if idle==null:
				failures.append("missing idle: "+species)
				continue
			if idle!=Art.enemy_pixel_texture(species,dir,"idle",42):
				failures.append("noncanonical idle: "+species)
			for part in range(3):
				for blink in [false,true]:
					var texture:=Art.enemy_pixel_texture(species,dir,"idle",0,blink,part)
					if texture==null or texture.get_width()!=48 or texture.get_height()!=48:
						failures.append("bad expression dimensions: "+species)
					checks+=1
			var hurt:=Art.enemy_pixel_texture(species,dir,"hurt",0)
			if hurt==null or hurt!=Art.enemy_pixel_texture(species,dir,"hurt",4,true,2):
				failures.append("combat cache priority: "+species)
			checks+=2
		for i in range(101):
			var t:float=float(i)/100.0
			var hit:Dictionary=view.creature_hit_sample(t,species)
			var idle_sample:Vector3=view.creature_idle_sample(species,t*10.0,.7,1.0,true)
			if float(hit.squash)<.7 or float(hit.squash)>1.3 or absf(idle_sample.x-1.0)>.04:
				failures.append("motion out of bounds: "+species)
			checks+=1
		# Exercise real Sprite3D actors and the actual state update code.
		var actor:=Node3D.new()
		root.add_child(actor)
		if not view.attach_enemy_pixel(actor,species):
			failures.append("attach enemy failed: "+species)
			actor.free()
			continue
		var sprite:=actor.get_node("EnemyPixel") as Sprite3D
		var shadow:=actor.get_node("EnemyContactShadow") as MeshInstance3D
		actor.set_meta("native_hp_ratio",.15)
		for i in range(30):
			view.elapsed+=1.0/60.0
			view.update_enemy_pixel(actor,1.0/60.0,Vector3.ZERO)
			if not sprite.scale.is_finite() or not sprite.position.is_finite():
				failures.append("invalid idle actor: "+species)
			checks+=1
		actor.set_meta("native_alert",true)
		view.update_enemy_pixel(actor,1.0/60.0,Vector3.ZERO)
		if sprite.texture!=Art.enemy_pixel_texture(species,0,"windup",0):
			failures.append("alert pose not applied: "+species)
		checks+=1
		actor.set_meta("native_alert",false)
		actor.set_meta("living_statuses",["sleep"])
		for i in range(30):
			view.update_enemy_pixel(actor,1.0/60.0,Vector3.ZERO)
		if sprite.texture!=Art.enemy_pixel_texture(species,0,"sleep",0):
			failures.append("sleep pose not applied: "+species)
		checks+=1
		actor.set_meta("living_statuses",[])
		view.enemy_pose(actor,"hurt",.24)
		view.update_enemy_pixel(actor,.08,Vector3.ZERO)
		if sprite.texture!=Art.enemy_pixel_texture(species,0,"hurt",0):
			failures.append("hurt did not override sleep: "+species)
		checks+=1
		view.enemy_pose(actor,"defeat",.32)
		view.update_enemy_pixel(actor,.25,Vector3.ZERO)
		if sprite.scale.y>=1.0 or shadow.scale.x>=1.45:
			failures.append("defeat collapse missing: "+species)
		checks+=1
		view.update_enemy_pixel(actor,.10,Vector3.ZERO)
		if not actor.is_queued_for_deletion() or actor.visible:
			failures.append("defeat cleanup missing: "+species)
		checks+=1
		# Deferred deletion avoids freeing a queued node twice.
	# Stress the same quota helper used by the combat renderer.
	for casts in range(1,11):
		for capacity in range(145):
			for demand in [1,4,12,26,80,144]:
				var used:int=0
				for i in range(casts):
					var quota:int=view.cast_particle_quota(used,capacity,casts-i)
					if quota<0 or used+quota>capacity:failures.append("cast quota overflow")
					if capacity>=casts and quota<1:failures.append("cast starved")
					used+=mini(quota,demand)
					checks+=1
				if used>capacity:failures.append("cast capacity exceeded")
	for capacity in range(65):
		var demands:Array[int]=[1,4,9,16,20,32]
		var budgets:Array[int]=view.living_particle_budgets(demands,capacity)
		var total:int=0
		for i in range(demands.size()):
			total+=budgets[i]
			if budgets[i]<0 or budgets[i]>demands[i]:failures.append("particle budget overflow")
		if total!=capacity:failures.append("particle budget conservation")
		checks+=1
	for i in range(101):
		var form:Vector3=view.form_effect_sample(float(i)/100.0)
		if form.x<.129 or form.x>1.051 or form.y<-.001 or form.y>1.001:
			failures.append("form envelope")
		checks+=1
	# Exercise real controller hysteresis and loading-spike rejection.
	view.fx_performance_grace=0.0
	for i in range(120):view.update_fx_performance(1.0/60.0)
	if view.fx_performance_tier!=0:failures.append("healthy frame budget degraded")
	view.update_fx_performance(.8)
	if view.fx_performance_tier!=0:failures.append("isolated loading spike degraded")
	for i in range(100):view.update_fx_performance(.04)
	if view.fx_performance_tier!=2 or view.residue_particle_count()!=2:failures.append("sustained pressure not detected")
	for i in range(60):view.update_fx_performance(1.0/60.0)
	if view.fx_performance_tier!=2:failures.append("premature recovery")
	for i in range(600):view.update_fx_performance(1.0/60.0)
	if view.fx_performance_tier!=0 or view.residue_particle_count()!=4:failures.append("full quality did not recover")
	checks+=5
	# V23.6: defer recovery at contact but never indefinitely.
	view.fx_performance_tier=2
	view.fx_frame_average=1.0/60.0
	view.fx_pressure_age=0.0;view.fx_recovery_age=0.0
	for i in range(260):view.update_fx_performance(1.0/60.0,true)
	if view.fx_performance_tier!=2:failures.append("V23.6 quality changed during active cast")
	view.update_fx_performance(1.0/60.0,false)
	if view.fx_performance_tier!=1:failures.append("V23.6 missed quiet recovery boundary")
	view.fx_recovery_age=0.0
	for i in range(310):view.update_fx_performance(1.0/60.0,true)
	if view.fx_performance_tier!=0:failures.append("V23.6 indefinite recovery deferral")
	view.fx_frame_average=.045;view.fx_pressure_age=.95;view.fx_recovery_age=.5
	view.update_fx_performance(.8,true)
	if not is_equal_approx(view.fx_frame_average,1.0/60.0) or view.fx_pressure_age!=0.0 or view.fx_recovery_age!=0.0:failures.append("V23.6 stale pressure after pause")
	view.update_fx_performance(NAN,true)
	if not is_finite(view.fx_frame_average) or view.fx_performance_tier!=0:failures.append("V23.6 nonfinite delta")
	for i in range(100):view.update_fx_performance(.04,true)
	if view.fx_performance_tier!=2:failures.append("V23.6 active pressure still requires protection")
	view.fx_performance_tier=0;view.fx_frame_average=1.0/60.0
	view.fx_pressure_age=0.0;view.fx_recovery_age=0.0
	checks+=6
	# Catalog-wide real image smoke test, including native signatures.
	var catalog:Dictionary=Dungeon.Rules.MOVE_LIBRARY.duplicate()
	catalog.merge(Dungeon.Rules.DEV_NATIVE_MOVES)
	# V22.4: one family classification must exactly match all legacy branches.
	var particle_prefixes:Array[String]=["electric","fire_","water_","grass_","ice_","earth_","rock_","fight_","air_","poison_","bug_","psi_","ghost_","dragon_","dark_","steel_","normal_","neutral_","support_","status_"]
	var particle_roles:Array[String]=["electric","electric_sky","fire","fire_","ground","lash","unknown_extra"]
	for move_id in catalog:particle_roles.append(str(view.combat_profile(str(move_id)).role))
	for particle_role in particle_roles:
		var family:String=view.combat_particle_family(particle_role)
		for prefix in particle_prefixes:
			if (family==prefix)!=particle_role.begins_with(prefix):failures.append("V22.4 particle family mismatch "+particle_role+" "+prefix)
			checks+=1
	var elements:Dictionary={}
	for id in catalog:
		var profile:Dictionary=view.combat_profile(str(id))
		var move:Dictionary=catalog[id]
		elements[str(move.type)]=true
		if str(profile.element)!=str(move.type) or float(profile.duration)<=0.0 or float(profile.impact)<=0.0 or float(profile.impact)>=1.0:
			failures.append("invalid move profile: "+str(id))
		var image:Image=view.combat_frame_image(str(id),6)
		if image==null or image.get_width()!=48 or image.get_height()!=48 or not image.get_used_rect().has_area():
			failures.append("missing midpoint art: "+str(id))
		checks+=1
	if catalog.size()!=589 or elements.size()!=18:failures.append("catalog coverage changed")
	# Verify every explicit physical symbol resolves to a real catalog move
	# and all three stages contain nonempty 48px art.
	for id in Dungeon.CONTACT_ICON_KIND:
		if not catalog.has(id):failures.append("unknown contact icon move: "+str(id))
		var kind:String=str(Dungeon.CONTACT_ICON_KIND[id])
		for stage in range(3):
			var icon:Image=view.contact_icon_image(kind,stage,Color("#fff1bc"),Color("#926185"))
			if icon==null or icon.get_size()!=Vector2i(48,48) or not icon.get_used_rect().has_area():
				failures.append("empty physical contact icon: "+str(id))
			checks+=1
	# Each projectile reaches the actual path endpoint, even on bent routes.
	# Cached routes must reproduce the original distance-weighted interpolation.
	var route_rng:=RandomNumberGenerator.new()
	route_rng.seed=218
	for trial in range(64):
		var route_points:Array=[Vector3.ZERO]
		for k in range(1+trial%8):
			var last:Vector3=route_points[-1]
			route_points.append(last if k%3==0 else last+Vector3(route_rng.randf_range(-3,3),route_rng.randf_range(-1,1),route_rng.randf_range(-3,3)))
		var metrics:=view.combat_path_metrics(route_points)
		var builds:int=view.fx_path_metrics_builds
		for k in range(33):
			var t:float=float(k)/32.0
			var cached:=view.combat_path_sample(route_points,t,metrics)
			var expected:=view.combat_path_sample(route_points,t)
			if cached.distance_to(expected)>.000001:failures.append("V21.8 path parity")
			if view.combat_path_prefix(route_points,t,metrics)!=view.combat_path_prefix(route_points,t):failures.append("V21.8 path prefix parity")
			checks+=2
		if view.fx_path_metrics_builds<=builds:failures.append("V21.8 fallback path test")
		builds=view.fx_path_metrics_builds
		for k in range(33):view.combat_path_sample(route_points,float(k)/32.0,metrics)
		if view.fx_path_metrics_builds!=builds:failures.append("V21.8 cached path rebuild")
		checks+=2
	# Snapshot parity for confirmed, missed, and redirected multi-hit results.
	var snapshot_tile:=Vector2i(1,0)
	var snapshot_other:=Vector2i(2,0)
	var snapshot_points:Array=[Vector3.ZERO,Vector3(1.4,.6,0)]
	var snapshot_waves:Array[Dictionary]=[{snapshot_tile:{"damage":0}},{snapshot_other:{"damage":7,"crit":1}}]
	var snapshot_burst:Dictionary={"points":snapshot_points,"results":{snapshot_other:{"damage":7,"crit":1}},"damage":7,"impact_waves":snapshot_waves,"impact_times":[.2,.4],"impact_cursor":0,"age":0.0,"duration":.8}
	var legacy_snapshot:Dictionary=snapshot_burst.duplicate(true)
	view.prepare_impact_snapshots(snapshot_burst)
	var snapshot_builds:int=view.fx_impact_snapshot_builds
	for cursor in range(3):
		snapshot_burst.impact_cursor=cursor
		legacy_snapshot.impact_cursor=cursor
		snapshot_burst.age=.01+float(cursor)*.2
		legacy_snapshot.age=snapshot_burst.age
		var expected:=view.resolve_element_impact(view.impact_visual_view(legacy_snapshot))
		if view.resolve_element_impact(view.impact_visual_view(snapshot_burst))!=expected:failures.append("V21.9 impact snapshot parity")
		if view.critical_impact_tiles(snapshot_burst)!=view.critical_impact_tiles(legacy_snapshot):failures.append("V21.9 critical snapshot parity")
		if view.contact_wave_sample(snapshot_burst)!=view.contact_wave_sample(legacy_snapshot):failures.append("V21.9 contact clock parity")
		var hits:int=view.fx_contact_sample_hits
		view.contact_wave_sample(snapshot_burst)
		if view.fx_contact_sample_hits!=hits+1:failures.append("V21.9 contact reuse")
		checks+=4
	if view.fx_impact_snapshot_builds!=snapshot_builds:failures.append("V21.9 repeated snapshot build")
	checks+=1
	var route:Array=[Vector3(0,.5,0),Vector3(1.4,.5,0),Vector3(1.4,.5,2.8)]
	for id in Dungeon.PROJECTILE_IDENTITY:
		if not catalog.has(id):failures.append("unknown projectile: "+str(id))
		var kind:String=str(Dungeon.PROJECTILE_IDENTITY[id])
		var texture:=view.combat_pixel_texture("projectile_"+kind,Color("#ffe5ab"),Color("#946ac1"))
		if texture==null or not texture.get_image().get_used_rect().has_area():failures.append("empty projectile: "+str(id))
		for i in range(101):
			var t:float=float(i)/100.0
			var q:=view.projectile_identity_sample(kind,route,t,0.0)
			if not q.is_finite():failures.append("nonfinite projectile path")
			if i==0 and q.distance_to(route[0])>.001:failures.append("projectile launch offset")
			if i==100 and q.distance_to(route[-1])>.001:failures.append("projectile impact offset")
			checks+=1
	# Confirmed impacts must override failed primary targets without inventing damage.
	var impact_points:Array=[Vector3(0,.5,0),Vector3(1.4,.5,0)]
	var impact_burst:Dictionary={"points":impact_points,"results":{},"damage":0}
	if view.resolve_element_impact(impact_burst).kind!="terrain":failures.append("empty terrain misclassified")
	impact_burst.results={Vector2i(1,0):{"damage":0,"misses":1}}
	if view.resolve_element_impact(impact_burst).kind!="miss":failures.append("miss misclassified")
	impact_burst.results[Vector2i(2,0)]={"damage":8}
	var redirected:=view.resolve_element_impact(impact_burst)
	if redirected.kind!="confirmed" or redirected.tile!=Vector2i(2,0) or int(redirected.damage)!=8:failures.append("secondary hit not redirected")
	impact_burst.results[Vector2i(1,0)]={"effects":1}
	if view.resolve_element_impact(impact_burst).tile!=Vector2i(1,0):failures.append("primary status effect ignored")
	impact_burst.results={};impact_burst.damage=5
	if view.resolve_element_impact(impact_burst).kind!="confirmed":failures.append("legacy enemy damage ignored")
	impact_burst.results={Vector2i(1,0):{"damage":0,"misses":1}}
	if view.resolve_element_impact(impact_burst).kind!="miss":failures.append("explicit miss overridden by aggregate damage")
	checks+=6
	# All status contracts select a nonempty semantic glyph.
	var status_count:int=0
	for id in Dungeon.Rules.MOVE_LIBRARY:
		var move:Dictionary=Dungeon.Rules.MOVE_LIBRARY[id]
		if str(move.category)!="status":continue
		status_count+=1
		var kind:String=view.status_finish_kind(move)
		if not Dungeon.STATUS_FINISH_STYLE.has(kind):
			failures.append("missing status finish: "+str(id))
			continue
		var style:Array=Dungeon.STATUS_FINISH_STYLE[kind]
		var texture:=view.combat_pixel_texture(str(style[0]),Color(style[1]),Color(style[2]))
		if texture==null or not texture.get_image().get_used_rect().has_area():failures.append("empty status glyph: "+str(id))
		checks+=1
	if status_count!=177:failures.append("status catalog changed")
	if view.status_finish_kind({"category":"status","stat_changes":{"attack":2}})!="boost":failures.append("boost classification")
	if view.status_finish_kind({"category":"status","stat_changes":{"defense":-1}})!="weaken":failures.append("weaken classification")
	if view.status_finish_kind({"category":"status","heal_fraction":.5})!="heal":failures.append("heal classification")
	if view.status_finish_kind({"category":"status","shield_kind":"protect"})!="shield":failures.append("shield classification")
	checks+=4
	# Ultimate presentation is bounded and only refers to actual damage moves.
	for id in Dungeon.ULTIMATE_ACCENTS:
		if not catalog.has(id) or str(catalog[id].category)=="status":failures.append("invalid ultimate accent: "+str(id))
		for i in range(101):
			var p:float=float(i)/100.0
			var envelope:Vector2=view.ultimate_envelope(p)
			if not envelope.is_finite() or envelope.x<-.0001 or envelope.x>1.001 or envelope.y<0.0 or envelope.y>1.001:failures.append("invalid cinematic envelope")
			if i==100 and envelope.length()>.001:failures.append("ultimate effect never expires")
			checks+=1
	# Outbound and return legs use exactly the original tile route.
	var movement_route:Array=[Vector3.ZERO,Vector3(1.4,0,0),Vector3(1.4,0,2.8)]
	for kind in ["air","ground","burrow","dive","vanish"]:
		for peak in [.4,.48,.64]:
			var launch:=view.tile_cast_sample(movement_route,kind,0.0,peak)
			var contact:=view.tile_cast_sample(movement_route,kind,peak,peak)
			var landing:=view.tile_cast_sample(movement_route,kind,1.0,peak)
			if Vector3(contact.position).distance_to(movement_route[-1])>.001 or not bool(contact.visible):failures.append("tile cast contact failed")
			if Vector3(landing.position).distance_to(movement_route[0])>.001 or not bool(landing.visible):failures.append("tile cast return failed")
			if kind in ["burrow","dive","vanish"] and bool(launch.visible):failures.append("concealed cast visible at launch")
			for i in range(101):
				var t:float=float(i)/100.0
				var motion_sample:=view.tile_cast_sample(movement_route,kind,t,peak)
				if not Vector3(motion_sample.position).is_finite() or float(motion_sample.path_progress)<0.0 or float(motion_sample.path_progress)>1.0:failures.append("invalid tile cast trajectory")
				checks+=1
	# Every nature has a visible, bounded environmental stamp and a finite fade.
	if Dungeon.SURFACE_STAMP.size()!=18:failures.append("surface stamp nature coverage")
	var silhouettes:Dictionary={}
	for element in Dungeon.SURFACE_STAMP:
		var ink:=view.surface_stamp_palette(element)
		var mode:String="surface_"+str(Dungeon.SURFACE_STAMP[element])
		var texture:=view.combat_pixel_texture(mode,ink[0],ink[1])
		if texture==null or not texture.get_image().get_used_rect().has_area():
			failures.append("empty surface stamp: "+str(element))
		var shape:=view.combat_pixel_texture(mode,Color.WHITE,Color.BLACK)
		silhouettes[mode]=shape.get_image().get_data()
		for step in range(101):
			var phase:float=float(step)/100.0
			var sample:Vector3=view.surface_stamp_sample(element,phase)
			if not sample.is_finite() or sample.x<=0.0 or sample.x>2.0 or sample.y<0.0 or sample.y>1.001 or sample.z<-.0001 or sample.z>1.001:
				failures.append("invalid surface envelope: "+str(element))
			if step==100 and absf(sample.y)>.0001:failures.append("surface stamp did not expire")
			checks+=1
	if silhouettes.size()!=12:failures.append("surface silhouette coverage")
	var modes:Array=silhouettes.keys()
	for i in range(modes.size()):
		for j in range(i+1,modes.size()):
			if silhouettes[modes[i]]==silhouettes[modes[j]]:failures.append("duplicate ground stamp")
			checks+=1
	# Anticipation and drive use exactly the same authored impact time.
	for peak in [.12,.34,.48,.64,.88]:
		var windup:=view.attack_direction_sample(peak*.17,peak)
		var contact:=view.attack_direction_sample(peak,peak)
		if windup.x<.99 or absf(windup.y)>.001:failures.append("missing anticipation")
		if absf(contact.y-1.0)>.001 or absf(contact.x)>.001:failures.append("contact clock mismatch")
		for kind in ["rush","contact","lash","aerial","down","spin","focus","gesture","cast"]:
			for step in range(101):
				var phase:float=float(step)/100.0
				var sample:=view.cast_motion_offset(kind,phase,peak)
				if not sample.is_finite() or sample.length()>1.0:failures.append("invalid cast direction")
				if step in [0,100] and sample.length()>.001:failures.append("cast offset did not return to neutral")
				checks+=1
	for step in range(101):
		var phase:float=float(step)/100.0
		var value:float=view.contact_camera_sample(phase)
		if not is_finite(value) or absf(value)>1.0:failures.append("unbounded camera impulse")
		if step in [0,100] and absf(value)>.001:failures.append("camera impulse endpoint")
		checks+=1
	# V22.0: equal-time contacts must not depend on active/retired traversal.
	for first_critical in [false,true]:
		view.fx_contact_camera=Vector3.ZERO;view.fx_contact_camera_age=1.0
		if first_critical:
			view.queue_contact_camera(Vector3.ZERO,Vector3.FORWARD,true,.04)
			view.queue_contact_camera(Vector3.ZERO,Vector3.RIGHT,false,.04)
		else:
			view.queue_contact_camera(Vector3.ZERO,Vector3.RIGHT,false,.04)
			view.queue_contact_camera(Vector3.ZERO,Vector3.FORWARD,true,.04)
		if not view.fx_contact_camera.is_equal_approx(Vector3.FORWARD*.065):failures.append("V22.0 concurrent critical priority")
		view.queue_contact_camera(Vector3.ZERO,Vector3.RIGHT,false,.05)
		if not view.fx_contact_camera.is_equal_approx(Vector3.FORWARD*.065):failures.append("V22.0 stale impact override")
		view.queue_contact_camera(Vector3.ZERO,Vector3.RIGHT,false,.02)
		if not view.fx_contact_camera.is_equal_approx(Vector3.RIGHT*.038):failures.append("V22.0 newest impact priority")
		checks+=3
	for reverse_order in [false,true]:
		view.fx_contact_camera=Vector3.ZERO;view.fx_contact_camera_age=1.0
		var directions:Array[Vector3]=[Vector3.RIGHT,Vector3.FORWARD]
		if reverse_order:directions.reverse()
		for direction in directions:view.queue_contact_camera(Vector3.ZERO,direction,true,.04)
		if not view.fx_contact_camera.is_equal_approx(Vector3.RIGHT*.065):failures.append("V22.0 equal-strength deterministic direction")
		view.queue_contact_camera(Vector3.ZERO,Vector3.ZERO,true,.01)
		if not view.fx_contact_camera.is_equal_approx(Vector3.RIGHT*.065):failures.append("V22.0 zero-length contact override")
		checks+=2
	view.fx_contact_camera=Vector3.ZERO;view.fx_contact_camera_age=1.0
	view.queue_contact_camera(Vector3.ZERO,Vector3.RIGHT,true,.18)
	if view.fx_contact_camera!=Vector3.ZERO:failures.append("V22.0 expired impulse replay")
	checks+=1
	# V22.2: active and retired hits at the same instant choose one body
	# reaction, regardless of the order in which the bursts were visited.
	var simultaneous_target:=Vector2i.ZERO
	var simultaneous_a:Dictionary={"target_player":true,"points":[Vector3.LEFT,Vector3.ZERO],"age":.54,"impact_times":[.5],"impact_cursor":1,"impact_waves":[{simultaneous_target:{"damage":30}}]}
	var simultaneous_b:Dictionary={"target_player":true,"points":[Vector3.BACK,Vector3.ZERO],"age":.54,"impact_times":[.5],"impact_cursor":1,"impact_waves":[{simultaneous_target:{"damage":8,"crit":1}}]}
	for order in [false,true]:
		var first:Dictionary=simultaneous_b if order else simultaneous_a
		var second:Dictionary=simultaneous_a if order else simultaneous_b
		var winner:=view.latest_player_impact(view.latest_player_impact({},first),second)
		if not bool(winner.get("critical",false)) or winner.get("direction",Vector3.ZERO)!=Vector3.FORWARD:failures.append("V22.2 simultaneous critical hurt")
		checks+=1
	simultaneous_b.impact_waves=[{simultaneous_target:{"damage":8}}]
	for order in [false,true]:
		var first:Dictionary=simultaneous_b if order else simultaneous_a
		var second:Dictionary=simultaneous_a if order else simultaneous_b
		var winner:=view.latest_player_impact(view.latest_player_impact({},first),second)
		if int(winner.get("damage",0))!=30 or winner.get("direction",Vector3.ZERO)!=Vector3.RIGHT:failures.append("V22.2 simultaneous damage hurt")
		checks+=1
	simultaneous_b.impact_waves=[{simultaneous_target:{"damage":30}}]
	for order in [false,true]:
		var first:Dictionary=simultaneous_b if order else simultaneous_a
		var second:Dictionary=simultaneous_a if order else simultaneous_b
		var winner:=view.latest_player_impact(view.latest_player_impact({},first),second)
		if winner.get("direction",Vector3.ZERO)!=Vector3.RIGHT:failures.append("V22.2 simultaneous directional hurt")
		checks+=1
	simultaneous_b.age=.52
	var newest:=view.latest_player_impact(view.latest_player_impact({},simultaneous_a),simultaneous_b)
	if newest.get("direction",Vector3.ZERO)!=Vector3.FORWARD:failures.append("V22.2 latest hurt priority")
	checks+=1
	simultaneous_b.impact_waves=[{simultaneous_target:{"damage":0,"crit":1}}]
	var confirmed:=view.latest_player_impact(view.latest_player_impact({},simultaneous_a),simultaneous_b)
	if confirmed.get("direction",Vector3.ZERO)!=Vector3.RIGHT:failures.append("V22.2 unconfirmed hurt override")
	checks+=1
	# Body deformation must peak on the same frame as the directional drive,
	# including very short anticipation windows and downward strikes.
	for peak in [.12,.34,.48,.64,.88]:
		for kind in ["rush","contact","lash","aerial","down","spin","focus","gesture","cast"]:
			var contact_body:=Art.attack_body_sample(peak,peak,kind)
			var previous_body:=Art.attack_body_sample(0.0,peak,kind)
			for step in range(101):
				var phase:float=float(step)/100.0
				var body:=Art.attack_body_sample(phase,peak,kind)
				var stretch:float=float(body.stretch)
				if not is_finite(stretch) or stretch<.84 or stretch>1.16 or float(body.lift)<0.0:failures.append("invalid continuous body")
				if step in [0,100] and (absf(stretch-1.0)>.001 or absf(float(body.lift))>.001):failures.append("body rest mismatch")
				if kind!="down" and stretch>float(contact_body.stretch)+.001:failures.append("extension after contact")
				if absf(stretch-float(previous_body.stretch))>.13:failures.append("body transition jump")
				previous_body=body
				checks+=1
			var before:=Art.attack_body_sample(peak-.0001,peak,kind)
			var after:=Art.attack_body_sample(peak+.0001,peak,kind)
			if absf(float(before.stretch)-float(after.stretch))>.001:failures.append("body contact discontinuity")
			if kind in ["aerial","down"]:
				var landed:=view.cast_motion_offset(kind,peak,peak)
				var near_landing:=view.cast_motion_offset(kind,peak-.0001,peak)
				if absf(landed.y)>.0001 or absf(near_landing.y)>.0001:failures.append("abrupt landing")
			checks+=1
	# Anatomical casts retain bounded continuous geometry, with a unique
	# contact position/deformation signature per motion family.
	var anatomy_kinds:Array=["fang","crunch","claw","pincer","punch","uppercut","kick","lowkick","wing","tail","horn"]
	var anatomy_signatures:Dictionary={}
	for kind in anatomy_kinds:
		var at_contact:=view.cast_motion_offset(kind,.48,.48)
		var body_contact:=Art.attack_body_sample(.48,.48,kind)
		var signature:=str(at_contact)+str(body_contact)
		if anatomy_signatures.has(signature):failures.append("duplicate anatomy "+kind)
		anatomy_signatures[signature]=true
		for peak in [.12,.34,.48,.64,.88]:
			for step in range(101):
				var phase:float=float(step)/100.0
				var motion:=view.cast_motion_offset(kind,phase,peak)
				var body:=Art.attack_body_sample(phase,peak,kind)
				if not motion.is_finite() or motion.length()>1.0 or float(body.stretch)<.84 or float(body.stretch)>1.16:failures.append("anatomical motion bounds "+kind)
				if step in [0,100] and (motion.length()>.001 or absf(float(body.stretch)-1.0)>.001):failures.append("anatomical motion rest "+kind)
				checks+=1
	var anatomy_expected:Dictionary={"eos_063":"fang","eos_062":"crunch","eos_065":"punch","eos_092":"lowkick","eos_136":"uppercut","eos_008":"contact","eos_153":"aerial","eos_205":"aerial"}
	for id in anatomy_expected:
		if view.cast_motion_kind(id,view.combat_profile(id))!=anatomy_expected[id]:failures.append("incorrect anatomical cast "+id)
		checks+=1
	# Every creature owns a distinct authored response, without changing the
	# neutral endpoints or tile-based travel rules.
	var creature_signatures:Dictionary={}
	for species in Art.ENEMY_PIXEL_PILOTS:
		var anatomy:=Art.creature_cast_profile(species)
		if not Art.CREATURE_CAST_PROFILES.has(species):failures.append("missing creature cast profile "+species)
		if creature_signatures.has(str(anatomy)):failures.append("duplicate creature cast profile "+species)
		creature_signatures[str(anatomy)]=true
		for kind in ["rush","contact","lash","aerial","down","spin","focus","gesture","cast","fang","crunch","claw","pincer","punch","uppercut","kick","lowkick","wing","tail","horn"]:
			for step in range(101):
				var phase:float=float(step)/100.0
				var motion:=Art.creature_cast_offset(view.cast_motion_offset(kind,phase,.48),species)
				var body:=Art.attack_body_sample(phase,.48,kind,species)
				if not motion.is_finite() or motion.length()>1.0 or float(body.stretch)<.78 or float(body.stretch)>1.22 or float(body.lift)<0.0:failures.append("creature cast bounds "+species+" "+kind)
				if step in [0,100] and (motion.length()>.001 or absf(float(body.stretch)-1.0)>.001 or absf(float(body.lift))>.001):failures.append("creature cast endpoint "+species+" "+kind)
				checks+=1
	if creature_signatures.size()!=Art.ENEMY_PIXEL_PILOTS.size():failures.append("creature profile coverage")
	if Art.creature_cast_profile("")!=Vector4.ONE:failures.append("neutral companion profile")
	# Native anatomical strike cells must differ from their base art, while
	# incompatible imported atlases remain protected by the expression guard.
	var anatomy_visible:int=0
	var anatomy_visibility:Dictionary={}
	if Art.ENEMY_COMBAT_APPENDAGES.size()!=33 or Art.ENEMY_COMBAT_APPENDAGES.size()!=Art.ENEMY_PIXEL_PILOTS.size():failures.append("full anatomy registry coverage")
	for species in Art.ENEMY_PIXEL_PILOTS:
		if not species in Art.ENEMY_COMBAT_APPENDAGES:failures.append("missing anatomical species "+species)
	for species in Art.ENEMY_COMBAT_APPENDAGES:
		var species_changed:bool=false
		var species_visible:int=0
		for direction in range(8):
			var base:=Art.enemy_pixel_cell(species,direction,"attack",1,false,0)
			var first:=Art.enemy_pixel_cell(species,direction,"attack",1,false,1)
			var second:=Art.enemy_pixel_cell(species,direction,"attack",1,false,2)
			if base.get_size()!=Vector2i(48,48) or first.get_size()!=base.get_size() or second.get_size()!=base.get_size() or not first.get_used_rect().has_area() or not second.get_used_rect().has_area():
				failures.append("invalid combat appendage cell "+species)
			if first.get_data()!=second.get_data():species_changed=true
			var native_texture:=Art.enemy_pixel_texture(species,direction,"attack",1,false,0)
			var attack_texture:=Art.enemy_pixel_texture(species,direction,"attack",1,false,1)
			var recovery_texture:=Art.enemy_pixel_texture(species,direction,"attack",1,false,2)
			if native_texture==null or attack_texture==null or recovery_texture==null:failures.append("missing native combat appendage "+species)
			elif attack_texture!=native_texture or recovery_texture!=native_texture:
				anatomy_visible+=1
				species_visible+=1
			for pose in ["windup","recover","defeat","sleep"]:
				if Art.enemy_pixel_texture(species,direction,pose,0,false,2)!=Art.enemy_pixel_texture(species,direction,pose,0,false,0):failures.append("combat part overrides "+pose+" "+species)
				checks+=1
			if Art.enemy_pixel_texture(species,direction,"hurt",0,false,2)!=Art.enemy_pixel_texture(species,direction,"hurt",0,false,0):failures.append("appendage overrides hurt "+species)
			checks+=1
		if not species_changed:failures.append("static native appendage "+species)
		anatomy_visibility[species]=species_visible
	for peak in [.12,.34,.48,.64,.88]:
		if Art.combat_appendage_stage(peak-.0001,peak)!=0 or Art.combat_appendage_stage(peak,peak)!=1 or Art.combat_appendage_stage(peak+(1.0-peak)*.30,peak)!=2 or Art.combat_appendage_stage(1.0,peak)!=0:failures.append("appendage phase contract")
		checks+=1
	print("KINDRIA_COMBAT_APPENDAGES species=",Art.ENEMY_COMBAT_APPENDAGES.size()," visible_direction_variants=",anatomy_visible)
	print("KINDRIA_ANATOMY_VISIBILITY ",JSON.stringify(anatomy_visibility))
	# Attack-specific slots must resolve to existing native anatomy only.
	var slot_routes:int=0
	for species in Art.ENEMY_PIXEL_PILOTS:
		if not Art.COMBAT_ANATOMY_SLOTS.has(species):failures.append("missing anatomy slot registry "+species)
		for motion in Art.MOTION_ANATOMY:
			var slot:String=Art.combat_anatomy_slot(species,motion)
			if not slot.is_empty() and not slot in Art.COMBAT_ANATOMY_SLOTS.get(species,[]):failures.append("unsupported anatomy slot "+species)
			if not slot.is_empty():slot_routes+=1
			checks+=1
	var targeted_cases:Dictionary={"tidal_sovereign":["jaw","tail"],"vinesnap":["jaw","leaf"],"fungal_monarch":["aura","limbs"],"marrowray":["wing","tail"],"rootgnawer":["horn","legs"]}
	for species in targeted_cases:
		var slots:Array=targeted_cases[species]
		var distinct:bool=false
		for direction in range(8):
			var left:=Art.enemy_pixel_cell(species,direction,"attack",1,false,2,str(slots[0]))
			var right:=Art.enemy_pixel_cell(species,direction,"attack",1,false,2,str(slots[1]))
			if left.get_data()!=right.get_data():distinct=true
			var plain:=Art.enemy_pixel_texture(species,direction,"attack",1)
			var unsupported:=Art.enemy_pixel_texture(species,direction,"attack",1,false,2,"unavailable")
			if plain!=unsupported:failures.append("unsupported anatomy allocated variant "+species)
			checks+=1
		if not distinct:failures.append("identical targeted anatomy "+species)
	if Art.combat_anatomy_slot("tidal_sovereign","crunch")!="jaw" or Art.combat_anatomy_slot("tidal_sovereign","tail")!="tail" or Art.combat_anatomy_slot("comet_hare","kick")!="legs" or not Art.combat_anatomy_slot("nova_wisp","punch").is_empty():failures.append("incorrect anatomical routing")
	checks+=4
	print("KINDRIA_ATTACK_ANATOMY routes=",slot_routes," multislot_species=",targeted_cases.size())

	# Body timing shares the actual attempts ledger (including misses), not
	# a guessed nominal hit count. Each segment returns to neutral.
	var wave_event:Dictionary={"results":{Vector2i(1,0):{"damage":9,"attempts":[{"damage":3},{"damage":0,"misses":1},{"damage":6}]}}}
	for duration in [.18,.44,.8,1.2]:
		for peak in [.12,.34,.48,.64,.88]:
			var times:=view.caster_wave_times(wave_event,duration,peak)
			if times!=view.reaction_times(duration,peak,3):failures.append("caster attempt timing mismatch")
			for time in times:
				var progress:float=view.caster_wave_progress(time,duration,peak,times)
				if absf(progress-peak)>.0001:failures.append("caster wave contact mismatch")
				var body:=Art.attack_body_sample(progress,peak,"punch")
				var expected:=Art.attack_body_sample(peak,peak,"punch")
				if absf(float(body.stretch)-float(expected.stretch))>.0001:failures.append("caster deformation not at impact")
				checks+=1
			for i in range(times.size()-1):
				var midpoint:float=(times[i]+times[i+1])*.5
				var before:=view.cast_motion_offset("punch",view.caster_wave_progress(midpoint-.000001,duration,peak,times),peak)
				var after:=view.cast_motion_offset("punch",view.caster_wave_progress(midpoint+.000001,duration,peak,times),peak)
				if before.distance_to(after)>.001:failures.append("multi-hit body boundary discontinuity")
				checks+=1
			for step in range(101):
				var time:float=duration*float(step)/100.0
				var progress:float=view.caster_wave_progress(time,duration,peak,times)
				if not is_finite(progress) or progress<0.0 or progress>1.0:failures.append("invalid caster wave clock")
				if absf(view.caster_wave_progress(time,duration,peak,[])-float(step)/100.0)>.0001:failures.append("single-hit body clock changed")
				checks+=1
			if view.caster_wave_progress(0.0,duration,peak,times)!=0.0 or view.caster_wave_progress(duration,duration,peak,times)!=1.0:failures.append("caster wave endpoints")
			checks+=1
	# Critical finish is local to the active wave and actual damage row.
	var critical_tile:=Vector2i(1,0)
	var normal_tile:=Vector2i(2,0)
	var critical_burst:Dictionary={"duration":.8,"age":.2,"impact_cursor":1,"impact_times":[.2,.4,.6],"impact_waves":[{critical_tile:{"damage":7,"crit":0}},{critical_tile:{"damage":9,"crit":1},normal_tile:{"damage":6,"crit":0}},{critical_tile:{"damage":0,"crit":1,"misses":1}}]}
	if not view.critical_impact_tiles(critical_burst).is_empty():failures.append("future critical leak")
	critical_burst.age=.4;critical_burst.impact_cursor=2
	if view.critical_impact_tiles(critical_burst)!=[critical_tile]:failures.append("critical target isolation")
	critical_burst.age=.59
	if not view.critical_impact_tiles(critical_burst).is_empty():failures.append("expired critical flash")
	critical_burst.age=.6;critical_burst.impact_cursor=3
	if not view.critical_impact_tiles(critical_burst).is_empty():failures.append("false critical on miss")
	checks+=4
	var critical_texture:=view.combat_pixel_texture("critical_flash",Color("#fff3c2"),Color("#e0a34c"))
	if critical_texture==null or not critical_texture.get_image().get_used_rect().has_area():failures.append("empty critical flash")
	checks+=1
	var prior_flash:float=1.0
	var prior_ring:float=0.0
	for step in range(101):
		var critical_sample:=view.critical_finish_sample(float(step)/100.0)
		if not critical_sample.is_finite() or critical_sample.x<0.0 or critical_sample.x>prior_flash+.0001 or critical_sample.y<prior_ring-.0001 or critical_sample.y>1.47:failures.append("critical envelope")
		if step==100 and critical_sample.x>.0001:failures.append("critical flash not expired")
		prior_flash=critical_sample.x;prior_ring=critical_sample.y
		checks+=1
	# Every elemental terminal profile has a material and bounded trajectory.
	var terminal_signatures:Dictionary={}
	if Dungeon.ELEMENT_DISSIPATION.size()!=18:failures.append("elemental dissipation coverage")
	for element in Dungeon.ELEMENT_FINISH_MODE:
		if not Dungeon.ELEMENT_DISSIPATION.has(element):
			failures.append("missing dissipation "+element)
			continue
		var cue:Array=Dungeon.ELEMENT_DISSIPATION[element]
		if terminal_signatures.has(str(cue)):failures.append("duplicate dissipation profile "+element)
		terminal_signatures[str(cue)]=true
		var terminal_texture:=view.combat_pixel_texture(str(cue[0]),Color("#fff3c2"),Color("#e0a34c"))
		if terminal_texture==null or not terminal_texture.get_image().get_used_rect().has_area():failures.append("empty dissipation texture "+element)
		for step in range(101):
			var phase:float=float(step)/100.0
			for particle_index in range(5):
				var terminal:=view.elemental_dissipation_sample(element,phase,particle_index)
				var offset:=view.elemental_dissipation_offset(element,phase,particle_index,5)
				if not terminal.is_finite() or not offset.is_finite() or terminal.x<0.0 or terminal.x>1.1 or terminal.z<.3 or terminal.z>1.41 or terminal.w<0.0 or terminal.w>1.001 or offset.length()>1.3:failures.append("dissipation bounds "+element)
				if step==100 and terminal.w>.0001:failures.append("dissipation did not expire "+element)
				checks+=1
	if view.elemental_dissipation_sample("fire",.9).y<=0.0 or view.elemental_dissipation_sample("ice",.9).y>=0.0 or view.elemental_dissipation_sample("psychic",.9).x>=view.elemental_dissipation_sample("psychic",.1).x:failures.append("elemental trajectory distinction")
	checks+=1
	# Lighting is local, elemental, finite and bounded by the original pool.
	var lighting_signatures:Dictionary={}
	if Dungeon.ELEMENT_LIGHT_PROFILE.size()!=18:failures.append("elemental light profile coverage")
	for element in Dungeon.ELEMENT_FINISH_MODE:
		if not Dungeon.ELEMENT_LIGHT_PROFILE.has(element):
			failures.append("missing elemental light "+element)
			continue
		var cue:Array=Dungeon.ELEMENT_LIGHT_PROFILE[element]
		if lighting_signatures.has(str(cue)):failures.append("duplicate light profile "+element)
		lighting_signatures[str(cue)]=true
		for stage in ["launch","impact","residue"]:
			for step in range(101):
				var phase:float=float(step)/100.0
				var sample:=view.elemental_light_sample(element,phase,stage)
				var wide_sample:=view.elemental_light_sample(element,phase,stage,true)
				if not sample.is_finite() or sample.x<0.0 or sample.x>1.201 or sample.y<1.0 or sample.y>2.7 or sample.z<1.0 or sample.z>3.0:failures.append("light profile bounds "+element)
				if wide_sample.y<sample.y or wide_sample.y>3.2 or wide_sample.x!=sample.x:failures.append("wide light bounds "+element)
				if step==100 and sample.x>.0001:failures.append("light did not expire "+element)
				if stage=="launch" and step==0 and sample.x>.0001:failures.append("launch light starts abruptly "+element)
				checks+=1
	if view.cinematic_light_slot([],2,1.0)!=0 or view.cinematic_light_slot([1.0],2,2.0)!=1 or view.cinematic_light_slot([4.8,2.9],2,6.2)!=1 or view.cinematic_light_slot([4.8,2.9],2,1.9)!=-1 or view.cinematic_light_slot([2.5],1,4.2)!=0 or view.cinematic_light_slot([],0,6.0)!=-1:failures.append("light pool priority")
	checks+=6
	# Local environmental response must expire and never grow stronger on
	# empty terrain than on a confirmed hit.
	var environmental_signatures:Dictionary={}
	if Dungeon.ELEMENT_ENVIRONMENT_RESPONSE.size()!=18:failures.append("environment response coverage")
	for element in Dungeon.ELEMENT_FINISH_MODE:
		if not Dungeon.ELEMENT_ENVIRONMENT_RESPONSE.has(element):
			failures.append("missing environment response "+element)
			continue
		var signature:String=str(Dungeon.ELEMENT_ENVIRONMENT_RESPONSE[element])
		if environmental_signatures.has(signature):failures.append("duplicate environment response "+element)
		environmental_signatures[signature]=true
		for step in range(101):
			var phase:float=float(step)/100.0
			var response:=view.environmental_response_sample(element,phase)
			var terrain:=view.environmental_response_sample(element,phase,true)
			if not response.is_finite() or response.x<1.0 or response.x>3.2001 or absf(response.y)>1.0001 or response.z<0.0 or response.z>1.0 or response.w<0.0 or response.w>.5:failures.append("environment response bounds "+element)
			if absf(terrain.y-response.y*.45)>.0001 or absf(terrain.z-response.z*.45)>.0001 or absf(terrain.w-response.w*.45)>.0001:failures.append("terrain response strength "+element)
			if step==100 and (absf(response.y)+response.z+response.w)>.0001:failures.append("environment response not expired "+element)
			checks+=1
	var old_mark:Dictionary={"at":Vector3(1,0,1),"age":.95,"life":1.0,"element":"water","terrain_only":false,"color":Color.BLUE}
	var live_mark:Dictionary={"at":Vector3(4,0,2),"age":.05,"life":1.0,"element":"flying","terrain_only":false,"color":Color.WHITE}
	var picked:=view.exterior_response_pick([live_mark,old_mark])
	if picked.is_empty() or Vector4(picked.pulse).x!=4.0:failures.append("environment impulse priority")
	old_mark.age=1.0;live_mark.age=1.0
	if not view.exterior_response_pick([live_mark,old_mark]).is_empty():failures.append("expired exterior impulse")
	checks+=2
	# Local shader warps must have distinct authored profiles, bounded amplitudes,
	# exact neutral endpoints, and a deterministic low-tier fallback.
	var distortion_signatures:Dictionary={}
	var distortion_families:Dictionary={}
	if Dungeon.ELEMENT_DISTORTION.size()!=18:failures.append("elemental distortion coverage")
	for element in Dungeon.ELEMENT_FINISH_MODE:
		if not Dungeon.ELEMENT_DISTORTION.has(element):
			failures.append("missing distortion "+element)
			continue
		var cue:Vector3=Dungeon.ELEMENT_DISTORTION[element]
		if distortion_signatures.has(str(cue)):failures.append("duplicate distortion profile "+element)
		distortion_signatures[str(cue)]=true
		distortion_families[int(cue.x)]=true
		for stage in ["launch","impact"]:
			for step in range(101):
				var phase:float=float(step)/100.0
				var high_sample:=view.elemental_distortion_sample(element,phase,stage,0)
				var medium_sample:=view.elemental_distortion_sample(element,phase,stage,1)
				var low_sample:=view.elemental_distortion_sample(element,phase,stage,2)
				if not high_sample.is_finite() or high_sample.x<1.0 or high_sample.x>6.0 or high_sample.y<0.0 or high_sample.y>.141 or high_sample.z<4.0 or high_sample.z>23.0:failures.append("distortion bounds "+element)
				if absf(medium_sample.y-high_sample.y*.55)>.0001 or low_sample!=Vector3.ZERO:failures.append("distortion tier fallback "+element)
				if step==100 and high_sample.y>.0001:failures.append("distortion did not expire "+element)
				if stage=="launch" and step==0 and high_sample.y>.0001:failures.append("distortion launch discontinuity "+element)
				checks+=1
		if view.elemental_distortion_sample(element,.5,"none",0)!=Vector3.ZERO:failures.append("distortion on disabled stage "+element)
		checks+=1
	if distortion_families.size()!=6:failures.append("distortion family coverage")
	checks+=1
	# V17: exact catalog membership, not the obsolete eight-move pilot count.
	var remastered:Dictionary={}
	for id in Dungeon.VISUAL_REMASTER_MOVES:
		if remastered.has(id):failures.append("duplicate remaster registration "+str(id))
		if not catalog.has(id):failures.append("unknown remaster registration "+str(id))
		remastered[id]=true
		checks+=1
	for id in catalog:
		if not remastered.has(id):failures.append("missing remaster registration "+str(id))
		checks+=1
	if remastered.size()!=catalog.size():failures.append("visual remaster coverage")
	# Directed contact art is independently visible and kick poses are animated.
	for id in Dungeon.CONTACT_ICON_KIND:
		var kind:String=view.directed_contact_kind(id,str(view.combat_profile(id).role))
		var previous:PackedByteArray=[]
		for stage in range(3):
			var image:Image=view.contact_icon_image(kind,stage,Color("#fff1bc"),Color("#926185"))
			if not image.get_used_rect().has_area():failures.append("empty directed contact: "+str(id))
			if kind.begins_with("kick") and stage>0 and image.get_data()==previous:failures.append("static kick pose: "+str(id))
			previous=image.get_data()
			checks+=1
	var contact_tile:=Vector2i(1,0)
	var contact_burst:Dictionary={"duration":.6,"age":.21,"impact_times":[.2,.3,.4],"impact_cursor":1,"impact_waves":[{contact_tile:{"damage":7}},{contact_tile:{"damage":0,"misses":1}},{contact_tile:{"damage":9}}]}
	var first_contact:=view.contact_wave_sample(contact_burst)
	if first_contact.is_empty() or int(first_contact.results[contact_tile].damage)!=7:failures.append("first contact wave")
	contact_burst.age=.31;contact_burst.impact_cursor=2
	var missed_contact:=view.contact_wave_sample(contact_burst)
	if missed_contact.is_empty() or int(missed_contact.results[contact_tile].damage)!=0:failures.append("intermediate miss lost")
	contact_burst.age=.41;contact_burst.impact_cursor=3
	var last_contact:=view.contact_wave_sample(contact_burst)
	if last_contact.is_empty() or int(last_contact.results[contact_tile].damage)!=9:failures.append("third contact wave")
	contact_burst.age=.60
	if not view.contact_wave_sample(contact_burst).is_empty():failures.append("contact did not expire")
	checks+=4
	# V19.4: a miss cannot trigger recoil, and a later confirmed attempt can.
	var player_tile:=Vector2i(1,0)
	var player_wave:Dictionary={"target_player":true,"points":[Vector3(0,.5,0),Vector3(1.4,.5,0)],"damage":16,"age":.21,"impact_cursor":1,"impact_times":[.2,.3,.4],"impact_waves":[{player_tile:{"damage":0,"misses":1}},{player_tile:{"damage":7}},{player_tile:{"damage":9}}]}
	if not view.latest_player_impact({},player_wave,0).is_empty():failures.append("player first miss recoil")
	player_wave.age=.31;player_wave.impact_cursor=2
	var player_second:=view.latest_player_impact({},player_wave,1)
	if player_second.is_empty() or absf(float(player_second.age)-.01)>.00001:failures.append("player second hit timing")
	if not view.latest_player_impact({},player_wave,2).is_empty():failures.append("player duplicate recoil")
	player_wave.age=.42;player_wave.impact_cursor=3
	var player_lagged:=view.latest_player_impact({},player_wave,0)
	if player_lagged.is_empty() or absf(float(player_lagged.age)-.02)>.00001:failures.append("player newest hit under lag")
	player_wave.impact_waves[2]={Vector2i(2,0):{"damage":9}}
	if not view.latest_player_impact({},player_wave,2).is_empty():failures.append("other tile must not cause player recoil")
	player_wave.target_player=false
	if not view.latest_player_impact({},player_wave,0).is_empty():failures.append("non-player recoil")
	checks+=6
	# Validate actual authored projectile forms on the same bent route as the
	# existing family tests, including finite lagged samples and budget limits.
	var directed_forms:Dictionary={}
	for id in Dungeon.PROJECTILE_IDENTITY:
		var form:=view.directed_projectile_form(id,str(view.combat_profile(id).role))
		directed_forms[form]=true
	for role in Dungeon.PROJECTILE_ROLE_FORM:
		directed_forms[Dungeon.PROJECTILE_ROLE_FORM[role]]=true
	for form in directed_forms:
		var texture:=view.combat_pixel_texture("projectile_"+str(form),Color("#ffe5ab"),Color("#946ac1"))
		if texture==null or not texture.get_image().get_used_rect().has_area():failures.append("empty directed projectile: "+str(form))
		var budget:=view.projectile_form_profile(form)
		if not budget.is_finite() or budget.x<=0.0 or budget.y<=0.0 or budget.z<1.0 or budget.z>5.0:failures.append("invalid projectile budget")
		for i in range(101):
			var phase:float=float(i)/100.0
			var head:=view.projectile_identity_sample(form,route,phase,0.0)
			var tail:=view.projectile_identity_sample(form,route,phase,budget.y)
			if not head.is_finite() or not tail.is_finite():failures.append("nonfinite directed projectile")
			if i==0 and head.distance_to(route[0])>.001:failures.append("directed launch mismatch")
			if i==100 and head.distance_to(route[-1])>.001:failures.append("directed impact mismatch")
			checks+=1
	# Directed impact shapes and envelopes must be valid across every nature.
	var impact_forms:Dictionary={}
	for element in Dungeon.IMPACT_ELEMENT_FORM:
		impact_forms[Dungeon.IMPACT_ELEMENT_FORM[element]]=true
	for role in Dungeon.IMPACT_ROLE_FORM:
		impact_forms[Dungeon.IMPACT_ROLE_FORM[role]]=true
	if Dungeon.IMPACT_ELEMENT_FORM.size()!=18 or impact_forms.size()!=21:failures.append("impact form coverage")
	for form in impact_forms:
		var texture:=view.combat_pixel_texture("impact_"+str(form),Color("#ffe5ab"),Color("#946ac1"))
		if texture==null or not texture.get_image().get_used_rect().has_area():failures.append("empty directed impact: "+str(form))
		for i in range(101):
			var phase:float=float(i)/100.0
			var sample:=view.directed_impact_sample(form,phase)
			if not sample.is_finite() or sample.x<0.0 or sample.y<-.0001 or sample.z<0.0 or sample.z>1.001:failures.append("invalid impact envelope")
			if i==100 and absf(sample.z)>.0001:failures.append("impact failed to expire")
			checks+=1
	if view.directed_impact_sample("implosion",.8).x>=view.directed_impact_sample("implosion",.2).x:failures.append("implosion does not contract")
	if view.directed_impact_sample("detonation",.8).x<=view.directed_impact_sample("detonation",.2).x:failures.append("detonation does not expand")
	var impact_test:Dictionary={"points":[Vector3.ZERO,Vector3(1.4,.6,0)],"damage":16,"results":{Vector2i(1,0):{"damage":16}},"impact_waves":[{Vector2i(1,0):{"damage":0,"misses":1}},{Vector2i(1,0):{"damage":16}}],"impact_cursor":1}
	if view.resolve_element_impact(view.impact_visual_view(impact_test)).kind!="miss":failures.append("future hit leaked into miss")
	impact_test.impact_cursor=2
	if view.resolve_element_impact(view.impact_visual_view(impact_test)).kind!="confirmed":failures.append("confirmed wave lost")
	checks+=4
	# All elemental materials select finite, bounded parameters for the pooled shader.
	var families:Dictionary={}
	for element in Dungeon.ELEMENT_MATERIAL:
		var material:=view.elemental_material_profile(element)
		families[int(material.x)]=true
		if not material.is_finite() or material.x<0.0 or material.x>11.0 or material.y<=0.0 or material.y>1.0 or material.z<0.0 or material.z>1.2+.001:failures.append("invalid elemental material: "+str(element))
		checks+=1
	if Dungeon.ELEMENT_MATERIAL.size()!=18 or families.size()!=12:failures.append("elemental material coverage")
	var material_light:=Color("#d6b6a0")
	var material_dark:=Color("#44342d")
	for family in range(12):
		for y in range(16):
			for x in range(16):
				for inner in [true,false]:
					var pixel:=view.particle_material_pixel(family,Vector2(x-7.5,y-7.5),inner,material_light,material_dark)
					if not is_finite(pixel.r) or not is_finite(pixel.g) or not is_finite(pixel.b) or not is_finite(pixel.a) or pixel.r<0.0 or pixel.r>1.001 or pixel.g<0.0 or pixel.g>1.001 or pixel.b<0.0 or pixel.b>1.001 or pixel.a<=0.0 or pixel.a>1.001:failures.append("invalid material pixel")
					checks+=1
	if view.particle_material_pixel(2,Vector2(4,4),false,material_light,material_dark).a>=1.0:failures.append("water not translucent")
	if view.particle_material_pixel(3,Vector2.ZERO,true,material_light,material_dark).r<=material_light.r:failures.append("electric core not luminous")
	checks+=2
	# Audio timing is deterministic and every synthesized PCM buffer has
	# silent endpoints, bounded peaks and audible energy.
	for phase in ["launch","impact","miss","status"]:
		for i in range(101):
			var envelope:float=view.combat_audio_envelope(float(i)/100.0,phase)
			if not is_finite(envelope) or envelope<0.0 or envelope>1.001:failures.append("invalid audio envelope")
			if i in [0,100] and absf(envelope)>.000001:failures.append("audio envelope endpoint")
			checks+=1
	var audio_ids:Array=["eos_062","eos_063","eos_065","eos_092","eos_127","eos_155","eos_193","eos_239","eos_280","eos_345","eos_453","eos_483","eos_538","lib_grass_2","lib_water_2","lib_fire_2","lib_fairy_1","lib_steel_2"]
	var audio_signatures:Dictionary={}
	for id in audio_ids:
		var profile:=view.combat_profile(id)
		var form:=view.combat_audio_form(id,profile)
		for phase in ["launch","impact","miss","status"]:
			var audio:=view.combat_sound(id,phase,0)
			var pcm:PackedByteArray=audio.data
			if pcm.size()<1000 or audio.mix_rate!=22050 or audio.stereo:failures.append("invalid combat PCM")
			if pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0:failures.append("nonzero audio endpoint")
			var peak:int=0
			for offset in range(0,pcm.size(),2):
				peak=maxi(peak,absi(pcm.decode_s16(offset)))
			if peak<100 or peak>31130:failures.append("invalid combat audio level")
			var signature:=pcm.hex_encode()
			if audio_signatures.has(signature):failures.append("duplicate combat audio")
			audio_signatures[signature]=true
			var expected:float=view.combat_audio_duration(profile,form,phase)
			if absf(float(pcm.size())/2.0/22050.0-expected)>.0001:failures.append("combat audio duration mismatch")
			checks+=1
	if view.combat_audio_form("eos_062",view.combat_profile("eos_062"))!="crunch":failures.append("crunch acoustic identity")
	if view.combat_audio_form("eos_063",view.combat_profile("eos_063"))!="fang":failures.append("bite acoustic identity")
	checks+=2
	# V19.6 audio variants: verify each nature in impact and status phases.
	var audio_natures:Dictionary={}
	for id in catalog:
		var nature:String=str(view.combat_profile(id).element)
		if audio_natures.has(nature):continue
		audio_natures[nature]=id
		for phase in ["impact","status"]:
			var previous:=PackedByteArray()
			for variant in range(3):
				var sample:=view.combat_sound(id,phase,variant)
				var bytes:PackedByteArray=sample.data
				var peak:int=0
				for offset in range(0,bytes.size(),2):
					peak=maxi(peak,absi(bytes.decode_s16(offset)))
				if bytes.size()<1000 or peak<100 or peak>31130 or bytes.decode_s16(0)!=0 or bytes.decode_s16(bytes.size()-2)!=0:failures.append("V19.6 PCM "+nature+" "+phase)
				if bytes==previous:failures.append("V19.6 duplicate variant "+nature+" "+phase)
				if view.combat_sound(id,phase,variant).data!=bytes:failures.append("V19.6 unstable cache "+nature+" "+phase)
				previous=bytes
				checks+=3
	if audio_natures.size()!=18:failures.append("V19.6 missing acoustic nature")
	checks+=1
	# V19.7 acoustic gestures: every catalog move has a bounded semantic profile.
	var gesture_groups:Dictionary={}
	for id in catalog:
		var gesture:Vector4=view.combat_audio_gesture(id,view.combat_profile(id))
		if not gesture.is_finite() or gesture.x<60.0 or gesture.x>2000.0 or gesture.x+gesture.y<30.0 or gesture.z<1.0 or gesture.z>7.0 or gesture.w<0.0 or gesture.w>1.0:failures.append("V19.7 invalid gesture "+str(id))
		var max_sample:float=0.0
		for i in range(21):
			var progress:float=float(i)/20.0
			var sample:float=view.combat_audio_gesture_sample(gesture,progress*.2,progress,1.0,.5,-.3)
			if not is_finite(sample) or absf(sample)>1.0:failures.append("V19.7 gesture sample "+str(id))
			max_sample=maxf(max_sample,absf(sample))
		if max_sample<.005:failures.append("V19.7 silent gesture "+str(id))
		gesture_groups[str(gesture)]=true
		checks+=23
	if gesture_groups.size()<35:failures.append("V19.7 insufficient gesture variety")
	checks+=1
	for group in [["eos_262","eos_053","eos_291","eos_157"],["eos_308","eos_240","eos_239","eos_255"],["eos_064","eos_193","eos_489","eos_521"]]:
		var seen_gestures:Dictionary={}
		for id in group:
			var gesture:Vector4=view.combat_audio_gesture(id,view.combat_profile(id))
			if seen_gestures.has(str(gesture)):failures.append("V19.7 same-nature gesture collision "+id)
			seen_gestures[str(gesture)]=true
			checks+=1
	# V19.8 environmental cues are bounded, ordered and subordinate to contact.
	for id in catalog:
		var profile:Dictionary=view.combat_profile(id)
		var cues:Array=view.combat_environment_audio_plan(id,profile)
		var last_fraction:float=-1.0
		if cues.size()>2:failures.append("V19.8 excessive environmental cues "+str(id))
		for cue in cues:
			var fraction:float=float(cue.fraction)
			if not is_finite(fraction) or fraction<last_fraction or fraction<0.0 or fraction>=1.0:failures.append("V19.8 environment timing "+str(id))
			last_fraction=fraction
			if not str(cue.phase).begins_with("env_") or str(cue.anchor) not in ["travel","terrain","surface"]:failures.append("V19.8 environment phase "+str(id))
			checks+=2
		checks+=1
	var env_ids:Array=["eos_008","eos_156","eos_153","eos_477"]
	var env_phases:Array=["env_dig","env_dive","env_wind","env_vanish"]
	for i in range(env_ids.size()):
		var id:String=env_ids[i]
		var cues:Array=view.combat_environment_audio_plan(id,view.combat_profile(id))
		if cues.size()!=2 or str(cues[0].phase)!=env_phases[i] or str(cues[1].anchor)!="terrain":failures.append("V19.8 travel identity "+id)
		checks+=1
	var env_cell:=Vector2i(3,4)
	if view.combat_environment_surface_allowed({env_cell:{"damage":0}},env_cell,0,"fire"):failures.append("V19.8 false surface contact")
	if not view.combat_environment_surface_allowed({env_cell:{"damage":1}},env_cell,1,"fire"):failures.append("V19.8 missing confirmed surface")
	if not view.combat_environment_surface_allowed({},env_cell,0,"water"):failures.append("V19.8 empty terrain water")
	if view.combat_environment_surface_allowed({},env_cell,0,"ghost"):failures.append("V19.8 false spectral surface")
	checks+=4
	var env_signatures:Dictionary={}
	for kind in ["ember","splash","crystal","gravel","dig","dive","drip","static","leaves","metal","wind","land","vanish"]:
		var phase:String="env_"+kind
		var mix:Vector3=view.combat_audio_mix(60,phase,true)
		if mix.z!=0.0 or mix.x> -20.0:failures.append("V19.8 environment mix priority")
		checks+=1
		for variant in range(3):
			var audio:AudioStreamWAV=view.combat_environment_sound(phase,variant)
			var pcm:PackedByteArray=audio.data
			var peak:int=0
			for offset in range(0,pcm.size(),2):peak=maxi(peak,absi(pcm.decode_s16(offset)))
			if pcm.size()<1000 or audio.mix_rate!=22050 or audio.stereo or peak<100 or peak>31130 or pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0:failures.append("V19.8 environmental PCM "+kind)
			var signature:String=pcm.hex_encode()
			if env_signatures.has(signature):failures.append("V19.8 duplicate environmental sample "+kind)
			env_signatures[signature]=true
			if view.combat_environment_sound(phase,variant)!=audio:failures.append("V19.8 environment cache")
			checks+=3
	# V19.9 status motifs must reflect confirmed outcomes, not move chance.
	var ailment_move:Dictionary={"category":"special","inflict_status":"paralysis"}
	if view.combat_status_audio_kind(ailment_move,{"damage":5})!="":failures.append("V19.9 false proc")
	if view.combat_status_audio_kind(ailment_move,{"damage":5,"status":"Paralysis","status_changed":true})!="paralysis":failures.append("V19.9 confirmed proc")
	if view.combat_status_audio_kind({"category":"status","inflict_status":"sleep"},{"misses":1})!="":failures.append("V19.9 missed sleep")
	if view.combat_status_audio_kind({"category":"status","inflict_status":"sleep"},{"blocked":1})!="":failures.append("V19.9 blocked sleep")
	if view.combat_status_audio_kind({},{"heal":4})!="heal":failures.append("V19.9 healing")
	if view.combat_status_audio_kind({"drain_fraction":.5},{"heal":4})!="drain":failures.append("V19.9 drain")
	if view.combat_status_audio_kind({"category":"status","stat_changes":{"attack":1}},{"effects":1})!="boost":failures.append("V19.9 boost")
	if view.combat_status_audio_kind({"category":"status","stat_changes":{"attack":-1}},{"effects":1})!="weaken":failures.append("V19.9 weaken")
	var status_cell:=Vector2i(7,8)
	var status_waves:Array[Dictionary]=view.cast_impact_waves({status_cell:{"status":"Poison","attempts":[{"damage":3,"status":"Poison","status_changed":true},{"damage":0,"misses":1}]}})
	if status_waves.size()!=2 or view.combat_status_audio_kind({},status_waves[0][status_cell])!="poison" or not view.combat_status_audio_kind({},status_waves[1][status_cell]).is_empty():failures.append("V19.9 wrong proc timing")
	checks+=9
	var status_signatures:Dictionary={}
	for kind in ["heal","drain","cleanse","shield","boost","weaken","exchange","transform","sleep","confusion","poison","burn","paralysis","freeze","curse","heart","bind","trap","weather","blocked","ritual"]:
		var phase:String="status_"+kind
		var mix:Vector3=view.combat_audio_mix(60,phase,true)
		if mix.z!=(0.0 if kind=="blocked" else 1.0) or mix.x> -15.0:failures.append("V19.9 status priority "+kind)
		checks+=1
		for variant in range(3):
			var audio:AudioStreamWAV=view.combat_status_sound(phase,variant)
			var pcm:PackedByteArray=audio.data
			var peak:int=0
			for offset in range(0,pcm.size(),2):peak=maxi(peak,absi(pcm.decode_s16(offset)))
			if pcm.size()<1000 or peak<100 or peak>31130 or pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0 or audio.stereo or audio.mix_rate!=22050:failures.append("V19.9 status PCM "+kind)
			var signature:String=pcm.hex_encode()
			if status_signatures.has(signature):failures.append("V19.9 duplicate motif "+kind)
			status_signatures[signature]=true
			if view.combat_status_sound(phase,variant)!=audio:failures.append("V19.9 status cache "+kind)
			checks+=3
	# V20.0 mastering: bounded source peaks and conservative admission under load.
	var mastered:=PackedByteArray()
	mastered.resize(1024)
	for i in range(512):
		mastered.encode_s16(i*2,roundi(25000.0+7000.0*sin(float(i)*.7)))
	var master_peak:float=view.combat_audio_master_pcm(mastered)
	var measured_peak:float=0.0
	for i in range(512):
		measured_peak=maxf(measured_peak,float(absi(mastered.decode_s16(i*2)))/32767.0)
	if absf(master_peak-measured_peak)>.0001 or master_peak>Dungeon.FX_AUDIO_PEAK_LIMIT+.0001 or master_peak<.01:failures.append("V20.0 mastered peak")
	if mastered.decode_s16(0)!=0 or mastered.decode_s16(mastered.size()-2)!=0:failures.append("V20.0 mastered endpoints")
	checks+=2
	for priority in range(4):
		for step in range(71):
			var occupied:float=float(step)/100.0
			for peak in [.08,.25,.78]:
				var admitted:float=view.combat_audio_admission_db(peak,-8.0,occupied,priority)
				var ceiling:float=[.34,.46,.58,.70][priority]
				if not is_finite(admitted) or admitted> -7.9999:failures.append("V20.0 invalid admission")
				if occupied<ceiling and admitted> -40.0 and occupied+peak*db_to_linear(admitted)>ceiling+.0001:failures.append("V20.0 peak budget")
				if occupied>=ceiling and admitted> -40.0:failures.append("V20.0 over-admission")
				checks+=3
	var low_spatial:Vector2=view.combat_audio_spatial_profile(0)
	var high_spatial:Vector2=view.combat_audio_spatial_profile(3)
	if low_spatial.x>=high_spatial.x or low_spatial.y>=high_spatial.y:failures.append("V20.0 spatial priority")
	if view.combat_audio_admission_db(.5,-8.0,.58,3)<=view.combat_audio_admission_db(.5,-8.0,.58,0):failures.append("V20.0 critical headroom")
	checks+=2
	view.fx_audio_cache.clear()
	var lru_bytes:=PackedByteArray()
	lru_bytes.resize(128)
	for i in range(Dungeon.FX_AUDIO_CACHE_CAP):
		view.combat_audio_store("lru_"+str(i),lru_bytes.duplicate(),22050)
	var retained:AudioStreamWAV=view.combat_audio_cached("lru_0")
	view.combat_audio_store("lru_new",lru_bytes.duplicate(),22050)
	if retained==null or not view.fx_audio_cache.has("lru_0") or view.fx_audio_cache.has("lru_1") or view.fx_audio_cache.size()!=Dungeon.FX_AUDIO_CACHE_CAP:failures.append("V20.0 LRU eviction")
	view.fx_audio_cache.clear()
	checks+=1
	# V20.2 sub-frame synchronization across several mobile frame rates.
	for hz in [15,20,30,60,90,120]:
		var dt:float=1.0/float(hz)
		for step in range(101):
			var age:float=dt*float(step)/100.0
			var fresh_age:float=view.combat_visual_age(age,dt,true)
			var next_age:float=view.combat_visual_age(fresh_age,dt,false)
			if absf(fresh_age-age)>.000001 or absf(next_age-age-dt)>.000001:failures.append("V20.2 visual clock")
			if absf(view.combat_ground_shake_at_age(age)-maxf(0.0,.22-age*3.0))>.000001:failures.append("V20.2 aged shake")
			checks+=2
	var av_origin:=Vector3(0,.5,0)
	var av_wave:Dictionary={Vector2i.ZERO:{"effects":1},Vector2i(1,0):{"damage":5},Vector2i(2,0):{"damage":3,"crit":1}}
	if not view.combat_wave_audio_target(av_wave,av_origin).is_equal_approx(Vector3(2.8,.5,0)):failures.append("V20.2 critical audio location")
	av_wave.erase(Vector2i(2,0))
	if not view.combat_wave_audio_target(av_wave,av_origin).is_equal_approx(Vector3(1.4,.5,0)):failures.append("V20.2 damaging audio location")
	av_wave.erase(Vector2i(1,0))
	if not view.combat_wave_audio_target(av_wave,av_origin).is_equal_approx(av_origin):failures.append("V20.2 status audio location")
	if not view.combat_wave_audio_target({Vector2i(3,0):{"misses":1}},av_origin).is_equal_approx(av_origin):failures.append("V20.2 miss audio location")
	checks+=4
	view.fx_reaction_sparks.clear()
	view.queue_ultra_reaction(Vector3.ZERO,Vector3.FORWARD,false,.12)
	if view.fx_reaction_sparks.size()!=1 or absf(float(view.fx_reaction_sparks[0].age)-.12)>.000001 or not bool(view.fx_reaction_sparks[0].fresh):failures.append("V20.2 reaction initial age")
	view.queue_ultra_reaction(Vector3.ZERO,Vector3.FORWARD,false,.25)
	if view.fx_reaction_sparks.size()!=1:failures.append("V20.2 expired reaction")
	view.fx_reaction_sparks.clear()
	checks+=2
	# V20.3 motion timing: differentiated anticipation and recovery without
	# changing the contact frame, logical tiles or neutral endpoints.
	var polish_kinds:Array=["rush","contact","fang","crunch","claw","pincer","punch","uppercut","kick","lowkick","wing","tail","horn","lash","aerial","down","spin","focus","gesture","cast"]
	var polish_signatures:Dictionary={}
	for kind in polish_kinds:
		polish_signatures[str(view.cast_motion_timing(kind))]=true
		for peak in [.12,.34,.48,.64,.88]:
			var timing:Vector4=view.cast_motion_timing(kind)
			var windup:Vector3=view.attack_direction_sample(peak*timing.x*.5,peak,kind)
			var contact:Vector3=view.attack_direction_sample(peak,peak,kind)
			if absf(windup.x-1.0)>.0001 or absf(contact.y-1.0)>.0001 or absf(contact.x)>.0001:failures.append("V20.3 contact clock "+kind)
			checks+=1
			var previous:=Vector3.ZERO
			for step in range(201):
				var phase:float=float(step)/200.0
				var motion:Vector3=view.cast_motion_offset(kind,phase,peak)
				var body:Dictionary=Art.attack_body_sample(phase,peak,kind)
				if not motion.is_finite() or motion.length()>1.0 or float(body.stretch)<.84 or float(body.stretch)>1.16:failures.append("V20.3 motion bounds "+kind)
				if step>0 and motion.distance_to(previous)>.16:failures.append("V20.3 abrupt motion "+kind)
				if step in [0,200] and (motion.length()>.001 or absf(float(body.stretch)-1.0)>.001):failures.append("V20.3 rest "+kind)
				previous=motion
				checks+=3
	if polish_signatures.size()<10:failures.append("V20.3 insufficient timing variety")
	checks+=1
	for step in range(101):
		var phase:float=float(step)/100.0
		var hit:Dictionary=view.premium_hit_sample(phase)
		if float(hit.recoil)<0.0 or float(hit.recoil)>1.0 or absf(float(hit.tilt))>.10:failures.append("V20.3 recoil bounds")
		if step in [0,100] and (absf(float(hit.recoil))>.001 or absf(float(hit.squash)-1.0)>.001):failures.append("V20.3 recoil rest")
		checks+=2
	# V20.6 acoustic repair: replay every flagged move in all three variants.
	var repaired_audio_ids:Array=["lib_electric_1","lib_dark_1","eos_063","eos_064","eos_325","eos_452","eos_461","eos_522","eos_529","eos_020","alt_vinesnap","alt_sylphowl","alt_eelstrix"]
	for id in repaired_audio_ids:
		for phase in ["launch","impact"]:
			for variant in range(3):
				var pcm:PackedByteArray=view.combat_sound(id,phase,variant).data
				var metrics:Dictionary=audio_quality_metrics(pcm)
				if float(metrics.max_step)>Dungeon.FX_AUDIO_STEP_LIMIT+.0001:failures.append("V20.6 excessive sample step "+id+" "+phase)
				if float(metrics.rms)<.005 or absf(float(metrics.dc))>.025:failures.append("V20.6 weak or biased audio "+id+" "+phase)
				if pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0:failures.append("V20.6 PCM endpoints "+id+" "+phase)
				checks+=3
	# V20.7 acoustic identity: compare authored role contours and semantic status
	# families instead of accepting a common thump for unrelated attacks.
	var identity_ids:Array=["eos_154","eos_139","eos_140","eos_161","eos_176","eos_177","eos_190","eos_203","eos_226","eos_235","eos_247","eos_248","eos_250","eos_260","eos_264","eos_271","eos_275","eos_294","eos_311","eos_312","eos_314","eos_321","eos_322","eos_328"]
	var identity_signatures:Dictionary={}
	for id in identity_ids:
		var gesture:Vector4=view.combat_audio_gesture(id,view.combat_profile(id))
		var signature:String=str(gesture)
		if identity_signatures.has(signature):failures.append("V20.7 duplicate authored gesture "+id)
		identity_signatures[signature]=true
		if not gesture.is_finite() or gesture.x<50.0 or gesture.x>2000.0 or gesture.z<1.0 or gesture.z>8.0 or gesture.w<0.0 or gesture.w>1.0:failures.append("V20.7 invalid gesture "+id)
		checks+=2
	for kind in ["normal_tackle","normal_drill","normal_megapunch","normal_furyswipes","normal_bide","normal_wrap"]:
		if not Dungeon.AUDIO_ROLE_GESTURES.has(kind):failures.append("V20.7 missing authored role "+kind)
		checks+=1
	# V21.0 texture reuse: retain hot entries even under full cache pressure.
	view.fx_secondary_pack_checked=true
	view.fx_frame_pack_checked=true # Exercise the original fallback LRU independently of the baked path.
	view.fx_animated_cache.clear()
	view.fx_animated_newest=""
	var hot_frame:Texture2D=view.combat_animated_texture("eos_308",0)
	var cold_frame:Texture2D=view.combat_animated_texture("eos_308",1)
	for i in range(Dungeon.FX_ANIMATED_CACHE_CAP-2):
		view.fx_animated_cache["synthetic_"+str(i)]=cold_frame
	var initial_builds:int=view.fx_frame_builds
	if view.combat_animated_texture("eos_308",0)!=hot_frame or view.fx_frame_builds!=initial_builds:failures.append("V21.0 texture hot reuse")
	view.combat_animated_texture("eos_308",2)
	if not view.fx_animated_cache.has("animated:eos_308:0") or view.fx_animated_cache.has("animated:eos_308:1") or view.fx_animated_cache.size()!=Dungeon.FX_ANIMATED_CACHE_CAP:failures.append("V21.0 animated LRU")
	view.fx_animated_cache.clear()
	view.fx_animated_newest=""
	view.combat_textures.clear()
	view.fx_secondary_newest=""
	var hot_particle:ImageTexture=view.combat_pixel_texture("impact_star",Color.WHITE,Color.BLACK)
	var cold_particle:ImageTexture=view.combat_pixel_texture("bubble",Color.WHITE,Color.BLACK)
	for i in range(Dungeon.FX_SECONDARY_TEXTURE_CAP-2):
		view.combat_textures["synthetic_"+str(i)]=cold_particle
	var secondary_builds:int=view.fx_secondary_builds
	if view.combat_pixel_texture("impact_star",Color.WHITE,Color.BLACK)!=hot_particle or view.fx_secondary_builds!=secondary_builds:failures.append("V21.0 secondary hot reuse")
	view.combat_pixel_texture("cloud",Color.WHITE,Color.BLACK)
	if not view.combat_textures.has("impact_star"+str(Color.WHITE)+str(Color.BLACK)) or view.combat_textures.has("bubble"+str(Color.WHITE)+str(Color.BLACK)) or view.combat_textures.size()!=Dungeon.FX_SECONDARY_TEXTURE_CAP:failures.append("V21.0 secondary LRU")
	view.combat_textures.clear()
	view.fx_secondary_newest=""
	checks+=4
	# Full catalog: actual frame bytes, audio buffers, and pooled world FX.
	# A duplicate sequence or sparse animation is a review candidate, not proof
	# of poor visual quality. Preserve exact IDs in the downloadable CI report.
	var quality_rows:Array=[]
	var visual_rows:Dictionary={}
	var visual_dir:String="/tmp/kindria-visual"
	if DirAccess.make_dir_recursive_absolute(visual_dir)!=OK:failures.append("visual output directory")
	var sequence_owners:Dictionary={}
	var duplicate_groups:Dictionary={}
	var review_candidates:Array=[]
	var frame_total:int=0
	var runtime_samples:int=0
	var audio_total:int=0
	var audio_digest_owners:Dictionary={}
	var audio_similarity_groups:Dictionary={}
	var audio_review_rows:Array=[]
	var audio_cold_usec:int=0
	var audio_cached_usec:int=0
	var scene:=Node3D.new()
	root.add_child(scene)
	view.combat_fx_setup(scene)
	# Indexed geometry must expand to the exact original two triangles.
	view.ultra_trail_segment(Vector3.ZERO,Vector3.RIGHT,.1,.2,Color.RED,Color.BLUE)
	var expected_indices:=PackedInt32Array([0,1,2,0,2,3])
	if view.fx_trail_positions.size()!=4 or view.fx_quad_indices(view.fx_trail_positions.size())!=expected_indices or view.fx_trail_colors!=PackedColorArray([Color.RED,Color.RED,Color.BLUE,Color.BLUE]):failures.append("V21.5 ribbon topology")
	if not view.commit_fx_geometry(view.fx_trail_mesh,view.fx_trail_material,view.fx_trail_positions,view.fx_trail_colors,view.fx_quad_indices(view.fx_trail_positions.size())):failures.append("V21.5 ribbon submission")
	if view.fx_trail_mesh.get_surface_count()!=1 or view.fx_trail_mesh.surface_get_array_len(0)!=4 or view.fx_trail_mesh.surface_get_array_index_len(0)!=6:failures.append("V21.5 indexed mesh")
	view.fx_trail_mesh.clear_surfaces()
	var ribbon_override_found:bool=false
	for fx_child in view.combat_fx_root.get_children():
		if fx_child is MeshInstance3D and fx_child.mesh==view.fx_trail_mesh:
			ribbon_override_found=fx_child.material_override==view.fx_trail_material
	if not ribbon_override_found:failures.append("V25.5 ribbon material override")
	if not view.commit_fx_geometry(view.fx_trail_mesh,view.fx_trail_material,view.fx_trail_positions,view.fx_trail_colors,view.fx_quad_indices(view.fx_trail_positions.size()),true):failures.append("V25.5 node material submission")
	if view.fx_trail_mesh.surface_get_material(0)!=null:failures.append("V25.5 redundant surface material")
	view.fx_trail_mesh.clear_surfaces()
	checks+=3
	view.fx_trail_started=false
	view.arc_segment(Vector3.ZERO,Vector3.RIGHT,.1,Color.WHITE)
	if view.fx_arc_positions.size()!=4 or view.fx_quad_indices(view.fx_arc_positions.size())!=expected_indices:failures.append("V21.5 arc topology")
	var warnings:=PackedVector3Array([Vector3(1,.045,0),Vector3(2,.045,0),Vector3(1,.045,0)])
	view.apply_combat_warning_batch(warnings)
	var warning_updates:int=view.fx_warning_batch_updates
	view.apply_combat_warning_batch(warnings)
	if view.combat_warning_batch.multimesh.visible_instance_count!=3 or view.fx_warning_batch_updates!=warning_updates:failures.append("V21.5 warning batch")
	view.apply_combat_warning_batch(PackedVector3Array())
	if view.combat_warning_batch.visible or view.combat_warning_batch.multimesh.visible_instance_count!=0:failures.append("V21.5 warning cleanup")
	checks+=6
	var batch_rects:Array[Rect2]=[Rect2(0,0,10,10),Rect2(20,0,10,10),Rect2(40,0,10,10),Rect2(60,0,10,10),Rect2(65,0,10,10)]
	var batch_keys:Array[int]=[1,1,1,1,-1]
	var safe_groups:=view.particle_batch_groups(batch_rects,batch_keys)
	if safe_groups.size()!=1 or safe_groups[0]!=[0,1,2]:failures.append("V21.6 isolated particle grouping")
	batch_rects[2]=Rect2(25,0,10,10)
	if not view.particle_batch_groups(batch_rects,batch_keys).is_empty():failures.append("V21.6 overlapping particle fallback")
	checks+=2
	# Compare sweep output against the original exhaustive isolation test.
	var random:=RandomNumberGenerator.new()
	random.seed=217
	for trial in range(80):
		var rects:Array[Rect2]=[]
		var keys:Array[int]=[]
		for k in range(40):
			rects.append(Rect2(random.randi_range(-20,180),random.randi_range(-20,180),random.randi_range(1,16),random.randi_range(1,16)))
			keys.append(random.randi_range(-1,4))
		var expected:Dictionary={}
		for k in range(keys.size()):
			if keys[k]<0:continue
			var isolated:bool=true
			for other in range(rects.size()):
				if k!=other and rects[k].intersects(rects[other],true):
					isolated=false
					break
			if not isolated:continue
			if not expected.has(keys[k]):expected[keys[k]]=[]
			expected[keys[k]].append(k)
		var expected_groups:Array=[]
		for key in expected:
			if expected[key].size()>=Dungeon.FX_PARTICLE_BATCH_MIN:expected_groups.append(expected[key])
		expected_groups.sort_custom(func(a:Array,b:Array)->bool:
			if a.size()==b.size():return int(a[0])<int(b[0])
			return a.size()>b.size())
		if view.particle_batch_groups(rects,keys)!=expected_groups.slice(0,Dungeon.FX_PARTICLE_BATCH_CAP):failures.append("V21.7 sweep mismatch "+str(trial))
		checks+=1
	var spaced_rects:Array[Rect2]=[]
	var spaced_keys:Array[int]=[]
	for k in range(208):
		spaced_rects.append(Rect2(k*12,0,8,8))
		spaced_keys.append(1)
	var before_tests:int=view.fx_particle_overlap_tests
	var spaced_groups:=view.particle_batch_groups(spaced_rects,spaced_keys)
	if spaced_groups.size()!=1 or spaced_groups[0].size()!=208 or view.fx_particle_overlap_tests!=before_tests:failures.append("V21.7 separated sweep")
	if view.particle_batch_preflight([-1,1,1,2]) or not view.particle_batch_preflight([1,-1,1,1]):failures.append("V21.7 preflight")
	for k in range(Dungeon.FX_PARTICLE_NO_GAIN_LIMIT):view.particle_batch_adapt(0)
	if view.fx_particle_cooldown!=Dungeon.FX_PARTICLE_PROBE_INTERVAL:failures.append("V21.7 adaptive backoff")
	view.particle_batch_adapt(4)
	if view.fx_particle_cooldown!=0 or view.fx_particle_no_gain_frames!=0:failures.append("V21.7 adaptive recovery")
	checks+=4
	# Generate PCM explicitly below; no speaker playback in a headless test.
	view.fx_audio.clear()
	# An evicted cast with a completed hit still owns future environmental cues.
	var retired_points:Array=[Vector3.ZERO,Vector3(1.4,.4,0),Vector3(1.4,.4,1.4)]
	var retired_test:Dictionary={"id":"eos_100","age":.55,"duration":1.0,"profile":{"impact":.5,"role":"air_fly","element":"flying"},"points":retired_points,"target_player":false,"damage":4,"results":{},"impact_waves":[{}],"impact_times":[.5],"impact_cursor":1,"impacted":true,"environment_audio":[{"phase":"env_land","fraction":.7,"anchor":"terrain"}],"environment_audio_cursor":0}
	view.retire_combat_burst(retired_test)
	if view.retired_impacts.size()!=1 or view.retired_impacts[0].points!=retired_points:failures.append("V22.0 retired environment route")
	var retired_cues:int=view.fx_retired_environment_cues
	view.update_retired_impacts(.05)
	if view.retired_impacts.size()!=1 or view.fx_retired_environment_cues!=retired_cues:failures.append("V22.0 early retired cue")
	view.update_retired_impacts(.11)
	if not view.retired_impacts.is_empty() or view.fx_retired_environment_cues!=retired_cues+1:failures.append("V22.0 retired cue completion")
	checks+=3
	# Saturate the visual pool using actual casts with hit/miss/critical ledgers.
	# All pending attempts must dispatch exactly once despite visual eviction.
	var stress_count:int=Dungeon.COMBAT_BURST_CAP+6
	var stress_tile:=Vector2i(2,0)
	var stress_row:Dictionary={"damage":9,"hits":2,"misses":1,"crit":1,"attempts":[{"damage":3},{"damage":0,"misses":1},{"damage":6,"crit":1}]}
	var wave_before:int=view.fx_dispatched_waves
	var damage_before:int=view.fx_dispatched_damage_waves
	var miss_before:int=view.fx_dispatched_miss_waves
	var drops_before:int=view.fx_retired_dropped
	for k in range(stress_count):
		view.combat_fx_spawn({"fx":"eos_064","from":Vector2i.ZERO,"to":stress_tile,"path":[Vector2i(1,0),stress_tile],"tiles":[stress_tile],"results":{stress_tile:stress_row},"damage":9})
	if view.combat_bursts.size()!=Dungeon.COMBAT_BURST_CAP or view.retired_impacts.size()!=6:failures.append("V22.1 overflow retirement")
	# Mix ordinary frames and a deliberately slow frame crossing multiple hits.
	for k in range(180):
		view.combat_fx_update(.23 if k==10 else 1.0/60.0)
	if not view.combat_bursts.is_empty() or not view.retired_impacts.is_empty():failures.append("V22.1 overflow completion")
	if view.fx_dispatched_waves-wave_before!=stress_count*3 or view.fx_dispatched_damage_waves-damage_before!=stress_count*2 or view.fx_dispatched_miss_waves-miss_before!=stress_count:failures.append("V22.1 overflow wave accounting")
	if view.fx_retired_dropped!=drops_before:failures.append("V22.1 unexpected retirement loss")
	var wave_final:int=view.fx_dispatched_waves
	view.combat_fx_update(.5)
	if view.fx_dispatched_waves!=wave_final:failures.append("V22.1 duplicate wave")
	checks+=5
	print("KINDRIA_OVERFLOW casts=",stress_count," waves=",view.fx_dispatched_waves-wave_before," damage=",view.fx_dispatched_damage_waves-damage_before," misses=",view.fx_dispatched_miss_waves-miss_before)
	for id in catalog:
		var profile:=view.combat_profile(id)
		var move:Dictionary=catalog[id]
		var frame_hashes:Dictionary={}
		var sequence:=HashingContext.new()
		sequence.start(HashingContext.HASH_SHA256)
		var blank_frames:Array=[]
		var repeat_count:int=0
		var previous_hash:String=""
		var strip:=Image.create(48*Dungeon.FX_FRAME_COUNT,48,false,Image.FORMAT_RGBA8)
		strip.fill(Color.TRANSPARENT)
		var frame_areas:Array[int]=[]
		var edge_frames:Array[int]=[]
		var visible_pixels:Array[int]=[]
		var border_pixels:Array[int]=[]
		var peak_visible:int=0
		var visual_signature:Array=[]
		var impact_frame:int=clampi(roundi(float(profile.impact)*float(Dungeon.FX_FRAME_COUNT-1)),0,Dungeon.FX_FRAME_COUNT-1)
		for frame in range(Dungeon.FX_FRAME_COUNT):
			var image:Image=view.combat_frame_image(id,frame)
			var bytes:PackedByteArray=image.get_data()
			var occupied:int=0
			var border:int=0
			# Alpha threshold excludes nearly transparent dissipation from silhouette metrics.
			for y in range(48):
				for x in range(48):
					if bytes[(y*48+x)*4+3]<=32:continue
					occupied+=1
					if x==0 or x==47 or y==0 or y==47:border+=1
			visible_pixels.append(occupied)
			border_pixels.append(border)
			peak_visible=maxi(peak_visible,occupied)
			# Sample the actual pixels at fixed animation phases. Premultiply color
			# so invisible RGB does not make two silhouettes appear different.
			if frame in [1,4,7,10]:
				var phase_features:Array=[]
				for gy in range(6):
					for gx in range(6):
						var sums:=Vector4.ZERO
						for y in range(gy*8,gy*8+8):
							for x in range(gx*8,gx*8+8):
								var pixel:=image.get_pixel(x,y)
								sums+=Vector4(pixel.a,pixel.r*pixel.a,pixel.g*pixel.a,pixel.b*pixel.a)
						phase_features.append([roundi(sums.x*255.0/64.0),roundi(sums.y*255.0/64.0),roundi(sums.z*255.0/64.0),roundi(sums.w*255.0/64.0)])
				visual_signature.append(phase_features)
			strip.blit_rect(image,Rect2i(0,0,48,48),Vector2i(frame*48,0))
			var bounds:=image.get_used_rect()
			frame_areas.append(bounds.get_area())
			if bounds.has_area() and (bounds.position.x==0 or bounds.position.y==0 or bounds.end.x==48 or bounds.end.y==48):edge_frames.append(frame)
			sequence.update(bytes)
			var frame_hash:String=bytes.hex_encode().sha256_text()
			frame_hashes[frame_hash]=true
			if frame_hash==previous_hash:repeat_count+=1
			previous_hash=frame_hash
			if occupied==0:blank_frames.append(frame)
			if image.get_size()!=Vector2i(48,48):failures.append("full catalog frame size "+str(id))
			frame_total+=1;checks+=1
		var signature:String=sequence.finish().hex_encode()
		var element:String=str(profile.element)
		var folder:String=visual_dir+"/"+element
		if DirAccess.make_dir_recursive_absolute(folder)!=OK:failures.append("visual element directory "+element)
		if strip.save_png(folder+"/"+str(id)+".png")!=OK:failures.append("visual strip export "+str(id))
		if not visual_rows.has(element):visual_rows[element]=[]
		visual_rows[element].append({"id":id,"name":str(move.get("name",id)),"impact_frame":impact_frame,"frame_areas":frame_areas,"edge_frames":edge_frames,"visible_pixels":visible_pixels,"border_pixels":border_pixels,"visual_signature":visual_signature})
		if sequence_owners.has(signature):
			if not duplicate_groups.has(signature):duplicate_groups[signature]=[sequence_owners[signature]]
			duplicate_groups[signature].append(id)
		else:sequence_owners[signature]=id
		var reasons:Array[String]=[]
		if frame_hashes.size()<6:reasons.append("low_temporal_variation")
		if blank_frames.size()>3:reasons.append("many_low_alpha_frames")
		if repeat_count>5:reasons.append("adjacent_repeats")
		if peak_visible<170:reasons.append("small_peak_silhouette")
		var impact_visible:int=visible_pixels[impact_frame]
		if impact_visible<30:reasons.append("weak_impact_silhouette")
		var max_border_ratio:float=0.0
		for frame in range(Dungeon.FX_FRAME_COUNT):
			if visible_pixels[frame]<30:continue
			max_border_ratio=maxf(max_border_ratio,float(border_pixels[frame])/float(visible_pixels[frame]))
		if max_border_ratio>.10:reasons.append("possible_frame_clipping")
		if not reasons.is_empty():
			review_candidates.append(id)
			print("KINDRIA_VISUAL_REVIEW ",JSON.stringify({"id":id,"name":str(move.get("name",id)),"element":element,"reasons":reasons,"peak_visible":peak_visible,"impact_visible":impact_visible,"distinct_frames":frame_hashes.size(),"blank_frames":blank_frames,"max_border_ratio":max_border_ratio}))
		if peak_visible==0:failures.append("empty full sequence "+str(id))
		if frame_hashes.size()==1:failures.append("static full sequence "+str(id))
		# A transparent final frame can be intentional. A weak impact is a review
		# candidate, not a hard failure for thin beams or subtle status moves.
		var audio_form:=view.combat_audio_form(id,profile)
		var audio_peaks:Dictionary={}
		var audio_metrics:Dictionary={}
		for phase in ["launch","impact"]:
			var started:int=Time.get_ticks_usec()
			var audio:=view.combat_sound(id,phase,0)
			var cold_usec:int=Time.get_ticks_usec()-started
			started=Time.get_ticks_usec()
			var cached:AudioStreamWAV=view.combat_sound(id,phase,0)
			var cached_usec:int=Time.get_ticks_usec()-started
			audio_cold_usec+=cold_usec
			audio_cached_usec+=cached_usec
			if cached!=audio:failures.append("V20.1 cache identity "+str(id))
			var pcm:PackedByteArray=audio.data
			var metrics:Dictionary=audio_quality_metrics(pcm)
			metrics["first_lookup_usec"]=cold_usec
			metrics["cached_lookup_usec"]=cached_usec
			audio_metrics[phase]=metrics
			var digest:String=str(metrics.pcm_sha256)
			if audio_digest_owners.has(digest):failures.append("V20.1 exact audio duplicate "+str(id)+" "+phase+" vs "+str(audio_digest_owners[digest]))
			audio_digest_owners[digest]=str(id)+":"+phase
			var similarity_key:String=str(profile.element)+":"+phase+":"+str(metrics.descriptor)
			if not audio_similarity_groups.has(similarity_key):audio_similarity_groups[similarity_key]=[]
			audio_similarity_groups[similarity_key].append(id)
			var acoustic_reasons:Array[String]=[]
			if float(metrics.rms)<.005:acoustic_reasons.append("low_rms")
			if absf(float(metrics.dc))>.025:acoustic_reasons.append("dc_offset")
			if float(metrics.max_step)>.8:acoustic_reasons.append("large_sample_step")
			if not acoustic_reasons.is_empty():
				var candidate:Dictionary={"id":id,"name":str(move.get("name",id)),"element":profile.element,"phase":phase,"reasons":acoustic_reasons,"metrics":metrics}
				audio_review_rows.append(candidate)
				print("KINDRIA_AUDIO_REVIEW ",JSON.stringify(candidate))
			if float(metrics.peak)>Dungeon.FX_AUDIO_PEAK_LIMIT+.0001:failures.append("V20.1 peak ceiling "+str(id))
			if float(metrics.max_step)>Dungeon.FX_AUDIO_STEP_LIMIT+.0001:failures.append("V20.6 sample step ceiling "+str(id)+" "+phase)
			checks+=1
			checks+=2
			var peak:int=0
			for offset in range(0,pcm.size(),2):
				peak=maxi(peak,absi(pcm.decode_s16(offset)))
			if pcm.size()<1000 or peak<100 or peak>31130 or pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0:failures.append("catalog audio "+str(id)+" "+phase)
			audio_peaks[phase]=peak
			audio_total+=1;checks+=1
		var category:String=str(move.get("category",""))
		var target_tile:=Vector2i(2,0)
		var row:Dictionary={"effects":1} if category=="status" else {"damage":8}
		var event:Dictionary={"fx":id,"from":Vector2i.ZERO,"to":target_tile,"path":[Vector2i(1,0),target_tile],"tiles":[target_tile],"results":{target_tile:row},"damage":int(row.get("damage",0))}
		view.combat_fx_spawn(event)
		var duration:float=float(view.combat_bursts[-1].duration)
		var last:float=0.0
		var max_visible:int=0
		var peak_time:float=float(profile.impact)
		for phase in [peak_time*.45,peak_time,peak_time+(1.0-peak_time)*.45,.98,1.02]:
			view.combat_fx_update((float(phase)-last)*duration)
			last=float(phase)
			var visible:int=0
			for particle in view.combat_particles:
				if not particle.visible:continue
				visible+=1
				if not particle.position.is_finite() or not particle.scale.is_finite() or particle.texture==null:failures.append("invalid world particle "+str(id))
			max_visible=maxi(max_visible,visible)
			if visible>Dungeon.FX_PARTICLE_CAP or view.fx_trail_vertices>Dungeon.FX_TRAIL_VERTEX_CAP or view.fx_halos_used>Dungeon.FX_HALO_CAP or view.fx_lights_used>Dungeon.FX_LIGHT_CAP:failures.append("world pool overflow "+str(id))
			runtime_samples+=1;checks+=1
		if not view.combat_bursts.is_empty() or max_visible==0:failures.append("world cast lifetime "+str(id))
		quality_rows.append({"id":id,"element":profile.element,"role":profile.role,"category":category,"distinct_frames":frame_hashes.size(),"blank_frames":blank_frames,"adjacent_repeats":repeat_count,"peak_visible_pixels":peak_visible,"impact_frame":impact_frame,"impact_visible_pixels":impact_visible,"max_border_ratio":max_border_ratio,"visible_pixels":visible_pixels,"border_pixels":border_pixels,"review_reasons":reasons,"sequence_sha256":signature,"audio_form":audio_form,"audio_peaks":audio_peaks,"audio_metrics":audio_metrics,"max_visible_particles":max_visible})
	# Coarse similarity groups are advisory; only exact PCM duplicates fail.
	var audio_similarity_review:Dictionary={}
	for group in audio_similarity_groups:
		if audio_similarity_groups[group].size()>1:
			audio_similarity_review[group]=audio_similarity_groups[group]
			print("KINDRIA_AUDIO_SIMILARITY ",JSON.stringify({"group":group,"ids":audio_similarity_groups[group]}))
	for priority in range(4):
		var ceiling:float=view.combat_audio_priority_ceiling(priority)
		if view.combat_audio_can_admit(ceiling,priority) or not view.combat_audio_can_admit(ceiling-.01,priority):failures.append("V20.1 early admission")
		checks+=1
	var audio_report:=FileAccess.open("/tmp/kindria-audio-quality.json",FileAccess.WRITE)
	if audio_report==null:failures.append("V20.1 audio report")
	else:
		audio_report.store_string(JSON.stringify({"samples":audio_total,"first_lookup_total_usec":audio_cold_usec,"cached_lookup_total_usec":audio_cached_usec,"exact_unique_pcm":audio_digest_owners.size(),"similarity_groups":audio_similarity_review,"review_candidates":audio_review_rows}, "\t"))
		audio_report.close()
	print("KINDRIA_AUDIO_QUALITY samples=",audio_total," exact_unique=",audio_digest_owners.size()," review_groups=",audio_similarity_review.size()," review_candidates=",audio_review_rows.size()," first_lookup_usec=",audio_cold_usec," cached_lookup_usec=",audio_cached_usec)
	if frame_total!=589*Dungeon.FX_FRAME_COUNT or audio_total!=1178 or runtime_samples!=2945:failures.append("full catalog sample coverage")
	# V15.2 promotes the original duplicate report from advisory to a hard gate.
	if Dungeon.NATIVE_IDENTITY_CASTS.size()!=60:failures.append("native identity coverage")
	for signature in duplicate_groups:
		failures.append("identical move sequence: "+str(duplicate_groups[signature]))
	for id in Dungeon.NATIVE_IDENTITY_CASTS:
		if not catalog.has(id) or not Dungeon.AUTHORED_STAGE_FX.has(id):failures.append("missing native choreography "+str(id))
		checks+=1
	if view.combat_textures.size()>Dungeon.FX_SECONDARY_TEXTURE_CAP or view.fx_animated_cache.size()>Dungeon.FX_ANIMATED_CACHE_CAP or view.fx_audio_cache.size()>192:failures.append("catalog cache overflow")
	var report:=FileAccess.open("/tmp/kindria-quality-report.log",FileAccess.WRITE)
	if report==null:failures.append("quality report write failed")
	else:
		report.store_string(JSON.stringify({"moves":quality_rows,"frame_total":frame_total,"audio_total":audio_total,"runtime_samples":runtime_samples,"duplicate_sequences":duplicate_groups,"review_candidates":review_candidates,"remastered_count":remastered.size(),"alpha_threshold":32,"secondary_cache_size":view.combat_textures.size()}, "\t"))
		report.close()
	var visual_index:=FileAccess.open(visual_dir+"/index.json",FileAccess.WRITE)
	if visual_index==null:failures.append("visual index export")
	else:
		visual_index.store_string(JSON.stringify(visual_rows,"\t"))
		visual_index.close()
	print("KINDRIA_VISUAL_EXPORT sequences=",quality_rows.size()," elements=",visual_rows.size()," frames=",frame_total)
	print("KINDRIA_FULL_QUALITY moves=",quality_rows.size()," frames=",frame_total," audio=",audio_total," runtime_samples=",runtime_samples," duplicate_groups=",duplicate_groups.size()," review_candidates=",review_candidates.size())
	scene.free()
	var home:=Home.new()
	home.free()
	view.free()
	print("CINEMATIC_GAUNTLET checks=",checks," failures=",failures.size())
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
