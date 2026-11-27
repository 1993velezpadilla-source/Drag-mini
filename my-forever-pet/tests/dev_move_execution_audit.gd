extends SceneTree
const Rules=preload("res://dungeon_rules.gd")
func _initialize():call_deferred("run")
func fixture(seed_value:int)->RefCounted:
	var f=Rules.new();f.setup(0,1,0,false,false,seed_value)
	f.enable_dev_sandbox();f.cells.clear();f.rooms.clear();f.rooms.append(Rect2i(1,1,15,15))
	f.player=Vector2i(5,5)
	for y in range(1,16):
		for x in range(1,16):f.cells[Vector2i(x,y)]=true
	f.enemies.clear();f.loot.clear();f.traps.clear()
	var e:Dictionary=f.make_enemy(f.player+Vector2i.RIGHT,500,0,400)
	f.enemies.append(e);f.hp=maxi(1,f.max_hp/2)
	f.rng.seed=seed_value
	return f
func run():
	var ids:Array=Rules.MOVE_LIBRARY.keys()+Rules.DEV_NATIVE_MOVES.keys()
	var report:Array=[]
	var native_damage:int=0
	var accepted:int=0
	var blocked:int=0
	var retry_damage:int=0
	var reactive:int=0
	var conditional_damage:int=0
	var info_count:int=0
	var outcome_rows:int=0
	var outcome_moves:int=0
	for id in ids:
		var f=fixture(4100)
		var m:Dictionary=Rules.dev_move_record(id)
		for key in ["what_it_does","target_rule","condition_text"]:assert(not str(m.get(key,"")).strip_edges().is_empty(),str(id)+" missing "+key)
		assert(not "individual rule review required" in str(m.what_it_does),str(id)+" unspecified effect")
		info_count+=1
		if id=="eos_245":f.stockpile_count=3
		var before:int=f.attack_serial
		var used:bool=f.dev_cast_move(id,Vector2i.RIGHT)
		if not f.charged_move_id.is_empty():used=f.dev_cast_move(id,Vector2i.RIGHT) or used
		if id=="eos_535":
			# Real reactive damage accumulation and timed release, not ordinary damage.
			f.record_reactive_hit(f.player+Vector2i.RIGHT,5)
			while f.boon_active("bide"):f.tick_player_boons()
		var damage:int=0
		for value in f.last_move_damage:damage+=int(value)
		if used:accepted+=1
		else:blocked+=1
		var initial_outcome:String=f.dev_cast_outcome
		if f.player_cast_result_serial==f.attack_serial and not f.player_cast_results.is_empty():
			outcome_moves+=1
			for row in f.player_cast_results.values():
				assert(int(row.damage)>=0 and int(row.hits)+int(row.misses)+int(row.effects)+int(row.blocked)+int(row.get("heal",0))>0)
				outcome_rows+=1
		var retry_attempts:int=0
		var best_damage:int=damage
		if id in ["eos_245","eos_535"] and damage>0:conditional_damage+=1
		if int(m.power)>0 and damage==0:
			for seed_value in [4101,4102,4103,4104,4105,4106,4107]:
				var trial=fixture(seed_value)
				if id=="eos_245":trial.stockpile_count=3
				trial.dev_cast_move(id,Vector2i.RIGHT)
				if not trial.charged_move_id.is_empty():trial.dev_cast_move(id,Vector2i.RIGHT)
				retry_attempts+=1
				var total:int=0
				for value in trial.last_move_damage:total+=int(value)
				best_damage=maxi(best_damage,total)
				if best_damage>0:retry_damage+=1;break
		if m.get("sleep_reactive",false):
			assert(used and "sleep + incoming hit fixture" in initial_outcome)
			reactive+=1
		if m.get("native",false):
			assert(used and f.attack_serial>before and not f.last_move_damage.is_empty(),str(id)+" native damage dispatch")
			native_damage+=1
		report.append({"id":id,"name":m.name,"source":"kindra" if not m.has("reference_id") else "eos","category":m.category,"power":m.power,"pp":m.pp,"acc1":m.acc1,"acc2":m.acc2,"range":m.pattern,"reach":m.reach,"attempted":true,"accepted":used,"damage":damage,"hits":f.last_move_hits,"attempts":f.last_move_attempts,"attack_serial_delta":f.attack_serial-before,"outcome":initial_outcome,"enemy_turn_message":f.message,"retry_attempts":retry_attempts,"best_damage":best_damage,"parity":"unverified"})
	var out:=FileAccess.open("/tmp/dev-move-audit.json",FileAccess.WRITE)
	assert(out!=null);out.store_string(JSON.stringify(report,"  "));out.close()
	assert(report.size()==589 and native_damage==67 and reactive==2 and info_count==589)
	assert(outcome_moves==589,"every fixture must yield a serial-matched result")
	print("KINDRA_CAST_OUTCOME_ROWS ",outcome_rows," moves=",outcome_moves)
	print("KINDRA_MOVE_INFO_PASS ",info_count," conditional damage first attempt=",conditional_damage)
	print("KINDRA_REACTIVE_FIXTURES_PASS ",reactive," zero-damage-retries-resolved=",retry_damage)
	print("KINDRA_DEV_EXECUTION_AUDIT_PASS ",report.size()," native=",native_damage," accepted=",accepted," blocked=",blocked," parity=unverified")
	quit()
