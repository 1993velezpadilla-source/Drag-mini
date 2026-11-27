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
	var motion_cases:Dictionary={"eos_064":"fall","eos_113":"eruption","eos_219":"wave","eos_047":"helix","eos_345":"stream","eos_028":"arc","eos_149":"rise"}
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
	var sky:Dictionary=field.elemental_track_plan("eos_064",field.combat_profile("eos_064"))[3]
	var sky_slot:int=backend.launch(sky,effect,motion_path,[],.2,1.0)
	assert(sky_slot>=0 and backend.slots[sky_slot].node.position.y>2.0)
	backend.advance(.5)
	assert(backend.slots[sky_slot].node.position.y<2.0)
	backend.reset()
	print("KINDRIA_NATIVE_CHOREOGRAPHY_PASS 7")
	# V10: real move IDs resolve their authored finish, and actual pooled
	# Godot impact particles use the selected textures without extra nodes.
	var art_cases:Dictionary={"eos_262":"ember","eos_053":"flame","eos_149":"flame","eos_047":"flame","eos_230":"wave","eos_157":"flame","eos_041":"smoke","eos_278":"flame","eos_016":"bubble","eos_255":"bubble","eos_308":"drop","eos_240":"drop","eos_219":"wave","eos_032":"spiral","eos_044":"smoke","eos_113":"drop","eos_064":"lightning","eos_188":"lightning","eos_129":"shock_ring","eos_489":"lightning","eos_193":"impact_star","eos_189":"shock_ring","eos_521":"lightning","eos_345":"crystal","eos_462":"shards","eos_270":"crystal","eos_101":"cloud","eos_535":"shards","eos_036":"slash","eos_057":"wave","eos_100":"slash","eos_211":"spiral","eos_353":"beam"}
	var particle_count:int=field.combat_particles.size()
	for move_id in art_cases:
		var p:Dictionary=field.combat_profile(move_id)
		var art:Array=field.move_finish_art(move_id,p)
		assert(art.size()==5 and art[0]==art_cases[move_id],move_id+" finish material")
		var tracks:Array=field.elemental_track_plan(move_id,p)
		assert(tracks[5].material==art[0],move_id+" track finish")
		var used:int=field.cinematic_impact_layers(move_id,p,motion_path[0],motion_path[1],.25,0,Color.WHITE,Color.BLACK,false)
		assert(used>1 and used<=11)
		var sprite:Sprite3D=field.combat_particles[1]
		assert(sprite.texture==field.combat_pixel_texture(str(art[0]),Color(str(art[2])),Color.BLACK),move_id+" actual particle texture")
		assert(field.combat_particles.size()==particle_count)
	assert(field.move_finish_art("eos_149",field.combat_profile("eos_149"))[2]!=field.move_finish_art("eos_053",field.combat_profile("eos_053"))[2])
	print("KINDRIA_MOVE_FINISH_ART_PASS 33")
	# V11 phase 1: physical jaw geometry, closing motion and elemental overlay.
	var bite_cases:Dictionary={"eos_063":"bite","eos_062":"crunch","eos_198":"fang","eos_261":"fang","eos_020":"fang","eos_452":"fang","eos_461":"fang","eos_522":"fang","eos_529":"bite","lib_electric_1":"fang","lib_dragon_3":"fang","lib_dark_1":"fang","reef_bite":"bite"}
	var bite_position:Vector3=field.pos(target)+Vector3.UP*.55
	for move_id in bite_cases:
		var art:Array=field.bite_contact_art(move_id)
		assert(art[0]==bite_cases[move_id])
		var count_open:int=field.bite_contact_fx(move_id,bite_position,0.0,0,Color.WHITE,Color.BLACK)
		assert(count_open==2)
		var upper:Sprite3D=field.combat_particles[0]
		var lower:Sprite3D=field.combat_particles[1]
		assert(upper.texture!=lower.texture)
		assert(upper.texture.get_image().get_used_rect().size.x>0)
		var open_gap:float=upper.position.distance_to(lower.position)
		var count_closed:int=field.bite_contact_fx(move_id,bite_position,.35,0,Color.WHITE,Color.BLACK)
		assert(count_closed>=3 and upper.position.distance_to(lower.position)<open_gap*.25)
		assert(field.combat_particles[2].texture==field.combat_pixel_texture(str(art[5]),Color.WHITE,Color.BLACK))
		assert(field.combat_particles.size()==particle_count)
		assert(field.bite_contact_fx(move_id,bite_position,0.0,Field.FX_PARTICLE_CAP-1,Color.WHITE,Color.BLACK)==Field.FX_PARTICLE_CAP-1,"jaw pair atomic at cap")
	var normal_bite:Array=field.bite_contact_art("eos_063")
	var heavy_bite:Array=field.bite_contact_art("eos_062")
	assert(float(heavy_bite[1])>float(normal_bite[1])*1.5)
	assert(field.bite_contact_fx("eos_063",bite_position,.75,0,Color.WHITE,Color.BLACK)==0)
	assert(field.bite_contact_fx("eos_062",bite_position,.75,0,Color.WHITE,Color.BLACK)>0)
	var bite_profile:Dictionary=field.combat_profile("eos_063")
	var bite_burst:Dictionary={"id":"eos_063","profile":bite_profile,"points":[field.pos(origin),bite_position],"results":{target:{"misses":1}}}
	assert(field.element_finish_fx(bite_burst,float(bite_profile.impact),0)==1,"miss gets dissipating cloud only")
	bite_burst.results={target:{"damage":7}}
	assert(field.element_finish_fx(bite_burst,float(bite_profile.impact),0)>2)
	assert(field.combat_particles[0].texture==field.combat_pixel_texture("bite_upper",Color(str(normal_bite[3])),Color(str(normal_bite[4]))))
	print("KINDRIA_CONTACT_BITE_PASS 13")
	# V11.2: physical fist and independent elemental accents on actual move IDs.
	var punch_cases:Dictionary={"lib_fighting_3":"impact_star","eos_065":"lightning","eos_075":"shock_ring","eos_103":"shards","eos_126":"smoke","eos_136":"impact_star","eos_246":"shock_ring","eos_264":"spiral","eos_292":"flame","eos_300":"slash","eos_322":"shock_ring","eos_344":"crystal","eos_430":"impact_star","eos_500":"spiral","eos_510":"shards","eos_515":"smoke","eos_347":"impact_star"}
	var punch_source:Vector3=bite_position-Vector3.RIGHT*1.4
	for move_id in punch_cases:
		var art:Array=field.punch_contact_art(move_id)
		assert(art.size()==8 and art[7]==punch_cases[move_id])
		assert(field.punch_contact_fx(move_id,punch_source,bite_position,0.0,0,Color.WHITE,Color.BLACK)==1)
		var fist:Sprite3D=field.combat_particles[0]
		var initial:Vector3=fist.position
		assert(fist.texture.get_image().get_used_rect().size.x>0)
		assert(fist.texture==field.combat_pixel_texture(str(art[4]),Color(str(art[5])),Color(str(art[6]))))
		var hit_age:float=float(art[2])*.28
		assert(field.punch_contact_fx(move_id,punch_source,bite_position,hit_age,0,Color.WHITE,Color.BLACK)>=2)
		assert(fist.position.distance_to(initial)>.05)
		assert(field.combat_particles[1].texture==field.combat_pixel_texture(str(art[7]),Color.WHITE,Color.BLACK))
		assert(field.combat_particles.size()==particle_count)
		assert(field.punch_contact_fx(move_id,punch_source,bite_position,float(art[2]),0,Color.WHITE,Color.BLACK)==0)
		assert(field.punch_contact_fx(move_id,punch_source,bite_position,0.0,Field.FX_PARTICLE_CAP,Color.WHITE,Color.BLACK)==Field.FX_PARTICLE_CAP)
	var flurry:Array=field.punch_contact_art("eos_347")
	field.punch_contact_fx("eos_347",punch_source,bite_position,float(flurry[2])*.10,0,Color.WHITE,Color.BLACK,3)
	var first_fist:Vector3=field.combat_particles[0].position
	field.punch_contact_fx("eos_347",punch_source,bite_position,float(flurry[2])*(.10+1.0/3.0),0,Color.WHITE,Color.BLACK,3)
	assert(field.combat_particles[0].position.distance_to(first_fist)>.30,"confirmed flurry alternates fists")
	var punch_profile:Dictionary=field.combat_profile("eos_292")
	var punch_burst:Dictionary={"id":"eos_292","profile":punch_profile,"points":[field.pos(origin),bite_position],"results":{target:{"misses":1}}}
	assert(field.element_finish_fx(punch_burst,float(punch_profile.impact),0)==1)
	punch_burst.results={target:{"damage":8,"hits":1}}
	assert(field.element_finish_fx(punch_burst,float(punch_profile.impact),0)>1)
	var fire_art:Array=field.punch_contact_art("eos_292")
	assert(field.combat_particles[0].texture==field.combat_pixel_texture("fist_front",Color(str(fire_art[5])),Color(str(fire_art[6]))))
	print("KINDRIA_CONTACT_PUNCH_PASS 17")
	# V11.3: actual feet, directional contact and element accents for all kicks.
	var kick_cases:Dictionary={"lib_fighting_2":"slash","eos_092":"shards","eos_204":"slash","eos_206":"impact_star","eos_271":"shards","eos_276":"flame","eos_303":"shock_ring","eos_321":"shock_ring","eos_222":"impact_star","eos_210":"slash"}
	for move_id in kick_cases:
		var art:Array=field.kick_contact_art(move_id)
		assert(art.size()==9 and art[8]==kick_cases[move_id])
		assert(field.kick_contact_fx(move_id,punch_source,bite_position,0.0,0,Color.WHITE,Color.BLACK)==1)
		var foot:Sprite3D=field.combat_particles[0]
		var initial:Vector3=foot.position
		assert(foot.texture.get_width()==32 and foot.texture.get_height()==32)
		assert(is_equal_approx(foot.pixel_size,.016))
		assert(foot.texture.get_image().get_used_rect().size.x>0)
		var expected_texture:Texture2D=field.combat_pixel_texture(str(art[5]),Color(str(art[6])),Color(str(art[7])))
		var mirror_texture:Texture2D=expected_texture
		if str(art[5]) in ["kick_side","kick_raised"]:
			mirror_texture=field.combat_pixel_texture(str(art[5])+"_mirror",Color(str(art[6])),Color(str(art[7])))
		assert(foot.texture==expected_texture or foot.texture==mirror_texture)
		assert(field.kick_contact_fx(move_id,punch_source,bite_position,float(art[1])*.30,0,Color.WHITE,Color.BLACK)>=2)
		assert(foot.position.distance_to(initial)>.05)
		assert(field.combat_particles[1].texture==field.combat_pixel_texture(str(art[8]),Color.WHITE,Color.BLACK))
		assert(is_equal_approx(field.combat_particles[1].pixel_size,.032))
		assert(field.combat_particles.size()==particle_count)
		assert(field.kick_contact_fx(move_id,punch_source,bite_position,float(art[1]),0,Color.WHITE,Color.BLACK)==0)
		assert(field.kick_contact_fx(move_id,punch_source,bite_position,0.0,Field.FX_PARTICLE_CAP,Color.WHITE,Color.BLACK)==Field.FX_PARTICLE_CAP)
	field.kick_contact_fx("eos_092",punch_source,bite_position,0.0,0,Color.WHITE,Color.BLACK)
	var low_height:float=field.combat_particles[0].position.y
	field.kick_contact_fx("eos_206",punch_source,bite_position,0.0,0,Color.WHITE,Color.BLACK)
	assert(field.combat_particles[0].position.y>low_height+.80)
	var triple_art:Array=field.kick_contact_art("eos_210")
	field.kick_contact_fx("eos_210",punch_source,bite_position,float(triple_art[1])*.10,0,Color.WHITE,Color.BLACK,3)
	var first_kick:Vector3=field.combat_particles[0].position
	var first_foot:Texture2D=field.combat_particles[0].texture
	field.kick_contact_fx("eos_210",punch_source,bite_position,float(triple_art[1])*(.10+1.0/3.0),0,Color.WHITE,Color.BLACK,3)
	assert(field.combat_particles[0].position.distance_to(first_kick)>.35)
	assert(field.combat_particles[0].texture!=first_foot)
	var kick_profile:Dictionary=field.combat_profile("eos_276")
	var kick_burst:Dictionary={"id":"eos_276","profile":kick_profile,"points":[field.pos(origin),bite_position],"results":{target:{"misses":1}}}
	assert(field.element_finish_fx(kick_burst,float(kick_profile.impact),0)==1)
	kick_burst.results={target:{"damage":8,"hits":1}}
	assert(field.element_finish_fx(kick_burst,float(kick_profile.impact),0)>1)
	var blaze_art:Array=field.kick_contact_art("eos_276")
	assert(field.combat_particles[0].texture==field.combat_pixel_texture("kick_heel",Color(str(blaze_art[6])),Color(str(blaze_art[7]))))
	print("KINDRIA_CONTACT_KICK_PASS 10")
	# Classic footprint: distinct three toes and a compact pad, not a shin.
	var stamp:Image=field.classic_kick_stamp("kick_sole",Color.WHITE,Color("#554258"))
	for pixel in [Vector2i(7,10),Vector2i(15,6),Vector2i(23,10),Vector2i(15,19)]:
		assert(stamp.get_pixelv(pixel).a>.9,"toe or sole absent")
	assert(stamp.get_pixel(15,12).a==0.0,"toe-to-pad separation")
	assert(stamp.get_pixel(0,0).a==0.0 and stamp.get_pixel(31,31).a==0.0)
	assert(stamp.save_png("/tmp/effekseer-review/kick-classic-stamp.png")==OK)
	# Capture each move using the real dungeon impact compositor.
	for move_id in kick_cases:
		var p:Dictionary=field.combat_profile(move_id)
		var art:Array=field.kick_contact_art(move_id)
		var hit_count:int=3 if move_id=="eos_210" else 2 if move_id=="eos_222" else 1
		var burst:Dictionary={"id":move_id,"profile":p,"points":[field.pos(origin)+Vector3.UP*.55,bite_position],"results":{target:{"damage":8,"hits":hit_count}}}
		for particle in field.combat_particles:particle.hide()
		var age:float=float(art[1])*.30/float(hit_count)
		var tick:float=lerpf(float(p.impact),1.0,age)
		var used:int=field.element_finish_fx(burst,tick,0)
		assert(used>1)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/kick-remake-"+move_id+".png")==OK)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_CLASSIC_KICK_STAMP_PASS 10")
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
