extends SubViewportContainer
# A live Godot scene using the exact runner GLB and articulated paws.
var view:SubViewport
var world:Node3D
var room_node:Node3D
var avatar:Node3D
var camera:Camera3D
var pet_fit=1.0
var bare_bounds=AABB()
var framing_key=""
var camera_safe=Rect2()
var decor:Node3D
var garden_crop:Node3D
var crop_stage=-1
var decor_key=""
var accent_light:OmniLight3D
var theme_index=-1
var projected_pet=Rect2()
var incompatible_wearables=0
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
var reaction_time=0.0
var reaction_kind=""
var sleeping=false
var fx_root:Node3D
var fx_nodes:Array[Node3D]=[]
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
	fx_root=Node3D.new(); world.add_child(fx_root)
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	environment=env.environment
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("#192a49")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("#c5d9ee")
	env.environment.ambient_light_energy=0.33
	world.add_child(env)
	light_key=DirectionalLight3D.new()
	light_key.rotation_degrees=Vector3(-55,-35,0)
	light_key.light_color=Color("#ffe3ba")
	light_key.light_energy=0.72
	light_key.shadow_enabled=true
	light_key.directional_shadow_max_distance=22
	world.add_child(light_key)
	var fill=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-30,145,0)
	fill.light_color=Color("#a5c7ff")
	fill.light_energy=0.38
	world.add_child(fill)
	var practical=OmniLight3D.new(); practical.position=Vector3(-3.4,2.8,-1.5); practical.light_color=Color("#ffb278"); practical.light_energy=1.25; practical.omni_range=6.0; world.add_child(practical)
	var rim=OmniLight3D.new(); rim.position=Vector3(3.5,2.9,-1.7); rim.light_color=Color("#ae81ff"); rim.light_energy=1.1; rim.omni_range=5.5; world.add_child(rim); accent_light=rim
	camera=Camera3D.new()
	world.add_child(camera)
	camera.position=Vector3(0,3.25,8.8)
	camera.look_at(Vector3(0,2.35,0.0))
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	camera.fov=56
	camera.keep_aspect=Camera3D.KEEP_HEIGHT
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
	camera.fov=clampf(53.0+maxf(0.0,1.0-size.x/size.y)*8.0,53.0,61.0)
	framing_key=""
# Compose the actual 3D avatar inside the unoccluded screen rectangle.
# Refit only when room, model, clothing or layout changes, not every frame.
func frame_pet(safe:Rect2):
	if not is_instance_valid(camera) or not is_instance_valid(avatar) or active_stage==0 or not bare_bounds.has_volume(): return
	if safe.size.x<100 or safe.size.y<120 or view.size.x<2: return
	camera_safe=safe
	var key=str(safe)+str(size)+str(active_species)+str(active_stage)+equipped_key
	if key==framing_key: return
	camera.v_offset=0
	update_camera()
	framing_key=key
	var bounds=bare_bounds
	for ob in wardrobe_nodes:
		if is_instance_valid(ob):
			var b=mesh_bounds(ob,Transform3D.IDENTITY)
			if b.has_volume(): bounds=bounds.merge(b)
	# Avoid transient bounce, squash and yaw affecting composition.
	var factor=(.70 if active_stage==1 else .88 if active_stage==2 else 1.0)*1.65*pet_fit
	var anchor=ground-Vector3(0,sole_offset*factor,0)
	var target=Rect2(safe.position+Vector2(10,8),safe.size-Vector2(20,16))
	for attempt in range(7):
		var r=project_bounds(bounds,anchor,factor)
		if r.size.x<=0 or r.size.y<=0: break
		var fit=minf(target.size.x*.88/r.size.x,target.size.y*.88/r.size.y)
		if fit<.99 and camera.fov<77:
			camera.fov=minf(77,rad_to_deg(2*atan(tan(deg_to_rad(camera.fov*.5))/maxf(.5,fit))))
			continue
		var desired_y=target.end.y-r.size.y*.5-8
		var delta=desired_y-r.get_center().y
		if absf(delta)<2: break
		var original=camera.v_offset
		camera.v_offset=original+.1
		var slope=(project_bounds(bounds,anchor,factor).get_center().y-r.get_center().y)/.1
		camera.v_offset=original
		if absf(slope)<.1: break
		camera.v_offset=clampf(original+delta/slope,-2.8,2.8)
	projected_pet=project_bounds(bounds,anchor,factor)
