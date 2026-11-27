extends SceneTree
const View=preload("res://dungeon_view.gd")
const Art=preload("res://pixel_pet_art.gd")
const RulesForFX=preload("res://dungeon_rules.gd")
func _initialize():call_deferred("run")
func run():
	var dungeon=View.new()
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1080,1760)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world:=Node3D.new();viewport.add_child(world)
	var camera:=Camera3D.new();world.add_child(camera)
	camera.position=Vector3(0,5,10);camera.look_at(Vector3(0,.5,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=23.0;camera.current=true
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("#243345");world.add_child(env)
	var floor:=MeshInstance3D.new();world.add_child(floor)
	var floor_mesh:=PlaneMesh.new();floor_mesh.size=Vector2(18,18);floor.mesh=floor_mesh
	var floor_mat:=StandardMaterial3D.new();floor_mat.albedo_color=Color("#46505b");floor_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;floor.material_override=floor_mat
	var i:int=0
	for id in Art.ENEMY_PIXEL_PILOTS:
		var actor:=Node3D.new();world.add_child(actor)
		actor.position=Vector3((i%3-1)*2.1,0,float(int(i/3.0))*1.65-8.25)
		dungeon.region=0 if id in ["sporeling","vinesnap","thornbeetle","rootgnawer","leafwisp","bramble_pup","mossmite","sylphowl","hollow_stag","grovetitan","fungal_monarch"] else 1 if id in ["coralcrab","eelstrix","marrowray","jellymancer","shellguard","anemoneye","reef_pup","bubblewisp","leviathorn","abyss_colossus","tidal_sovereign"] else 2
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
	dungeon.combat_fx_setup(world)
	var modes:Dictionary={}
	for id in RulesForFX.SIGNATURE_SKILLS:
		var skill:Array=RulesForFX.SIGNATURE_SKILLS[id]
		assert(dungeon.COMBAT_FX_STYLES.has(skill[6]))
		var mode:String=dungeon.COMBAT_FX_STYLES[skill[6]][0]
		modes[mode]=true
		dungeon.combat_fx_spawn({"fx":skill[6],"from":Vector2i.ZERO,"to":Vector2i(2,0),"path":[Vector2i(1,0),Vector2i(2,0)],"tiles":[Vector2i(2,0)]})
		dungeon.combat_fx_update(.12)
		assert(dungeon.combat_particles[0].visible)
		dungeon.combat_fx_update(1.0)
		assert(dungeon.combat_bursts.is_empty() and not dungeon.combat_particles[0].visible)
	for species in RulesForFX.SECONDARY_SKILLS:
		var style:Array=dungeon.combat_style("alt_"+species)
		assert(style[0]==RulesForFX.SECONDARY_SKILLS[species][6])
		dungeon.combat_fx_spawn({"fx":"alt_"+species,"from":Vector2i.ZERO,"to":Vector2i.RIGHT})
		dungeon.combat_fx_update(.12)
		assert(dungeon.combat_particles[0].visible)
		dungeon.combat_fx_update(1.0)
	assert(modes.size()>=13)
	for j in range(3):
		dungeon.combat_fx_spawn({"fx":["vine_snap","nova_bolt","gravity_web"][j],"from":Vector2i(-2,j-1),"to":Vector2i(2,j-1),"path":[Vector2i(-1,j-1),Vector2i(0,j-1),Vector2i(1,j-1),Vector2i(2,j-1)],"tiles":[Vector2i(2,j-1)]})
	dungeon.combat_fx_update(.24)
	await process_frame
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png("/tmp/volnox-combat-fx.png")==OK)
	print("VOLNOX_COMBAT_VFX_PASS ",modes.size()," modes / 66 skills")
	dungeon.free()
	print("VOLNOX_RUNTIME_PIXEL_PASS ",i)
	quit()
