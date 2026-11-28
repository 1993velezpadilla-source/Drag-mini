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

func ai_cache_fixture(sample:int,enabled:bool):
	var arena=Rules.new()
	arena.ai_cache_enabled=enabled
	arena.rng.seed=717000+sample
	arena.monster_house_rng.seed=818000+sample
	for y in range(1,10):
		for x in range(1,10):arena.cells[Vector2i(x,y)]=true
	arena.rooms.append(Rect2i(1,1,9,9))
	arena.player=Vector2i(5,5);arena.stairs=Vector2i(9,9);arena.relic=Vector2i(9,8)
	arena.hp=10000;arena.max_hp=10000
	arena.region=sample%3;arena.floor_number=3;arena.tier=sample%3
	arena.monster_house_room=0;arena.monster_house_profile=sample%6
	if sample%2==0:
		arena.allies.append({"uid":1000,"pos":Vector2i(4,5),"hp":100,"max_hp":100,"species":"reef_pup","moves":[],"pp":{},"stages":{},"status":{}})
	arena.trigger_monster_house()
	return arena

func ai_cache_regressions(failures:Array[String])->int:
	var count:int=0
	var total_hits:int=0
	var total_misses:int=0
	var cached_usec:int=0
	var reference_usec:int=0
	for sample in range(18):
		var cached=ai_cache_fixture(sample,true)
		var reference=ai_cache_fixture(sample,false)
		for turn in range(12):
			if cached.finished or reference.finished:break
			var started:int=Time.get_ticks_usec()
			cached.enemy_turn()
			cached_usec+=Time.get_ticks_usec()-started
			started=Time.get_ticks_usec()
			reference.enemy_turn()
			reference_usec+=Time.get_ticks_usec()-started
			total_hits+=cached.ai_cache_hits
			total_misses+=cached.ai_cache_misses
			if cached.enemies!=reference.enemies or cached.allies!=reference.allies or cached.player!=reference.player or cached.hp!=reference.hp or cached.enemy_actions!=reference.enemy_actions or cached.player_boons!=reference.player_boons or cached.rng.state!=reference.rng.state or cached.traps!=reference.traps or cached.finished!=reference.finished:failures.append("cache behavior mismatch %d:%d"%[sample,turn])
			if cached.ai_cache_active or cached.ai_actor_cache_active or not cached.ai_los_cache.is_empty() or not cached.ai_footprint_cache.is_empty() or not cached.ai_terrain_cache.is_empty() or not cached.ai_occupancy_cache.is_empty():failures.append("cache escaped enemy turn")
			count+=2
	var scope=Rules.new()
	for x in range(1,7):scope.cells[Vector2i(x,3)]=true
	scope.enemies.append({"pos":Vector2i(3,3),"hp":20})
	scope.ai_begin_turn_cache();scope.ai_begin_actor_cache()
	var ray:Dictionary=scope.attack_footprint(Vector2i(1,3),Vector2i.RIGHT,"line",5)
	if ray.has(Vector2i(4,3)) or not scope.navigation_occupancy().has(Vector2i(3,3)):failures.append("cache original occupancy")
	count+=1
	scope.enemies[0].pos=Vector2i(5,3)
	scope.ai_begin_actor_cache()
	var new_ray:Dictionary=scope.attack_footprint(Vector2i(1,3),Vector2i.RIGHT,"line",5)
	if not new_ray.has(Vector2i(4,3)) or new_ray.has(Vector2i(5,3)) or scope.navigation_occupancy().has(Vector2i(3,3)) or not scope.navigation_occupancy().has(Vector2i(5,3)):failures.append("cache refreshed after actor movement")
	count+=1
	if not scope.enemy_line_of_sight(Vector2i(1,3),Vector2i(6,3)) or not scope.ai_terrain_distances(Vector2i(6,3)).has(Vector2i(1,3)):failures.append("cache terrain initial")
	count+=1
	scope.ai_end_turn_cache()
	scope.cells.erase(Vector2i(3,3))
	scope.ai_begin_turn_cache()
	if scope.enemy_line_of_sight(Vector2i(1,3),Vector2i(6,3)) or scope.ai_terrain_distances(Vector2i(6,3)).has(Vector2i(1,3)):failures.append("cache terrain invalidation")
	scope.ai_end_turn_cache()
	count+=1
	scope.hp=1;scope.poison_turns=1
	scope.enemy_turn_actions()
	if scope.ai_cache_active or scope.ai_actor_cache_active:failures.append("cache early return cleanup")
	count+=1
	if total_hits<=0:failures.append("cache never reused")
	count+=1
	print("KINDRIA_AI_CACHE comparisons=",count," hits=",total_hits," misses=",total_misses," cached_usec=",cached_usec," uncached_usec=",reference_usec)
	return count

# Differential paths include disconnected terrain, crowding and tie cases.
func ai_path_regressions(failures:Array[String])->int:
	var checks_local:int=0
	var expanded_reference:int=0
	var expanded_optimized:int=0
	var fast_count:int=0
	var reuse_count:int=0
	var path_rng:=RandomNumberGenerator.new()
	path_rng.seed=663001
	for sample in range(128):
		var arena=Rules.new()
		for y in range(1,10):
			for x in range(1,10):
				if path_rng.randi_range(0,99)>=23:arena.cells[Vector2i(x,y)]=true
		var origin:=Vector2i(1+sample%3,1+sample%7)
		var target:=Vector2i(7+sample%3,7+sample%3)
		if sample%4==0:target=Vector2i(9,origin.y)
		arena.cells[origin]=true;arena.cells[target]=true
		arena.player=target
		for j in range(5):
			var tile:=Vector2i(path_rng.randi_range(1,9),path_rng.randi_range(1,9))
			if tile!=origin and tile!=target and arena.cells.has(tile) and arena.enemy_at(tile)<0:
				arena.enemies.append({"uid":j,"pos":tile,"hp":20})
		arena.ai_cache_enabled=false;arena.ai_begin_turn_cache();arena.ai_begin_actor_cache()
		var reference:Array[Vector2i]=arena.enemy_approach_route(origin,target)
		var diagonal_reference:Array[Vector2i]=arena.route(origin,target,true,true)
		expanded_reference+=arena.ai_path_nodes
		arena.ai_end_turn_cache()
		arena.ai_cache_enabled=true;arena.ai_begin_turn_cache();arena.ai_begin_actor_cache()
		var optimized:Array[Vector2i]=arena.enemy_approach_route(origin,target)
		var diagonal_optimized:Array[Vector2i]=arena.route(origin,target,true,true)
		expanded_optimized+=arena.ai_path_nodes
		fast_count+=arena.ai_path_fast_routes;reuse_count+=arena.ai_path_reused_searches
		if optimized!=reference:failures.append("path cardinal equivalence %d"%sample)
		if diagonal_optimized!=diagonal_reference:failures.append("path diagonal tie equivalence %d"%sample)
		arena.ai_end_turn_cache()
		checks_local+=2
	# Guaranteed straight and blocked-corridor cases exercise both fast paths.
	var corridor=Rules.new()
	for x in range(1,9):corridor.cells[Vector2i(x,3)]=true
	corridor.player=Vector2i(8,3)
	corridor.ai_begin_turn_cache();corridor.ai_begin_actor_cache()
	var straight:Array[Vector2i]=corridor.enemy_approach_route(Vector2i(1,3),corridor.player)
	if straight.size()!=7 or corridor.ai_path_fast_routes!=1 or corridor.ai_path_nodes!=0:failures.append("path straight unique shortest")
	corridor.ai_end_turn_cache()
	checks_local+=1
	corridor.enemies.append({"pos":Vector2i(5,3),"hp":20})
	corridor.ai_cache_enabled=false;corridor.ai_begin_turn_cache();corridor.ai_begin_actor_cache()
	var blocked_reference:Array[Vector2i]=corridor.enemy_approach_route(Vector2i(1,3),corridor.player)
	var blocked_nodes:int=corridor.ai_path_nodes
	corridor.ai_end_turn_cache()
	corridor.ai_cache_enabled=true;corridor.ai_begin_turn_cache();corridor.ai_begin_actor_cache()
	var blocked_optimized:Array[Vector2i]=corridor.enemy_approach_route(Vector2i(1,3),corridor.player)
	if blocked_optimized!=blocked_reference or blocked_optimized.size()!=3 or corridor.ai_path_reused_searches!=1 or corridor.ai_path_nodes>=blocked_nodes:failures.append("path blocked search reuse")
	corridor.ai_end_turn_cache()
	checks_local+=1
	print("KINDRIA_PATH_OPTIMIZATION checks=",checks_local," reference_nodes=",expanded_reference," optimized_nodes=",expanded_optimized," fast=",fast_count," reused=",reuse_count)
	return checks_local

# End-to-end adversarial turn checks, with mixed House profiles and terrain.
func enemy_adversarial_gauntlet(failures:Array[String])->int:
	var checks_local:int=0
	var samples:int=0
	var timings:Array[int]=[]
	for sample in range(18):
		var arena=ai_cache_fixture(sample,true)
		arena.belly_tenths=1000
		for round_index in range(8):
			if arena.finished:break
			var before:Dictionary={}
			for e in arena.enemies:
				before[int(e.uid)]={"pos":e.pos,"primary":arena.enemy_move_pp(e,"primary"),"secondary":arena.enemy_move_pp(e,"secondary"),"support":arena.enemy_move_pp(e,"support"),"control":arena.enemy_move_pp(e,"control")}
			# Alternate protection, stationary play, and legal voluntary movement.
			arena.shield_kind="protect" if round_index%4==1 else ""
			arena.shield_turns=1 if round_index%4==1 else 0
			if round_index%2==0:
				for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
					var q:Vector2i=arena.player+d
					if arena.cells.has(q) and arena.enemy_at(q)<0 and arena.ally_at(q)<0:
						arena.adaptive_walk_from=arena.player;arena.adaptive_walk_to=q;arena.adaptive_walk_turn=arena.turns
						arena.player=q;break
			var start:int=Time.get_ticks_usec()
			arena.enemy_turn_actions()
			timings.append(Time.get_ticks_usec()-start)
			var acted:Dictionary={}
			for action in arena.enemy_actions:
				var uid:int=int(action.get("uid",-1))
				acted[uid]=int(acted.get(uid,0))+1
			var one_action:bool=true
			for uid in acted:
				if int(acted[uid])>1:one_action=false
			if not one_action:failures.append("adversarial duplicate actor action %d:%d"%[sample,round_index])
			checks_local+=1
			var positions:Dictionary={}
			var legal:bool=true
			var pp_legal:bool=true
			for e in arena.enemies:
				if int(e.hp)<=0:continue
				var uid:int=int(e.uid)
				if not arena.cells.has(e.pos) or positions.has(e.pos) or e.pos==arena.player or arena.ally_at(e.pos)>=0:legal=false
				positions[e.pos]=true
				if not before.has(uid):continue
				var spent:int=0
				for slot in ["primary","secondary","support","control"]:
					var remaining:int=arena.enemy_move_pp(e,slot)
					if remaining<0 or remaining>int(before[uid][slot]):pp_legal=false
					spent+=maxi(0,int(before[uid][slot])-remaining)
				if spent>1:pp_legal=false
			if not legal:failures.append("adversarial occupied or invalid position %d:%d"%[sample,round_index])
			checks_local+=1
			if not pp_legal:failures.append("adversarial invalid PP budget %d:%d"%[sample,round_index])
			checks_local+=1
			if arena.ai_cache_active or arena.ai_actor_cache_active or not arena.ai_occupancy_cache.is_empty():failures.append("adversarial cache leak %d:%d"%[sample,round_index])
			checks_local+=1
			samples+=1
	if not timings.is_empty():
		timings.sort()
		print("KINDRIA_ENEMY_ADVERSARIAL turns=",samples," checks=",checks_local," median_usec=",timings[int(timings.size()/2)]," p95_usec=",timings[int((timings.size()-1)*.95)]," max_usec=",timings.back())
	return checks_local

# Long-running deterministic integration: identical inputs with and without caches.
func enemy_integration_input(arena,round_index:int,sample:int)->void:
	arena.shield_kind="protect" if round_index%7==3 else ""
	arena.shield_turns=1 if round_index%7==3 else 0
	if round_index%3==0:
		var directions:Array=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
		for offset in range(4):
			var q:Vector2i=arena.player+directions[(offset+sample+round_index)%4]
			if not arena.cells.has(q) or arena.enemy_at(q)>=0 or arena.ally_at(q)>=0:continue
			arena.adaptive_walk_from=arena.player;arena.adaptive_walk_to=q;arena.adaptive_walk_turn=arena.turns
			arena.player=q;break
	# Controlled casualty, PP scarcity and interruption fixtures.
	if round_index==4 and not arena.enemies.is_empty():
		var e:Dictionary=arena.enemies[0]
		e.hp=maxi(1,int(float(e.hp)/3.0))
		e["incoming_turn"]=arena.turns;e["incoming_damage"]=int(e.hp)
	if round_index==9 and arena.enemies.size()>1:
		arena.enemies[1]["pp_primary"]=0;arena.enemies[1]["pp_secondary"]=0
	if round_index==14 and arena.enemies.size()>2:arena.enemies[2]["sleep_turns"]=2
	if round_index==19 and arena.enemies.size()>3:arena.enemies[3].hp=0
	if round_index==22 and arena.enemies.size()>2:arena.enemies[2]["sleep_turns"]=0

func enemy_integration_gauntlet(failures:Array[String])->int:
	var checks_local:int=0
	var samples:int=0
	var personalities:Dictionary={}
	var cached_times:Array[int]=[]
	var reference_times:Array[int]=[]
	var idle_peak:int=0
	var reversal_count:int=0
	var idle_open_peak:int=0
	var reserve_idle_observations:int=0
	var congestion_observations:int=0
	var unresolved_after_congestion_peak:int=0
	var unexplained_open_peak:int=0
	var unexplained_context:Dictionary={}
	var idle_observations:Dictionary={}
	var idle_peak_context:Dictionary={}
	var reversal_species:Dictionary={}
	var species:Array=["rootgnawer","bramble_pup","mossmite","sporeling","leafwisp","fungal_monarch"]
	var expected:Array=["territorial","hunter","defender","opportunist","cautious","steadfast"]
	for sample in range(18):
		var cached=ai_cache_fixture(sample,true)
		var reference=ai_cache_fixture(sample,false)
		for arena in [cached,reference]:
			arena.belly_tenths=1000
			for index in range(mini(species.size(),arena.enemies.size())):
				var e:Dictionary=arena.enemies[index]
				e.species=species[index]
				e["personality_enabled"]=true
				e["house_role"]=arena.house_tactical_role(e)
				personalities[arena.enemy_combat_personality(e)]=true
		var idle:Dictionary={}
		var idle_open:Dictionary={}
		var unexplained_open:Dictionary={}
		var unresolved_after_congestion:Dictionary={}
		var previous_moves:Dictionary={}
		for round_index in range(32):
			if cached.finished or reference.finished:break
			enemy_integration_input(cached,round_index,sample)
			enemy_integration_input(reference,round_index,sample)
			var start:int=Time.get_ticks_usec()
			cached.enemy_turn_actions()
			cached_times.append(Time.get_ticks_usec()-start)
			start=Time.get_ticks_usec()
			reference.enemy_turn_actions()
			reference_times.append(Time.get_ticks_usec()-start)
			if cached.enemies!=reference.enemies or cached.allies!=reference.allies or cached.player!=reference.player or cached.hp!=reference.hp or cached.enemy_actions!=reference.enemy_actions or cached.rng.state!=reference.rng.state or cached.player_boons!=reference.player_boons or cached.traps!=reference.traps or cached.finished!=reference.finished:
				failures.append("integration deterministic state mismatch %d:%d"%[sample,round_index])
			checks_local+=1
			if cached.ai_cache_active or cached.ai_actor_cache_active or not cached.ai_topology_cache.is_empty() or not cached.ai_los_cache.is_empty() or not cached.ai_footprint_cache.is_empty() or not cached.ai_occupancy_cache.is_empty() or not cached.ai_terrain_cache.is_empty():
				failures.append("integration escaped cache %d:%d"%[sample,round_index])
			checks_local+=1
			var acted:Dictionary={}
			for action in cached.enemy_actions:
				var uid:int=int(action.get("uid",-1))
				acted[uid]=true
				if str(action.get("phase",""))=="move":
					var prior:Dictionary=previous_moves.get(uid,{})
					if int(prior.get("turn",-9999))==cached.turns-1 and prior.get("from",Vector2i.ZERO)==action.to and prior.get("to",Vector2i.ZERO)==action.from and prior.get("target",Vector2i.ZERO)==cached.player:
						reversal_count+=1
						for actor in cached.enemies:
							if int(actor.uid)==uid:
								var label:String=str(actor.get("species","unknown"))
								reversal_species[label]=int(reversal_species.get(label,0))+1
								break
					previous_moves[uid]={"turn":cached.turns,"from":action.from,"to":action.to,"target":cached.player}
			for e in cached.enemies:
				var uid:int=int(e.uid)
				var visible:bool=cached.enemy_line_of_sight(e.pos,cached.player) and cached.distance(e.pos,cached.player)<=cached.enemy_awareness(e)
				var inactive:bool=visible and cached.enemy_alert_eligible(e) and not acted.has(uid)
				idle[uid]=int(idle.get(uid,0))+1 if inactive else 0
				# Post-turn observations are diagnostic, not proof of a bad decision.
				# Separate crowded/immobilized actors from actors with open safe cardinal exits.
				var exits:int=0
				if inactive:
					for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
						var q:Vector2i=e.pos+d
						if cached.cells.has(q) and q!=cached.player and cached.enemy_at(q)<0 and cached.ally_at(q)<0 and not cached.traps.has(q):exits+=1
					var observation:String="open"
					if int(e.get("stuck_turns",0))>0:observation="immobilized"
					elif int(e.get("slow_turns",0))>0:observation="slowed"
					elif int(e.get("reinforcement_turn",-1))==cached.turns:observation="reinforcement_hold"
					elif exits==0:observation="no_safe_cardinal_exit"
					idle_observations[observation]=int(idle_observations.get(observation,0))+1
					idle_open[uid]=int(idle_open.get(uid,0))+1 if observation=="open" else 0
					idle_open_peak=maxi(idle_open_peak,int(idle_open[uid]))
					if int(idle[uid])>idle_peak:
						idle_peak_context={"sample":sample,"round":round_index,"uid":uid,"species":e.get("species",""),"position":e.pos,"player":cached.player,"exits":exits,"observation":observation}
					# Preserve original open-idle metric for apples-to-apples comparison.
					var verified_reserve:bool=observation=="open" and int(e.get("reserve_hold_turn",-1))==cached.turns and e.get("reserve_hold_target",Vector2i.ZERO)==cached.player and cached.enemy_encircled_frontline(e,cached.player)
					if verified_reserve:reserve_idle_observations+=1
					var verified_congestion:bool=observation=="open" and not verified_reserve and int(e.get("congestion_hold_turn",-1))==cached.turns and e.get("congestion_hold_target",Vector2i.ZERO)==cached.player and cached.enemy_occupied_frontline(e,cached.player)
					if verified_congestion:congestion_observations+=1
					unresolved_after_congestion[uid]=int(unresolved_after_congestion.get(uid,0))+1 if observation=="open" and not verified_reserve and not verified_congestion else 0
					unresolved_after_congestion_peak=maxi(unresolved_after_congestion_peak,int(unresolved_after_congestion[uid]))
					unexplained_open[uid]=int(unexplained_open.get(uid,0))+1 if observation=="open" and not verified_reserve else 0
					if int(unexplained_open[uid])>unexplained_open_peak:
						unexplained_open_peak=int(unexplained_open[uid])
						var residual_board:Array[String]=[]
						for y in range(1,10):
							var line:String=""
							for x in range(1,10):
								var tile:=Vector2i(x,y)
								var glyph:String="." if cached.cells.has(tile) else "#"
								if cached.traps.has(tile) or cached.player_traps.has(tile):glyph="T"
								if cached.ally_at(tile)>=0:glyph="A"
								if cached.enemy_at(tile)>=0:glyph="E"
								if tile==e.pos:glyph="L"
								if tile==cached.player:glyph="P"
								line+=glyph
							residual_board.append(line)
						unexplained_context={"board":residual_board,"sample":sample,"round":round_index,"uid":uid,"species":e.get("species",""),"position":e.pos,"player":cached.player,"actor":e.duplicate(true),"charge_phase":cached.charge_phase,"shield_turns":cached.shield_turns,"shield_kind":cached.shield_kind,"current_attack":cached.enemy_strategy_attack_tile(e,e.pos,cached.player),"encircled":cached.enemy_encircled_frontline(e,cached.player)}
				else:
					idle_open[uid]=0;unexplained_open[uid]=0;unresolved_after_congestion[uid]=0
				idle_peak=maxi(idle_peak,int(idle[uid]))
			samples+=1
	for personality in expected:
		if not personalities.has(personality):failures.append("integration missing personality "+personality)
		checks_local+=1
	if not cached_times.is_empty():
		cached_times.sort();reference_times.sort()
		var percentile:int=int((cached_times.size()-1)*.95)
		print("KINDRIA_AI_INTEGRATION turns=",samples," personalities=",personalities.size()," checks=",checks_local," cached_p95_usec=",cached_times[percentile]," reference_p95_usec=",reference_times[percentile]," max_visible_idle=",idle_peak," reversals=",reversal_count)
		print("KINDRIA_AI_STALL_DIAGNOSTICS open_idle_peak=",idle_open_peak," observations=",idle_observations," peak_context=",idle_peak_context," reversal_species=",reversal_species)
		print("KINDRIA_CONGESTION_DIAGNOSTICS verified_physical_congestion=",congestion_observations)
		print("KINDRIA_RESERVE_DIAGNOSTICS verified_open_reserve=",reserve_idle_observations," unexplained_open_peak=",unexplained_open_peak," context=",unexplained_context)
		print("KINDRIA_REMAINING_IDLE unresolved_after_congestion_peak=",unresolved_after_congestion_peak)
	return checks_local

# V27.1: ordinary ecology actors, not just Monster House actors, in constrained
# topology. Run identical inputs with and without caches and compare outcomes.
func living_dungeon_gauntlet(failures:Array[String])->int:
	var checks_local:int=0
	var rounds:int=0
	var timings:Array[int]=[]
	for sample in range(12):
		var variants:Array=[]
		for enabled in [true,false]:
			var arena=Rules.new()
			arena.ai_cache_enabled=enabled
			arena.rng.seed=927100+sample
			arena.hp=10000;arena.max_hp=10000;arena.belly_tenths=1000
			arena.player=Vector2i(6,4);arena.stairs=Vector2i(9,7);arena.relic=Vector2i(9,6)
			for y in range(1,8):
				for x in range(1,10):
					if x!=5 or y==4 or (sample%2==0 and y==2):arena.cells[Vector2i(x,y)]=true
			arena.rooms.append(Rect2i(1,1,4,7));arena.rooms.append(Rect2i(6,1,4,7))
			var species:Array=["bramble_pup","leafwisp","thornbeetle","mossmite","rootgnawer","eelstrix"]
			var posts:Array=[Vector2i(3,4),Vector2i(4,3),Vector2i(7,4),Vector2i(8,5),Vector2i(4,5),Vector2i(7,2)]
			for index in range(species.size()):
				arena.enemies.append({"uid":400+index,"pos":posts[index],"hp":30,"max_hp":30,"kind":0,"species":species[(index+sample)%species.size()],"ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":10})
			arena.traps[Vector2i(5,4)]="snare" if sample%3==0 else "spike"
			variants.append(arena)
		var cached=variants[0];var reference=variants[1]
		for tick in range(16):
			if cached.finished or reference.finished:break
			for arena in variants:
				arena.charge_phase="vanish" if tick%5==2 else ""
				arena.shield_kind="protect" if tick%5==3 else ""
				arena.shield_turns=1 if tick%5==3 else 0
				if tick%4==0:
					for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.RIGHT,Vector2i.LEFT]:
						var q:Vector2i=arena.player+d
						if arena.cells.has(q) and arena.enemy_at(q)<0 and arena.ally_at(q)<0:
							arena.adaptive_walk_from=arena.player;arena.adaptive_walk_to=q;arena.adaptive_walk_turn=arena.turns;arena.player=q;break
				if tick==4 and not arena.enemies.is_empty():
					arena.enemies[0]["hp"]=6
				if tick==8 and arena.enemies.size()>1:
					arena.enemies[1]["pp_primary"]=0;arena.enemies[1]["pp_secondary"]=0
			var start:int=Time.get_ticks_usec()
			cached.enemy_turn_actions()
			timings.append(Time.get_ticks_usec()-start)
			reference.enemy_turn_actions()
			if cached.enemies!=reference.enemies or cached.player!=reference.player or cached.hp!=reference.hp or cached.enemy_actions!=reference.enemy_actions or cached.rng.state!=reference.rng.state or cached.finished!=reference.finished:failures.append("living gauntlet differential %d:%d"%[sample,tick])
			checks_local+=1
			var occupied:Dictionary={}
			var valid:bool=true
			for e in cached.enemies:
				if int(e.hp)<=0:continue
				if not cached.cells.has(e.pos) or occupied.has(e.pos) or e.pos==cached.player:valid=false
				occupied[e.pos]=true
			if not valid:failures.append("living gauntlet occupancy %d:%d"%[sample,tick])
			checks_local+=1
			var acted:Dictionary={}
			var duplicate_action:bool=false
			for action in cached.enemy_actions:
				var uid:int=int(action.get("uid",-1))
				if acted.has(uid):duplicate_action=true
				acted[uid]=true
			if duplicate_action:failures.append("living gauntlet duplicate action %d:%d"%[sample,tick])
			checks_local+=1
			if cached.ai_actor_cache_active or cached.ai_cache_active or not cached.ai_footprint_cache.is_empty():failures.append("living gauntlet cache leak %d:%d"%[sample,tick])
			checks_local+=1;rounds+=1
	if not timings.is_empty():
		timings.sort()
		print("KINDRIA_LIVING_GAUNTLET turns=",rounds," checks=",checks_local," p95_usec=",timings[int((timings.size()-1)*.95)])
	return checks_local

