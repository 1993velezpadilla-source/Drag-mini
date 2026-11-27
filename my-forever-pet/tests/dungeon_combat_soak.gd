extends SceneTree
const Rules=preload("res://dungeon_rules.gd")
func _initialize():call_deferred("run")
func invariant(d):
	assert(d.cells.has(d.player))
	assert(d.hp>=0 and d.hp<=d.max_hp)
	assert(d.energy>=0 and d.energy<=8)
	assert(d.potions>=0 and d.coins>=0)
	var occupied={}
	for enemy in d.enemies:
		assert(d.cells.has(enemy.pos) and enemy.pos!=d.player)
		assert(not occupied.has(enemy.pos))
		occupied[enemy.pos]=true
		assert(enemy.hp>0 and enemy.hp<=enemy.max_hp)
func step(d,policy:Dictionary)->bool:
	if d.hp<=d.max_hp/2 and d.potions>0:return d.heal()
	if d.player==d.stairs and d.secured:return d.descend()
	if d.energy>=2 and d.attack(true):return true
	if d.attack():return true
	var target:Vector2i=d.stairs if d.secured else d.relic
	# Keep a selected healing detour until consumed. A dynamic enemy-avoidance
	# route and a changing nearest pickup can otherwise oscillate between tiles.
	var detour:Vector2i=policy.get("detour",Vector2i(-999,-999))
	if not d.loot.has(detour) or d.player==detour:
		policy.erase("detour")
		detour=Vector2i(-999,-999)
	if not policy.has("detour") and not d.secured and (d.potions<2 or d.hp<d.max_hp/2):
		var best_distance=6
		for p in d.loot:
			var kind:String=d.loot[p]
			if kind!="potion" and (kind!="spring" or d.hp==d.max_hp and d.energy==8):continue
			var candidate=d.route(d.player,p)
			if not candidate.is_empty() and candidate.size()<best_distance:
				best_distance=candidate.size();detour=p
		if detour!=Vector2i(-999,-999):policy["detour"]=detour
	if policy.has("detour") and not d.secured:target=policy["detour"]
	# Static shortest route guarantees progress toward a fixed goal if no combat
	# occurs. Occupied next tiles invoke the real production melee mechanic.
	var route=d.route(d.player,target)
	if route.is_empty():
		print("DUNGEON_STALL seed=",d.seed_value," floor=",d.floor_number," pos=",d.player," target=",target," secured=",d.secured)
		return false
	return d.move(route[0])
func combat_state(d,policy:Dictionary)->String:
	# Exclude counters and feedback strings: they do not change future choices.
	# The policy is deterministic, and enemy turns do not use RNG on a floor.
	return str([d.floor_number,d.player,d.hp,d.energy,d.potions,d.secured,d.guardian_defeated,d.enemies,d.loot,d.traps,d.poison_turns,d.weakened_strikes,d.marked_damage,policy.get("detour",Vector2i(-999,-999))])
func run():
	var victories=0;var defeats=0;var stalls=0;var actions=0;var guardians=0;var cycles=0
	for region in range(3):
		for id in [1,13,24]:
			var local_wins=0
			for seed_value in range(12):
				var d=Rules.new();d.setup(region,id,0,seed_value%2==0,false,seed_value+301,seed_value%3)
				var attempts=0
				var seen:Dictionary={}
				var policy:Dictionary={}
				var history:Array[String]=[]
				var reason="action limit"
				var previous_floor:int=d.floor_number
				while not d.finished and attempts<900:
					invariant(d)
					if d.floor_number!=previous_floor:
						seen.clear();history.clear();policy.clear();previous_floor=d.floor_number
					var key=combat_state(d,policy)
					if seen.has(key):
						cycles+=1;reason="repeated combat state"
						print("DUNGEON_CYCLE region=",region," seed=",d.seed_value," id=",id," floor=",d.floor_number," length=",attempts-int(seen[key])," player=",d.player," relic=",d.relic," stairs=",d.stairs," secured=",d.secured," guardian=",d.guardian_defeated," recent=",history)
						break
					seen[key]=attempts
					history.append("%s HP=%d energy=%d enemies=%d"%[str(d.player),d.hp,d.energy,d.enemies.size()])
					if history.size()>12:history.pop_front()
					if not step(d,policy):
						reason="no policy action";break
					attempts+=1;actions+=1
				invariant(d)
				if d.success:
					assert(d.finished and d.secured and d.floor_number==d.floor_count)
					if d.rescue_finale:
						assert(d.guardian_defeated);guardians+=1
					victories+=1;local_wins+=1
				elif d.finished:defeats+=1
				else:
					stalls+=1
					print("DUNGEON_UNFINISHED seed=",d.seed_value," id=",id," floor=",d.floor_number," turns=",d.turns," attempts=",attempts," HP=",d.hp," reason=",reason)
			print("DUNGEON_BALANCE region=",region," id=",id," wins=",local_wins,"/12")
	assert(victories+defeats+stalls==108)
	print("DUNGEON_COMBAT_POLICY committed_detour_static_route_v2")
	print("DUNGEON_COMBAT_SOAK_PASS runs=108 wins=",victories," defeats=",defeats," stalls=",stalls," actions=",actions," guardian_wins=",guardians," cycles=",cycles)
	if stalls>0:print("DUNGEON_COMBAT_BALANCE_UNAPPROVED incomplete=",stalls,"; 108 region runs include only 36 seed/specimen/skill combinations")
	quit()
