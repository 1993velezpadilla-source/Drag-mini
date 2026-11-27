extends SceneTree
# CPU submission benchmark uses the actual combat world, not synthetic math.
# Optional rendered mode measures software/desktop frame intervals separately.
const Dungeon=preload("res://dungeon_view.gd")
const DT:float=1.0/60.0
var view:Dungeon
var scene:Node3D
var failures:Array[String]=[]
var peak_atlases:int=0
var peak_secondary:int=0
var peak_particles:int=0
var peak_lights:int=0
var peak_trail:int=0
var peak_static_bytes:int=0
var peak_video_bytes:int=0

func _initialize()->void:
	call_deferred("benchmark")

func stats(values:Array[int])->Dictionary:
	if values.is_empty():return {}
	values.sort()
	var result:Dictionary={"samples":values.size(),"max_usec":values[-1],"over_16_667_usec":0}
	for p in [50,95,99]:
		result["p"+str(p)+"_usec"]=values[clampi(ceili(float(values.size())*float(p)/100.0)-1,0,values.size()-1)]
	for value in values:
		if value>16667:result["over_16_667_usec"]+=1
	return result

func counters()->Dictionary:
	return {"atlas_uploads":view.fx_atlas_uploads,"cast_uploads":view.fx_atlas_uploads_in_cast,"frame_builds":view.fx_frame_builds,"secondary_builds":view.fx_secondary_builds,"secondary_pack_hits":view.fx_secondary_pack_hits,"light_candidates":view.fx_light_candidates,"light_commits":view.fx_light_commits}

func delta(before:Dictionary)->Dictionary:
	var after:=counters()
	for key in after:after[key]=int(after[key])-int(before[key])
	return after

func sample_pools()->void:
	peak_atlases=maxi(peak_atlases,view.fx_atlas_cache.size())
	peak_secondary=maxi(peak_secondary,view.combat_textures.size())
	peak_lights=maxi(peak_lights,view.fx_lights_used)
	peak_trail=maxi(peak_trail,view.fx_trail_vertices)
	var visible:int=0
	for particle in view.combat_particles:
		if particle.visible:visible+=1
	peak_particles=maxi(peak_particles,visible)

func sample_memory()->void:
	peak_static_bytes=maxi(peak_static_bytes,int(OS.get_static_memory_usage()))
	peak_video_bytes=maxi(peak_video_bytes,int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)))

func event_for(id:String,move:Dictionary,index:int)->Dictionary:
	var source:=Vector2i(0,index%5-2)
	var target:=source+Vector2i(2,0)
	var row:Dictionary={"effects":1} if str(move.get("category",""))=="status" else {"damage":8}
	return {"fx":id,"from":source,"to":target,"path":[source+Vector2i(1,0),target],"tiles":[target],"results":{target:row},"damage":int(row.get("damage",0))}

func simulate(ids:Array,catalog:Dictionary,spawn_times:Array[int],update_times:Array[int])->Dictionary:
	var before:=counters()
	for i in range(ids.size()):
		var id:String=str(ids[i])
		var event:=event_for(id,catalog[id],i)
		var start:int=Time.get_ticks_usec()
		view.combat_fx_spawn(event)
		spawn_times.append(Time.get_ticks_usec()-start)
	var frame:int=0
	while not view.combat_bursts.is_empty() and frame<180:
		var start:int=Time.get_ticks_usec()
		view.combat_fx_update(DT)
		update_times.append(Time.get_ticks_usec()-start)
		sample_pools()
		frame+=1
	if not view.combat_bursts.is_empty():failures.append("cast did not finish")
	for i in range(6):
		var start:int=Time.get_ticks_usec()
		view.combat_fx_update(DT)
		update_times.append(Time.get_ticks_usec()-start)
		sample_pools()
	sample_memory()
	return delta(before)