# Compare actual gameplay turns separately from the isolated action scheduler.
func full_turn_intelligence_gauntlet(failures:Array[String])->int:
	var checks_local:int=0
	var rounds:int=0
	var idle_peak:int=0
	var leaf_trace:Array[String]=[]
	for sample in [0,1,4,7,11,17]:
		var cached=ai_cache_fixture(sample,true)
		var reference=ai_cache_fixture(sample,false)
		for arena in [cached,reference]:
			arena.belly_tenths=1000
			var species:Array=["rootgnawer","bramble_pup","mossmite","sporeling","leafwisp","fungal_monarch"]
			for index in range(mini(species.size(),arena.enemies.size())):
				var e:Dictionary=arena.enemies[index]
				e.species=species[index];e["personality_enabled"]=true
				e["house_role"]=arena.house_tactical_role(e)
		var idle:Dictionary={}
		for tick in range(32):
			if cached.finished or reference.finished:break
			enemy_integration_input(cached,tick,sample)
			enemy_integration_input(reference,tick,sample)
			var old_turn:int=cached.turns
			cached.enemy_turn();reference.enemy_turn()
			if cached.enemies!=reference.enemies or cached.allies!=reference.allies or cached.player!=reference.player or cached.hp!=reference.hp or cached.enemy_actions!=reference.enemy_actions or cached.rng.state!=reference.rng.state or cached.player_boons!=reference.player_boons or cached.traps!=reference.traps or cached.finished!=reference.finished or cached.shield_turns!=reference.shield_turns:failures.append("full turn differential %d:%d"%[sample,tick])
			checks_local+=1
			if cached.turns!=old_turn+1 or cached.ai_cache_active or cached.ai_actor_cache_active:failures.append("full turn counter or cache scope %d:%d"%[sample,tick])
			checks_local+=1
			var acted:Dictionary={}
			var duplicate:bool=false
			for action in cached.enemy_actions:
				var uid:int=int(action.get("uid",-1))
				if acted.has(uid):duplicate=true
				acted[uid]=true
			if duplicate:failures.append("full turn duplicate action %d:%d"%[sample,tick])
			checks_local+=1
			var occupied:Dictionary={}
			var overlap:bool=false
			for e in cached.enemies:
				var uid:int=int(e.uid)
				if int(e.hp)<=0:continue
				if not cached.cells.has(e.pos) or e.pos==cached.player or occupied.has(e.pos) or cached.ally_at(e.pos)>=0:overlap=true
				occupied[e.pos]=true
				var visible:bool=cached.enemy_alert_eligible(e) and cached.distance(e.pos,cached.player)<=cached.enemy_awareness(e) and cached.enemy_line_of_sight(e.pos,cached.player)
				idle[uid]=int(idle.get(uid,0))+1 if visible and not acted.has(uid) else 0
				idle_peak=maxi(idle_peak,int(idle[uid]))
				if sample==7 and uid==204:
					if tick in [6,15,31]:
						print("KINDRIA_LEAFWISP_RESERVE tick=",tick," hold_turn=",e.get("reserve_hold_turn",-1)," current_turn=",cached.turns," target=",e.get("reserve_hold_target",Vector2i.ZERO))
						var board:Array[String]=[]
						for y in range(1,10):
							var line:String=""
							for x in range(1,10):
								var tile:=Vector2i(x,y)
								var ch:String="." if cached.cells.has(tile) else "#"
								if cached.traps.has(tile) or cached.player_traps.has(tile):ch="T"
								if tile==cached.stairs or tile==cached.relic or tile in cached.side_rewards:ch="R"
								if cached.ally_at(tile)>=0:ch="A"
								if cached.enemy_at(tile)>=0:ch="E"
								if tile==e.pos:ch="L"
								if tile==cached.player:ch="P"
								line+=ch
							board.append(line)
						var posts:Array[String]=[]
						var reserved:Dictionary=cached.enemy_pack_reserved_posts(e,cached.player)
						for tile in cached.cells:
							if not cached.enemy_ambush_safe_tile(tile) or not cached.enemy_strategy_attack_tile(e,tile,cached.player):continue
							var blockers:Array[int]=[]
							for other in cached.enemies:
								if cached.enemy_squad_partner(e,other) and cached.enemy_relief_blocks_lane(other,tile,cached.player):blockers.append(int(other.uid))
							posts.append("%s reserved=%s blockers=%s"%[str(tile),str(reserved.has(tile)),str(blockers)])
						var old_turn_for_probe:int=cached.turns
						cached.turns+=1
						var probe:Vector2i=cached.enemy_unstall_step(e,cached.player)
						cached.turns=old_turn_for_probe
						print("KINDRIA_LEAFWISP_BOARD tick=",tick," map=",board," actor=",e," eligible=",cached.enemy_opportunity_eligible(e)," current_attack=",cached.enemy_strategy_attack_tile(e,e.pos,cached.player)," recovery_probe=",probe," posts=",posts)
					leaf_trace.append("%d pos=%s target=%s action=%s pp=%d/%d cd=%d/%d stall=%d stuck=%d slow=%d"%[tick,str(e.pos),str(cached.player),str(acted.has(uid)),cached.enemy_move_pp(e,"primary"),cached.enemy_move_pp(e,"secondary"),int(e.get("cooldown",0)),int(e.get("alt_cooldown",0)),int(e.get("stall_count",0)),int(e.get("stuck_turns",0)),int(e.get("slow_turns",0))])
			if overlap:failures.append("full turn illegal occupancy %d:%d"%[sample,tick])
			checks_local+=1;rounds+=1
	if rounds==0:failures.append("full turn audit executed no turns")
	checks_local+=1
	print("KINDRIA_FULL_TURN_GAUNTLET turns=",rounds," checks=",checks_local," max_visible_idle=",idle_peak)
	for entry in leaf_trace:print("KINDRIA_LEAFWISP_FULL_TURN ",entry)
	return checks_local

