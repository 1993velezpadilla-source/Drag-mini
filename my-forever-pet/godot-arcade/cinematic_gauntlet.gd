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
	# Body deformation must peak on the same frame as the directional drive,
	# including very short anticipation windows and downward strikes.
	for peak in [.12,.34,.48,.64,.88]:
		for kind in ["rush","contact","lash","aerial","down","spin","focus","gesture","cast"]:
			var contact_body:=Art.attack_body_sample(peak,peak,kind)
			var previous_body:=Art.attack_body_sample(0.0,peak,kind)
			for step in range(101):
				var phase:float=float(step)/100.0
				var body:=Art.attack_body_sample(phase,peak,kind)
				var stretch:float=float(body.stretch)
				if not is_finite(stretch) or stretch<.84 or stretch>1.16 or float(body.lift)<0.0:failures.append("invalid continuous body")
				if step in [0,100] and (absf(stretch-1.0)>.001 or absf(float(body.lift))>.001):failures.append("body rest mismatch")
				if kind!="down" and stretch>float(contact_body.stretch)+.001:failures.append("extension after contact")
				if absf(stretch-float(previous_body.stretch))>.13:failures.append("body transition jump")
				previous_body=body
				checks+=1
			var before:=Art.attack_body_sample(peak-.0001,peak,kind)
			var after:=Art.attack_body_sample(peak+.0001,peak,kind)
			if absf(float(before.stretch)-float(after.stretch))>.001:failures.append("body contact discontinuity")
			if kind in ["aerial","down"]:
				var landed:=view.cast_motion_offset(kind,peak,peak)
				var near_landing:=view.cast_motion_offset(kind,peak-.0001,peak)
				if absf(landed.y)>.0001 or absf(near_landing.y)>.0001:failures.append("abrupt landing")
			checks+=1
	# Anatomical casts retain bounded continuous geometry, with a unique
	# contact position/deformation signature per motion family.
	var anatomy_kinds:Array=["fang","crunch","claw","pincer","punch","uppercut","kick","lowkick","wing","tail","horn"]
	var anatomy_signatures:Dictionary={}
	for kind in anatomy_kinds:
		var at_contact:=view.cast_motion_offset(kind,.48,.48)
		var body_contact:=Art.attack_body_sample(.48,.48,kind)
		var signature:=str(at_contact)+str(body_contact)
		if anatomy_signatures.has(signature):failures.append("duplicate anatomy "+kind)
		anatomy_signatures[signature]=true
		for peak in [.12,.34,.48,.64,.88]:
			for step in range(101):
				var phase:float=float(step)/100.0
				var motion:=view.cast_motion_offset(kind,phase,peak)
				var body:=Art.attack_body_sample(phase,peak,kind)
				if not motion.is_finite() or motion.length()>1.0 or float(body.stretch)<.84 or float(body.stretch)>1.16:failures.append("anatomical motion bounds "+kind)
				if step in [0,100] and (motion.length()>.001 or absf(float(body.stretch)-1.0)>.001):failures.append("anatomical motion rest "+kind)
				checks+=1
	var anatomy_expected:Dictionary={"eos_063":"fang","eos_062":"crunch","eos_065":"punch","eos_092":"lowkick","eos_136":"uppercut","eos_008":"contact","eos_153":"aerial","eos_205":"aerial"}
	for id in anatomy_expected:
		if view.cast_motion_kind(id,view.combat_profile(id))!=anatomy_expected[id]:failures.append("incorrect anatomical cast "+id)
		checks+=1
	# Every creature owns a distinct authored response, without changing the
	# neutral endpoints or tile-based travel rules.
	var creature_signatures:Dictionary={}
	for species in Art.ENEMY_PIXEL_PILOTS:
		var anatomy:=Art.creature_cast_profile(species)
		if not Art.CREATURE_CAST_PROFILES.has(species):failures.append("missing creature cast profile "+species)
		if creature_signatures.has(str(anatomy)):failures.append("duplicate creature cast profile "+species)
		creature_signatures[str(anatomy)]=true
		for kind in ["rush","contact","lash","aerial","down","spin","focus","gesture","cast","fang","crunch","claw","pincer","punch","uppercut","kick","lowkick","wing","tail","horn"]:
			for step in range(101):
				var phase:float=float(step)/100.0
				var motion:=Art.creature_cast_offset(view.cast_motion_offset(kind,phase,.48),species)
				var body:=Art.attack_body_sample(phase,.48,kind,species)
				if not motion.is_finite() or motion.length()>1.0 or float(body.stretch)<.78 or float(body.stretch)>1.22 or float(body.lift)<0.0:failures.append("creature cast bounds "+species+" "+kind)
				if step in [0,100] and (motion.length()>.001 or absf(float(body.stretch)-1.0)>.001 or absf(float(body.lift))>.001):failures.append("creature cast endpoint "+species+" "+kind)
				checks+=1
	if creature_signatures.size()!=Art.ENEMY_PIXEL_PILOTS.size():failures.append("creature profile coverage")
	if Art.creature_cast_profile("")!=Vector4.ONE:failures.append("neutral companion profile")
	# Native anatomical strike cells must differ from their base art, while
	# incompatible imported atlases remain protected by the expression guard.
	var anatomy_visible:int=0
	var anatomy_visibility:Dictionary={}
	if Art.ENEMY_COMBAT_APPENDAGES.size()!=33 or Art.ENEMY_COMBAT_APPENDAGES.size()!=Art.ENEMY_PIXEL_PILOTS.size():failures.append("full anatomy registry coverage")
	for species in Art.ENEMY_PIXEL_PILOTS:
		if not species in Art.ENEMY_COMBAT_APPENDAGES:failures.append("missing anatomical species "+species)
	for species in Art.ENEMY_COMBAT_APPENDAGES:
		var species_changed:bool=false
		var species_visible:int=0
		for direction in range(8):
			var base:=Art.enemy_pixel_cell(species,direction,"attack",1,false,0)
			var first:=Art.enemy_pixel_cell(species,direction,"attack",1,false,1)
			var second:=Art.enemy_pixel_cell(species,direction,"attack",1,false,2)
			if base.get_size()!=Vector2i(48,48) or first.get_size()!=base.get_size() or second.get_size()!=base.get_size() or not first.get_used_rect().has_area() or not second.get_used_rect().has_area():
				failures.append("invalid combat appendage cell "+species)
			if first.get_data()!=second.get_data():species_changed=true
			var native_texture:=Art.enemy_pixel_texture(species,direction,"attack",1,false,0)
			var attack_texture:=Art.enemy_pixel_texture(species,direction,"attack",1,false,1)
			var recovery_texture:=Art.enemy_pixel_texture(species,direction,"attack",1,false,2)
			if native_texture==null or attack_texture==null or recovery_texture==null:failures.append("missing native combat appendage "+species)
			elif attack_texture!=native_texture or recovery_texture!=native_texture:
				anatomy_visible+=1
				species_visible+=1
			for pose in ["windup","recover","defeat","sleep"]:
				if Art.enemy_pixel_texture(species,direction,pose,0,false,2)!=Art.enemy_pixel_texture(species,direction,pose,0,false,0):failures.append("combat part overrides "+pose+" "+species)
				checks+=1
			if Art.enemy_pixel_texture(species,direction,"hurt",0,false,2)!=Art.enemy_pixel_texture(species,direction,"hurt",0,false,0):failures.append("appendage overrides hurt "+species)
			checks+=1
		if not species_changed:failures.append("static native appendage "+species)
		anatomy_visibility[species]=species_visible
	for peak in [.12,.34,.48,.64,.88]:
		if Art.combat_appendage_stage(peak-.0001,peak)!=0 or Art.combat_appendage_stage(peak,peak)!=1 or Art.combat_appendage_stage(peak+(1.0-peak)*.30,peak)!=2 or Art.combat_appendage_stage(1.0,peak)!=0:failures.append("appendage phase contract")
		checks+=1
	print("KINDRIA_COMBAT_APPENDAGES species=",Art.ENEMY_COMBAT_APPENDAGES.size()," visible_direction_variants=",anatomy_visible)
	print("KINDRIA_ANATOMY_VISIBILITY ",JSON.stringify(anatomy_visibility))
	# Attack-specific slots must resolve to existing native anatomy only.
	var slot_routes:int=0
	for species in Art.ENEMY_PIXEL_PILOTS:
		if not Art.COMBAT_ANATOMY_SLOTS.has(species):failures.append("missing anatomy slot registry "+species)
		for motion in Art.MOTION_ANATOMY:
			var slot:String=Art.combat_anatomy_slot(species,motion)
			if not slot.is_empty() and not slot in Art.COMBAT_ANATOMY_SLOTS.get(species,[]):failures.append("unsupported anatomy slot "+species)
			if not slot.is_empty():slot_routes+=1
			checks+=1
	var targeted_cases:Dictionary={"tidal_sovereign":["jaw","tail"],"vinesnap":["jaw","leaf"],"fungal_monarch":["aura","limbs"],"marrowray":["wing","tail"],"rootgnawer":["horn","legs"]}
	for species in targeted_cases:
		var slots:Array=targeted_cases[species]
		var distinct:bool=false
		for direction in range(8):
			var left:=Art.enemy_pixel_cell(species,direction,"attack",1,false,2,str(slots[0]))
			var right:=Art.enemy_pixel_cell(species,direction,"attack",1,false,2,str(slots[1]))
			if left.get_data()!=right.get_data():distinct=true
			var plain:=Art.enemy_pixel_texture(species,direction,"attack",1)
			var unsupported:=Art.enemy_pixel_texture(species,direction,"attack",1,false,2,"unavailable")
			if plain!=unsupported:failures.append("unsupported anatomy allocated variant "+species)
			checks+=1
		if not distinct:failures.append("identical targeted anatomy "+species)
	if Art.combat_anatomy_slot("tidal_sovereign","crunch")!="jaw" or Art.combat_anatomy_slot("tidal_sovereign","tail")!="tail" or Art.combat_anatomy_slot("comet_hare","kick")!="legs" or not Art.combat_anatomy_slot("nova_wisp","punch").is_empty():failures.append("incorrect anatomical routing")
	checks+=4
	print("KINDRIA_ATTACK_ANATOMY routes=",slot_routes," multislot_species=",targeted_cases.size())

	# Body timing shares the actual attempts ledger (including misses), not
	# a guessed nominal hit count. Each segment returns to neutral.
	var wave_event:Dictionary={"results":{Vector2i(1,0):{"damage":9,"attempts":[{"damage":3},{"damage":0,"misses":1},{"damage":6}]}}}
	for duration in [.18,.44,.8,1.2]:
		for peak in [.12,.34,.48,.64,.88]:
			var times:=view.caster_wave_times(wave_event,duration,peak)
			if times!=view.reaction_times(duration,peak,3):failures.append("caster attempt timing mismatch")
			for time in times:
				var progress:float=view.caster_wave_progress(time,duration,peak,times)
				if absf(progress-peak)>.0001:failures.append("caster wave contact mismatch")
				var body:=Art.attack_body_sample(progress,peak,"punch")
				var expected:=Art.attack_body_sample(peak,peak,"punch")
				if absf(float(body.stretch)-float(expected.stretch))>.0001:failures.append("caster deformation not at impact")
				checks+=1
			for i in range(times.size()-1):
				var midpoint:float=(times[i]+times[i+1])*.5
				var before:=view.cast_motion_offset("punch",view.caster_wave_progress(midpoint-.000001,duration,peak,times),peak)
				var after:=view.cast_motion_offset("punch",view.caster_wave_progress(midpoint+.000001,duration,peak,times),peak)
				if before.distance_to(after)>.001:failures.append("multi-hit body boundary discontinuity")
				checks+=1
			for step in range(101):
				var time:float=duration*float(step)/100.0
				var progress:float=view.caster_wave_progress(time,duration,peak,times)
				if not is_finite(progress) or progress<0.0 or progress>1.0:failures.append("invalid caster wave clock")
				if absf(view.caster_wave_progress(time,duration,peak,[])-float(step)/100.0)>.0001:failures.append("single-hit body clock changed")
				checks+=1
			if view.caster_wave_progress(0.0,duration,peak,times)!=0.0 or view.caster_wave_progress(duration,duration,peak,times)!=1.0:failures.append("caster wave endpoints")
			checks+=1
	# Critical finish is local to the active wave and actual damage row.
	var critical_tile:=Vector2i(1,0)
	var normal_tile:=Vector2i(2,0)
	var critical_burst:Dictionary={"duration":.8,"age":.2,"impact_cursor":1,"impact_times":[.2,.4,.6],"impact_waves":[{critical_tile:{"damage":7,"crit":0}},{critical_tile:{"damage":9,"crit":1},normal_tile:{"damage":6,"crit":0}},{critical_tile:{"damage":0,"crit":1,"misses":1}}]}
	if not view.critical_impact_tiles(critical_burst).is_empty():failures.append("future critical leak")
	critical_burst.age=.4;critical_burst.impact_cursor=2
	if view.critical_impact_tiles(critical_burst)!=[critical_tile]:failures.append("critical target isolation")
	critical_burst.age=.59
	if not view.critical_impact_tiles(critical_burst).is_empty():failures.append("expired critical flash")
	critical_burst.age=.6;critical_burst.impact_cursor=3
	if not view.critical_impact_tiles(critical_burst).is_empty():failures.append("false critical on miss")
	checks+=4
	var critical_texture:=view.combat_pixel_texture("critical_flash",Color("#fff3c2"),Color("#e0a34c"))
	if critical_texture==null or not critical_texture.get_image().get_used_rect().has_area():failures.append("empty critical flash")
	checks+=1
	var prior_flash:float=1.0
	var prior_ring:float=0.0
	for step in range(101):
		var critical_sample:=view.critical_finish_sample(float(step)/100.0)
		if not critical_sample.is_finite() or critical_sample.x<0.0 or critical_sample.x>prior_flash+.0001 or critical_sample.y<prior_ring-.0001 or critical_sample.y>1.47:failures.append("critical envelope")
		if step==100 and critical_sample.x>.0001:failures.append("critical flash not expired")
		prior_flash=critical_sample.x;prior_ring=critical_sample.y
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
	# All elemental materials select finite, bounded parameters for the pooled shader.
	var families:Dictionary={}
	for element in Dungeon.ELEMENT_MATERIAL:
		var material:=view.elemental_material_profile(element)
		families[int(material.x)]=true
		if not material.is_finite() or material.x<0.0 or material.x>11.0 or material.y<=0.0 or material.y>1.0 or material.z<0.0 or material.z>1.2+.001:failures.append("invalid elemental material: "+str(element))
		checks+=1
	if Dungeon.ELEMENT_MATERIAL.size()!=18 or families.size()!=12:failures.append("elemental material coverage")
	var material_light:=Color("#d6b6a0")
	var material_dark:=Color("#44342d")
	for family in range(12):
		for y in range(16):
			for x in range(16):
				for inner in [true,false]:
					var pixel:=view.particle_material_pixel(family,Vector2(x-7.5,y-7.5),inner,material_light,material_dark)
					if not is_finite(pixel.r) or not is_finite(pixel.g) or not is_finite(pixel.b) or not is_finite(pixel.a) or pixel.r<0.0 or pixel.r>1.001 or pixel.g<0.0 or pixel.g>1.001 or pixel.b<0.0 or pixel.b>1.001 or pixel.a<=0.0 or pixel.a>1.001:failures.append("invalid material pixel")
					checks+=1
	if view.particle_material_pixel(2,Vector2(4,4),false,material_light,material_dark).a>=1.0:failures.append("water not translucent")
	if view.particle_material_pixel(3,Vector2.ZERO,true,material_light,material_dark).r<=material_light.r:failures.append("electric core not luminous")
	checks+=2
	# Audio timing is deterministic and every synthesized PCM buffer has
	# silent endpoints, bounded peaks and audible energy.
	for phase in ["launch","impact","miss","status"]:
		for i in range(101):
			var envelope:float=view.combat_audio_envelope(float(i)/100.0,phase)
			if not is_finite(envelope) or envelope<0.0 or envelope>1.001:failures.append("invalid audio envelope")
			if i in [0,100] and absf(envelope)>.000001:failures.append("audio envelope endpoint")
			checks+=1
	var audio_ids:Array=["eos_062","eos_063","eos_065","eos_092","eos_127","eos_155","eos_193","eos_239","eos_280","eos_345","eos_453","eos_483","eos_538","lib_grass_2","lib_water_2","lib_fire_2","lib_fairy_1","lib_steel_2"]
	var audio_signatures:Dictionary={}
	for id in audio_ids:
		var profile:=view.combat_profile(id)
		var form:=view.combat_audio_form(id,profile)
		for phase in ["launch","impact","miss","status"]:
			var audio:=view.combat_sound(id,phase,0)
			var pcm:PackedByteArray=audio.data
			if pcm.size()<1000 or audio.mix_rate!=22050 or audio.stereo:failures.append("invalid combat PCM")
			if pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0:failures.append("nonzero audio endpoint")
			var peak:int=0
			for offset in range(0,pcm.size(),2):
				peak=maxi(peak,absi(pcm.decode_s16(offset)))
			if peak<100 or peak>31130:failures.append("invalid combat audio level")
			var signature:=pcm.hex_encode()
			if audio_signatures.has(signature):failures.append("duplicate combat audio")
			audio_signatures[signature]=true
			var expected:float=view.combat_audio_duration(profile,form,phase)
			if absf(float(pcm.size())/2.0/22050.0-expected)>.0001:failures.append("combat audio duration mismatch")
			checks+=1
	if view.combat_audio_form("eos_062",view.combat_profile("eos_062"))!="crunch":failures.append("crunch acoustic identity")
	if view.combat_audio_form("eos_063",view.combat_profile("eos_063"))!="fang":failures.append("bite acoustic identity")
	checks+=2
	# Full catalog: actual frame bytes, audio buffers, and pooled world FX.
	# A duplicate sequence or sparse animation is a review candidate, not proof
	# of poor visual quality. Preserve exact IDs in the downloadable CI report.
	var quality_rows:Array=[]
	var sequence_owners:Dictionary={}
	var duplicate_groups:Dictionary={}
	var review_candidates:Array=[]
	var frame_total:int=0
	var runtime_samples:int=0
	var audio_total:int=0
	var scene:=Node3D.new()
	root.add_child(scene)
	view.combat_fx_setup(scene)
	# Generate PCM explicitly below; no speaker playback in a headless test.
	view.fx_audio.clear()
	for id in catalog:
		var profile:=view.combat_profile(id)
		var move:Dictionary=catalog[id]
		var frame_hashes:Dictionary={}
		var sequence:=HashingContext.new()
		sequence.start(HashingContext.HASH_SHA256)
		var blank_frames:Array=[]
		var repeat_count:int=0
		var previous_hash:String=""
		for frame in range(Dungeon.FX_FRAME_COUNT):
			var image:Image=view.combat_frame_image(id,frame)
			var bytes:PackedByteArray=image.get_data()
			sequence.update(bytes)
			var frame_hash:String=bytes.hex_encode().sha256_text()
			frame_hashes[frame_hash]=true
			if frame_hash==previous_hash:repeat_count+=1
			previous_hash=frame_hash
			if not image.get_used_rect().has_area():blank_frames.append(frame)
			if image.get_size()!=Vector2i(48,48):failures.append("full catalog frame size "+str(id))
			frame_total+=1;checks+=1
		var signature:String=sequence.finish().hex_encode()
		if sequence_owners.has(signature):
			if not duplicate_groups.has(signature):duplicate_groups[signature]=[sequence_owners[signature]]
			duplicate_groups[signature].append(id)
		else:sequence_owners[signature]=id
		if frame_hashes.size()<3 or blank_frames.size()>3 or repeat_count>5:review_candidates.append(id)
		if blank_frames.size()==Dungeon.FX_FRAME_COUNT:failures.append("empty full sequence "+str(id))
		var audio_form:=view.combat_audio_form(id,profile)
		var audio_peaks:Dictionary={}
		for phase in ["launch","impact"]:
			var audio:=view.combat_sound(id,phase,0)
			var pcm:PackedByteArray=audio.data
			var peak:int=0
			for offset in range(0,pcm.size(),2):
				peak=maxi(peak,absi(pcm.decode_s16(offset)))
			if pcm.size()<1000 or peak<100 or peak>31130 or pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0:failures.append("catalog audio "+str(id)+" "+phase)
			audio_peaks[phase]=peak
			audio_total+=1;checks+=1
		var category:String=str(move.get("category",""))
		var target_tile:=Vector2i(2,0)
		var row:Dictionary={"effects":1} if category=="status" else {"damage":8}
		var event:Dictionary={"fx":id,"from":Vector2i.ZERO,"to":target_tile,"path":[Vector2i(1,0),target_tile],"tiles":[target_tile],"results":{target_tile:row},"damage":int(row.get("damage",0))}
		view.combat_fx_spawn(event)
		var duration:float=float(view.combat_bursts[-1].duration)
		var last:float=0.0
		var max_visible:int=0
		var peak_time:float=float(profile.impact)
		for phase in [peak_time*.45,peak_time,peak_time+(1.0-peak_time)*.45,.98,1.02]:
			view.combat_fx_update((float(phase)-last)*duration)
			last=float(phase)
			var visible:int=0
			for particle in view.combat_particles:
				if not particle.visible:continue
				visible+=1
				if not particle.position.is_finite() or not particle.scale.is_finite() or particle.texture==null:failures.append("invalid world particle "+str(id))
			max_visible=maxi(max_visible,visible)
			if visible>Dungeon.FX_PARTICLE_CAP or view.fx_trail_vertices>Dungeon.FX_TRAIL_VERTEX_CAP or view.fx_halos_used>Dungeon.FX_HALO_CAP:failures.append("world pool overflow "+str(id))
			runtime_samples+=1;checks+=1
		if not view.combat_bursts.is_empty() or max_visible==0:failures.append("world cast lifetime "+str(id))
		quality_rows.append({"id":id,"element":profile.element,"role":profile.role,"category":category,"distinct_frames":frame_hashes.size(),"blank_frames":blank_frames,"adjacent_repeats":repeat_count,"sequence_sha256":signature,"audio_form":audio_form,"audio_peaks":audio_peaks,"max_visible_particles":max_visible})
	if frame_total!=589*Dungeon.FX_FRAME_COUNT or audio_total!=1178 or runtime_samples!=2945:failures.append("full catalog sample coverage")
	# V15.2 promotes the original duplicate report from advisory to a hard gate.
	if Dungeon.NATIVE_IDENTITY_CASTS.size()!=60:failures.append("native identity coverage")
	for signature in duplicate_groups:
		failures.append("identical move sequence: "+str(duplicate_groups[signature]))
	for id in Dungeon.NATIVE_IDENTITY_CASTS:
		if not catalog.has(id) or not Dungeon.AUTHORED_STAGE_FX.has(id):failures.append("missing native choreography "+str(id))
		checks+=1
	if view.combat_textures.size()>Dungeon.FX_SECONDARY_TEXTURE_CAP or view.fx_animated_cache.size()>Dungeon.FX_ANIMATED_CACHE_CAP or view.fx_audio_cache.size()>192:failures.append("catalog cache overflow")
	var report:=FileAccess.open("/tmp/kindria-quality-report.log",FileAccess.WRITE)
	if report==null:failures.append("quality report write failed")
	else:
		report.store_string(JSON.stringify({"moves":quality_rows,"frame_total":frame_total,"audio_total":audio_total,"runtime_samples":runtime_samples,"duplicate_sequences":duplicate_groups,"review_candidates":review_candidates,"secondary_cache_size":view.combat_textures.size()}, "\t"))
		report.close()
	print("KINDRIA_FULL_QUALITY moves=",quality_rows.size()," frames=",frame_total," audio=",audio_total," runtime_samples=",runtime_samples," duplicate_groups=",duplicate_groups.size()," review_candidates=",review_candidates.size())
	scene.free()
	var home:=Home.new()
	home.free()
	view.free()
	print("CINEMATIC_GAUNTLET checks=",checks," failures=",failures.size())
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
