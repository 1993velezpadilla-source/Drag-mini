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
	assert(dungeon.floor_detail_count==dungeon.floor_detail_bounds.size() and dungeon.floor_detail_count<=48,"bounded interior decoration")
	for q in dungeon.floor_detail_bounds:
		assert(dungeon.run.cells.has(q) and not dungeon.threshold_cells.has(q) and q!=dungeon.run.relic and q!=dungeon.run.stairs,"keep objectives and entrances clear")
		assert(dungeon.floor_detail_fits(q,dungeon.floor_detail_bounds[q]),"interior detail stays low and within a single tile")
	assert(dungeon.landscape_links.size()<=dungeon.LANDSCAPE_LINK_CAP,"bounded landscape connections")
	if region==2:assert(dungeon.landscape_links.is_empty() and dungeon.landscape_ridge_weights.is_empty(),"floating islands remain separate")
	for link in dungeon.landscape_links:
		var a=Vector2i(link.x,link.y);var b=Vector2i(link.z,link.w)
		assert(dungeon.landscape_path_clear(a,b),"terrain connection stays outside rooms and walls")
	for q in dungeon.landscape_ridge_weights:
		assert(dungeon.exterior_distances.get(q,0)>=2 and not dungeon.run.cells.has(q),"ridge outside traversable graph")
		assert(dungeon.landscape_ridge_weights[q]>0.0 and dungeon.landscape_ridge_weights[q]<=1.0)
	assert(dungeon.astral_cloud_bounds.size()<=dungeon.ASTRAL_CLOUD_CAP,"bounded cloud geometry")
	if region!=2:assert(dungeon.astral_cloud_bounds.is_empty(),"cloud banks restricted to Starfall")
	for cloud in dungeon.astral_cloud_bounds:
		assert(cloud.end.y<=-.35 and dungeon.scenery_clear_of_floor(cloud),"clouds remain below and outside gameplay")
		for other in dungeon.scenic_bounds:assert(not other.intersects(cloud),"clouds preserve scenic island silhouettes")
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
	for suffix in ["_habitat.glb","_understory.glb","_crystal_habitat.glb","_ruin_habitat.glb","_cloud_habitat.glb"]:
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
# Staged art review in the actual gameplay camera and terrain, not a concept image.
func review_volnox(dungeon,region:int):
	var species:Array=[["sporeling","vinesnap","thornbeetle"],["coralcrab","eelstrix","marrowray"],["nova_wisp","comet_hare","voidspider"]][region]
	var cells:Array=[]
	for q in dungeon.run.cells:
		if q==dungeon.run.player or dungeon.run.loot.has(q) or dungeon.run.enemy_at(q)>=0:continue
		var offset:Vector2i=q-dungeon.run.player
		if absi(offset.x)<=2 and absi(offset.y)<=2:cells.append(q)
	cells.sort_custom(func(a,b):return Vector2(a-dungeon.run.player).length_squared()<Vector2(b-dungeon.run.player).length_squared())
	assert(cells.size()>=1,"visible review positions")
	var staged:Array[Node3D]=[]
	for i in range(mini(species.size(),cells.size())):
		var actor:=Node3D.new()
		dungeon.actors.add_child(actor)
		actor.position=dungeon.pos(cells[i])
		assert(dungeon.attach_enemy_pixel(actor,str(species[i])))
		assert(actor.has_node("EnemyContactShadow"))
		assert(actor.get_node("EnemyPixel").material_override is ShaderMaterial)
		dungeon.enemy_pose(actor,"idle",0.0,Vector2([Vector2.DOWN,Vector2.RIGHT,Vector2.LEFT][i]))
		dungeon.update_enemy_pixel(actor,.1,Vector3.ZERO)
		staged.append(actor)
	await frames()
	assert(root.get_texture().get_image().save_png("/tmp/dungeon-real-volnox-%d.png"%region)==OK)
	for actor in staged:actor.free()
	await frames()
