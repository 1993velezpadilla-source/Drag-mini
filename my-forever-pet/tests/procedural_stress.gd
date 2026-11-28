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
	var encounter_profiles:Dictionary={}
	var treasure_seen:Dictionary={}
	var treasure_ranks:Dictionary={}
	var treasure_floors:int=0
	var encounter_moves:Dictionary={}
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
			var encounter:int=run.encounter_profile
			encounter_profiles[encounter]=int(encounter_profiles.get(encounter,0))+1
			var moved:=Vector3i(run.encounter_enemy_count,run.encounter_loot_count,run.encounter_trap_count)
			encounter_moves[encounter]=encounter_moves.get(encounter,Vector3i.ZERO)+moved
			var caps:Vector3i=[Vector3i.ZERO,Vector3i(3,0,0),Vector3i(0,4,0),Vector3i(2,3,0),Vector3i(0,1,3)][encounter]
			if moved.x<0 or moved.y<0 or moved.z<0 or moved.x>caps.x or moved.y>caps.y or moved.z>caps.z:failures.append("encounter relocation budget "+context)
			if encounter==0:
				if run.encounter_room!=-1 or moved!=Vector3i.ZERO:failures.append("classic isolation "+context)
			elif run.encounter_room<0 or run.encounter_room>=run.rooms.size():failures.append("encounter room index "+context)
			else:
				var encounter_bounds:Rect2i=run.rooms[run.encounter_room]
				if encounter_bounds.has_point(run.player) or encounter_bounds.has_point(run.stairs) or encounter_bounds.has_point(run.relic) or run.encounter_room==run.monster_house_room:failures.append("encounter isolation "+context)
				var local_enemies:int=0
				var local_loot:int=0
				var local_traps:int=0
				for e in run.enemies:
					if encounter_bounds.has_point(e.pos):local_enemies+=1
				for p in run.loot:
					if encounter_bounds.has_point(p):local_loot+=1
				for p in run.traps:
					if encounter_bounds.has_point(p):local_traps+=1
				if local_enemies<moved.x or local_loot<moved.y or local_traps<moved.z:failures.append("encounter relocation integrity "+context)
			if (floor_id==1 or run.floor_kind==3) and encounter!=0:failures.append("protected floor encounter "+context)
			var treasure_ok:bool=run.treasure_tiles.size()==run.treasure_kinds.size() and run.treasure_tiles.size()<=(2 if floor_id>=3 else 1)
			if not run.treasure_tiles.is_empty():treasure_floors+=1
			var found:Dictionary={}
			for i in range(run.treasure_tiles.size()):
				var tile:Vector2i=run.treasure_tiles[i]
				var item:String=run.treasure_kinds[i]
				if found.has(tile) or run.loot.get(tile,"")!=item or tile==run.player or tile==run.stairs or tile==run.relic or tile in run.side_rewards or run.enemy_at(tile)>=0 or run.traps.has(tile):treasure_ok=false
				found[tile]=true
				treasure_seen[item]=int(treasure_seen.get(item,0))+1
				if item.begins_with("manual:"):
					var id:String=item.trim_prefix("manual:")
					if not Rules.MOVE_LIBRARY.has(id):treasure_ok=false;continue
					var move:Dictionary=Rules.MOVE_LIBRARY[id]
					var level:int=int(move.learn_level)
					treasure_ranks[level]=true
					if move.type not in Rules.TREASURE_TYPES[run.region] or (level>=8 and floor_id<3) or (level>=15 and floor_id<4):treasure_ok=false
				elif item not in ["ward_band","force_band"]:treasure_ok=false
			if (floor_id==1 or run.floor_kind==3) and not found.is_empty():treasure_ok=false
			if not treasure_ok:failures.append("treasure integrity "+context)
			checks+=11
		if history.size()+4>run.SHAPE_HISTORY_CAP:
			var dropped:int=history.size()+4-run.SHAPE_HISTORY_CAP
			if run.recent_shapes.size()!=run.SHAPE_HISTORY_CAP or run.recent_shapes.front()!=history[dropped]:failures.append("history rollover ordering")
			rollover_checks+=1;checks+=1
		history.assign(run.recent_shapes)
	if treasure_floors==0 or treasure_seen.size()<18 or treasure_ranks.size()!=3 or not treasure_seen.has("ward_band") or not treasure_seen.has("force_band"):failures.append("treasure coverage")
	checks+=1
	print("KINDRIA_TREASURES floors=",treasure_floors," distinct=",treasure_seen.size()," ranks=",treasure_ranks.keys()," items=",treasure_seen)
	if encounter_profiles.size()!=Rules.ENCOUNTER_PROFILES.size():failures.append("encounter profile coverage")
	for profile in range(1,Rules.ENCOUNTER_PROFILES.size()):
		if encounter_moves.get(profile,Vector3i.ZERO)==Vector3i.ZERO:failures.append("encounter realization "+str(profile))
	checks+=5
	print("KINDRIA_ROOM_ENCOUNTERS ",encounter_profiles," relocated=",encounter_moves)
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
	# Exercise every encounter recipe without relying on the natural event probability.
	var house_profiles:Dictionary={}
	for seed_id in range(192):
		var house=Rules.new()
		house.setup(seed_id%3,24,0,false,false,120003+seed_id,0,false)
		if not house.prepare_monster_house(true):continue
		var profile:int=house.monster_house_profile
		house_profiles[profile]=int(house_profiles.get(profile,0))+1
		var room:Rect2i=house.rooms[house.monster_house_room]
		var entry:Vector2i=room.get_center()
		if entry==house.stairs or entry==house.relic or house.enemy_at(entry)>=0 or not house.cells.has(entry):
			for tile in house.cells:
				if room.has_point(tile) and tile!=house.stairs and tile!=house.relic and house.enemy_at(tile)<0 and house.ally_at(tile)<0:
					entry=tile;break
		house.player=entry
		var before:int=house.enemies.size()
		if not house.trigger_monster_house():failures.append("house trigger "+str(seed_id))
		var count:int=house.monster_house_remaining()
		if count<1 or count>house.MONSTER_HOUSE_CAP or house.enemies.size()!=before+count:failures.append("house budget "+str(seed_id))
		var occupied:Dictionary={}
		for e in house.enemies:
			if occupied.has(e.pos) or not house.cells.has(e.pos) or e.pos==house.player or e.pos==house.stairs:failures.append("house placement "+str(seed_id))
			occupied[e.pos]=true
			if bool(e.get("monster_house",false)):
				var index:int=int(e.uid)-house.MONSTER_HOUSE_UID_BASE
				if profile in [1,2,3] and int(e.kind)!=house.house_enemy_kind(profile,index):failures.append("house composition "+str(seed_id))
		if house.trigger_monster_house() or not house.stairs_available():failures.append("house duplicate or stair lock "+str(seed_id))
		checks+=4
	if house_profiles.size()!=Rules.HOUSE_PROFILES.size():failures.append("house profile coverage")
	checks+=1
	print("KINDRIA_HOUSE_PROFILES ",house_profiles)
	# Exploration bookkeeping uses visits, not the minimap's reveal radius.
	var full_discoveries:int=0
	var side_discoveries:int=0
	for seed_id in range(128):
		var explorer=Rules.new()
		explorer.setup(seed_id%3,24,0,false,false,180003+seed_id,0,false)
		explorer.floor_number=explorer.floor_count
		explorer.generate_floor()
		if explorer.exploration_count()!=1 or explorer.exploration_coin_bonus()!=0 or explorer.exploration_material_bonus()!=0:failures.append("exploration initial progress")
		for room in explorer.rooms:
			explorer.player=explorer.center(room);explorer.reveal();explorer.reveal()
		if explorer.exploration_count()!=explorer.rooms.size():failures.append("exploration unique room visits")
		if not explorer.side_chambers.is_empty() and explorer.exploration_material_bonus()!=0:failures.append("side chamber required for full discovery")
		for room in explorer.side_chambers:
			explorer.player=explorer.center(room);explorer.reveal();explorer.reveal()
			side_discoveries+=1
		if explorer.exploration_count()!=explorer.exploration_total() or explorer.exploration_material_bonus()!=1:failures.append("full discovery payout eligibility")
		var coins_before:int=explorer.coins
		var materials_before:int=explorer.materials
		var expected_coins:int=explorer.exploration_coin_bonus()
		explorer.player=explorer.stairs
		if not explorer.descend() or not explorer.finished or explorer.coins!=coins_before+expected_coins or explorer.materials!=materials_before+1 or expected_coins>6:failures.append("exploration settlement")
		if explorer.descend() or explorer.coins!=coins_before+expected_coins or explorer.materials!=materials_before+1:failures.append("duplicate exploration settlement")
		full_discoveries+=1;checks+=6
	if side_discoveries==0:failures.append("side discovery coverage")
	checks+=1
	var skip=Rules.new()
	skip.setup(0,24,0,false,false,192021,0,false)
	var skip_materials:int=skip.materials
	skip.player=skip.stairs
	if not skip.descend() or skip.materials!=skip_materials or skip.explored_side_chambers.size()!=0 or skip.exploration_count()!=1:failures.append("optional exploration and next floor reset")
	checks+=1
	print("KINDRIA_EXPLORATION full=",full_discoveries," side_chambers=",side_discoveries)
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
