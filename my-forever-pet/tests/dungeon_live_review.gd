extends SceneTree
# Capture genuine live expeditions; no enemy deletion, teleporting or free loot.
const Field=preload("res://dungeon_view.gd")
var transitions=0
var fights=0
var captures=0
func _initialize():call_deferred("run")
func frames():
	for i in range(3):
		await process_frame
		await RenderingServer.frame_post_draw
func capture(d,region:int,stage:String):
	await frames()
	assert(root.get_texture().get_image().save_png("/tmp/dungeon-live-%d-%s.png"%[region,stage])==OK)
	captures+=1
	print("DUNGEON_LIVE_CAPTURE region=",region," stage=",stage," floor=",d.run.floor_number," enemies=",d.run.enemies.size()," rooms=",d.run.explored_rooms.size()," hp=",d.run.hp)
func next_action(d)->bool:
	var r=d.run
	if r.hp<=r.max_hp/2 and r.potions>0:
		d.heal_button.pressed.emit();return true
	if r.player==r.stairs and r.secured:
		d.stairs_button.pressed.emit();return true
	for direction in r.DIR:
		if r.enemy_at(r.player+direction)>=0:
			if r.energy>=2:d.power_button.pressed.emit()
			else:d.attack_button.pressed.emit()
			fights+=1;return true
	if r.skill_kind==1 and r.energy>=2:
		for direction in r.DIR:
			if r.cells.has(r.player+direction) and r.enemy_at(r.player+direction)<0 and r.enemy_at(r.player+direction*2)>=0:
				d.power_button.pressed.emit();fights+=1;return true
	var target:Vector2i=r.stairs if r.secured else r.relic
	var route=r.route(r.player,target)
	if route.is_empty():return false
	var screen=d.camera.unproject_position(d.pos(route[0]))*d.area.size/Vector2(d.viewport.size)
	var tap=InputEventScreenTouch.new();tap.index=0;tap.pressed=true;tap.position=screen
	d.touch(tap)
	if d.path.is_empty():return false
	d._process(.2)
	return true
func run():
	for region in range(3):
		var d=Field.new();root.add_child(d)
		d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		d.setup(region,1,0,false,true,902+region,24+region)
		d.set_process(false)
		await frames()
		assert(d.run.enemies.size()>0 and d.companion_id==0,"live enemies preserved and Mosky is the only companion")
		assert(d.pet_pose.get_node_or_null("PixelCompanion") is Sprite3D,"actual pixel companion visible")
		var seen:Dictionary={}
		await capture(d,region,"entry")
		seen["entry"]=true
		for action in range(360):
			if d.run.finished:break
			var old_turn:int=d.run.turns;var old_floor:int=d.run.floor_number
			var old_attack:int=d.run.attack_serial
			if not next_action(d):
				print("DUNGEON_LIVE_ROUTE_STOP region=",region," action=",action," tile=",d.run.player)
				break
			d._process(.12)
			assert(d.run.cells.has(d.run.player))
			assert(d.run.turns>old_turn or d.run.floor_number>old_floor or d.run.finished,"UI action advances gameplay")
			if d.run.attack_serial>old_attack and not seen.has("combat"):
				seen["combat"]=true;await capture(d,region,"combat")
			var in_room=false
			for room in d.run.rooms:
				if room.has_point(d.run.player):in_room=true;break
			if not in_room and not seen.has("corridor"):
				seen["corridor"]=true;await capture(d,region,"corridor")
			if d.run.explored_rooms.size()>=2 and in_room and not seen.has("second-room"):
				seen["second-room"]=true;await capture(d,region,"second-room")
			if d.run.secured and not seen.has("relic"):
				seen["relic"]=true;await capture(d,region,"relic")
			if d.run.floor_number>old_floor:
				transitions+=1
				if not seen.has("second-floor"):
					seen["second-floor"]=true;await capture(d,region,"second-floor")
			if action%12==0:await process_frame
		print("DUNGEON_LIVE_RESULT region=",region," finished=",d.run.finished," success=",d.run.success," floor=",d.run.floor_number," turns=",d.run.turns)
		d.queue_free();await process_frame
	assert(fights>0,"live enemy combat exercised")
	assert(transitions>0,"at least one actual descent exercised")
	print("DUNGEON_LIVE_REVIEW_PASS captures=",captures," fights=",fights," transitions=",transitions)
	quit()
