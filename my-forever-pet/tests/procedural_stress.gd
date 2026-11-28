extends SceneTree
const Rules=preload("res://dungeon_rules.gd")

func _initialize()->void:
	call_deferred("run_checks")

func restart_check(mode:String)->void:
	var path:String="user://kindria_restart_fixture.cfg"
	var run=Rules.new()
	if mode=="--history-write":
		for suffix in ["",".bak",".tmp"]:
			if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
		run.setup(0,24,0,false,false,994321,0,false)
		if Rules.write_layout_history(path,run.recent_layouts,run.recent_shapes)!=OK:
			push_error("restart fixture write failed");quit(1);return
		print("KINDRIA_HISTORY_WRITE shape=",run.shape_signature)
		quit(0);return
	var config:ConfigFile=Rules.read_layout_history(path)
	var shapes:Variant=config.get_value("dungeons","canonical_shapes_v1",[])
	if shapes.size()!=1:
		push_error("restart fixture missing");quit(1);return
	run.recent_shapes.assign(shapes)
	run.setup(0,24,0,false,false,994321,0,false)
	if run.shape_history_hits<1 or run.shape_signature==shapes[0]:
		push_error("restart repeat not rejected");quit(1);return
	print("KINDRIA_HISTORY_RESTART_PASS previous=",shapes[0]," replacement=",run.shape_signature," retries=",run.layout_retries)
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	quit(0)