func run_checks()->void:
	if "--ai-integration" in OS.get_cmdline_user_args():
		var integration_failures:Array[String]=[]
		var integration_checks:int=enemy_adversarial_gauntlet(integration_failures)+enemy_integration_gauntlet(integration_failures)+living_dungeon_gauntlet(integration_failures)+full_turn_intelligence_gauntlet(integration_failures)
		print("KINDRIA_AI_INTEGRATION_RESULT checks=",integration_checks," failures=",integration_failures.size())
		for failure in integration_failures:push_error(failure)
		quit(0 if integration_failures.is_empty() else 1);return
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
		var search_actor:Dictionary={"uid":0,"pos":search_anchor,"hp":20,"ecology_role":role,"ecology_search_enabled":true,"last_seen_player":search_anchor,"last_seen_until":20}
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
	var reacquire_actor:Dictionary={"uid":0,"pos":search_anchor,"hp":20,"ecology_role":"scout","ecology_search_enabled":true,"last_seen_player":search_anchor,"last_seen_until":20}
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
	# Prepare a knockback angle without executing the move in the same turn.
	control_fixture.enemies.pop_back()
	control_fixture.player=Vector2i(3,3)
	controller.pos=Vector2i(2,2);controller["control_cooldown"]=0
	control_fixture.player_slow_turns=0
	control_fixture.traps[Vector2i(5,3)]="snare"
	var setup_tile:Vector2i=control_fixture.enemy_control_setup_step(controller,control_fixture.player)
	if setup_tile!=Vector2i(2,3) or controller.pos!=Vector2i(2,2) or controller.pp_control!=3:failures.append("control setup angle and purity")
	checks+=1
	controller["control_cooldown"]=1
	if control_fixture.enemy_control_setup_step(controller,control_fixture.player)!=controller.pos:failures.append("control setup cooldown")
	controller["control_cooldown"]=0
	checks+=1
	exit_fixture.rooms.append(Rect2i(1,2,3,3))
	exit_fixture.cells[Vector2i(4,2)]=true
	exit_fixture.cells[Vector2i(3,2)]=true
	exit_actor.pos=Vector2i(4,2)
	if exit_fixture.enemy_exit_block_step(exit_actor,exit_fixture.player)!=Vector2i(4,3):failures.append("control side doorway intercept")
	checks+=1
	print("KINDRIA_TERRAIN_CONTROL push=9 exit=4 setup=2")
	# Learned status utility is compared to direct attacks, including shared recovery.
	var status_fixture=Rules.new()
	for y in range(1,7):
		for x in range(1,7):status_fixture.cells[Vector2i(x,y)]=true
	status_fixture.rooms.append(Rect2i(1,1,6,6))
	status_fixture.player=Vector2i(4,3)
	var status_actor:Dictionary={"uid":0,"pos":Vector2i(3,3),"hp":30,"kind":0,"species":"coralcrab","ecology_role":"hunter","ecology_search_enabled":true,"control_move":"eos_085","pp_control":5,"pp_primary":0,"pp_secondary":0,"stages":{"accuracy":10}}
	status_fixture.enemies.append(status_actor)
	var debuff_move:Dictionary=Rules.MOVE_LIBRARY["eos_085"]
	var solo_utility:float=status_fixture.enemy_status_utility(status_actor,debuff_move)
	status_fixture.enemies.append({"uid":1,"pos":Vector2i(4,4),"hp":20,"kind":0,"ecology_search_enabled":true,"pp_primary":10,"pp_secondary":0})
	if solo_utility<=0.0 or status_fixture.enemy_status_utility(status_actor,debuff_move)<=solo_utility or status_actor.pp_control!=5 or not status_fixture.player_stages.is_empty():failures.append("status utility team benefit and purity")
	checks+=1
	status_fixture.enemies.pop_back()
	status_fixture.shield_kind="safeguard";status_fixture.shield_turns=2
	if status_fixture.enemy_status_utility(status_actor,debuff_move)!=0.0:failures.append("status safeguard gate")
	status_fixture.shield_kind="";status_fixture.shield_turns=0
	checks+=1
	status_fixture.enemy_turn_actions()
	if status_actor.pp_control!=4 or status_actor.get("last_move_slot","")!="control" or int(status_fixture.player_stages.get("attack",0))!=-1 or int(status_fixture.player_stages.get("defense",0))!=-1 or status_fixture.enemy_actions.size()!=1:failures.append("status actual learned debuff action")
	checks+=1
	status_fixture.player_stages={"attack":-2,"defense":-2}
	if status_fixture.enemy_status_utility(status_actor,debuff_move)!=0.0:failures.append("status redundant debuff")
	checks+=1
	var sleep_move:Dictionary=Rules.MOVE_LIBRARY["eos_079"]
	var paralysis_move:Dictionary=Rules.MOVE_LIBRARY["eos_192"]
	if status_fixture.enemy_status_utility(status_actor,sleep_move)<=0.0 or status_fixture.enemy_status_utility(status_actor,paralysis_move)<=0.0:failures.append("status available control utility")
	checks+=1
	status_fixture.player_boons["hostile_control_recovery"]=8
	if status_fixture.enemy_status_utility(status_actor,sleep_move)!=0.0 or status_fixture.enemy_status_utility(status_actor,paralysis_move)!=0.0:failures.append("status shared recovery")
	status_fixture.player_boons.clear()
	checks+=1
	status_fixture.player_boons["sleepless"]=1
	if status_fixture.enemy_status_utility(status_actor,sleep_move)!=0.0:failures.append("status sleep immunity")
	status_fixture.player_boons.clear()
	checks+=1
	status_fixture.cells.erase(Vector2i(4,3))
	if status_fixture.enemy_status_utility(status_actor,debuff_move)!=0.0:failures.append("status occlusion")
	status_fixture.cells[Vector2i(4,3)]=true
	checks+=1
	status_actor["control_cooldown"]=0;status_actor["pp_control"]=0
	if status_fixture.enemy_execute_control(0):failures.append("status depleted PP")
	checks+=1
	status_fixture.player_stages.clear()
	status_actor["pp_control"]=4;status_actor["pp_primary"]=12;status_actor["pp_secondary"]=10
	status_fixture.tier=5
	if status_fixture.enemy_execute_control(0):failures.append("status stronger attack priority")
	checks+=1
	print("KINDRIA_STATUS_TACTICS utility=2 gates=5 action=1 redundancy=1 priority=1")
	# Area attacks hit each party member once, without sharing the player's shield.
	var area_fixture=Rules.new()
	for y in range(1,8):
		for x in range(1,8):area_fixture.cells[Vector2i(x,y)]=true
	area_fixture.player=Vector2i(5,4)
	var area_actor:Dictionary={"uid":0,"pos":Vector2i(3,4),"hp":30,"kind":1,"species":"sporeling","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":0,"stages":{"accuracy":10}}
	area_fixture.enemies.append(area_actor)
	area_fixture.allies.append({"uid":1000,"pos":Vector2i(3,3),"hp":20,"species":"reef_pup"})
	area_fixture.allies.append({"uid":1001,"pos":Vector2i(3,5),"hp":20,"species":"reef_pup"})
	area_fixture.allies.append({"uid":1002,"pos":Vector2i(7,7),"hp":20,"species":"reef_pup"})
	var area_aim:Vector2i=area_fixture.enemy_area_aim(area_actor,"radius",2)
	var area_tiles:Dictionary=area_fixture.attack_footprint(area_actor.pos,area_aim,"radius",2)
	if not area_tiles.has(area_fixture.player) or area_fixture.enemy_area_allies(area_actor.pos,area_tiles).size()!=2 or not area_fixture.enemy_has_party_area_attack(area_actor):failures.append("area target selection and ally priority")
	checks+=1
	if area_fixture.enemy_area_bonus(area_actor,"radius",2,area_aim)<=0.0 or area_fixture.enemy_area_bonus(area_actor,"line",2,area_aim)!=0.0 or area_actor.pp_primary!=12:failures.append("area score and purity")
	checks+=1
	var area_hp:int=area_fixture.hp
	area_fixture.shield_kind="protect";area_fixture.shield_turns=2
	area_fixture.enemy_turn_actions()
	if area_fixture.hp!=area_hp or int(area_fixture.allies[0].hp)>=20 or int(area_fixture.allies[1].hp)>=20 or int(area_fixture.allies[2].hp)!=20:failures.append("area independent party damage")
	checks+=1
	if area_fixture.enemy_actions.size()!=1 or area_actor.pp_primary!=11 or area_fixture.enemy_actions[0].get("party_hits",[]).size()!=2:failures.append("area single cast and PP")
	checks+=1
	var area_ids:Dictionary={}
	for result in area_fixture.enemy_actions[0].get("party_hits",[]):area_ids[result.uid]=true
	if area_ids.size()!=2 or not area_ids.has(1000) or not area_ids.has(1001):failures.append("area distinct impact metadata")
	checks+=1
	area_fixture.allies[0].hp=0
	if area_fixture.enemy_area_allies(area_actor.pos,area_tiles).size()!=1:failures.append("area exclude defeated ally")
	checks+=1
	area_fixture.cells.erase(Vector2i(3,5))
	if not area_fixture.enemy_area_allies(area_actor.pos,area_tiles).is_empty():failures.append("area exclude occluded ally")
	area_fixture.cells[Vector2i(3,5)]=true
	checks+=1
	var remaining_ally_hp:int=int(area_fixture.allies[1].hp)
	var single_hits:Array[Dictionary]=area_fixture.enemy_apply_area_damage(area_actor,area_actor.pos,area_tiles,"line",area_fixture.signature_skill(area_actor),false)
	if not single_hits.is_empty() or int(area_fixture.allies[1].hp)!=remaining_ally_hp:failures.append("area preserve single target move")
	checks+=1
	area_actor["ecology_search_enabled"]=false
	if area_fixture.enemy_has_party_area_attack(area_actor) or not area_fixture.enemy_apply_area_damage(area_actor,area_actor.pos,area_tiles,"radius",area_fixture.signature_skill(area_actor),false).is_empty():failures.append("area preserve legacy actor")
	checks+=1
	print("KINDRIA_AREA_TACTICS selection=2 damage=1 action=1 impacts=1 gates=4")
	# Learned single-target attacks prioritize an exposed vulnerable companion.
	var priority_fixture=Rules.new()
	for y in range(1,9):
		for x in range(1,9):priority_fixture.cells[Vector2i(x,y)]=true
	priority_fixture.player=Vector2i(7,7)
	var priority_actor:Dictionary={"uid":0,"pos":Vector2i(3,3),"hp":30,"kind":0,"species":"eelstrix","signature":"Static Lash","ecology_role":"scout","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":0,"stages":{"accuracy":10}}
	priority_fixture.enemies.append(priority_actor)
	priority_fixture.allies.append({"uid":1000,"pos":Vector2i(3,2),"hp":20,"max_hp":20,"species":"rootgnawer"})
	priority_fixture.allies.append({"uid":1001,"pos":Vector2i(5,3),"hp":2,"max_hp":20,"species":"reef_pup"})
	var priority_skill:Array=priority_fixture.signature_skill(priority_actor)
	var resistant:Dictionary=priority_fixture.enemy_party_damage_estimate(priority_actor,priority_fixture.allies[0],priority_skill,false)
	var vulnerable:Dictionary=priority_fixture.enemy_party_damage_estimate(priority_actor,priority_fixture.allies[1],priority_skill,false)
	if float(vulnerable.effectiveness)<=float(resistant.effectiveness) or int(vulnerable.damage)<=int(resistant.damage):failures.append("priority elemental damage estimate")
	checks+=1
	var priority_plan:Dictionary=priority_fixture.enemy_party_attack_plan(priority_actor)
	if priority_plan.get("targets",[])!=[1] or priority_actor.pp_primary!=12 or int(priority_fixture.allies[1].hp)!=2:failures.append("priority vulnerable selection purity")
	checks+=1
	priority_fixture.cells.erase(Vector2i(4,3))
	var blocked_plan:Dictionary=priority_fixture.enemy_party_attack_plan(priority_actor)
	if 1 in blocked_plan.get("targets",[]):failures.append("priority hidden target excluded")
	priority_fixture.cells[Vector2i(4,3)]=true
	checks+=1
	priority_actor["pp_primary"]=0
	if not priority_fixture.enemy_party_attack_plan(priority_actor).is_empty():failures.append("priority exhausted kit")
	priority_actor["pp_primary"]=12
	checks+=1
	priority_fixture.enemy_turn_actions()
	if priority_actor.pp_primary!=11 or int(priority_fixture.allies[1].hp)!=0 or int(priority_fixture.allies[0].hp)!=20 or priority_fixture.enemy_actions.size()!=1:failures.append("priority learned actual cast")
	checks+=1
	if not priority_fixture.enemy_actions.is_empty():
		var impact:Array=priority_fixture.enemy_actions[0].get("party_hits",[])
		if impact.size()!=1 or int(impact[0].get("uid",-1))!=1001:failures.append("priority exact target metadata")
	else:failures.append("priority missing cast")
	checks+=1
	# Area-only targeting can hit multiple allies without hitting the distant player.
	var party_only=Rules.new()
	for y in range(1,9):
		for x in range(1,9):party_only.cells[Vector2i(x,y)]=true
	party_only.player=Vector2i(7,7)
	var party_actor:Dictionary={"uid":0,"pos":Vector2i(3,3),"hp":30,"kind":1,"species":"sporeling","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":0,"stages":{"accuracy":10}}
	party_only.enemies.append(party_actor)
	party_only.allies.append({"uid":1000,"pos":Vector2i(3,2),"hp":20,"max_hp":20,"species":"reef_pup"})
	party_only.allies.append({"uid":1001,"pos":Vector2i(4,3),"hp":20,"max_hp":20,"species":"reef_pup"})
	var party_plan_later:Dictionary=party_only.enemy_party_attack_plan(party_actor)
	if party_plan_later.get("targets",[]).size()!=2:failures.append("priority ally-only area selection")
	checks+=1
	var party_player_hp:int=party_only.hp
	party_only.enemy_turn_actions()
	if party_actor.pp_primary!=11 or party_only.hp!=party_player_hp or int(party_only.allies[0].hp)>=20 or int(party_only.allies[1].hp)>=20 or party_only.enemy_actions.size()!=1:failures.append("priority ally-only area execution")
	checks+=1
	party_actor["windup"]=true
	if not party_only.enemy_party_attack_plan(party_actor).is_empty():failures.append("priority preserve telegraphed attack")
	checks+=1
	print("KINDRIA_TARGET_PRIORITY elemental=1 selection=2 gates=3 execution=2 metadata=1")
	# Local coordination uses observed successful hits and legal escape interception.
	var squad_fixture=Rules.new()
	for y in range(1,9):
		for x in range(1,9):squad_fixture.cells[Vector2i(x,y)]=true
	squad_fixture.player=Vector2i(4,4)
	squad_fixture.stairs=Vector2i(8,8)
	squad_fixture.relic=Vector2i(8,7)
	var squad_origin:=Vector2i(5,6)
	var squad_actor:Dictionary={"uid":0,"pos":squad_origin,"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	var squad_partner:Dictionary={"uid":1,"pos":Vector2i(3,4),"hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":12}
	squad_fixture.enemies.append(squad_actor);squad_fixture.enemies.append(squad_partner)
	squad_fixture.turns=10
	squad_fixture.enemy_record_squad_focus(squad_partner,-1,0)
	if squad_fixture.enemy_squad_focus_bonus(squad_actor,-1,squad_fixture.player)!=0.0:failures.append("squad miss does not signal")
	checks+=1
	squad_fixture.enemy_record_squad_focus(squad_partner,-1,3)
	if squad_fixture.enemy_squad_focus_bonus(squad_actor,-1,squad_fixture.player)<=0.0:failures.append("squad observed focus")
	checks+=1
	squad_fixture.turns=13
	if squad_fixture.enemy_squad_focus_bonus(squad_actor,-1,squad_fixture.player)!=0.0:failures.append("squad focus expiry")
	squad_fixture.turns=10
	checks+=1
	squad_fixture.allies.append({"uid":1000,"pos":Vector2i(6,4),"hp":20,"max_hp":20,"species":"reef_pup"})
	squad_fixture.enemy_record_squad_focus(squad_partner,1000,2)
	if squad_fixture.enemy_squad_focus_bonus(squad_actor,1000,Vector2i(6,4))<=0.0 or squad_fixture.enemy_squad_focus_bonus(squad_actor,-1,squad_fixture.player)!=0.0:failures.append("squad target identity")
	checks+=1
	squad_fixture.allies[0].hp=0
	if squad_fixture.enemy_squad_focus_bonus(squad_actor,1000,Vector2i(6,4))!=0.0:failures.append("squad no focus on defeated target")
	squad_fixture.allies.clear()
	checks+=1
	squad_fixture.enemy_record_squad_focus(squad_partner,-1,3)
	squad_partner["sleep_turns"]=2
	if squad_fixture.enemy_squad_focus_bonus(squad_actor,-1,squad_fixture.player)!=0.0 or squad_fixture.enemy_squad_intercept_step(squad_actor,squad_fixture.player)!=squad_origin:failures.append("squad incapacitated partner")
	squad_partner.erase("sleep_turns")
	checks+=1
	var squad_step:Vector2i=squad_fixture.enemy_squad_intercept_step(squad_actor,squad_fixture.player)
	if squad_step==squad_origin or squad_fixture.distance(squad_origin,squad_step)!=1 or squad_actor.pos!=squad_origin or squad_actor.pp_primary!=0:failures.append("squad interception purity and bounded step")
	checks+=1
	squad_fixture.traps[squad_step]="snare"
	if squad_fixture.enemy_squad_intercept_step(squad_actor,squad_fixture.player)==squad_step:failures.append("squad avoid trapped route")
	squad_fixture.traps.clear()
	checks+=1
	squad_actor["stuck_turns"]=2
	if squad_fixture.enemy_squad_intercept_step(squad_actor,squad_fixture.player)!=squad_origin:failures.append("squad rooted actor")
	squad_actor.erase("stuck_turns")
	checks+=1
	squad_fixture.cells.erase(Vector2i(4,5))
	if squad_fixture.enemy_squad_focus_bonus(squad_actor,-1,squad_fixture.player)!=0.0 or squad_fixture.enemy_squad_intercept_step(squad_actor,squad_fixture.player)!=squad_origin:failures.append("squad no hidden player coordination")
	squad_fixture.cells[Vector2i(4,5)]=true
	checks+=1
	squad_fixture.enemy_turn_actions()
	var squad_actions:int=0
	for action in squad_fixture.enemy_actions:
		if int(action.get("uid",-1))==0:
			squad_actions+=1
			if action.get("phase","")!="move":failures.append("squad intercept no extra attack")
	if squad_actions!=1 or squad_actor.pos==squad_origin or squad_fixture.distance(squad_actor.pos,squad_origin)!=1:failures.append("squad actual interception turn")
	checks+=1
	print("KINDRIA_SQUAD_TACTICS focus=5 gates=3 movement=3")
	# Adaptive retreat recognition uses witnessed voluntary steps, not forced motion.
	var adaptive_fixture=Rules.new()
	for y in range(1,9):
		for x in range(1,9):adaptive_fixture.cells[Vector2i(x,y)]=true
	adaptive_fixture.stairs=Vector2i(8,8)
	adaptive_fixture.relic=Vector2i(8,7)
	var adaptive_actor:Dictionary={"uid":0,"pos":Vector2i(6,2),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	var adaptive_partner:Dictionary={"uid":1,"pos":Vector2i(3,2),"hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	adaptive_fixture.enemies.append(adaptive_actor);adaptive_fixture.enemies.append(adaptive_partner)
	adaptive_fixture.turns=20
	adaptive_fixture.player=Vector2i(3,3)
	adaptive_fixture.enemy_observe_movement(adaptive_actor,adaptive_fixture.player)
	adaptive_fixture.adaptive_walk_from=Vector2i(3,3);adaptive_fixture.adaptive_walk_to=Vector2i(4,3);adaptive_fixture.adaptive_walk_turn=20
	adaptive_fixture.player=Vector2i(4,3);adaptive_fixture.turns=21
	adaptive_fixture.enemy_observe_movement(adaptive_actor,adaptive_fixture.player)
	if adaptive_actor.get("adaptive_streak",0)!=1 or adaptive_fixture.enemy_retreat_prediction(adaptive_actor,adaptive_fixture.player)!=adaptive_fixture.player:failures.append("adaptive common requires repeat")
	checks+=1
	adaptive_actor["kind"]=2
	if adaptive_fixture.enemy_retreat_prediction(adaptive_actor,adaptive_fixture.player)!=Vector2i(5,3):failures.append("adaptive elite earlier recognition")
	adaptive_actor["kind"]=0
	checks+=1
	adaptive_fixture.adaptive_walk_from=Vector2i(4,3);adaptive_fixture.adaptive_walk_to=Vector2i(5,3);adaptive_fixture.adaptive_walk_turn=21
	adaptive_fixture.player=Vector2i(5,3);adaptive_fixture.turns=22
	adaptive_fixture.enemy_observe_movement(adaptive_actor,adaptive_fixture.player)
	if adaptive_fixture.enemy_retreat_prediction(adaptive_actor,adaptive_fixture.player)!=Vector2i(6,3) or adaptive_fixture.enemy_adaptive_intercept_step(adaptive_actor,adaptive_fixture.player)!=Vector2i(6,3):failures.append("adaptive observed flank intercept")
	checks+=1
	adaptive_fixture.traps[Vector2i(6,3)]="snare"
	if adaptive_fixture.enemy_adaptive_intercept_step(adaptive_actor,adaptive_fixture.player)!=adaptive_actor.pos:failures.append("adaptive hazard gate")
	adaptive_fixture.traps.clear()
	checks+=1
	adaptive_actor["kind"]=3
	if adaptive_fixture.enemy_retreat_prediction(adaptive_actor,adaptive_fixture.player)!=adaptive_fixture.player:failures.append("adaptive guardian exclusion")
	adaptive_actor["kind"]=0
	checks+=1
	adaptive_actor["windup"]=true
	if adaptive_fixture.enemy_adaptive_intercept_step(adaptive_actor,adaptive_fixture.player)!=adaptive_actor.pos:failures.append("adaptive preserve telegraph")
	adaptive_actor.erase("windup")
	checks+=1
	adaptive_fixture.turns=23;adaptive_fixture.player=Vector2i(6,3)
	adaptive_fixture.enemy_observe_movement(adaptive_actor,adaptive_fixture.player)
	if adaptive_actor.get("adaptive_streak",0)!=0:failures.append("adaptive forced displacement clears streak")
	checks+=1
	adaptive_fixture.cells.erase(Vector2i(6,3))
	adaptive_fixture.turns=24
	adaptive_fixture.enemy_observe_movement(adaptive_actor,adaptive_fixture.player)
	if adaptive_actor.has("adaptive_seen_turn"):failures.append("adaptive occlusion forgets observation")
	adaptive_fixture.cells[Vector2i(6,3)]=true
	checks+=1
	# Replay a witnessed two-step retreat through the real enemy turn path.
	adaptive_actor["adaptive_seen"]=Vector2i(4,3);adaptive_actor["adaptive_seen_turn"]=21
	adaptive_actor["adaptive_heading"]=Vector2i.RIGHT;adaptive_actor["adaptive_streak"]=1
	adaptive_fixture.turns=21;adaptive_fixture.player=Vector2i(5,3)
	adaptive_fixture.adaptive_walk_from=Vector2i(4,3);adaptive_fixture.adaptive_walk_to=Vector2i(5,3);adaptive_fixture.adaptive_walk_turn=21
	adaptive_fixture.enemy_turn_actions()
	var adaptive_moves:int=0
	for action in adaptive_fixture.enemy_actions:
		if int(action.get("uid",-1))==0:
			adaptive_moves+=1
			if action.get("phase","")!="move":failures.append("adaptive no bonus attack")
	if adaptive_actor.pos!=Vector2i(6,3) or adaptive_moves!=1:failures.append("adaptive real interception")
	checks+=1
	var defensive_skill:Array=adaptive_fixture.signature_skill(adaptive_actor)
	var neutral_score:float=adaptive_fixture.enemy_attack_score(adaptive_actor,defensive_skill,false)
	adaptive_fixture.player_stages={"defense":-2,"sp_defense":-2}
	if adaptive_fixture.enemy_attack_score(adaptive_actor,defensive_skill,false)<=neutral_score:failures.append("adaptive exploit defense debuff")
	checks+=1
	adaptive_fixture.shield_kind="protect";adaptive_fixture.shield_turns=2
	if adaptive_fixture.enemy_attack_score(adaptive_actor,defensive_skill,false)!=0.0:failures.append("adaptive active protection score")
	checks+=1
	print("KINDRIA_ADAPTIVE_TACTICS observation=3 gates=4 movement=2 scoring=2")
	# House tactical roles and placement preserve the encounter's original budget.
	var house_tactics=Rules.new()
	for y in range(1,10):
		for x in range(1,10):house_tactics.cells[Vector2i(x,y)]=true
	house_tactics.rooms.append(Rect2i(2,2,7,7))
	house_tactics.player=Vector2i(5,5);house_tactics.stairs=Vector2i(9,9);house_tactics.relic=Vector2i(9,8)
	house_tactics.monster_house_room=0;house_tactics.monster_house_profile=3
	house_tactics.floor_number=3;house_tactics.guardian_defeated=true
	var house_guard:Dictionary={"pos":Vector2i(4,7),"hp":30,"kind":1,"species":"mossmite","house_tactical":true,"house_role":"guard","monster_house":true,"monster_house_spawn_serial":1,"ecology_search_enabled":true}
	var house_ranged:Dictionary={"pos":Vector2i(5,7),"hp":30,"kind":1,"species":"leafwisp","house_tactical":true,"house_role":"ranged","monster_house":true,"monster_house_spawn_serial":1,"ecology_search_enabled":true}
	if house_tactics.house_tactical_role(house_guard)!="guard" or house_tactics.house_tactical_role(house_ranged)!="ranged" or house_tactics.house_tactical_role({"species":"sporeling","kind":1})!="controller" or house_tactics.house_tactical_role({"species":"reef_pup","kind":0})!="vanguard":failures.append("house tactical role mapping")
	checks+=1
	var house_spots:Array[Vector2i]=[Vector2i(5,6),Vector2i(5,8),Vector2i(8,5)]
	house_tactics.traps[Vector2i(5,8)]="snare"
	if house_tactics.house_spawn_tile(house_ranged,house_spots,house_tactics.rooms[0])!=Vector2i(8,5) or house_spots.size()!=3:failures.append("house tactical safe spawn selection")
	house_tactics.traps.clear()
	checks+=1
	if not house_tactics.trigger_monster_house() or house_tactics.monster_house_remaining()!=house_tactics.monster_house_spawn_count or house_tactics.monster_house_spawn_count>Rules.MONSTER_HOUSE_CAP:failures.append("house tactical actual spawn budget")
	checks+=1
	var house_seen_tiles:Dictionary={}
	for actor in house_tactics.enemies:
		if not bool(actor.get("house_tactical",false)) or not bool(actor.get("ecology_search_enabled",false)) or not actor.get("house_role","") in ["guard","ranged","controller","vanguard"] or house_seen_tiles.has(actor.pos):failures.append("house tactical spawn metadata")
		house_seen_tiles[actor.pos]=true
	checks+=1
	if not house_tactics.stairs_available() or house_tactics.trigger_monster_house():failures.append("house tactical stair freedom and one trigger")
	checks+=1
	house_tactics.enemies.clear()
	house_tactics.enemies.append(house_guard);house_tactics.enemies.append(house_ranged)
	house_tactics.player=Vector2i(5,5)
	house_ranged.pos=Vector2i(5,8);house_guard.pos=Vector2i(4,7)
	var guard_step:Vector2i=house_tactics.house_formation_step(house_guard,house_tactics.player)
	if guard_step==Vector2i(5,7) or house_guard.pos!=Vector2i(4,7):failures.append("house tactical guard avoids ranged lane")
	checks+=1
	house_ranged.pos=Vector2i(4,8);house_guard.pos=Vector2i(3,7)
	if house_tactics.house_formation_step(house_guard,house_tactics.player)!=Vector2i(4,7):failures.append("house tactical guard screening step")
	checks+=1
	house_guard["stuck_turns"]=2
	if house_tactics.house_formation_step(house_guard,house_tactics.player)!=house_guard.pos:failures.append("house tactical rooted guard")
	house_guard.erase("stuck_turns")
	checks+=1
	house_guard["ecology_role"]="hunter"
	house_tactics.turns=20
	house_guard["last_seen_player"]=Vector2i(5,5);house_guard["last_seen_until"]=21
	house_tactics.cells.erase(Vector2i(4,7));house_tactics.cells.erase(Vector2i(3,6))
	if house_tactics.enemy_pursuit_target(house_guard,Vector2i(5,5))!=Vector2i(5,5):failures.append("house tactical last known target")
	house_tactics.turns=22
	if house_tactics.enemy_pursuit_target(house_guard,Vector2i(5,5))==Vector2i(5,5):failures.append("house tactical memory expires behind wall")
	checks+=2
	print("KINDRIA_HOUSE_TACTICS roles=1 spawn=3 stairs=1 formation=3 memory=2")
	# Guardian tactics change decisions, not the original combat action budget.
	var boss_fixture=Rules.new()
	for y in range(1,10):
		for x in range(1,10):boss_fixture.cells[Vector2i(x,y)]=true
	boss_fixture.player=Vector2i(5,3);boss_fixture.stairs=Vector2i(9,9);boss_fixture.relic=Vector2i(3,3)
	var boss_actor:Dictionary={"uid":99,"pos":Vector2i(3,3),"hp":30,"max_hp":30,"kind":3,"species":"abyss_colossus","name":"Abyss Colossus","pp_primary":0,"pp_secondary":0}
	boss_fixture.boss_initialize(boss_actor)
	boss_fixture.enemies.append(boss_actor)
	if boss_fixture.boss_combat_phase(boss_actor)!=0 or boss_actor.get("control_move","")!="eos_284" or int(boss_actor.get("pp_control",0))<=0:failures.append("boss initial phase and learned control")
	checks+=1
	boss_actor.hp=20
	boss_fixture.boss_observe_phase(boss_actor)
	if boss_actor.boss_phase!=1 or boss_fixture.boss_attack_preference(boss_actor,true)!=0.0:failures.append("boss pressure phase")
	checks+=1
	boss_actor.hp=10
	boss_fixture.boss_observe_phase(boss_actor)
	if boss_actor.boss_phase!=2 or boss_fixture.boss_attack_preference(boss_actor,true)<=0.0 or boss_actor.hp!=10 or boss_actor.max_hp!=30:failures.append("boss last stand no stat inflation")
	checks+=1
	if boss_fixture.boss_tactical_style({"species":"fungal_monarch"})!="zone" or boss_fixture.boss_tactical_style({"species":"tidal_sovereign"})!="crossfire" or boss_fixture.boss_tactical_style({"species":"celestial_guardian"})!="sentinel":failures.append("boss distinct styles")
	checks+=1
	var boss_step:Vector2i=boss_fixture.boss_reposition_step(boss_actor,boss_fixture.player)
	if boss_step!=Vector2i(4,3) or boss_actor.pos!=Vector2i(3,3):failures.append("boss legal movement purity")
	checks+=1
	boss_fixture.traps[boss_step]="snare"
	if boss_fixture.boss_reposition_step(boss_actor,boss_fixture.player)==boss_step:failures.append("boss avoids trap")
	boss_fixture.traps.clear()
	checks+=1
	boss_actor["windup"]=true
	if boss_fixture.boss_reposition_step(boss_actor,boss_fixture.player)!=boss_actor.pos:failures.append("boss telegraph not redirected")
	boss_actor.erase("windup")
	checks+=1
	boss_actor["stuck_turns"]=2
	if boss_fixture.boss_reposition_step(boss_actor,boss_fixture.player)!=boss_actor.pos:failures.append("boss rooted movement gate")
	boss_actor.erase("stuck_turns")
	checks+=1
	boss_actor["pp_control"]=0
	boss_fixture.enemy_turn_actions()
	if boss_actor.pos!=boss_step or boss_fixture.enemy_actions.size()!=1 or boss_fixture.enemy_actions[0].get("phase","")!="move":failures.append("boss real turn single movement")
	checks+=1
	boss_actor.pos=Vector2i(7,3);boss_fixture.player=Vector2i(9,3)
	if boss_fixture.boss_reposition_step(boss_actor,boss_fixture.player)==Vector2i(8,3):failures.append("boss home leash")
	checks+=1
	print("KINDRIA_BOSS_TACTICS phases=3 styles=1 movement=6")
	# V26.64: regression fixtures and a mixed-actor simulation.
	var stability=Rules.new()
	for y in range(1,10):
		for x in range(1,10):stability.cells[Vector2i(x,y)]=true
	stability.player=Vector2i(5,5)
	var stability_actor:Dictionary={"uid":0,"pos":Vector2i(3,5),"hp":20,"max_hp":20,"kind":0,"species":"bramble_pup","ecology_search_enabled":true,"ecology_role":"hunter","cooldown":3,"alt_cooldown":2,"support_cooldown":1,"control_cooldown":4}
	stability.enemies.append(stability_actor)
	stability.allies.append({"uid":1000,"pos":Vector2i(4,5),"hp":20,"max_hp":20})
	stability.apply_signature_effect(0,stability.signature_skill(stability_actor))
	if stability_actor.pos!=Vector2i(3,5):failures.append("stability pounce cannot overlap ally")
	checks+=1
	stability_actor["sleep_turns"]=2
	stability.enemy_turn_actions()
	if stability_actor.cooldown!=2 or stability_actor.alt_cooldown!=1 or stability_actor.support_cooldown!=0 or stability_actor.control_cooldown!=3 or not stability.enemy_actions.is_empty():failures.append("stability asleep cooldown ticking")
	checks+=1
	stability.player_boons={"hostile_sleep":3,"hostile_drowse":2,"hostile_paralysis":4,"hostile_control_recovery":8}
	stability.player_slow_turns=4
	if not stability.apply_player_boon({"boon_kind":"cure"}) or stability.boon_active("hostile_sleep") or stability.boon_active("hostile_drowse") or stability.boon_active("hostile_paralysis") or stability.player_slow_turns!=0 or not stability.boon_active("hostile_control_recovery"):failures.append("stability cure and recovery preservation")
	checks+=1
	stability.player_boons={"hostile_drowse":1}
	stability.shield_kind="safeguard";stability.shield_turns=2
	stability.tick_player_boons()
	if stability.boon_active("hostile_sleep"):failures.append("stability delayed sleep safeguard")
	checks+=1
	var stability_turns:int=0
	for sample in range(32):
		var arena=Rules.new()
		arena.rng.seed=21000+sample
		arena.monster_house_rng.seed=32000+sample
		for y in range(1,10):
			for x in range(1,10):arena.cells[Vector2i(x,y)]=true
		arena.rooms.append(Rect2i(1,1,9,9))
		arena.player=Vector2i(5,5);arena.stairs=Vector2i(9,9);arena.relic=Vector2i(9,8)
		arena.hp=10000;arena.max_hp=10000
		arena.region=sample%3;arena.floor_number=3;arena.tier=sample%3
		arena.monster_house_room=0;arena.monster_house_profile=sample%6
		arena.trigger_monster_house()
		for tick in range(16):
			if arena.finished:break
			arena.enemy_turn()
			stability_turns+=1
			var occupied_stability:Dictionary={arena.player:true}
			for actor in arena.enemies:
				if int(actor.hp)<=0:continue
				if not arena.cells.has(actor.pos) or occupied_stability.has(actor.pos):failures.append("stability occupied or invalid actor tile %d:%d"%[sample,tick])
				occupied_stability[actor.pos]=true
				for slot in ["primary","secondary","support","control"]:
					if arena.enemy_move_pp(actor,slot)<0:failures.append("stability negative PP")
				for key in ["cooldown","alt_cooldown","support_cooldown","control_cooldown"]:
					if int(actor.get(key,0))<0:failures.append("stability negative cooldown")
			var action_uids:Dictionary={}
			for action in arena.enemy_actions:
				var uid:int=int(action.get("uid",-1))
				if action_uids.has(uid):failures.append("stability duplicate actor action %d:%d"%[sample,tick])
				action_uids[uid]=true
				if action.get("phase","")=="move" and (action.get("from")==action.get("to") or not arena.cells.has(action.get("to"))):failures.append("stability invalid movement event")
			checks+=1
	print("KINDRIA_AI_STABILITY turns=",stability_turns," scenarios=32")
	checks+=ai_cache_regressions(failures)
	checks+=ai_path_regressions(failures)
	# Local lane yielding must open a real learned attack rather than wander.
	var crowd=Rules.new()
	for y in range(1,8):
		for x in range(1,8):crowd.cells[Vector2i(x,y)]=true
	crowd.player=Vector2i(5,3);crowd.stairs=Vector2i(7,7);crowd.relic=Vector2i(7,6)
	var crowd_front:Dictionary={"uid":0,"pos":Vector2i(3,3),"hp":20,"max_hp":20,"kind":0,"species":"rootgnawer","ecology_search_enabled":true,"ecology_role":"hunter","pp_primary":0,"pp_secondary":0}
	var crowd_rear:Dictionary={"uid":1,"pos":Vector2i(2,3),"hp":20,"max_hp":20,"kind":1,"species":"leafwisp","ecology_search_enabled":true,"ecology_role":"hunter","pp_primary":12,"pp_secondary":0}
	crowd.enemies.append(crowd_front);crowd.enemies.append(crowd_rear)
	crowd.traps[Vector2i(3,4)]="snare"
	var crowd_step:Vector2i=crowd.enemy_crowd_yield_step(crowd_front,crowd.player)
	if crowd_step!=Vector2i(3,2) or crowd_front.pos!=Vector2i(3,3) or crowd_rear.pp_primary!=12:failures.append("crowd safe lane yield purity")
	checks+=1
	crowd_rear["pp_primary"]=0
	if crowd.enemy_crowd_yield_step(crowd_front,crowd.player)!=crowd_front.pos:failures.append("crowd depleted rear kit")
	crowd_rear["pp_primary"]=12
	checks+=1
	crowd_rear["sleep_turns"]=2
	if crowd.enemy_crowd_yield_step(crowd_front,crowd.player)!=crowd_front.pos:failures.append("crowd sleeping partner")
	crowd_rear.erase("sleep_turns")
	checks+=1
	crowd_front["stuck_turns"]=2
	if crowd.enemy_crowd_yield_step(crowd_front,crowd.player)!=crowd_front.pos:failures.append("crowd rooted front")
	crowd_front.erase("stuck_turns")
	checks+=1
	crowd.enemies.append({"uid":2,"pos":Vector2i(4,3),"hp":20,"kind":0})
	if crowd.enemy_crowd_yield_step(crowd_front,crowd.player)!=crowd_front.pos:failures.append("crowd second obstruction")
	crowd.enemies.pop_back()
	checks+=1
	crowd.player_traps[Vector2i(3,2)]="snare"
	if crowd.enemy_crowd_yield_step(crowd_front,crowd.player)!=crowd_front.pos:failures.append("crowd no safe pocket")
	crowd.player_traps.clear()
	checks+=1
	crowd.enemy_turn_actions()
	var crowd_front_actions:int=0
	var crowd_rear_attacks:int=0
	for action in crowd.enemy_actions:
		if int(action.get("uid",-1))==0:
			crowd_front_actions+=1
			if action.get("phase","")!="move":failures.append("crowd yield grants no attack")
		if int(action.get("uid",-1))==1 and action.get("phase","")=="attack":crowd_rear_attacks+=1
	if crowd_front.pos!=crowd_step or crowd_front_actions!=1 or crowd_rear_attacks!=1 or crowd_rear.pp_primary!=11:failures.append("crowd actual lane handoff")
	checks+=1
	crowd.turns+=1
	if not crowd.enemy_crowd_hold(crowd_front,Vector2i(3,3),crowd.player):failures.append("crowd one-turn anti-reversal")
	if crowd.enemy_crowd_hold(crowd_front,Vector2i(3,3),Vector2i(6,3)):failures.append("crowd changed target breaks hold")
	checks+=2
	crowd.turns+=1
	if crowd.enemy_crowd_hold(crowd_front,Vector2i(3,3),crowd.player):failures.append("crowd hold expiry")
	checks+=1
	print("KINDRIA_CROWD_NAVIGATION checks=10")

	# Idle watch posts are selected from nearby geometry, never a hidden target.
	var ambush=Rules.new()
	for y in range(2,7):
		for x in range(3,8):ambush.cells[Vector2i(x,y)]=true
	for x in range(1,3):ambush.cells[Vector2i(x,4)]=true
	ambush.rooms.append(Rect2i(3,2,5,5))
	ambush.cells[Vector2i(9,9)]=true
	ambush.cells[Vector2i(9,8)]=true
	ambush.player=Vector2i(9,9);ambush.stairs=Vector2i(10,9);ambush.relic=Vector2i(10,8)
	var ambush_actor:Dictionary={"uid":0,"pos":Vector2i(5,3),"hp":20,"max_hp":20,"kind":0,"species":"rootgnawer","ecology_role":"sentry","ecology_home":Vector2i(5,3),"ecology_search_enabled":true,"ambush_enabled":true,"pp_primary":12,"pp_secondary":0}
	ambush.enemies.append(ambush_actor)
	var ambush_plan:Dictionary=ambush.enemy_ambush_plan(ambush_actor)
	if ambush_plan.is_empty() or ambush_plan.get("gate")!=Vector2i(2,4) or ambush_plan.get("entry")!=Vector2i(3,4) or ambush.distance(ambush_plan.get("post",Vector2i.ZERO),Vector2i(3,4))!=1 or ambush_actor.has("ambush_post"):failures.append("ambush valid melee watch post and pure plan")
	checks+=1
	ambush.player=Vector2i(9,8)
	if ambush.enemy_ambush_plan(ambush_actor)!=ambush_plan:failures.append("ambush hidden target independence")
	checks+=1
	ambush_actor["ambush_enabled"]=false
	if not ambush.enemy_ambush_plan(ambush_actor).is_empty():failures.append("ambush opt-in ecology")
	ambush_actor["ambush_enabled"]=true
	checks+=1
	ambush_actor["stuck_turns"]=2
	if not ambush.enemy_ambush_plan(ambush_actor).is_empty():failures.append("ambush rooted actor")
	ambush_actor.erase("stuck_turns")
	checks+=1
	ambush_actor["windup"]=true
	if not ambush.enemy_ambush_plan(ambush_actor).is_empty():failures.append("ambush charged actor")
	ambush_actor.erase("windup")
	checks+=1
	var ambush_step:Vector2i=ambush_plan.get("step",ambush_actor.pos)
	ambush.traps[ambush_step]="snare"
	if ambush.enemy_ambush_plan(ambush_actor).get("step",Vector2i.ZERO)==ambush_step:failures.append("ambush avoids trapped approach")
	ambush.traps.clear()
	checks+=1
	ambush.enemy_turn_actions()
	if ambush_actor.pos!=ambush_step or ambush_actor.pp_primary!=12 or ambush.enemy_actions.size()!=1 or ambush.enemy_actions[0].get("phase","")!="move":failures.append("ambush actual single action")
	checks+=1
	for tick in range(3):ambush.enemy_turn_actions()
	if ambush_actor.pos!=ambush_plan.get("post") or not ambush_actor.has("ambush_post") or not ambush.enemy_actions.is_empty():failures.append("ambush holds chosen post")
	checks+=1
	ambush.player=Vector2i(3,4)
	if ambush.enemy_pursuit_target(ambush_actor,ambush.player)!=ambush.player or ambush_actor.has("ambush_post"):failures.append("ambush visible target cancels post")
	checks+=1
	ambush.enemy_turn_actions()
	if ambush.enemy_actions.size()!=1 or ambush.enemy_actions[0].get("phase","")!="attack" or ambush_actor.pp_primary!=11:failures.append("ambush normal learned attack after contact")
	checks+=1
	print("KINDRIA_AMBUSH_TACTICS checks=10")

	# Coordination claims depend on visible live peers and expire.
	var ambush_coord=Rules.new()
	for y in range(2,7):
		for x in range(3,8):ambush_coord.cells[Vector2i(x,y)]=true
	for x in range(1,3):ambush_coord.cells[Vector2i(x,4)]=true
	ambush_coord.rooms.append(Rect2i(3,2,5,5))
	ambush_coord.player=Vector2i(9,9);ambush_coord.cells[ambush_coord.player]=true
	ambush_coord.stairs=Vector2i(10,9);ambush_coord.relic=Vector2i(10,8);ambush_coord.turns=20
	var ac_entry:=Vector2i(3,4)
	var ac_gate:=Vector2i(2,4)
	var ac_actor:Dictionary={"uid":60,"pos":Vector2i(4,4),"hp":20,"kind":0,"species":"rootgnawer","ecology_search_enabled":true,"ecology_role":"sentry","ambush_enabled":true,"personality_enabled":true,"ecology_home":Vector2i(4,4),"pp_primary":12,"pp_secondary":0}
	var ac_peer:Dictionary={"uid":61,"pos":Vector2i(4,3),"hp":20,"kind":0,"species":"rootgnawer","ecology_search_enabled":true,"ambush_enabled":true,"ambush_post":Vector2i(3,3),"ambush_entry":ac_entry,"ambush_gate":ac_gate,"ambush_plan_turn":19}
	ambush_coord.enemies.append(ac_actor);ambush_coord.enemies.append(ac_peer)
	if ambush_coord.enemy_ambush_claim_score(ac_actor,Vector2i(3,3),ac_entry,ac_gate)!=-1000:failures.append("ambush claim excludes duplicate post")
	checks+=1
	if ambush_coord.enemy_ambush_claim_score(ac_actor,Vector2i(3,5),ac_entry,ac_gate)<=0:failures.append("ambush opposite entry support")
	checks+=1
	ac_peer["sleep_turns"]=2
	if ambush_coord.enemy_ambush_claim_score(ac_actor,Vector2i(3,3),ac_entry,ac_gate)!=0:failures.append("ambush sleeping peer ignored")
	ac_peer.erase("sleep_turns")
	checks+=1
	ambush_coord.turns=25
	if ambush_coord.enemy_ambush_claim_score(ac_actor,Vector2i(3,3),ac_entry,ac_gate)!=0:failures.append("ambush expired peer claim")
	checks+=1
	ambush_coord.turns=20
	var ac_plan:Dictionary=ambush_coord.enemy_ambush_plan(ac_actor)
	if ac_plan.is_empty() or ac_plan.get("post")==Vector2i(3,3) or ac_actor.has("ambush_post"):failures.append("ambush coordinated pure plan")
	checks+=1
	ac_actor["ambush_post"]=ac_actor.pos;ac_actor["ambush_entry"]=ac_entry;ac_actor["ambush_gate"]=ac_gate;ac_actor["ambush_plan_turn"]=14
	if ambush_coord.enemy_ambush_step(ac_actor)!=ac_actor.pos or ac_actor.has("ambush_post") or int(ac_actor.get("ambush_retry",-1))!=23:failures.append("ambush wait expires and retries")
	checks+=1
	ac_actor["pp_primary"]=0;ac_actor["pp_secondary"]=0
	if ambush_coord.enemy_ambush_attack_ready(ac_actor,Vector2i(5,4),ac_entry) or not ambush_coord.enemy_ambush_attack_ready(ac_actor,Vector2i(4,4),ac_entry):failures.append("ambush no imaginary learned attack")
	checks+=1
	ac_actor["ambush_post"]=ac_actor.pos;ac_actor["ambush_entry"]=ac_entry;ac_actor["ambush_gate"]=ac_gate;ac_actor["ambush_plan_turn"]=20
	ambush_coord.player=ac_entry
	if ambush_coord.enemy_pursuit_target(ac_actor,ac_entry)!=ac_entry or ac_actor.has("ambush_plan_turn"):failures.append("ambush direct sight clears coordinated plan")
	checks+=1
	print("KINDRIA_COORDINATED_AMBUSH checks=8")

	# Push pressure is individual, bounded and never creates a new ability.
	var adapt_push=Rules.new()
	for y in range(1,12):
		for x in range(1,12):adapt_push.cells[Vector2i(x,y)]=true
	adapt_push.player=Vector2i(3,5);adapt_push.stairs=Vector2i(11,11);adapt_push.relic=Vector2i(11,10);adapt_push.turns=20
	var ap_actor:Dictionary={"uid":200,"pos":Vector2i(6,5),"hp":30,"max_hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0}
	adapt_push.enemies.append(ap_actor)
	adapt_push.enemy_record_push_pressure(ap_actor);adapt_push.enemy_record_push_pressure(ap_actor)
	if adapt_push.enemy_repeated_push(ap_actor) or int(ap_actor.get("push_pressure_count",0))!=1:failures.append("adapt push one sample per turn")
	checks+=1
	adapt_push.turns=21
	adapt_push.enemy_record_push_pressure(ap_actor)
	if not adapt_push.enemy_repeated_push(ap_actor):failures.append("adapt push repeated observation")
	checks+=1
	var ap_step:Vector2i=adapt_push.enemy_push_adaptation_step(ap_actor,adapt_push.player)
	if ap_step==ap_actor.pos or adapt_push.distance(ap_step,ap_actor.pos)!=1 or adapt_push.enemy_push_exposure(ap_actor,ap_step,adapt_push.player)>=adapt_push.enemy_push_exposure(ap_actor,ap_actor.pos,adapt_push.player):failures.append("adapt push lower exposure legal step")
	checks+=1
	if ap_actor.pos!=Vector2i(6,5) or ap_actor.pp_primary!=0 or not adapt_push.enemy_actions.is_empty():failures.append("adapt push planning purity")
	checks+=1
	adapt_push.traps[ap_step]="snare"
	if adapt_push.enemy_push_adaptation_step(ap_actor,adapt_push.player)==ap_step:failures.append("adapt push avoid trap")
	adapt_push.traps.clear()
	checks+=1
	ap_actor["push_adapt_turn"]=21
	if adapt_push.enemy_push_adaptation_step(ap_actor,adapt_push.player)!=ap_actor.pos:failures.append("adapt push retry interval")
	ap_actor.erase("push_adapt_turn")
	checks+=1
	adapt_push.cells.erase(Vector2i(5,5))
	if adapt_push.enemy_push_adaptation_step(ap_actor,adapt_push.player)!=ap_actor.pos:failures.append("adapt push no hidden target")
	adapt_push.cells[Vector2i(5,5)]=true
	checks+=1
	adapt_push.turns=26
	if adapt_push.enemy_repeated_push(ap_actor) or adapt_push.enemy_push_adaptation_step(ap_actor,adapt_push.player)!=ap_actor.pos:failures.append("adapt push expiry")
	checks+=1
	adapt_push.turns=27
	ap_actor["push_immune"]=true
	if adapt_push.push_enemy(0) or int(ap_actor.get("push_pressure_turn",-1))!=21:failures.append("adapt push immune attempt not learned")
	ap_actor.erase("push_immune")
	checks+=1
	print("KINDRIA_ENEMY_ADAPTATION checks=9")

	# Decision scoring compares usable learned moves without consuming a turn.
	var decision_fixture=Rules.new()
	for y in range(1,10):
		for x in range(1,10):decision_fixture.cells[Vector2i(x,y)]=true
	decision_fixture.player=Vector2i(6,4);decision_fixture.stairs=Vector2i(9,9);decision_fixture.relic=Vector2i(9,8);decision_fixture.turns=20;decision_fixture.hp=30
	var decision_actor:Dictionary={"uid":220,"pos":Vector2i(4,5),"hp":30,"max_hp":30,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":0}
	decision_fixture.enemies.append(decision_actor)
	var decision_position:Dictionary=decision_fixture.enemy_decision_position_plan(decision_actor,decision_fixture.player)
	if decision_position.get("step")!=Vector2i(4,4) or float(decision_position.get("value",0))<=0.0:failures.append("decision opens real primary firing lane")
	checks+=1
	if decision_actor.pos!=Vector2i(4,5) or decision_actor.pp_primary!=12 or not decision_fixture.enemy_actions.is_empty():failures.append("decision pure evaluation")
	checks+=1
	decision_fixture.traps[Vector2i(4,4)]="snare"
	if not decision_fixture.enemy_decision_position_plan(decision_actor,decision_fixture.player).is_empty():failures.append("decision excludes trapped post")
	decision_fixture.traps.clear()
	checks+=1
	decision_actor["cooldown"]=2
	if not decision_fixture.enemy_decision_position_plan(decision_actor,decision_fixture.player).is_empty():failures.append("decision cooling move unavailable")
	decision_actor.erase("cooldown")
	checks+=1
	decision_actor.species="rootgnawer";decision_actor.pp_primary=0;decision_actor.pp_secondary=12
	if decision_fixture.enemy_decision_position_plan(decision_actor,decision_fixture.player).get("step")!=Vector2i(4,4):failures.append("decision considers learned secondary")
	checks+=1
	decision_actor.pp_secondary=0
	if not decision_fixture.enemy_decision_position_plan(decision_actor,decision_fixture.player).is_empty():failures.append("decision exhausted kit preserves fallback")
	checks+=1
	decision_actor.pp_secondary=12;decision_actor.pos=Vector2i(4,4)
	if not decision_fixture.enemy_decision_position_plan(decision_actor,decision_fixture.player).is_empty():failures.append("decision retains immediate attack")
	checks+=1
	decision_actor.pos=Vector2i(4,5);decision_fixture.shield_kind="protect";decision_fixture.shield_turns=2
	if not decision_fixture.enemy_decision_position_plan(decision_actor,decision_fixture.player).is_empty():failures.append("decision respects protected target")
	decision_fixture.shield_turns=0
	checks+=1
	decision_fixture.cells.erase(Vector2i(5,5));decision_fixture.cells.erase(Vector2i(5,4))
	if not decision_fixture.enemy_decision_position_plan(decision_actor,decision_fixture.player).is_empty():failures.append("decision no unseen target")
	checks+=1
	print("KINDRIA_ENEMY_DECISION_ENGINE checks=9")

	# Lookahead finds a firing position beyond the immediate neighborhood.
	var foresight_fixture=Rules.new()
	for y in range(1,11):
		for x in range(1,11):foresight_fixture.cells[Vector2i(x,y)]=true
	foresight_fixture.player=Vector2i(6,4);foresight_fixture.stairs=Vector2i(10,10);foresight_fixture.relic=Vector2i(10,9);foresight_fixture.turns=20;foresight_fixture.hp=30
	var foresight_actor:Dictionary={"uid":240,"pos":Vector2i(3,6),"hp":30,"max_hp":30,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":0}
	foresight_fixture.enemies.append(foresight_actor)
	var fs_plan:Dictionary=foresight_fixture.enemy_foresight_plan(foresight_actor,foresight_fixture.player)
	if fs_plan.is_empty() or int(fs_plan.get("depth",0))!=2 or fs_plan.get("step")!=Vector2i(3,5) or fs_plan.get("post")!=Vector2i(3,4):failures.append("foresight two step firing post")
	checks+=1
	if int(fs_plan.get("nodes",999))>25 or foresight_actor.pos!=Vector2i(3,6) or foresight_actor.pp_primary!=12 or not foresight_fixture.enemy_actions.is_empty():failures.append("foresight bounded pure planning")
	checks+=1
	foresight_fixture.traps[Vector2i(3,5)]="snare"
	var fs_detour:Dictionary=foresight_fixture.enemy_foresight_plan(foresight_actor,foresight_fixture.player)
	if not fs_detour.is_empty() and fs_detour.get("step")==Vector2i(3,5):failures.append("foresight trap invalidates route")
	foresight_fixture.traps.clear()
	checks+=1
	foresight_actor.pos=Vector2i(3,5)
	if not foresight_fixture.enemy_foresight_plan(foresight_actor,foresight_fixture.player).is_empty():failures.append("foresight defers to immediate position")
	foresight_actor.pos=Vector2i(3,6)
	checks+=1
	foresight_actor.pp_primary=0
	if not foresight_fixture.enemy_foresight_plan(foresight_actor,foresight_fixture.player).is_empty():failures.append("foresight exhausted kit")
	foresight_actor.pp_primary=12
	checks+=1
	foresight_actor.species="thornbeetle"
	var fs_kits:Array[Dictionary]=foresight_fixture.enemy_foresight_kits(foresight_actor)
	if fs_kits.is_empty() or not bool(fs_kits[0].get("charged",false)):failures.append("foresight learned charge candidate")
	foresight_actor.species="leafwisp"
	checks+=1
	foresight_actor["windup"]=true
	if not foresight_fixture.enemy_foresight_plan(foresight_actor,foresight_fixture.player).is_empty():failures.append("foresight preserves committed charge")
	foresight_actor.erase("windup")
	checks+=1
	foresight_fixture.charge_phase="vanish"
	if not foresight_fixture.enemy_foresight_plan(foresight_actor,foresight_fixture.player).is_empty():failures.append("foresight hidden player rejected")
	foresight_fixture.charge_phase=""
	checks+=1
	foresight_actor["cooldown"]=2
	if not foresight_fixture.enemy_foresight_plan(foresight_actor,foresight_fixture.player).is_empty():failures.append("foresight cooling kit rejected")
	checks+=1
	print("KINDRIA_ENEMY_FORESIGHT checks=9")

	# Counterplay supports an actually announced charge, never a guessed attack.
	var cp_fixture=Rules.new()
	for y in range(1,11):
		for x in range(1,11):cp_fixture.cells[Vector2i(x,y)]=true
	cp_fixture.player=Vector2i(5,5);cp_fixture.stairs=Vector2i(10,10);cp_fixture.relic=Vector2i(10,9);cp_fixture.turns=20;cp_fixture.hp=30
	var cp_charger:Dictionary={"uid":260,"pos":Vector2i(5,3),"hp":30,"max_hp":30,"kind":2,"species":"thornbeetle","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":0,"windup":true,"aim":Vector2i.DOWN}
	var cp_guard:Dictionary={"uid":261,"pos":Vector2i(3,5),"hp":30,"max_hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0}
	cp_fixture.enemies.append(cp_charger);cp_fixture.enemies.append(cp_guard)
	if not cp_fixture.enemy_counterplay_charge_tiles(cp_guard,cp_fixture.player).is_empty():failures.append("counterplay requires actual announcement")
	checks+=1
	cp_fixture.enemy_actions.append({"uid":260,"phase":"windup"})
	var cp_tiles:Dictionary=cp_fixture.enemy_counterplay_charge_tiles(cp_guard,cp_fixture.player)
	if not cp_tiles.has(cp_fixture.player) or cp_tiles.has(Vector2i(4,5)):failures.append("counterplay fixed real charge footprint")
	checks+=1
	if cp_fixture.enemy_counterplay_escape_step(cp_guard,cp_fixture.player)!=Vector2i(4,5):failures.append("counterplay legal uncovered escape post")
	checks+=1
	if cp_guard.pos!=Vector2i(3,5) or cp_guard.pp_primary!=0 or cp_charger.pp_primary!=12 or cp_fixture.enemy_actions.size()!=1:failures.append("counterplay pure scoring")
	checks+=1
	cp_fixture.traps[Vector2i(4,5)]="snare"
	if cp_fixture.enemy_counterplay_escape_step(cp_guard,cp_fixture.player)!=cp_guard.pos:failures.append("counterplay avoids hazard")
	cp_fixture.traps.clear()
	checks+=1
	cp_guard.hp=10
	if cp_fixture.enemy_counterplay_escape_step(cp_guard,cp_fixture.player)!=cp_guard.pos:failures.append("counterplay wounded actor excluded")
	cp_guard.hp=30
	checks+=1
	cp_charger.aim=Vector2i.UP
	if cp_fixture.enemy_counterplay_escape_step(cp_guard,cp_fixture.player)!=cp_guard.pos:failures.append("counterplay stale direction not used")
	cp_charger.aim=Vector2i.DOWN
	checks+=1
	cp_fixture.enemies.reverse()
	if cp_fixture.enemy_counterplay_escape_step(cp_guard,cp_fixture.player)!=cp_guard.pos:failures.append("counterplay only earlier actor")
	cp_fixture.enemies.reverse()
	checks+=1
	cp_guard.pp_primary=12
	if cp_fixture.enemy_counterplay_escape_step(cp_guard,cp_fixture.player)!=cp_guard.pos:failures.append("counterplay retains immediate attack")
	cp_guard.pp_primary=0
	checks+=1
	cp_fixture.charge_phase="vanish"
	if cp_fixture.enemy_counterplay_escape_step(cp_guard,cp_fixture.player)!=cp_guard.pos:failures.append("counterplay hidden player rejected")
	cp_fixture.charge_phase=""
	checks+=1
	print("KINDRIA_ENEMY_COUNTERPLAY checks=10")

	# Relative opportunities depend on visible support and realistic accuracy.
	var opp_fixture=Rules.new()
	for y in range(1,11):
		for x in range(1,11):opp_fixture.cells[Vector2i(x,y)]=true
	opp_fixture.player=Vector2i(9,9);opp_fixture.stairs=Vector2i(10,10);opp_fixture.relic=Vector2i(10,9);opp_fixture.turns=20;opp_fixture.hp=30
	var opp_actor:Dictionary={"uid":280,"pos":Vector2i(3,4),"hp":30,"max_hp":30,"kind":0,"species":"eelstrix","ecology_role":"scout","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":0}
	var opp_target:Dictionary={"uid":1280,"pos":Vector2i(5,4),"hp":4,"max_hp":30,"species":"reef_pup"}
	var opp_support:Dictionary={"uid":1281,"pos":Vector2i(5,5),"hp":30,"max_hp":30,"species":"reef_pup"}
	opp_fixture.enemies.append(opp_actor);opp_fixture.allies.append(opp_target)
	var opp_isolated:float=opp_fixture.enemy_target_exposure(opp_actor,opp_target.pos,1280)
	if opp_isolated!=1.25:failures.append("opportunity isolated visible target")
	checks+=1
	opp_fixture.allies.append(opp_support)
	if opp_fixture.enemy_target_exposure(opp_actor,opp_target.pos,1280)>=opp_isolated:failures.append("opportunity visible support reduces exposure")
	checks+=1
	opp_support.hp=0
	if opp_fixture.enemy_target_exposure(opp_actor,opp_target.pos,1280)!=opp_isolated:failures.append("opportunity defeated support excluded")
	opp_support.hp=30
	checks+=1
	opp_fixture.cells.erase(Vector2i(4,4))
	if opp_fixture.enemy_target_exposure(opp_actor,opp_target.pos,1280)!=0.0:failures.append("opportunity hidden target rejected")
	opp_fixture.cells[Vector2i(4,4)]=true
	checks+=1
	var opp_skill:Array=opp_fixture.signature_skill(opp_actor)
	var opp_value:float=opp_fixture.enemy_party_opportunity_value(opp_actor,opp_target,0,opp_skill,false)
	opp_actor["whiffer_turns"]=2
	var opp_low_accuracy:float=opp_fixture.enemy_party_opportunity_value(opp_actor,opp_target,0,opp_skill,false)
	if opp_value<=0.0 or opp_low_accuracy>opp_value*.051:failures.append("opportunity accuracy weights expected and tactical value")
	opp_actor.erase("whiffer_turns")
	checks+=1
	if opp_actor.pp_primary!=12 or int(opp_target.hp)!=4 or not opp_fixture.enemy_actions.is_empty():failures.append("opportunity pure scoring")
	checks+=1
	opp_actor["personality_enabled"]=false
	if opp_fixture.enemy_target_exposure(opp_actor,opp_target.pos,1280)!=0.0:failures.append("opportunity legacy exposure gate")
	opp_actor["personality_enabled"]=true
	checks+=1
	opp_target.hp=0
	if opp_fixture.enemy_party_opportunity_value(opp_actor,opp_target,0,opp_skill,false)!=0.0:failures.append("opportunity defeated target excluded")
	opp_target.hp=4
	checks+=1
	opp_fixture.player=Vector2i(6,4)
	if opp_fixture.enemy_target_exposure(opp_actor,opp_target.pos,1280)!=0.0:failures.append("opportunity player and ally provide support")
	checks+=1
	print("KINDRIA_ENEMY_OPPORTUNITY_ENGINE checks=9")

	# Audit the real dispatch order, not just isolated planner scores.
	var audit_combat=Rules.new()
	for y in range(1,10):
		for x in range(1,10):audit_combat.cells[Vector2i(x,y)]=true
	audit_combat.player=Vector2i(5,4);audit_combat.stairs=Vector2i(9,9);audit_combat.relic=Vector2i(9,8);audit_combat.turns=20;audit_combat.hp=1
	var audit_hunter:Dictionary={"uid":290,"pos":Vector2i(3,4),"hp":30,"max_hp":30,"kind":0,"species":"bramble_pup","signature":"Briar Pounce","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":0,"stages":{"accuracy":10}}
	var audit_friend:Dictionary={"uid":1290,"pos":Vector2i(3,3),"hp":30,"max_hp":30,"species":"reef_pup"}
	audit_combat.enemies.append(audit_hunter);audit_combat.allies.append(audit_friend)
	if not audit_combat.enemy_risk_has_finisher(audit_hunter):failures.append("combat audit credible lethal primary")
	checks+=1
	audit_combat.charge_phase="vanish"
	if audit_combat.enemy_opportunity_eligible(audit_hunter) or audit_combat.enemy_risk_has_finisher(audit_hunter):failures.append("combat audit hidden target no finisher")
	audit_combat.charge_phase=""
	checks+=1
	audit_combat.cells.erase(Vector2i(4,4))
	if audit_combat.enemy_risk_has_finisher(audit_hunter):failures.append("combat audit wall prevents finisher")
	audit_combat.cells[Vector2i(4,4)]=true
	checks+=1
	audit_combat.hp=0
	if audit_combat.enemy_risk_has_finisher(audit_hunter):failures.append("combat audit defeated player no finisher")
	audit_combat.hp=1
	checks+=1
	audit_combat.enemy_turn_actions()
	if audit_combat.hp!=0 or int(audit_friend.hp)!=30 or audit_hunter.pp_primary!=11 or audit_combat.enemy_actions.size()!=1:failures.append("combat audit lethal attack precedes ally diversion")
	checks+=1
	audit_combat.hp=30;audit_combat.player=Vector2i(4,3)
	var audit_supported:float=audit_combat.enemy_target_exposure(audit_hunter,audit_friend.pos,1290)
	audit_combat.charge_phase="vanish"
	if audit_combat.enemy_target_exposure(audit_hunter,audit_friend.pos,1290)<=audit_supported or audit_combat.enemy_target_exposure(audit_hunter,audit_combat.player,-1)!=0.0:failures.append("combat audit hidden player does not provide known support")
	audit_combat.charge_phase=""
	checks+=1
	audit_friend.pos=Vector2i(5,4);audit_combat.cells.erase(Vector2i(4,4))
	if audit_combat.enemy_party_opportunity_value(audit_hunter,audit_friend,0,audit_combat.signature_skill(audit_hunter),false)!=0.0:failures.append("combat audit hidden ally direct scoring rejected")
	checks+=1
	print("KINDRIA_ENEMY_COMBAT_AUDIT checks=7")

	# Shared live contact must not replace last-known target pursuit.
	var living_fixture=Rules.new()
	for y in range(1,9):
		for x in range(1,9):living_fixture.cells[Vector2i(x,y)]=true
	living_fixture.player=Vector2i(4,4);living_fixture.stairs=Vector2i(8,8);living_fixture.relic=Vector2i(8,7);living_fixture.turns=20
	var living_actor:Dictionary={"uid":300,"pos":Vector2i(3,4),"hp":5,"max_hp":30,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":0}
	living_fixture.enemies.append(living_actor)
	living_fixture.player_stages["attack"]=2
	if not living_fixture.enemy_live_contact(living_actor,living_fixture.player) or living_fixture.enemy_retreat_step(living_actor,living_fixture.player)==living_actor.pos:failures.append("living dungeon visible threat")
	checks+=1
	living_fixture.enemy_pursuit_target(living_actor,living_fixture.player)
	living_fixture.charge_phase="vanish";living_fixture.player=Vector2i(4,5)
	if living_fixture.enemy_live_contact(living_actor,living_fixture.player) or living_fixture.enemy_pursuit_target(living_actor,living_fixture.player)!=Vector2i(4,4):failures.append("living dungeon separates memory and live contact")
	checks+=1
	living_fixture.player=Vector2i(4,4)
	if living_fixture.enemy_retreat_step(living_actor,living_fixture.player)!=living_actor.pos or living_fixture.enemy_cautious_spacing_step(living_actor,living_fixture.player)!=living_actor.pos:failures.append("living dungeon hidden survival tactics rejected")
	checks+=1
	living_fixture.shield_turns=2;living_fixture.shield_kind="protect"
	if living_fixture.enemy_counter_protected(living_actor,living_fixture.player):failures.append("living dungeon hidden shield counter rejected")
	checks+=1
	living_fixture.enemy_record_push_pressure(living_actor);living_fixture.enemy_remember_incoming(living_actor,5,"normal")
	if living_actor.has("push_pressure_turn") or living_actor.has("incoming_turn"):failures.append("living dungeon hidden attack observation rejected")
	checks+=1
	living_fixture.charge_phase="";living_fixture.player_boons["decoy"]=2
	if living_fixture.enemy_live_contact(living_actor,living_fixture.player) or living_fixture.enemy_exit_block_step(living_actor,living_fixture.player)!=living_actor.pos:failures.append("living dungeon decoy contact rejected")
	living_fixture.player_boons.clear()
	checks+=1
	living_fixture.hp=0
	if living_fixture.enemy_live_contact(living_actor,living_fixture.player):failures.append("living dungeon defeated player rejected")
	living_fixture.hp=30
	checks+=1
	living_fixture.enemy_record_push_pressure(living_actor);living_fixture.enemy_remember_incoming(living_actor,5,"normal")
	if living_actor.get("push_pressure_turn")!=20 or living_actor.get("incoming_turn")!=20:failures.append("living dungeon real observation restored")
	checks+=1
	print("KINDRIA_LIVING_DUNGEON checks=8")

	var stall_fixture=Rules.new()
	for y in range(1,9):
		for x in range(1,9):stall_fixture.cells[Vector2i(x,y)]=true
	stall_fixture.player=Vector2i(5,4);stall_fixture.stairs=Vector2i(8,8);stall_fixture.relic=Vector2i(8,7);stall_fixture.turns=20
	var stall_actor:Dictionary={"uid":310,"pos":Vector2i(3,5),"hp":30,"max_hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":0}
	stall_fixture.enemies.append(stall_actor)
	stall_fixture.enemy_record_stall(stall_actor,stall_fixture.player)
	stall_fixture.enemy_record_stall(stall_actor,stall_fixture.player)
	if stall_actor.get("stall_count")!=1:failures.append("unstall one observation per turn")
	checks+=1
	stall_fixture.turns=21;stall_fixture.enemy_record_stall(stall_actor,stall_fixture.player)
	stall_fixture.turns=22
	var stall_step:Vector2i=stall_fixture.enemy_unstall_step(stall_actor,stall_fixture.player)
	if stall_step==stall_actor.pos or not stall_fixture.enemy_ambush_safe_tile(stall_step):failures.append("unstall useful legal detour")
	checks+=1
	if stall_actor.pos!=Vector2i(3,5) or stall_actor.pp_primary!=12 or not stall_fixture.enemy_actions.is_empty():failures.append("unstall pure planning")
	checks+=1
	stall_actor["unstall_turn"]=21
	if stall_fixture.enemy_unstall_step(stall_actor,stall_fixture.player)!=stall_actor.pos:failures.append("unstall retry gate")
	stall_actor.erase("unstall_turn")
	checks+=1
	stall_fixture.shield_kind="protect";stall_fixture.shield_turns=1
	if stall_fixture.enemy_unstall_step(stall_actor,stall_fixture.player)!=stall_actor.pos:failures.append("unstall intentional protection wait")
	stall_fixture.shield_turns=0
	checks+=1
	stall_fixture.charge_phase="vanish"
	if stall_fixture.enemy_unstall_step(stall_actor,stall_fixture.player)!=stall_actor.pos:failures.append("unstall no hidden pursuit")
	stall_fixture.charge_phase=""
	checks+=1
	stall_fixture.turns=24
	if stall_fixture.enemy_unstall_step(stall_actor,stall_fixture.player)!=stall_actor.pos:failures.append("unstall stale observations rejected")
	checks+=1
	# Three-step detour around a friendly frontline; no learned move is available.
	var detour_fixture=Rules.new()
	for y in range(2,7):
		for x in range(1,7):detour_fixture.cells[Vector2i(x,y)]=true
	detour_fixture.player=Vector2i(4,4);detour_fixture.stairs=Vector2i(6,6);detour_fixture.relic=Vector2i(6,5);detour_fixture.turns=22
	var detour_actor:Dictionary={"uid":311,"pos":Vector2i(2,4),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0,"stall_count":2,"stall_turn":21,"stall_target":Vector2i(4,4)}
	detour_fixture.enemies.append(detour_actor)
	detour_fixture.enemies.append({"uid":312,"pos":Vector2i(3,4),"hp":30,"kind":0,"species":"rootgnawer","pp_primary":0,"pp_secondary":0})
	detour_fixture.enemies.append({"uid":313,"pos":Vector2i(4,3),"hp":30,"kind":0,"species":"rootgnawer","pp_primary":0,"pp_secondary":0})
	var detour_result:Vector2i=detour_fixture.enemy_unstall_step(detour_actor,detour_fixture.player)
	if detour_result!=Vector2i(2,5):failures.append("unstall extended friendly frontline detour")
	checks+=1
	if detour_actor.pos!=Vector2i(2,4) or detour_actor.pp_primary!=0 or not detour_fixture.enemy_actions.is_empty():failures.append("unstall extended plan purity")
	checks+=1
	detour_fixture.traps[Vector2i(2,5)]="snare"
	detour_fixture.traps[Vector2i(2,3)]="snare"
	detour_fixture.traps[Vector2i(1,4)]="snare"
	if detour_fixture.enemy_unstall_step(detour_actor,detour_fixture.player)!=detour_actor.pos:failures.append("unstall extended no safe exits")
	checks+=1
	# A reserve is justified only by a complete, live friendly frontline.
	var ring_fixture=Rules.new()
	for y in range(1,8):
		for x in range(1,8):ring_fixture.cells[Vector2i(x,y)]=true
	ring_fixture.player=Vector2i(4,4);ring_fixture.stairs=Vector2i(7,7);ring_fixture.relic=Vector2i(7,6);ring_fixture.turns=22
	var ring_actor:Dictionary={"uid":330,"pos":Vector2i(2,4),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0}
	ring_fixture.enemies.append(ring_actor)
	for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		ring_fixture.enemies.append({"uid":330+ring_fixture.enemies.size(),"pos":ring_fixture.player+d,"hp":30,"kind":0,"species":"rootgnawer","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0})
	if not ring_fixture.enemy_encircled_frontline(ring_actor,ring_fixture.player):failures.append("reserve complete live frontline")
	checks+=1
	ring_fixture.enemies[1]["sleep_turns"]=2
	if ring_fixture.enemy_encircled_frontline(ring_actor,ring_fixture.player):failures.append("reserve sleeping peer cannot justify hold")
	checks+=1
	ring_fixture.enemies[1].erase("sleep_turns")
	ring_actor["reserve_hold_turn"]=21;ring_actor["reserve_hold_target"]=ring_fixture.player;ring_actor["unstall_turn"]=21
	ring_fixture.enemies.remove_at(1)
	if ring_fixture.enemy_encircled_frontline(ring_actor,ring_fixture.player) or ring_fixture.enemy_unstall_step(ring_actor,ring_fixture.player)!=Vector2i(3,4):failures.append("reserve immediately exploits opening")
	checks+=1
	if ring_actor.pos!=Vector2i(2,4) or ring_actor.pp_primary!=0 or not ring_fixture.enemy_actions.is_empty():failures.append("reserve reentry planning purity")
	checks+=1
	ring_fixture.turns=24
	if ring_fixture.enemy_unstall_step(ring_actor,ring_fixture.player)!=ring_actor.pos:failures.append("reserve stale reentry rejected")
	checks+=1
	# Real dispatch, not a synthetic call to the reserve planner.
	ring_fixture.turns=30;ring_fixture.hp=10000;ring_fixture.max_hp=10000;ring_fixture.belly_tenths=1000
	ring_actor.erase("reserve_hold_turn");ring_actor.erase("reserve_hold_target");ring_actor.erase("unstall_turn")
	ring_actor["pp_support"]=0;ring_actor["pp_control"]=0
	ring_fixture.enemies.insert(1,{"uid":331,"pos":Vector2i(3,4),"hp":30,"kind":0,"species":"rootgnawer","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0,"pp_support":0,"pp_control":0})
	for peer in ring_fixture.enemies:
		peer["pp_support"]=0;peer["pp_control"]=0
	for tick in range(3):ring_fixture.enemy_turn_actions()
	if int(ring_actor.get("reserve_hold_turn",-1))!=ring_fixture.turns or ring_actor.pos!=Vector2i(2,4):failures.append("reserve live dispatcher holds closed ring")
	checks+=1
	ring_fixture.enemies.remove_at(1)
	var previous_turn:int=ring_fixture.turns
	ring_fixture.enemy_turn_actions()
	var reserve_actions:int=0
	for action in ring_fixture.enemy_actions:
		if int(action.get("uid",-1))==330:reserve_actions+=1
	if ring_actor.pos!=Vector2i(3,4) or reserve_actions!=1 or ring_fixture.turns!=previous_turn+1:failures.append("reserve live dispatcher reenters on next turn")
	checks+=1
	if ring_actor.has("reserve_hold_turn") or ring_actor.pp_primary!=0:failures.append("reserve live dispatcher clears hold without spending PP")
	checks+=1
	# A wall-assisted frontline has fewer walkable cardinal entrances.
	var wall_ring=Rules.new()
	for y in range(1,8):
		for x in range(1,8):wall_ring.cells[Vector2i(x,y)]=true
	wall_ring.player=Vector2i(1,4);wall_ring.stairs=Vector2i(7,7);wall_ring.relic=Vector2i(7,6);wall_ring.turns=22
	var wall_reserve:Dictionary={"uid":340,"pos":Vector2i(3,4),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0}
	wall_ring.enemies.append(wall_reserve)
	for d in [Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		wall_ring.enemies.append({"uid":340+wall_ring.enemies.size(),"pos":wall_ring.player+d,"hp":30,"kind":0,"species":"rootgnawer","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0})
	if not wall_ring.enemy_encircled_frontline(wall_reserve,wall_ring.player):failures.append("reserve wall assisted frontline")
	checks+=1
	wall_ring.enemies.remove_at(1)
	wall_ring.traps[Vector2i(2,4)]="snare"
	if wall_ring.enemy_encircled_frontline(wall_reserve,wall_ring.player):failures.append("reserve trap not a wall")
	checks+=1
	wall_ring.traps.clear()
	wall_reserve["reserve_hold_turn"]=21;wall_reserve["reserve_hold_target"]=wall_ring.player
	if wall_ring.enemy_unstall_step(wall_reserve,wall_ring.player)!=Vector2i(2,4):failures.append("reserve wall frontline opening")
	checks+=1
	wall_ring.enemies.remove_at(2)
	wall_ring.cells.erase(Vector2i(1,5))
	wall_ring.cells.erase(Vector2i(2,4))
	if wall_ring.enemy_encircled_frontline(wall_reserve,wall_ring.player):failures.append("reserve wall alone insufficient")
	checks+=1
	# A blocked player route does not make a visible opposing ally irrelevant.
	var party_recovery=Rules.new()
	for y in range(1,8):
		for x in range(1,8):party_recovery.cells[Vector2i(x,y)]=true
	party_recovery.player=Vector2i(4,4);party_recovery.stairs=Vector2i(7,7);party_recovery.relic=Vector2i(7,6);party_recovery.turns=22
	var party_reserve:Dictionary={"uid":350,"pos":Vector2i(2,4),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0,"stall_count":2,"stall_turn":21,"stall_target":Vector2i(4,4)}
	party_recovery.enemies.append(party_reserve)
	party_recovery.allies.append({"uid":1000,"pos":Vector2i(2,1),"hp":30,"max_hp":30})
	if party_recovery.enemy_unstall_party_step(party_reserve,party_recovery.player)!=Vector2i(2,3):failures.append("party recovery visible ally shortest post")
	checks+=1
	if party_reserve.pos!=Vector2i(2,4) or party_reserve.pp_primary!=0 or not party_recovery.enemy_actions.is_empty():failures.append("party recovery pure planning")
	checks+=1
	party_recovery.cells.erase(Vector2i(2,3))
	if party_recovery.enemy_unstall_party_step(party_reserve,party_recovery.player)!=party_reserve.pos:failures.append("party recovery no hidden ally pursuit")
	checks+=1
	party_recovery.cells[Vector2i(2,3)]=true
	party_recovery.allies[0].hp=0
	if party_recovery.enemy_unstall_party_step(party_reserve,party_recovery.player)!=party_reserve.pos:failures.append("party recovery ignores defeated ally")
	checks+=1
	party_recovery.allies[0].hp=30
	for d in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:party_recovery.traps[party_reserve.pos+d]="snare"
	if party_recovery.enemy_unstall_party_step(party_reserve,party_recovery.player)!=party_reserve.pos:failures.append("party recovery avoids trapped exits")
	checks+=1
	# Compare memoized geometry against the underlying pure queries.
	var memo_peers:Array[Dictionary]=[]
	for other in ring_fixture.enemies:
		if ring_fixture.enemy_squad_partner(ring_actor,other):memo_peers.append(other)
	var memo_lanes:Dictionary={}
	var memo_attacks:Dictionary={}
	for y in range(2,6):
		for x in range(2,6):
			var q:=Vector2i(x,y)
			var blocked:bool=false
			for other in memo_peers:
				if ring_fixture.enemy_relief_blocks_lane(other,q,ring_fixture.player):blocked=true;break
			var expected:bool=ring_fixture.enemy_strategy_attack_tile(ring_actor,q,ring_fixture.player)
			if ring_fixture.enemy_recovery_lane_blocked(memo_peers,q,ring_fixture.player,memo_lanes)!=blocked or ring_fixture.enemy_recovery_lane_blocked(memo_peers,q,ring_fixture.player,memo_lanes)!=blocked:failures.append("recovery memo lane equivalence")
			checks+=1
			if ring_fixture.enemy_recovery_attack_tile(ring_actor,q,ring_fixture.player,memo_attacks)!=expected or ring_fixture.enemy_recovery_attack_tile(ring_actor,q,ring_fixture.player,memo_attacks)!=expected:failures.append("recovery memo attack equivalence")
			checks+=1
	if memo_lanes.size()!=16 or memo_attacks.size()!=16:failures.append("recovery memo one entry per tile")
	checks+=1
	# A sleeping peer obstructs movement but does not qualify as an active reserve guard.
	var congestion=Rules.new()
	for y in range(1,8):
		for x in range(1,8):congestion.cells[Vector2i(x,y)]=true
	congestion.player=Vector2i(4,4);congestion.stairs=Vector2i(7,7);congestion.relic=Vector2i(7,6);congestion.turns=22
	var waiting:Dictionary={"uid":360,"pos":Vector2i(2,4),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0}
	congestion.enemies.append(waiting)
	for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		congestion.enemies.append({"uid":360+congestion.enemies.size(),"pos":congestion.player+d,"hp":30,"kind":0,"species":"rootgnawer","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0})
	congestion.enemies[1]["sleep_turns"]=2
	if not congestion.enemy_occupied_frontline(waiting,congestion.player) or congestion.enemy_encircled_frontline(waiting,congestion.player):failures.append("physical congestion distinct from active ring")
	checks+=1
	waiting["congestion_hold_turn"]=21;waiting["congestion_hold_target"]=congestion.player;waiting["unstall_turn"]=21
	congestion.enemies.remove_at(1)
	if congestion.enemy_occupied_frontline(waiting,congestion.player) or congestion.enemy_unstall_step(waiting,congestion.player)!=Vector2i(3,4):failures.append("physical congestion vacancy immediate recovery")
	checks+=1
	if waiting.pos!=Vector2i(2,4) or waiting.pp_primary!=0 or not congestion.enemy_actions.is_empty():failures.append("physical congestion planning purity")
	checks+=1
	congestion.turns=24
	if congestion.enemy_unstall_step(waiting,congestion.player)!=waiting.pos:failures.append("physical congestion stale hold")
	checks+=1
	# A recently observed escape invalidates the old reserve formation.
	var escape_fixture=Rules.new()
	for y in range(1,8):
		for x in range(1,8):escape_fixture.cells[Vector2i(x,y)]=true
	escape_fixture.player=Vector2i(4,5);escape_fixture.stairs=Vector2i(7,7);escape_fixture.relic=Vector2i(7,6);escape_fixture.turns=22
	var escape_actor:Dictionary={"uid":370,"pos":Vector2i(2,4),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0,"reserve_hold_turn":21,"reserve_hold_target":Vector2i(4,4),"unstall_turn":21}
	escape_fixture.enemies.append(escape_actor)
	var escape_step:Vector2i=escape_fixture.enemy_unstall_step(escape_actor,escape_fixture.player)
	if escape_step==escape_actor.pos or not escape_fixture.enemy_ambush_safe_tile(escape_step):failures.append("reserve observed escape reentry")
	checks+=1
	escape_actor.erase("reserve_hold_turn");escape_actor.erase("reserve_hold_target")
	escape_actor["congestion_hold_turn"]=21;escape_actor["congestion_hold_target"]=Vector2i(4,4)
	if escape_fixture.enemy_unstall_step(escape_actor,escape_fixture.player)!=escape_step:failures.append("congestion observed escape reentry")
	checks+=1
	escape_fixture.charge_phase="vanish"
	if escape_fixture.enemy_unstall_step(escape_actor,escape_fixture.player)!=escape_actor.pos:failures.append("reserve escape no hidden tracking")
	checks+=1
	escape_fixture.charge_phase=""
	escape_fixture.turns=24
	if escape_fixture.enemy_unstall_step(escape_actor,escape_fixture.player)!=escape_actor.pos:failures.append("reserve escape expired observation")
	checks+=1
	escape_fixture.turns=22;escape_actor["congestion_hold_target"]=Vector2i(7,7)
	if escape_fixture.enemy_unstall_step(escape_actor,escape_fixture.player)!=escape_actor.pos:failures.append("reserve distant escape no stale shortcut")
	checks+=1
	# Expiration is independent of the next selected action.
	escape_fixture.turns=22
	escape_actor["reserve_hold_turn"]=20;escape_actor["reserve_hold_target"]=Vector2i(4,4)
	escape_actor["congestion_hold_turn"]=19;escape_actor["congestion_hold_target"]=Vector2i(4,4)
	escape_fixture.enemy_expire_frontline_holds(escape_actor)
	if not escape_actor.has("reserve_hold_turn") or escape_actor.has("congestion_hold_turn") or escape_actor.has("congestion_hold_target"):failures.append("frontline holds independent expiry")
	checks+=1
	escape_fixture.turns=23
	escape_actor["sleep_turns"]=2
	escape_fixture.enemy_expire_frontline_holds(escape_actor)
	if escape_actor.has("reserve_hold_turn") or escape_actor.has("reserve_hold_target"):failures.append("frontline holds expire during sleep")
	checks+=1
	escape_actor["reserve_hold_turn"]=24;escape_actor["reserve_hold_target"]=Vector2i(4,4)
	escape_fixture.enemy_expire_frontline_holds(escape_actor)
	if escape_actor.has("reserve_hold_turn") or escape_actor.has("reserve_hold_target"):failures.append("frontline future timestamp rejected")
	checks+=1
	print("KINDRIA_ANTI_STALL checks=72")
	# A direct witness may report a tile, but a listener cannot relay it.
	var comm=Rules.new()
	for x in range(1,4):comm.cells[Vector2i(x,3)]=true
	for y in range(1,4):comm.cells[Vector2i(1,y)]=true
	for y in range(3,6):comm.cells[Vector2i(3,y)]=true
	comm.cells[Vector2i(8,8)]=true
	comm.player=Vector2i(3,5);comm.stairs=Vector2i(9,9);comm.relic=Vector2i(9,8)
	var listener:Dictionary={"uid":0,"pos":Vector2i(1,3),"hp":20,"max_hp":20,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	var witness:Dictionary={"uid":1,"pos":Vector2i(3,3),"hp":20,"max_hp":20,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	var remote:Dictionary={"uid":2,"pos":Vector2i(1,1),"hp":20,"max_hp":20,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	comm.enemies.append(listener);comm.enemies.append(witness);comm.enemies.append(remote)
	comm.turns=10
	comm.enemy_share_alerts(comm.player)
	if listener.get("alert_tile")!=comm.player or listener.get("alert_source")!=1 or listener.get("alert_until")!=12 or witness.has("alert_tile"):failures.append("communication first-hand local report")
	checks+=1
	if remote.has("alert_tile"):failures.append("communication no relay or wall crossing")
	checks+=1
	comm.player=Vector2i(8,8)
	comm.turns=11;comm.enemy_share_alerts(comm.player)
	if comm.enemy_pursuit_target(listener,comm.player)!=Vector2i(3,5) or listener.get("alert_until")!=12:failures.append("communication stale report not refreshed")
	checks+=1
	listener["last_seen_player"]=Vector2i(2,3);listener["last_seen_turn"]=11;listener["last_seen_until"]=15
	if comm.enemy_pursuit_target(listener,comm.player)!=Vector2i(2,3):failures.append("communication firsthand memory precedence")
	checks+=1
	listener.erase("last_seen_player");listener.erase("last_seen_turn");listener.erase("last_seen_until")
	comm.turns=13
	if comm.enemy_alert_target(listener)!=listener.pos or listener.has("alert_tile"):failures.append("communication report expiry")
	checks+=1
	comm.player=Vector2i(3,5)
	witness["sleep_turns"]=2
	comm.enemy_share_alerts(comm.player)
	if listener.has("alert_tile"):failures.append("communication sleeping witness")
	witness.erase("sleep_turns")
	checks+=1
	listener["confusion_turns"]=2
	comm.enemy_share_alerts(comm.player)
	if listener.has("alert_tile"):failures.append("communication confused listener")
	listener.erase("confusion_turns")
	checks+=1
	comm.charge_phase="vanish"
	comm.enemy_share_alerts(comm.player)
	if listener.has("alert_tile"):failures.append("communication hidden charge")
	comm.charge_phase=""
	checks+=1
	comm.enemy_share_alerts(comm.player)
	comm.player_boons["decoy"]=2
	comm.enemy_share_alerts(comm.player)
	if listener.has("alert_tile"):failures.append("communication decoy invalidates reports")
	comm.player_boons.clear()
	checks+=1
	comm.enemy_turn_actions()
	var listener_moves:int=0
	for action in comm.enemy_actions:
		if int(action.get("uid",-1))==0 and action.get("phase","")=="move":listener_moves+=1
	if listener.pos!=Vector2i(2,3) or listener_moves!=1 or listener.pp_primary!=0:failures.append("communication real single investigation movement")
	checks+=1
	print("KINDRIA_ENEMY_COMMUNICATION checks=10")
	# Temperament influences ordinary choices, not actual damage or PP.
	var personality=Rules.new()
	for y in range(1,9):
		for x in range(1,9):personality.cells[Vector2i(x,y)]=true
	personality.player=Vector2i(4,4);personality.stairs=Vector2i(8,8);personality.relic=Vector2i(8,7)
	var cautious:Dictionary={"uid":0,"pos":Vector2i(3,4),"hp":20,"max_hp":20,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":0}
	personality.enemies.append(cautious)
	if personality.enemy_combat_personality(cautious)!="cautious" or personality.enemy_combat_personality({"species":"rootgnawer"})!="territorial" or personality.enemy_combat_personality({"species":"bramble_pup"})!="hunter" or personality.enemy_combat_personality({"species":"mossmite"})!="defender" or personality.enemy_combat_personality({"species":"eelstrix"})!="opportunist":failures.append("personality mapping")
	checks+=1
	if personality.enemy_cautious_spacing_step(cautious,personality.player)!=cautious.pos:failures.append("personality no spacing without threat")
	checks+=1
	personality.player_stages["attack"]=2
	var spacing:Vector2i=personality.enemy_cautious_spacing_step(cautious,personality.player)
	if spacing!=Vector2i(2,4) or cautious.pos!=Vector2i(3,4) or cautious.pp_primary!=12:failures.append("personality cautious spacing purity")
	checks+=1
	personality.traps[spacing]="snare"
	if personality.enemy_cautious_spacing_step(cautious,personality.player)==spacing:failures.append("personality hazard avoidance")
	personality.traps.clear()
	checks+=1
	cautious["spacing_count"]=2
	if personality.enemy_cautious_spacing_step(cautious,personality.player)!=cautious.pos:failures.append("personality spacing cap")
	cautious.erase("spacing_count")
	checks+=1
	cautious["windup"]=true
	if personality.enemy_cautious_spacing_step(cautious,personality.player)!=cautious.pos:failures.append("personality preserves charged attack")
	cautious.erase("windup")
	checks+=1
	personality.enemy_turn_actions()
	if cautious.pos!=spacing or cautious.pp_primary!=12 or cautious.get("spacing_count",0)!=1 or personality.enemy_actions.size()!=1 or personality.enemy_actions[0].get("phase","")!="move":failures.append("personality actual movement budget")
	checks+=1
	var hunter:Dictionary={"species":"bramble_pup","ecology_role":"hunter","personality_enabled":true}
	if personality.enemy_memory_duration(hunter)!=5 or personality.enemy_memory_duration({"species":"bramble_pup","ecology_role":"hunter"})!=4:failures.append("personality hunter memory")
	checks+=1
	var opportunist:Dictionary={"species":"eelstrix","personality_enabled":true}
	var opportunist_skill:Array=personality.signature_skill(opportunist)
	if personality.enemy_personality_bonus(opportunist,opportunist_skill,1.0)<=0.0 or personality.enemy_personality_bonus(opportunist,opportunist_skill,0.0)!=0.0 or personality.enemy_personality_control_bonus(opportunist)<=0.0:failures.append("personality useful effect only")
	checks+=1
	var territorial:Dictionary={"uid":1,"pos":Vector2i(2,2),"hp":20,"kind":0,"species":"rootgnawer","ecology_home":Vector2i(4,2),"personality_enabled":true}
	personality.enemies.clear();personality.enemies.append(territorial)
	if personality.enemy_territorial_idle_step(territorial)!=Vector2i(3,2):failures.append("personality territorial home return")
	checks+=1
	territorial["monster_house"]=true
	if personality.enemy_territorial_idle_step(territorial)!=territorial.pos:failures.append("personality house territory exception")
	checks+=1
	print("KINDRIA_COMBAT_PERSONALITY checks=11")
	# Actual resolved outcomes inform future preferences, not damage formulas.
	var combat_memory=Rules.new()
	for y in range(1,8):
		for x in range(1,8):combat_memory.cells[Vector2i(x,y)]=true
	combat_memory.player=Vector2i(4,4);combat_memory.stairs=Vector2i(7,7);combat_memory.relic=Vector2i(7,6)
	var memory_actor:Dictionary={"uid":0,"pos":Vector2i(3,4),"hp":40,"max_hp":40,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":10}
	combat_memory.enemies.append(memory_actor)
	combat_memory.turns=20
	var memory_skill:Array=combat_memory.signature_skill(memory_actor)
	var original_score:float=combat_memory.enemy_attack_score(memory_actor,memory_skill,false)
	combat_memory.enemy_remember_result(memory_actor,-1,"primary",.5,false,false)
	if combat_memory.enemy_attack_score(memory_actor,memory_skill,false)>=original_score or combat_memory.enemy_observed_attack_weight(memory_actor,-1,"secondary")!=1.0:failures.append("combat memory slot-specific resistance")
	checks+=1
	combat_memory.enemy_remember_result(memory_actor,-1,"primary",0.0,true,false)
	combat_memory.enemy_remember_result(memory_actor,-1,"primary",0.0,false,true)
	if combat_memory.enemy_observed_attack_weight(memory_actor,-1,"primary")!=.85:failures.append("combat memory ignores miss and protection")
	checks+=1
	combat_memory.enemy_remember_result(memory_actor,1000,"primary",2.0,false,false)
	if combat_memory.enemy_observed_attack_weight(memory_actor,1000,"primary")<=1.0 or combat_memory.enemy_observed_attack_weight(memory_actor,-1,"primary")!=.85:failures.append("combat memory target isolation")
	checks+=1
	combat_memory.turns=27
	if combat_memory.enemy_observed_attack_weight(memory_actor,-1,"primary")!=1.0:failures.append("combat memory expiry")
	checks+=1
	for target_uid in range(1010,1022):
		combat_memory.turns+=1
		combat_memory.enemy_remember_result(memory_actor,target_uid,"primary",.5,false,false)
	if memory_actor.combat_observations.size()!=Rules.ENEMY_MEMORY_CAP or memory_actor.combat_observations.has("-1:primary"):failures.append("combat memory bounded eviction")
	checks+=1
	combat_memory.enemy_remember_incoming(memory_actor,9,"fire")
	if combat_memory.enemy_recent_threat(memory_actor):failures.append("combat memory trivial damage threshold")
	checks+=1
	combat_memory.enemy_remember_incoming(memory_actor,12,"fire")
	if not combat_memory.enemy_recent_threat(memory_actor) or combat_memory.enemy_cautious_spacing_step(memory_actor,combat_memory.player)!=Vector2i(2,4):failures.append("combat memory observed threat spacing")
	checks+=1
	combat_memory.turns+=4
	if combat_memory.enemy_recent_threat(memory_actor):failures.append("combat memory threat expiry")
	checks+=1
	combat_memory.player=Vector2i(6,4);combat_memory.cells.erase(Vector2i(5,4))
	combat_memory.enemy_remember_incoming(memory_actor,20,"fire")
	if combat_memory.enemy_recent_threat(memory_actor):failures.append("combat memory no unseen attacker inference")
	combat_memory.cells[Vector2i(5,4)]=true
	checks+=1
	combat_memory.player=Vector2i(4,4)
	memory_actor["pp_secondary"]=0
	combat_memory.enemy_turn_actions()
	if combat_memory.enemy_actions.size()!=1 or not memory_actor.combat_observations.has("-1:primary") or memory_actor.pp_primary!=11:failures.append("combat memory real attack records once")
	checks+=1
	print("KINDRIA_COMBAT_MEMORY checks=10")
	# Setup evaluates usable, visible follow-ups, not mere enemy proximity.
	var combo_fixture=Rules.new()
	for y in range(1,8):
		for x in range(1,8):combo_fixture.cells[Vector2i(x,y)]=true
	combo_fixture.player=Vector2i(4,4)
	var setup_actor:Dictionary={"uid":0,"pos":Vector2i(3,4),"hp":30,"kind":0,"species":"coralcrab","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0,"pp_control":5}
	var follow_actor:Dictionary={"uid":1,"pos":Vector2i(4,3),"hp":30,"kind":0,"species":"bramble_pup","ecology_search_enabled":true,"pp_primary":10,"pp_secondary":0}
	combo_fixture.enemies.append(setup_actor);combo_fixture.enemies.append(follow_actor)
	var combo_move:Dictionary=Rules.MOVE_LIBRARY["eos_192"]
	var combo_debuff:Dictionary={"stat_changes":{"defense":-1}}
	var available:float=combo_fixture.enemy_combo_setup_bonus(setup_actor,combo_move)
	if available<=0.0 or combo_fixture.enemy_combo_followup(follow_actor,combo_debuff,0)<=0.0:failures.append("combo available physical followup")
	checks+=1
	follow_actor.pp_primary=0
	if combo_fixture.enemy_combo_setup_bonus(setup_actor,combo_move)!=0.0:failures.append("combo exhausted partner")
	checks+=1
	follow_actor.pp_primary=10;follow_actor["cooldown"]=2
	if combo_fixture.enemy_combo_setup_bonus(setup_actor,combo_move)!=0.0:failures.append("combo cooldown partner")
	checks+=1
	follow_actor.cooldown=0;follow_actor["sleep_turns"]=2
	if combo_fixture.enemy_combo_setup_bonus(setup_actor,combo_move)!=0.0:failures.append("combo incapacitated partner")
	checks+=1
	follow_actor.sleep_turns=0;follow_actor["sealed_moves"]=["primary"]
	if combo_fixture.enemy_combo_setup_bonus(setup_actor,combo_move)!=0.0:failures.append("combo sealed attack")
	checks+=1
	follow_actor.sealed_moves=[];follow_actor.pos=Vector2i(6,6)
	if combo_fixture.enemy_combo_setup_bonus(setup_actor,combo_move)!=0.0:failures.append("combo unreachable followup")
	checks+=1
	follow_actor.pos=Vector2i(4,3)
	if combo_fixture.enemy_combo_followup(follow_actor,{"stat_changes":{"sp_defense":-1}},0)!=0.0:failures.append("combo irrelevant defense")
	checks+=1
	combo_fixture.player_stages["defense"]=-2
	if combo_fixture.enemy_combo_followup(follow_actor,combo_debuff,0)!=0.0:failures.append("combo redundant defense")
	checks+=1
	combo_fixture.player_stages.clear()
	var charged_skill:Array=combo_fixture.signature_skill(follow_actor).duplicate()
	charged_skill[1]=true
	var idle_charge_score:float=combo_fixture.enemy_attack_score(follow_actor,charged_skill,false)
	combo_fixture.player_boons["hostile_paralysis"]=5
	if combo_fixture.enemy_attack_score(follow_actor,charged_skill,false)<=idle_charge_score or combo_fixture.enemy_status_utility(setup_actor,combo_move)!=0.0:failures.append("combo charged window and no repeat paralysis")
	checks+=1
	if setup_actor.pp_control!=5 or follow_actor.pp_primary!=10 or not combo_fixture.enemy_actions.is_empty():failures.append("combo scoring pure")
	checks+=1
	print("KINDRIA_ATTACK_COMBINATIONS checks=10")
	# A setup must benefit actors who still have a turn, not spent actions.
	var sequencing=Rules.new()
	for y in range(1,8):
		for x in range(1,8):sequencing.cells[Vector2i(x,y)]=true
	sequencing.player=Vector2i(4,4)
	sequencing.hp=100;sequencing.max_hp=100
	var sequence_setup:Dictionary={"uid":1,"pos":Vector2i(3,4),"hp":30,"kind":0,"species":"coralcrab","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0,"pp_control":5}
	var sequence_partner:Dictionary={"uid":2,"pos":Vector2i(4,3),"hp":30,"kind":0,"species":"bramble_pup","ecology_search_enabled":true,"pp_primary":10,"pp_secondary":0}
	sequencing.enemies.append(sequence_setup);sequencing.enemies.append(sequence_partner)
	var sequence_debuff:Dictionary={"stat_changes":{"defense":-1}}
	if sequencing.enemy_combo_setup_bonus(sequence_setup,sequence_debuff)<=0.0:failures.append("sequence later ready partner")
	checks+=1
	sequencing.enemies.reverse()
	if sequencing.enemy_combo_setup_bonus(sequence_setup,sequence_debuff)!=0.0:failures.append("sequence earlier spent partner excluded")
	sequencing.enemies.reverse()
	checks+=1
	sequence_partner.species="thornbeetle"
	if sequencing.enemy_combo_setup_bonus(sequence_setup,sequence_debuff)!=0.0:failures.append("sequence unstarted charge not immediate")
	checks+=1
	sequence_partner["windup"]=true;sequence_partner["aim"]=Vector2i.DOWN
	if sequencing.enemy_combo_setup_bonus(sequence_setup,sequence_debuff)<=0.0:failures.append("sequence committed charge can follow")
	checks+=1
	sequence_partner["aim"]=Vector2i.UP
	if sequencing.enemy_combo_setup_bonus(sequence_setup,sequence_debuff)!=0.0:failures.append("sequence fixed charge cannot reaim")
	checks+=1
	sequence_partner.erase("windup");sequence_partner.erase("aim");sequence_partner.species="bramble_pup"
	sequence_partner["sleep_turns"]=2
	if sequencing.enemy_combo_followup(sequence_partner,sequence_debuff,0)!=0.0:failures.append("sequence incapacitated followup")
	sequence_partner.erase("sleep_turns")
	checks+=1
	sequence_setup["whiffer_turns"]=2
	if sequencing.enemy_status_utility(sequence_setup,Rules.MOVE_LIBRARY["eos_192"])!=0.0:failures.append("sequence guaranteed status miss rejected")
	sequence_setup.erase("whiffer_turns")
	checks+=1
	if sequence_setup.pp_control!=5 or sequence_partner.pp_primary!=10 or not sequencing.enemy_actions.is_empty():failures.append("sequence scoring purity")
	checks+=1
	print("KINDRIA_ATTACK_SEQUENCING checks=8")
	# Bounded search follows actual witnessed headings and explores alternatives.
	var hunter_search=Rules.new()
	for y in range(1,10):
		for x in range(1,20):hunter_search.cells[Vector2i(x,y)]=true
	hunter_search.player=Vector2i(19,9);hunter_search.stairs=Vector2i(18,9);hunter_search.relic=Vector2i(18,8);hunter_search.turns=20
	var search_origin:=Vector2i(4,4)
	var hunter_actor:Dictionary={"uid":0,"pos":search_origin,"hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"last_seen_player":search_origin,"last_seen_until":22,"search_heading":Vector2i.RIGHT,"search_heading_turn":19,"search_heading_anchor":search_origin}
	hunter_search.enemies.append(hunter_actor)
	if hunter_search.enemy_pursuit_target(hunter_actor,hunter_search.player)!=Vector2i(5,4) or int(hunter_actor.search_until)!=22:failures.append("hunter witnessed direction and bounded budget")
	checks+=1
	hunter_search.traps[Vector2i(5,4)]="snare"
	if hunter_search.enemy_search_target(hunter_actor)==Vector2i(5,4):failures.append("hunter avoids trap")
	hunter_search.traps.clear()
	checks+=1
	var peer_search:Dictionary={"uid":1,"pos":Vector2i(4,3),"hp":30,"kind":0,"species":"leafwisp","ecology_search_enabled":true,"search_anchor":search_origin,"search_until":22,"search_claim":Vector2i(5,4),"search_claim_turn":20}
	hunter_search.enemies.append(peer_search)
	if not hunter_search.enemy_hunter_search_claims(hunter_actor,search_origin).has(Vector2i(5,4)) or hunter_search.enemy_search_target(hunter_actor)==Vector2i(5,4):failures.append("hunter respects local shared claim")
	checks+=1
	peer_search["sleep_turns"]=2
	if not hunter_search.enemy_hunter_search_claims(hunter_actor,search_origin).is_empty():failures.append("hunter sleeping peer ignored")
	peer_search.erase("sleep_turns")
	checks+=1
	hunter_search.turns=22
	if not hunter_search.enemy_hunter_search_claims(hunter_actor,search_origin).is_empty():failures.append("hunter expired claim ignored")
	checks+=1
	hunter_search.turns=20
	hunter_search.enemies.pop_back()
	hunter_actor.search_visited={search_origin:true,Vector2i(5,4):true,Vector2i(4,3):true,Vector2i(4,5):true,Vector2i(3,4):true}
	if hunter_search.enemy_search_target(hunter_actor)==search_origin:failures.append("hunter backtracks to unvisited branch")
	checks+=1
	hunter_search.turns=23
	if hunter_search.enemy_search_target(hunter_actor)!=search_origin or hunter_actor.has("search_claim"):failures.append("hunter search expires")
	checks+=1
	hunter_search.player=Vector2i(6,4)
	if hunter_search.enemy_pursuit_target(hunter_actor,hunter_search.player)!=hunter_search.player or hunter_actor.has("search_anchor"):failures.append("hunter direct reacquisition clears search")
	checks+=1
	print("KINDRIA_DUNGEON_HUNTERS checks=8")

	# Firsthand contact cannot be refreshed by repetition or relayed by listeners.
	var comm_v2691=Rules.new()
	for y in range(1,9):
		for x in range(1,20):comm_v2691.cells[Vector2i(x,y)]=true
	comm_v2691.turns=40
	comm_v2691.player=Vector2i(19,8)
	var contact_tile:=Vector2i(6,4)
	var comm_witness:Dictionary={"uid":101,"pos":Vector2i(4,4),"hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"contact_tile":contact_tile,"contact_turn":39}
	var comm_listener:Dictionary={"uid":102,"pos":Vector2i(5,4),"hp":30,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true}
	var comm_remote:Dictionary={"uid":103,"pos":Vector2i(5,5),"hp":30,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true}
	comm_v2691.enemies.append(comm_witness);comm_v2691.enemies.append(comm_listener)
	comm_v2691.enemy_share_remembered_contact(comm_listener)
	if comm_listener.get("alert_tile")!=contact_tile or int(comm_listener.get("alert_until",-1))!=41 or int(comm_listener.get("alert_source",-1))!=101:failures.append("communication firsthand report")
	checks+=1
	comm_v2691.turns=41
	comm_v2691.enemy_share_remembered_contact(comm_listener)
	if int(comm_listener.get("alert_turn",-1))!=39 or int(comm_listener.get("alert_until",-1))!=41:failures.append("communication cannot refresh timestamp")
	checks+=1
	comm_v2691.enemies.erase(comm_witness);comm_v2691.enemies.append(comm_remote)
	comm_v2691.enemy_share_remembered_contact(comm_remote)
	if comm_remote.has("alert_tile") or comm_listener.has("contact_tile"):failures.append("communication no secondhand relay")
	checks+=1
	comm_v2691.enemies.append(comm_witness)
	comm_v2691.turns=42
	comm_v2691.enemy_share_remembered_contact(comm_remote)
	if comm_remote.has("alert_tile"):failures.append("communication expired contact")
	checks+=1
	comm_v2691.turns=40
	comm_witness["sleep_turns"]=2
	comm_v2691.enemy_share_remembered_contact(comm_remote)
	if comm_remote.has("alert_tile"):failures.append("communication sleeping witness")
	checks+=1
	comm_witness.erase("sleep_turns")
	comm_remote["last_seen_turn"]=40
	comm_v2691.enemy_share_remembered_contact(comm_remote)
	if comm_remote.has("alert_tile"):failures.append("communication newer firsthand observation")
	checks+=1
	comm_remote.erase("last_seen_turn")
	comm_v2691.cells.erase(Vector2i(4,5))
	comm_v2691.enemy_share_remembered_contact(comm_remote)
	if comm_remote.has("alert_tile"):failures.append("communication blocked witness")
	comm_v2691.cells[Vector2i(4,5)]=true
	checks+=1
	comm_remote.pos=Vector2i(18,7)
	comm_v2691.enemy_record_witnessed_loss(comm_witness)
	if not comm_v2691.enemy_recent_squad_loss(comm_listener) or comm_v2691.enemy_recent_squad_loss(comm_remote):failures.append("communication visible loss only")
	checks+=1
	comm_v2691.turns=44
	if comm_v2691.enemy_recent_squad_loss(comm_listener):failures.append("communication loss expires")
	checks+=1
	print("KINDRIA_ENEMY_COMMUNICATION checks=9")

	# Dynamic reserve election must use actual routes and preserve immediate fire.
	var reserve_fixture=Rules.new()
	for y in range(1,10):
		for x in range(1,10):reserve_fixture.cells[Vector2i(x,y)]=true
	reserve_fixture.player=Vector2i(4,4);reserve_fixture.stairs=Vector2i(9,9);reserve_fixture.relic=Vector2i(9,8);reserve_fixture.turns=30
	var reserve_actor:Dictionary={"uid":20,"pos":Vector2i(4,6),"hp":30,"max_hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0,"squad_loss_turn":29}
	var reserve_peer:Dictionary={"uid":10,"pos":Vector2i(6,4),"hp":30,"max_hp":30,"kind":0,"species":"shellguard","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0,"squad_loss_turn":29}
	reserve_fixture.enemies.append(reserve_actor);reserve_fixture.enemies.append(reserve_peer)
	if not reserve_fixture.enemy_dynamic_reserve_plan(reserve_actor,reserve_fixture.player).is_empty() or reserve_fixture.enemy_dynamic_reserve_plan(reserve_peer,reserve_fixture.player).get("step")!=Vector2i(5,4):failures.append("reserve deterministic election")
	checks+=1
	for q in [Vector2i(5,4),Vector2i(6,3),Vector2i(6,5),Vector2i(7,4)]:reserve_fixture.traps[q]="snare"
	var reserve_plan:Dictionary=reserve_fixture.enemy_dynamic_reserve_plan(reserve_actor,reserve_fixture.player)
	if reserve_plan.get("step")!=Vector2i(4,5) or reserve_plan.get("post")!=Vector2i(4,5):failures.append("reserve blocked peer cannot veto")
	checks+=1
	if reserve_actor.pos!=Vector2i(4,6) or reserve_actor.pp_primary!=0 or not reserve_fixture.enemy_actions.is_empty():failures.append("reserve plan purity")
	checks+=1
	reserve_fixture.traps[Vector2i(4,5)]="snare"
	var reserve_detour:Dictionary=reserve_fixture.enemy_dynamic_reserve_plan(reserve_actor,reserve_fixture.player)
	if not reserve_detour.is_empty() and (reserve_detour.get("step")==Vector2i(4,5) or int(reserve_detour.cost)>3):failures.append("reserve bounded safe detour")
	checks+=1
	reserve_fixture.traps.clear()
	reserve_fixture.enemies.erase(reserve_peer)
	var reserve_front:Dictionary={"uid":30,"pos":Vector2i(3,4),"hp":30,"max_hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true}
	reserve_fixture.enemies.append(reserve_front)
	if not reserve_fixture.enemy_dynamic_reserve_plan(reserve_actor,reserve_fixture.player).is_empty():failures.append("reserve healthy front line retained")
	checks+=1
	reserve_fixture.enemies.erase(reserve_front)
	reserve_actor["sleep_turns"]=2
	if not reserve_fixture.enemy_dynamic_reserve_plan(reserve_actor,reserve_fixture.player).is_empty():failures.append("reserve incapacitated actor")
	reserve_actor.erase("sleep_turns")
	checks+=1
	reserve_fixture.turns=34
	if not reserve_fixture.enemy_dynamic_reserve_plan(reserve_actor,reserve_fixture.player).is_empty():failures.append("reserve expired loss without backup")
	checks+=1
	reserve_fixture.turns=30
	reserve_fixture.cells.erase(Vector2i(4,5))
	if not reserve_fixture.enemy_dynamic_reserve_plan(reserve_actor,reserve_fixture.player).is_empty():failures.append("reserve no target sight through wall")
	checks+=1
	print("KINDRIA_DYNAMIC_SQUAD_ROLES checks=8")
	# Forecast only witnessed retreats, and commit only a safe ordinary step.
	var forecast=Rules.new()
	for y in range(1,9):
		for x in range(1,9):forecast.cells[Vector2i(x,y)]=true
	forecast.player=Vector2i(3,4);forecast.stairs=Vector2i(8,8);forecast.relic=Vector2i(8,7)
	forecast.cells.erase(Vector2i(5,3));forecast.cells.erase(Vector2i(5,5))
	var forecaster:Dictionary={"uid":0,"pos":Vector2i(7,4),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"adaptive_seen":Vector2i(3,4),"adaptive_seen_turn":30,"adaptive_heading":Vector2i.RIGHT,"adaptive_streak":2,"pp_primary":0,"pp_secondary":0}
	forecast.enemies.append(forecaster);forecast.turns=30
	if forecast.enemy_predictive_cutoff_step(forecaster,forecast.player)!=Vector2i(6,4):failures.append("forecast two-step corridor intercept")
	checks+=1
	if forecaster.pos!=Vector2i(7,4) or forecaster.has("prediction_turn") or not forecast.enemy_actions.is_empty():failures.append("forecast evaluation purity")
	checks+=1
	forecast.cells[Vector2i(5,3)]=true
	if forecast.enemy_predictive_cutoff_step(forecaster,forecast.player)!=forecaster.pos:failures.append("forecast no open room detour")
	forecast.cells.erase(Vector2i(5,3))
	checks+=1
	forecast.traps[Vector2i(5,4)]="snare"
	if forecast.enemy_predictive_cutoff_step(forecaster,forecast.player)!=forecaster.pos:failures.append("forecast hazardous post")
	forecast.traps.clear()
	checks+=1
	forecast.player_traps[Vector2i(6,4)]="snare"
	if forecast.enemy_predictive_cutoff_step(forecaster,forecast.player)!=forecaster.pos:failures.append("forecast hazardous first step")
	forecast.player_traps.clear()
	checks+=1
	forecaster["windup"]=true
	if forecast.enemy_predictive_cutoff_step(forecaster,forecast.player)!=forecaster.pos:failures.append("forecast preserves windup")
	forecaster.erase("windup")
	checks+=1
	forecast.charge_phase="airborne"
	if forecast.enemy_predictive_cutoff_step(forecaster,forecast.player)!=forecaster.pos:failures.append("forecast hidden player")
	forecast.charge_phase=""
	checks+=1
	forecast.enemy_record_prediction(forecaster,forecast.player)
	forecast.cells[Vector2i(5,3)]=true
	forecast.turns=31;forecast.player=Vector2i(3,3);forecast.adaptive_walk_from=Vector2i(3,4);forecast.adaptive_walk_to=forecast.player;forecast.adaptive_walk_turn=30
	forecast.enemy_review_prediction(forecaster,forecast.player)
	if int(forecaster.get("prediction_retry",0))!=33 or forecaster.has("prediction_turn"):failures.append("forecast witnessed deviation recovery")
	checks+=1
	forecaster["adaptive_seen"]=forecast.player;forecaster["adaptive_seen_turn"]=31;forecaster["adaptive_heading"]=Vector2i.UP;forecaster["adaptive_streak"]=2
	if forecast.enemy_retreat_prediction(forecaster,forecast.player)!=forecast.player:failures.append("forecast retry gate")
	checks+=1
	forecaster.erase("prediction_retry")
	forecast.enemy_record_prediction(forecaster,forecast.player)
	forecast.turns=32;forecast.player=Vector2i(3,2);forecast.adaptive_walk_turn=29
	forecast.enemy_review_prediction(forecaster,forecast.player)
	if forecaster.has("prediction_retry") or forecaster.has("prediction_turn"):failures.append("forecast forced displacement is not failed prediction")
	checks+=1
	forecast.cells.erase(Vector2i(5,3))
	forecast.player=Vector2i(3,4);forecast.turns=40
	# Seed a current witnessed forecast to exercise the actual movement dispatcher.
	forecaster.pos=Vector2i(7,4);forecaster["adaptive_seen"]=forecast.player;forecaster["adaptive_seen_turn"]=41;forecaster["adaptive_heading"]=Vector2i.RIGHT;forecaster["adaptive_streak"]=2
	forecast.enemy_turn_actions()
	var forecast_moves:int=0
	for action in forecast.enemy_actions:
		if int(action.get("uid",-1))==0 and str(action.phase)=="move":forecast_moves+=1
	if forecast_moves!=1 or forecaster.pos!=Vector2i(6,4) or int(forecaster.get("prediction_turn",-1))!=41:failures.append("forecast actual single movement")
	checks+=1
	print("KINDRIA_PREDICTIVE_COMBAT checks=11")
	# Manipulation rewards improved real attack coverage, not arbitrary distance.
	var battlefield=Rules.new()
	for y in range(1,7):
		for x in range(1,8):battlefield.cells[Vector2i(x,y)]=true
	battlefield.cells.erase(Vector2i(6,3))
	battlefield.player=Vector2i(3,3);battlefield.stairs=Vector2i(7,6);battlefield.relic=Vector2i(7,5)
	var manipulator:Dictionary={"uid":0,"pos":Vector2i(2,3),"hp":30,"max_hp":30,"kind":1,"species":"sylphowl","ecology_role":"scout","ecology_search_enabled":true,"control_move":"eos_268","pp_control":5,"pp_primary":0,"pp_secondary":0,"stages":{"accuracy":10}}
	var followup:Dictionary={"uid":1,"pos":Vector2i(5,4),"hp":30,"max_hp":30,"kind":1,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":0,"stages":{"accuracy":10}}
	battlefield.enemies.append(manipulator);battlefield.enemies.append(followup)
	var landing:Dictionary=battlefield.enemy_push_plan(manipulator,battlefield.player)
	if landing.destination!=Vector2i(5,3) or int(landing.position_bonus)!=4 or int(landing.score)<5:failures.append("battlefield opens learned firing lane")
	checks+=1
	if manipulator.pp_control!=5 or followup.pp_primary!=12 or battlefield.player!=Vector2i(3,3) or not battlefield.enemy_actions.is_empty():failures.append("battlefield evaluation purity")
	checks+=1
	followup.pp_primary=0
	if battlefield.enemy_push_attack_coverage(followup,Vector2i(5,3))!=1:failures.append("battlefield exhausted learned move only basic coverage")
	checks+=1
	followup.pp_primary=12;followup["sleep_turns"]=2
	if int(battlefield.enemy_push_plan(manipulator,battlefield.player).score)>=5:failures.append("battlefield sleeping followup excluded")
	checks+=1
	followup.sleep_turns=0
	battlefield.enemies.reverse()
	if int(battlefield.enemy_push_plan(manipulator,battlefield.player).position_bonus)!=0:failures.append("battlefield already acted partner excluded")
	battlefield.enemies.reverse()
	checks+=1
	followup.pos=Vector2i(5,3)
	if int(battlefield.enemy_push_plan(manipulator,battlefield.player).score)>=5:failures.append("battlefield avoids friendly impact")
	checks+=1
	followup.pos=Vector2i(5,4)
	battlefield.stairs=Vector2i(5,3)
	if int(battlefield.enemy_push_plan(manipulator,battlefield.player).score)>=5:failures.append("battlefield avoids granting exit")
	battlefield.stairs=Vector2i(7,6)
	checks+=1
	battlefield.allies.append({"pos":Vector2i(2,4),"hp":20})
	if battlefield.enemy_push_position_bonus(manipulator,battlefield.player,Vector2i(5,3))!=6:failures.append("battlefield visible party separation")
	battlefield.allies.clear()
	checks+=1
	followup.sleep_turns=2; battlefield.traps[Vector2i(5,3)]="snare"
	battlefield.shield_kind="safeguard";battlefield.shield_turns=2
	if int(battlefield.enemy_push_plan(manipulator,battlefield.player).score)>=5:failures.append("battlefield protected trap discounted")
	battlefield.shield_kind="";battlefield.shield_turns=0;battlefield.traps.clear()
	checks+=1
	followup.sleep_turns=0
	battlefield.enemy_turn_actions()
	var push_count:int=0
	var follow_count:int=0
	for action in battlefield.enemy_actions:
		if int(action.get("uid",-1))==0 and str(action.get("effect",""))=="push":push_count+=1
		if int(action.get("uid",-1))==1 and str(action.get("phase",""))=="attack":follow_count+=1
	if push_count!=1 or follow_count!=1 or manipulator.pp_control!=4 or followup.pp_primary!=11 or battlefield.player!=Vector2i(5,3):failures.append("battlefield actual ordered knockback and followup")
	checks+=1
	print("KINDRIA_BATTLEFIELD_MANIPULATION checks=10")
	# Counterplay derives from personally observed hits on distinct turns.
	var counterplay=Rules.new()
	for y in range(1,9):
		for x in range(1,9):counterplay.cells[Vector2i(x,y)]=true
	counterplay.stairs=Vector2i(8,8);counterplay.relic=Vector2i(8,7)
	counterplay.player=Vector2i(5,4);counterplay.turns=20
	var counter_actor:Dictionary={"uid":0,"pos":Vector2i(2,2),"hp":40,"max_hp":40,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0}
	counterplay.enemies.append(counter_actor)
	counterplay.enemy_remember_incoming(counter_actor,4,"normal")
	counterplay.enemy_remember_incoming(counter_actor,4,"normal")
	if counterplay.enemy_counter_pattern(counter_actor,"ranged") or int(counter_actor.counter_hit_streak)!=1:failures.append("counterplay no multihit overcount")
	checks+=1
	counterplay.turns=21;counterplay.enemy_remember_incoming(counter_actor,4,"normal")
	if not counterplay.enemy_counter_pattern(counter_actor,"ranged") or counterplay.enemy_counter_pattern(counter_actor,"close"):failures.append("counterplay distinct ranged hits")
	checks+=1
	counterplay.cells.erase(Vector2i(3,4))
	if counterplay.enemy_counter_cover_step(counter_actor,counterplay.player)!=Vector2i(2,3):failures.append("counterplay cover approach")
	checks+=1
	counterplay.traps[Vector2i(2,3)]="snare"
	if counterplay.enemy_counter_cover_step(counter_actor,counterplay.player)!=counter_actor.pos:failures.append("counterplay unsafe cover excluded")
	counterplay.traps.clear()
	checks+=1
	counter_actor["windup"]=true
	if counterplay.enemy_counter_cover_step(counter_actor,counterplay.player)!=counter_actor.pos:failures.append("counterplay windup preserved")
	counter_actor.erase("windup")
	checks+=1
	counterplay.enemy_turn_actions()
	if counter_actor.pos!=Vector2i(2,3) or counterplay.enemy_actions.size()!=1 or int(counter_actor.get("counter_cover_turn",-1))!=22:failures.append("counterplay real cover movement")
	checks+=1
	counterplay.turns=25
	if counterplay.enemy_counter_pattern(counter_actor,"ranged"):failures.append("counterplay pattern expiry")
	checks+=1
	counter_actor.pos=Vector2i(2,2);counterplay.player=Vector2i(3,2)
	counterplay.turns=30;counterplay.enemy_remember_incoming(counter_actor,3,"normal")
	counterplay.turns=31;counterplay.enemy_remember_incoming(counter_actor,3,"normal")
	if not counterplay.enemy_counter_pattern(counter_actor,"close") or counterplay.enemy_counter_pattern(counter_actor,"ranged"):failures.append("counterplay pattern switches")
	checks+=1
	counter_actor.pp_primary=12
	counterplay.shield_kind="protect";counterplay.shield_turns=2
	counterplay.enemy_turn_actions()
	if counter_actor.pp_primary!=12 or not counterplay.enemy_actions.is_empty():failures.append("counterplay protected hold no PP")
	checks+=1
	counterplay.shield_kind="";counterplay.shield_turns=0;counter_actor["stages"]={"accuracy":10}
	counterplay.enemy_turn_actions()
	if counter_actor.pp_primary!=11 or counterplay.enemy_actions.size()!=1 or str(counterplay.enemy_actions[0].phase)!="attack":failures.append("counterplay resumes after protection")
	checks+=1
	print("KINDRIA_INTELLIGENT_COUNTERPLAY checks=10")
	# Pack intentions are local, advisory and bounded to real movement.
	var pack_fixture_hunt=Rules.new()
	for y in range(1,9):
		for x in range(1,9):pack_fixture_hunt.cells[Vector2i(x,y)]=true
	pack_fixture_hunt.player=Vector2i(4,4);pack_fixture_hunt.stairs=Vector2i(8,8);pack_fixture_hunt.relic=Vector2i(8,7);pack_fixture_hunt.turns=20
	var pack_actor_hunt:Dictionary={"uid":0,"pos":Vector2i(5,6),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	var pack_anchor:Dictionary={"uid":1,"pos":Vector2i(3,4),"hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	var pack_peer:Dictionary={"uid":2,"pos":Vector2i(6,5),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	pack_fixture_hunt.enemies.append(pack_actor_hunt);pack_fixture_hunt.enemies.append(pack_anchor);pack_fixture_hunt.enemies.append(pack_peer)
	var pack_first:Dictionary=pack_fixture_hunt.enemy_pack_intercept_plan(pack_actor_hunt,pack_fixture_hunt.player)
	var pack_post:Vector2i=pack_first.get("post",Vector2i.ZERO)
	if pack_first.is_empty() or pack_fixture_hunt.distance(pack_post,pack_fixture_hunt.player)!=1 or pack_fixture_hunt.distance(pack_actor_hunt.pos,pack_first.get("step",pack_actor_hunt.pos))!=1:failures.append("pack valid interception post")
	checks+=1
	if pack_actor_hunt.has("pack_post") or pack_actor_hunt.pos!=Vector2i(5,6) or not pack_fixture_hunt.enemy_actions.is_empty():failures.append("pack plan purity")
	checks+=1
	pack_fixture_hunt.enemy_pack_commit(pack_peer,pack_fixture_hunt.player,pack_post)
	if not pack_fixture_hunt.enemy_pack_reserved_posts(pack_actor_hunt,pack_fixture_hunt.player).has(pack_post):failures.append("pack visible peer intention")
	checks+=1
	var pack_alternative:Dictionary=pack_fixture_hunt.enemy_pack_intercept_plan(pack_actor_hunt,pack_fixture_hunt.player)
	if pack_alternative.is_empty() or pack_alternative.get("post",Vector2i.ZERO)==pack_post or pack_alternative.get("step",Vector2i.ZERO)==pack_post:failures.append("pack distinct flank allocation")
	checks+=1
	pack_peer["sleep_turns"]=2
	if pack_fixture_hunt.enemy_pack_reserved_posts(pack_actor_hunt,pack_fixture_hunt.player).has(pack_post):failures.append("pack incapacitated claim ignored")
	pack_peer.erase("sleep_turns")
	checks+=1
	pack_fixture_hunt.turns=22
	if not pack_fixture_hunt.enemy_pack_reserved_posts(pack_actor_hunt,pack_fixture_hunt.player).is_empty():failures.append("pack stale claim expires")
	checks+=1
	pack_fixture_hunt.enemy_pack_commit(pack_peer,pack_fixture_hunt.player,pack_post)
	pack_fixture_hunt.traps[pack_post]="snare"
	if pack_fixture_hunt.enemy_pack_reserved_posts(pack_actor_hunt,pack_fixture_hunt.player).has(pack_post):failures.append("pack hazard invalidates claim")
	pack_fixture_hunt.traps.clear()
	checks+=1
	if not pack_fixture_hunt.enemy_pack_reserved_posts(pack_actor_hunt,Vector2i(4,5)).is_empty():failures.append("pack target change invalidates claim")
	checks+=1
	pack_fixture_hunt.charge_phase="airborne"
	if not pack_fixture_hunt.enemy_pack_intercept_plan(pack_actor_hunt,pack_fixture_hunt.player).is_empty():failures.append("pack hidden player gate")
	pack_fixture_hunt.charge_phase=""
	checks+=1
	pack_peer.erase("pack_post")
	pack_fixture_hunt.enemy_turn_actions()
	var pack_moves_hunt:int=0
	for action in pack_fixture_hunt.enemy_actions:
		if int(action.get("uid",-1))==0 and str(action.phase)=="move":pack_moves_hunt+=1
	if pack_moves_hunt!=1 or int(pack_actor_hunt.get("pack_turn",-1))!=23 or pack_actor_hunt.pp_primary!=0:failures.append("pack real dispatcher commits once")
	checks+=1
	print("KINDRIA_ENEMY_PACK_HUNTING checks=10")
	# Dynamic relief is selected from visible healthy teammates, never new abilities.
	var relief_fixture=Rules.new()
	for y in range(1,9):
		for x in range(1,9):relief_fixture.cells[Vector2i(x,y)]=true
	relief_fixture.player=Vector2i(4,4);relief_fixture.stairs=Vector2i(8,8);relief_fixture.relic=Vector2i(8,7)
	var relief_guard:Dictionary={"uid":0,"pos":Vector2i(4,6),"hp":30,"max_hp":30,"kind":0,"species":"shellguard","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0}
	var relief_wounded:Dictionary={"uid":1,"pos":Vector2i(3,4),"hp":5,"max_hp":30,"kind":0,"species":"bramble_pup","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	var relief_ranged:Dictionary={"uid":2,"pos":Vector2i(6,4),"hp":30,"max_hp":30,"kind":1,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":0}
	relief_fixture.enemies.append(relief_guard);relief_fixture.enemies.append(relief_wounded);relief_fixture.enemies.append(relief_ranged)
	if relief_fixture.enemy_relief_step(relief_guard,relief_fixture.player)!=Vector2i(4,5):failures.append("relief wounded frontline replacement")
	checks+=1
	if relief_guard.pos!=Vector2i(4,6) or relief_guard.pp_primary!=0 or not relief_fixture.enemy_actions.is_empty():failures.append("relief plan purity")
	checks+=1
	relief_wounded.hp=30
	if relief_fixture.enemy_relief_step(relief_guard,relief_fixture.player)!=relief_guard.pos:failures.append("relief healthy frontline retained")
	checks+=1
	relief_wounded.hp=0
	if relief_fixture.enemy_relief_step(relief_guard,relief_fixture.player)!=Vector2i(4,5):failures.append("relief fallen frontline with ranged backup")
	checks+=1
	relief_ranged.pp_primary=0
	if relief_fixture.enemy_relief_step(relief_guard,relief_fixture.player)!=relief_guard.pos:failures.append("relief exhausted backup")
	checks+=1
	relief_ranged.pp_primary=12;relief_ranged["sleep_turns"]=2
	if relief_fixture.enemy_relief_step(relief_guard,relief_fixture.player)!=relief_guard.pos:failures.append("relief incapacitated backup")
	relief_ranged.erase("sleep_turns")
	checks+=1
	relief_guard.hp=12
	if relief_fixture.enemy_relief_step(relief_guard,relief_fixture.player)!=relief_guard.pos:failures.append("relief wounded candidate excluded")
	relief_guard.hp=30
	checks+=1
	relief_fixture.traps[Vector2i(4,5)]="snare"
	if relief_fixture.enemy_relief_step(relief_guard,relief_fixture.player)!=relief_guard.pos:failures.append("relief unsafe approach excluded")
	relief_fixture.traps.clear()
	checks+=1
	relief_guard.pos=Vector2i(5,5);relief_ranged.pos=Vector2i(6,4)
	if not relief_fixture.enemy_relief_blocks_lane(relief_ranged,Vector2i(5,4),relief_fixture.player) or relief_fixture.enemy_relief_step(relief_guard,relief_fixture.player)!=Vector2i(4,5):failures.append("relief avoids blocking ranged ray")
	checks+=1
	relief_guard.pos=Vector2i(4,6)
	# Isolate relief dispatch from the guard’s legal support move.
	relief_guard["pp_support"]=0
	relief_fixture.enemies.remove_at(1)
	relief_fixture.enemy_turn_actions()
	var relief_moves:int=0
	for action in relief_fixture.enemy_actions:
		if int(action.get("uid",-1))==0 and str(action.phase)=="move":relief_moves+=1
	if relief_moves!=1 or relief_guard.pos!=Vector2i(4,5) or relief_guard.pp_primary!=0:failures.append("relief real turn dispatch")
	checks+=1
	print("KINDRIA_DYNAMIC_COMBAT_ROLES checks=10")
	# Finishers use real non-critical HP estimates, not tactical utility scores.
	var opportunity=Rules.new()
	for y in range(1,7):
		for x in range(1,7):opportunity.cells[Vector2i(x,y)]=true
	opportunity.player=Vector2i(3,3);opportunity.stairs=Vector2i(6,6);opportunity.relic=Vector2i(6,5)
	opportunity.hp=1;opportunity.max_hp=30
	var finisher:Dictionary={"uid":0,"pos":Vector2i(2,3),"hp":30,"max_hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":10,"stages":{"accuracy":10}}
	opportunity.enemies.append(finisher)
	var finish_skill:Array=opportunity.signature_skill(finisher)
	var finish_damage:int=opportunity.enemy_opportunity_damage(finisher,[],false,true)
	if finish_damage<1 or not opportunity.enemy_basic_finish(finisher):failures.append("opportunity basic finisher")
	checks+=1
	var prior_multiplier:float=opportunity.last_type_multiplier
	opportunity.enemy_opportunity_damage(finisher,finish_skill,false)
	if opportunity.hp!=1 or opportunity.last_type_multiplier!=prior_multiplier or finisher.pp_primary!=12 or not opportunity.enemy_actions.is_empty():failures.append("opportunity estimate purity")
	checks+=1
	opportunity.hp=finish_damage+1
	if opportunity.enemy_basic_finish(finisher):failures.append("opportunity no premature basic")
	checks+=1
	opportunity.hp=1;opportunity.shield_kind="protect";opportunity.shield_turns=2
	if opportunity.enemy_basic_finish(finisher) or opportunity.enemy_opportunity_bonus(finisher,finish_skill,false)>0.0:failures.append("opportunity protect gate")
	checks+=1
	opportunity.shield_kind="endure"
	if opportunity.enemy_opportunity_damage(finisher,[],false,true)!=0:failures.append("opportunity endure gate")
	checks+=1
	opportunity.shield_kind="";opportunity.shield_turns=0
	opportunity.charge_phase="airborne"
	if opportunity.enemy_basic_finish(finisher):failures.append("opportunity hidden charge gate")
	opportunity.charge_phase=""
	checks+=1
	finisher["whiffer_turns"]=2
	if opportunity.enemy_basic_finish(finisher):failures.append("opportunity inaccurate basic gate")
	finisher.erase("whiffer_turns")
	checks+=1
	finisher["windup"]=true
	if opportunity.enemy_basic_finish(finisher):failures.append("opportunity existing windup preserved")
	finisher.erase("windup")
	checks+=1
	if opportunity.enemy_opportunity_bonus(finisher,finish_skill,false)<=0.0:failures.append("opportunity immediate lethal bonus")
	var delayed:Array=finish_skill.duplicate();delayed[1]=true
	if opportunity.enemy_opportunity_bonus(finisher,delayed,false)!=0.0:failures.append("opportunity delayed attack not immediate KO")
	checks+=1
	opportunity.enemy_turn_actions()
	if opportunity.hp!=0 or finisher.pp_primary!=12 or finisher.pp_secondary!=10 or opportunity.enemy_actions.size()!=1 or str(opportunity.enemy_actions[0].move)!="Quick strike":failures.append("opportunity real basic finisher no PP")
	checks+=1
	print("KINDRIA_OPPORTUNITY_EXPLOITATION checks=10")
	# A cautious wounded enemy must not retreat from an available basic KO.
	var finish_conflict=Rules.new()
	for y in range(1,7):
		for x in range(1,7):finish_conflict.cells[Vector2i(x,y)]=true
	finish_conflict.player=Vector2i(3,3);finish_conflict.stairs=Vector2i(6,6);finish_conflict.relic=Vector2i(6,5)
	finish_conflict.hp=1;finish_conflict.max_hp=30;finish_conflict.turns=20
	var finish_cautious:Dictionary={"uid":0,"pos":Vector2i(2,3),"hp":3,"max_hp":30,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":10,"stages":{"accuracy":10},"incoming_turn":20,"incoming_damage":10}
	finish_conflict.enemies.append(finish_cautious)
	if not finish_conflict.enemy_basic_finish(finish_cautious) or not finish_conflict.enemy_risk_has_finisher(finish_cautious):failures.append("tactical polish credible finisher")
	checks+=1
	finish_conflict.enemy_turn_actions()
	if finish_conflict.hp!=0 or finish_cautious.pos!=Vector2i(2,3) or finish_cautious.pp_primary!=12 or finish_cautious.pp_secondary!=10 or finish_conflict.enemy_actions.size()!=1 or str(finish_conflict.enemy_actions[0].get("move",""))!="Quick strike":failures.append("tactical polish finisher overrides retreat")
	checks+=1
	print("KINDRIA_TACTICAL_POLISH checks=2")
	# Visible player charge responses must use real catalog geometry and legal actions.
	var charge_counter_fixture=Rules.new()
	for y in range(1,7):
		for x in range(1,7):charge_counter_fixture.cells[Vector2i(x,y)]=true
	charge_counter_fixture.player=Vector2i(3,3);charge_counter_fixture.stairs=Vector2i(6,6);charge_counter_fixture.relic=Vector2i(6,5)
	charge_counter_fixture.hp=100;charge_counter_fixture.max_hp=100;charge_counter_fixture.turns=20
	var charge_counter_actor:Dictionary={"uid":0,"pos":Vector2i(2,3),"hp":30,"max_hp":30,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":0,"pp_control":0}
	charge_counter_fixture.enemies.append(charge_counter_actor)
	charge_counter_fixture.charged_move_id="eos_075";charge_counter_fixture.charged_aim=Vector2i.LEFT;charge_counter_fixture.charge_phase="gather"
	var counter_threat:Dictionary=charge_counter_fixture.enemy_visible_charge_threat(charge_counter_actor)
	if not counter_threat.has(charge_counter_actor.pos) or counter_threat.has(Vector2i(2,2)):failures.append("charge counter real focused fist footprint")
	checks+=1
	var counter_evade:Vector2i=charge_counter_fixture.enemy_charge_evasion_step(charge_counter_actor)
	if counter_evade==charge_counter_actor.pos or counter_threat.has(counter_evade) or not charge_counter_fixture.enemy_ambush_safe_tile(counter_evade) or charge_counter_actor.pp_primary!=12:failures.append("charge counter pure safe evasion")
	checks+=1
	charge_counter_fixture.charged_move_id="eos_060"
	if not charge_counter_fixture.enemy_visible_charge_threat(charge_counter_actor).has(Vector2i(2,2)):failures.append("charge counter corner-front footprint")
	checks+=1
	charge_counter_fixture.charged_move_id="eos_075";charge_counter_fixture.charged_aim=Vector2i.RIGHT
	if charge_counter_fixture.enemy_charge_evasion_step(charge_counter_actor)!=charge_counter_actor.pos:failures.append("charge counter no response outside threat")
	charge_counter_fixture.charged_aim=Vector2i.LEFT
	checks+=1
	charge_counter_fixture.charged_move_id="eos_153";charge_counter_fixture.charge_phase="airborne"
	if not charge_counter_fixture.enemy_visible_charge_threat(charge_counter_actor).is_empty():failures.append("charge counter hidden aim excluded")
	charge_counter_fixture.charged_move_id="eos_075";charge_counter_fixture.charge_phase="gather"
	checks+=1
	charge_counter_actor["stuck_turns"]=2
	if charge_counter_fixture.enemy_charge_evasion_step(charge_counter_actor)!=charge_counter_actor.pos:failures.append("charge counter rooted actor")
	charge_counter_actor.erase("stuck_turns")
	checks+=1
	charge_counter_fixture.traps[Vector2i(2,2)]="snare";charge_counter_fixture.traps[Vector2i(2,4)]="snare";charge_counter_fixture.traps[Vector2i(1,3)]="snare"
	if charge_counter_fixture.enemy_charge_evasion_step(charge_counter_actor)!=charge_counter_actor.pos:failures.append("charge counter no unsafe escape")
	charge_counter_fixture.traps.clear()
	checks+=1
	var counter_push:Dictionary=charge_counter_fixture.enemy_push_plan(charge_counter_actor,charge_counter_fixture.player)
	if charge_counter_fixture.enemy_charge_push_bonus(charge_counter_actor,counter_push)!=3 or charge_counter_fixture.player!=Vector2i(3,3):failures.append("charge counter push shifts release origin without mutation")
	checks+=1
	charge_counter_actor["control_move"]="eos_284"
	if charge_counter_fixture.enemy_execute_control(0):failures.append("charge counter no learned PP no control")
	checks+=1
	charge_counter_fixture.enemy_turn_actions()
	if charge_counter_actor.pos==Vector2i(2,3) or counter_threat.has(charge_counter_actor.pos) or charge_counter_fixture.enemy_actions.size()!=1 or str(charge_counter_fixture.enemy_actions[0].phase)!="move" or charge_counter_actor.pp_primary!=12 or charge_counter_fixture.charged_move_id!="eos_075":failures.append("charge counter actual single evasion preserves release")
	checks+=1
	print("KINDRIA_CHARGE_COUNTERPLAY checks=10")
	var formation_fixture=Rules.new()
	for y in range(1,8):
		for x in range(1,8):formation_fixture.cells[Vector2i(x,y)]=true
	formation_fixture.player=Vector2i(4,4)
	var formation_actor:Dictionary={"uid":0,"pos":Vector2i(3,4),"hp":30,"kind":0,"species":"rootgnawer","ecology_search_enabled":true,"personality_enabled":true}
	var formation_peer:Dictionary={"uid":1,"pos":Vector2i(4,3),"hp":30,"kind":0,"species":"leafwisp","ecology_search_enabled":true,"personality_enabled":true}
	formation_fixture.enemies.append(formation_actor);formation_fixture.enemies.append(formation_peer)
	formation_fixture.allies.append({"uid":10,"pos":Vector2i(4,5),"hp":20})
	formation_fixture.allies.append({"uid":11,"pos":Vector2i(3,5),"hp":20})
	if formation_fixture.enemy_formation_support_count(formation_actor,formation_fixture.player)!=2:failures.append("formation visible support")
	checks+=1
	if formation_fixture.enemy_formation_separation_bonus(formation_actor,formation_fixture.player,Vector2i(7,4))!=4:failures.append("formation separating two allies")
	checks+=1
	if formation_fixture.enemy_formation_separation_bonus(formation_actor,Vector2i(7,4),formation_fixture.player)!=-4:failures.append("formation avoid restoring support")
	checks+=1
	if formation_fixture.enemy_formation_separation_bonus(formation_actor,formation_fixture.player,formation_fixture.player)!=0:failures.append("formation no displacement")
	checks+=1
	formation_fixture.allies[0].hp=0
	if formation_fixture.enemy_formation_support_count(formation_actor,formation_fixture.player)!=1:failures.append("formation defeated ally excluded")
	checks+=1
	formation_fixture.allies.clear()
	if formation_fixture.enemy_formation_post_bonus(formation_actor,Vector2i(4,5),formation_fixture.player)<=formation_fixture.enemy_formation_post_bonus(formation_actor,Vector2i(5,4),formation_fixture.player):failures.append("formation opposite flank priority")
	checks+=1
	formation_actor.personality_enabled=false
	if formation_fixture.enemy_formation_post_bonus(formation_actor,Vector2i(4,5),formation_fixture.player)!=0:failures.append("formation personality gate")
	formation_actor.personality_enabled=true
	checks+=1
	formation_fixture.allies.append({"uid":12,"pos":Vector2i(4,5),"hp":20})
	if formation_fixture.enemy_formation_post_bonus(formation_actor,Vector2i(5,4),formation_fixture.player)!=2:failures.append("formation supported target no isolation bonus")
	checks+=1
	print("KINDRIA_FORMATION_BREAKING checks=8")
	# Risk counts visible healthy support and actual recent damage, not hidden actors.
	var risk_fixture=Rules.new()
	for y in range(1,9):
		for x in range(1,9):risk_fixture.cells[Vector2i(x,y)]=true
	risk_fixture.player=Vector2i(4,3);risk_fixture.stairs=Vector2i(8,8);risk_fixture.relic=Vector2i(8,7)
	risk_fixture.hp=30;risk_fixture.max_hp=30;risk_fixture.turns=20
	var risk_actor:Dictionary={"uid":0,"pos":Vector2i(3,3),"hp":12,"max_hp":30,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":12,"pp_secondary":0,"incoming_turn":20,"incoming_damage":14}
	risk_fixture.enemies.append(risk_actor)
	var risk_report:Dictionary=risk_fixture.enemy_risk_snapshot(risk_actor,risk_fixture.player)
	if int(risk_report.get("risk",0))!=5 or int(risk_report.get("friendly",0))!=1 or int(risk_report.get("hostile",0))!=1:failures.append("risk recent lethal threat")
	checks+=1
	risk_fixture.traps[Vector2i(3,2)]="snare";risk_fixture.traps[Vector2i(3,4)]="snare"
	if risk_fixture.enemy_risk_step(risk_actor,risk_fixture.player)!=Vector2i(2,3) or risk_actor.pos!=Vector2i(3,3) or risk_actor.pp_primary!=12:failures.append("risk safe withdrawal and purity")
	checks+=1
	var risk_backup:Dictionary={"uid":1,"pos":Vector2i(4,5),"hp":30,"max_hp":30,"kind":1,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":12,"pp_secondary":0}
	risk_fixture.enemies.append(risk_backup)
	if int(risk_fixture.enemy_risk_snapshot(risk_actor,risk_fixture.player).risk)!=3 or risk_fixture.enemy_risk_step(risk_actor,risk_fixture.player)!=risk_actor.pos:failures.append("risk visible ready reinforcement")
	checks+=1
	risk_backup["sleep_turns"]=2
	if int(risk_fixture.enemy_risk_snapshot(risk_actor,risk_fixture.player).friendly)!=1:failures.append("risk sleeping reinforcement excluded")
	risk_backup.erase("sleep_turns")
	checks+=1
	risk_fixture.allies.append({"uid":1000,"pos":Vector2i(4,2),"hp":20})
	if int(risk_fixture.enemy_risk_snapshot(risk_actor,risk_fixture.player).hostile)!=2 or int(risk_fixture.enemy_risk_snapshot(risk_actor,risk_fixture.player).risk)!=4:failures.append("risk visible hostile numbers")
	risk_fixture.allies.clear()
	checks+=1
	risk_fixture.enemies.pop_back()
	risk_actor["risk_move_turn"]=19
	if risk_fixture.enemy_risk_step(risk_actor,risk_fixture.player)!=risk_actor.pos:failures.append("risk bounded retry")
	risk_actor.erase("risk_move_turn")
	checks+=1
	risk_actor.species="rootgnawer"
	if risk_fixture.enemy_risk_step(risk_actor,risk_fixture.player)!=risk_actor.pos:failures.append("risk aggressive personality")
	risk_actor.species="leafwisp"
	checks+=1
	risk_fixture.hp=1;risk_actor["stages"]={"accuracy":10}
	if not risk_fixture.enemy_risk_has_finisher(risk_actor) or risk_fixture.enemy_risk_step(risk_actor,risk_fixture.player)!=risk_actor.pos:failures.append("risk immediate finisher outweighs retreat")
	risk_fixture.hp=30
	checks+=1
	risk_fixture.turns=24
	if int(risk_fixture.enemy_risk_snapshot(risk_actor,risk_fixture.player).recent)!=0 or risk_fixture.enemy_risk_step(risk_actor,risk_fixture.player)!=risk_actor.pos:failures.append("risk old damage expires")
	checks+=1
	risk_fixture.turns=20
	risk_fixture.enemy_turn_actions()
	if risk_actor.pos!=Vector2i(2,3) or int(risk_actor.get("risk_move_turn",-1))!=21 or risk_actor.pp_primary!=12 or risk_fixture.enemy_actions.size()!=1:failures.append("risk actual single movement")
	checks+=1
	print("KINDRIA_ENEMY_RISK_ASSESSMENT checks=10")
	# Reinforcement holds spend one ordinary turn, with no forced pursuit.
	var reinforcement=Rules.new()
	for y in range(1,9):
		for x in range(1,9):reinforcement.cells[Vector2i(x,y)]=true
	reinforcement.player=Vector2i(5,3);reinforcement.stairs=Vector2i(8,8);reinforcement.relic=Vector2i(8,7);reinforcement.turns=20
	reinforcement.hp=30;reinforcement.max_hp=30
	var waiting_actor:Dictionary={"uid":0,"pos":Vector2i(2,3),"hp":30,"max_hp":30,"kind":0,"species":"leafwisp","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0,"cooldown":2}
	var arriving_actor:Dictionary={"uid":1,"pos":Vector2i(4,4),"hp":30,"max_hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	reinforcement.enemies.append(waiting_actor);reinforcement.enemies.append(arriving_actor)
	if not reinforcement.enemy_reinforcement_wait(waiting_actor,reinforcement.player) or waiting_actor.has("reinforcement_turn"):failures.append("reinforcement eligible pure hold")
	checks+=1
	arriving_actor["sleep_turns"]=2
	if reinforcement.enemy_reinforcement_wait(waiting_actor,reinforcement.player):failures.append("reinforcement incapacitated partner")
	arriving_actor.erase("sleep_turns")
	checks+=1
	reinforcement.enemies.reverse()
	if reinforcement.enemy_reinforcement_wait(waiting_actor,reinforcement.player):failures.append("reinforcement already acted partner")
	reinforcement.enemies.reverse()
	checks+=1
	reinforcement.traps[Vector2i(4,3)]="snare";reinforcement.traps[Vector2i(5,4)]="snare"
	if reinforcement.enemy_reinforcement_wait(waiting_actor,reinforcement.player):failures.append("reinforcement unsafe approach")
	reinforcement.traps.clear()
	checks+=1
	reinforcement.enemy_turn_actions()
	var waiting_actions:int=0
	for action in reinforcement.enemy_actions:
		if int(action.get("uid",-1))==0:waiting_actions+=1
	if waiting_actions!=0 or waiting_actor.pos!=Vector2i(2,3) or int(waiting_actor.get("reinforcement_turn",-1))!=21 or int(waiting_actor.cooldown)!=1:failures.append("reinforcement actual spent hold")
	checks+=1
	arriving_actor.pos=Vector2i(4,4)
	if reinforcement.enemy_reinforcement_wait(waiting_actor,reinforcement.player):failures.append("reinforcement no indefinite holding")
	reinforcement.turns=26
	if not reinforcement.enemy_reinforcement_wait(waiting_actor,reinforcement.player):failures.append("reinforcement retry expires")
	checks+=1
	waiting_actor.pos=Vector2i(3,3);waiting_actor.hp=12;waiting_actor["incoming_turn"]=26;waiting_actor["incoming_damage"]=10
	arriving_actor.pos=Vector2i(4,5);arriving_actor.species="leafwisp";arriving_actor.pp_primary=12
	if reinforcement.enemy_lure_step(waiting_actor,reinforcement.player)!=Vector2i(3,4) or reinforcement.player!=Vector2i(5,3):failures.append("reinforcement lure toward real firing lane")
	checks+=1
	arriving_actor.pp_primary=0
	if reinforcement.enemy_lure_step(waiting_actor,reinforcement.player)!=waiting_actor.pos:failures.append("reinforcement no unlearned followup")
	arriving_actor.pp_primary=12
	checks+=1
	reinforcement.traps[Vector2i(3,4)]="snare"
	if reinforcement.enemy_lure_step(waiting_actor,reinforcement.player)!=waiting_actor.pos:failures.append("reinforcement lure avoids hazard")
	reinforcement.traps.clear()
	checks+=1
	reinforcement.enemy_turn_actions()
	var lure_actions:int=0
	for action in reinforcement.enemy_actions:
		if int(action.get("uid",-1))==0 and str(action.phase)=="move":lure_actions+=1
	if lure_actions!=1 or waiting_actor.pos!=Vector2i(3,4) or int(waiting_actor.get("lure_turn",-1))!=27 or reinforcement.player!=Vector2i(5,3):failures.append("reinforcement actual lure no forced movement")
	checks+=1
	print("KINDRIA_REINFORCEMENT_AMBUSH checks=10")
	# Terrain is classified from real floor geometry, not cosmetic biome.
	var environment_fixture=Rules.new()
	for y in range(2,6):
		for x in range(4,8):environment_fixture.cells[Vector2i(x,y)]=true
	for x in range(1,4):environment_fixture.cells[Vector2i(x,3)]=true
	environment_fixture.cells[Vector2i(1,4)]=true
	environment_fixture.rooms.append(Rect2i(4,2,4,4))
	environment_fixture.player=Vector2i(6,3);environment_fixture.stairs=Vector2i(7,5);environment_fixture.relic=Vector2i(7,4)
	environment_fixture.turns=20;environment_fixture.hp=30;environment_fixture.max_hp=30
	if environment_fixture.enemy_terrain_kind(Vector2i(3,3))!="corridor" or environment_fixture.enemy_terrain_kind(Vector2i(4,3))!="doorway" or environment_fixture.enemy_terrain_kind(Vector2i(1,3))!="corner" or environment_fixture.enemy_terrain_kind(Vector2i(1,4))!="dead_end" or environment_fixture.enemy_terrain_kind(Vector2i(5,3))!="open" or environment_fixture.enemy_terrain_kind(Vector2i(2,2))!="wall":failures.append("environment six terrain classes")
	checks+=1
	var terrain_guard:Dictionary={"uid":0,"pos":Vector2i(3,3),"hp":30,"max_hp":30,"kind":0,"species":"shellguard","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0,"pp_support":0,"pp_control":0}
	var terrain_front:Dictionary={"uid":1,"pos":Vector2i(6,4),"hp":30,"max_hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"pp_primary":0,"pp_secondary":0}
	environment_fixture.enemies.append(terrain_guard);environment_fixture.enemies.append(terrain_front)
	if environment_fixture.enemy_environment_guard_step(terrain_guard,environment_fixture.player)!=Vector2i(4,3) or terrain_guard.pos!=Vector2i(3,3) or terrain_guard.has("environment_guard_turn"):failures.append("environment pure doorway guard")
	checks+=1
	terrain_front.hp=10
	if environment_fixture.enemy_environment_guard_step(terrain_guard,environment_fixture.player)!=terrain_guard.pos:failures.append("environment no unsupported choke")
	terrain_front.hp=30
	checks+=1
	environment_fixture.traps[Vector2i(4,3)]="snare"
	if environment_fixture.enemy_environment_guard_step(terrain_guard,environment_fixture.player)!=terrain_guard.pos:failures.append("environment unsafe gate")
	environment_fixture.traps.clear()
	checks+=1
	terrain_guard["environment_guard_turn"]=19
	if environment_fixture.enemy_environment_guard_step(terrain_guard,environment_fixture.player)!=terrain_guard.pos:failures.append("environment guard retry")
	terrain_guard.erase("environment_guard_turn")
	checks+=1
	terrain_guard["stuck_turns"]=2
	if environment_fixture.enemy_environment_guard_step(terrain_guard,environment_fixture.player)!=terrain_guard.pos:failures.append("environment rooted guard")
	terrain_guard.erase("stuck_turns")
	checks+=1
	if environment_fixture.enemy_terrain_position_bonus(terrain_guard,Vector2i(5,4),environment_fixture.player)<=environment_fixture.enemy_terrain_position_bonus(terrain_guard,Vector2i(2,3),environment_fixture.player):failures.append("environment ranged prefers lateral space")
	checks+=1
	terrain_guard.pos=Vector2i(5,4);terrain_front.pos=Vector2i(4,3);terrain_front.species="leafwisp";terrain_front.pp_primary=12
	var obstructing_score:int=environment_fixture.enemy_terrain_position_bonus(terrain_guard,Vector2i(5,3),environment_fixture.player)
	terrain_front.pp_primary=0
	if environment_fixture.enemy_terrain_position_bonus(terrain_guard,Vector2i(5,3),environment_fixture.player)-obstructing_score!=12:failures.append("environment real friendly ray penalty")
	checks+=1
	terrain_guard.personality_enabled=false
	if environment_fixture.enemy_terrain_position_bonus(terrain_guard,Vector2i(5,3),environment_fixture.player)!=0:failures.append("environment legacy behavior preserved")
	terrain_guard.personality_enabled=true
	checks+=1
	terrain_guard.pos=Vector2i(3,3);terrain_front.pos=Vector2i(6,4);terrain_front.species="rootgnawer"
	environment_fixture.enemy_turn_actions()
	var environmental_moves:int=0
	for action in environment_fixture.enemy_actions:
		if int(action.get("uid",-1))==0 and str(action.phase)=="move":environmental_moves+=1
	if environmental_moves!=1 or terrain_guard.pos!=Vector2i(4,3) or int(terrain_guard.get("environment_guard_turn",-1))!=21 or terrain_guard.pp_primary!=0:failures.append("environment actual doorway movement")
	checks+=1
	print("KINDRIA_ENVIRONMENTAL_INTELLIGENCE checks=10")
	# An alternate route is only chosen for a consecutive witnessed reversal.
	var strategy_fixture=Rules.new()
	for y in range(1,9):
		for x in range(1,9):strategy_fixture.cells[Vector2i(x,y)]=true
	strategy_fixture.player=Vector2i(5,4);strategy_fixture.stairs=Vector2i(8,8);strategy_fixture.relic=Vector2i(8,7);strategy_fixture.turns=20
	var strategy_actor:Dictionary={"uid":0,"pos":Vector2i(2,4),"hp":30,"max_hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true,"pp_primary":0,"pp_secondary":0}
	strategy_fixture.enemies.append(strategy_actor)
	strategy_fixture.enemy_strategy_record_step(strategy_actor,Vector2i(2,4),Vector2i(2,5),strategy_fixture.player)
	strategy_actor.pos=Vector2i(2,5);strategy_fixture.turns=21
	if not strategy_fixture.enemy_strategy_reversal(strategy_actor,Vector2i(2,4),strategy_fixture.player):failures.append("strategy witnessed reversal")
	checks+=1
	if strategy_fixture.enemy_strategy_alternative(strategy_actor,Vector2i(2,4),strategy_fixture.player)!=Vector2i(3,5) or strategy_actor.pos!=Vector2i(2,5) or strategy_actor.pp_primary!=0 or not strategy_fixture.enemy_actions.is_empty():failures.append("strategy safe alternative pure evaluation")
	checks+=1
	strategy_fixture.traps[Vector2i(3,5)]="snare"
	if strategy_fixture.enemy_strategy_alternative(strategy_actor,Vector2i(2,4),strategy_fixture.player)!=Vector2i(2,4):failures.append("strategy no safe alternative allows return")
	strategy_fixture.traps.clear()
	checks+=1
	strategy_fixture.turns=22
	if strategy_fixture.enemy_strategy_reversal(strategy_actor,Vector2i(2,4),strategy_fixture.player):failures.append("strategy stale movement ignored")
	strategy_fixture.turns=21
	checks+=1
	strategy_fixture.player=Vector2i(5,5)
	if strategy_fixture.enemy_strategy_reversal(strategy_actor,Vector2i(2,4),strategy_fixture.player):failures.append("strategy target changes reset")
	strategy_fixture.player=Vector2i(5,4)
	checks+=1
	strategy_fixture.charge_phase="airborne"
	if strategy_fixture.enemy_strategy_reversal(strategy_actor,Vector2i(2,4),strategy_fixture.player):failures.append("strategy hidden player excluded")
	strategy_fixture.charge_phase=""
	checks+=1
	strategy_actor["windup"]=true
	if strategy_fixture.enemy_strategy_reversal(strategy_actor,Vector2i(2,4),strategy_fixture.player):failures.append("strategy charged attack preserved")
	strategy_actor.erase("windup")
	checks+=1
	strategy_actor.species="leafwisp";strategy_actor.pp_primary=12
	if not strategy_fixture.enemy_strategy_attack_tile(strategy_actor,Vector2i(2,4),strategy_fixture.player) or strategy_fixture.enemy_strategy_alternative(strategy_actor,Vector2i(2,4),strategy_fixture.player)!=Vector2i(2,4):failures.append("strategy useful return retained")
	strategy_actor.species="rootgnawer";strategy_actor.pp_primary=0
	checks+=1
	strategy_actor.personality_enabled=false
	if strategy_fixture.enemy_strategy_reversal(strategy_actor,Vector2i(2,4),strategy_fixture.player):failures.append("strategy legacy actor unchanged")
	strategy_actor.personality_enabled=true
	checks+=1
	strategy_fixture.enemy_turn_actions()
	var strategy_moves:int=0
	for action in strategy_fixture.enemy_actions:
		if int(action.get("uid",-1))==0 and str(action.phase)=="move":strategy_moves+=1
	if strategy_moves!=1 or int(strategy_actor.get("strategy_turn",-1))!=22 or strategy_actor.get("strategy_to",Vector2i.ZERO)!=strategy_actor.pos or strategy_actor.pp_primary!=0:failures.append("strategy real movement recorded once")
	checks+=1
	# A projected retreat must vacate only the actor's original tile, never a teammate.
	var projected_fixture=Rules.new()
	for x in range(1,7):projected_fixture.cells[Vector2i(x,4)]=true
	projected_fixture.player=Vector2i(5,4)
	var projected_actor:Dictionary={"uid":41,"pos":Vector2i(3,4),"hp":30,"kind":0,"species":"leafwisp","pp_primary":12,"pp_secondary":0}
	projected_fixture.enemies.append(projected_actor)
	for enabled in [true,false]:
		projected_fixture.ai_cache_enabled=enabled
		projected_fixture.ai_begin_turn_cache();projected_fixture.ai_begin_actor_cache()
		if not projected_fixture.enemy_strategy_attack_tile(projected_actor,Vector2i(2,4),projected_fixture.player):failures.append("strategy projected self tile must be vacated")
		checks+=1
		projected_fixture.ai_end_turn_cache()
		projected_fixture.enemies.append({"uid":42,"pos":Vector2i(4,4),"hp":20})
		projected_fixture.ai_begin_turn_cache();projected_fixture.ai_begin_actor_cache()
		if projected_fixture.enemy_strategy_attack_tile(projected_actor,Vector2i(2,4),projected_fixture.player):failures.append("strategy projected teammate must still block ray")
		checks+=1
		projected_fixture.ai_end_turn_cache()
		projected_fixture.enemies.pop_back()
	if projected_actor.pos!=Vector2i(3,4) or projected_actor.pp_primary!=12 or not projected_fixture.enemy_actions.is_empty():failures.append("strategy projected planning must not mutate actor")
	checks+=1
	print("KINDRIA_ADAPTIVE_STRATEGY checks=15")
	# Hidden charge and decoy observations must not refresh tactical tracking.
	var visibility_audit=Rules.new()
	for y in range(1,7):
		for x in range(1,7):visibility_audit.cells[Vector2i(x,y)]=true
	visibility_audit.player=Vector2i(4,3);visibility_audit.turns=20
	var audit_actor:Dictionary={"uid":0,"pos":Vector2i(2,3),"hp":30,"kind":0,"species":"rootgnawer","ecology_role":"hunter","ecology_search_enabled":true,"personality_enabled":true}
	var audit_peer:Dictionary={"uid":1,"pos":Vector2i(2,4),"hp":30,"kind":0,"species":"leafwisp","ecology_search_enabled":true,"decoy_turns":2}
	visibility_audit.enemies.append(audit_actor);visibility_audit.enemies.append(audit_peer)
	visibility_audit.enemy_observe_movement(audit_actor,visibility_audit.player)
	visibility_audit.enemy_pursuit_target(audit_actor,visibility_audit.player)
	visibility_audit.turns=21;visibility_audit.player=Vector2i(4,4);visibility_audit.charge_phase="airborne"
	visibility_audit.enemy_observe_movement(audit_actor,visibility_audit.player)
	if audit_actor.has("adaptive_seen_turn"):failures.append("audit hidden movement memory")
	checks+=1
	if visibility_audit.enemy_pursuit_target(audit_actor,visibility_audit.player)!=Vector2i(4,3) or int(audit_actor.get("last_seen_turn",-1))!=20:failures.append("audit hidden location not refreshed")
	checks+=1
	if visibility_audit.enemy_squad_partner(audit_actor,audit_peer):failures.append("audit decoy peer excluded")
	checks+=1
	audit_peer.erase("decoy_turns");visibility_audit.charge_phase=""
	if not visibility_audit.enemy_squad_partner(audit_actor,audit_peer) or visibility_audit.enemy_pursuit_target(audit_actor,visibility_audit.player)!=visibility_audit.player:failures.append("audit visibility restored")
	checks+=1
	checks+=enemy_adversarial_gauntlet(failures)
	checks+=living_dungeon_gauntlet(failures)
	# Geometry-only cache must be symmetric, bounded and cleared between turns.
	var geometry_audit=Rules.new()
	for y in range(1,19):
		for x in range(1,19):geometry_audit.cells[Vector2i(x,y)]=true
	geometry_audit.rooms.append(Rect2i(1,1,18,18))
	for x in range(3,17,3):geometry_audit.cells.erase(Vector2i(x,9))
	geometry_audit.ai_begin_turn_cache()
	for y in range(1,19):
		for x in range(1,19):
			var q:=Vector2i(x,y)
			if geometry_audit.enemy_terrain_kind(q)!=geometry_audit.compute_enemy_terrain_kind(q):failures.append("topology cache parity")
			checks+=1
	for y in range(1,19):
		for x in range(1,19):
			var q:=Vector2i(x,y)
			var r:=Vector2i(19-x,19-y)
			var direct:bool=geometry_audit.compute_enemy_line_of_sight(q,r)
			if direct!=geometry_audit.compute_enemy_line_of_sight(r,q) or direct!=geometry_audit.enemy_line_of_sight(q,r) or direct!=geometry_audit.enemy_line_of_sight(r,q):failures.append("reciprocal LOS parity")
			checks+=1
	if geometry_audit.ai_topology_cache.size()>256 or geometry_audit.ai_cache_hits<=0:failures.append("topology cap or cache reuse")
	checks+=1
	geometry_audit.ai_end_turn_cache()
	if not geometry_audit.ai_topology_cache.is_empty() or not geometry_audit.ai_los_cache.is_empty():failures.append("geometry cache escaped turn")
	checks+=1
	geometry_audit.ai_begin_turn_cache()
	var geometry_point:=Vector2i(2,2)
	geometry_audit.enemy_terrain_kind(geometry_point)
	geometry_audit.ai_end_turn_cache()
	geometry_audit.cells.erase(geometry_point)
	geometry_audit.ai_begin_turn_cache()
	if geometry_audit.enemy_terrain_kind(geometry_point)!="wall":failures.append("topology invalidation between turns")
	geometry_audit.ai_end_turn_cache()
	checks+=1
	print("KINDRIA_GEOMETRY_CACHE checks=651")
	checks+=enemy_integration_gauntlet(failures)
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
