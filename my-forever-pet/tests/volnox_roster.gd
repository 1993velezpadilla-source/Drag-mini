extends SceneTree
const Rules=preload("res://dungeon_rules.gd")
func _initialize():
	var ids:Dictionary={}
	var gaits:Dictionary={}
	var moves:Dictionary={}
	for region in range(3):
		assert(Rules.MINION_ROSTER[region].size()==11)
		for row in Rules.MINION_ROSTER[region]:
			assert(not ids.has(row[0]))
			assert(not gaits.has(row[2]))
			assert(not moves.has(row[3]))
			ids[row[0]]=true
			gaits[row[2]]=true
			moves[row[3]]=true
		var d=Rules.new()
		d.setup(region,1,0,false,false,29)
		for e in d.enemies:
			assert(ids.has(e.species) and gaits.has(e.gait) and moves.has(e.signature))
		assert(int(d.enemy_profile(3,99)[4])==3)
	var fx:Dictionary={}
	var patterns:Dictionary={}
	var effects:Dictionary={}
	for region in range(3):
		for row in Rules.MINION_ROSTER[region]:
			var id:String=row[0]
			assert(Rules.SIGNATURE_SKILLS.has(id))
			var skill:Array=Rules.SIGNATURE_SKILLS[id]
			var pattern:String=Rules.ATTACK_PATTERNS[id]
			patterns[pattern]=true
			assert(not fx.has(skill[6]))
			fx[skill[6]]=true
			var d=Rules.new()
			d.region=region;d.hp=100;d.max_hp=100;d.player=Vector2i(4,4);d.energy=8
			for x in range(9):
				for y in range(9):d.cells[Vector2i(x,y)]=true
			var pos:Vector2i=d.player-Vector2i(int(skill[0]),0)
			d.enemies.append({"uid":0,"pos":pos,"hp":30,"max_hp":30,"kind":row[4],"species":id,"name":row[1],"signature":row[3],"windup":false})
			d.enemy_turn()
			if bool(skill[1]):
				assert(d.hp==100 and d.enemies[0].windup,id+" telegraph")
				d.enemy_turn()
			assert(d.hp<100,id+" hit")
			assert(d.enemy_actions.size()==1 and d.enemy_actions[0].fx==skill[6],id+" signature")
			assert(d.enemy_actions[0].effect==skill[4])
			effects[skill[4]]=true
			match str(skill[4]):
				"poison":assert(d.poison_turns==int(skill[5]))
				"weaken":assert(d.weakened_strikes==int(skill[5]))
				"mark":assert(d.marked_damage==int(skill[5]))
				"drain":assert(d.energy==8-int(skill[5]))
				"guard":assert(d.enemies[0].guard==int(skill[5]))
				"pounce":assert(d.distance(d.enemies[0].pos,d.player)==1)
			# Line of sight cannot fire through a wall.
			d.cells.erase(d.player-Vector2i(1,0))
			assert(not d.line_of_attack(d.player-Vector2i(2,0),d.player,3))
	assert(fx.size()==33 and effects.size()==7 and patterns.size()==6)
	var second_names:Dictionary={}
	for species in Rules.SECONDARY_SKILLS:
		var alt:Array=Rules.SECONDARY_SKILLS[species]
		assert(not second_names.has(alt[2]));second_names[alt[2]]=true
		var encounter=Rules.new()
		encounter.hp=100;encounter.max_hp=100;encounter.player=Vector2i(4,4)
		for x in range(9):
			for y in range(9):encounter.cells[Vector2i(x,y)]=true
		encounter.enemies.append({"pos":encounter.player-Vector2i(int(alt[0]),0),"uid":0,"hp":30,"kind":0,"species":species,"windup":false,"cooldown":2})
		encounter.enemy_turn()
		assert(encounter.hp<100 and encounter.enemy_actions[0].fx=="alt_"+species,species+" secondary")
		assert(encounter.enemy_actions[0].move==alt[2])
	assert(second_names.size()==33)
	print("VOLNOX_SECONDARY_SKILL_PASS 33")
	var grid=Rules.new()
	for x in range(7):
		for y in range(7):grid.cells[Vector2i(x,y)]=true
	var origin:=Vector2i(3,3)
	assert(grid.attack_footprint(origin,Vector2i.RIGHT,"front",1).size()==1)
	assert(grid.attack_footprint(origin,Vector2i.RIGHT,"line",3).size()==3)
	assert(grid.attack_footprint(origin,Vector2i.RIGHT,"fan",1).has(origin+Vector2i(1,1)))
	assert(grid.attack_footprint(origin,Vector2i.RIGHT,"corner",3).has(origin+Vector2i(1,2)))
	assert(not grid.attack_footprint(origin,Vector2i.RIGHT,"corner",3).has(origin+Vector2i(-1,1)))
	assert(grid.attack_footprint(origin,Vector2i.RIGHT,"radius",2).size()==12)
	assert(grid.attack_footprint(origin,Vector2i.RIGHT,"cross",3).size()==12)
	grid.cells.erase(origin+Vector2i.RIGHT)
	assert(grid.attack_footprint(origin,Vector2i.RIGHT,"line",3).is_empty())
	assert(grid.attack_footprint(origin,Vector2i.RIGHT,"corner",3).is_empty())
	grid.cells[origin+Vector2i.RIGHT]=true
	grid.player=origin+Vector2i.RIGHT*2;grid.hp=100;grid.max_hp=100
	grid.enemies.append({"pos":origin,"uid":0,"hp":30,"kind":2,"species":"thornbeetle","windup":false})
	grid.enemy_turn();assert(grid.enemies[0].windup)
	grid.player=origin+Vector2i.UP;grid.enemy_turn()
	assert(grid.hp==100 and grid.enemy_actions[0].phase=="cancel","locked aim cannot retarget")
	print("VOLNOX_GRID_PATTERN_PASS 6")
	print("VOLNOX_SIGNATURE_COMBAT_PASS ",fx.size())
	print("VOLNOX_ROSTER_PASS ",ids.size())
	quit()
