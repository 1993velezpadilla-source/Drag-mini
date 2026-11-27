extends SceneTree
const Art=preload("res://pixel_pet_art.gd")
const Life=preload("res://volnox_pixel_life.gdshader")
func _initialize():call_deferred("run")
func run():
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(576,288)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world:=Node3D.new();viewport.add_child(world)
	var camera:=Camera3D.new();world.add_child(camera)
	camera.position=Vector3(0,0,8);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.0;camera.current=true
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("#202330");world.add_child(env)
	for i in range(3):
		for j in range(2):
			var mesh:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(1.25,1.25);mesh.mesh=quad;world.add_child(mesh)
			mesh.position=Vector3((i-1)*1.7,.75-j*1.5,0)
			var m:=ShaderMaterial.new();m.shader=Life
			m.set_shader_parameter("sprite_tex",Art.enemy_pixel_texture(Art.ENEMY_PIXEL_PILOTS[i],3 if j==1 else 0,"attack" if j==1 else "idle",1))
			m.set_shader_parameter("hit_flash",.18 if j==1 else 0.0)
			m.set_shader_parameter("pulse_offset",float(i))
			mesh.material_override=m
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=viewport.get_texture().get_image()
	assert(image!=null and not image.is_empty())
	assert(image.save_png("/tmp/volnox-shader-preview.png")==OK)
	print("VOLNOX_PIXEL_SHADER_VIEW_PASS")
	quit()
