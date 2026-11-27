extends SceneTree
const Field=preload("res://dungeon_view.gd")
const OUTPUT="/tmp/kindria-rtdx-runtime/"
func _initialize()->void:
	call_deferred("run")
func check(ok:bool,message:String)->bool:
	if not ok:
		push_error("RTDX_RUNTIME_FAIL "+message)
		quit(1)
	return ok
func draw()->void:
	await process_frame
	await RenderingServer.frame_post_draw
func count_visible(field)->int:
	var count:int=0
	for i in range(Field.FX_PARTICLE_CAP):
		if field.combat_particles[i].visible:count+=1
	return count
func run()->void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var field=Field.new()
	root.add_child(field)
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field.setup(0,1,0,false,true,902,24)
	field.set_process(false)
	for i in range(4):await draw()
	var origin:Vector2i=field.run.player
	var target:Vector2i=origin+Vector2i.RIGHT
	var report:Array=[]
	for move_id in Field.RTDX_OBSERVED_MOVES:
		var p:Dictionary=field.combat_profile(move_id)
		var duration:float=float(field.combat_style(move_id)[3])
		var peak:float=float(p.impact)
		var outcome:Dictionary={"effects":1} if move_id=="eos_142" else {"damage":8,"hits":1}
		var phases:Array=[peak*.45,peak*.90,lerpf(peak,1.0,.08),lerpf(peak,1.0,.35),lerpf(peak,1.0,.85),1.05]
		for is_miss in [false,true]:
			field.combat_bursts.clear()
			field.retired_impacts.clear()
			field.fx_residues.clear()
			field.fx_reaction_sparks.clear()
			field.combat_fx_update(1.0)
			var event:Dictionary={"fx":move_id,"from":origin,"to":target,"path":[target],"tiles":[target],"source_height":.55,"target_height":.55,"results":{target:{"misses":1} if is_miss else outcome}}
			var previous_cache:int=field.fx_animated_cache.size()
			field.combat_fx_spawn(event)
			if not check(field.combat_bursts.size()==1,move_id+" spawn"):return
			if not check(field.fx_animated_cache.size()==previous_cache,move_id+" unused legacy cache"):return
			var previous:float=0.0
			var visible:Array=[]
			for j in range(phases.size()):
				var phase:float=phases[j]
				field.combat_fx_update((phase-previous)*duration)
				previous=phase
				var count:int=count_visible(field)
				visible.append(count)
				if not check(count<=Field.FX_PARTICLE_CAP,move_id+" overflow"):return
				if j==2 and is_miss and move_id in ["eos_260","eos_174","eos_036","eos_092","eos_109","eos_108","eos_151","eos_114"]:
					if not check(count==0,move_id+" false contact"):return
				if j==2 and not is_miss:
					if not check(count>0,move_id+" missing contact"):return
				if j==5:
					if not check(field.combat_bursts.is_empty() and count==0,move_id+" lingering cast"):return
				if not is_miss and j<5:
					await draw()
					if not check(root.get_texture().get_image().save_png(OUTPUT+move_id+"-"+str(j)+".png")==OK,move_id+" capture"):return
			if not check(field.fx_residues.is_empty(),move_id+" legacy residue"):return
			report.append({"id":move_id,"miss":is_miss,"normalized_phases":phases,"visible_particles":visible,"engine_duration_ms":duration*1000.0,"dx_timing_verified":false})
	var f:=FileAccess.open(OUTPUT+"runtime-report.json",FileAccess.WRITE)
	if not check(f!=null,"report open"):return
	f.store_string(JSON.stringify(report,"  "))
	f.close()
	print("KINDRIA_RTDX_RUNTIME_PASS ",Field.RTDX_OBSERVED_MOVES.size()," casts=",report.size())
	quit(0)