func project_bounds(bounds:AABB,anchor:Vector3,factor:float)->Rect2:
	var lower=Vector2(INF,INF)
	var upper=Vector2(-INF,-INF)
	for i in range(8):
		var p=screen_point(anchor+bounds.get_endpoint(i)*factor)
		lower=lower.min(p); upper=upper.max(p)
	return Rect2(lower,upper-lower)
func set_night(night:bool):
	if night==night_state: return
	night_state=night
	light_key.light_energy=0.38 if night else 0.72
	light_key.light_color=Color("#b9caff") if night else Color("#ffe3ba")
	environment.ambient_light_energy=0.23 if night else 0.33
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
	decor_key=""; crop_stage=-1
	if is_instance_valid(decor): world.remove_child(decor); decor.queue_free(); decor=null
	if is_instance_valid(garden_crop): world.remove_child(garden_crop); garden_crop.queue_free(); garden_crop=null
	if is_instance_valid(room_node):
		world.remove_child(room_node); room_node.queue_free()
	room_node=mesh(world,"res://assets/rooms/"+id+".glb",Vector3.ZERO)
	if room_node==null: push_error("Missing live room "+id)
func set_room_lighting(index:int):
	if index==theme_index or not is_instance_valid(accent_light): return
	theme_index=clampi(index,0,2)
	accent_light.light_color=[Color("#ffbe91"),Color("#65d9ff"),Color("#c18aff")][theme_index]
	accent_light.light_energy=[1.0,1.35,1.5][theme_index]
	environment.ambient_light_color=[Color("#d4deed"),Color("#afddff"),Color("#d0b4ff")][theme_index]
func set_installation(id:int):
	var key=active_room+":"+str(id)
	if key==decor_key: return
	decor_key=key
	if is_instance_valid(decor): world.remove_child(decor); decor.queue_free(); decor=null
	# The purchased object is displayed in its matching room.
	if id==4 and active_room=="room_bathroom": decor=mesh(world,"res://assets/wardrobe/item_3.glb",Vector3(3.3,.32,1.3))
	elif id==5 and active_room=="room_bedroom": decor=mesh(world,"res://assets/wardrobe/item_4.glb",Vector3(-3.35,.55,1.35))
	elif id==6 and active_room=="room_garden": decor=mesh(world,"res://assets/wardrobe/item_5.glb",Vector3(4.1,.9,1.45))
	if is_instance_valid(decor): decor.scale=Vector3.ONE*.65
func crop_shape(parent:Node3D,at:Vector3,dimensions:Vector3,color:Color)->MeshInstance3D:
	var ob=MeshInstance3D.new()
	var sphere=SphereMesh.new(); sphere.radius=.5; sphere.height=1; sphere.radial_segments=16; sphere.rings=8
	var mat=StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=.55
	ob.mesh=sphere; ob.material_override=mat; ob.position=at; ob.scale=dimensions
	parent.add_child(ob)
	return ob