func run():
	for region in range(3):
		var dungeon=Field.new();root.add_child(dungeon)
		dungeon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dungeon.setup(region,1,0,false,true,902+region,24+region)
		dungeon.set_process(false)
		await frames()
		check_exterior_chunks(dungeon)
		if region==0:
			var electric_roles:Dictionary={}
			var electric_frames:Dictionary={}
			for id in ["eos_064","eos_129","eos_188","eos_189","eos_065","eos_144","eos_193","eos_354","eos_452","eos_489","eos_521","eos_192","eos_128","eos_493"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(not electric_roles.has(profile.role),"unique electric choreography "+id)
				electric_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"electric animation changes "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not electric_frames.has(signature),"unique electric sprite "+id)
				electric_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-electric-"+id+".png")==OK)
			print("KINDRIA_ELECTRIC_CHOREOGRAPHY_PASS ",electric_roles.size())
			var fire_roles:Dictionary={}
			var fire_frames:Dictionary={}
			for id in ["eos_041","eos_052","eos_053","eos_149","eos_157","eos_230","eos_262","eos_272","eos_276","eos_278","eos_291","eos_292","eos_517","eos_519","eos_522","eos_524","eos_047","eos_223"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(not fire_roles.has(profile.role),"unique fire choreography "+id)
				fire_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"fire animation changes "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not fire_frames.has(signature),"unique fire sprite "+id)
				fire_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-fire-"+id+".png")==OK)
			print("KINDRIA_FIRE_CHOREOGRAPHY_PASS ",fire_roles.size())
			var water_roles:Dictionary={}
			var water_frames:Dictionary={}
			for id in ["eos_016","eos_032","eos_044","eos_069","eos_087","eos_113","eos_156","eos_158","eos_159","eos_219","eos_239","eos_240","eos_255","eos_308","eos_310","eos_432","eos_433","eos_469","eos_070","eos_012","eos_307","eos_434"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(not water_roles.has(profile.role),"unique water choreography "+id)
				water_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"water animation changes "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not water_frames.has(signature),"unique water sprite "+id)
				water_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-water-"+id+".png")==OK)
			print("KINDRIA_WATER_CHOREOGRAPHY_PASS ",water_roles.size())
			var grass_roles:Dictionary={}
			var grass_frames:Dictionary={}
			for id in ["eos_076","eos_135","eos_151","eos_182","eos_221","eos_238","eos_251","eos_297","eos_320","eos_336","eos_441","eos_443","eos_458","eos_468","eos_486","eos_511","eos_537","eos_163","eos_079","eos_231","eos_124","eos_351","eos_015","eos_094","eos_084","eos_329","eos_253","eos_233","eos_504"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(not grass_roles.has(profile.role),"unique grass choreography "+id)
				grass_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"grass animation changes "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not grass_frames.has(signature),"unique grass sprite "+id)
				grass_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-grass-"+id+".png")==OK)
			print("KINDRIA_GRASS_CHOREOGRAPHY_PASS ",grass_roles.size())
			var ice_roles:Dictionary={}
			var ice_frames:Dictionary={}
			for id in ["eos_042","eos_097","eos_101","eos_270","eos_344","eos_345","eos_461","eos_462","eos_180","eos_002","eos_088","eos_130","eos_014","eos_150","eos_535"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(not ice_roles.has(profile.role),"unique ice choreography "+id)
				ice_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"ice animation changes "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not ice_frames.has(signature),"unique ice sprite "+id)
				ice_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-ice-"+id+".png")==OK)
			print("KINDRIA_ICE_CHOREOGRAPHY_PASS ",ice_roles.size())
			var earth_roles:Dictionary={}
			var earth_frames:Dictionary={}
			for id in ["eos_008","eos_143","eos_213","eos_289","eos_299","eos_484","eos_501","eos_285","eos_290","eos_142","eos_212","eos_131","eos_295","eos_118","eos_296"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(not earth_roles.has(profile.role),"unique earth choreography "+id)
				earth_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"earth animation changes "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not earth_frames.has(signature),"unique earth sprite "+id)
				earth_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-earth-"+id+".png")==OK)
			print("KINDRIA_EARTH_CHOREOGRAPHY_PASS ",earth_roles.size())
			var rock_roles:Dictionary={}
			var rock_frames:Dictionary={}
			for id in ["eos_028","eos_030","eos_073","eos_093","eos_453","eos_481","eos_512","eos_533","eos_350","eos_105","eos_540","eos_141","eos_480"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(not rock_roles.has(profile.role),"unique rock choreography "+id)
				rock_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"rock animation changes "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not rock_frames.has(signature),"unique rock sprite "+id)
				rock_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-rock-"+id+".png")==OK)
			print("KINDRIA_ROCK_CHOREOGRAPHY_PASS ",rock_roles.size())
			var fight_roles:Dictionary={}
			var fight_frames:Dictionary={}
			for id in ["eos_068","eos_072","eos_075","eos_077","eos_090","eos_092","eos_116","eos_136","eos_204","eos_206","eos_243","eos_246","eos_300","eos_303","eos_430","eos_440","eos_454","eos_479","eos_500","eos_507","eos_508","eos_531","eos_175","eos_222","eos_210","eos_265","eos_305","eos_051","eos_170","eos_340","eos_007","eos_029"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(not fight_roles.has(profile.role),"unique fight choreography "+id)
				fight_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"fight animation changes "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not fight_frames.has(signature),"unique fight sprite "+id)
				fight_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-fight-"+id+".png")==OK)
			print("KINDRIA_FIGHT_CHOREOGRAPHY_PASS ",fight_roles.size())
			var air_roles:Dictionary={}
			var air_frames:Dictionary={}
			for id in ["eos_036","eos_057","eos_100","eos_153","eos_174","eos_178","eos_179","eos_205","eos_211","eos_353","eos_442","eos_446","eos_490","eos_518","eos_444","eos_267","eos_509","eos_456","eos_040"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(not air_roles.has(profile.role),"unique air choreography "+id)
				air_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"air animation changes "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not air_frames.has(signature),"unique air sprite "+id)
				air_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-air-"+id+".png")==OK)
			print("KINDRIA_AIR_CHOREOGRAPHY_PASS ",air_roles.size())
			var poison_roles:Dictionary={}
			var poison_frames:Dictionary={}
			for id in ["eos_147","eos_196","eos_197","eos_198","eos_199","eos_200","eos_202","eos_279","eos_280","eos_283","eos_332","eos_438","eos_459","eos_485","eos_495","eos_496"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("poison_"),"dedicated poison role "+id)
				assert(not poison_roles.has(profile.role),"unique poison choreography "+id)
				poison_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"poison animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty poison frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not poison_frames.has(signature),"unique poison sprite "+id)
				poison_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-poison-"+id+".png")==OK)
			print("KINDRIA_POISON_CHOREOGRAPHY_PASS ",poison_roles.size())
			var bug_roles:Dictionary={}
			var bug_frames:Dictionary={}
			for id in ["eos_023","eos_080","eos_082","eos_086","eos_114","eos_164","eos_288","eos_306","eos_323","eos_346","eos_449","eos_460","eos_470","eos_502","eos_520","eos_529","eos_530"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("bug_"),"dedicated bug role "+id)
				assert(not bug_roles.has(profile.role),"unique bug choreography "+id)
				bug_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"bug animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty bug frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not bug_frames.has(signature),"unique bug sprite "+id)
				bug_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-bug-"+id+".png")==OK)
			print("KINDRIA_BUG_CHOREOGRAPHY_PASS ",bug_roles.size())
			var psychic_roles:Dictionary={}
			var psychic_frames:Dictionary={}
			for id in ["eos_095","eos_099","eos_107","eos_108","eos_109","eos_110","eos_111","eos_133","eos_137","eos_146","eos_187","eos_209","eos_215","eos_220","eos_232","eos_234","eos_258","eos_259","eos_266","eos_298","eos_309","eos_316","eos_317","eos_319","eos_331","eos_333","eos_335","eos_338","eos_439","eos_448","eos_450","eos_463","eos_464","eos_473","eos_478","eos_499","eos_506","eos_513","eos_514","eos_526","eos_528"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("psi_"),"dedicated psychic role "+id)
				assert(not psychic_roles.has(profile.role),"unique psychic choreography "+id)
				psychic_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"psychic animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty psychic frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not psychic_frames.has(signature),"unique psychic sprite "+id)
				psychic_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-psychic-"+id+".png")==OK)
			print("KINDRIA_PSYCHIC_CHOREOGRAPHY_PASS ",psychic_roles.size())
			var ghost_roles:Dictionary={}
			var ghost_frames:Dictionary={}
			for id in ["eos_005","eos_013","eos_035","eos_046","eos_049","eos_120","eos_126","eos_127","eos_216","eos_313","eos_437","eos_451","eos_476","eos_477"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("ghost_"),"dedicated ghost role "+id)
				assert(not ghost_roles.has(profile.role),"unique ghost choreography "+id)
				ghost_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"ghost animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty ghost frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not ghost_frames.has(signature),"unique ghost sprite "+id)
				ghost_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-ghost-"+id+".png")==OK)
			print("KINDRIA_GHOST_CHOREOGRAPHY_PASS ",ghost_roles.size())
			var dragon_roles:Dictionary={}
			var dragon_frames:Dictionary={}
			for id in ["eos_091","eos_162","eos_208","eos_341","eos_342","eos_343","eos_435","eos_494","eos_498","eos_538","eos_539"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("dragon_"),"dedicated dragon role "+id)
				assert(not dragon_roles.has(profile.role),"unique dragon choreography "+id)
				dragon_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"dragon animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty dragon frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not dragon_frames.has(signature),"unique dragon sprite "+id)
				dragon_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-dragon-"+id+".png")==OK)
			print("KINDRIA_DRAGON_CHOREOGRAPHY_PASS ",dragon_roles.size())
			var dark_roles:Dictionary={}
			var dark_frames:Dictionary={}
			for id in ["eos_022","eos_033","eos_038","eos_043","eos_045","eos_062","eos_063","eos_167","eos_172","eos_214","eos_249","eos_269","eos_334","eos_436","eos_445","eos_466","eos_472","eos_482","eos_483","eos_488","eos_491","eos_503","eos_515","eos_542"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("dark_"),"dedicated dark role "+id)
				assert(not dark_roles.has(profile.role),"unique dark choreography "+id)
				dark_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"dark animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty dark frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not dark_frames.has(signature),"unique dark sprite "+id)
				dark_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-dark-"+id+".png")==OK)
			print("KINDRIA_DARK_CHOREOGRAPHY_PASS ",dark_roles.size())
			var steel_roles:Dictionary={}
			var steel_frames:Dictionary={}
			for id in ["eos_001","eos_083","eos_103","eos_186","eos_244","eos_256","eos_325","eos_431","eos_475","eos_510","eos_523","eos_527","eos_532","eos_536"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("steel_"),"dedicated steel role "+id)
				assert(not steel_roles.has(profile.role),"unique steel choreography "+id)
				steel_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"steel animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty steel frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not steel_frames.has(signature),"unique steel sprite "+id)
				steel_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-steel-"+id+".png")==OK)
			print("KINDRIA_STEEL_CHOREOGRAPHY_PASS ",steel_roles.size())
			var neutral_contact_roles:Dictionary={}
			var neutral_contact_frames:Dictionary={}
			for id in ["eos_009","eos_018","eos_020","eos_039","eos_048","eos_050","eos_061","eos_066","eos_067","eos_071","eos_078","eos_081","eos_096","eos_121","eos_125","eos_132","eos_139","eos_140","eos_154","eos_161","eos_176","eos_177","eos_190","eos_203","eos_226","eos_235","eos_247","eos_248","eos_250","eos_260","eos_261","eos_264","eos_271","eos_275","eos_294","eos_311","eos_312","eos_314","eos_321","eos_322","eos_328","eos_347","eos_348","eos_352","eos_455","eos_487","eos_497","eos_505","eos_516","eos_541"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("normal_"),"dedicated neutral contact role "+id)
				assert(not neutral_contact_roles.has(profile.role),"unique neutral contact choreography "+id)
				neutral_contact_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"neutral contact animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty neutral contact frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not neutral_contact_frames.has(signature),"unique neutral contact sprite "+id)
				neutral_contact_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-neutral-contact-"+id+".png")==OK)
			print("KINDRIA_NEUTRAL_CONTACT_CHOREOGRAPHY_PASS ",neutral_contact_roles.size())
			var neutral_special_roles:Dictionary={}
			var neutral_special_frames:Dictionary={}
			for id in ["eos_025","eos_031","eos_060","eos_123","eos_145","eos_152","eos_155","eos_166","eos_168","eos_201","eos_207","eos_228","eos_241","eos_242","eos_245","eos_263","eos_277","eos_287","eos_324","eos_360","eos_394","eos_457","eos_471","eos_474"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("neutral_"),"dedicated neutral special role "+id)
				assert(not neutral_special_roles.has(profile.role),"unique neutral special choreography "+id)
				neutral_special_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"neutral special animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty neutral special frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not neutral_special_frames.has(signature),"unique neutral special sprite "+id)
				neutral_special_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-neutral-special-"+id+".png")==OK)
			print("KINDRIA_NEUTRAL_SPECIAL_CHOREOGRAPHY_PASS ",neutral_special_roles.size())
			var support_roles:Dictionary={}
			var support_frames:Dictionary={}
			for id in ["eos_006","eos_019","eos_021","eos_026","eos_055","eos_056","eos_058","eos_074","eos_098","eos_102","eos_104","eos_115","eos_117","eos_134","eos_148","eos_160","eos_165","eos_169","eos_173","eos_181","eos_185","eos_195","eos_218","eos_225","eos_236","eos_257","eos_301","eos_302","eos_318","eos_339","eos_349","eos_447","eos_492"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("support_"),"dedicated support role "+id)
				assert(not support_roles.has(profile.role),"unique support choreography "+id)
				support_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"support animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty support frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not support_frames.has(signature),"unique support sprite "+id)
				support_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-support-"+id+".png")==OK)
			print("KINDRIA_SUPPORT_CHOREOGRAPHY_PASS ",support_roles.size())
			var status_roles:Dictionary={}
			var status_frames:Dictionary={}
			for id in ["eos_003","eos_227","eos_004","eos_011","eos_191","eos_326","eos_534","eos_010","eos_037","eos_054","eos_027","eos_034","eos_112","eos_171","eos_217","eos_284","eos_293","eos_089","eos_106","eos_224","eos_281","eos_315","eos_017","eos_059","eos_194","eos_237","eos_304","eos_183","eos_184","eos_282","eos_286","eos_119","eos_138","eos_229","eos_327","eos_330","eos_465","eos_525","eos_024","eos_085","eos_122","eos_274","eos_252","eos_337","eos_254","eos_268","eos_273"]:
				var profile:Dictionary=dungeon.combat_profile(id)
				assert(str(profile.role).begins_with("status_"),"dedicated status role "+id)
				assert(not status_roles.has(profile.role),"unique status choreography "+id)
				status_roles[profile.role]=true
				var first:Image=dungeon.combat_frame_image(id,2)
				var middle:Image=dungeon.combat_frame_image(id,6)
				assert(first.get_data()!=middle.get_data(),"status animation changes "+id)
				assert(middle.get_used_rect().has_area(),"nonempty status frame "+id)
				var signature:String=middle.get_data().hex_encode()
				assert(not status_frames.has(signature),"unique status sprite "+id)
				status_frames[signature]=true
				assert(middle.save_png("/tmp/dungeon-real-status-"+id+".png")==OK)
			print("KINDRIA_STATUS_CHOREOGRAPHY_PASS ",status_roles.size())
			# Reproduce the freed-instance registry fault before the real expedition.
			var retired:Node3D=dungeon.actor_for("retired-test",Vector3.ZERO)
			retired.free()
			dungeon.refresh_actors()
			assert(not dungeon.actor_nodes.has("retired-test"))
			print("KINDRIA_ACTOR_LIFETIME_PASS")
		var test_center:Vector3=dungeon.pos(dungeon.run.player)
		var near_vista=AABB(test_center+Vector3(2,0,-2),Vector3(1.4,2,1.4))
		var cropped_vista=AABB(test_center+Vector3(8,0,-2),Vector3(1.4,2,1.4))
		assert(dungeon.score_vista(near_vista,test_center)>dungeon.score_vista(cropped_vista,test_center),"camera-visible scenic anchor wins")
		var blocker:Vector3=test_center+Vector3(0,7.6,11.3).normalized()*3
		assert(dungeon.camera_ray_blocked(AABB(blocker-Vector3.ONE*.3,Vector3.ONE*.6),test_center),"foreground obstruction detected")
		assert(not dungeon.camera_ray_blocked(AABB(blocker+Vector3(5,0,0),Vector3.ONE*.6),test_center),"side scenery does not obstruct camera")
		assert(not dungeon.scenery_clear_of_floor(AABB(test_center-Vector3(.25,0,.25),Vector3(.5,1,.5))),"reject model over player tile")
		assert(dungeon.companion_id==0,"retired species cannot replace Mosky")
		var sprite=dungeon.pet_pose.get_node("PixelCompanion") as Sprite3D
		var art=preload("res://pixel_pet_art.gd")
		var directions=[Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]
		var hashes:Array=[]
		for dir in range(4):
			art.animate_world_sprite(dungeon.pet_pose,directions[dir],true,.01)
			assert(int(sprite.get_meta("facing"))==dir)
			var first:Texture2D=sprite.texture
			hashes.append(first.get_image().get_data().hex_encode())
			art.animate_world_sprite(dungeon.pet_pose,directions[dir],true,.11)
			assert(sprite.texture!=first and sprite.texture.get_image().get_data()!=first.get_image().get_data(),"walk has distinct drawn frames")
			art.animate_world_sprite(dungeon.pet_pose,Vector2.ZERO,false,.01)
			assert(int(sprite.get_meta("facing"))==dir and sprite.get_meta("anim_state")=="idle")
		for i in range(4):
			for k in range(i+1,4):assert(hashes[i]!=hashes[k],"directions must have distinct pixel art")
		art.animate_world_sprite(dungeon.pet_pose,Vector2.DOWN,false,.01,"hurt")
		assert(sprite.get_meta("anim_state")=="hurt")
		art.animate_world_sprite(dungeon.pet_pose,Vector2.DOWN,false,.01,"idle")
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
		var baked:Image=dungeon.terrain_texture.get_image()
		assert(baked.get_size()==Vector2i(128,128) and baked.has_mipmaps(),"bounded mipmapped surface bake")
		var low_luma=1.0;var high_luma=0.0
		for yy in range(0,128,4):
			for xx in range(0,128,4):
				var luma=baked.get_pixel(xx,yy).get_luminance()
				low_luma=minf(low_luma,luma);high_luma=maxf(high_luma,luma)
		assert(high_luma-low_luma>.08,"surface has visible tonal variation")
		if region<2:
			assert(dungeon.exterior_surface.material_override is StandardMaterial3D)
			var outside:StandardMaterial3D=dungeon.exterior_surface.material_override
			var inside:StandardMaterial3D=dungeon.floor_surface.material_override
			assert(outside.uv1_scale.x<inside.uv1_scale.x,"exterior and room surface use distinct physical scale")
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
		await review_volnox(dungeon,region)
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
	# Ponoko review: render the real dungeon and actual runtime companion for each octant.
	var preview=Field.new();root.add_child(preview)
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.setup(0,1,0,false,true,943,0)
	preview.set_process(false)
	await frames()
	var art=preload("res://pixel_pet_art.gd")
	var actor:Node3D=preview.pet_pose
	var sprite:Sprite3D=actor.get_node("PixelCompanion")
	actor.set_meta("dungeon_grounded_gait",true)
	var directions:Array=[Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]
	var names:Array=["SE","SW","NE","NW"]
	for i in range(4):
		var direction:Vector2i=directions[i]
		preview.facing=direction
		preview._process(.016)
		assert(sprite.get_meta("facing")==i+4)
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/dungeon-real-ponoko-"+str(names[i])+"-idle.png")==OK)
		art.animate_world_sprite(actor,Vector2(direction),true,.15,"walk")
		assert(sprite.get_meta("facing")==i+4 and sprite.get_meta("anim_state")=="walk")
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/dungeon-real-ponoko-"+str(names[i])+"-walk.png")==OK)
		actor.set_meta("dungeon_cast_motion","cast")
		art.animate_world_sprite(actor,Vector2(direction),false,.016,"attack",false,.52,.48)
		assert(sprite.get_meta("facing")==i+4 and sprite.get_meta("attack_phase")=="strike")
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/dungeon-real-ponoko-"+str(names[i])+"-cast.png")==OK)
		art.animate_world_sprite(actor,Vector2(direction),false,.016,"hurt")
		assert(sprite.get_meta("anim_state")=="hurt")
		await frames()
		assert(root.get_texture().get_image().save_png("/tmp/dungeon-real-ponoko-"+str(names[i])+"-hurt.png")==OK)
	print("PONOKO_DUNGEON_DIAGONAL_PASS 16")
	preview.queue_free();await process_frame
	# Test the lab on a separate expedition; the normal completion tests above remain unchanged.
	var lab=Field.new();root.add_child(lab)
	lab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lab.setup(0,1,0,false,true,943,0)
	lab.set_process(false)
	await frames()
	lab.lab_open()
	await frames()
	assert(lab.run.dev_sandbox and lab.dev_panel.visible and not lab.dev_bubble.visible)
	assert(lab.dev_catalog.size()>=522 and lab.lab_filtered_ids().size()==lab.dev_catalog.size())
	assert(lab.dev_grid.get_child_count()==lab.DEV_PAGE_SIZE,"paged catalog")
	assert(lab.dev_panel.get_parent()==lab.hud_base and not lab.dungeon_footer.visible,"DEV replaces footer rather than covering world")
	assert(not lab.area.get_global_rect().intersects(lab.dev_panel.get_global_rect()),"combat lab and world never overlap")
	assert(lab.area.size.y>=lab.size.y*.35,"substantial world view remains")
	lab.dev_search.text="THUNDER"
	lab.dev_search.text_changed.emit("THUNDER")
	assert("eos_064" in lab.lab_filtered_ids())
	var info:String=lab.lab_move_info("eos_064")
	assert("Power 45" in info and "PP 7" in info and "73%" in info and "Range:" in info)
	lab.dev_fx_only.button_pressed=true
	var before:int=lab.run.attack_serial
	lab.lab_cast("eos_064")
	assert(lab.dev_panel.visible and lab.run.attack_serial==before and lab.player_cast_duration>0.0)
	assert(lab.dev_result.text.begins_with("FX preview"))
	var move_button:Button=lab.dev_grid.get_child(0)
	var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=move_button.size*.5
	move_button.gui_input.emit(down)
	assert(lab.hold_active)
	lab.show_held_attack()
	assert(lab.dev_detail.visible and "Power" in lab.dev_detail.text)
	var drag:=InputEventMouseMotion.new();drag.position=lab.hold_origin+Vector2(40,-40)
	lab._input(drag)
	assert(lab.facing==Vector2i(1,-1) and lab.hold_active)
	var up:=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=drag.position
	lab._input(up)
	await frames()
	assert(not lab.hold_active and lab.dev_panel.visible and not lab.dev_detail.visible)
	# Accessibility / keyboard / test activation still performs exactly one real action.
	var before_direct:String=lab.dev_result.text
	lab.dev_result.text="Direct activation pending"
	move_button.pressed.emit()
	assert(lab.dev_result.text!="Direct activation pending","direct action is not swallowed by hold capture")
	print("KINDRA_DEV_HOLD_DRAG_PASS")
	lab.lab_minimize()
	assert(lab.dev_bubble.visible and not lab.dev_panel.visible)
	var bubble_before:Vector2=lab.dev_bubble.position
	lab.dev_drag_moved=false;lab.dev_drag_distance=0.0
	lab.lab_drag(Vector2(-60,-30))
	assert(lab.dev_bubble.position!=bubble_before)
	lab.lab_end_drag()
	assert(lab.dev_bubble.visible)
	lab.dev_drag_moved=false
	lab.lab_end_drag()
	assert(lab.dev_panel.visible and not lab.dev_bubble.visible)
	lab.run.hp=0
	assert(lab.run.hp>0)
	lab.run.potions=0;lab.run.energy=0;lab.run.belly_tenths=0
	lab.run.dev_refill()
	assert(lab.run.hp==lab.run.max_hp and lab.run.potions>=99 and lab.run.energy==8 and lab.run.belly_tenths==1000)
	var equipped:Array=lab.run.equipped_moves.duplicate()
	lab.dev_fx_only.button_pressed=false
	lab.lab_spawn_target()
	lab.lab_cast("eos_064")
	assert(lab.dev_panel.visible and lab.run.equipped_moves==equipped)
	assert(lab.run.move_pp["eos_064"]==7)
	lab.run.floor_number=lab.run.floor_count
	lab.run.player=lab.run.stairs;lab.run.secured=true
	assert(lab.run.descend() and not lab.run.finished and lab.run.floor_number>lab.run.floor_count)
	lab.sync()
	await frames()
	assert(root.get_texture().get_image().save_png("/tmp/dungeon-real-dev-lab.png")==OK)
	print("KINDRIA_DEV_LAB_PASS moves=",lab.dev_catalog.size()," floor=",lab.run.floor_number)
	lab.queue_free()
	await process_frame
	print("FOREVER_DUNGEON_VIEW_PASS ",completed)
	quit()
