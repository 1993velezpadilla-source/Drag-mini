extends SceneTree
const Field=preload("res://dungeon_view.gd")
var completed=0
func _initialize():call_deferred("run")
func frames():
	for i in range(4):
		await process_frame
		await RenderingServer.frame_post_draw
func run():
	for region in range(3):
		var dungeon=Field.new();root.add_child(dungeon)
		dungeon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dungeon.setup(region,1,0,false,true,902+region,24+region)
		dungeon.set_process(false)
		await frames()
		assert(dungeon.companion_id==24+region)
		assert(dungeon.area.size.x>200 and dungeon.area.size.y>200)
		assert(dungeon.floor_label.text.contains("rooms"))
		assert(dungeon.terrain_texture!=null and dungeon.terrain_normal!=null)
		if ResourceLoader.exists("res://assets/dungeon_forest_rock_0.glb"):assert(dungeon.rock_modules>0,"real Blender boundary modules required")
		assert(root.get_visible_rect().encloses(dungeon.heal_button.get_global_rect()))
		assert(dungeon.attack_button.icon!=null and dungeon.power_button.icon!=null and dungeon.heal_button.icon!=null)
		dungeon.run.enemies.clear()
		var pickup:Vector2i
		for d in dungeon.run.DIR:
			if dungeon.run.loot.get(dungeon.run.player+d,"")=="coin":pickup=dungeon.run.player+d;break
		var target=dungeon.pos(pickup)
		var screen=dungeon.camera.unproject_position(target)*dungeon.area.size/Vector2(dungeon.viewport.size)
		var tap=InputEventScreenTouch.new();tap.index=0;tap.pressed=true;tap.position=screen
		dungeon.touch(tap)
		assert(not dungeon.path.is_empty(),"real viewport tap resolves pickup")
		dungeon._process(.2)
		assert(dungeon.run.coins==3 and not dungeon.run.loot.has(pickup),"pickup commits once")
		assert(not dungeon.stairs_button.visible,"irrelevant action does not occupy HUD")
		var created:int=dungeon.actor_created
		dungeon.sync();dungeon.sync()
		assert(dungeon.actor_created==created,"unchanged actors reused")
		dungeon.feedback.hide();dungeon.floor_banner.hide()
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/dungeon-real-%d.png"%region)==OK)
		dungeon.ended.connect(func(ok:bool,count:int,_time:float):
			assert(ok and count==2)
			completed+=1)
		for floor_index in range(2):
			dungeon.run.enemies.clear()
			for p in dungeon.run.route(dungeon.run.player,dungeon.run.relic):assert(dungeon.run.move(p))
			dungeon.sync()
			for p in dungeon.run.route(dungeon.run.player,dungeon.run.stairs):assert(dungeon.run.move(p))
			dungeon.sync()
			assert(not dungeon.stairs_button.disabled)
			dungeon.stairs_button.pressed.emit()
			await frames()
			if floor_index==0:assert(dungeon.run.floor_number==2 and not dungeon.notified)
		assert(dungeon.notified and completed==region+1)
		dungeon.sync()
		await frames()
		assert(completed==region+1,"no repeated completion")
		dungeon.queue_free()
		await process_frame
	print("FOREVER_DUNGEON_VIEW_PASS ",completed)
	quit()
