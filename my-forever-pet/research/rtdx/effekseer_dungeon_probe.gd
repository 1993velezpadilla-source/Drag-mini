extends SceneTree
const Field=preload("res://dungeon_view.gd")
const Backend=preload("res://dungeon_effekseer_backend.gd")
func _initialize()->void:call_deferred("run")
func frames()->void:
	await process_frame
	await RenderingServer.frame_post_draw
func run()->void:
	var field=Field.new()
	root.add_child(field)
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field.setup(0,1,0,false,true,902,24)
	field.set_process(false)
	for i in range(4):await frames()
	var backend=Backend.new()
	field.combat_fx_root.add_child(backend)
	assert(backend.prepare(),"native extension missing")
	var origin:Vector2i=field.run.player
	var target:Vector2i=origin+Vector2i.RIGHT
	var points:Array=[field.pos(origin)+Vector3.UP*.55,field.pos(target)+Vector3.UP*.55]
	var cases:Array=[
		["lib_fire_2","sample-material3/ef_fire01_projectile.efkefc","sample-material3/ef_fire01.efkefc",.36,.36],
		["lib_ice_2","sample-material3/ef_ice02.efkefc","sample-material3/ef_ice01.efkefc",.30,.30],
		["lib_electric_2","sample-material3/ef_lightning02.efkefc","sample-material3/ef_lightning01.efkefc",.22,.22],
		["lib_flying_2","sample-material3/ef_wind02.efkefc","sample-material3/ef_wind01.efkefc",.30,.30],
		["lib_water_2","sample-material2/ToonWater.efkefc","sample-material2/ToonWater.efkefc",.035,.035]]
	for row in cases:
		var id:String=row[0]
		var profile:Dictionary=field.combat_profile(id)
		var tracks:Array=field.elemental_track_plan(id,profile)
		var travel:Dictionary=tracks[3] if tracks[3].enabled else tracks[2]
		var impact:Dictionary=tracks[5]
		var projectile:Resource=load("res://effects/"+str(row[1]))
		var hit:Resource=load("res://effects/"+str(row[2]))
		assert(projectile!=null and hit!=null)
		backend.reset()
		field.combat_bursts.clear()
		field.combat_fx_update(0.0)
		var i:int=backend.launch(travel,projectile,points,[points[-1]],float(row[3]),1.0)
		assert(i>=0)
		for frame in range(24):
			backend.advance(.99/24.0)
			await frames()
			if frame in [8,16,23]:assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/dungeon-"+id+"-travel-"+str(frame)+".png")==OK)
		backend.reset()
		var j:int=backend.launch(impact,hit,points,[points[-1]],float(row[4]),1.0)
		assert(j>=0)
		assert(backend.slots[j].node.position.distance_to(points[-1])<.001)
		for frame in range(30):
			backend.advance(.016)
			await frames()
			if frame in [8,16,23]:assert(root.get_texture().get_image().save_png("/tmp/effekseer-review/dungeon-"+id+"-impact-"+str(frame)+".png")==OK)
		backend.reset()
		print("KINDRIA_EFFEKSEER_TRACKS ",id)
	# Independent clocks, uneven segment distances, capacity and reuse.
	var effect:Resource=load("res://effects/sample-material3/ef_fire01_projectile.efkefc")
	var track:Dictionary={"enabled":true,"anchor":"path"}
	var path:Array=[Vector3.ZERO,Vector3.RIGHT,Vector3.RIGHT*4.0]
	var slow:int=backend.launch(track,effect,path,[],.2,2.0)
	var fast:int=backend.launch(track,effect,path,[],.2,1.0)
	assert(slow>=0 and fast>=0 and slow!=fast)
	backend.advance(.5)
	assert(backend.slots[slow].node.position.distance_to(Vector3.RIGHT)<.001,"slow clock and uneven segment")
	assert(backend.slots[fast].node.position.distance_to(Vector3.RIGHT*2.0)<.001,"fast clock independent")
	backend.advance(.5)
	assert(not backend.slots[fast].busy and backend.slots[slow].busy)
	for index in range(Backend.SLOT_CAP-1):assert(backend.launch(track,effect,path,[],.2,1.0)>=0)
	assert(backend.launch(track,effect,path,[],.2,1.0)==-1,"overflow is rejected")
	backend.reset()
	assert(backend.prepare() and backend.slots.size()==Backend.SLOT_CAP,"pool initialization idempotent")
	print("KINDRIA_EFFEKSEER_CONCURRENT_PASS")
	var plan:Array=[
		{"stage":"ally_invoke","anchor":"source","start":0.0,"end":.15,"enabled":true},
		{"stage":"enemy_invoke","anchor":"source","start":0.0,"end":.15,"enabled":true},
		{"stage":"projectile","anchor":"path","start":.2,"end":.6,"enabled":true},
		{"stage":"impact","anchor":"target","start":.6,"end":1.0,"enabled":true}]
	var bindings:Dictionary={}
	for track_row in plan:bindings[track_row.stage]={"effect":effect,"scale":.2}
	assert(backend.schedule_cast(plan,bindings,path,[],1.0,true,false)==2)
	assert(backend.pending[0].track.stage=="enemy_invoke")
	backend.advance(.1)
	assert(backend.pending.size()==1)
	backend.advance(.2)
	assert(backend.pending.is_empty())
	var traveling:bool=false
	for slot in backend.slots:
		if slot.busy and slot.follows:
			traveling=true
			assert(slot.node.position.distance_to(Vector3.RIGHT)<.001,"late frame advances correct path fraction")
	assert(traveling)
	backend.advance(.5)
	for slot in backend.slots:assert(not slot.busy)
	assert(backend.schedule_cast(plan,bindings,path,[],1.0,false,true)==3)
	assert(backend.pending[0].track.stage=="ally_invoke")
	backend.reset()
	assert(backend.pending.is_empty())
	print("KINDRIA_EFFEKSEER_TIMELINE_PASS")
	assert(backend.slots.size()==Backend.SLOT_CAP)
	for slot in backend.slots:assert(not slot.busy)
	print("KINDRIA_EFFEKSEER_DUNGEON_PASS 5")
	quit(0)
