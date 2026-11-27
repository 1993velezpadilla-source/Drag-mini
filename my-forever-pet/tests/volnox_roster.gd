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
	var effects:Dictionary={}
	for region in range(3):
		for row in Rules.MINION_ROSTER[region]:
			var id:String=row[0]
			assert(Rules.SIGNATURE_SKILLS.has(id))
			var skill:Array=Rules.SIGNATURE_SKILLS[id]
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
	assert(fx.size()==33 and effects.size()==7)
	print("VOLNOX_SIGNATURE_COMBAT_PASS ",fx.size())
	print("VOLNOX_ROSTER_PASS ",ids.size())
	quit()
