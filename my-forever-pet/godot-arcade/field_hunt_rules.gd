extends RefCounted
# A deterministic active field session. Positions are world X/Z coordinates.
var region:int
var specimen:int
var step:int
var encounter:bool
var patrol:bool
var player=Vector2(0,6.5)
var destination=Vector2(0,6.5)
var trail:Array[Vector2]=[]
var index=0
var time_left=0.0
var elapsed=0.0
var started=false
var finished=false
var success=false
var hold=0.0
var hit_cooldown=0.0
var hits=0
var required=0
var hazard_positions:Array[Vector2]=[]
var seed_value:int
var inspecting=false
var scans=3
var scan_left=0.0
var capture_time=.65
var capture_radius=.85
var burst_left=0.0
var burst_cooldown=0.0
var burst_target=Vector2.ZERO
var environmental_force=Vector2.ZERO
var gust_phase=0.0
var tier=0
var reveal_radius=2.6
var alert_period=5.0
var alert_duration=1.0
var route_pattern=0
var hazard_phase=0.0
func setup(r:int,id:int,n:int,finale:bool,is_patrol:bool,seed_id:int):
	region=r;specimen=id;step=n;encounter=finale;patrol=is_patrol;seed_value=seed_id
	var rng=RandomNumberGenerator.new();rng.seed=seed_id
	tier=0 if is_patrol else 0 if id<12 else 1 if id<24 else 2
	reveal_radius=[2.6,1.9,1.45][tier]
	alert_period=[5.5,5.0,4.6][tier]
	alert_duration=[.85,1.0,1.15][tier]
	required=3 if is_patrol else 4 if finale else 3 if id<12 else 4 if id<24 else 5
	time_left=44.0 if finale else 29.0+required*3
	capture_time=(1.25+float(tier)*.15) if finale else [.65,.85,1.0][tier]
	capture_radius=1.6 if finale else [.85,.75,.7][tier]
	scans=[3,2,1][tier]
	# As research advances, vary hazard routes without changing the reward rules.
	route_pattern=posmod(step,3) if not patrol else 0
	hazard_phase=float(posmod(seed_id,17))*.12 if route_pattern!=0 else 0.0
	for i in range(required):
		var p=Vector2(rng.randf_range(-7.0,7.0),rng.randf_range(-6.5,5.0))
		for attempt in range(20):
			if p.distance_to(player if i==0 else trail[-1])>4.0:break
			p=Vector2(rng.randf_range(-7.0,7.0),rng.randf_range(-6.5,5.0))
		trail.append(p)
func move_to(p:Vector2):
	if finished:return
	destination=p.clamp(Vector2(-7.8,-7.4),Vector2(7.8,7.4))
	started=true
func signal_position()->Vector2:
	if finished or index>=trail.size():return player
	var p=trail[index]
	if encounter:p+=Vector2(sin(elapsed*(1.8+tier*.15)+index)*1.1,cos(elapsed*1.4+index)*.9)
	return p.clamp(Vector2(-7.7,-7.3),Vector2(7.7,7.3))
func burst()->bool:
	if finished or burst_cooldown>0:return false
	var v=destination-player
	if v.length()<.3:return false
	burst_target=player+v.limit_length(11.5*.42);burst_left=.42;burst_cooldown=4.0;started=true;set_inspecting(false);return true
func current_at(p:Vector2)->Vector2:
	if region==1:
		return Vector2(sin(p.y*.55+elapsed*.8),cos(p.x*.46-elapsed*.65))*.72
	if region==2:
		var strength=maxf(0.0,sin(elapsed*1.1))
		return Vector2(cos(p.y*.2),sin(p.x*.2))*strength*1.25
	return Vector2.ZERO
func scan()->bool:
	if finished or scans<=0 or scan_left>0:return false
	scans-=1;scan_left=2.6;started=true;return true
func signal_strength()->float:
	return clampf(1.0-player.distance_to(signal_position())/18.0,0.0,1.0)
