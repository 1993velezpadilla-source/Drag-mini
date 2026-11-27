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
	for id in ids:
		var f=fixture(4100)
		var m:Dictionary=Rules.dev_move_record(id)
		var before:int=f.attack_serial
		var used:bool=f.dev_cast_move(id,Vector2i.RIGHT)
		if not f.charged_move_id.is_empty():used=f.dev_cast_move(id,Vector2i.RIGHT) or used
		var damage:int=0
		for value in f.last_move_damage:damage+=int(value)
		if used:accepted+=1
		else:blocked+=1
		var initial_outcome:String=f.dev_cast_outcome
		var retry_attempts:int=0
		var best_damage:int=damage
		if int(m.power)>0 and damage==0:
			for seed_value in [4101,4102,4103,4104,4105,4106,4107]:
				var trial=fixture(seed_value)
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
	assert(report.size()==589 and native_damage==67 and reactive==2)
	print("KINDRA_REACTIVE_FIXTURES_PASS ",reactive," zero-damage-retries-resolved=",retry_damage)
	print("KINDRA_DEV_EXECUTION_AUDIT_PASS ",report.size()," native=",native_damage," accepted=",accepted," blocked=",blocked," parity=unverified")
	quit()
