extends SceneTree
const Rules=preload("res://field_hunt_rules.gd")
func _initialize():call_deferred("run")
func run():
	var count=0
	for region in range(3):
		for id in [1,14,24]:
			for finale in [false,true]:
				for seed_id in [123,999,8731]:
					var field=Rules.new();field.setup(region,id,0,finale,false,seed_id)
					field.tick(.1);assert(not field.started and field.elapsed==0)
					for frame in range(3000):
						field.move_to(field.signal_position());field.set_inspecting(true);field.tick(1.0/60)
						if field.finished:break
					assert(field.finished and field.success,"field not completable")
					assert(field.index==field.required)
					assert(field.elapsed>=2.0)
					count+=1
	var passive=Rules.new();passive.setup(0,1,0,false,false,123)
	for i in range(150):passive.move_to(passive.signal_position());passive.tick(.016)
	assert(passive.index==0,"walking alone must not collect a trace")
	assert(passive.scan() and not passive.scan(),"scan cannot spam")
	for i in range(30):passive.tick(.1)
	assert(passive.scan_left==0 and passive.scans==2,"scan expires and costs a charge")
	var land=Rules.new();land.setup(0,1,0,false,false,123)
	land.move_to(Vector2(0,-4));assert(land.burst() and not land.burst(),"burst cooldown")
	var start=land.player
	land.tick(.1);assert(land.player.distance_to(start)>1.0,"dash accelerates movement")
	assert(not land.inspect_ready(),"cannot inspect while dashing")
	for i in range(40):land.tick(.1)
	assert(land.burst_cooldown<.001,"burst recharges")
	assert(land.current_at(Vector2.ZERO)==Vector2.ZERO,"land has no drift")
	var water=Rules.new();water.setup(1,1,0,false,false,123)
	assert(water.current_at(Vector2.ZERO).length()>.5,"water current")
	var sky=Rules.new();sky.setup(2,1,0,false,false,123);sky.elapsed=1.2
	assert(sky.current_at(Vector2.ZERO).length()>1.0,"sky gust")
	var timeout_edge=Rules.new();timeout_edge.setup(0,1,0,false,false,321)
	timeout_edge.player=timeout_edge.signal_position();timeout_edge.move_to(timeout_edge.player)
	timeout_edge.index=timeout_edge.required-1;timeout_edge.player=timeout_edge.signal_position();timeout_edge.destination=timeout_edge.player
	timeout_edge.set_inspecting(true);timeout_edge.hold=timeout_edge.capture_time-.01;timeout_edge.time_left=.01
	timeout_edge.tick(.02);assert(timeout_edge.finished and not timeout_edge.success,"timeout wins over late collection")
	var stall=Rules.new();stall.setup(0,1,0,false,false,123);stall.move_to(stall.player)
	var initial_clock=stall.time_left
	stall.tick(1.0)
	assert(absf(stall.time_left-(initial_clock-1.0))<.001,"stalled frame must not extend deadline")
	stall.time_left=.2;stall.tick(.5)
	assert(stall.finished and not stall.success and stall.time_left==0.0,"stall past deadline loses")
	var short_dash=Rules.new();short_dash.setup(0,1,0,false,false,123)
	var target=short_dash.player+Vector2(.75,0)
	short_dash.move_to(target);assert(short_dash.burst())
	for i in range(9):short_dash.tick(.05)
	assert(short_dash.player.distance_to(target)<.01,"dash must not overshoot a nearby target")
	var expired=Rules.new();expired.setup(0,1,0,false,false,99);expired.move_to(expired.player)
	for i in range(500):expired.tick(.1)
	assert(expired.finished and not expired.success)
	print("FOREVER_WILD_FIELD_PASS ",count)
	quit()
