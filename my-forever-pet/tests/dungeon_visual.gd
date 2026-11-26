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
	# Run this geometry gate on both floors, before capturing the actual camera.
	assert(dungeon.vista_focus_points.size()==dungeon.exterior_vistas.size(),"one camera target per vista")
	var variant_total:int=0
	for count in dungeon.habitat_variant_counts:variant_total+=count
	assert(variant_total==dungeon.habitat_tall.size(),"habitat variants account for every placement")
	if region==2 and ResourceLoader.exists("res://assets/dungeon_star_crystal_habitat.glb"):
		assert(dungeon.exterior_surface.material_override is ShaderMaterial,"astral background uses layered cloud shading")
		if variant_total>=3:
			for count in dungeon.habitat_variant_counts:assert(count>0,"all three island silhouettes placed")
	for bounds in dungeon.scenic_bounds:
		assert(dungeon.scenery_clear_of_floor(bounds),"transformed Blender model overlaps gameplay tiles")
	for q in dungeon.habitat_large+dungeon.vista_large:
		for dy in range(-2,3):
			for dx in range(-2,3):
				assert(not dungeon.run.cells.has(q+Vector2i(dx,dy)),"wide scenery keeps the 5x5 traversal clearance")
	# Measure actual visible pixel contribution, not just node count or frustum overlap.
	# Render the exact same gameplay camera twice, with and without the exterior GLBs.
	var prefix="res://assets/dungeon_"+["forest","reef","star"][region]
	if not ResourceLoader.exists(prefix+"_exterior.glb"):return
	var meshes:Array[Mesh]=[]
	for part in dungeon.rock_parts(prefix+"_exterior.glb"):meshes.append(part.mesh)
	for part in dungeon.rock_parts(prefix+"_vista.glb"):meshes.append(part.mesh)
	for suffix in ["_habitat.glb","_understory.glb","_crystal_habitat.glb","_ruin_habitat.glb"]:
		for part in dungeon.rock_parts(prefix+suffix):meshes.append(part.mesh)
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
	if coverage<8.0:push_warning("ART_REJECT exterior contribution below 8 percent; inspect the real camera captures before release")
	# Coverage is not aesthetic approval. A large ugly mesh can also score highly.
func check_exterior_chunks(dungeon):
	var original:Array[Transform3D]=[]
	for p in [Vector3(-9,0,-1),Vector3(-.1,0,0),Vector3(0,0,0),Vector3(8.39,0,8.39),Vector3(8.4,0,8.4),Vector3(18,0,-9)]:
		original.append(Transform3D(Basis(Vector3.UP,.31),p))
	var chunks:Dictionary=dungeon.exterior_chunks(original)
	var flattened:Array[Transform3D]=[]
	for key in chunks:
		for placement in chunks[key]:
			assert(Vector2i(floori(placement.origin.x/8.4),floori(placement.origin.z/8.4))==key)
			flattened.append(placement)
	assert(flattened.size()==original.size())
	for placement in original:assert(flattened.count(placement)==1,"preserve each exterior transform")
	assert(chunks.size()>1)
