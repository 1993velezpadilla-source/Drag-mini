extends SceneTree
# Isolated production WildField scene; missing companion art intentionally uses its fallback.
const Field=preload("res://wild_field.gd")
func _initialize():
	call_deferred("run")
func frames():
	for i in range(4):
		await process_frame
		await RenderingServer.frame_post_draw
func run():
	for region in range(3):
		var field=Field.new()
		root.add_child(field)
		field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		field.setup(region,1,region,false,false,123+region,0)
		field.set_process(false)
		await frames()
		assert(field.field_input.size.x>200 and field.field_input.size.y>200,"usable field area")
		assert(root.get_visible_rect().encloses(field.inspect_button.get_global_rect()),"action stays on screen")
		var point=Vector2(2.5,2.0)
		var screen=field.camera.unproject_position(Vector3(point.x,0,point.y))*field.field_input.size/Vector2(field.viewport.size)
		assert(Rect2(Vector2.ZERO,field.field_input.size).has_point(screen),"test point in viewport")
		var tap=InputEventScreenTouch.new()
		tap.index=0;tap.pressed=true;tap.position=screen
		field.field_input.gui_input.emit(tap)
		assert(field.run.destination.distance_to(point)<.12,"touch maps to terrain")
		var other=InputEventScreenTouch.new()
		other.index=1;other.pressed=true;other.position=Vector2(3,3)
		field.field_input.gui_input.emit(other)
		assert(field.run.destination.distance_to(point)<.12,"secondary touch cannot steal movement")
		tap.pressed=false;field.field_input.gui_input.emit(tap)
		assert(field.touch_index==-1,"release clears pointer")
		field._process(.016)
		assert(field.destination_marker.visible,"destination is visible")
		field.scan_button.pressed.emit()
		field._process(.016)
		assert(field.compass_arrow.visible and field.trace.visible and field.run.scans==2,"scan activates actual world markers")
		await frames()
		var path="/tmp/field-isolated-%d.png"%region
		assert(root.get_texture().get_image().save_png(path)==OK)
		field.run.scan_left=0
		field._process(.016)
		assert(not field.compass_arrow.visible,"expired scan hides compass")
		field.inspect_button.button_down.emit()
		assert(field.run.inspecting)
		field.inspect_button.button_up.emit()
		assert(not field.run.inspecting and field.run.hold==0.0,"release clears action")
		print("FIELD_VISUAL_OK ",region," viewport=",field.viewport.size," meshes=",field.mesh_cache.size())
		field.queue_free()
		await process_frame
	print("FOREVER_FIELD_ISOLATED_PASS 3")
	quit()