func benchmark()->void:
	var catalog:Dictionary=Dungeon.Rules.MOVE_LIBRARY.duplicate()
	catalog.merge(Dungeon.Rules.DEV_NATIVE_MOVES)
	var ids:Array=catalog.keys()
	ids.sort()
	scene=Node3D.new()
	root.add_child(scene)
	view=Dungeon.new()
	view.combat_fx_setup(scene)
	view.fx_audio.clear() # Rendering/CPU isolated from audio playback.
	view.combat_frame_pack_init()
	view.secondary_pack_init()
	if ids.size()!=589 or view.fx_frame_pack==null or view.fx_secondary_pack==null:
		push_error("benchmark requires complete baked packs and 589 moves")
		scene.free()
		view.free()
		quit(1)
		return
	var rendered:bool="--rendered" in OS.get_cmdline_user_args()
	var report:Dictionary={"mode":"desktop_rendered" if rendered else "headless_cpu_submission","catalog_moves":ids.size(),"simulation_hz":60,"frame_budget_usec":16667,"audio_playback":false}
	if rendered:
		await rendered_probe(ids,catalog,report)
	else:
		var cold_spawn:Array[int]=[]
		var cold_update:Array[int]=[]
		var warm_spawn:Array[int]=[]
		var warm_update:Array[int]=[]
		var crowd_spawn:Array[int]=[]
		var crowd_update:Array[int]=[]
		var per_move:Array[Dictionary]=[]
		for id in ids:
			view.fx_atlas_cache.clear()
			view.combat_textures.clear()
			view.fx_secondary_newest=""
			var cold_s:Array[int]=[]
			var cold_u:Array[int]=[]
			var warm_s:Array[int]=[]
			var warm_u:Array[int]=[]
			var cold:=simulate([id],catalog,cold_s,cold_u)
			var warm:=simulate([id],catalog,warm_s,warm_u)
			if int(cold.frame_builds)!=0 or int(warm.frame_builds)!=0 or int(warm.atlas_uploads)!=0:
				failures.append("packed atlas regression "+str(id))
			cold_spawn.append_array(cold_s)
			cold_update.append_array(cold_u)
			warm_spawn.append_array(warm_s)
			warm_update.append_array(warm_u)
			per_move.append({"id":id,"cold_spawn_usec":cold_s[0],"cold_update":stats(cold_u),"cold_counters":cold,"warm_spawn_usec":warm_s[0],"warm_update":stats(warm_u),"warm_counters":warm})
		var crowd_before:=counters()
		for batch in range(12):
			var group:Array=[]
			for i in range(Dungeon.COMBAT_BURST_CAP):
				group.append(ids[posmod(batch*47+i*31,ids.size())])
			for id in group:view.combat_packed_frame(str(id),0)
			var measured:=simulate(group,catalog,crowd_spawn,crowd_update)
			if int(measured.atlas_uploads)!=0 or int(measured.frame_builds)!=0:failures.append("warm concurrent atlas regression")
		report["cold_spawn"]=stats(cold_spawn)
		report["cold_update"]=stats(cold_update)
		report["warm_spawn"]=stats(warm_spawn)
		report["warm_update"]=stats(warm_update)
		report["crowd_spawn"]=stats(crowd_spawn)
		report["crowd_update"]=stats(crowd_update)
		report["crowd_batches"]=12
		report["concurrent_casts"]=Dungeon.COMBAT_BURST_CAP
		report["crowd_counters_including_prewarm"]=delta(crowd_before)
		report["per_move"]=per_move
		if cold_spawn.size()!=589 or warm_spawn.size()!=589 or crowd_spawn.size()!=12*Dungeon.COMBAT_BURST_CAP:failures.append("benchmark coverage")
	report["counters"]=counters()
	report["peaks"]={"atlas_entries":peak_atlases,"secondary_entries":peak_secondary,"visible_particles":peak_particles,"lights":peak_lights,"trail_vertices":peak_trail,"static_bytes":peak_static_bytes,"renderer_video_bytes":peak_video_bytes}
	if peak_atlases>Dungeon.FX_ATLAS_CACHE_CAP or peak_secondary>Dungeon.FX_SECONDARY_TEXTURE_CAP or peak_particles>Dungeon.FX_PARTICLE_CAP+Dungeon.LIVING_PARTICLE_CAP or peak_lights>Dungeon.FX_LIGHT_CAP or peak_trail>Dungeon.FX_TRAIL_VERTEX_CAP:failures.append("pool cap exceeded")
	if view.fx_frame_builds!=0 or view.fx_light_commits>view.fx_light_candidates:failures.append("renderer regression")
	report["failures"]=failures
	var file:=FileAccess.open("/tmp/kindria-performance-rendered.json" if rendered else "/tmp/kindria-performance-cpu.json",FileAccess.WRITE)
	if file==null:failures.append("report write")
	else:
		file.store_string(JSON.stringify(report,"\t"))
		file.close()
	print("KINDRIA_PERFORMANCE mode=",report.mode," moves=",ids.size()," failures=",failures.size())
	for failure in failures:push_error(failure)
	scene.free()
	view.free()
	quit(0 if failures.is_empty() else 1)

func rendered_probe(ids:Array,catalog:Dictionary,report:Dictionary)->void:
	var camera:=Camera3D.new()
	scene.add_child(camera)
	camera.position=Vector3(4,7,10)
	camera.look_at(Vector3(1,0,0))
	camera.current=true
	view.camera=camera
	var environment:=WorldEnvironment.new()
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("#20263a")
	environment.environment=env
	scene.add_child(environment)
	var frame_times:Array[int]=[]
	var submit_times:Array[int]=[]
	var group:Array=[]
	for i in range(Dungeon.COMBAT_BURST_CAP):
		var id:String=str(ids[i*47])
		group.append(id)
		view.combat_packed_frame(id,0)
	# Warm up render pipelines before measuring the repeated mixed battle.
	for i in range(240):
		var start:int=Time.get_ticks_usec()
		if i%40==0:
			for j in range(group.size()):
				var id:String=group[j]
				view.combat_fx_spawn(event_for(id,catalog[id],j))
		var submit_start:int=Time.get_ticks_usec()
		view.combat_fx_update(DT)
		var submit_usec:int=Time.get_ticks_usec()-submit_start
		await process_frame
		await RenderingServer.frame_post_draw
		if i>=40:
			frame_times.append(Time.get_ticks_usec()-start)
			submit_times.append(submit_usec)
			sample_pools()
		if i%20==0:sample_memory()
	report["rendered_frame_intervals"]=stats(frame_times)
	report["cpu_update"]=stats(submit_times)
	report["rendered_samples"]=frame_times.size()
	if frame_times.size()!=200:failures.append("rendered sample coverage")
