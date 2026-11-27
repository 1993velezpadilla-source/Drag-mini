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
	# V11.4: physical talons and single blades, not a recolored universal slash.
	var claw_cases:Dictionary={"lib_ghost_1":"smoke","lib_dragon_1":"flame","eos_018":"impact_star","eos_081":"slash","eos_208":"flame","eos_260":"impact_star","eos_275":"shock_ring","eos_325":"shards","eos_463":"spiral","eos_476":"smoke","eos_491":"smoke","eos_312":"impact_star","eos_346":"leaf","eos_360":"slash"}
	for move_id in claw_cases:
		var art:Array=field.claw_contact_art(move_id)
		assert(art.size()==8 and art[6]==claw_cases[move_id])
		assert(field.claw_contact_fx(move_id,punch_source,bite_position,0.0,0,Color.WHITE,Color.BLACK)==1)
		var mark:Sprite3D=field.combat_particles[0]
		var start_mark:Vector3=mark.position
		assert(mark.texture.get_width()==32 and mark.texture.get_height()==32)
		assert(mark.texture.get_image().get_used_rect().size.x>0)
		assert(is_equal_approx(mark.pixel_size,.016))
		assert(mark.texture==field.combat_pixel_texture(str(art[3]),Color(str(art[4])),Color(str(art[5]))))
		var used_marks:int=field.claw_contact_fx(move_id,punch_source,bite_position,float(art[1])*.30,0,Color.WHITE,Color.BLACK)
		assert(used_marks>=2)
		assert(mark.position.distance_to(start_mark)>.05)
		assert(field.combat_particles[1].texture==field.combat_pixel_texture(str(art[6]),Color.WHITE,Color.BLACK))
		assert(is_equal_approx(field.combat_particles[1].pixel_size,.032))
		if str(art[7])=="ghost":
			assert(used_marks==4)
			assert(field.combat_particles[2].texture==mark.texture)
			assert(field.combat_particles[3].texture==field.combat_pixel_texture("spiral",Color(str(art[4])),Color(str(art[5]))))
		assert(field.combat_particles.size()==particle_count)
		assert(field.claw_contact_fx(move_id,punch_source,bite_position,float(art[1]),0,Color.WHITE,Color.BLACK)==0)
		assert(field.claw_contact_fx(move_id,punch_source,bite_position,0.0,Field.FX_PARTICLE_CAP,Color.WHITE,Color.BLACK)==Field.FX_PARTICLE_CAP)
	var ghost_profile:Dictionary=field.combat_profile("eos_476")
	var ghost_burst:Dictionary={"id":"eos_476","profile":ghost_profile,"points":[field.pos(origin),bite_position],"results":{target:{"misses":1}}}
	assert(field.element_finish_fx(ghost_burst,float(ghost_profile.impact),0)==1)
	ghost_burst.results={target:{"damage":8,"hits":1}}
	assert(field.element_finish_fx(ghost_burst,float(ghost_profile.impact),0)>1)
	var spectral_art:Array=field.claw_contact_art("eos_476")
	assert(field.combat_particles[0].texture==field.combat_pixel_texture("claw_spectral",Color(str(spectral_art[4])),Color(str(spectral_art[5]))))
	# Visual artifacts for all 14 physical claw and blade moves.
	for move_id in claw_cases:
		var p:Dictionary=field.combat_profile(move_id)
		var art:Array=field.claw_contact_art(move_id)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[field.pos(origin)+Vector3.UP*.55,bite_position],"results":{target:{"damage":8,"hits":1}}}
		for particle in field.combat_particles:particle.hide()
		var tick:float=lerpf(float(p.impact),1.0,float(art[1])*.30)
		assert(field.element_finish_fx(burst,tick,0)>1)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/claw-"+move_id+".png")==OK)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_CONTACT_CLAW_PASS 14")
	# V11.5: confirmed creature contact, directional silhouettes and elemental accents.
	var body_cases:Dictionary={"lib_normal_1":"impact_star","lib_normal_2":"shock_ring","lib_bug_2":"shards","eos_001":"shards","eos_121":"impact_star","eos_139":"impact_star","eos_140":"shock_ring","eos_154":"impact_star","eos_161":"shards","eos_176":"impact_star","eos_203":"shock_ring","eos_235":"shock_ring","eos_283":"venom_splash","eos_323":"leaf","eos_348":"shock_ring","eos_354":"lightning","eos_431":"shards","eos_433":"wave","eos_455":"shock_ring","eos_473":"spiral","eos_517":"flame","eos_533":"shards","eos_177":"shards","eos_009":"impact_star"}
	for move_id in body_cases:
		var art:Array=field.body_contact_art(move_id)
		assert(art.size()==8 and art[6]==body_cases[move_id])
		assert(field.body_contact_fx(move_id,punch_source,bite_position,0.0,0,Color.WHITE,Color.BLACK)==1)
		var emblem:Sprite3D=field.combat_particles[0]
		var start_position:Vector3=emblem.position
		var face:Texture2D=field.combat_pixel_texture(str(art[3]),Color(str(art[4])),Color(str(art[5])))
		var mirrored:Texture2D=field.combat_pixel_texture(str(art[3])+"_mirror",Color(str(art[4])),Color(str(art[5])))
		assert(emblem.texture==face or emblem.texture==mirrored)
		assert(emblem.texture.get_width()==32 and emblem.texture.get_height()==32)
		assert(emblem.texture.get_image().get_used_rect().size.x>0)
		assert(is_equal_approx(emblem.pixel_size,.016))
		assert(field.body_contact_fx(move_id,punch_source,bite_position,float(art[1])*.30,0,Color.WHITE,Color.BLACK)>=2)
		assert(emblem.position.distance_to(start_position)>.05)
		assert(field.combat_particles[1].texture==field.combat_pixel_texture(str(art[6]),Color.WHITE,Color.BLACK))
		assert(is_equal_approx(field.combat_particles[1].pixel_size,.032))
		assert(field.combat_particles.size()==particle_count)
		assert(field.body_contact_fx(move_id,punch_source,bite_position,float(art[1]),0,Color.WHITE,Color.BLACK)==0)
		assert(field.body_contact_fx(move_id,punch_source,bite_position,0.0,Field.FX_PARTICLE_CAP,Color.WHITE,Color.BLACK)==Field.FX_PARTICLE_CAP)
	assert(field.body_contact_art("eos_122").is_empty(),"Tail Whip remains a status animation")
	assert(field.body_contact_art("eos_489").is_empty(),"Charge Beam is not a body contact attack")
	var ram_profile:Dictionary=field.combat_profile("eos_354")
	var ram_burst:Dictionary={"id":"eos_354","profile":ram_profile,"points":[field.pos(origin),bite_position],"results":{target:{"misses":1}}}
	assert(field.element_finish_fx(ram_burst,float(ram_profile.impact),0)==1)
	ram_burst.results={target:{"damage":8,"hits":1}}
	assert(field.element_finish_fx(ram_burst,float(ram_profile.impact),0)>1)
	# Capture a representative frame for each authored move.
	for move_id in body_cases:
		var p:Dictionary=field.combat_profile(move_id)
		var art:Array=field.body_contact_art(move_id)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[field.pos(origin)+Vector3.UP*.55,bite_position],"results":{target:{"damage":8,"hits":1}}}
		for particle in field.combat_particles:particle.hide()
		var tick:float=lerpf(float(p.impact),1.0,float(art[1])*.30)
		assert(field.element_finish_fx(burst,tick,0)>1)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/body-"+move_id+".png")==OK)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_CONTACT_BODY_PASS 24")
	# V11.6: cast-centered blasts, outcome-driven restraint and return trails.
	var special_cases:Dictionary={"eos_123":"burst","eos_155":"burst","eos_272":"burst","eos_120":"lash","lib_grass_1":"lash","eos_182":"lash","eos_511":"lash","eos_023":"silk","eos_086":"silk","eos_294":"coil","eos_125":"coil","eos_071":"coil","eos_069":"clamp","eos_116":"clamp","eos_076":"drain","eos_135":"drain","eos_320":"drain","eos_080":"drain","eos_500":"drain","eos_329":"seed","lib_normal_3":"sound","eos_152":"sound","eos_241":"sound","eos_530":"sound","eos_446":"sound","eos_034":"sound","eos_171":"sound","eos_027":"sound","eos_083":"sound","eos_284":"sound","eos_293":"sound","eos_112":"sound","eos_025":"sound","eos_217":"sound","eos_195":"sound","eos_026":"sound","tentacle_snare":"lash","vine_snap":"lash","gravity_web":"silk","abyss_grasp":"clamp","eos_192":"coil"}
	var special_source:Vector3=field.pos(origin)+Vector3.UP*.55
	for move_id in special_cases:
		var art:Array=field.special_contact_art(move_id)
		assert(art.size()==4 and art[0]==special_cases[move_id])
		var p:Dictionary=field.combat_profile(move_id)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"results":{target:{"damage":8,"hits":1}}}
		var peak:float=float(p.impact)
		var tick:float=lerpf(peak,1.0,.25)
		for particle in field.combat_particles:particle.hide()
		var used_special:int=field.special_contact_fx(burst,tick,0,Color.WHITE,Color.BLACK)
		assert(used_special>0 and used_special<=12)
		assert(field.combat_particles.size()==particle_count)
		assert(field.special_contact_fx(burst,tick,Field.FX_PARTICLE_CAP,Color.WHITE,Color.BLACK)==Field.FX_PARTICLE_CAP)
		burst.results={target:{"misses":1}}
		var missed:int=field.special_contact_fx(burst,tick,0,Color.WHITE,Color.BLACK)
		assert(missed==6 if art[0]=="burst" else missed==0)
		if move_id in ["eos_123","eos_155"]:
			assert(field.combat_particles[0].position.distance_to(special_source)<.001)
		if str(art[0])=="drain":
			burst.results={target:{"damage":8},origin:{"heal":4}}
			field.special_contact_fx(burst,peak,0,Color.WHITE,Color.BLACK)
			var before:float=field.combat_particles[0].position.distance_to(special_source)
			field.special_contact_fx(burst,lerpf(peak,1.0,.70),0,Color.WHITE,Color.BLACK)
			assert(field.combat_particles[0].position.distance_to(special_source)<before)
		burst.results={target:{"damage":8,"hits":1}}
		for particle in field.combat_particles:particle.hide()
		field.special_contact_fx(burst,tick,0,Color.WHITE,Color.BLACK)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/special-"+move_id+".png")==OK)
	var silk_profile:Dictionary=field.combat_profile("eos_086")
	var silk_burst:Dictionary={"id":"eos_086","profile":silk_profile,"points":[special_source,bite_position],"results":{target:{"effects":1}}}
	assert(field.special_contact_fx(silk_burst,float(silk_profile.impact),0,Color.WHITE,Color.BLACK)==2)
	for mode in ["special_tongue","special_vine","special_thread","special_coil","special_clamp","special_note","special_wave"]:
		var tex:Texture2D=field.combat_pixel_texture(mode,Color.WHITE,Color.BLACK)
		assert(tex.get_width()==32 and tex.get_image().get_used_rect().size.x>0)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_SPECIAL_CONTACT_PASS 41")
	# V11.7: all actual projectile IDs, distinct motion and confirmed finish.
	var projectile_cases:Dictionary={"lib_fire_1":"dart","lib_fire_2":"beam","lib_water_2":"beam","lib_ice_1":"dart","lib_flying_1":"dart","lib_psychic_2":"pulse","lib_rock_1":"dart","lib_dark_3":"pulse","lib_fairy_1":"dart","eos_028":"lob","eos_031":"orb","eos_042":"beam","eos_053":"beam","eos_107":"beam","eos_114":"beam","eos_127":"orb","eos_145":"volley","eos_151":"beam","eos_166":"lob","eos_193":"orb","eos_213":"dart","eos_239":"beam","eos_240":"beam","eos_242":"beam","eos_251":"volley","eos_255":"beam","eos_262":"dart","eos_279":"lob","eos_280":"lob","eos_299":"dart","eos_308":"beam","eos_309":"orb","eos_310":"pulse","eos_345":"beam","eos_436":"pulse","eos_443":"orb","eos_454":"orb","eos_462":"dart","eos_468":"lob","eos_485":"lob","eos_486":"lob","eos_489":"beam","eos_501":"lob","eos_508":"orb","eos_523":"lob","eos_527":"dart","eos_536":"beam","eos_538":"meteor","eos_539":"pulse","eos_163":"volley","eos_164":"volley","eos_201":"volley","eos_306":"volley","eos_350":"volley","eos_002":"roll","eos_108":"pulse","eos_341":"beam","eos_504":"dart"}
	for move_id in projectile_cases:
		var art:Array=field.projectile_contact_art(move_id)
		assert(art.size()==5 and art[0]==projectile_cases[move_id])
		var p:Dictionary=field.combat_profile(move_id)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"results":{target:{"damage":8,"hits":2}}}
		var peak:float=float(p.impact)
		for particle in field.combat_particles:particle.hide()
		var used_shots:int=field.projectile_contact_fx(burst,peak*.5,0,Color.WHITE,Color.BLACK)
		assert(used_shots>0 and used_shots<=6)
		var shot:Sprite3D=field.combat_particles[0]
		assert(shot.texture==field.combat_pixel_texture(str(art[1]),Color.WHITE,Color.BLACK))
		if art[0]=="lob":assert(shot.position.y>maxf(special_source.y,bite_position.y))
		if art[0]=="meteor":assert(shot.position.y>bite_position.y+1.0)
		if art[0]=="beam":assert(used_shots==6 and shot.position.distance_to(field.combat_particles[5].position)>.1)
		if art[0]=="roll":assert(is_equal_approx(shot.position.y,.18))
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/projectile-"+move_id+".png")==OK)
		var tick:float=lerpf(peak,1.0,.25)
		assert(field.projectile_contact_fx(burst,tick,0,Color.WHITE,Color.BLACK)>0)
		assert(field.combat_particles[0].texture==field.combat_pixel_texture(str(art[2]),Color.WHITE,Color.BLACK))
		burst.results={target:{"misses":1}}
		assert(field.projectile_contact_fx(burst,tick,0,Color.WHITE,Color.BLACK)==0)
		assert(field.projectile_contact_fx(burst,peak*.5,Field.FX_PARTICLE_CAP,Color.WHITE,Color.BLACK)==Field.FX_PARTICLE_CAP)
		assert(field.combat_particles.size()==particle_count)
	for mode in ["projectile_seed","projectile_needle","projectile_stone","projectile_orb","projectile_ray"]:
		var tex:Texture2D=field.combat_pixel_texture(mode,Color.WHITE,Color.BLACK)
		assert(tex.get_width()==32 and tex.get_image().get_used_rect().size.x>0)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_PROJECTILE_CONTACT_PASS 58")
	# V11.8: terrain persists on actual affected tiles even when no enemy is hit.
	var terrain_cases:Dictionary={"lib_ground_1":"quake","lib_rock_3":"fall","eos_008":"burrow","eos_030":"fall","eos_032":"vortex","eos_036":"wind","eos_057":"wind","eos_060":"wind","eos_064":"storm","eos_073":"rise","eos_082":"wind","eos_097":"wind","eos_101":"fall","eos_113":"rise","eos_129":"storm","eos_156":"dive","eos_158":"fall","eos_159":"wave","eos_162":"vortex","eos_219":"wave","eos_230":"wave","eos_270":"wind","eos_272":"rise","eos_278":"rise","eos_437":"wind","eos_481":"rise","eos_484":"rise","eos_519":"rise","eos_521":"storm","eos_012":"weather","eos_014":"weather","eos_141":"weather","eos_223":"sun","eos_131":"rift","eos_118":"quake","eos_296":"quake","eos_535":"fall","eos_435":"rift","eos_460":"wind","eos_494":"wave","eos_538":"fall","eos_394":"wind"}
	var terrain_tiles:Array=[]
	for i in range(12):
		terrain_tiles.append(field.pos(target+Vector2i(i,0))+Vector3.UP*.12)
	terrain_tiles.append(terrain_tiles[0])
	for move_id in terrain_cases:
		var art:Array=field.terrain_contact_art(move_id)
		assert(art.size()==3 and art[0]==terrain_cases[move_id])
		var p:Dictionary=field.combat_profile(move_id)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"tiles":terrain_tiles,"results":{}}
		var cells:Array[Vector3]=field.terrain_contact_tiles(burst)
		assert(cells.size()==Field.TERRAIN_TILE_CAP)
		assert(is_equal_approx(cells[0].y,.055))
		assert(Vector2(cells[0].x,cells[0].z).distance_to(Vector2(bite_position.x,bite_position.z))<.001)
		var peak:float=clampf(float(p.impact),.01,.99)
		for particle in field.combat_particles:particle.hide()
		var count_ground:int=field.terrain_contact_fx(burst,peak*.5,0,Color.WHITE,Color.BLACK)
		assert(count_ground>0 and count_ground<=12)
		if art[0] in ["burrow","dive","quake","rift","rise","wave","vortex"]:
			assert(is_equal_approx(field.combat_particles[0].position.y,.055))
		if art[0] in ["fall","storm","weather","sun"]:
			assert(field.combat_particles[0].position.y>.20)
		assert(field.terrain_contact_fx(burst,peak*.5,Field.FX_PARTICLE_CAP,Color.WHITE,Color.BLACK)==Field.FX_PARTICLE_CAP)
		assert(field.combat_particles.size()==particle_count)
		burst.tiles=[field.pos(target)]
		for particle in field.combat_particles:particle.hide()
		assert(field.terrain_contact_fx(burst,peak*.5,0,Color.WHITE,Color.BLACK)>0)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/terrain-"+move_id+".png")==OK)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_TERRAIN_CONTACT_PASS 42")
	# V11.9: status symbols are tied to confirmed changes, not attack damage.
	var support_cases:Dictionary={"eos_117":"heal","eos_218":"heal","eos_006":"heal","eos_094":"heal","eos_173":"heal","eos_449":"heal","eos_165":"heal","eos_318":"heal","eos_509":"heal","eos_236":"heal","eos_439":"heal","eos_526":"heal","eos_015":"cleanse","eos_026":"cleanse","eos_339":"cleanse","eos_456":"cleanse","eos_088":"cleanse","eos_301":"shield","eos_305":"shield","eos_104":"shield","eos_338":"shield","eos_259":"shield","eos_134":"shield","eos_130":"shield","eos_258":"shield","eos_186":"shield","eos_058":"shield","eos_070":"shield","eos_202":"shield","eos_520":"shield","eos_302":"shield","eos_298":"shield","eos_003":"sleep","eos_004":"sleep","eos_034":"sleep","eos_079":"sleep","eos_111":"sleep","eos_231":"sleep","eos_483":"sleep","eos_084":"sleep","eos_232":"sleep","eos_013":"confuse","eos_171":"confuse","eos_191":"confuse","eos_274":"confuse","eos_196":"poison","eos_197":"poison","eos_199":"poison","eos_124":"paralysis","eos_192":"paralysis","eos_281":"paralysis","eos_047":"burn","eos_183":"transform","eos_184":"transform","eos_286":"transform","eos_282":"transform","eos_304":"transform","eos_169":"transform","eos_148":"transform","eos_056":"transform","eos_055":"boost","eos_099":"boost","eos_181":"boost","eos_195":"boost","eos_215":"boost","eos_265":"boost","eos_288":"boost","eos_319":"boost","eos_333":"boost","eos_542":"boost","eos_095":"boost","eos_343":"boost","eos_444":"boost","eos_540":"boost","eos_074":"boost","eos_492":"boost","eos_257":"boost","eos_128":"boost","eos_160":"boost","eos_019":"boost","eos_010":"weaken","eos_011":"weaken","eos_027":"weaken","eos_033":"weaken","eos_083":"weaken","eos_085":"weaken","eos_122":"weaken","eos_142":"weaken","eos_146":"weaken","eos_217":"weaken","eos_224":"weaken","eos_273":"weaken","eos_106":"weaken","eos_351":"weaken","eos_267":"weaken","eos_534":"weaken","eos_266":"seal","eos_450":"seal","eos_059":"seal","eos_017":"seal","eos_022":"seal","eos_172":"seal","eos_466":"seal","eos_089":"seal","eos_194":"seal","eos_225":"regen","eos_434":"regen","eos_233":"regen","eos_021":"link","eos_313":"link","eos_464":"link","eos_448":"link","eos_506":"link","eos_513":"link","eos_137":"link","eos_209":"link","eos_482":"link","eos_187":"phase","eos_478":"phase","eos_493":"phase","eos_499":"phase"}
	for move_id in support_cases:
		var kind:String=field.support_contact_kind(move_id)
		assert(kind==support_cases[move_id])
		var p:Dictionary=field.combat_profile(move_id)
		var peak:float=clampf(float(p.impact),.01,.99)
		var tick:float=lerpf(peak,1.0,.25)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"results":{target:{"heal":8} if kind=="heal" else {"effects":1}}}
		for particle in field.combat_particles:particle.hide()
		assert(field.support_contact_fx(burst,tick,0)==3)
		var icon:Sprite3D=field.combat_particles[0]
		var visual:Array=Field.SUPPORT_VISUALS[kind]
		assert(icon.texture==field.combat_pixel_texture(str(visual[0]),Color(str(visual[2])),Color(str(visual[3]))))
		assert(field.combat_particles.size()==particle_count)
		assert(field.support_contact_fx(burst,tick,Field.FX_PARTICLE_CAP)==Field.FX_PARTICLE_CAP)
		burst.results={target:{"misses":1}}
		assert(field.support_contact_fx(burst,tick,0)==0)
		burst.results={target:{"blocked":1}}
		assert(field.support_contact_fx(burst,tick,0)==0)
		if kind=="heal":
			burst.results={target:{"effects":1}}
			assert(field.support_contact_fx(burst,tick,0)==0,"healing requires real HP gain")
		if move_id in ["eos_117","eos_301","eos_111","eos_197","eos_047","eos_282","eos_181","eos_027","eos_450","eos_434","eos_464","eos_187","eos_192","eos_013","eos_015"]:
			burst.results={target:{"heal":8} if kind=="heal" else {"effects":1}}
			for particle in field.combat_particles:particle.hide()
			field.support_contact_fx(burst,tick,0)
			await frames()
			assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/support-"+move_id+".png")==OK)
	for mode in ["support_cross","support_ward","support_up","support_down","support_moon","support_seal","support_change"]:
		var tex:Texture2D=field.combat_pixel_texture(mode,Color.WHITE,Color.BLACK)
		assert(tex.get_width()==32 and tex.get_image().get_used_rect().size.x>0)
	var saved_shield:String=field.run.shield_kind
	var saved_turns:int=field.run.shield_turns
	field.run.shield_kind="reflect";field.run.shield_turns=2
	assert("ward_reflect" in field.living_player_statuses())
	assert(field.living_status_palette("ward_reflect")[0]=="support_ward")
	field.run.shield_turns=0
	assert(not "ward_reflect" in field.living_player_statuses())
	field.run.shield_kind=saved_shield;field.run.shield_turns=saved_turns
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_SUPPORT_CONTACT_PASS 121")
	# V12.1: aerial and open-hand impacts omitted from previous profiles.
	var contact_motion_cases:Dictionary={"eos_100":["wing","dive",1.12,"slash"],"eos_153":["wing","dive",0.91,"cloud"],"eos_205":["crest","bounce",1,"shock_ring"],"eos_179":["wing","sweep",0.83,"slash"],"eos_518":["wing","dive",1.2,"flame"],"eos_211":["beak","drill",1.02,"shards"],"eos_174":["beak","jab",0.65,"impact_star"],"eos_490":["beak","jab",0.75,"leaf"],"eos_178":["wing","sweep",0.88,"cloud"],"eos_244":["wing","sweep",1,"shards"],"eos_477":["crest","vanish",1.1,"smoke"],"eos_132":["crest","rush",1.05,"slash"],"eos_190":["crest","rush",0.68,"slash"],"eos_226":["palm","jab",0.65,"impact_star"],"eos_039":["palm","multi",0.72,"impact_star"],"eos_175":["palm","multi",0.82,"shock_ring"],"eos_531":["palm","sweep",0.85,"impact_star"],"eos_507":["palm","jab",1,"shock_ring"],"eos_068":["chop","down",0.8,"slash"],"eos_072":["chop","down",1.05,"shards"],"eos_090":["cross","down",1.05,"slash"],"eos_243":["crest","rush",1.18,"shock_ring"],"eos_440":["palm","rush",1.08,"impact_star"],"eos_170":["crest","toss",1.1,"shock_ring"],"eos_311":["beak","multi",0.74,"impact_star"],"eos_487":["palm","multi",0.83,"impact_star"],"eos_250":["palm","down",0.78,"impact_star"],"eos_432":["crest","rush",0.85,"drop"],"eos_451":["crest","vanish",0.78,"smoke"],"eos_498":["crest","rush",1.15,"flame"],"eos_502":["wing","sweep",0.8,"leaf"],"lib_fighting_1":["palm","jab",0.83,"shock_ring"],"alt_sylphowl":["wing","sweep",0.78,"slash"],"alt_lunamoth":["wing","sweep",0.9,"impact_star"]}
	for move_id in contact_motion_cases:
		var art:Array=field.motion_contact_art(move_id)
		assert(art==contact_motion_cases[move_id])
		assert(field.motion_contact_fx(move_id,punch_source,bite_position,0.0,0,Color.WHITE,Color.BLACK)==1)
		var emblem:Sprite3D=field.combat_particles[0]
		var initial:Vector3=emblem.position
		assert(emblem.texture.get_width()==32 and emblem.texture.get_image().get_used_rect().size.x>0)
		assert(is_equal_approx(emblem.pixel_size,.016))
		assert(field.motion_contact_fx(move_id,punch_source,bite_position,.25,0,Color.WHITE,Color.BLACK)>=2)
		assert(emblem.position.distance_to(initial)>.05)
		assert(field.combat_particles[1].texture==field.combat_pixel_texture(str(art[3]),Color.WHITE,Color.BLACK))
		assert(field.motion_contact_fx(move_id,punch_source,bite_position,.82,0,Color.WHITE,Color.BLACK)==0)
		assert(field.motion_contact_fx(move_id,punch_source,bite_position,0.0,Field.FX_PARTICLE_CAP,Color.WHITE,Color.BLACK)==Field.FX_PARTICLE_CAP)
		assert(field.combat_particles.size()==particle_count)
		var p:Dictionary=field.combat_profile(move_id)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"results":{target:{"misses":1}}}
		assert(field.priority_contact_fx(burst,float(p.impact),0)==0)
		burst.results={target:{"damage":8,"hits":1}}
		for particle in field.combat_particles:particle.hide()
		assert(field.element_finish_fx(burst,lerpf(float(p.impact),1.0,.25),0)>1)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/motion-"+move_id+".png")==OK)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_MOTION_CONTACT_PASS 34")
	# V12.2: every previously uncovered water, fire, ice and electric record.
	var elemental_cases:Dictionary={"alt_bubblewisp":"TERRAIN","alt_coralcrab":"PROJECTILE","alt_crystarok":"PROJECTILE","alt_eelstrix":"BITE","alt_jellymancer":"SPECIAL","alt_leviathorn":"PROJECTILE","alt_marrowray":"PROJECTILE","alt_nova_wisp":"TERRAIN","alt_reef_pup":"PROJECTILE","alt_tidal_sovereign":"BODY","bubble_burst":"PROJECTILE","electric_lash":"SPECIAL","eos_016":"PROJECTILE","eos_041":"TERRAIN","eos_044":"PROJECTILE","eos_052":"BODY","eos_087":"MOTION","eos_144":"BODY","eos_149":"BODY","eos_150":"TERRAIN","eos_157":"PROJECTILE","eos_180":"PROJECTILE","eos_188":"PROJECTILE","eos_189":"PROJECTILE","eos_291":"TERRAIN","eos_307":"TERRAIN","eos_469":"PROJECTILE","eos_524":"TERRAIN","jelly_pulse":"TERRAIN","lib_electric_2":"PROJECTILE","lib_electric_3":"TERRAIN","lib_fire_3":"TERRAIN","lib_ice_2":"PROJECTILE","lib_ice_3":"TERRAIN","lib_water_1":"PROJECTILE","lib_water_3":"TERRAIN","nova_bolt":"PROJECTILE","prism_shatter":"TERRAIN","spiral_current":"BODY","tidal_jaws":"BITE"}
	for move_id in elemental_cases:
		var group:String=elemental_cases[move_id]
		var p:Dictionary=field.combat_profile(move_id)
		var style:Array=field.combat_style(move_id)
		var light:=Color(str(style[1]));var dark:=Color(str(style[2]))
		var peak:float=clampf(float(p.impact),.01,.99)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"tiles":[field.pos(target)],"results":{target:{"damage":8,"hits":2}}}
		var n:int=0
		for particle in field.combat_particles:particle.hide()
		match group:
			"PROJECTILE":
				assert(not field.projectile_contact_art(move_id).is_empty())
				n=field.projectile_contact_fx(burst,peak*.55,0,light,dark)
			"TERRAIN":
				assert(not field.terrain_contact_art(move_id).is_empty())
				n=field.terrain_contact_fx(burst,peak*.55,0,light,dark)
			"BODY":
				n=field.body_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"SPECIAL":
				n=field.special_contact_fx(burst,peak*.55,0,light,dark)
			"BITE":
				n=field.bite_contact_fx(move_id,bite_position,.20,0,light,dark)
			"MOTION":
				n=field.motion_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
		assert(n>0 and n<=12,"missing elemental presentation "+move_id)
		assert(field.combat_particles.size()==particle_count)
		assert(field.combat_particles[0].texture.get_image().get_used_rect().size.x>0)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v12-element-"+move_id+".png")==OK)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_ELEMENTAL_AUDIT_PASS 40")
	# V12.3: all remaining grass, poison, bug, ground and rock records.
	var nature_cases:Dictionary={"alt_anemoneye":"TERRAIN","alt_astro_golem":"TERRAIN","alt_fungal_monarch":"PROJECTILE","alt_grovetitan":"BODY","alt_hollow_stag":"PROJECTILE","alt_leafwisp":"PROJECTILE","alt_mossmite":"TERRAIN","alt_rootgnawer":"PROJECTILE","alt_shellguard":"BODY","alt_sporeling":"BODY","alt_thornbeetle":"BITE","alt_vinesnap":"BITE","alt_voidspider":"PROJECTILE","antler_arc":"BODY","briar_arc":"BODY","double_pincer":"MOTION","eos_093":"PROJECTILE","eos_105":"PROJECTILE","eos_143":"TERRAIN","eos_147":"TERRAIN","eos_200":"PROJECTILE","eos_212":"TERRAIN","eos_221":"MOTION","eos_238":"TERRAIN","eos_253":"TERRAIN","eos_285":"PROJECTILE","eos_289":"MOTION","eos_290":"PROJECTILE","eos_295":"TERRAIN","eos_297":"PROJECTILE","eos_332":"PROJECTILE","eos_336":"CLAW","eos_438":"SUPPORT","eos_441":"BODY","eos_453":"PROJECTILE","eos_458":"SPECIAL","eos_459":"MOTION","eos_470":"MOTION","eos_480":"TERRAIN","eos_495":"MOTION","eos_496":"TERRAIN","eos_512":"PROJECTILE","eos_537":"PROJECTILE","horn_ram":"BODY","leaf_dart":"PROJECTILE","lib_bug_1":"SPECIAL","lib_bug_3":"SPECIAL","lib_grass_2":"PROJECTILE","lib_grass_3":"TERRAIN","lib_ground_2":"BODY","lib_ground_3":"PROJECTILE","lib_poison_1":"PROJECTILE","lib_poison_2":"PROJECTILE","lib_poison_3":"TERRAIN","lib_rock_2":"BODY","meteor_fist":"PUNCH","rolling_moss":"BODY","royal_spores":"TERRAIN","shell_impact":"BODY","spore_cloud":"TERRAIN","timber_shock":"TERRAIN","tusk_sweep":"BODY"}
	for move_id in nature_cases:
		var group:String=nature_cases[move_id]
		var p:Dictionary=field.combat_profile(move_id)
		var style:Array=field.combat_style(move_id)
		var light:=Color(str(style[1]));var dark:=Color(str(style[2]))
		var peak:float=clampf(float(p.impact),.01,.99)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"tiles":[field.pos(target)],"results":{target:{"damage":8,"hits":2,"effects":1}}}
		var n:int=0
		for particle in field.combat_particles:particle.hide()
		match group:
			"PROJECTILE":n=field.projectile_contact_fx(burst,peak*.55,0,light,dark)
			"TERRAIN":n=field.terrain_contact_fx(burst,peak*.55,0,light,dark)
			"BODY":n=field.body_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"SPECIAL":
				var tick:float=lerpf(peak,1.0,.25) if move_id=="eos_458" else peak*.55
				n=field.special_contact_fx(burst,tick,0,light,dark)
			"BITE":n=field.bite_contact_fx(move_id,bite_position,.20,0,light,dark)
			"MOTION":n=field.motion_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"CLAW":n=field.claw_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"PUNCH":n=field.punch_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"SUPPORT":n=field.support_contact_fx(burst,lerpf(peak,1.0,.25),0)
		assert(n>0 and n<=12,"missing nature presentation "+move_id)
		assert(field.combat_particles.size()==particle_count)
		assert(field.combat_particles[0].texture.get_image().get_used_rect().size.x>0)
		if move_id in ["eos_290","eos_295","eos_480","eos_496","eos_238","eos_495","eos_470","eos_336","eos_289","eos_453","eos_253","royal_spores"]:
			await frames()
			assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v12-nature-"+move_id+".png")==OK)
	var return_profile:Dictionary=field.combat_profile("eos_290")
	var returning:Dictionary={"id":"eos_290","profile":return_profile,"points":[special_source,bite_position],"results":{}}
	var return_peak:float=clampf(float(return_profile.impact),.01,.99)
	assert(field.projectile_contact_fx(returning,lerpf(return_peak,1.0,.25),0,Color.WHITE,Color.BLACK)==1)
	var return_start:float=field.combat_particles[0].position.distance_to(special_source)
	assert(field.projectile_contact_fx(returning,lerpf(return_peak,1.0,.8),0,Color.WHITE,Color.BLACK)==1)
	assert(field.combat_particles[0].position.distance_to(special_source)<return_start)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_NATURE_AUDIT_PASS 62")
	# V12.4: remaining spectral, dark, dragon, fairy and psychic profiles.
	var mystic_cases:Dictionary={"alt_abyss_colossus":"TERRAIN","alt_celestial_guardian":"PROJECTILE","alt_lunar_prowler":"MOTION","alt_orbitserpent":"BITE","alt_starlit_pup":"PROJECTILE","celestial_verdict":"TERRAIN","comet_drop":"TERRAIN","eos_005":"SUPPORT","eos_035":"SUPPORT","eos_038":"MOTION","eos_043":"SUPPORT","eos_045":"SUPPORT","eos_046":"MOTION","eos_049":"SUPPORT","eos_091":"BODY","eos_109":"PROJECTILE","eos_110":"PROJECTILE","eos_133":"PROJECTILE","eos_167":"MOTION","eos_214":"MOTION","eos_216":"TERRAIN","eos_220":"SUPPORT","eos_234":"PROJECTILE","eos_249":"MOTION","eos_269":"SUPPORT","eos_316":"SUPPORT","eos_317":"SUPPORT","eos_331":"SPECIAL","eos_334":"SUPPORT","eos_335":"PROJECTILE","eos_342":"PROJECTILE","eos_445":"MOTION","eos_472":"MOTION","eos_488":"MOTION","eos_503":"SUPPORT","eos_514":"SUPPORT","eos_528":"SUPPORT","lib_dark_2":"TERRAIN","lib_dragon_2":"PROJECTILE","lib_fairy_2":"TERRAIN","lib_fairy_3":"PROJECTILE","lib_ghost_2":"SPECIAL","lib_ghost_3":"TERRAIN","lib_psychic_1":"PROJECTILE","lib_psychic_3":"TERRAIN","lunar_dust":"TERRAIN","moon_claw":"CLAW","orbit_lash":"SPECIAL","sonic_cone":"SPECIAL","star_kick":"KICK"}
	for move_id in mystic_cases:
		var group:String=mystic_cases[move_id]
		var p:Dictionary=field.combat_profile(move_id)
		var style:Array=field.combat_style(move_id)
		var light:=Color(str(style[1]));var dark:=Color(str(style[2]))
		var peak:float=clampf(float(p.impact),.01,.99)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"tiles":[field.pos(target)],"results":{target:{"damage":8,"hits":2,"effects":1}}}
		var n:int=0
		for particle in field.combat_particles:particle.hide()
		match group:
			"PROJECTILE":n=field.projectile_contact_fx(burst,peak*.55,0,light,dark)
			"TERRAIN":n=field.terrain_contact_fx(burst,peak*.55,0,light,dark)
			"BODY":n=field.body_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"SPECIAL":
				var tick:float=lerpf(peak,1.0,.25) if move_id=="eos_331" else peak*.55
				n=field.special_contact_fx(burst,tick,0,light,dark)
			"BITE":n=field.bite_contact_fx(move_id,bite_position,.20,0,light,dark)
			"MOTION":n=field.motion_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"CLAW":n=field.claw_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"KICK":n=field.kick_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"SUPPORT":n=field.support_contact_fx(burst,lerpf(peak,1.0,.25),0)
		assert(n>0 and n<=12,"missing mystic presentation "+move_id)
		assert(field.combat_particles.size()==particle_count)
		assert(field.combat_particles[0].texture.get_image().get_used_rect().size.x>0)
		if move_id in ["eos_109","eos_331","eos_342","eos_005","eos_317","eos_528","eos_167","star_kick","moon_claw","celestial_verdict","alt_celestial_guardian","lib_fairy_3"]:
			await frames()
			assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v12-mystic-"+move_id+".png")==OK)
	for mode in ["projectile_crescent","projectile_comet","projectile_eye","projectile_prism"]:
		var tex:Texture2D=field.combat_pixel_texture(mode,Color.WHITE,Color.BLACK)
		assert(tex.get_width()==32 and tex.get_image().get_used_rect().size.x>0)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_MYSTIC_AUDIT_PASS 50")
	# V12.5: every final normal, fighting, steel and flying record.
	var final_cases:Dictionary={"alt_bramble_pup":"CLAW","alt_comet_hare":"KICK","alt_nebulwing":"TERRAIN","basic_strike":"MOTION","eos_007":"SPECIAL","eos_024":"SUPPORT","eos_029":"TERRAIN","eos_037":"SUPPORT","eos_040":"SUPPORT","eos_048":"MOTION","eos_050":"MOTION","eos_051":"SPECIAL","eos_054":"SUPPORT","eos_061":"SPECIAL","eos_066":"MOTION","eos_067":"MOTION","eos_077":"MOTION","eos_078":"MOTION","eos_096":"MOTION","eos_098":"SUPPORT","eos_102":"SUPPORT","eos_115":"SUPPORT","eos_119":"SUPPORT","eos_138":"SUPPORT","eos_168":"PROJECTILE","eos_185":"SUPPORT","eos_207":"PROJECTILE","eos_227":"SUPPORT","eos_228":"PROJECTILE","eos_229":"SUPPORT","eos_237":"SUPPORT","eos_245":"PROJECTILE","eos_247":"MOTION","eos_248":"SPECIAL","eos_252":"SUPPORT","eos_254":"SPECIAL","eos_256":"SUPPORT","eos_263":"SUPPORT","eos_268":"SPECIAL","eos_277":"PROJECTILE","eos_287":"MOTION","eos_314":"CLAW","eos_315":"SUPPORT","eos_324":"PROJECTILE","eos_326":"SUPPORT","eos_327":"SUPPORT","eos_328":"MOTION","eos_330":"SUPPORT","eos_337":"SUPPORT","eos_340":"SPECIAL","eos_349":"SUPPORT","eos_352":"MOTION","eos_353":"PROJECTILE","eos_442":"PROJECTILE","eos_447":"SUPPORT","eos_457":"PROJECTILE","eos_465":"SUPPORT","eos_471":"SUPPORT","eos_474":"SPECIAL","eos_475":"PROJECTILE","eos_479":"PROJECTILE","eos_497":"MOTION","eos_505":"SPECIAL","eos_516":"MOTION","eos_525":"SUPPORT","eos_532":"SPECIAL","eos_541":"MOTION","feather_fan":"PROJECTILE","fin_slice":"MOTION","lib_flying_2":"PROJECTILE","lib_flying_3":"TERRAIN","lib_steel_1":"CLAW","lib_steel_2":"PROJECTILE","lib_steel_3":"PROJECTILE"}
	for move_id in final_cases:
		var group:String=final_cases[move_id]
		var p:Dictionary=field.combat_profile(move_id)
		var style:Array=field.combat_style(move_id)
		var light:=Color(str(style[1]));var dark:=Color(str(style[2]))
		var peak:float=clampf(float(p.impact),.01,.99)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"tiles":[field.pos(target)],"results":{target:{"damage":8,"hits":2,"effects":1}}}
		var n:int=0
		for particle in field.combat_particles:particle.hide()
		match group:
			"PROJECTILE":n=field.projectile_contact_fx(burst,peak*.55,0,light,dark)
			"TERRAIN":n=field.terrain_contact_fx(burst,peak*.55,0,light,dark)
			"SPECIAL":
				var tick:float=lerpf(peak,1.0,.25) if move_id in ["eos_248","eos_474","eos_505"] else peak*.55
				n=field.special_contact_fx(burst,tick,0,light,dark)
			"MOTION":n=field.motion_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"CLAW":n=field.claw_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"KICK":n=field.kick_contact_fx(move_id,special_source,bite_position,.25,0,light,dark,2)
			"SUPPORT":n=field.support_contact_fx(burst,lerpf(peak,1.0,.25),0)
		assert(n>0 and n<=12,"missing final presentation "+move_id)
		assert(field.combat_particles.size()==particle_count)
		assert(field.combat_particles[0].texture.get_image().get_used_rect().size.x>0)
		if move_id in ["eos_207","eos_228","eos_277","eos_457","eos_254","eos_051","eos_532","eos_326","eos_353","eos_442","lib_steel_2","alt_comet_hare"]:
			await frames()
			assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v12-final-"+move_id+".png")==OK)
	for mode in ["projectile_coin","projectile_parcel","projectile_card","projectile_feather","support_heart"]:
		var tex:Texture2D=field.combat_pixel_texture(mode,Color.WHITE,Color.BLACK)
		assert(tex.get_width()==32 and tex.get_image().get_used_rect().size.x>0)
	var all_profiles:Dictionary={}
	for group in [Field.BITE_CONTACT_ART,Field.PUNCH_CONTACT_ART,Field.KICK_CONTACT_ART,Field.CLAW_CONTACT_ART,Field.BODY_CONTACT_ART,Field.SPECIAL_CONTACT_ART,Field.PROJECTILE_CONTACT_ART,Field.TERRAIN_CONTACT_ART,Field.SUPPORT_CONTACT_ART,Field.MOTION_CONTACT_ART]:
		for move_id in group:all_profiles[move_id]=true
	var catalog:Dictionary=Field.Rules.DEV_NATIVE_MOVES.duplicate()
	catalog.merge(Field.Rules.MOVE_LIBRARY,true)
	for move_id in catalog:
		assert(all_profiles.has(move_id),"uncovered catalog ID "+move_id)
	for move_id in all_profiles:
		assert(catalog.has(move_id),"orphan visual profile "+move_id)
	assert(catalog.size()==589 and all_profiles.size()==589)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_FINAL_AUDIT_PASS 74")
	print("KINDRIA_FULL_COVERAGE_PASS 589")
	# V13: validate all element materials and every actual catalog profile.
	var v13_elements:Dictionary={}
	var v13_authored:Dictionary={}
	var v13_styles:Dictionary={}
	for move_id in catalog:
		var record:Dictionary=catalog[move_id]
		var profile:Dictionary=field.combat_profile(move_id)
		assert(str(profile.element)==str(record.type),"incorrect element "+move_id)
		assert(str(profile.pattern)==str(record.pattern),"incorrect pattern "+move_id)
		var material:Array=field.move_finish_art(move_id,profile)
		assert(material.size()==5,"missing finish "+move_id)
		assert(float(material[3])>0.0 and float(material[4])>0.0)
		var style:Array=field.combat_style(move_id)
		var light:=Color(str(style[1]));var dark:=Color(str(style[2]))
		for texture_mode in [material[0],material[1]]:
			var tex:Texture2D=field.combat_pixel_texture(str(texture_mode),Color(str(material[2])),dark)
			assert(tex.get_image().get_used_rect().size.x>0,"empty material "+move_id+" "+str(texture_mode))
		var tracks:Array=field.elemental_track_plan(move_id,profile)
		assert(tracks[5].material==material[0])
		var peak:float=clampf(float(profile.impact),.01,.99)
		var outcome:Dictionary={"effects":1} if record.category=="status" else {"damage":8,"hits":2}
		var burst:Dictionary={"id":move_id,"profile":profile,"points":[special_source,bite_position],"tiles":[field.pos(target)],"results":{target:outcome}}
		for sample in [peak*.35,peak,lerpf(peak,1.0,.30),.98]:
			var used:int=field.element_finish_fx(burst,float(sample),0)
			assert(used>=0 and used<=Field.FX_PARTICLE_CAP,"pool overflow "+move_id)
		assert(field.combat_particles.size()==particle_count)
		v13_elements[str(record.type)]=true
		if Field.V13_FINISH_ART.has(move_id):v13_authored[move_id]=true
		elif Field.V13_FINISH_ART.has(str(profile.role)):v13_authored[str(profile.role)]=true
		v13_styles[move_id]=style
	assert(v13_elements.size()==18 and v13_authored.size()==147)
	for element in Field.ELEMENT_MATERIAL_ART:
		var material:Array=Field.ELEMENT_MATERIAL_ART[element]
		var fake_profile:Dictionary={"element":element,"role":"v13_reference","pattern":"front"}
		assert(field.move_finish_art("v13_reference",fake_profile)==material)
		for particle in field.combat_particles:particle.hide()
		var used:int=field.cinematic_impact_layers("v13_reference",fake_profile,special_source,bite_position,.30,0,Color.WHITE,Color.BLACK,false)
		assert(used==6)
		assert(field.combat_particles[1].texture==field.combat_pixel_texture(str(material[0]),Color(str(material[2])),Color.BLACK))
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v13-material-"+element+".png")==OK)
	var secondary_tile:Vector2i=target+Vector2i.DOWN
	var outcome:Dictionary={target:{"misses":1},secondary_tile:{"damage":8,"hits":1}}
	assert(field.secondary_material_target(outcome,target)==field.pos(secondary_tile)+Vector3.UP*.55)
	assert(field.secondary_material_target({target:{"misses":1}},target)==null)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V13_ALL_ELEMENTS_PASS 18")
	print("KINDRIA_V13_AUTHORED_FINISH_PASS 147")
	print("KINDRIA_V13_FULL_COMPOSITOR_PASS 589")
	# V13.2: concurrent cast contact reservation must run ahead of filler.
	var saved_bursts:Array[Dictionary]=field.combat_bursts.duplicate()
	field.combat_bursts.clear()
	for move_id in ["eos_063","eos_062","eos_292","eos_344","eos_065","eos_276","eos_476","eos_208","eos_433","eos_354"]:
		var p:Dictionary=field.combat_profile(move_id)
		var age_at_hit:float=lerpf(float(p.impact),1.0,.15)
		field.combat_bursts.append({"id":move_id,"profile":p,"points":[special_source,bite_position],"age":age_at_hit,"duration":1.0,"results":{target:{"damage":8,"hits":1}}})
	var reserved:int=field.reserve_confirmed_contacts(0.0,0)
	assert(reserved>=12 and reserved<72)
	var before_filler:Texture2D=field.combat_particles[0].texture
	for j in range(reserved,Field.FX_PARTICLE_CAP):
		field.environment_particle(j,bite_position,"cloud",Color.WHITE,Color.BLACK,.5,.5)
	assert(field.combat_particles[0].texture==before_filler)
	assert(field.reserve_confirmed_contacts(0.0,Field.FX_PARTICLE_CAP)==Field.FX_PARTICLE_CAP)
	for burst in field.combat_bursts:burst.results={target:{"misses":1}}
	assert(field.reserve_confirmed_contacts(0.0,0)==0)
	field.combat_bursts.assign(saved_bursts)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V13_CONTACT_PRIORITY_PASS 10")
	# V13.3: no confirmed victim means no contact or elemental impact.
	var mixed_profile:Dictionary=field.combat_profile("eos_063")
	var mixed_burst:Dictionary={"id":"eos_063","profile":mixed_profile,"points":[special_source,bite_position],"tiles":[field.pos(target)],"results":{}}
	var mixed_tick:float=lerpf(float(mixed_profile.impact),1.0,.2)
	assert(field.element_finish_fx(mixed_burst,mixed_tick,0)==1)
	assert(field.priority_contact_fx(mixed_burst,mixed_tick,0)==0)
	mixed_burst.results={target:{"misses":1},secondary_tile:{"damage":8,"hits":1}}
	assert(field.priority_contact_fx(mixed_burst,mixed_tick,0)==0)
	assert(field.priority_contact_fx(mixed_burst,mixed_tick,0,true)>=2)
	assert(field.element_finish_fx(mixed_burst,mixed_tick,0)>8)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V13_CONFIRMED_MATERIAL_PASS")
	# V13.4: persistent elemental residues must follow actual damage cells.
	var saved_residues:Array[Dictionary]=field.fx_residues.duplicate()
	field.fx_residues.clear()
	var residue_profile:Dictionary=field.combat_profile("lib_fire_1")
	var residue_burst:Dictionary={"id":"lib_fire_1","profile":residue_profile,"points":[special_source,bite_position],"damage":99,"results":{target:{"misses":1}}}
	field.ultra_impact_residue(residue_burst)
	assert(field.fx_residues.is_empty())
	var residue_far:Vector2i=target+Vector2i(3,0)
	var residue_tie:Vector2i=target+Vector2i.LEFT
	residue_burst.results={residue_far:{"damage":4},secondary_tile:{"damage":8},target:{"blocked":1},residue_tie:{"damage":3}}
	field.ultra_impact_residue(residue_burst)
	assert(field.fx_residues.size()==3)
	assert(field.fx_residues[0].at==Vector3(field.pos(residue_tie).x,.065,field.pos(residue_tie).z))
	assert(field.fx_residues[1].at==Vector3(field.pos(secondary_tile).x,.065,field.pos(secondary_tile).z))
	assert(field.fx_residues[2].at==Vector3(field.pos(residue_far).x,.065,field.pos(residue_far).z))
	field.fx_residues.clear()
	residue_burst.results={target:{"effects":1},secondary_tile:{"heal":5}}
	field.ultra_impact_residue(residue_burst)
	assert(field.fx_residues.is_empty())
	residue_burst.results={}
	field.ultra_impact_residue(residue_burst)
	assert(field.fx_residues.is_empty())
	residue_burst.results={target:{"damage":7},secondary_tile:{"damage":8},residue_tie:{"damage":3},residue_far:{"damage":4},target+Vector2i(4,0):{"damage":9}}
	field.ultra_impact_residue(residue_burst)
	assert(field.fx_residues.size()==4)
	for j in range(Field.FX_RESIDUE_CAP+2):field.ultra_impact_residue(residue_burst)
	assert(field.fx_residues.size()==Field.FX_RESIDUE_CAP)
	field.fx_residues.assign(saved_residues)
	print("KINDRIA_V13_RESIDUE_DAMAGE_CELLS_PASS")
	# V13.5: all catalog IDs preserve launch but reject empty or missed legacy impacts.
	for move_id in catalog:
		var p:Dictionary=field.combat_profile(move_id)
		var peak:float=float(p.impact)
		var sample:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"tiles":[field.pos(target)],"results":{}}
		assert(field.legacy_stage_visible(sample,peak*.5),move_id)
		assert(not field.legacy_stage_visible(sample,peak),move_id)
		assert(field.confirmed_stage_target(sample)==null,move_id)
		sample.results={target:{"misses":1},secondary_tile:{"damage":8}}
		assert(not field.legacy_stage_visible(sample,peak),move_id)
		assert(field.confirmed_stage_target(sample)==field.pos(secondary_tile)+Vector3.UP*.55,move_id)
		sample.results={target:{"damage":8}}
		assert(field.legacy_stage_visible(sample,peak),move_id)
		assert(field.confirmed_stage_target(sample)==bite_position,move_id)
	var drain_profile:Dictionary=field.combat_profile("eos_076")
	var drain_burst:Dictionary={"id":"eos_076","profile":drain_profile,"points":[special_source,bite_position],"results":{target:{"misses":1},origin:{"heal":4}}}
	assert(field.confirmed_stage_target(drain_burst,true)==null)
	drain_burst.results={target:{"blocked":1},secondary_tile:{"damage":8},origin:{"heal":4}}
	assert(field.confirmed_stage_target(drain_burst,true)==field.pos(secondary_tile)+Vector3.UP*.55)
	print("KINDRIA_V13_LEGACY_STAGE_PASS 589")
	# V14.1: unique authored motion fingerprints, not merely color changes.
	var motion_fingerprints:Dictionary={}
	for role in Field.V14_ATTACK_DIRECTION:
		var design:Array=Field.V14_ATTACK_DIRECTION[role]
		var fingerprint:Array=[]
		for moment in [.18,.48,.76]:
			for index in range(6):
				var q:Vector3=field.attack_direction_sample(design,float(moment),index,6,Vector3.FORWARD,Vector3.RIGHT)
				assert(q.is_finite() and q.length()<4.0,role)
				fingerprint.append(q.snapped(Vector3.ONE*.001))
		var key:String=str(fingerprint)
		assert(not motion_fingerprints.has(key),"duplicate geometry "+role)
		motion_fingerprints[key]=role
	assert(motion_fingerprints.size()==589)
	for move_id in catalog:
		var intensity:float=field.attack_visual_intensity(move_id)
		assert(intensity>=.66 and intensity<=1.34,move_id)
	assert(field.attack_visual_intensity("eos_188")<field.attack_visual_intensity("eos_064"))
	assert(field.attack_visual_intensity("eos_308")<field.attack_visual_intensity("eos_240"))
	assert(field.attack_visual_intensity("eos_262")<field.attack_visual_intensity("eos_157"))
	print("KINDRIA_V14_DIRECTION_PASS 589")
	# Every actual catalog ID must resolve to its own authored direction.
	var resolved_profiles:Dictionary={}
	for move_id in catalog:
		var p:Dictionary=field.combat_profile(move_id)
		var design:Array=field.attack_direction_profile(move_id,p)
		assert(not design.is_empty(),"generic attack "+move_id)
		var key:String=str(design)
		assert(not resolved_profiles.has(key),"shared direction "+move_id)
		resolved_profiles[key]=move_id
	assert(resolved_profiles.size()==589)
	print("KINDRIA_V14_NO_GENERIC_DIRECTION_PASS 589")
	# Capture paired actual material finishes, not concept art, for visual review.
	var review_moves:Dictionary={"eos_135":"grass","eos_076":"grass","eos_462":"ice","eos_270":"ice","eos_008":"ground","eos_118":"ground","eos_028":"rock","eos_453":"rock","eos_200":"poison","eos_280":"poison"}
	for move_id in review_moves:
		assert(catalog.has(move_id),move_id)
		var profile:Dictionary=field.combat_profile(move_id)
		assert(str(profile.element)==str(review_moves[move_id]),move_id)
		assert(Field.V14_ATTACK_DIRECTION.has(str(profile.role)),move_id)
		for particle in field.combat_particles:particle.hide()
		var style:Array=field.combat_style(move_id)
		var used:int=field.cinematic_impact_layers(move_id,profile,special_source,bite_position,.32,0,Color(str(style[1])),Color(str(style[2])),catalog[move_id].category=="status")
		assert(used>0 and used<=Field.FX_PARTICLE_CAP,move_id)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v14-finish-"+move_id+".png")==OK)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V14_NATURE_MATERIAL_PASS 88")
	# Paired direct-contact and supernatural attacks: capture three distinct
	# points through the finish while preserving their existing contact emblems.
	var v14_combat_pairs:Dictionary={"eos_092":"fight_lowkick","eos_206":"fight_highkick","eos_036":"air_cutter","eos_353":"air_blast","eos_108":"psi_wave","eos_109":"psi_psychic","eos_126":"ghost_punch","eos_476":"ghost_claw","eos_063":"dark_bite","eos_062":"dark_crunch"}
	for move_id in v14_combat_pairs:
		assert(catalog.has(move_id),move_id)
		var p:Dictionary=field.combat_profile(move_id)
		assert(str(p.role)==str(v14_combat_pairs[move_id]),move_id)
		assert(Field.V14_ATTACK_DIRECTION.has(str(p.role)),move_id)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"tiles":[field.pos(target)],"results":{target:{"damage":8,"hits":1}}}
		for moment in [.12,.34,.58]:
			for particle in field.combat_particles:particle.hide()
			var phase:float=lerpf(float(p.impact),1.0,float(moment))
			var used:int=field.element_finish_fx(burst,phase,0)
			assert(used>0 and used<=Field.FX_PARTICLE_CAP,move_id)
			await frames()
			assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v14-contact-"+move_id+"-"+str(roundi(float(moment)*100.0))+".png")==OK)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V14_COMBAT_MOTION_PASS 130")
	var v14_final_pairs:Dictionary={"eos_114":"bug","eos_530":"bug","eos_342":"dragon","eos_538":"dragon","eos_510":"steel","eos_536":"steel","lib_fairy_1":"fairy","lib_fairy_3":"fairy","eos_154":"normal","eos_455":"normal","eos_301":"normal","eos_034":"normal"}
	for move_id in v14_final_pairs:
		assert(catalog.has(move_id),move_id)
		var p:Dictionary=field.combat_profile(move_id)
		assert(str(p.element)==str(v14_final_pairs[move_id]),move_id)
		assert(Field.V14_ATTACK_DIRECTION.has(move_id) or Field.V14_ATTACK_DIRECTION.has(str(p.role)),move_id)
		var style:Array=field.combat_style(move_id)
		for particle in field.combat_particles:particle.hide()
		var used:int=field.cinematic_impact_layers(move_id,p,special_source,bite_position,.35,0,Color(str(style[1])),Color(str(style[2])),catalog[move_id].category=="status")
		assert(used>0 and used<=Field.FX_PARTICLE_CAP,move_id)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v14-final-"+move_id+".png")==OK)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V14_FINAL_NATURE_PASS 205")
	# V15 screenshot-grounded geometry: source rings and blue moving projectile.
	for move_id in ["eos_530","eos_114"]:
		var observed_profile:Dictionary=field.combat_profile(move_id)
		var observed_peak:float=float(observed_profile.impact)
		var observed_burst:Dictionary={"id":move_id,"profile":observed_profile,"points":[special_source,bite_position],"results":{target:{"damage":8}}}
		for particle in field.combat_particles:particle.hide()
		var observed_count:int=field.rtdx_observed_stage_fx(observed_burst,observed_peak*.55,0)
		assert(observed_count==5 if move_id=="eos_530" else observed_count==13)
		if move_id=="eos_530":
			for i in range(3):
				assert(field.combat_particles[i].position.is_equal_approx(special_source))
		else:
			assert(field.combat_particles[12].position.is_equal_approx(special_source.lerp(bite_position,.55)))
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v15-observed-"+move_id+".png")==OK)
		observed_burst.results={target:{"misses":1}}
		var miss_count:int=field.rtdx_observed_stage_fx(observed_burst,observed_peak+.02,0)
		assert(miss_count==5 if move_id=="eos_530" else miss_count==0)
		assert(field.rtdx_observed_stage_fx(observed_burst,observed_peak*.55,Field.FX_PARTICLE_CAP)==Field.FX_PARTICLE_CAP)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V15_OBSERVED_GEOMETRY_PASS 2")
	# V15.1: the original procedural stamp is nonempty and uses soft alpha.
	for mode in ["rtdx_flame","rtdx_bluefire","rtdx_scratch","rtdx_peck","rtdx_glint"]:
		var im:Image=field.rtdx_material_stamp(mode,Color.WHITE,Color.BLUE)
		assert(im.get_size()==Vector2i(64,64) and im.get_used_rect().size.x>0,mode)
	for move_id in ["eos_262","eos_149","eos_260","eos_174"]:
		var p:Dictionary=field.combat_profile(move_id)
		var peak:float=float(p.impact)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"tiles":[field.pos(target)],"results":{target:{"damage":8}}}
		var phase:float=peak*.65 if move_id in ["eos_262","eos_149"] else lerpf(peak,1.0,.22)
		for particle in field.combat_particles:particle.hide()
		var n:int=field.rtdx_observed_stage_fx(burst,phase,0)
		assert(n>0 and n<=Field.FX_PARTICLE_CAP,move_id)
		assert(field.combat_particles[0].texture.get_width()==64,move_id)
		assert(field.combat_particles[0].texture_filter==BaseMaterial3D.TEXTURE_FILTER_LINEAR,move_id)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v15-observed-"+move_id+".png")==OK)
		burst.results={target:{"misses":1}}
		if move_id in ["eos_260","eos_174"]:
			assert(field.rtdx_observed_stage_fx(burst,phase,0)==0,move_id)
		assert(field.rtdx_observed_stage_fx(burst,phase,Field.FX_PARTICLE_CAP)==Field.FX_PARTICLE_CAP,move_id)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V15_CONTACT_FIRE_PASS 4")
	# V15.2: source-based charge/release, contact shapes and existing tile rush.
	for move_id in ["eos_036","eos_092","eos_109","eos_108","eos_151"]:
		var p:Dictionary=field.combat_profile(move_id)
		var peak:float=float(p.impact)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"tiles":[field.pos(target)],"results":{target:{"damage":8}}}
		var phase:float=peak*.72 if move_id=="eos_151" else lerpf(peak,1.0,.22)
		for particle in field.combat_particles:particle.hide()
		var n:int=field.rtdx_observed_stage_fx(burst,phase,0)
		assert(n>0 and n<=Field.FX_PARTICLE_CAP,move_id)
		assert(field.combat_particles[0].texture.get_width()==64,move_id)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v15-observed-"+move_id+".png")==OK)
		burst.results={target:{"misses":1}}
		assert(field.rtdx_observed_stage_fx(burst,lerpf(peak,1.0,.22),0)==0,move_id)
		assert(field.rtdx_observed_stage_fx(burst,phase,Field.FX_PARTICLE_CAP)==Field.FX_PARTICLE_CAP,move_id)
	for particle in field.combat_particles:particle.hide()
	assert(field.rtdx_solar_charge_fx(special_source,1.25,0)==7)
	await frames()
	assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v15-solar-charge.png")==OK)
	for particle in field.combat_particles:particle.hide()
	assert(field.tile_cast_kind("eos_190")=="ground")
	var rush:Array=[special_source,bite_position]
	assert(field.tile_cast_sample(rush,"ground",0.0,.64).position.is_equal_approx(special_source))
	assert(field.tile_cast_sample(rush,"ground",.64,.64).position.is_equal_approx(bite_position))
	assert(field.tile_cast_sample(rush,"ground",1.0,.64).position.is_equal_approx(special_source))
	print("KINDRIA_V15_PSYCHIC_SOLAR_CONTACT_PASS 5")
	print("KINDRIA_V15_QUICK_ROUTE_PASS")
	# Sand Attack must show environmental dust independently of the accuracy
	# reduction glyph; only an actual effect result can emit the latter.
	var sand_profile:Dictionary=field.combat_profile("eos_142")
	var sand_peak:float=float(sand_profile.impact)
	var sand_burst:Dictionary={"id":"eos_142","profile":sand_profile,"points":[special_source,bite_position],"results":{target:{"effects":1}}}
	var sand_phase:float=lerpf(sand_peak,1.0,.22)
	assert(field.rtdx_observed_stage_fx(sand_burst,sand_peak*.65,0)==5)
	assert(field.rtdx_observed_stage_fx(sand_burst,sand_phase,0)==6)
	assert(field.combat_particles[0].texture.get_width()==64)
	assert(field.combat_particles[5].texture.get_width()==32)
	await frames()
	assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/v15-observed-eos_142.png")==OK)
	sand_burst.results={target:{"misses":1}}
	assert(field.rtdx_observed_stage_fx(sand_burst,sand_phase,0)==5)
	sand_burst.results={target:{"damage":8}}
	assert(field.rtdx_observed_stage_fx(sand_burst,sand_phase,0)==5)
	assert(field.rtdx_observed_stage_fx(sand_burst,sand_phase,Field.FX_PARTICLE_CAP)==Field.FX_PARTICLE_CAP)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V15_SAND_STATUS_PASS")
	# V15.4: preserve the source-centered rings while displaying each
	# confirmed victim independently; a missed primary has no damage star.
	var buzz_profile:Dictionary=field.combat_profile("eos_530")
	var buzz_peak:float=float(buzz_profile.impact)
	var buzz_burst:Dictionary={"id":"eos_530","profile":buzz_profile,"points":[special_source,bite_position],"results":{target:{"misses":1},secondary_tile:{"damage":8},origin:{"damage":4}}}
	var buzz_phase:float=lerpf(buzz_peak,1.0,.2)
	assert(field.rtdx_observed_stage_fx(buzz_burst,buzz_phase,0)==7)
	var hit_positions:Array=[field.combat_particles[5].position,field.combat_particles[6].position]
	assert(hit_positions.has(field.pos(secondary_tile)+Vector3.UP*.55))
	assert(hit_positions.has(field.pos(origin)+Vector3.UP*.55))
	assert(not hit_positions.has(bite_position))
	assert(field.rtdx_observed_stage_fx(buzz_burst,buzz_phase,Field.FX_PARTICLE_CAP)==Field.FX_PARTICLE_CAP)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V15_MULTI_TARGET_PASS")
	# V15.5: one ordering and confirmation contract, including contact
	# and solar effects. No false marks for healing, status or missed cells.
	for move_id in ["eos_260","eos_174","eos_151"]:
		var p:Dictionary=field.combat_profile(move_id)
		var peak:float=float(p.impact)
		var burst:Dictionary={"id":move_id,"profile":p,"points":[special_source,bite_position],"results":{secondary_tile:{"damage":8},target:{"misses":1},origin:{"damage":4}}}
		var cells:Array[Vector2i]=field.rtdx_confirmed_cells(burst)
		assert(cells.size()==2 and not cells.has(target),move_id)
		var phase:float=lerpf(peak,1.0,.20)
		for particle in field.combat_particles:particle.hide()
		var used:int=field.rtdx_observed_stage_fx(burst,phase,0)
		assert(used==8 if move_id=="eos_260" else used==2,move_id)
		burst.results={origin:{"damage":4},target:{"misses":1},secondary_tile:{"damage":8}}
		assert(field.rtdx_confirmed_cells(burst)==cells,move_id)
		burst.results={target:{"heal":4},secondary_tile:{"effects":1}}
		assert(field.rtdx_observed_stage_fx(burst,phase,0)==0,move_id)
		assert(field.rtdx_confirmed_cells(burst,true)==[secondary_tile],move_id)
	for particle in field.combat_particles:particle.hide()
	print("KINDRIA_V15_CONTACT_TARGET_CONTRACT_PASS 3")
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
