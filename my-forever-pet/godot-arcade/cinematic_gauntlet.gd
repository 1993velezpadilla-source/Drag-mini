extends SceneTree
# Run after import: godot --headless --path . --script res://cinematic_gauntlet.gd
const Art=preload("res://pixel_pet_art.gd")
const Dungeon=preload("res://dungeon_view.gd")
const Home=preload("res://live_pet_stage.gd")

func _initialize()->void:
	call_deferred("run_checks")

func run_checks()->void:
	var checks:int=0
	var failures:Array[String]=[]
	var view:=Dungeon.new()
	for species in Art.ENEMY_PIXEL_PILOTS:
		for dir in range(8):
			var idle:=Art.enemy_pixel_texture(species,dir,"idle",0)
			if idle==null:
				failures.append("missing idle: "+species)
				continue
			if idle!=Art.enemy_pixel_texture(species,dir,"idle",42):
				failures.append("noncanonical idle: "+species)
			for part in range(3):
				for blink in [false,true]:
					var texture:=Art.enemy_pixel_texture(species,dir,"idle",0,blink,part)
					if texture==null or texture.get_width()!=48 or texture.get_height()!=48:
						failures.append("bad expression dimensions: "+species)
					checks+=1
			var hurt:=Art.enemy_pixel_texture(species,dir,"hurt",0)
			if hurt==null or hurt!=Art.enemy_pixel_texture(species,dir,"hurt",4,true,2):
				failures.append("combat cache priority: "+species)
			checks+=2
		for i in range(101):
			var t:float=float(i)/100.0
			var hit:Dictionary=view.creature_hit_sample(t,species)
			var idle_sample:Vector3=view.creature_idle_sample(species,t*10.0,.7,1.0,true)
			if float(hit.squash)<.7 or float(hit.squash)>1.3 or absf(idle_sample.x-1.0)>.04:
				failures.append("motion out of bounds: "+species)
			checks+=1
		# Exercise real Sprite3D actors and the actual state update code.
		var actor:=Node3D.new()
		root.add_child(actor)
		if not view.attach_enemy_pixel(actor,species):
			failures.append("attach enemy failed: "+species)
			actor.free()
			continue
		var sprite:=actor.get_node("EnemyPixel") as Sprite3D
		var shadow:=actor.get_node("EnemyContactShadow") as MeshInstance3D
		actor.set_meta("native_hp_ratio",.15)
		for i in range(30):
			view.elapsed+=1.0/60.0
			view.update_enemy_pixel(actor,1.0/60.0,Vector3.ZERO)
			if not sprite.scale.is_finite() or not sprite.position.is_finite():
				failures.append("invalid idle actor: "+species)
			checks+=1
		actor.set_meta("native_alert",true)
		view.update_enemy_pixel(actor,1.0/60.0,Vector3.ZERO)
		if sprite.texture!=Art.enemy_pixel_texture(species,0,"windup",0):
			failures.append("alert pose not applied: "+species)
		checks+=1
		actor.set_meta("native_alert",false)
		actor.set_meta("living_statuses",["sleep"])
		for i in range(30):
			view.update_enemy_pixel(actor,1.0/60.0,Vector3.ZERO)
		if sprite.texture!=Art.enemy_pixel_texture(species,0,"sleep",0):
			failures.append("sleep pose not applied: "+species)
		checks+=1
		actor.set_meta("living_statuses",[])
		view.enemy_pose(actor,"hurt",.24)
		view.update_enemy_pixel(actor,.08,Vector3.ZERO)
		if sprite.texture!=Art.enemy_pixel_texture(species,0,"hurt",0):
			failures.append("hurt did not override sleep: "+species)
		checks+=1
		view.enemy_pose(actor,"defeat",.32)
		view.update_enemy_pixel(actor,.25,Vector3.ZERO)
		if sprite.scale.y>=1.0 or shadow.scale.x>=1.45:
			failures.append("defeat collapse missing: "+species)
		checks+=1
		view.update_enemy_pixel(actor,.10,Vector3.ZERO)
		if not actor.is_queued_for_deletion() or actor.visible:
			failures.append("defeat cleanup missing: "+species)
		checks+=1
		# Deferred deletion avoids freeing a queued node twice.
	for capacity in range(65):
		var demands:Array[int]=[1,4,9,16,20,32]
		var budgets:Array[int]=view.living_particle_budgets(demands,capacity)
		var total:int=0
		for i in range(demands.size()):
			total+=budgets[i]
			if budgets[i]<0 or budgets[i]>demands[i]:failures.append("particle budget overflow")
		if total!=capacity:failures.append("particle budget conservation")
		checks+=1
	for i in range(101):
		var form:Vector3=view.form_effect_sample(float(i)/100.0)
		if form.x<.129 or form.x>1.051 or form.y<-.001 or form.y>1.001:
			failures.append("form envelope")
		checks+=1
	var home:=Home.new()
	home.free()
	view.free()
	print("CINEMATIC_GAUNTLET checks=",checks," failures=",failures.size())
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
