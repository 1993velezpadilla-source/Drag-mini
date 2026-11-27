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
	# Stress the same quota helper used by the combat renderer.
	for casts in range(1,11):
		for capacity in range(145):
			for demand in [1,4,12,26,80,144]:
				var used:int=0
				for i in range(casts):
					var quota:int=view.cast_particle_quota(used,capacity,casts-i)
					if quota<0 or used+quota>capacity:failures.append("cast quota overflow")
					if capacity>=casts and quota<1:failures.append("cast starved")
					used+=mini(quota,demand)
					checks+=1
				if used>capacity:failures.append("cast capacity exceeded")
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
	# Exercise real controller hysteresis and loading-spike rejection.
	view.fx_performance_grace=0.0
	for i in range(120):view.update_fx_performance(1.0/60.0)
	if view.fx_performance_tier!=0:failures.append("healthy frame budget degraded")
	view.update_fx_performance(.8)
	if view.fx_performance_tier!=0:failures.append("isolated loading spike degraded")
	for i in range(100):view.update_fx_performance(.04)
	if view.fx_performance_tier!=2 or view.residue_particle_count()!=2:failures.append("sustained pressure not detected")
	for i in range(60):view.update_fx_performance(1.0/60.0)
	if view.fx_performance_tier!=2:failures.append("premature recovery")
	for i in range(600):view.update_fx_performance(1.0/60.0)
	if view.fx_performance_tier!=0 or view.residue_particle_count()!=4:failures.append("full quality did not recover")
	checks+=5
	# Catalog-wide real image smoke test, including native signatures.
	var catalog:Dictionary=Dungeon.Rules.MOVE_LIBRARY.duplicate()
	catalog.merge(Dungeon.Rules.DEV_NATIVE_MOVES)
	var elements:Dictionary={}
	for id in catalog:
		var profile:Dictionary=view.combat_profile(str(id))
		var move:Dictionary=catalog[id]
		elements[str(move.type)]=true
		if str(profile.element)!=str(move.type) or float(profile.duration)<=0.0 or float(profile.impact)<=0.0 or float(profile.impact)>=1.0:
			failures.append("invalid move profile: "+str(id))
		var image:Image=view.combat_frame_image(str(id),6)
		if image==null or image.get_width()!=48 or image.get_height()!=48 or not image.get_used_rect().has_area():
			failures.append("missing midpoint art: "+str(id))
		checks+=1
	if catalog.size()!=589 or elements.size()!=18:failures.append("catalog coverage changed")
	# Verify every explicit physical symbol resolves to a real catalog move
	# and all three stages contain nonempty 48px art.
	for id in Dungeon.CONTACT_ICON_KIND:
		if not catalog.has(id):failures.append("unknown contact icon move: "+str(id))
		var kind:String=str(Dungeon.CONTACT_ICON_KIND[id])
		for stage in range(3):
			var icon:Image=view.contact_icon_image(kind,stage,Color("#fff1bc"),Color("#926185"))
			if icon==null or icon.get_size()!=Vector2i(48,48) or not icon.get_used_rect().has_area():
				failures.append("empty physical contact icon: "+str(id))
			checks+=1
	# Each projectile reaches the actual path endpoint, even on bent routes.
	var route:Array=[Vector3(0,.5,0),Vector3(1.4,.5,0),Vector3(1.4,.5,2.8)]
	for id in Dungeon.PROJECTILE_IDENTITY:
		if not catalog.has(id):failures.append("unknown projectile: "+str(id))
		var kind:String=str(Dungeon.PROJECTILE_IDENTITY[id])
		var texture:=view.combat_pixel_texture("projectile_"+kind,Color("#ffe5ab"),Color("#946ac1"))
		if texture==null or not texture.get_image().get_used_rect().has_area():failures.append("empty projectile: "+str(id))
		for i in range(101):
			var t:float=float(i)/100.0
			var q:=view.projectile_identity_sample(kind,route,t,0.0)
			if not q.is_finite():failures.append("nonfinite projectile path")
			if i==0 and q.distance_to(route[0])>.001:failures.append("projectile launch offset")
			if i==100 and q.distance_to(route[-1])>.001:failures.append("projectile impact offset")
			checks+=1
	# Confirmed impacts must override failed primary targets without inventing damage.
	var impact_points:Array=[Vector3(0,.5,0),Vector3(1.4,.5,0)]
	var impact_burst:Dictionary={"points":impact_points,"results":{},"damage":0}
	if view.resolve_element_impact(impact_burst).kind!="terrain":failures.append("empty terrain misclassified")
	impact_burst.results={Vector2i(1,0):{"damage":0,"misses":1}}
	if view.resolve_element_impact(impact_burst).kind!="miss":failures.append("miss misclassified")
	impact_burst.results[Vector2i(2,0)]={"damage":8}
	var redirected:=view.resolve_element_impact(impact_burst)
	if redirected.kind!="confirmed" or redirected.tile!=Vector2i(2,0) or int(redirected.damage)!=8:failures.append("secondary hit not redirected")
	impact_burst.results[Vector2i(1,0)]={"effects":1}
	if view.resolve_element_impact(impact_burst).tile!=Vector2i(1,0):failures.append("primary status effect ignored")
	impact_burst.results={};impact_burst.damage=5
	if view.resolve_element_impact(impact_burst).kind!="confirmed":failures.append("legacy enemy damage ignored")
	impact_burst.results={Vector2i(1,0):{"damage":0,"misses":1}}
	if view.resolve_element_impact(impact_burst).kind!="miss":failures.append("explicit miss overridden by aggregate damage")
	checks+=6
	# All status contracts select a nonempty semantic glyph.
	var status_count:int=0
	for id in Dungeon.Rules.MOVE_LIBRARY:
		var move:Dictionary=Dungeon.Rules.MOVE_LIBRARY[id]
		if str(move.category)!="status":continue
		status_count+=1
		var kind:String=view.status_finish_kind(move)
		if not Dungeon.STATUS_FINISH_STYLE.has(kind):
			failures.append("missing status finish: "+str(id))
			continue
		var style:Array=Dungeon.STATUS_FINISH_STYLE[kind]
		var texture:=view.combat_pixel_texture(str(style[0]),Color(style[1]),Color(style[2]))
		if texture==null or not texture.get_image().get_used_rect().has_area():failures.append("empty status glyph: "+str(id))
		checks+=1
	if status_count!=177:failures.append("status catalog changed")
	if view.status_finish_kind({"category":"status","stat_changes":{"attack":2}})!="boost":failures.append("boost classification")
	if view.status_finish_kind({"category":"status","stat_changes":{"defense":-1}})!="weaken":failures.append("weaken classification")
	if view.status_finish_kind({"category":"status","heal_fraction":.5})!="heal":failures.append("heal classification")
	if view.status_finish_kind({"category":"status","shield_kind":"protect"})!="shield":failures.append("shield classification")
	checks+=4
	# Ultimate presentation is bounded and only refers to actual damage moves.
	for id in Dungeon.ULTIMATE_ACCENTS:
		if not catalog.has(id) or str(catalog[id].category)=="status":failures.append("invalid ultimate accent: "+str(id))
		for i in range(101):
			var p:float=float(i)/100.0
			var envelope:Vector2=view.ultimate_envelope(p)
			if not envelope.is_finite() or envelope.x<-.0001 or envelope.x>1.001 or envelope.y<0.0 or envelope.y>1.001:failures.append("invalid cinematic envelope")
			if i==100 and envelope.length()>.001:failures.append("ultimate effect never expires")
			checks+=1
	# Outbound and return legs use exactly the original tile route.
	var movement_route:Array=[Vector3.ZERO,Vector3(1.4,0,0),Vector3(1.4,0,2.8)]
	for kind in ["air","ground","burrow","dive","vanish"]:
		for peak in [.4,.48,.64]:
			var launch:=view.tile_cast_sample(movement_route,kind,0.0,peak)
			var contact:=view.tile_cast_sample(movement_route,kind,peak,peak)
			var landing:=view.tile_cast_sample(movement_route,kind,1.0,peak)
			if Vector3(contact.position).distance_to(movement_route[-1])>.001 or not bool(contact.visible):failures.append("tile cast contact failed")
			if Vector3(landing.position).distance_to(movement_route[0])>.001 or not bool(landing.visible):failures.append("tile cast return failed")
			if kind in ["burrow","dive","vanish"] and bool(launch.visible):failures.append("concealed cast visible at launch")
			for i in range(101):
				var t:float=float(i)/100.0
				var motion_sample:=view.tile_cast_sample(movement_route,kind,t,peak)
				if not Vector3(motion_sample.position).is_finite() or float(motion_sample.path_progress)<0.0 or float(motion_sample.path_progress)>1.0:failures.append("invalid tile cast trajectory")
				checks+=1
	# Every nature has a visible, bounded environmental stamp and a finite fade.
	if Dungeon.SURFACE_STAMP.size()!=18:failures.append("surface stamp nature coverage")
	var silhouettes:Dictionary={}
	for element in Dungeon.SURFACE_STAMP:
		var ink:=view.surface_stamp_palette(element)
		var mode:String="surface_"+str(Dungeon.SURFACE_STAMP[element])
		var texture:=view.combat_pixel_texture(mode,ink[0],ink[1])
		if texture==null or not texture.get_image().get_used_rect().has_area():
			failures.append("empty surface stamp: "+str(element))
		var shape:=view.combat_pixel_texture(mode,Color.WHITE,Color.BLACK)
		silhouettes[mode]=shape.get_image().get_data()
		for step in range(101):
			var phase:float=float(step)/100.0
			var sample:Vector3=view.surface_stamp_sample(element,phase)
			if not sample.is_finite() or sample.x<=0.0 or sample.x>2.0 or sample.y<0.0 or sample.y>1.001 or sample.z<-.0001 or sample.z>1.001:
				failures.append("invalid surface envelope: "+str(element))
			if step==100 and absf(sample.y)>.0001:failures.append("surface stamp did not expire")
			checks+=1
	if silhouettes.size()!=12:failures.append("surface silhouette coverage")
	var modes:Array=silhouettes.keys()
	for i in range(modes.size()):
		for j in range(i+1,modes.size()):
			if silhouettes[modes[i]]==silhouettes[modes[j]]:failures.append("duplicate ground stamp")
			checks+=1
	# Anticipation and drive use exactly the same authored impact time.
	for peak in [.12,.34,.48,.64,.88]:
		var windup:=view.attack_direction_sample(peak*.17,peak)
		var contact:=view.attack_direction_sample(peak,peak)
		if windup.x<.99 or absf(windup.y)>.001:failures.append("missing anticipation")
		if absf(contact.y-1.0)>.001 or absf(contact.x)>.001:failures.append("contact clock mismatch")
		for kind in ["rush","contact","lash","aerial","down","spin","focus","gesture","cast"]:
			for step in range(101):
				var phase:float=float(step)/100.0
				var sample:=view.cast_motion_offset(kind,phase,peak)
				if not sample.is_finite() or sample.length()>1.0:failures.append("invalid cast direction")
				if step in [0,100] and sample.length()>.001:failures.append("cast offset did not return to neutral")
				checks+=1
	for step in range(101):
		var phase:float=float(step)/100.0
		var value:float=view.contact_camera_sample(phase)
		if not is_finite(value) or absf(value)>1.0:failures.append("unbounded camera impulse")
		if step in [0,100] and absf(value)>.001:failures.append("camera impulse endpoint")
		checks+=1
	# Directed contact art is independently visible and kick poses are animated.
	for id in Dungeon.CONTACT_ICON_KIND:
		var kind:String=view.directed_contact_kind(id,str(view.combat_profile(id).role))
		var previous:PackedByteArray=[]
		for stage in range(3):
			var image:Image=view.contact_icon_image(kind,stage,Color("#fff1bc"),Color("#926185"))
			if not image.get_used_rect().has_area():failures.append("empty directed contact: "+str(id))
			if kind.begins_with("kick") and stage>0 and image.get_data()==previous:failures.append("static kick pose: "+str(id))
			previous=image.get_data()
			checks+=1
	var contact_tile:=Vector2i(1,0)
	var contact_burst:Dictionary={"duration":.6,"age":.21,"impact_times":[.2,.3,.4],"impact_cursor":1,"impact_waves":[{contact_tile:{"damage":7}},{contact_tile:{"damage":0,"misses":1}},{contact_tile:{"damage":9}}]}
	var first_contact:=view.contact_wave_sample(contact_burst)
	if first_contact.is_empty() or int(first_contact.results[contact_tile].damage)!=7:failures.append("first contact wave")
	contact_burst.age=.31;contact_burst.impact_cursor=2
	var missed_contact:=view.contact_wave_sample(contact_burst)
	if missed_contact.is_empty() or int(missed_contact.results[contact_tile].damage)!=0:failures.append("intermediate miss lost")
	contact_burst.age=.41;contact_burst.impact_cursor=3
	var last_contact:=view.contact_wave_sample(contact_burst)
	if last_contact.is_empty() or int(last_contact.results[contact_tile].damage)!=9:failures.append("third contact wave")
	contact_burst.age=.60
	if not view.contact_wave_sample(contact_burst).is_empty():failures.append("contact did not expire")
	checks+=4
	# Validate actual authored projectile forms on the same bent route as the
	# existing family tests, including finite lagged samples and budget limits.
	var directed_forms:Dictionary={}
	for id in Dungeon.PROJECTILE_IDENTITY:
		var form:=view.directed_projectile_form(id,str(view.combat_profile(id).role))
		directed_forms[form]=true
	for role in Dungeon.PROJECTILE_ROLE_FORM:
		directed_forms[Dungeon.PROJECTILE_ROLE_FORM[role]]=true
	for form in directed_forms:
		var texture:=view.combat_pixel_texture("projectile_"+str(form),Color("#ffe5ab"),Color("#946ac1"))
		if texture==null or not texture.get_image().get_used_rect().has_area():failures.append("empty directed projectile: "+str(form))
		var budget:=view.projectile_form_profile(form)
		if not budget.is_finite() or budget.x<=0.0 or budget.y<=0.0 or budget.z<1.0 or budget.z>5.0:failures.append("invalid projectile budget")
		for i in range(101):
			var phase:float=float(i)/100.0
			var head:=view.projectile_identity_sample(form,route,phase,0.0)
			var tail:=view.projectile_identity_sample(form,route,phase,budget.y)
			if not head.is_finite() or not tail.is_finite():failures.append("nonfinite directed projectile")
			if i==0 and head.distance_to(route[0])>.001:failures.append("directed launch mismatch")
			if i==100 and head.distance_to(route[-1])>.001:failures.append("directed impact mismatch")
			checks+=1
	# Directed impact shapes and envelopes must be valid across every nature.
	var impact_forms:Dictionary={}
	for element in Dungeon.IMPACT_ELEMENT_FORM:
		impact_forms[Dungeon.IMPACT_ELEMENT_FORM[element]]=true
	for role in Dungeon.IMPACT_ROLE_FORM:
		impact_forms[Dungeon.IMPACT_ROLE_FORM[role]]=true
	if Dungeon.IMPACT_ELEMENT_FORM.size()!=18 or impact_forms.size()!=21:failures.append("impact form coverage")
	for form in impact_forms:
		var texture:=view.combat_pixel_texture("impact_"+str(form),Color("#ffe5ab"),Color("#946ac1"))
		if texture==null or not texture.get_image().get_used_rect().has_area():failures.append("empty directed impact: "+str(form))
		for i in range(101):
			var phase:float=float(i)/100.0
			var sample:=view.directed_impact_sample(form,phase)
			if not sample.is_finite() or sample.x<0.0 or sample.y<-.0001 or sample.z<0.0 or sample.z>1.001:failures.append("invalid impact envelope")
			if i==100 and absf(sample.z)>.0001:failures.append("impact failed to expire")
			checks+=1
	if view.directed_impact_sample("implosion",.8).x>=view.directed_impact_sample("implosion",.2).x:failures.append("implosion does not contract")
	if view.directed_impact_sample("detonation",.8).x<=view.directed_impact_sample("detonation",.2).x:failures.append("detonation does not expand")
	var impact_test:Dictionary={"points":[Vector3.ZERO,Vector3(1.4,.6,0)],"damage":16,"results":{Vector2i(1,0):{"damage":16}},"impact_waves":[{Vector2i(1,0):{"damage":0,"misses":1}},{Vector2i(1,0):{"damage":16}}],"impact_cursor":1}
	if view.resolve_element_impact(view.impact_visual_view(impact_test)).kind!="miss":failures.append("future hit leaked into miss")
	impact_test.impact_cursor=2
	if view.resolve_element_impact(view.impact_visual_view(impact_test)).kind!="confirmed":failures.append("confirmed wave lost")
	checks+=4
	var home:=Home.new()
	home.free()
	view.free()
	print("CINEMATIC_GAUNTLET checks=",checks," failures=",failures.size())
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
