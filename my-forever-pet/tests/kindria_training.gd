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
	print("KINDRIA_TRAINING_PASS 18 types 26 natures 33 EV yields")
	quit()