func run():
	for region in range(3):
		var dungeon=Field.new();root.add_child(dungeon)
		dungeon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dungeon.setup(region,1,0,false,true,902+region,24+region)
		dungeon.set_process(false)
		await frames()
		check_exterior_chunks(dungeon)
		var test_center:Vector3=dungeon.pos(dungeon.run.player)
		var near_vista=AABB(test_center+Vector3(2,0,-2),Vector3(1.4,2,1.4))
		var cropped_vista=AABB(test_center+Vector3(8,0,-2),Vector3(1.4,2,1.4))
		assert(dungeon.score_vista(near_vista,test_center)>dungeon.score_vista(cropped_vista,test_center),"camera-visible scenic anchor wins")
		var blocker:Vector3=test_center+Vector3(0,7.6,11.3).normalized()*3
		assert(dungeon.camera_ray_blocked(AABB(blocker-Vector3.ONE*.3,Vector3.ONE*.6),test_center),"foreground obstruction detected")
		assert(not dungeon.camera_ray_blocked(AABB(blocker+Vector3(5,0,0),Vector3.ONE*.6),test_center),"side scenery does not obstruct camera")
		assert(not dungeon.scenery_clear_of_floor(AABB(test_center-Vector3(.25,0,.25),Vector3(.5,1,.5))),"reject model over player tile")
		assert(dungeon.companion_id==24+region)
		assert(dungeon.area.size.x>200 and dungeon.area.size.y>200)
		assert(dungeon.floor_label.text.contains("rooms"))
		assert(dungeon.hp_text.text=="HP %d/%d"%[dungeon.run.hp,dungeon.run.max_hp])
		assert(dungeon.relic_text.text=="0/1" and dungeon.stats.text==str(dungeon.run.coins))
		var small_map:Vector2=dungeon.map.size
		dungeon.map_zoom.pressed.emit()
		assert(dungeon.map_expanded and dungeon.map.size.x>small_map.x)
		var original_player:Vector2i=dungeon.run.player
		var map_tap=InputEventScreenTouch.new();map_tap.index=0;map_tap.pressed=true;map_tap.position=dungeon.map.position+Vector2(20,20)
		dungeon.touch(map_tap)
		assert(dungeon.path.is_empty() and dungeon.run.player==original_player,"expanded map tap does not move pet")
		dungeon.map_zoom.pressed.emit()
		assert(not dungeon.map_expanded and dungeon.map.size==small_map)
		assert(dungeon.terrain_texture!=null and dungeon.terrain_normal!=null)
		assert(dungeon.exterior_vertex_count>100 and dungeon.exterior_max_height<-.25,"exterior stays below playable floor")
		var landscape_bounds:AABB=dungeon.exterior_surface.mesh.get_aabb()
		for cell in dungeon.run.cells:
			var center:Vector3=dungeon.pos(cell)
			assert(center.x-landscape_bounds.position.x>=16.7 and landscape_bounds.end.x-center.x>=16.7,"exterior side margin")
			assert(center.z-landscape_bounds.position.z>=25.1 and landscape_bounds.end.z-center.z>=16.7,"exterior depth margin")
		assert(dungeon.floor_surface.mesh.get_surface_count()==1,"continuous indexed walkable terrain")
		if ResourceLoader.exists("res://assets/dungeon_forest_exterior.glb"):
			assert(dungeon.exterior_groups.size()>0 and dungeon.exterior_groups.size()<=40,"exterior landscape groups placed within budget")
			assert(dungeon.exterior_static_batches>0,"static landscape submitted in spatial chunks")
			if ResourceLoader.exists("res://assets/dungeon_forest_habitat.glb"):
				assert(dungeon.habitat_tall.size()>0 and dungeon.habitat_tall.size()<=36)
				assert(dungeon.habitat_low.size()>0 and dungeon.habitat_low.size()<=150)
				for q in dungeon.habitat_tall:
					assert(dungeon.exterior_distances[q]>=3 and dungeon.exterior_distances[q]<=9)
					for dy in range(-1,2):
						for dx in range(-1,2):assert(not dungeon.run.cells.has(q+Vector2i(dx,dy)),"tall scenery clearance")
				for q in dungeon.habitat_low:
					assert(dungeon.exterior_distances[q]>=2 and not dungeon.run.cells.has(q))
					assert(not dungeon.terrace_cells.has(q),"understory fills open land, not terrace footprints")
				for q in dungeon.habitat_tall:
					for tile in dungeon.terrace_cells:assert(Vector2(q-tile).length_squared()>=(5.0 if dungeon.habitat_large.has(q) else 3.0),"terrace keeps clear of tall habitat")
			if region<2 and ResourceLoader.exists("res://assets/dungeon_forest_vista.glb"):
				assert(dungeon.exterior_motion_batches>0,"authored water or kelp material animates")
				for material in dungeon.exterior_motion_materials.values():
					var previous_time:float=material.get_shader_parameter("scene_time")
					dungeon.update_exterior_world(.1)
					assert(material.get_shader_parameter("scene_time")>previous_time)
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
		assert((dungeon.forest_light_overlay!=null)==(region==0),"canopy light only in woodland")
		if region==2:
			assert(dungeon.astral_sigils!=null and dungeon.astral_sigil_cells.size()<=dungeon.run.rooms.size(),"bounded astral floor seals")
			for q in dungeon.astral_sigil_cells:assert(dungeon.run.cells.has(q))
		else:assert(dungeon.astral_sigils==null)
		assert(not dungeon.biome_light_materials.is_empty(),"biome lighting uses explicit clock")
		var old_light_time:float=dungeon.biome_light_materials[0].get_shader_parameter("scene_time")
		var old_ambient:Vector3=dungeon.ambient_batches[0].multimesh.get_instance_transform(0).origin
		dungeon.update_living_ambient(.2)
		assert(dungeon.biome_light_materials[0].get_shader_parameter("scene_time")>old_light_time)
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
