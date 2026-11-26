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
						field.move_to(field.signal_position());field.tick(1.0/60)
						if field.finished:break
					assert(field.finished and field.success,"field not completable")
					assert(field.index==field.required)
					assert(field.elapsed>=2.0)
					count+=1
	var expired=Rules.new();expired.setup(0,1,0,false,false,99);expired.move_to(expired.player)
	for i in range(500):expired.tick(.1)
	assert(expired.finished and not expired.success)
	print("FOREVER_WILD_FIELD_PASS ",count)
	quit()
