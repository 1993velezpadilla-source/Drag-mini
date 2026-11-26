extends SceneTree
const Field=preload("res://dungeon_view.gd")
var completed=0
var surfaces:Dictionary={}
func _initialize():call_deferred("run")
func frames():
	for i in range(4):
		await process_frame
		await RenderingServer.frame_post_draw
func exterior_review(dungeon,region:int,floor_index:int):
	# Measure actual visible pixel contribution, not just node count or frustum overlap.
	# Render the exact same gameplay camera twice, with and without the exterior GLBs.
	var prefix="res://assets/dungeon_"+["forest","reef","star"][region]
	if not ResourceLoader.exists(prefix+"_exterior.glb"):return
	var meshes:Array[Mesh]=[]
	for part in dungeon.rock_parts(prefix+"_exterior.glb"):meshes.append(part.mesh)
	for part in dungeon.rock_parts(prefix+"_vista.glb"):meshes.append(part.mesh)
	var layers:Array[Node3D]=[]
	for child in dungeon.geometry.get_children():
		if child is MultiMeshInstance3D and child.multimesh!=null and meshes.has(child.multimesh.mesh):
			layers.append(child)
	for child in dungeon.exterior_life:
		if not layers.has(child):layers.append(child)
	assert(not layers.is_empty(),"real exterior render layers found")
	await frames()
	var full:Image=dungeon.viewport.get_texture().get_image()
	for layer in layers:layer.hide()
	await frames()
	var empty:Image=dungeon.viewport.get_texture().get_image()
	for layer in layers:layer.show()
	await frames()
	assert(full.get_size()==empty.get_size())
	var changed=0;var samples=0
	var difference=Image.create(full.get_width(),full.get_height(),false,Image.FORMAT_RGB8)
	difference.fill(Color.BLACK)
	# Sample every other pixel, using an explicit color delta rather than a file hash.
	for y in range(0,full.get_height(),2):
		for x in range(0,full.get_width(),2):
			var a=full.get_pixel(x,y);var b=empty.get_pixel(x,y)
			var delta=maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
			if delta>.045:
				changed+=1
				difference.fill_rect(Rect2i(x,y,mini(2,full.get_width()-x),mini(2,full.get_height()-y)),Color(1,.65,.15))
			samples+=1
	var coverage=100.0*float(changed)/maxi(samples,1)
	print("DUNGEON_EXTERIOR_VISIBILITY region=",region," floor=",floor_index," pixel_percent=",coverage," groups=",dungeon.exterior_groups.size()," animated=",dungeon.exterior_life_centers.size())
	# Diagnostic mask shows exactly where the new models contribute to gameplay.
	var path="/tmp/dungeon-real-%d-floor%d-exterior-"%[region,floor_index]
	assert(full.save_png(path+"on.png")==OK)
	assert(empty.save_png(path+"off.png")==OK)
	assert(difference.save_png(path+"mask.png")==OK)
	if coverage<1.0:push_warning("Exterior composition rejected: less than 1 percent visible contribution from new assets")
	# Coverage is not aesthetic approval. A large ugly mesh can also score highly.
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
		assert(dungeon.exterior_vertex_count>100 and dungeon.exterior_max_height<-.25,"exterior stays below playable floor")
		assert(dungeon.floor_surface.mesh.get_surface_count()==1,"continuous indexed walkable terrain")
		if ResourceLoader.exists("res://assets/dungeon_forest_exterior.glb"):
			assert(dungeon.exterior_groups.size()>0 and dungeon.exterior_groups.size()<=40,"exterior landscape groups placed within budget")
			for q in dungeon.exterior_groups:
				assert(dungeon.exterior_distances[q]>=2 and not dungeon.run.cells.has(q),"exterior groups stay beyond walls")
				for dy in range(-1,2):
					for dx in range(-1,2):assert(not dungeon.run.cells.has(q+Vector2i(dx,dy)),"scenic footprint clear")
			if ResourceLoader.exists("res://assets/dungeon_forest_vista.glb"):assert(dungeon.exterior_vistas.size()>0,"room focal scenery placed")
			assert(dungeon.exterior_life_centers.size()>0 and dungeon.exterior_life_centers.size()<=12)
			assert(not dungeon.exterior_life.is_empty(),"actual Blender exterior inhabitants loaded")
			var previous:Vector3=dungeon.exterior_life[0].multimesh.get_instance_transform(0).origin
			dungeon.update_exterior_world(.25)
			assert(dungeon.exterior_life[0].multimesh.get_instance_transform(0).origin!=previous,"exterior inhabitants animate")
		assert(dungeon.ambient_batches.size()==2 and dungeon.ambient_origins.size()==36)
		assert(dungeon.trail_batch.multimesh.instance_count==16 and dungeon.trail_emitted==0)
		assert((dungeon.caustic_overlay!=null)==(region==1))
		var old_ambient:Vector3=dungeon.ambient_batches[0].multimesh.get_instance_transform(0).origin
		dungeon.update_living_ambient(.2)
		assert(dungeon.ambient_batches[0].multimesh.get_instance_transform(0).origin!=old_ambient,"living ambient moves")
		assert(not surfaces.has(dungeon.floor_surface_signature),"biomes have different floor textures");surfaces[dungeon.floor_surface_signature]=true
		if ResourceLoader.exists("res://assets/dungeon_forest_landmark.glb"):assert(dungeon.landmark_count>0,"production landmark placed")
		if ResourceLoader.exists("res://assets/dungeon_forest_rock_0.glb"):
			var boundary:Dictionary={}
			for p in dungeon.run.cells:
				for d in dungeon.run.DIR:
					if not dungeon.run.cells.has(p+d):boundary[p+d]=true
			assert(dungeon.rock_modules==boundary.size(),"every boundary cell rendered exactly once")
		if ResourceLoader.exists("res://assets/dungeon_forest_span.glb"):assert(dungeon.span_count>0,"continuous sculpted wall faces required")
		if ResourceLoader.exists("res://assets/dungeon_forest_terrace.glb"):
			assert(dungeon.terrace_count>0 and dungeon.floor_detail_count>0,"layered environment models placed")
			for q in dungeon.terrace_cells:assert(not dungeon.run.cells.has(q),"terraces never cover walkable tiles")
		dungeon.floor_banner.hide()
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/dungeon-real-%d-entry.png"%region)==OK)
		await exterior_review(dungeon,region,1)
		if ResourceLoader.exists("res://assets/dungeon_forest_threshold.glb"):
			assert(dungeon.threshold_count>0,"authored passage entrances")
			for q in dungeon.threshold_cells:assert(dungeon.run.cells.has(q),"entrances remain walkable")
		assert(dungeon.room_lights.size()==2,"bounded room light budget")
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
		assert(dungeon.trail_emitted==1 and dungeon.trail_ages[0]==0.0,"successful movement emits one pooled trail")
		for k in range(16):dungeon.update_living_ambient(.25)
		assert(dungeon.trail_ages[0]>=4.0,"trail expires without allocation")
		assert(dungeon.reward_age>0.0 and dungeon.reward_pool.size()==12,"pooled pickup reward burst")
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
			if floor_index==0:
				assert(dungeon.run.floor_number==2 and not dungeon.notified)
				assert(dungeon.trail_emitted==0 and dungeon.ambient_origins.size()==36,"floor rebuild resets ambient pools")
				await exterior_review(dungeon,region,2)
		assert(dungeon.notified and completed==region+1)
		dungeon.sync()
		await frames()
		assert(completed==region+1,"no repeated completion")
		dungeon.queue_free()
		await process_frame
	print("FOREVER_DUNGEON_VIEW_PASS ",completed)
	quit()