func set_crop(ready_at:float,now:float):
	if active_room!="room_garden": return
	var phase=0 if ready_at<=0 else 4 if ready_at<=now else 1+clampi(int((1200-(ready_at-now))/400),0,2)
	if phase==crop_stage: return
	crop_stage=phase
	if is_instance_valid(garden_crop): world.remove_child(garden_crop); garden_crop.queue_free()
	garden_crop=Node3D.new(); world.add_child(garden_crop)
	if phase==0: return
	var growth=.26+float(phase)*.18
	for side in [-1,1]:
		for i in range(6):
			var x=side*3.1-.8+(i%3)*.8
			var z=-.5-floorf(float(i)/3.0)*.9
			crop_shape(garden_crop,Vector3(x,.97+growth*.32,z),Vector3(.10,growth,.10),Color("#5d9b44"))
			for j in range(4):
				var angle=float(j)*TAU/4
				var leaf=crop_shape(garden_crop,Vector3(x+cos(angle)*growth*.24,1.01+growth*.39,z+sin(angle)*growth*.24),Vector3(.18,growth*.40,.30),Color("#97d45a") if j%2==0 else Color("#59b867"))
				leaf.rotation.y=angle; leaf.rotation.x=.55
			if phase==4:
				for j in range(3):
					var angle=float(j)*TAU/3
					crop_shape(garden_crop,Vector3(x+cos(angle)*.20,1.17+growth*.42,z+sin(angle)*.20),Vector3(.17,.19,.17),Color("#ff628e"))
func set_pet(species:int,stage:int):
	if species==active_species and stage==active_stage: return
	active_species=species; active_stage=stage
	framing_key=""
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
	bare_bounds=mesh_bounds(avatar,Transform3D.IDENTITY)
	pet_fit=minf(1.0,2.3/maxf(0.1,maxf(bare_bounds.size.x,bare_bounds.size.y))) if species!=0 else 1.0
	var base=0.70 if stage==1 else 0.88 if stage==2 else 1.0
	avatar.scale=Vector3.ONE*base*1.65*pet_fit
	avatar.position.y=ground.y-sole_offset*avatar.scale.y
func mesh_bounds(node:Node,relative:Transform3D)->AABB:
	var result=AABB()
	var t=relative
	if node is Node3D and node!=avatar: t=relative*node.transform
	if node is MeshInstance3D and node.mesh!=null: result=t*node.get_aabb()
	for child in node.get_children():
		var b=mesh_bounds(child,t)
		if b.has_volume(): result=b if not result.has_volume() else result.merge(b)
	return result
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
# Face anchors are authored from the same dimensions as render_dash_creatures.py.
# Mosskit retains the exact approved runner geometry; clothing is a separate layer.
func face_anchor()->Vector3:
	if active_species==0: return Vector3(0,1.03,.68)
	if active_species>=24: return [Vector3(0,1.47,.79),Vector3(0,1.38,.67),Vector3(0,1.45,.80),Vector3(0,1.09,.56)][active_species-24]
	match active_species%12:
		1,2,10: return Vector3(0,1.50,.84)
		3,6: return Vector3(0,1.64,.85)
		4: return Vector3(0,1.12,.79)
		5: return Vector3(0,1.39,.76)
		7: return Vector3(0,1.32,.80)
		8,11: return Vector3(0,1.50,.77)
	return Vector3(0,1.50,.77)
func eye_spacing()->float:
	if active_species==0: return .58
	if active_species>=24: return [.60,.58,.60,.46][active_species-24]
	match active_species%12:
		3,6: return .68
		5: return .64
		4: return .60
		7: return .62
		8,11: return .56
	return .58
