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
func step(d)->bool:
	if d.hp<=d.max_hp/2 and d.potions>0:return d.heal()
	if d.player==d.stairs and d.secured:return d.descend()
	if d.energy>=2 and d.attack(true):return true
	if d.attack():return true
	var target:Vector2i=d.stairs if d.secured else d.relic
	# Seek nearby healing items before engaging a distant objective.
	if d.potions<2 or d.hp<d.max_hp/2:
		for p in d.loot:
			if d.loot[p] in ["potion","spring"] and d.distance(p,d.player)<=5:
				target=p;break
	var route=d.route(d.player,target,true)
	if route.is_empty():route=d.route(d.player,target)
	if route.is_empty():return false
	return d.move(route[0])
func run():
	var victories=0;var defeats=0;var stalls=0;var actions=0;var guardians=0
	for region in range(3):
		for id in [1,13,24]:
			var local_wins=0
			for seed_value in range(12):
				var d=Rules.new();d.setup(region,id,0,seed_value%2==0,false,seed_value+301,seed_value%3)
				var attempts=0
				while not d.finished and attempts<900:
					invariant(d)
					if not step(d):break
					attempts+=1;actions+=1
				invariant(d)
				if d.success:
					assert(d.finished and d.secured and d.floor_number==d.floor_count)
					if d.rescue_finale:
						assert(d.guardian_defeated);guardians+=1
					victories+=1;local_wins+=1
				elif d.finished:defeats+=1
				else:stalls+=1
			print("DUNGEON_BALANCE region=",region," id=",id," wins=",local_wins,"/12")
	print("DUNGEON_COMBAT_SOAK_PASS runs=108 wins=",victories," defeats=",defeats," stalls=",stalls," actions=",actions," guardian_wins=",guardians)
	quit()
