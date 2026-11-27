extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not ClassDB.class_exists("EffekseerEmitter3D"):
		push_error("Native emitter missing")
		quit(1)
		return
	var scene := Node3D.new()
	root.add_child(scene)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0, 4, 9)
	camera.look_at(Vector3(0, 1, 0))
	camera.current = true
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#161b28")
	scene.add_child(env)
	var emitter = ClassDB.instantiate("EffekseerEmitter3D")
	scene.add_child(emitter)
	emitter.position = Vector3(0, 0.8, 0)
	var paths := ["sample-material3/ef_fire01.efkefc","sample-material3/ef_ice01.efkefc","sample-material3/ef_lightning01.efkefc","sample-material3/ef_wind01.efkefc","sample-material2/ToonWater.efkefc"]
	for path in paths:
		var effect = load("res://effects/"+path)
		if effect == null:
			push_error("Import failed: "+path)
			quit(1)
			return
		emitter.effect = effect
		emitter.play()
		var largest := 0
		for i in range(60):
			await process_frame
			await RenderingServer.frame_post_draw
			if i in [10,20,30,45,59]:
				var im := root.get_texture().get_image()
				var count := 0
				for y in range(0,im.get_height(),3):
					for x in range(0,im.get_width(),3):
						var c := im.get_pixel(x,y)
						if maxf(c.r,maxf(c.g,c.b)) > 0.32:
							count += 1
				if count > largest:
					largest = count
					im.save_png("/tmp/effekseer-review/"+path.get_file().get_basename()+".png")
		emitter.stop()
		if largest < 10:
			push_error("No visible effect: "+path)
			quit(1)
			return
		print("EFFEKSEER_VISIBLE ",path," pixels=",largest)
	print("EFFEKSEER_GL_PROBE_PASS 5")
	quit(0)
