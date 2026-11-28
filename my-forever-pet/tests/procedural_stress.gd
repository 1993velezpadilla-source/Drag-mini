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
	# Verify all trap effects, single-use settlement and protection.
	var trap_coverage:Dictionary={}
	for seed_id in range(128):
		var trap_run=Rules.new()
		trap_run.setup(seed_id%3,24,0,false,false,230003+seed_id,0,false)
		trap_run.floor_number=4;trap_run.generate_floor()
		for p in trap_run.traps:
			var kind:String=str(trap_run.traps[p])
			trap_coverage[kind]=int(trap_coverage.get(kind,0))+1
			if kind not in Rules.FLOOR_TRAP_KINDS or not trap_run.cells.has(p) or p==trap_run.player or p==trap_run.stairs or p==trap_run.relic or p in trap_run.side_rewards:failures.append("trap placement")
		checks+=1
	if trap_coverage.size()!=Rules.FLOOR_TRAP_KINDS.size():failures.append("trap coverage")
	checks+=1
	var fixture=Rules.new()
	var tile:=Vector2i(2,2)
	for kind in Rules.FLOOR_TRAP_KINDS+["legacy"]:
		fixture.hp=20;fixture.energy=5;fixture.belly_tenths=1000
		fixture.player_slow_turns=0;fixture.weakened_strikes=0
		fixture.traps[tile]=true if kind=="legacy" else kind
		if not fixture.trigger_floor_trap(tile) or fixture.trigger_floor_trap(tile):failures.append("trap single use "+kind)
		var valid:bool=true
		match kind:
			"snare":valid=fixture.player_slow_turns==4 and fixture.hp==20
			"drain":valid=fixture.energy==3 and fixture.hp==20
			"hunger":valid=fixture.belly_tenths==920 and fixture.hp==20
			"weaken":valid=fixture.weakened_strikes==2 and fixture.hp==20
			_:valid=fixture.hp==17
		if not valid:failures.append("trap effect "+kind)
		checks+=2
	fixture.shield_kind="safeguard";fixture.shield_turns=3
	fixture.player_slow_turns=0;fixture.weakened_strikes=0
	for kind in ["snare","weaken"]:
		fixture.traps[tile]=kind;fixture.trigger_floor_trap(tile)
	if fixture.player_slow_turns!=0 or fixture.weakened_strikes!=0:failures.append("trap safeguard")
	checks+=1
	fixture.hp=1;fixture.energy=0;fixture.belly_tenths=10
	for kind in ["spike","drain","hunger"]:
		fixture.traps[tile]=kind;fixture.trigger_floor_trap(tile)
	if fixture.hp!=1 or fixture.energy!=0 or fixture.belly_tenths!=10:failures.append("trap resource bounds")
	checks+=1
	print("KINDRIA_FLOOR_TRAPS ",trap_coverage)
	# Ordinary ecosystem roles must preserve original combat kits and spawn budgets.
	var role_coverage:Dictionary={}
	for seed_id in range(128):
		var ecosystem=Rules.new()
		ecosystem.setup(seed_id%3,24,0,false,false,270003+seed_id,0,false)
		for e in ecosystem.enemies:
			if e.has("ecology_role"):failures.append("first floor ecology isolation")
		ecosystem.floor_number=4;ecosystem.generate_floor()
		for e in ecosystem.enemies:
			if ecosystem.floor_kind==3:
				if e.has("ecology_role"):failures.append("restorative ecology isolation")
				continue
			var role:String=str(e.get("ecology_role",""))
			role_coverage[role]=int(role_coverage.get(role,0))+1
			if role not in Rules.ENEMY_ECOLOGY_ROLES or e.get("ecology_home")!=e.pos or not ecosystem.cells.has(e.pos):failures.append("ecology role integrity")
			if ecosystem.enemy_awareness(e)!=(8 if role=="scout" else 4 if role=="sentry" else 6):failures.append("ecology awareness")
		checks+=2
	if role_coverage.size()!=Rules.ENEMY_ECOLOGY_ROLES.size():failures.append("ecology coverage")
	checks+=1
	var patrol_fixture=Rules.new()
	patrol_fixture.player=Vector2i(14,14)
	patrol_fixture.stairs=Vector2i(5,4)
	patrol_fixture.relic=Vector2i(4,5)
	patrol_fixture.cells.clear()
	for y in range(1,17):
		for x in range(1,17):patrol_fixture.cells[Vector2i(x,y)]=true
	var home:=Vector2i(4,4)
	patrol_fixture.traps[Vector2i(3,4)]="spike"
	patrol_fixture.enemies.append({"uid":0,"pos":home,"hp":20,"kind":0,"ecology_role":"roamer","ecology_home":home})
	var steps:int=0
	for tick in range(16):
		var old:Vector2i=patrol_fixture.enemies[0].pos
		patrol_fixture.enemy_turn_actions()
		var next:Vector2i=patrol_fixture.enemies[0].pos
		if next!=old:steps+=1
		if patrol_fixture.distance(next,home)>3 or patrol_fixture.distance(next,old)>1 or next==patrol_fixture.stairs or next==patrol_fixture.relic or patrol_fixture.traps.has(next):failures.append("patrol movement bounds")
		checks+=1
	if steps==0:failures.append("patrol realization")
	patrol_fixture.enemies[0]["stuck_turns"]=3
	if patrol_fixture.enemy_patrol_destination(patrol_fixture.enemies[0])!=patrol_fixture.enemies[0].pos:failures.append("patrol immobilization")
	if patrol_fixture.enemy_awareness({"monster_house":true})<100:failures.append("house pursuit isolation")
	checks+=3
	print("KINDRIA_ENEMY_ECOLOGY ",role_coverage," patrol_steps=",steps)
	# Real corridor congestion: a blocked route may still have a useful prefix.
	var navigation=Rules.new()
	navigation.cells.clear()
	for x in range(1,10):navigation.cells[Vector2i(x,3)]=true
	navigation.player=Vector2i(9,3)
	var origin:=Vector2i(1,3)
	navigation.enemies.append({"uid":0,"pos":origin,"hp":20,"kind":0})
	navigation.enemies.append({"uid":1,"pos":Vector2i(5,3),"hp":20,"kind":0})
	if not navigation.route(origin,navigation.player,true).is_empty():failures.append("blocked corridor direct route")
	var partial:Array[Vector2i]=navigation.enemy_approach_route(origin,navigation.player)
	if partial!=[Vector2i(2,3),Vector2i(3,3),Vector2i(4,3)]:failures.append("blocked corridor partial approach")
	if not navigation.enemy_approach_route(Vector2i(4,3),navigation.player).is_empty():failures.append("blocked corridor wait")
	checks+=3
	# A detour is preferred when an unobstructed full route exists.
	for x in range(4,7):navigation.cells[Vector2i(x,2)]=true
	var detour:Array[Vector2i]=navigation.enemy_approach_route(origin,navigation.player)
	if detour.is_empty() or detour.back()!=navigation.player or Vector2i(5,3) in detour or Vector2i(5,2) not in detour:failures.append("congestion detour")
	checks+=1
	# Live allies block traversal; defeated allies do not.
	navigation.allies.append({"pos":Vector2i(5,2),"hp":5})
	var blocked_detour:Array[Vector2i]=navigation.enemy_approach_route(origin,navigation.player)
	if blocked_detour.is_empty() or blocked_detour.back()==navigation.player or Vector2i(5,2) in blocked_detour:failures.append("ally occupancy")
	navigation.allies[0].hp=0
	if navigation.enemy_approach_route(origin,navigation.player)!=detour:failures.append("defeated ally occupancy")
	checks+=2
	# Seeded routes must retain valid adjacency, determinism and target semantics.
	for seed_id in range(128):
		var walker=Rules.new()
		walker.setup(seed_id%3,24,0,false,false,290003+seed_id,0,false)
		for e in walker.enemies:
			var p:Vector2i=e.pos
			var route_a:Array[Vector2i]=walker.enemy_approach_route(p,walker.player)
			var route_b:Array[Vector2i]=walker.enemy_approach_route(p,walker.player)
			var direct_route:Array[Vector2i]=walker.route(p,walker.player,true)
			if route_a!=route_b or (not direct_route.is_empty() and route_a!=direct_route):failures.append("navigation determinism")
			for q in route_a:
				if walker.distance(p,q)!=1 or not walker.cells.has(q) or walker.enemy_at(q)>=0 or walker.ally_at(q)>=0:failures.append("navigation path integrity")
				p=q
		checks+=2
	print("KINDRIA_NAVIGATION congestion=3 detour=1 occupancy=2 seeded_floors=128")
	# Memory follows only the last observed position and expires by global turn.
	var memory_fixture=Rules.new()
	for x in range(1,18):memory_fixture.cells[Vector2i(x,3)]=true
	var memory_origin:=Vector2i(2,3)
	var known:=Vector2i(5,3)
	var hidden:=Vector2i(17,3)
	for role in Rules.ENEMY_ECOLOGY_ROLES:
		var actor:Dictionary={"pos":memory_origin,"ecology_role":role}
		memory_fixture.turns=10
		var duration:int=memory_fixture.enemy_memory_duration(actor)
		if memory_fixture.enemy_pursuit_target(actor,known)!=known or actor.get("last_seen_player")!=known:failures.append("memory acquisition "+role)
		memory_fixture.turns=11
		if memory_fixture.enemy_pursuit_target(actor,hidden)!=known or int(actor.get("last_seen_until",-1))!=10+duration:failures.append("memory no hidden refresh "+role)
		memory_fixture.turns=10+duration
		if memory_fixture.enemy_pursuit_target(actor,hidden)!=known:failures.append("memory last valid turn "+role)
		memory_fixture.turns+=1
		if memory_fixture.enemy_pursuit_target(actor,hidden)!=memory_origin or actor.has("last_seen_player"):failures.append("memory expiry "+role)
		memory_fixture.enemy_pursuit_target(actor,known)
		actor.pos=known
		if memory_fixture.enemy_pursuit_target(actor,hidden)!=known or actor.has("last_seen_player"):failures.append("memory reached target "+role)
		checks+=5
	var legacy_actor:Dictionary={"pos":memory_origin}
	if memory_fixture.enemy_pursuit_target(legacy_actor,hidden)!=memory_origin or legacy_actor.has("last_seen_player"):failures.append("legacy memory isolation")
	if memory_fixture.enemy_pursuit_target({"pos":memory_origin,"monster_house":true},hidden)!=hidden:failures.append("house memory isolation")
	checks+=2
	# Exercise the real enemy turn branch: approach old target then stop, not the new location.
	memory_fixture.turns=0
	memory_fixture.player=Vector2i(7,3)
	memory_fixture.enemies.append({"uid":0,"pos":memory_origin,"hp":20,"kind":0,"ecology_role":"hunter","ecology_home":memory_origin})
	memory_fixture.enemy_turn_actions()
	if memory_fixture.enemies[0].pos!=Vector2i(3,3):failures.append("memory initial pursuit")
	memory_fixture.player=hidden
	for expected_x in range(4,8):
		memory_fixture.enemy_turn_actions()
		if memory_fixture.enemies[0].pos!=Vector2i(expected_x,3):failures.append("memory movement")
		checks+=1
	memory_fixture.enemy_turn_actions()
	if memory_fixture.enemies[0].pos!=Vector2i(7,3) or memory_fixture.enemies[0].has("last_seen_player"):failures.append("memory stop after search")
	checks+=2
	print("KINDRIA_ENEMY_MEMORY roles=4 pursuit_steps=5 expiry=4")
	# Visibility must be reciprocal, reject walls and strict diagonal corners.
	var sight=Rules.new()
	for y in range(1,10):
		for x in range(1,10):sight.cells[Vector2i(x,y)]=true
	var eye:=Vector2i(2,3)
	var visible:=Vector2i(5,3)
	var sight_hidden:=Vector2i(5,5)
	if not sight.enemy_line_of_sight(eye,visible) or not sight.enemy_line_of_sight(visible,eye):failures.append("open sight")
	sight.cells.erase(Vector2i(4,3))
	if sight.enemy_line_of_sight(eye,visible) or sight.enemy_line_of_sight(visible,eye):failures.append("wall sight")
	sight.cells[Vector2i(4,3)]=true
	sight.cells.erase(Vector2i(3,3))
	if sight.enemy_line_of_sight(eye,Vector2i(3,4)) or sight.enemy_line_of_sight(Vector2i(3,4),eye):failures.append("corner sight")
	sight.cells[Vector2i(3,3)]=true
	if not sight.enemy_line_of_sight(eye,Vector2i(3,4)):failures.append("open diagonal sight")
	checks+=4
	var watcher:Dictionary={"pos":eye,"ecology_role":"scout"}
	sight.turns=1
	if sight.enemy_pursuit_target(watcher,visible)!=visible:failures.append("sight acquisition")
	sight.cells.erase(Vector2i(3,4))
	sight.turns=2
	if sight.enemy_line_of_sight(eye,sight_hidden) or sight.enemy_pursuit_target(watcher,sight_hidden)!=visible or int(watcher.get("last_seen_until",0))!=7:failures.append("wall memory")
	sight.cells[Vector2i(3,4)]=true
	if sight.enemy_pursuit_target(watcher,sight_hidden)!=sight_hidden or watcher.get("last_seen_player")!=sight_hidden:failures.append("sight reacquisition")
	checks+=3
	var sight_pairs:int=0
	for seed_id in range(128):
		var layout=Rules.new()
		layout.setup(seed_id%3,24,0,false,false,310003+seed_id,0,false)
		for e in layout.enemies:
			var p:Vector2i=e.pos
			for d in [Vector2i(1,1),Vector2i(3,2),Vector2i(-2,3),Vector2i(0,-3),Vector2i(-3,-2)]:
				var q:Vector2i=p+d
				if layout.enemy_line_of_sight(p,q)!=layout.enemy_line_of_sight(q,p):failures.append("asymmetric sight")
				sight_pairs+=1
		checks+=1
	print("KINDRIA_ENEMY_SIGHT seeded_pairs=",sight_pairs," fixtures=7")
	# Local search explores only the remembered neighborhood with a finite turn budget.
	var search_fixture=Rules.new()
	for y in range(1,10):
		for x in range(1,20):search_fixture.cells[Vector2i(x,y)]=true
	var search_anchor:=Vector2i(4,4)
	var remote_player:=Vector2i(19,9)
	search_fixture.player=remote_player
	search_fixture.stairs=Vector2i(5,4)
	search_fixture.relic=Vector2i(4,5)
	search_fixture.traps[Vector2i(3,4)]="spike"
	var search_steps:int=0
	for role in Rules.ENEMY_ECOLOGY_ROLES:
		var search_actor:Dictionary={"uid":0,"pos":search_anchor,"ecology_role":role,"ecology_search_enabled":true,"last_seen_player":search_anchor,"last_seen_until":20}
		search_fixture.turns=10
		var budget:int=3 if role=="scout" else 1 if role=="sentry" else 2
		var visited_search:Dictionary={search_anchor:true}
		for tick in range(budget):
			var from:Vector2i=search_actor.pos
			var candidate:Vector2i=search_fixture.enemy_pursuit_target(search_actor,remote_player)
			if candidate==from or visited_search.has(candidate) or search_fixture.distance(from,candidate)!=1 or search_fixture.distance(search_anchor,candidate)>(3 if role=="scout" else 2) or candidate==search_fixture.stairs or candidate==search_fixture.relic or search_fixture.traps.has(candidate):failures.append("local search step "+role)
			visited_search[candidate]=true;search_actor.pos=candidate
			search_fixture.turns+=1;search_steps+=1
			checks+=1
		if search_fixture.enemy_pursuit_target(search_actor,remote_player)!=search_actor.pos or search_actor.has("search_anchor"):failures.append("local search expiry "+role)
		checks+=1
	var reacquire_actor:Dictionary={"uid":0,"pos":search_anchor,"ecology_role":"scout","ecology_search_enabled":true,"last_seen_player":search_anchor,"last_seen_until":20}
	search_fixture.turns=10
	search_fixture.enemy_pursuit_target(reacquire_actor,remote_player)
	var new_target:=Vector2i(4,2)
	if not reacquire_actor.has("search_anchor") or search_fixture.enemy_pursuit_target(reacquire_actor,new_target)!=new_target or reacquire_actor.has("search_anchor") or reacquire_actor.get("last_seen_player")!=new_target:failures.append("local search reacquisition")
	checks+=1
	print("KINDRIA_ENEMY_SEARCH roles=4 steps=",search_steps)
	# Tactical ranged enemy must sidestep to acquire a real firing lane, not gain an extra action.
	var tactics_fixture=Rules.new()
	for y in range(1,8):
		for x in range(1,9):tactics_fixture.cells[Vector2i(x,y)]=true
	var firing_origin:=Vector2i(2,3)
	var firing_tile:=Vector2i(2,4)
	tactics_fixture.player=Vector2i(5,4)
	tactics_fixture.stairs=Vector2i(8,7)
	tactics_fixture.relic=Vector2i(8,6)
	var ranged_actor:Dictionary={"uid":0,"pos":firing_origin,"hp":20,"kind":1,"species":"leafwisp","ecology_role":"scout","ecology_search_enabled":true}
	tactics_fixture.enemies.append(ranged_actor)
	tactics_fixture.enemies.append({"uid":1,"pos":Vector2i(3,3),"hp":20,"kind":0,"sleep_turns":99})
	if tactics_fixture.enemy_tactical_step(ranged_actor,tactics_fixture.player,"line",3)!=firing_tile:failures.append("tactical firing lane")
	checks+=1
	tactics_fixture.traps[firing_tile]="spike"
	if tactics_fixture.enemy_tactical_step(ranged_actor,tactics_fixture.player,"line",3)!=firing_origin:failures.append("tactical trap avoidance")
	tactics_fixture.traps.clear()
	tactics_fixture.cells.erase(Vector2i(3,4))
	if tactics_fixture.enemy_tactical_step(ranged_actor,tactics_fixture.player,"line",3)!=firing_origin:failures.append("tactical occlusion")
	tactics_fixture.cells[Vector2i(3,4)]=true
	checks+=2
	tactics_fixture.enemy_turn_actions()
	if ranged_actor.pos!=firing_tile:failures.append("tactical real turn movement")
	var tactical_moves:int=0
	var tactical_attacks:int=0
	for action in tactics_fixture.enemy_actions:
		if int(action.get("uid",-1))!=0:continue
		if action.get("phase","")=="move":tactical_moves+=1
		if action.get("phase","")=="attack":tactical_attacks+=1
	if tactical_moves!=1 or tactical_attacks!=0:failures.append("tactical one action")
	checks+=2
	tactics_fixture.enemy_turn_actions()
	var acquired_attack:bool=false
	for action in tactics_fixture.enemy_actions:
		if int(action.get("uid",-1))==0 and action.get("phase","")=="attack":acquired_attack=true
	if not acquired_attack:failures.append("tactical next turn attack")
	checks+=1
	print("KINDRIA_TACTICAL_AI lane=1 forbidden=2 turn_actions=3")
	# Elemental choice must use legal moves and never consume PP while evaluating.
	var choice_fixture=Rules.new()
	for y in range(1,7):
		for x in range(1,7):choice_fixture.cells[Vector2i(x,y)]=true
	choice_fixture.player=Vector2i(4,3)
	choice_fixture.trained_profile={"types":["ground"],"level":24,"nature":0,"ev":[0,0,0,0,0,0]}
	var choice_actor:Dictionary={"uid":0,"pos":Vector2i(3,3),"hp":30,"kind":1,"species":"jellymancer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":10}
	choice_fixture.enemies.append(choice_actor)
	var primary_skill:Array=choice_fixture.signature_skill(choice_actor)
	var secondary_skill:Array=[1,false,3,-1,"none",0,"alt_jellymancer"]
	var score_primary:float=choice_fixture.enemy_attack_score(choice_actor,primary_skill,false)
	var score_secondary:float=choice_fixture.enemy_attack_score(choice_actor,secondary_skill,true)
	if score_secondary<=score_primary+.25:failures.append("combat elemental ranking")
	if choice_actor.pp_primary!=12 or choice_actor.pp_secondary!=10:failures.append("combat scoring PP purity")
	checks+=2
	choice_fixture.enemy_turn_actions()
	if choice_actor.get("last_move_slot","")!="secondary" or choice_actor.pp_secondary!=9 or choice_actor.pp_primary!=12:failures.append("combat actual secondary choice")
	checks+=1
	choice_actor["alt_cooldown"]=0;choice_actor["pp_secondary"]=0
	choice_fixture.enemy_turn_actions()
	if choice_actor.get("last_move_slot","")!="primary" or choice_actor.pp_primary!=11 or choice_actor.pp_secondary!=0:failures.append("combat depleted PP fallback")
	checks+=1
	choice_fixture.trained_profile["types"]=["water"]
	if choice_fixture.enemy_attack_score(choice_actor,primary_skill,false)<=choice_fixture.enemy_attack_score(choice_actor,secondary_skill,true):failures.append("combat matchup reversal")
	checks+=1
	choice_actor["pp_secondary"]=10
	var abundant_score:float=choice_fixture.enemy_attack_score(choice_actor,secondary_skill,true)
	choice_actor["pp_secondary"]=1
	if choice_fixture.enemy_attack_score(choice_actor,secondary_skill,true)>=abundant_score:failures.append("combat scarce PP conservation")
	checks+=1
	print("KINDRIA_COMBAT_CHOICE elemental=2 pp=3 action=1")
	# A blocked melee creature must take a separate route, not stack behind its partner.
	var pack_fixture=Rules.new()
	for y in range(1,8):
		for x in range(1,8):pack_fixture.cells[Vector2i(x,y)]=true
	pack_fixture.player=Vector2i(5,4)
	pack_fixture.stairs=Vector2i(7,7)
	pack_fixture.relic=Vector2i(7,6)
	var pack_origin:=Vector2i(3,4)
	var pack_actor:Dictionary={"uid":0,"pos":pack_origin,"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":0}
	var pack_partner:Dictionary={"uid":1,"pos":Vector2i(4,4),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true}
	pack_fixture.enemies.append(pack_actor);pack_fixture.enemies.append(pack_partner)
	var pack_step:Vector2i=pack_fixture.enemy_cooperative_step(pack_actor,pack_fixture.player,"front",1)
	if pack_step not in [Vector2i(3,3),Vector2i(3,5)] or pack_actor.pos!=pack_origin or pack_actor.pp_primary!=12:failures.append("cooperative flank and purity")
	checks+=1
	pack_fixture.traps[pack_step]="spike"
	var safer_step:Vector2i=pack_fixture.enemy_cooperative_step(pack_actor,pack_fixture.player,"front",1)
	if safer_step==pack_step or safer_step==pack_origin:failures.append("cooperative alternate safe flank")
	pack_fixture.traps.clear()
	checks+=1
	pack_partner["sleep_turns"]=99
	if pack_fixture.enemy_cooperative_step(pack_actor,pack_fixture.player,"front",1)!=pack_origin:failures.append("cooperative inactive partner")
	pack_partner.erase("sleep_turns")
	checks+=1
	pack_fixture.cells.erase(Vector2i(3,3));pack_fixture.cells.erase(Vector2i(3,5))
	if pack_fixture.enemy_cooperative_step(pack_actor,pack_fixture.player,"front",1)!=pack_origin:failures.append("cooperative blocked corridor")
	pack_fixture.cells[Vector2i(3,3)]=true;pack_fixture.cells[Vector2i(3,5)]=true
	checks+=1
	pack_fixture.enemy_turn_actions()
	var pack_moves:int=0
	var pack_attacks:int=0
	for action in pack_fixture.enemy_actions:
		if int(action.get("uid",-1))!=0:continue
		if action.get("phase","")=="move":pack_moves+=1
		if action.get("phase","")=="attack":pack_attacks+=1
	if pack_moves!=1 or pack_attacks!=0 or pack_actor.pos not in [Vector2i(3,3),Vector2i(3,5)] or pack_actor.pp_primary!=12:failures.append("cooperative actual one turn")
	checks+=1
	# Already valid attack lanes must never be abandoned just for formation spacing.
	pack_actor.pos=Vector2i(5,3)
	if pack_fixture.enemy_cooperative_step(pack_actor,pack_fixture.player,"front",1)!=pack_actor.pos:failures.append("cooperative preserve valid attack")
	checks+=1
	print("KINDRIA_COOPERATIVE_AI flank=2 gates=2 turn=1 preserve=1")
	# Injured cautious species retreat briefly; aggressive and boss species stand their ground.
	var survival_fixture=Rules.new()
	for y in range(1,8):
		for x in range(1,8):survival_fixture.cells[Vector2i(x,y)]=true
	survival_fixture.player=Vector2i(4,4)
	survival_fixture.stairs=Vector2i(7,7)
	survival_fixture.relic=Vector2i(7,6)
	var survival_origin:=Vector2i(3,4)
	var survivor:Dictionary={"uid":0,"pos":survival_origin,"hp":6,"max_hp":30,"kind":1,"species":"leafwisp","ecology_role":"scout","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":10,"cooldown":2}
	survival_fixture.enemies.append(survivor)
	var retreat_step:Vector2i=survival_fixture.enemy_retreat_step(survivor,survival_fixture.player)
	if survival_fixture.distance(retreat_step,survival_fixture.player)!=2 or survivor.pos!=survival_origin or survivor.hp!=6 or survivor.pp_primary!=12:failures.append("survival cautious retreat purity")
	checks+=1
	survivor["species"]="bramble_pup"
	if survival_fixture.enemy_retreat_step(survivor,survival_fixture.player)!=survival_origin:failures.append("survival aggressive courage")
	survivor["species"]="shellguard"
	if survival_fixture.enemy_survival_profile(survivor)!="defensive" or survival_fixture.enemy_retreat_step(survivor,survival_fixture.player)!=survival_origin:failures.append("survival defensive hold")
	survivor["species"]="leafwisp"
	checks+=2
	for gate in ["windup","monster_house","stuck_turns","retreat_steps"]:
		survivor[gate]=2 if gate=="retreat_steps" else 1 if gate=="stuck_turns" else true
		if survival_fixture.enemy_retreat_step(survivor,survival_fixture.player)!=survival_origin:failures.append("survival gate "+gate)
		survivor.erase(gate)
		checks+=1
	survivor["hp"]=15
	if survival_fixture.enemy_retreat_step(survivor,survival_fixture.player)!=survival_origin:failures.append("survival healthy hold")
	survivor["hp"]=6
	checks+=1
	survival_fixture.traps[retreat_step]="spike"
	var alternative_retreat:Vector2i=survival_fixture.enemy_retreat_step(survivor,survival_fixture.player)
	if alternative_retreat==retreat_step or alternative_retreat==survival_origin:failures.append("survival trap avoidance")
	survival_fixture.traps.clear()
	checks+=1
	survival_fixture.enemy_turn_actions()
	var survival_moves:int=0
	var survival_attacks:int=0
	for action in survival_fixture.enemy_actions:
		if int(action.get("uid",-1))!=0:continue
		if action.get("phase","")=="move":survival_moves+=1
		if action.get("phase","")=="attack":survival_attacks+=1
	if survival_moves!=1 or survival_attacks!=0 or survivor.get("retreat_steps",0)!=1 or survivor.pp_primary!=12 or survivor.cooldown!=1:failures.append("survival actual retreat turn")
	checks+=1
	survival_fixture.enemy_turn_actions()
	if survivor.get("retreat_steps",0)!=2 or survival_fixture.enemy_retreat_step(survivor,survival_fixture.player)!=survivor.pos:failures.append("survival bounded retreat")
	checks+=1
	survivor["hp"]=20
	survival_fixture.enemy_turn_actions()
	if survivor.has("retreat_steps"):failures.append("survival rearm after recovery")
	checks+=1
	print("KINDRIA_SURVIVAL_AI profiles=3 gates=5 turn=1 budget=2 safety=1")
	# A defensive creature physically occupies the attack lane of an injured partner.
	var protector_fixture=Rules.new()
	for y in range(1,8):
		for x in range(1,8):protector_fixture.cells[Vector2i(x,y)]=true
	protector_fixture.player=Vector2i(5,4)
	protector_fixture.stairs=Vector2i(7,7)
	protector_fixture.relic=Vector2i(7,6)
	var protector_origin:=Vector2i(3,3)
	var screen_tile:=Vector2i(3,4)
	var defender:Dictionary={"uid":0,"pos":protector_origin,"hp":30,"max_hp":30,"kind":2,"species":"shellguard","ecology_role":"sentry","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":10}
	var wounded_friend:Dictionary={"uid":1,"pos":Vector2i(2,4),"hp":5,"max_hp":30,"kind":1,"species":"leafwisp","major_status":"freeze"}
	protector_fixture.enemies.append(defender);protector_fixture.enemies.append(wounded_friend)
	if protector_fixture.enemy_protector_step(defender,protector_fixture.player)!=screen_tile or defender.pos!=protector_origin or defender.pp_primary!=12:failures.append("protector screen selection purity")
	checks+=1
	wounded_friend["hp"]=20
	if protector_fixture.enemy_protector_step(defender,protector_fixture.player)!=protector_origin:failures.append("protector healthy partner")
	wounded_friend["hp"]=5
	checks+=1
	defender["species"]="bramble_pup"
	if protector_fixture.enemy_protector_step(defender,protector_fixture.player)!=protector_origin:failures.append("protector personality")
	defender["species"]="shellguard"
	checks+=1
	protector_fixture.traps[screen_tile]="spike"
	if protector_fixture.enemy_protector_step(defender,protector_fixture.player)!=protector_origin:failures.append("protector hazard")
	protector_fixture.traps.clear()
	checks+=1
	protector_fixture.cells.erase(Vector2i(4,4))
	if protector_fixture.enemy_protector_step(defender,protector_fixture.player)!=protector_origin:failures.append("protector occlusion")
	protector_fixture.cells[Vector2i(4,4)]=true
	checks+=1
	protector_fixture.enemies.append({"uid":2,"pos":Vector2i(4,4),"hp":20,"kind":0})
	if protector_fixture.enemy_protector_step(defender,protector_fixture.player)!=protector_origin:failures.append("protector existing screen")
	protector_fixture.enemies.pop_back()
	checks+=1
	var before_screen:Dictionary=protector_fixture.attack_footprint(protector_fixture.player,Vector2i.LEFT,"line",4,true)
	if not before_screen.has(wounded_friend.pos):failures.append("protector initial open attack lane")
	checks+=1
	protector_fixture.enemy_turn_actions()
	var screen_moves:int=0
	var screen_attacks:int=0
	for action in protector_fixture.enemy_actions:
		if int(action.get("uid",-1))!=0:continue
		if action.get("phase","")=="move":screen_moves+=1
		if action.get("phase","")=="attack":screen_attacks+=1
	if defender.pos!=screen_tile or screen_moves!=1 or screen_attacks!=0 or defender.pp_primary!=12 or defender.pp_secondary!=10:failures.append("protector actual movement turn")
	checks+=1
	var after_screen:Dictionary=protector_fixture.attack_footprint(protector_fixture.player,Vector2i.LEFT,"line",4,true)
	if not after_screen.has(screen_tile) or after_screen.has(wounded_friend.pos):failures.append("protector physical attack interception")
	checks+=1
	print("KINDRIA_PROTECTOR_AI selection=1 gates=5 lane=2 action=1")
	# Terrain control is a learned, PP-limited move, not a universal enemy power.
	var control_fixture=Rules.new()
	for y in range(1,6):
		for x in range(1,9):control_fixture.cells[Vector2i(x,y)]=true
	control_fixture.player=Vector2i(3,3)
	control_fixture.stairs=Vector2i(8,5)
	control_fixture.relic=Vector2i(8,4)
	var controller:Dictionary={"uid":0,"pos":Vector2i(2,3),"hp":30,"max_hp":30,"kind":1,"species":"sylphowl","ecology_role":"scout","ecology_search_enabled":true,"control_move":"eos_268","pp_control":5}
	control_fixture.enemies.append(controller)
	control_fixture.traps[Vector2i(5,3)]="snare"
	var push_plan:Dictionary=control_fixture.enemy_push_plan(controller,control_fixture.player)
	if push_plan.get("kind","")!="trap" or push_plan.get("destination")!=Vector2i(5,3) or controller.pp_control!=5 or control_fixture.player!=Vector2i(3,3):failures.append("control prediction and purity")
	checks+=1
	controller.erase("control_move")
	if control_fixture.enemy_execute_control(0):failures.append("control unlearned move")
	controller["control_move"]="eos_268"
	checks+=1
	controller["pp_control"]=0
	if control_fixture.enemy_execute_control(0):failures.append("control no PP")
	controller["pp_control"]=5
	checks+=1
	controller["sealed_moves"]=["control"]
	if control_fixture.enemy_execute_control(0):failures.append("control sealed move")
	controller.erase("sealed_moves")
	checks+=1
	control_fixture.shield_kind="protect";control_fixture.shield_turns=2
	if control_fixture.enemy_execute_control(0):failures.append("control protected player")
	control_fixture.shield_kind="";control_fixture.shield_turns=0
	checks+=1
	# Use an accuracy stage to make the fixture deterministic independently of seed.
	controller["stages"]={"accuracy":10}
	control_fixture.enemy_turn_actions()
	var control_actions:int=0
	for action in control_fixture.enemy_actions:
		if int(action.get("uid",-1))==0:control_actions+=1
	if control_actions!=1 or controller.pp_control!=4 or controller.get("control_cooldown",0)!=3 or control_fixture.player!=Vector2i(5,3) or control_fixture.traps.has(Vector2i(5,3)) or control_fixture.player_slow_turns<=0:failures.append("control actual trap push")
	checks+=1
	control_fixture.player=Vector2i(3,3)
	controller["control_cooldown"]=0
	control_fixture.allies.append({"pos":Vector2i(5,3),"hp":20,"max_hp":20})
	var party_plan:Dictionary=control_fixture.enemy_push_plan(controller,control_fixture.player)
	if party_plan.get("kind","")!="party" or party_plan.get("destination")!=Vector2i(4,3):failures.append("control party collision prediction")
	checks+=1
	if not control_fixture.enemy_execute_control(0) or control_fixture.player!=Vector2i(4,3) or int(control_fixture.allies[0].hp)!=15 or controller.pp_control!=3:failures.append("control party collision execution")
	checks+=1
	control_fixture.allies.clear()
	control_fixture.player=Vector2i(3,3)
	control_fixture.enemies.append({"uid":1,"pos":Vector2i(5,3),"hp":20,"kind":0})
	if int(control_fixture.enemy_push_plan(controller,control_fixture.player).get("score",0))>=5:failures.append("control avoid friendly collision")
	checks+=1
	var exit_fixture=Rules.new()
	for x in range(1,7):exit_fixture.cells[Vector2i(x,3)]=true
	exit_fixture.player=Vector2i(3,3)
	var exit_actor:Dictionary={"uid":0,"pos":Vector2i(5,3),"hp":20,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":0}
	exit_fixture.enemies.append(exit_actor)
	if exit_fixture.enemy_exit_block_step(exit_actor,exit_fixture.player)!=Vector2i(4,3):failures.append("control exit interception")
	checks+=1
	exit_fixture.traps[Vector2i(4,3)]="snare"
	if exit_fixture.enemy_exit_block_step(exit_actor,exit_fixture.player)!=exit_actor.pos:failures.append("control exit hazard")
	exit_fixture.traps.clear()
	checks+=1
	exit_fixture.enemy_turn_actions()
	if exit_actor.pos!=Vector2i(4,3) or exit_fixture.enemy_actions.size()!=1 or exit_fixture.enemy_actions[0].get("phase","")!="move":failures.append("control actual exit block")
	checks+=1
	print("KINDRIA_TERRAIN_CONTROL push=9 exit=3")
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
