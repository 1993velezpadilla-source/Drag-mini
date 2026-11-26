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
func setup(r:int,id:int,n:int,finale:bool,is_patrol:bool,seed_id:int):
	region=r;specimen=id;step=n;encounter=finale;patrol=is_patrol;seed_value=seed_id
	var rng=RandomNumberGenerator.new();rng.seed=seed_id
	required=3 if is_patrol else 4 if finale else 3 if id<12 else 4 if id<24 else 5
	time_left=44.0 if finale else 29.0+required*3
	capture_time=1.5 if finale else .65 if id<12 else .85
	capture_radius=1.6 if finale else .85
	scans=3 if id<12 else 2
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
	if encounter:p+=Vector2(sin(elapsed*1.8+index)*1.1,cos(elapsed*1.4+index)*.9)
	return p.clamp(Vector2(-7.7,-7.3),Vector2(7.7,7.3))
func scan()->bool:
	if finished or scans<=0 or scan_left>0:return false
	scans-=1;scan_left=2.6;started=true;return true
func signal_strength()->float:
	return clampf(1.0-player.distance_to(signal_position())/11.0,0.0,1.0)
func inspect_ready()->bool:
	return not finished and player.distance_to(signal_position())<=capture_radius and hit_cooldown<=0.0
func set_inspecting(value:bool):
	inspecting=value
	if not value:hold=0.0
func hazard_at(i:int)->Vector2:
	return Vector2(sin(elapsed*(.68+i*.11)+float(i)*2.3)*6.1,cos(elapsed*(.49+i*.13)+float(i)*1.7)*5.8)
func tick(delta:float):
	if finished or not started:return
	var dt=clampf(delta,0,.10)
	elapsed+=dt;time_left-=dt;hit_cooldown=maxf(0,hit_cooldown-dt);scan_left=maxf(0,scan_left-dt)
	player=player.move_toward(destination,dt*[5.5,5.0,6.0][region])
	hazard_positions.clear()
	for i in range(2 if specimen<12 else 3):
		var p=hazard_at(i);hazard_positions.append(p)
		if player.distance_to(p)<.83 and hit_cooldown<=0:
			hit_cooldown=1.3;hits+=1;time_left-=3;hold=0
	if inspecting and inspect_ready():hold+=dt
	else:hold=maxf(0,hold-dt*2.5)
	if hold>=capture_time:
		index+=1;hold=0;inspecting=false
		if index>=required:
			finished=true;success=true;return
	if time_left<=0:finished=true;success=false
func direction()->String:
	var v=signal_position()-player
	if v.length()<1.5:return "VERY CLOSE"
	if absf(v.x)>absf(v.y)*1.35:return "EAST" if v.x>0 else "WEST"
	if absf(v.y)>absf(v.x)*1.35:return "SOUTH" if v.y>0 else "NORTH"
	return ("SOUTH" if v.y>0 else "NORTH")+(" EAST" if v.x>0 else " WEST")
