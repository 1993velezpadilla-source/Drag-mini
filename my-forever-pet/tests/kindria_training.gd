extends SceneTree
const Rules=preload("res://dungeon_rules.gd")
func _initialize():
	assert(Rules.TYPE_CHART.size()==18 and Rules.ENEMY_TRAINING.size()==33)
	assert(is_equal_approx(Rules.type_multiplier("electric",["water","flying"]),1.96))
	assert(is_equal_approx(Rules.type_multiplier("grass",["water","flying"]),.98))
	assert(is_equal_approx(Rules.type_multiplier("ground",["flying"]),.5))
	assert(Rules.type_multiplier("ground",["flying"],"classic")==0.0)
	assert(is_equal_approx(Rules.type_multiplier("electric",["water","flying"],"classic"),4.0))
	assert(Rules.NATURE_NAMES.size()==26)
	var expected:Array=[[-1,-1],[1,2],[1,5],[1,3],[1,4],[2,1],[-1,-1],[2,5],[2,3],[2,4],[5,1],[5,2],[-1,-1],[5,3],[5,4],[3,1],[3,2],[3,5],[-1,-1],[3,4],[4,1],[4,2],[4,5],[4,3],[-1,-1],[2,5]]
	var unique:Dictionary={}
	var neutral_count:int=0
	for n in range(26):
		assert(Rules.nature_pair(n)==expected[n],Rules.NATURE_NAMES[n])
		if n<25:
			if expected[n][0]==-1:neutral_count+=1
			else:unique[str(expected[n])]=true
		for stat in range(6):
			var factor:float=1.1 if stat==expected[n][0] else .9 if stat==expected[n][1] else 1.0
			assert(is_equal_approx(Rules.nature_factor(n,stat),factor))
			var neutral:float=Rules.combat_stat_value(1,[0,0,0,0,0,0],0,stat)
			assert(is_equal_approx(Rules.combat_stat_value(1,[0,0,0,0,0,0],n,stat),neutral*factor))
	assert(neutral_count==5 and unique.size()==20)
	var fast=Rules.new()
	fast.configure_training({"level":1,"nature":10,"ev":[0,0,0,0,0,0]})
	var slow=Rules.new()
	slow.configure_training({"level":1,"nature":2,"ev":[0,0,0,0,0,0]})
	var fast_dodges:int=0
	var slow_dodges:int=0
	for i in range(100):
		if fast.speed_evade():fast_dodges+=1
		if slow.speed_evade():slow_dodges+=1
	assert(fast_dodges==11 and slow_dodges==9)
	print("KINDRIA_NATURE_MATRIX_PASS 25 official + Lazy; 156 modifiers; 20 directional pairs; 5 neutral")
	assert(is_equal_approx(Rules.nature_factor(10,5),1.1))
	assert(is_equal_approx(Rules.nature_factor(10,1),.9))
	assert(is_equal_approx(Rules.nature_factor(22,4),1.1))
	assert(is_equal_approx(Rules.nature_factor(22,5),.9))
	assert(Rules.nature_factor(24,1)==1.0)
	assert(Rules.stat_value(50,100,252,0,1)-Rules.stat_value(50,100,0,0,1)==63)
	assert(Rules.normalized_ev([252,252,252,252,252,252])==[252,252,6,0,0,0])
	var d=Rules.new()
	for species in Rules.ENEMY_TRAINING:
		var info:Array=Rules.ENEMY_TRAINING[species]
		var before:int=d.earned_ev[int(info[3])]
		d.gain_enemy_ev({"species":species})
		assert(d.earned_ev[int(info[3])]==before+int(info[4]))
	assert(d.earned_ev.reduce(func(a,b):return a+b,0)>33)
	var cast=Rules.new()
	cast.player=Vector2i(3,3)
	for x in range(7):
		for y in range(7):cast.cells[Vector2i(x,y)]=true
	cast.configure_training({"types":["grass"],"level":15,"nature":0,"ev":[0,0,0,0,0,0],"moves":["lib_grass_1","lib_grass_2","lib_grass_3","lib_fire_1"]})
	assert(cast.equipped_moves.size()==3 and not cast.move_pp.has("lib_fire_1"))
	cast.enemies.append({"pos":Vector2i(4,3),"hp":100,"kind":0,"species":"reef_pup"})
	assert(not cast.cast_move("lib_grass_2",Vector2i.LEFT))
	assert(cast.cast_move("lib_grass_1",Vector2i.RIGHT))
	assert(cast.move_pp.lib_grass_1==17 and cast.player_attack_path.size()==1)
	assert(cast.player_attack_fx=="lib_grass_1")
	cast.move_pp.lib_grass_1=0
	assert(not cast.cast_move("lib_grass_1",Vector2i.RIGHT))
	assert(Rules.MOVE_LIBRARY.lib_grass_1.reference_id==182)
	assert(Rules.MOVE_LIBRARY.lib_grass_1.power==6)
	assert(is_equal_approx(Rules.reference_accuracy(Rules.MOVE_LIBRARY.lib_electric_3),73.92))
	assert(Rules.reference_accuracy(Rules.MOVE_LIBRARY.lib_electric_2)==100.0)
	assert(Rules.MOVE_LIBRARY.lib_water_2.reach==10)
	print("KINDRIA_EOS_REFERENCE_PASS 9 mapped moves")
	print("KINDRIA_LEARNSET_PP_PASS")
	print("KINDRIA_TRAINING_PASS 18 types 26 natures 33 EV yields")
	quit()
