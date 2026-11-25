extends SceneTree
const VIEWS = ["front","rear","side","front34","rear34","underside"]
func _initialize() -> void:
	call_deferred("review")
func review() -> void:
	var scene:=Node3D.new()
	root.add_child(scene)
	var packed:=load("res://mosskit-mobile.glb") as PackedScene
	assert(packed!=null)
	var model:=packed.instantiate() as Node3D
	scene.add_child(model)
	var meshes:=model.find_children("*","MeshInstance3D",true,false)
	assert(meshes.size()>=20)
	var foot_l:=model.find_child("foot_L",true,false) as Node3D
	var foot_r:=model.find_child("foot_R",true,false) as Node3D
	assert(foot_l!=null and foot_r!=null)
	var pad:=foot_l.find_child("paw_main_L",true,false) as Node3D
	assert(pad!=null)
	for foot in [foot_l,foot_r]:
		for child in foot.get_children():
			if str(child.name).begins_with("paw_"):
				assert(child.position.y < -0.13 and absf(child.position.z)<0.20,"pad belongs on sole")
	var before:=pad.global_position
	var right_before:=foot_r.global_transform
	foot_l.rotation.x=0.45
	assert(pad.global_position.distance_to(before)>0.02 and foot_r.global_transform==right_before)
	foot_l.rotation.x=0.0
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("#243348")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("#cbdfff")
	env.environment.ambient_light_energy=0.48
	scene.add_child(env)
	for i in range(2):
		var light:=DirectionalLight3D.new()
		light.rotation_degrees=Vector3(-35,-35 if i==0 else 145,0)
		light.light_color=Color("#fff1d1") if i==0 else Color("#8bcfff")
		light.light_energy=0.85 if i==0 else 0.25
		scene.add_child(light)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=2.65
	scene.add_child(camera)
	camera.current=true
	var center:=Vector3(0,1.0,0)
	var directions:Array[Vector3]=[Vector3(0,0.12,5),Vector3(0,0.12,-5),Vector3(5,0.12,0),Vector3(3,1.25,5),Vector3(3,1.25,-5),Vector3(0,-5,0.35)]
	var path:=OS.get_environment("PET_GOLD_OUT")
	assert(not path.is_empty())
	for i in range(VIEWS.size()):
		camera.position=center+directions[i]
		camera.look_at(center)
		await process_frame
		await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image()
		assert(image.save_png(path+"/godot-"+VIEWS[i]+".png")==OK)
	var file:=FileAccess.open(path+"/godot-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"pass":true,"mesh_instances":meshes.size(),"foot_pivots_independent":true,"views":VIEWS,"scope":"desktop native engine; not physical Android"}))
	file.close()
	print("MOSSKit_NATIVE_GODOT_FIVE_VIEWS_PASS_NOT_ART_APPROVED")
	quit()
