extends SceneTree
const Trial=preload("res://research_trial.gd")
const Data=preload("res://research_data.gd")
func _initialize():
	call_deferred("run")
func run():
	var checks=0
	for r in range(3):
		for specimen in [1,12,26]:
			var trial=Trial.new()
			root.add_child(trial)
			trial.setup(r,specimen,1)
			trial.set_process(false)
			var results:Array=[]
			trial.resolved.connect(func(answer:Array,phase:float):results.append([answer.duplicate(),phase]))
			if r==1:
				trial.finish([],0.5)
			else:
				if r==0:
					trial._process(2.1)
					assert(trial.sequence_ready)
				for k in Data.trial_sequence(r,specimen,1):trial.press_symbol(k)
			assert(results.size()==1,"trial must emit exactly one result")
			assert(Data.trial_success(r,specimen,1,results[0][0],results[0][1]),"valid trial should succeed")
			trial.finish([],0.5)
			assert(results.size()==1,"double completion must not emit")
			checks+=1
			trial.free()
	print("FOREVER_RESEARCH_TRIAL_PASS ",checks)
	quit()
