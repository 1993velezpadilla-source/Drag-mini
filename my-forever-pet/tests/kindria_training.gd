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
	print("KINDRIA_TRAINING_PASS 18 types 26 natures 33 EV yields")
	quit()
