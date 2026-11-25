extends SubViewportContainer
# A live Godot scene using the exact runner GLB and articulated paws.
var view:SubViewport
var world:Node3D
var room_node:Node3D
var avatar:Node3D
var camera:Camera3D
var feet:Array[Node3D]=[]
var wardrobe_nodes:Array[Node3D]=[]
var equipped_key=""
var active_room=""
var active_species=-1
var active_stage=-1
var elapsed=0.0
var target_yaw=0.0
var touch_bounce=0.0
var ground=Vector3(0,0.09,1.7)
var sole_offset=0.0
var environment:Environment
var night_state=false
var contact_mesh:MeshInstance3D
var light_key:DirectionalLight3D
func _ready():
	stretch=true
	mouse_filter=MOUSE_FILTER_IGNORE
	view=SubViewport.new()
	view.own_world_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	view.msaa_3d=Viewport.MSAA_2X
	add_child(view)
	world=Node3D.new()
	view.add_child(world)
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	environment=env.environment
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("#192a49")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("#c5d9ee")
	env.environment.ambient_light_energy=0.56
	world.add_child(env)
	light_key=DirectionalLight3D.new()
	light_key.rotation_degrees=Vector3(-55,-35,0)
	light_key.light_color=Color("#ffe3ba")
	light_key.light_energy=0.92
	light_key.shadow_enabled=true
	light_key.directional_shadow_max_distance=22
	world.add_child(light_key)
	var fill=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-30,145,0)
	fill.light_color=Color("#a5c7ff")
	fill.light_energy=0.38
	world.add_child(fill)
	camera=Camera3D.new()
	world.add_child(camera)
	camera.position=Vector3(0,7.8,12.7)
	camera.look_at(Vector3(0,2.1,-0.35))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect=Camera3D.KEEP_WIDTH
	camera.size=11.6
	camera.current=true
	resized.connect(update_camera)
	visibility_changed.connect(update_render_state)
	update_camera()
func update_render_state():
	if not is_instance_valid(view): return
	view.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
func update_camera():
	if not is_instance_valid(camera) or size.x<2 or size.y<2: return
	# Keep the room composition inside both portrait and landscape-shaped panels.
	camera.size=maxf(10.6,7.4*size.x/size.y)
func set_night(night:bool):
	if night==night_state: return
	night_state=night
	light_key.light_energy=0.48 if night else 0.92
	light_key.light_color=Color("#b9caff") if night else Color("#ffe3ba")
	environment.ambient_light_energy=0.40 if night else 0.56
func mesh(parent:Node3D,path:String,p:Vector3)->Node3D:
	if not ResourceLoader.exists(path): return null
	var packed=load(path) as PackedScene
	if packed==null: return null
	var instance=packed.instantiate() as Node3D
	parent.add_child(instance)
	instance.position=p
	return instance
func set_room(id:String):
	if id==active_room: return
	active_room=id
	if is_instance_valid(room_node):
		world.remove_child(room_node); room_node.queue_free()
	room_node=mesh(world,"res://assets/rooms/"+id+".glb",Vector3.ZERO)
	if room_node==null: push_error("Missing live room "+id)
func set_pet(species:int,stage:int):
	if species==active_species and stage==active_stage: return
	active_species=species; active_stage=stage
	if is_instance_valid(avatar):
		world.remove_child(avatar); avatar.queue_free()
	avatar=Node3D.new()
	world.add_child(avatar)
	feet.clear()
	wardrobe_nodes.clear()
	equipped_key=""
	avatar.position=ground
	sole_offset=0.0
	if stage==0:
		avatar.hide()
		return
	if species==0:
		# Identical asset files and foot placement to runner.make_player().
		mesh(avatar,"res://assets/mosskit.glb",Vector3.ZERO)
		for side in [-1,1]:
			var foot=mesh(avatar,"res://assets/foot.glb",Vector3(side*0.37,0.20,0.16))
			if foot!=null:
				foot.rotation.y=PI
				feet.append(foot)
	else:
		mesh(avatar,"res://assets/creatures/species_%02d.glb"%species,Vector3.ZERO)
	sole_offset=mesh_bottom(avatar,Transform3D.IDENTITY)
	var base=0.70 if stage==1 else 0.88 if stage==2 else 1.0
	avatar.scale=Vector3.ONE*base*1.28
	avatar.position.y=ground.y-sole_offset*avatar.scale.y
func mesh_bottom(node:Node,relative:Transform3D)->float:
	var result=INF
	var t=relative
	if node is Node3D and node!=avatar: t=relative*node.transform
	if node is MeshInstance3D and node.mesh!=null:
		var a:AABB=node.get_aabb()
		for i in range(8): result=minf(result,(t*a.get_endpoint(i)).y)
	for child in node.get_children(): result=minf(result,mesh_bottom(child,t))
	return result
func grounded_error()->float:
	if not is_instance_valid(avatar) or active_stage==0: return 0.0
	return absf(avatar.position.y+sole_offset*avatar.scale.y-ground.y)
func dress(worn:Array,equipped:int):
	if not is_instance_valid(avatar): return
	var key=str(worn)+":"+str(equipped)
	if key==equipped_key: return
	equipped_key=key
	for ob in wardrobe_nodes:
		if is_instance_valid(ob):
			avatar.remove_child(ob)
			ob.queue_free()
	wardrobe_nodes.clear()
	if active_stage==0: return
	var anchors=[Vector3(0,1.66,0),Vector3(0,1.03,0.68),Vector3(0,0.52,0.38),Vector3(0,0.17,0.21)]
	var scales=[0.66,0.44,0.58,0.42]
	for slot in range(4):
		var id=int(worn[slot])
		if id<=0: continue
		var ob=mesh(avatar,"res://assets/wardrobe/clothes_%d.glb"%(id-1),anchors[slot])
		if ob!=null:
			ob.scale=Vector3.ONE*scales[slot]
			wardrobe_nodes.append(ob)
	if equipped>0:
		var anchor=Vector3(0,1.72,0) if equipped==1 else Vector3(0.60,1.40,0.26) if equipped==2 else Vector3(0,2.05,0)
		var ob=mesh(avatar,"res://assets/wardrobe/item_%d.glb"%(equipped-1),anchor)
		if ob!=null:
			ob.scale=Vector3.ONE*0.57
			if equipped==3: ob.rotation.x=PI/2
			wardrobe_nodes.append(ob)
func tap():
	touch_bounce=0.30
	target_yaw=randf_range(-0.20,0.20)
func screen_point(world_point:Vector3)->Vector2:
	if view.size.x<=1 or view.size.y<=1: return size*0.5
	var p=camera.unproject_position(world_point)
	return p*size/Vector2(view.size)
func _process(dt:float):
	if not is_instance_valid(avatar): return
	elapsed+=dt
	touch_bounce=maxf(0,touch_bounce-dt)
	avatar.rotation.y=lerpf(avatar.rotation.y,target_yaw+sin(elapsed*0.9)*0.055,minf(1,dt*5))
	var bounce=sin(touch_bounce/0.30*PI)*0.10
	var base=(0.70 if active_stage==1 else 0.88 if active_stage==2 else 1.0)*1.28
	var breathe=1.0+sin(elapsed*2.6)*0.014
	avatar.scale=Vector3(base/breathe,base*breathe,base/breathe)
	avatar.position=ground+Vector3(0,bounce-sole_offset*avatar.scale.y,0)