func fit_wearable(path:String,anchor:Vector3,factor:float)->Node3D:
	var ob=mesh(avatar,path,anchor)
	if ob==null: return null
	ob.scale=Vector3.ONE*factor
	wardrobe_nodes.append(ob)
	return ob
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
	incompatible_wearables=0
	if active_stage==0: return
	var eye=face_anchor()
	var family=active_species%12
	var aquatic=active_species==25 or (active_species>0 and active_species<24 and family in [4,7])
	var cap_y=1.66 if active_species==0 else eye.y+.52
	var anchors=[Vector3(0,cap_y,0.05),eye,Vector3(0,.49,.42),Vector3(0,.17,.32)]
	var scales=[.59,eye_spacing()/1.3,.53,.40]
	if active_species!=0:
		anchors[2]=Vector3(0,.62,.48)
		anchors[3]=Vector3(0,.16,.44)
	for slot in range(4):
		var id=int(worn[slot])
		if id<=0: continue
		# Fish and jellyfish have no legs to attach shoes to.
		if aquatic and slot==3:
			incompatible_wearables+=1
			continue
		var ob=fit_wearable("res://assets/wardrobe/clothes_%d.glb"%(id-1),anchors[slot],scales[slot])
		if ob!=null and slot==0:
			var bounds=mesh_bounds(ob,Transform3D.IDENTITY)
			var clearance=eye.y+.24-bounds.position.y
			if clearance>0: ob.position.y+=clearance
		if ob!=null and slot==2:
			var bounds=mesh_bounds(ob,Transform3D.IDENTITY)
			var overlap=bounds.end.y-(eye.y-.35)
			if overlap>0: ob.position.y-=overlap
	if equipped>0:
		var anchor=Vector3(0,cap_y+.12,0) if equipped==1 else Vector3(.53,eye.y+.37,.22) if equipped==2 else Vector3(0,bare_bounds.end.y+.20,0)
		var ob=fit_wearable("res://assets/wardrobe/item_%d.glb"%(equipped-1),anchor,.49)
		if ob!=null and equipped==3: ob.rotation.x=PI/2
func set_sleeping(value:bool):
	sleeping=value
func react(kind:String,asleep:bool):
	sleeping=asleep
	reaction_kind=kind
	reaction_time=1.15
	if kind in ["play","toy","bond","praise","train","daily","harvest","care_claim"]: touch_bounce=0.30
	for child in fx_root.get_children(): fx_root.remove_child(child); child.queue_free()
	fx_nodes.clear()
	if kind not in ["food","cook","snack","bond","play","toy","praise","daily","soap","rinse","harvest","craft","care_claim","clean","bath","toilet","cell","medicine"]: return
	var asset="coin" if kind in ["daily","harvest","care_claim"] else "reward_spark"
	for i in range(5):
		var ob:Node3D
		if kind in ["soap","rinse","bath"]:
			ob=crop_shape(fx_root,ground+Vector3(0,1.2,0),Vector3.ONE*.30,Color("#9edfff"))
		else: ob=mesh(fx_root,"res://assets/"+asset+".glb",ground+Vector3(0,1.2,0))
		if ob!=null:
			ob.scale=Vector3.ONE*(.34 if kind in ["soap","rinse","bath"] else .22)
			fx_nodes.append(ob)
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
	reaction_time=maxf(0,reaction_time-dt)
	for i in range(fx_nodes.size()):
		var ob=fx_nodes[i]
		if not is_instance_valid(ob): continue
		var t=1.0-reaction_time/1.15
		var a=float(i)*TAU/5+t*2.0
		ob.position=ground+Vector3(cos(a)*(0.5+t*0.7),1.1+t*1.9,sin(a)*0.5)
		ob.rotation.y+=dt*3
		ob.visible=reaction_time>0
	touch_bounce=maxf(0,touch_bounce-dt)
	avatar.rotation.y=lerpf(avatar.rotation.y,target_yaw+sin(elapsed*0.9)*0.055,minf(1,dt*5))
	var bounce=sin(touch_bounce/0.30*PI)*0.10
	if active_species==25: bounce+=.18+.06*sin(elapsed*2.5)
	var base=(0.70 if active_stage==1 else 0.88 if active_stage==2 else 1.0)*1.65*pet_fit
	var breathe=1.0+sin(elapsed*(1.7 if sleeping else 2.6))*0.014
	var chew=sin(reaction_time*24)*0.045 if reaction_time>0 and reaction_kind in ["food","cook","snack"] else 0.0
	avatar.scale=Vector3(base/breathe*(1+chew),base*breathe*(0.85 if sleeping else 1.0)*(1-chew),base/breathe)
	avatar.position=ground+Vector3(0,bounce-sole_offset*avatar.scale.y,0)
