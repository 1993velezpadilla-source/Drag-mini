extends SceneTree
const Field=preload("res://dungeon_view.gd")
const Backend=preload("res://dungeon_effekseer_backend.gd")
func _initialize()->void:call_deferred("run")
func frames()->void:
	await process_frame
	await RenderingServer.frame_post_draw
func run()->void:
	var field=Field.new()
	root.add_child(field)
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field.setup(0,1,0,false,true,902,24)
	field.set_process(false)
	for i in range(4):await frames()
	var backend=Backend.new()
	field.combat_fx_root.add_child(backend)
	assert(backend.prepare(),"native extension missing")
	var origin:Vector2i=field.run.player
	var target:Vector2i=origin+Vector2i.RIGHT
	var points:Array=[field.pos(origin)+Vector3.UP*.55,field.pos(target)+Vector3.UP*.55]
	var cases:Array=[
		["lib_fire_2","sample-material3/ef_fire01_projectile.efkefc","sample-material3/ef_fire01.efkefc",.62,.78],
		["lib_ice_2","sample-material3/ef_ice02.efkefc","sample-material3/ef_ice01.efkefc",.30,.35],
		["lib_electric_2","sample-material3/ef_lightning02.efkefc","sample-material3/ef_lightning01.efkefc",.48,.56],
		["lib_flying_2","sample-material3/ef_wind02.efkefc","sample-material3/ef_wind01.efkefc",.44,.52],
		["lib_water_2","sample-material2/ToonWater.efkefc","sample-material2/ToonWater.efkefc",.045,.055]]
	for row in cases:
		var id:String=row[0]
		var profile:Dictionary=field.combat_profile(id)
		var tracks:Array=field.elemental_track_plan(id,profile)
		var travel:Dictionary=tracks[3] if tracks[3].enabled else tracks[2]
		var impact:Dictionary=tracks[5]
		var projectile:Resource=load("res://effects/"+str(row[1]))
		var hit:Resource=load("res://effects/"+str(row[2]))
		assert(projectile!=null and hit!=null)
		backend.reset()
		field.combat_bursts.clear()
		field.combat_fx_update(0.0)
		var i:int=backend.launch(travel,projectile,points,[points[-1]],float(row[3]),1.0)
		assert(i>=0)
		for frame in range(24):
			backend.advance(.99/24.0)
			await frames()
			if frame in [8,16,23]:assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/dungeon-"+id+"-travel-"+str(frame)+".png")==OK)
		backend.reset()
		var j:int=backend.launch(impact,hit,points,[points[-1]],float(row[4]),1.0)
		assert(j>=0)
		assert(backend.slots[j].node.position.distance_to(points[-1])<.001)
		for frame in range(30):
			backend.advance(.016)
			await frames()
			if frame in [8,16,23]:assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/dungeon-"+id+"-impact-"+str(frame)+".png")==OK)
		backend.reset()
		print("KINDRIA_EFFEKSEER_TRACKS ",id)
	# Compare the actual built-in combat layers against a hybrid composition.
	# Both sides use the same attack, simulated time and camera.
	for row in cases:
		var id:String=row[0]
		var profile:Dictionary=field.combat_profile(id)
		var duration:float=float(profile.duration)
		var peak:float=float(profile.impact)
		var plan:Array=field.elemental_track_plan(id,profile)
		var travel:Dictionary=plan[3] if plan[3].enabled else plan[2]
		var impact:Dictionary=plan[5]
		var projectile:Resource=load("res://effects/"+str(row[1]))
		var hit:Resource=load("res://effects/"+str(row[2]))
		for hybrid in [false,true]:
			backend.reset()
			field.combat_bursts.clear()
			field.fx_residues.clear()
			field.fx_reaction_sparks.clear()
			field.configure_native_fx({})
			field.combat_fx_update(0.0)
			if hybrid:
				var binding:Dictionary={}
				binding[str(travel.stage)]={"effect":projectile,"scale":float(row[3])}
				binding[str(impact.stage)]={"effect":hit,"scale":float(row[4])}
				assert(field.configure_native_fx({id:binding}))
			field.combat_fx_spawn({"fx":id,"from":origin,"to":target,"path":[target],"tiles":[target],"results":{target:{"damage":8,"effects":0,"heal":0}}})
			if hybrid:
				assert(field.native_fx_backend.pending.size()>=1,"actual combat event schedules native tracks")
			var frame_dt:float=duration/24.0
			var saw_native:bool=false
			for frame in range(24):
				field.combat_fx_update(frame_dt)
				if hybrid:
					for slot in field.native_fx_backend.slots:
						if slot.busy:saw_native=true
				await frames()
				if frame in [int(peak*24.0*.75),mini(22,int(peak*24.0)+3)]:
					var suffix:String="hybrid" if hybrid else "native"
					assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/compare-"+id+"-"+suffix+"-"+str(frame)+".png")==OK)
			if hybrid:
				assert(saw_native,"real combat update dispatched native track")
				assert(field.native_fx_backend.pending.is_empty())
				field.configure_native_fx({})
			backend.reset()
		print("KINDRIA_HYBRID_COMPARISON ",id)
	print("KINDRIA_HYBRID_COMPARISON_PASS 5")
	# Mixed results must preserve secondary hit FX without a false primary hit.
	var hit_effect:Resource=load("res://effects/sample-material3/ef_fire01.efkefc")
	var mixed_id:String="lib_fire_2"
	var other:Vector2i=origin+Vector2i.DOWN
	assert(field.configure_native_fx({mixed_id:{"impact":{"effect":hit_effect,"scale":.4},"projectile_impact":{"effect":hit_effect,"scale":.4}}}))
	field.combat_fx_spawn({"fx":mixed_id,"from":origin,"to":target,"path":[target],"tiles":[target,other],"results":{target:{"damage":0,"effects":0,"heal":0,"misses":1},other:{"damage":7,"effects":0,"heal":0}}})
	assert(field.native_fx_backend.pending.size()==1,"one confirmed secondary impact")
	var pending_hit:Dictionary=field.native_fx_backend.pending[0]
	assert(pending_hit.track.stage=="impact")
	var expected:Vector3=field.pos(other)
	var actual:Vector3=pending_hit.points[-1]
	assert(Vector2(actual.x,actual.z).distance_to(Vector2(expected.x,expected.z))<.001)
	field.configure_native_fx({})
	field.combat_bursts.clear()
	print("KINDRIA_NATIVE_MIXED_OUTCOMES_PASS")
	# V8: one shared area layer, deterministic nearest four secondary hits,
	# and no impact/area emitter when every target misses.
	var area_binding:Dictionary={"effect":hit_effect,"scale":.4}
	assert(field.configure_native_fx({mixed_id:{"area":area_binding,"impact":area_binding,"projectile_impact":area_binding}}))
	var area_tracks:Array=[
		{"stage":"area","anchor":"tiles","start":.5,"end":.9,"enabled":true},
		{"stage":"impact","anchor":"target","start":.5,"end":1.0,"enabled":true},
		{"stage":"projectile_impact","anchor":"target","start":.5,"end":.9,"enabled":true}]
	var crowded:Dictionary={target:{"misses":1}}
	for offset in [Vector2i(5,0),Vector2i(4,0),Vector2i(3,0),Vector2i(2,0),Vector2i(1,0),Vector2i(0,1)]:
		crowded[target+offset]={"damage":1}
	var synthetic:Dictionary={"id":mixed_id,"points":points,"duration":1.0,"presentation_tracks":area_tracks,"results":crowded}
	field.schedule_native_cast(synthetic,false,target)
	var area_count:int=0
	var impact_count:int=0
	for item in field.native_fx_backend.pending:
		if item.track.stage=="area":
			area_count+=1
			assert(Vector3(item.tiles[0]).distance_to(field.pos(target+Vector2i.DOWN)+Vector3.UP*.12)<.001)
		elif item.track.stage=="impact":
			impact_count+=1
			assert(Vector3(item.points[-1]).distance_to(field.pos(target+Vector2i(5,0)))>1.0)
		else:assert(false,"primary miss must not emit projectile impact")
	assert(area_count==1 and impact_count==4,"shared area and capped secondary impacts")
	field.native_fx_backend.reset()
	synthetic.results={target:{"misses":1},other:{"misses":1}}
	field.schedule_native_cast(synthetic,false,target)
	assert(field.native_fx_backend.pending.is_empty(),"all miss suppresses confirmed hit layers")
	field.configure_native_fx({})
	print("KINDRIA_NATIVE_SHARED_AREA_PASS")
	# Independent clocks, uneven segment distances, capacity and reuse.
	var effect:Resource=load("res://effects/sample-material3/ef_fire01_projectile.efkefc")
	var track:Dictionary={"enabled":true,"anchor":"path"}
	var path:Array=[Vector3.ZERO,Vector3.RIGHT,Vector3.RIGHT*4.0]
	var slow:int=backend.launch(track,effect,path,[],.2,2.0)
	var fast:int=backend.launch(track,effect,path,[],.2,1.0)
	assert(slow>=0 and fast>=0 and slow!=fast)
	backend.advance(.5)
	assert(backend.slots[slow].node.position.distance_to(Vector3.RIGHT)<.001,"slow clock and uneven segment")
	assert(backend.slots[fast].node.position.distance_to(Vector3.RIGHT*2.0)<.001,"fast clock independent")
	backend.advance(.5)
	assert(not backend.slots[fast].busy and backend.slots[slow].busy)
	for index in range(Backend.SLOT_CAP-1):assert(backend.launch(track,effect,path,[],.2,1.0)>=0)
	assert(backend.launch(track,effect,path,[],.2,1.0)==-1,"overflow is rejected")
	backend.reset()
	assert(backend.prepare() and backend.slots.size()==Backend.SLOT_CAP,"pool initialization idempotent")
	print("KINDRIA_EFFEKSEER_CONCURRENT_PASS")
	# V9: verify the real authored track metadata and native trajectory samples.
	var motion_path:Array=[Vector3(0,.55,0),Vector3(4,.55,0)]
	var motion_cases:Dictionary={"electric_sky":"fall","water_spout":"eruption","water_surf":"wave","fire_wisp":"helix","ice_beam":"stream","rock_throw":"arc","fire_sacred":"rise"}
	for move_id in motion_cases:
		var move_tracks:Array=field.elemental_track_plan(move_id,field.combat_profile(move_id))
		var moving:Dictionary=move_tracks[3]
		assert(moving.enabled and moving.motion==motion_cases[move_id],move_id+" authored native motion")
		var endpoint:Vector3=backend.sample_motion(motion_path,4.0,1.0,moving)
		assert(endpoint.distance_to(motion_path[-1])<.001,move_id+" target endpoint")
		var first:Vector3=backend.sample_motion(motion_path,4.0,0.0,moving)
		var mid:Vector3=backend.sample_motion(motion_path,4.0,.25,moving)
		match moving.motion:
			"fall":
				assert(first.y>2.0 and absf(first.x-4.0)<.001 and mid.y<first.y)
			"eruption":
				assert(absf(first.y-.12)<.001 and absf(first.x-4.0)<.001 and mid.y>first.y)
			"wave","arc","rise":
				assert(mid.y>.55 and absf(mid.x-1.0)<.001)
			"helix":
				assert(absf(mid.y-.55)>.01 or absf(mid.z)>.01)
			"stream":
				assert(mid.distance_to(Vector3(1,.55,0))<.001)
	# Launch itself must honor the aerial origin before the first frame.
	var sky:Dictionary=field.elemental_track_plan("electric_sky",field.combat_profile("electric_sky"))[3]
	var sky_slot:int=backend.launch(sky,effect,motion_path,[],.2,1.0)
	assert(sky_slot>=0 and backend.slots[sky_slot].node.position.y>2.0)
	backend.advance(.5)
	assert(backend.slots[sky_slot].node.position.y<2.0)
	backend.reset()
	print("KINDRIA_NATIVE_CHOREOGRAPHY_PASS 7")
	var plan:Array=[
		{"stage":"ally_invoke","anchor":"source","start":0.0,"end":.15,"enabled":true},
		{"stage":"enemy_invoke","anchor":"source","start":0.0,"end":.15,"enabled":true},
		{"stage":"projectile","anchor":"path","start":.2,"end":.6,"enabled":true},
		{"stage":"impact","anchor":"target","start":.6,"end":1.0,"enabled":true}]
	var bindings:Dictionary={}
	for track_row in plan:bindings[track_row.stage]={"effect":effect,"scale":.2}
	assert(backend.schedule_cast(plan,bindings,path,[],1.0,true,false)==2)
	assert(backend.pending[0].track.stage=="enemy_invoke")
	backend.advance(.1)
	assert(backend.pending.size()==1)
	backend.advance(.2)
	assert(backend.pending.is_empty())
	var traveling:bool=false
	for slot in backend.slots:
		if slot.busy and slot.follows:
			traveling=true
			assert(slot.node.position.distance_to(Vector3.RIGHT)<.001,"late frame advances correct path fraction")
	assert(traveling)
	backend.advance(.5)
	for slot in backend.slots:assert(not slot.busy)
	assert(backend.schedule_cast(plan,bindings,path,[],1.0,false,true)==3)
	assert(backend.pending[0].track.stage=="ally_invoke")
	backend.reset()
	assert(backend.pending.is_empty())
	print("KINDRIA_EFFEKSEER_TIMELINE_PASS")
	assert(backend.slots.size()==Backend.SLOT_CAP)
	for slot in backend.slots:assert(not slot.busy)
	print("KINDRIA_EFFEKSEER_DUNGEON_PASS 5")
	quit(0)
