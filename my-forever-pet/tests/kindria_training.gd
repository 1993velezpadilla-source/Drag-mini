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
	var eos_count:int=0
	for id in Rules.MOVE_LIBRARY:
		if not str(id).begins_with("eos_"):continue
		var move:Dictionary=Rules.MOVE_LIBRARY[id]
		assert(int(str(id).trim_prefix("eos_"))==int(move.reference_id))
		assert(move.pp>0 and (move.power>0 or move.has("heal_fraction") or move.has("inflict_status") or move.has("stat_changes")))
		assert(move.reference_strikes==1 or (move.has("hit_min") and move.hit_min>=2 and move.hit_max<=5))
		assert(move.category in ["physical","special"] or (move.category=="status" and (move.has("heal_fraction") or move.has("inflict_status") or move.has("stat_changes"))))
		assert(id in Rules.available_moves([move.type],100))
		assert(not id in Rules.available_moves([move.type],15))
		assert(Rules.reference_accuracy(move)>=0.0 and Rules.reference_accuracy(move)<=100.0)
		eos_count+=1
	assert(eos_count==Rules.EOS_PROTOTYPE_COUNT)
	var multi_count:int=0
	for id in Rules.MOVE_LIBRARY:
		var entry:Dictionary=Rules.MOVE_LIBRARY[id]
		if entry.has("hit_min"):multi_count+=1
	assert(multi_count==Rules.EOS_MULTIHIT_COUNT)
	var observed_double:bool=false
	for seed_id in range(32):
		var burst=Rules.new()
		burst.rng.seed=seed_id
		burst.player=Vector2i(1,1)
		for x in range(12):burst.cells[Vector2i(x,1)]=true
		burst.configure_training({"types":["fighting"],"level":100,"moves":["eos_222"]})
		burst.enemies.append({"pos":Vector2i(2,1),"hp":1000,"kind":0,"species":"reef_pup"})
		assert(burst.cast_move("eos_222",Vector2i.RIGHT))
		assert(burst.last_move_attempts==2 and burst.move_pp.eos_222==13 and burst.turns==1)
		if burst.last_move_hits==2:observed_double=true
	assert(observed_double)
	print("KINDRIA_MULTIHIT_PASS ",multi_count)
	var heal=Rules.new()
	heal.configure_training({"types":["normal"],"level":100,"moves":["eos_117","eos_218"]})
	heal.hp=10
	assert(heal.cast_move("eos_117",Vector2i.UP))
	assert(heal.hp==28 and heal.last_move_healed==18 and heal.turns==1 and heal.move_pp.eos_117==11)
	assert(heal.attack_target==heal.player)
	heal.hp=heal.max_hp
	assert(not heal.cast_move("eos_117",Vector2i.UP))
	assert(heal.move_pp.eos_117==11 and heal.turns==1)
	var drain=Rules.new()
	drain.hp=10
	drain.enemies.append({"pos":Vector2i(1,0),"hp":5,"kind":0,"species":"reef_pup"})
	drain.strike(0,true,-1,"eos_076")
	assert(drain.hp==12 and drain.last_move_healed==2 and drain.enemies.is_empty())
	drain.hp=35
	drain.enemies.append({"pos":Vector2i(1,0),"hp":100,"kind":0,"species":"reef_pup"})
	drain.strike(0,true,-1,"eos_076")
	assert(drain.hp==drain.max_hp)
	print("KINDRIA_HEAL_DRAIN_PASS")
	assert(Rules.EOS_ESCALATING_COUNT==3 and Rules.EOS_RECOIL_COUNT==7)
	var triple_success:bool=false
	var stopped:bool=false
	for seed_id in range(128):
		var chain=Rules.new()
		chain.rng.seed=seed_id;chain.player=Vector2i(1,1)
		chain.cells[chain.player]=true;chain.cells[Vector2i(2,1)]=true
		chain.equipped_moves=["eos_210"];chain.move_pp={"eos_210":15}
		chain.enemies.append({"pos":Vector2i(2,1),"hp":1000,"kind":0,"species":"reef_pup"})
		assert(chain.cast_move("eos_210",Vector2i.RIGHT))
		assert(chain.turns==1 and chain.move_pp.eos_210==14)
		if chain.last_move_hits==3:
			assert(chain.last_move_damage==[8,16,24]);triple_success=true
		else:
			assert(chain.last_move_attempts==chain.last_move_hits+1);stopped=true
	assert(triple_success and stopped)
	var recoil_success:bool=false
	var recoil_fatal:bool=false
	for seed_id in range(32):
		var risk=Rules.new()
		risk.rng.seed=seed_id;risk.player=Vector2i(1,1)
		risk.cells[risk.player]=true;risk.cells[Vector2i(2,1)]=true
		risk.equipped_moves=["eos_533"];risk.move_pp={"eos_533":5}
		risk.max_hp=40;risk.hp=10
		risk.enemies.append({"pos":Vector2i(2,1),"hp":1,"kind":0,"species":"reef_pup"})
		assert(risk.cast_move("eos_533",Vector2i.RIGHT))
		if risk.last_move_hits>0:
			assert(risk.last_move_recoil==10 and risk.hp==0 and risk.finished and not risk.success and risk.turns==1)
			assert(risk.enemy_actions.is_empty());recoil_fatal=true
		else:assert(risk.last_move_recoil==0)
		risk=Rules.new()
		risk.rng.seed=seed_id;risk.player=Vector2i(1,1)
		risk.cells[risk.player]=true;risk.cells[Vector2i(2,1)]=true
		risk.equipped_moves=["eos_140"];risk.move_pp={"eos_140":12}
		risk.max_hp=40;risk.hp=40
		risk.enemies.append({"pos":Vector2i(2,1),"hp":1,"kind":0,"species":"reef_pup"})
		assert(risk.cast_move("eos_140",Vector2i.RIGHT))
		if risk.last_move_hits>0:
			assert(risk.hp==35 and risk.last_move_recoil==5);recoil_success=true
	assert(recoil_success and recoil_fatal)
	print("KINDRIA_ESCALATING_RECOIL_PASS")
	var charge_count:int=0
	for id in Rules.MOVE_LIBRARY:
		if Rules.MOVE_LIBRARY[id].has("charge_phase"):charge_count+=1
	assert(charge_count==Rules.EOS_TWO_TURN_COUNT)
	var charged=Rules.new()
	charged.player=Vector2i(1,1)
	charged.cells[charged.player]=true;charged.cells[Vector2i(2,1)]=true
	charged.equipped_moves=["eos_008"];charged.move_pp={"eos_008":1}
	charged.enemies.append({"pos":Vector2i(2,1),"hp":1000,"kind":0,"species":"reef_pup"})
	assert(charged.cast_move("eos_008",Vector2i.RIGHT))
	assert(charged.charged_move_id=="eos_008" and charged.charge_phase=="underground")
	assert(charged.hp==36 and charged.turns==1 and charged.move_pp.eos_008==0 and charged.enemies[0].hp==1000)
	assert(charged.cast_move("eos_008",Vector2i.LEFT))
	assert(charged.charged_move_id.is_empty() and charged.turns==2 and charged.move_pp.eos_008==0)
	assert(charged.last_move_damage==[24])
	var empty_charge=Rules.new()
	empty_charge.player=Vector2i(1,1)
	empty_charge.cells[empty_charge.player]=true;empty_charge.cells[Vector2i(2,1)]=true
	empty_charge.equipped_moves=["eos_151"];empty_charge.move_pp={"eos_151":9}
	assert(empty_charge.cast_move("eos_151",Vector2i.RIGHT))
	assert(empty_charge.move(Vector2i(2,1)))
	assert(empty_charge.player==Vector2i(1,1) and empty_charge.turns==2 and empty_charge.move_pp.eos_151==8 and empty_charge.charged_move_id.is_empty())
	print("KINDRIA_TWO_TURN_PASS ",charge_count)
	var status_run=Rules.new()
	status_run.player=Vector2i(1,1)
	status_run.cells[status_run.player]=true;status_run.cells[Vector2i(2,1)]=true
	status_run.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	assert(status_run.apply_enemy_status(0,"sleep"))
	var sleep_duration:int=status_run.enemies[0].sleep_turns
	assert(sleep_duration>=3 and sleep_duration<=6)
	assert(not status_run.apply_enemy_status(0,"sleep"))
	for i in range(sleep_duration):status_run.enemy_turn()
	assert(status_run.hp==36 and status_run.enemies[0].sleep_turns==0)
	assert(status_run.apply_enemy_status(0,"poison"))
	status_run.tick_enemy_statuses()
	assert(status_run.enemies[0].hp==98)
	for i in range(19):status_run.tick_enemy_statuses()
	assert(status_run.enemies[0].hp==98)
	status_run.tick_enemy_statuses()
	assert(status_run.enemies[0].hp==96)
	assert(status_run.apply_enemy_status(0,"toxic"))
	status_run.tick_enemy_statuses()
	assert(status_run.enemies[0].hp==90)
	assert(status_run.apply_enemy_status(0,"freeze"))
	status_run.strike(0,false)
	assert(status_run.enemies[0].hp==90)
	status_run.strike(0,true,-1,"eos_262")
	assert(status_run.enemies[0].hp==83 and not status_run.enemies[0].has("major_status"))
	var spell=Rules.new()
	spell.player=Vector2i(1,1)
	spell.cells[spell.player]=true;spell.cells[Vector2i(2,1)]=true
	spell.equipped_moves=["eos_013"];spell.move_pp={"eos_013":13}
	spell.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	assert(spell.cast_move("eos_013",Vector2i.RIGHT))
	assert(spell.enemies[0].hp==100 and spell.last_move_hits==1 and spell.move_pp.eos_013==12 and spell.turns==1)
	print("KINDRIA_STATUS_PASS")
	assert(is_equal_approx(Rules.stage_factor("attack",2),332.0/256.0))
	assert(is_equal_approx(Rules.stage_factor("sp_defense",2),409.0/256.0))
	var stage_run=Rules.new()
	stage_run.player=Vector2i(1,1)
	stage_run.cells[stage_run.player]=true
	stage_run.equipped_moves=["eos_181"];stage_run.move_pp={"eos_181":7}
	for i in range(6):assert(stage_run.cast_move("eos_181",Vector2i.UP))
	assert(stage_run.player_stages.attack==10 and stage_run.move_pp.eos_181==1 and stage_run.turns==6)
	stage_run.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	stage_run.strike(0)
	assert(stage_run.enemies[0].hp==89)
	var target_stages:Dictionary={}
	var target_halves:Dictionary={}
	for i in range(9):Rules.apply_stat_changes(target_stages,target_halves,Rules.MOVE_LIBRARY.eos_027)
	assert(target_halves.defense==7 and target_stages.is_empty())
	assert(is_equal_approx(Rules.stat_effect(target_stages,target_halves,"defense"),1.0/128.0))
	stage_run.clear_combat_effects()
	assert(stage_run.player_stages.is_empty())
	print("KINDRIA_STAT_STAGE_PASS")
	assert(Rules.EOS_IDENTIFIED_COUNT==468)
	print("KINDRIA_EOS_PROTOTYPES_PASS ",eos_count)
	print("KINDRIA_LEARNSET_PP_PASS")
	print("KINDRIA_TRAINING_PASS 18 types 26 natures 33 EV yields")
	quit()
