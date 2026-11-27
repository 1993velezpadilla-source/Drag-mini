extends SceneTree
const View=preload("res://dungeon_view.gd")
const Art=preload("res://pixel_pet_art.gd")
func _initialize():call_deferred("run")
func run():
	var dungeon=View.new()
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(960,1280)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world:=Node3D.new();viewport.add_child(world)
	var camera:=Camera3D.new();world.add_child(camera)
	camera.position=Vector3(0,5,10);camera.look_at(Vector3(0,.5,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=17.0;camera.current=true
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("#243345");world.add_child(env)
	var floor:=MeshInstance3D.new();world.add_child(floor)
	var floor_mesh:=PlaneMesh.new();floor_mesh.size=Vector2(18,18);floor.mesh=floor_mesh
	var floor_mat:=StandardMaterial3D.new();floor_mat.albedo_color=Color("#46505b");floor_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;floor.material_override=floor_mat
	var i:int=0
	for id in Art.ENEMY_PIXEL_PILOTS:
		var actor:=Node3D.new();world.add_child(actor)
		actor.position=Vector3((i%3-1)*2.1,0,float(int(i/3.0))*1.65-5.775)
		dungeon.region=0 if id in ["sporeling","vinesnap","thornbeetle","rootgnawer","leafwisp","bramble_pup","mossmite","sylphowl"] else 1 if id in ["coralcrab","eelstrix","marrowray","jellymancer","shellguard","anemoneye","reef_pup","bubblewisp"] else 2
		assert(dungeon.attach_enemy_pixel(actor,id))
		var sprite:=actor.get_node("EnemyPixel") as Sprite3D
		assert(sprite.texture_filter==BaseMaterial3D.TEXTURE_FILTER_NEAREST)
		assert(actor.has_node("EnemyContactShadow"))
		assert(sprite.material_override is ShaderMaterial)
		var idle:=sprite.texture
		dungeon.enemy_pose(actor,"attack",.28,Vector2.RIGHT)
		dungeon.update_enemy_pixel(actor,.14,Vector3.ZERO)
		assert(int(actor.get_meta("enemy_facing"))==3)
		assert(sprite.texture!=idle)
		assert(str(actor.get_meta("enemy_phase"))=="attack")
		dungeon.update_enemy_pixel(actor,.2,Vector3.ZERO)
		assert(str(actor.get_meta("enemy_phase"))=="recover")
		dungeon.update_enemy_pixel(actor,.15,Vector3.LEFT)
		assert(str(actor.get_meta("enemy_phase"))=="walk")
		assert(int(actor.get_meta("enemy_facing"))==2)
		dungeon.enemy_pose(actor,"attack",.28,Vector2.DOWN)
		dungeon.update_enemy_pixel(actor,.12,Vector3.ZERO)
		i+=1
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=viewport.get_texture().get_image()
	assert(image!=null and not image.is_empty())
	assert(image.save_png("/tmp/volnox-runtime-preview.png")==OK)
	dungeon.free()
	print("VOLNOX_RUNTIME_PIXEL_PASS ",i)
	quit()
