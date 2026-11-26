extends SceneTree
const Rules=preload("res://dungeon_rules.gd")
func _initialize():call_deferred("run")
func run():
	var total=0
	for region in range(3):
		for id in [1,13,24]:
			for seed_value in range(20):
				var field=Rules.new();field.setup(region,id,0,false,false,seed_value+1)
				var first=field.cells.duplicate()
				var clone=Rules.new();clone.setup(region,id,0,false,false,seed_value+1)
				assert(first==clone.cells,"same seed same layout")
				for floor_index in range(field.floor_count):
					assert(field.floor_number==floor_index+1)
					assert(field.route(field.player,field.relic).size()>0)
					assert(field.route(field.player,field.stairs).size()>0)
					assert(not field.descend(),"cannot skip relic")
					var all:Array=field.cells.keys()
					for p in all:
						assert(p==field.player or not field.route(field.player,p).is_empty(),"no disconnected tile")
					# Isolate navigation and pickup from combat.
					field.enemies.clear()
					var coin_pos:Vector2i
					for d in Rules.DIR:
						if field.loot.get(field.player+d,"")=="coin":coin_pos=field.player+d;break
					var wallet:int=field.coins
					assert(field.move(coin_pos) and field.coins==wallet+3)
					field.pickup();assert(field.coins==wallet+3,"cannot collect twice")
					for p in field.route(field.player,field.relic):assert(field.move(p))
					assert(field.secured)
					for p in field.route(field.player,field.stairs):assert(field.move(p))
					assert(field.descend())
					total+=1
				assert(field.finished and field.success)
	var fight=Rules.new();fight.setup(0,1,0,false,false,42)
	fight.enemies.clear()
	var neighbor:Vector2i
	for d in Rules.DIR:
		if fight.cells.has(fight.player+d):neighbor=fight.player+d;break
	fight.enemies.append({"pos":neighbor,"hp":12,"kind":0})
	var hp:int=fight.hp
	assert(fight.attack() and fight.hp<hp and fight.enemies.size()==1)
	assert(fight.attack(true) and fight.enemies.is_empty() and fight.energy==6)
	assert(fight.heal() and fight.hp==hp and fight.potions==1)
	var ranged=Rules.new();ranged.setup(0,1,0,false,false,99,1)
	ranged.enemies.clear()
	var direction=Vector2i.ZERO
	for d in Rules.DIR:
		if ranged.cells.has(ranged.player+d) and ranged.cells.has(ranged.player+d*2):direction=d;break
	assert(direction!=Vector2i.ZERO)
	ranged.enemies.append({"pos":ranged.player+direction*2,"hp":8,"kind":0})
	assert(ranged.attack(true) and ranged.enemies.is_empty() and ranged.defeated==1)
	var boss=Rules.new();boss.setup(0,14,0,true,false,123,1)
	boss.floor_number=boss.floor_count;boss.generate_floor()
	assert(not boss.guardian_defeated and boss.enemy_at(boss.relic)>=0)
	boss.player=boss.relic;boss.pickup();assert(not boss.secured)
	var idx:int=boss.enemy_at(boss.relic)
	boss.enemies[idx].hp=1;boss.strike(idx)
	assert(boss.guardian_defeated);boss.pickup();assert(boss.secured)
	var heavy=Rules.new();heavy.setup(0,1,0,false,false,19)
	heavy.enemies.clear()
	var near:Vector2i
	for d in Rules.DIR:
		if heavy.cells.has(heavy.player+d):near=heavy.player+d;break
	heavy.enemies.append({"pos":near,"hp":20,"kind":2,"windup":false})
	var health:int=heavy.hp
	heavy.enemy_turn();assert(heavy.hp==health and heavy.enemies[0].windup)
	heavy.enemy_turn();assert(heavy.hp<health and not heavy.enemies[0].windup)
	print("FOREVER_DUNGEON_PASS ",total)
	quit()
