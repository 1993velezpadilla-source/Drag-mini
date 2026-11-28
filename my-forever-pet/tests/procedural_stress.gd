extends SceneTree
const Rules=preload("res://dungeon_rules.gd")

func _initialize()->void:
	call_deferred("run_checks")

func run_checks()->void:
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
	for expedition in range(256):
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
		history.assign(run.recent_shapes)
	if signatures.size()!=1024 or history.size()!=1024:failures.append("unique history coverage")
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
	timings.sort()
	print("KINDRIA_PROCEDURAL_RESULT floors=",timings.size()," unique=",signatures.size()," families=",families.size()," profile_pairs=",profiles.size()," retries=",retries," same_tile=",lucky," side_chambers=",optional_chambers," median_usec=",timings[int(timings.size()/2)]," p95_usec=",timings[int((timings.size()-1)*.95)]," max_usec=",timings.back()," checks=",checks," failures=",failures.size())
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
