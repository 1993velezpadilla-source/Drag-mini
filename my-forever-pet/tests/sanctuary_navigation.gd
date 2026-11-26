extends SceneTree
const Field=preload("res://sanctuary_field.gd")
func _initialize():
	call_deferred("run")
func run():
	var checks=0
	for r in range(3):
		for tier in range(3):
			var field=Field.new()
			root.add_child(field)
			field.size=Vector2(440,400)
			field.setup(r,tier,0,null)
			field.set_process(false)
			field.recovered.connect(func(index:int):
				field.mask|=1<<index;field.locked=false)
			for i in range(3):
				assert(field.can_move(field.points[i]),"relic obstructed")
				field.move_to(field.points[i])
				assert(not field.path.is_empty(),"missing path")
				for j in range(360):
					field._process(1.0/60)
					assert(field.can_move(field.pos),"collision")
					if (field.mask&(1<<i))!=0:break
				assert((field.mask&(1<<i))!=0,"unreachable relic")
				checks+=1
			assert(field.mask==7)
			assert(field.companion!=null and field.companion.get_width()==48)
			field.free()
	print("FOREVER_SANCTUARY_NAV_PASS ",checks)
	quit()