func alert_left()->float:
	if not encounter or not started:return 0.0
	var phase=fposmod(elapsed+float(index)*.7,alert_period)
	return maxf(0.0,alert_duration-phase)
func inspect_ready()->bool:
	return not finished and alert_left()<=0.0 and player.distance_to(signal_position())<=capture_radius and hit_cooldown<=0.0 and burst_left<=0.0
func trace_visible()->bool:
	return not encounter and (player.distance_to(signal_position())<reveal_radius or scan_left>0.0)
func set_inspecting(value:bool):
	inspecting=value
	if not value:hold=0.0
func hazard_at(i:int)->Vector2:
	var offset=float(i)*2.3+hazard_phase
	var phase=elapsed*(1.0+float(route_pattern)*.09)
	match region:
		0:return Vector2(sin(phase*(.72+i*.14)+offset)*6.1,sin(phase*.43+offset)*5.8)
		1:return Vector2(cos(phase*(.48+i*.12)+offset)*5.7,sin(phase*(.48+i*.12)+offset)*5.7)
		_:return Vector2(sin(phase*(1.05+i*.10)+offset)*6.7,cos(phase*.57+offset)*5.8)
func tick(delta:float):
	if finished or not started:return
	if delta<=0.0:return
	# Do not award a capture after the deadline, even after a stalled frame.
	if delta>=time_left:
		elapsed+=time_left;time_left=0.0;finished=true;success=false;return
	# Limit simulation catch-up, but never give the player extra clock time.
	var remaining=minf(delta,.25)
	var skipped=delta-remaining
	elapsed+=skipped;time_left-=skipped
	while remaining>0.000001 and not finished:
		var dt=minf(remaining,.05)
		_tick_step(dt)
		remaining-=dt
func _tick_step(dt:float):
	elapsed+=dt;time_left-=dt;hit_cooldown=maxf(0,hit_cooldown-dt);scan_left=maxf(0,scan_left-dt)
	burst_cooldown=maxf(0,burst_cooldown-dt)
	environmental_force=current_at(player)
	var was_bursting=burst_left>0.0
	if was_bursting:
		var burst_dt=minf(dt,burst_left)
		burst_left=maxf(0,burst_left-dt)
		player=player.move_toward(burst_target,burst_dt*11.5)
	else:
		player=player.move_toward(destination,dt*[5.5,5.3,6.0][region])
		# Holding still to inspect stabilizes the pet against currents.
		if not (inspecting and inspect_ready()):player+=environmental_force*dt
	player=player.clamp(Vector2(-7.8,-7.4),Vector2(7.8,7.4))
	hazard_positions.clear()
	for i in range(2 if specimen<12 else 3):
		var p=hazard_at(i);hazard_positions.append(p)
		if player.distance_to(p)<.83 and hit_cooldown<=0 and not was_bursting:
			hit_cooldown=1.3;hits+=1;time_left-=3;hold=0
	if time_left<=0:
		finished=true;success=false;return
	if inspecting and not was_bursting and inspect_ready():hold+=dt
	else:hold=maxf(0,hold-dt*2.5)
	if hold>=capture_time:
		index+=1;hold=0;inspecting=false
		if index>=required:
			finished=true;success=true;return
	if time_left<=0:finished=true;success=false
func scan_vector()->Vector2:
	if scan_left<=0.0 or finished:return Vector2.ZERO
	return (signal_position()-player).normalized()
func direction()->String:
	var v=signal_position()-player
	if v.length()<1.5:return "VERY CLOSE"
	if absf(v.x)>absf(v.y)*1.35:return "EAST" if v.x>0 else "WEST"
	if absf(v.y)>absf(v.x)*1.35:return "SOUTH" if v.y>0 else "NORTH"
	return ("SOUTH" if v.y>0 else "NORTH")+(" EAST" if v.x>0 else " WEST")