func run_checks()->void:
	for mode in ["--history-write","--history-read"]:
		if mode in OS.get_cmdline_user_args():restart_check(mode);return
	var failures:Array[String]=[]
	var signatures:Dictionary={}
	var families:Dictionary={}
	var profiles:Dictionary={}
	var timings:Array[int]=[]
	var history:Array[String]=[]
	var retries:int=0
	var checks:int=0
	var lucky:int=0
	var optional_chambers:int=0
	var expedition_count:int=1152 if "--long" in OS.get_cmdline_user_args() else 256
	var expected_floors:int=expedition_count*4
	var rollover_checks:int=0
	var forced_retries:int=0
	for expedition in range(expedition_count):
		var run=Rules.new()
		run.recent_shapes.assign(history)
		for floor_id in range(1,5):
			var start:int=Time.get_ticks_usec()
			if floor_id==1:
				run.setup(expedition%3,24,0,false,false,97121+expedition*97,0,false)
			else:
				run.floor_number=floor_id
				run.generate_floor()
			timings.append(Time.get_ticks_usec()-start)
			var context:String="expedition=%d floor=%d seed=%d"%[expedition,floor_id,run.seed_value]
			if signatures.has(run.shape_signature):failures.append("duplicate "+context)
			signatures[run.shape_signature]=true
			families[run.topology_family]=true
			profiles[Vector2i(run.structure_profile,run.network_profile)]=true
			retries+=run.layout_retries
			if run.player==run.stairs:lucky+=1
			optional_chambers+=run.side_chambers.size()
			if not run.stairs_available() or not run.cells.has(run.player) or not run.cells.has(run.stairs):failures.append("stairs "+context)
			var visited:Dictionary={}
			var queue:Array[Vector2i]=[run.player]
			visited[run.player]=true
			var cursor:int=0
			var bounds_ok:bool=true
			while cursor<queue.size():
				var tile:Vector2i=queue[cursor];cursor+=1
				if not run.floor_bounds.has_point(tile):bounds_ok=false
				for direction in run.DIR:
					var next:Vector2i=tile+direction
					if run.cells.has(next) and not visited.has(next):
						visited[next]=true;queue.append(next)
			if visited.size()!=run.cells.size() or not visited.has(run.stairs):failures.append("connectivity "+context)
			if not bounds_ok or run.rooms.size()<3 or run.rooms.size()>12:failures.append("bounds "+context)
			var spawns_ok:bool=true
			var occupied:Dictionary={}
			for enemy in run.enemies:
				var q:Vector2i=enemy.pos
				if occupied.has(q) or not run.cells.has(q) or q==run.player or q==run.stairs:spawns_ok=false
				occupied[q]=true
			for reward in run.side_rewards:
				if run.loot.get(reward,"")!="material" or occupied.has(reward) or run.traps.has(reward):spawns_ok=false
			if not spawns_ok:failures.append("spawn integrity "+context)
			if not run.recent_shapes.has(run.shape_signature):failures.append("history "+context)
			checks+=6
		if history.size()+4>run.SHAPE_HISTORY_CAP:
			var dropped:int=history.size()+4-run.SHAPE_HISTORY_CAP
			if run.recent_shapes.size()!=run.SHAPE_HISTORY_CAP or run.recent_shapes.front()!=history[dropped]:failures.append("history rollover ordering")
			rollover_checks+=1;checks+=1
		history.assign(run.recent_shapes)
	if signatures.size()!=expected_floors or history.size()!=mini(expected_floors,Rules.SHAPE_HISTORY_CAP):failures.append("unique history coverage")
	if families.size()!=23:failures.append("normal family coverage")
	if lucky==0:failures.append("same tile stairs not observed")
	if optional_chambers==0:failures.append("optional chambers not observed")
	checks+=4
	for region_id in range(3):
		var final_run=Rules.new()
		final_run.setup(region_id,24,0,true,false,90117+region_id,0,false)
		final_run.floor_number=final_run.floor_count
		final_run.generate_floor()
		if final_run.stairs_available() or final_run.player==final_run.stairs:failures.append("guardian finale isolation")
		checks+=1
	# Re-enter the same seeded floor with only canonical history supplied.
	for seed_index in range(64):
		var original=Rules.new()
		original.setup(seed_index%3,24,0,false,false,840001+seed_index,0,false)
		var replay=Rules.new()
		replay.recent_shapes.assign(original.recent_shapes)
		replay.setup(seed_index%3,24,0,false,false,840001+seed_index,0,false)
		if replay.shape_history_hits<1 or replay.shape_signature==original.shape_signature or replay.layout_retries<1:failures.append("forced canonical retry "+str(seed_index))
		forced_retries+=replay.layout_retries;checks+=1
	if expedition_count>256 and rollover_checks==0:failures.append("missing history rollover")
	checks+=1
	# Actual disk I/O, legacy migration, corruption recovery, and resumed writes.
	var test_path:String="user://kindria_procedural_test_"+str(OS.get_process_id())+".cfg"
	var exact:Array[String]=["legacy exact".sha256_text()]
	var shapes:Array[String]=["first shape".sha256_text()]
	var legacy:=ConfigFile.new()
	legacy.set_value("dungeons","geometry",exact)
	if legacy.save(test_path)!=OK or Rules.read_layout_history(test_path).get_value("dungeons","geometry",[])!=exact:failures.append("legacy history disk load")
	if Rules.write_layout_history(test_path,exact,shapes)!=OK:failures.append("first snapshot write")
	var loaded:ConfigFile=Rules.read_layout_history(test_path)
	if loaded.get_value("dungeons","canonical_shapes_v1",[])!=shapes:failures.append("snapshot roundtrip")
	var latest:Array[String]=shapes.duplicate()
	latest.append("second shape".sha256_text())
	if Rules.write_layout_history(test_path,exact,latest)!=OK:failures.append("second snapshot write")
	if Rules.read_layout_history(test_path).get_value("dungeons","canonical_shapes_v1",[])!=latest:failures.append("replacement snapshot read")
	var damaged:=ConfigFile.new()
	damaged.set_value("dungeons","geometry",["invalid"])
	damaged.save(test_path)
	if Rules.read_layout_history(test_path).get_value("dungeons","canonical_shapes_v1",[])!=shapes:failures.append("corrupt primary backup recovery")
	if Rules.write_layout_history(test_path,exact,latest)!=OK or Rules.read_layout_history(test_path).get_value("dungeons","canonical_shapes_v1",[])!=latest:failures.append("resumed snapshot write")
	var backup:=ConfigFile.new()
	if backup.load(test_path+".bak")!=OK or backup.get_value("dungeons","canonical_shapes_v1",[])!=shapes:failures.append("valid backup preservation")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(test_path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+suffix))
	checks+=8
	timings.sort()
	print("KINDRIA_PROCEDURAL_RESULT floors=",timings.size()," unique=",signatures.size()," families=",families.size()," profile_pairs=",profiles.size()," retries=",retries," same_tile=",lucky," side_chambers=",optional_chambers," median_usec=",timings[int(timings.size()/2)]," p95_usec=",timings[int((timings.size()-1)*.95)]," max_usec=",timings.back()," rollover_checks=",rollover_checks," forced_retries=",forced_retries," checks=",checks," failures=",failures.size())
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
