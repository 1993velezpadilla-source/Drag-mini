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
		assert(move.pp>0 and (move.power>0 or move.has("heal_fraction") or move.has("inflict_status") or move.has("stat_changes") or move.has("shield_kind") or move.has("boon_kind") or move.has("weather_set") or move.has("floor_sport") or move.has("weather_heal") or move.has("special_rule") or move.has("trap_kind") or move.has("blast_radius") or move.has("stat_transfer") or move.has("random_cast") or move.has("reserve_action") or move.has("curse_action") or move.get("sleep_reactive",false)))
		assert(move.reference_strikes==1 or (move.has("hit_min") and move.hit_min>=2 and move.hit_max<=5))
		assert(move.category in ["physical","special"] or (move.category=="status" and (move.has("heal_fraction") or move.has("inflict_status") or move.has("stat_changes") or move.has("shield_kind") or move.has("boon_kind") or move.has("weather_set") or move.has("floor_sport") or move.has("weather_heal") or move.has("special_rule") or move.has("trap_kind") or move.has("blast_radius") or move.has("stat_transfer") or move.has("random_cast") or move.has("reserve_action") or move.has("curse_action") or move.get("sleep_reactive",false))))
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
	var fast_walk=Rules.new()
	fast_walk.player=Vector2i(1,1)
	for x in range(1,8):fast_walk.cells[Vector2i(x,1)]=true
	fast_walk.equipped_moves=["eos_540"];fast_walk.move_pp={"eos_540":22}
	assert(fast_walk.cast_move("eos_540",Vector2i.RIGHT))
	assert(fast_walk.travel_speed()==3 and fast_walk.move_pp.eos_540==21 and fast_walk.turns==0)
	assert(fast_walk.move(Vector2i(2,1)) and fast_walk.turns==0)
	assert(fast_walk.move(Vector2i(3,1)) and fast_walk.turns==0)
	assert(fast_walk.move(Vector2i(4,1)) and fast_walk.turns==1)
	fast_walk.player_stages={"attack":3}
	fast_walk.reset_room_stats()
	assert(fast_walk.player_stages.is_empty() and fast_walk.travel_speed()==3)
	for i in range(5):fast_walk.enemy_turn()
	assert(fast_walk.travel_speed()==1)
	var slow_run=Rules.new()
	slow_run.player=Vector2i(1,1)
	slow_run.cells[slow_run.player]=true;slow_run.cells[Vector2i(2,1)]=true
	slow_run.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	assert(slow_run.slow_enemy(slow_run.enemies[0]))
	slow_run.enemy_turn()
	assert(slow_run.hp==36 and slow_run.enemy_actions.is_empty())
	assert(int(slow_run.enemies[0].slow_turns)%2==1)
	var skull=Rules.new()
	skull.equipped_moves=["eos_348"];skull.move_pp={"eos_348":15}
	assert(skull.cast_move("eos_348",Vector2i.UP))
	assert(is_equal_approx(skull.player_stat_effect("defense"),Rules.stage_factor("defense",1)))
	assert(skull.release_charge())
	assert(is_equal_approx(skull.player_stat_effect("defense"),1.0))
	print("KINDRIA_TRAVEL_SPEED_PASS")
	var ward=Rules.new()
	ward.player=Vector2i(1,1)
	ward.cells[ward.player]=true;ward.cells[Vector2i(2,1)]=true
	assert(ward.activate_shield(Rules.MOVE_LIBRARY.eos_338))
	assert(ward.shield_damage(10,"physical")==5 and ward.shield_damage(10,"special")==10)
	assert(ward.activate_shield(Rules.MOVE_LIBRARY.eos_259))
	assert(ward.shield_kind=="screen" and ward.shield_damage(10,"special")==5 and ward.shield_damage(10,"physical")==10)
	assert(ward.activate_shield(Rules.MOVE_LIBRARY.eos_104))
	ward.hp=3
	assert(ward.shield_damage(20,"physical")==2)
	assert(ward.activate_shield(Rules.MOVE_LIBRARY.eos_301))
	assert(ward.shield_damage(20,"special")==0)
	ward.hp=36
	ward.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	assert(ward.activate_shield(Rules.MOVE_LIBRARY.eos_051))
	assert(not ward.activate_shield(Rules.MOVE_LIBRARY.eos_038))
	ward.queue_counter(Vector2i(2,1),8,"physical");ward.queue_counter(Vector2i(2,1),10,"special")
	ward.flush_counters()
	assert(ward.enemies[0].hp==92)
	assert(ward.activate_shield(Rules.MOVE_LIBRARY.eos_532))
	ward.queue_counter(Vector2i(2,1),10,"special");ward.flush_counters()
	assert(ward.enemies[0].hp==87)
	ward.clear_combat_effects()
	assert(ward.shield_kind.is_empty() and ward.shield_turns==0)
	print("KINDRIA_SHIELD_PASS")
	var boon=Rules.new()
	boon.player=Vector2i(1,1)
	boon.cells[boon.player]=true
	boon.equipped_moves=["eos_074"];boon.move_pp={"eos_074":27}
	assert(boon.cast_move("eos_074",Vector2i.UP))
	assert(boon.boon_active("focus") and boon.move_pp.eos_074==26 and boon.turns==1)
	assert(boon.roll_player_critical(Rules.MOVE_LIBRARY.eos_210,{}))
	assert(not boon.roll_player_critical(Rules.MOVE_LIBRARY.eos_210,{"critical_immune":true}))
	assert(Rules.critical_damage(11,true)==16 and Rules.critical_damage(11,false)==11)
	boon.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	boon.strike(0,true,-1,"eos_262")
	assert(boon.enemies[0].hp==90 and boon.last_critical_hits==1)
	assert(boon.apply_player_boon(Rules.MOVE_LIBRARY.eos_447))
	assert(not boon.roll_enemy_critical(100))
	assert(boon.apply_player_boon(Rules.MOVE_LIBRARY.eos_130))
	boon.apply_signature_effect(0,[1,false,1,0,"weaken",4,"basic_strike"])
	assert(boon.weakened_strikes==0)
	boon.poison_turns=5;boon.marked_damage=4
	assert(boon.apply_player_boon(Rules.MOVE_LIBRARY.eos_015))
	assert(boon.poison_turns==0 and boon.marked_damage==0 and boon.boon_active("focus"))
	boon.max_hp=100;boon.hp=50
	assert(boon.apply_player_boon(Rules.MOVE_LIBRARY.eos_225))
	for i in range(10):boon.tick_player_boons()
	assert(boon.hp>=82 and boon.hp<=83 and boon.boon_active("wish"))
	boon.clear_combat_effects()
	assert(boon.player_boons.is_empty())
	print("KINDRIA_BOON_CRITICAL_PASS")
	var climate=Rules.new()
	climate.player=Vector2i(1,1)
	climate.cells[climate.player]=true;climate.cells[Vector2i(2,1)]=true
	climate.equipped_moves=["eos_012","eos_223","eos_151"];climate.move_pp={"eos_012":12,"eos_223":12,"eos_151":9}
	assert(climate.cast_move("eos_012",Vector2i.UP))
	assert(climate.floor_weather=="rain" and climate.weather_factor("water")==1.5 and climate.weather_factor("fire")==.5)
	assert(climate.weather_ball_type()=="water" and climate.roll_reference_hit(Rules.MOVE_LIBRARY.eos_064))
	assert(climate.cast_move("eos_223",Vector2i.UP))
	assert(climate.weather_heal_amount()==80 and climate.weather_factor("fire")==1.5)
	climate.enemies.append({"pos":Vector2i(2,1),"hp":1000,"kind":0,"species":"reef_pup"})
	assert(climate.cast_move("eos_151",Vector2i.RIGHT))
	assert(climate.charged_move_id.is_empty() and climate.move_pp.eos_151==8)
	climate.floor_sports["water"]=10
	assert(climate.weather_factor("fire")==.75)
	climate.set_floor_weather("hail")
	assert(climate.roll_reference_hit(Rules.MOVE_LIBRARY.eos_270) and not climate.weather_hurts(["ice"]))
	var old_hp:int=climate.hp
	for i in range(10):climate.tick_floor_weather()
	assert(climate.hp==maxi(0,old_hp-3) and climate.floor_sports.is_empty())
	climate.clear_combat_effects()
	assert(climate.floor_weather=="clear" and climate.weather_heal_amount()==50)
	print("KINDRIA_WEATHER_PASS")
	var fixed=Rules.new()
	fixed.player=Vector2i(1,1)
	fixed.hp=20
	for x in range(1,5):fixed.cells[Vector2i(x,1)]=true
	fixed.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	var victim:Dictionary=fixed.enemies[0]
	assert(fixed.special_damage_amount(Rules.MOVE_LIBRARY.eos_341,victim)==30)
	assert(fixed.special_damage_amount(Rules.MOVE_LIBRARY.eos_152,victim)==20)
	assert(fixed.special_damage_amount(Rules.MOVE_LIBRARY.eos_020,victim)==50)
	assert(fixed.special_damage_amount(Rules.MOVE_LIBRARY.eos_066,victim)==80)
	assert(fixed.special_damage_amount(Rules.MOVE_LIBRARY.eos_177,victim)==100)
	assert(fixed.special_damage_amount(Rules.MOVE_LIBRARY.eos_177,{"hp":100,"kind":3})==0)
	assert(fixed.deal_special_damage(0,30)==30 and fixed.enemies[0].hp==70)
	fixed.enemies.append({"pos":Vector2i(4,1),"hp":40,"kind":0,"species":"reef_pup"})
	assert(fixed.push_enemy(0))
	assert(fixed.enemies[0].pos==Vector2i(3,1) and fixed.enemies[0].hp==65 and fixed.enemies[1].hp==35)
	assert(fixed.warp_player() and fixed.player==Vector2i(2,1))
	var fixed_cast=Rules.new()
	fixed_cast.player=Vector2i(1,1)
	fixed_cast.cells[fixed_cast.player]=true;fixed_cast.cells[Vector2i(2,1)]=true
	fixed_cast.equipped_moves=["eos_341"];fixed_cast.move_pp={"eos_341":8}
	fixed_cast.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	assert(fixed_cast.cast_move("eos_341",Vector2i.RIGHT))
	assert(fixed_cast.last_move_damage==[30] and fixed_cast.move_pp.eos_341==7 and fixed_cast.turns==1)
	print("KINDRIA_FIXED_DISPLACE_PASS")
	var advanced=Rules.new()
	advanced.player=Vector2i(1,1);advanced.hp=10;advanced.max_hp=100
	advanced.cells[advanced.player]=true;advanced.cells[Vector2i(2,1)]=true
	advanced.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	assert(advanced.apply_enemy_status(0,"stuck"))
	assert(int(advanced.enemies[0].stuck_turns)>=2)
	assert(advanced.apply_enemy_status(0,"leech"))
	advanced.tick_enemy_statuses()
	assert(advanced.hp==10)
	advanced.tick_enemy_statuses()
	assert(advanced.hp==20 and advanced.enemies[0].hp==90)
	assert(advanced.apply_enemy_status(0,"nightmare"))
	var nightmare_duration:int=advanced.enemies[0].nightmare_turns
	advanced.enemies[0].erase("leech_turns")
	for i in range(nightmare_duration):advanced.tick_enemy_statuses()
	assert(advanced.enemies[0].hp==82)
	assert(advanced.special_damage_amount(Rules.MOVE_LIBRARY.eos_394,advanced.enemies[0])==35)
	assert(Rules.reserve_multiplier(5,5)==1.0 and Rules.reserve_multiplier(3,5)==1.5 and Rules.reserve_multiplier(2,5)==2.0 and Rules.reserve_multiplier(1,5)==2.5)
	assert(advanced.apply_player_boon(Rules.MOVE_LIBRARY.eos_434))
	for i in range(4):advanced.tick_player_boons()
	assert(advanced.hp==28)
	assert(advanced.apply_player_boon(Rules.MOVE_LIBRARY.eos_098))
	assert(advanced.roll_reference_hit({"acc1":0,"acc2":0}))
	assert(advanced.apply_player_boon(Rules.MOVE_LIBRARY.eos_074))
	assert(not advanced.boon_active("sure"))
	print("KINDRIA_ADVANCED_STATUS_PASS")
	var hazard=Rules.new()
	hazard.player=Vector2i(1,1);hazard.stairs=Vector2i(9,9)
	hazard.rooms.append(Rect2i(0,0,5,5))
	for x in range(5):
		for y in range(5):hazard.cells[Vector2i(x,y)]=true
	assert(hazard.lay_player_trap("spikes") and not hazard.lay_player_trap("toxic"))
	hazard.player=Vector2i(0,1)
	hazard.enemies.append({"pos":Vector2i(1,1),"hp":100,"max_hp":100,"kind":0,"species":"reef_pup"})
	assert(hazard.activate_player_trap(0)==20 and hazard.enemies[0].hp==80)
	assert(hazard.player_traps.has(Vector2i(1,1)))
	hazard.player=Vector2i(2,2)
	assert(hazard.lay_player_trap("rock") and not hazard.revealed_player_traps.has(Vector2i(2,2)))
	hazard.player=Vector2i(0,1)
	hazard.enemies[0].pos=Vector2i(2,2)
	assert(hazard.activate_player_trap(0)==12 and hazard.revealed_player_traps.has(Vector2i(2,2)))
	assert(hazard.apply_enemy_status(0,"paused"))
	var duration:int=hazard.enemies[0].paused_turns
	assert(duration>=5 and duration<=12)
	assert(hazard.apply_enemy_status(0,"perish"))
	for i in range(4):hazard.tick_enemy_statuses()
	assert(hazard.enemies.is_empty())
	hazard.player=Vector2i(1,1);hazard.hp=36
	hazard.enemies.append({"pos":Vector2i(2,2),"hp":100,"kind":0,"species":"reef_pup"})
	assert(hazard.blast_move(Rules.MOVE_LIBRARY.eos_123))
	assert(hazard.hp==18 and hazard.enemies[0].hp==60)
	hazard.floor_weather="rain"
	assert(not hazard.blast_move(Rules.MOVE_LIBRARY.eos_155) and hazard.hp==18)
	print("KINDRIA_TRAP_BLAST_PASS")
	var exchange=Rules.new()
	exchange.player_stages={"attack":3,"defense":-2};exchange.player_halves={"attack":1}
	var target:Dictionary={"stages":{"attack":-1,"sp_attack":2,"defense":4},"stat_halves":{"defense":2}}
	assert(exchange.transfer_stats("power",target))
	assert(exchange.player_stages.attack==-1 and target.stages.attack==3 and target.stat_halves.attack==1)
	assert(exchange.transfer_stats("guard",target))
	assert(exchange.player_stages.defense==4 and exchange.player_halves.defense==2)
	assert(exchange.transfer_stats("invert"))
	assert(exchange.player_stages.attack==4 and exchange.player_stages.defense==-1)
	assert(exchange.transfer_stats("copy",target))
	assert(exchange.player_stages.attack==target.stages.attack)
	exchange.player_stages.attack=0
	assert(target.stages.attack==3)
	assert(exchange.transfer_stats("charge") and exchange.charge_power_turns==2)
	exchange.enemy_turn()
	assert(exchange.charge_power_turns==1)
	exchange.enemy_turn()
	assert(exchange.charge_power_turns==0)
	var invoke=Rules.new()
	invoke.player=Vector2i(1,1)
	invoke.cells[invoke.player]=true;invoke.cells[Vector2i(2,1)]=true
	invoke.enemies.append({"pos":Vector2i(2,1),"hp":1000,"kind":0,"species":"reef_pup"})
	invoke.equipped_moves=["eos_330"];invoke.move_pp={"eos_330":22}
	assert(not invoke.invocation_candidates(Vector2i.RIGHT).is_empty())
	assert(invoke.cast_move("eos_330",Vector2i.RIGHT))
	assert(invoke.move_pp.eos_330==21 and invoke.move_pp.size()==1 and invoke.turns==1)
	print("KINDRIA_TRANSFER_PASS")
	var reserve=Rules.new()
	reserve.max_hp=100;reserve.hp=10
	assert(reserve.store_vitality() and reserve.store_vitality() and reserve.store_vitality())
	assert(not reserve.store_vitality())
	assert(reserve.stockpile_count==3 and reserve.player_stages.defense==3 and reserve.player_stages.sp_defense==3)
	assert(reserve.consume_vitality()==80 and reserve.hp==90 and reserve.stockpile_count==0)
	assert(reserve.player_stages.defense==3 and reserve.player_stages.sp_defense==3)
	assert(reserve.store_vitality())
	reserve.player=Vector2i(1,1)
	reserve.cells[reserve.player]=true;reserve.cells[Vector2i(2,1)]=true
	reserve.enemies.append({"pos":Vector2i(2,1),"hp":1000,"kind":0,"species":"reef_pup"})
	reserve.equipped_moves=["eos_245"];reserve.move_pp={"eos_245":12}
	assert(reserve.cast_move("eos_245",Vector2i.RIGHT))
	assert(reserve.stockpile_count==0 and reserve.move_pp.eos_245==11)
	var values:Array=[5,10,15,25,30,35,40]
	for i in range(50):assert(reserve.choose_magnitude() in values)
	reserve.trained_profile={"types":["flying","fire"]}
	reserve.roost_active=true
	assert(reserve.current_player_types()==["fire"])
	assert(reserve.trained_profile.types==["flying","fire"])
	reserve.clear_combat_effects()
	assert(not reserve.roost_active and reserve.stockpile_count==0)
	print("KINDRIA_RESERVE_AREA_PASS")
	var rest=Rules.new()
	rest.max_hp=100;rest.hp=12;rest.poison_turns=5;rest.self_confusion_turns=5
	assert(rest.apply_player_boon(Rules.MOVE_LIBRARY.eos_232))
	var nap_duration:int=rest.player_boons.nap
	assert(nap_duration>=2 and nap_duration<=3)
	for i in range(nap_duration-1):rest.tick_player_boons()
	assert(rest.hp==12 and rest.boon_active("nap"))
	rest.tick_player_boons()
	assert(rest.hp==100 and rest.poison_turns==0 and rest.self_confusion_turns==0 and not rest.boon_active("nap"))
	rest.hp=20
	assert(rest.apply_player_boon(Rules.MOVE_LIBRARY.eos_233))
	for i in range(7):rest.tick_player_boons()
	assert(rest.hp==40)
	rest.player=Vector2i(1,1)
	rest.cells[rest.player]=true;rest.cells[Vector2i(2,1)]=true
	rest.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup","guard":10})
	assert(rest.apply_player_boon(Rules.MOVE_LIBRARY.eos_317))
	rest.strike(0,true,-1,"eos_262")
	assert(rest.enemies[0].hp==70 and rest.enemies[0].guard==10)
	assert(rest.apply_player_boon(Rules.MOVE_LIBRARY.eos_074) and not rest.boon_active("set_damage"))
	assert(rest.apply_enemy_status(0,"sleep"))
	assert(rest.apply_enemy_status(0,"sleepless"))
	assert(not rest.apply_enemy_status(0,"sleep"))
	assert(not rest.enemies[0].has("sleep_turns"))
	assert(rest.apply_player_boon(Rules.MOVE_LIBRARY.eos_112))
	assert(not rest.apply_player_boon(Rules.MOVE_LIBRARY.eos_232))
	var wild=Rules.new()
	wild.player=Vector2i(1,1);wild.equipped_moves=["eos_009"];wild.move_pp={"eos_009":12}
	assert(wild.cast_move("eos_009",Vector2i.RIGHT))
	assert(wild.last_move_attempts==3 and wild.move_pp.eos_009==11 and wild.self_confusion_turns>=6)
	print("KINDRIA_RAMPAGE_SLEEP_PASS")
	var field=Rules.new()
	field.player=Vector2i(1,1);field.hp=36
	field.cells[field.player]=true;field.cells[Vector2i(2,1)]=true;field.cells[Vector2i(5,1)]=true
	field.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup","guard":5})
	field.poison_turns=4;field.self_confusion_turns=5
	assert(field.shift_conditions(0))
	assert(field.poison_turns==0 and field.self_confusion_turns==0 and field.enemies[0].major_status=="poison")
	assert(field.present_outcome(20)==-1 and field.present_outcome(21)==25 and field.present_outcome(61)==50 and field.present_outcome(91)==75)
	field.clear_enemy_wards(field.enemies[0])
	assert(not field.enemies[0].has("guard"))
	assert(field.apply_player_boon(Rules.MOVE_LIBRARY.eos_493))
	assert(field.activate_gravity() and not field.boon_active("magnet"))
	assert(field.gravity_blocks(Rules.MOVE_LIBRARY.eos_153) and field.gravity_blocks(Rules.MOVE_LIBRARY.eos_493))
	assert(not field.apply_player_boon(Rules.MOVE_LIBRARY.eos_493))
	field.rooms.append(Rect2i(0,0,3,3))
	field.equipped_moves=["eos_043"];field.move_pp={"eos_043":15}
	assert(field.cast_move("eos_043",Vector2i.RIGHT))
	assert(field.player==Vector2i(5,1) and field.hp==1 and field.move_pp.eos_043==14)
	assert(field.enemies[0].stat_halves.attack==2 and field.enemies[0].stat_halves.sp_attack==2)
	field.clear_combat_effects()
	assert(not field.gravity_active)
	print("KINDRIA_FIELD_SACRIFICE_PASS")
	var reactive=Rules.new()
	reactive.player=Vector2i(1,1)
	reactive.cells[reactive.player]=true;reactive.cells[Vector2i(2,1)]=true;reactive.cells[Vector2i(3,1)]=true
	reactive.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	assert(reactive.apply_player_boon(Rules.MOVE_LIBRARY.eos_061))
	reactive.bide_aim=Vector2i.RIGHT;reactive.bide_move_id="eos_061"
	reactive.record_reactive_hit(Vector2i(2,1),7)
	reactive.record_reactive_hit(Vector2i(2,1),3)
	assert(reactive.bide_damage==10)
	for i in range(4):reactive.tick_player_boons()
	assert(reactive.enemies[0].hp==80 and not reactive.boon_active("bide") and reactive.bide_damage==0)
	assert(reactive.apply_player_boon(Rules.MOVE_LIBRARY.eos_019))
	reactive.record_reactive_hit(Vector2i(2,1),4)
	assert(reactive.player_stages.attack==1)
	assert(reactive.apply_enemy_status(0,"exposed"))
	assert(reactive.reveal_defender_types("fighting",["ghost","rock"],reactive.enemies[0])==["rock"])
	assert(reactive.apply_enemy_status(0,"miracle_eye"))
	assert(reactive.reveal_defender_types("psychic",["dark"],reactive.enemies[0]).is_empty())
	assert(reactive.apply_player_boon(Rules.MOVE_LIBRARY.eos_007))
	reactive.record_reactive_hit(Vector2i(2,1),4);reactive.flush_throws()
	assert(reactive.enemies[0].pos==Vector2i(3,1))
	reactive.clear_combat_effects()
	assert(reactive.bide_damage==0 and reactive.pending_throws.is_empty())
	print("KINDRIA_REACTIVE_PASS")
	var adaptive=Rules.new()
	adaptive.trained_profile={"types":["grass","poison"]}
	adaptive.equipped_moves=["eos_064"]
	assert(adaptive.convert_element() and adaptive.current_player_types()==["electric"])
	assert(adaptive.trained_profile.types==["grass","poison"])
	assert(adaptive.apply_player_boon(Rules.MOVE_LIBRARY.eos_184))
	assert(adaptive.adapt_after_hit("fire"))
	assert(Rules.type_multiplier("fire",adaptive.current_player_types())<1.0)
	for i in range(11):adaptive.tick_player_boons()
	assert(adaptive.adaptive_type.is_empty() and adaptive.current_player_types()==["electric"])
	adaptive.initialize_hidden_power(42)
	var hidden_type:String=adaptive.hidden_element
	var hidden_power:int=adaptive.hidden_base_power
	adaptive.initialize_hidden_power(42)
	assert(adaptive.hidden_element==hidden_type and adaptive.hidden_base_power==hidden_power)
	assert(hidden_power>=2 and hidden_power<=15)
	adaptive.enemies.append({"pos":Vector2i(2,1),"hp":40,"max_hp":100,"kind":0,"species":"reef_pup"})
	assert(adaptive.apply_enemy_status(0,"heal_block"))
	assert(adaptive.heal_enemy(adaptive.enemies[0],20)==0)
	assert(adaptive.apply_enemy_status(0,"curse"))
	adaptive.tick_enemy_statuses();adaptive.tick_enemy_statuses()
	assert(adaptive.enemies[0].hp==15)
	adaptive.clear_combat_effects()
	assert(adaptive.current_player_types()==["grass","poison"])
	print("KINDRIA_ADAPTIVE_PASS")
	var binding=Rules.new()
	binding.player=Vector2i(1,1);binding.hp=36
	binding.cells[binding.player]=true;binding.cells[Vector2i(2,1)]=true
	binding.enemies.append({"pos":Vector2i(2,1),"hp":100,"kind":0,"species":"reef_pup"})
	assert(binding.bind_enemy(0) and binding.boon_active("wrapping"))
	binding.tick_enemy_statuses()
	assert(binding.enemies[0].hp==94)
	binding.clear_combat_effects()
	assert(binding.splash_step(Vector2i.RIGHT))
	assert(binding.player==Vector2i(1,1) and binding.hp==31 and binding.enemies[0].hp==89)
	binding.equipped_moves=["eos_025","eos_227"];binding.move_pp={"eos_025":16,"eos_227":17}
	assert(binding.apply_player_boon(Rules.MOVE_LIBRARY.eos_232))
	binding.record_reactive_hit(Vector2i(2,1),3)
	binding.flush_sleep_reactions()
	assert(binding.move_pp.eos_025==15 and binding.move_pp.eos_227==17 and binding.turns==0)
	assert(binding.sleep_reactions.is_empty())
	print("KINDRIA_SLEEP_BINDING_PASS")
	assert(Rules.EOS_IDENTIFIED_COUNT==468)
	print("KINDRIA_EOS_PROTOTYPES_PASS ",eos_count)
	print("KINDRIA_LEARNSET_PP_PASS")
	print("KINDRIA_TRAINING_PASS 18 types 26 natures 33 EV yields")
	quit()
