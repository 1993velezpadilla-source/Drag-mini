extends SceneTree
# Run after import: godot --headless --path . --script res://cinematic_gauntlet.gd
const Art=preload("res://pixel_pet_art.gd")
const Dungeon=preload("res://dungeon_view.gd")
const Home=preload("res://live_pet_stage.gd")

func _initialize()->void:
	call_deferred("run_checks")

# V20.1: compact, amplitude-normalized descriptors for review, not a
# perceptual equivalence claim. Exact PCM digest is tracked separately.
func audio_quality_metrics(pcm:PackedByteArray)->Dictionary:
	var count:int=int(pcm.size()/2)
	var energy:float=0.0
	var mean:float=0.0
	var peak:float=0.0
	var max_step:float=0.0
	var crossings:int=0
	var last:float=0.0
	var bins:Array[float]=[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
	for i in range(count):
		var value:float=float(pcm.decode_s16(i*2))/32767.0
		energy+=value*value
		mean+=value
		peak=maxf(peak,absf(value))
		max_step=maxf(max_step,absf(value-last))
		if i>0 and (value>=0.0)!=(last>=0.0):crossings+=1
		last=value
		bins[mini(7,int(float(i)*8.0/maxi(1,count)))]+=value*value
	var descriptor:Array[int]=[]
	for bin in bins:descriptor.append(roundi(20.0*bin/maxf(.000001,energy)))
	var rms:float=sqrt(energy/maxi(1,count))
	return {"rms":rms,"dc":mean/maxi(1,count),"peak":peak,"max_step":max_step,"crossings_per_second":float(crossings)*22050.0/maxi(1,count),"descriptor":str(descriptor)+":"+str(roundi(float(crossings)*22050.0/maxi(1,count)/100.0))+":"+str(roundi(float(count)/22050.0*20.0)),"pcm_sha256":pcm.hex_encode().sha256_text()}

func run_checks()->void:
	var checks:int=0
	var failures:Array[String]=[]
	var view:=Dungeon.new()
	# V19.5: volume/pitch remain bounded and critical voices retain priority.
	for power in range(61):
		var normal_mix:=view.combat_audio_mix(power,"impact",false)
		var critical_mix:=view.combat_audio_mix(power,"impact",true)
		var launch_mix:=view.combat_audio_mix(power,"launch")
		var miss_mix:=view.combat_audio_mix(power,"miss")
		var status_mix:=view.combat_audio_mix(power,"status")
		if not normal_mix.is_finite() or normal_mix.x> -8.0 or normal_mix.x< -14.00001 or normal_mix.y<.91999 or normal_mix.y>1.04001:failures.append("impact audio bounds")
		if critical_mix.x<normal_mix.x or critical_mix.z!=3.0 or normal_mix.z!=2.0:failures.append("critical audio priority")
		if launch_mix.x>=normal_mix.x or launch_mix.z!=1.0 or miss_mix.z!=0.0 or status_mix.z!=1.0:failures.append("audio phase mix")
		checks+=3
	var voices:Array[int]=[3,2,1,0]
	if view.combat_audio_voice_slot(voices,0,0)!=-1:failures.append("miss voice eviction")
	if view.combat_audio_voice_slot(voices,0,2)!=3:failures.append("weakest voice selection")
	var critical_voices:Array[int]=[3,3,3]
	if view.combat_audio_voice_slot(critical_voices,1,2)!=-1:failures.append("protect critical voice")
	if view.combat_audio_voice_slot(critical_voices,1,3)!=1:failures.append("critical round robin")
	var idle_voices:Array[int]=[0,1,-1,3]
	if view.combat_audio_voice_slot(idle_voices,0,2)!=2:failures.append("prefer idle audio voice")
	checks+=5
	# V19.3: bounded optical profiles, distinct material identity and quality fallback.
	var optical_profiles:Dictionary={}
	for element in ["normal","fire","water","electric","grass","ice","fighting","poison","ground","flying","psychic","bug","rock","ghost","dragon","dark","steel","fairy"]:
		var initial:=view.elemental_atmosphere_sample(element,0.0,false,0)
		var ground:=view.elemental_atmosphere_sample(element,0.0,true,0)
		var medium:=view.elemental_atmosphere_sample(element,0.0,false,1)
		var low:=view.elemental_atmosphere_sample(element,0.0,false,2)
		if optical_profiles.has(initial):failures.append("duplicate optical profile "+element)
		optical_profiles[initial]=true
		if ground.z!=0.0 or ground.x>initial.x+.00001:failures.append("floor optical profile "+element)
		if medium.distance_to(initial*.55)>.00001 or low!=Vector3.ZERO:failures.append("optical quality fallback "+element)
		checks+=3
		var previous:=initial
		for step in range(101):
			var sample:=view.elemental_atmosphere_sample(element,float(step)/100.0,false,0)
			if not sample.is_finite() or sample.x<0.0 or sample.y<0.0 or sample.z<0.0 or sample.x>1.0 or sample.y>1.0 or sample.z>1.0:failures.append("optical bounds "+element)
			if sample.x>previous.x+.00001 or sample.y>previous.y+.00001 or sample.z>previous.z+.00001:failures.append("optical dissipation "+element)
			previous=sample
			checks+=2
		if previous.length()>.00001:failures.append("optical terminal fade "+element)
		checks+=1
	# V19.2: verify analytic flight apex, landing, bounce and ground clearance.
	for landing in [.35,.58,.72,.90]:
		for height in [.2,.6,1.1]:
			for bounce in [0.0,.12,.20]:
				var start:=view.material_flight_sample(0.0,landing,height,bounce)
				var apex:=view.material_flight_sample(landing*.5,landing,height,bounce)
				var contact:=view.material_flight_sample(landing,landing,height,bounce)
				var end:=view.material_flight_sample(1.0,landing,height,bounce)
				if start.distance_to(Vector3.ZERO)>.00001:failures.append("material flight start")
				if absf(apex.x-height)>.00001 or apex.z!=0.0:failures.append("material flight apex")
				if absf(contact.x)>.00001 or absf(contact.y-1.0)>.00001 or contact.z!=1.0:failures.append("material landing")
				if absf(end.x)>.00001 or end.z!=1.0:failures.append("material settling")
				checks+=4
				var previous:float=0.0
				for step in range(101):
					var sample:=view.material_flight_sample(float(step)/100.0,landing,height,bounce)
					if not sample.is_finite() or sample.x<-.00001 or sample.y<previous-.00001:failures.append("material flight continuity")
					previous=sample.y
					checks+=1
	# V19 power scaling is monotonic, bounded and neutral for variable-power moves.
	var previous_power:=Vector3.ZERO
	for power in range(1,61):
		var sample:=view.cinematic_power_sample(power)
		if not sample.is_finite() or sample.x<.78-.00001 or sample.x>1.48+.00001 or sample.y<.80-.00001 or sample.y>1.40+.00001 or sample.z<.85-.00001 or sample.z>1.30+.00001:
			failures.append("cinematic power bounds "+str(power))
		if sample.x<previous_power.x or sample.y<previous_power.y or sample.z<previous_power.z:
			failures.append("cinematic power monotonicity "+str(power))
		previous_power=sample
		checks+=2
	if view.cinematic_power_sample(0)!=Vector3.ONE:failures.append("variable power visual neutrality")
	if view.cinematic_power_sample(8).distance_to(Vector3.ONE)>.0001:failures.append("baseline power visual scale")
	if view.cinematic_power_sample(60,true)!=view.cinematic_power_sample(0,true):failures.append("status power must not amplify lighting")
	if view.cinematic_power_sample(44).x<=view.cinematic_power_sample(6).x:failures.append("strong attack visual differentiation")
	checks+=4
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
	# Every elemental terminal profile has a material and bounded trajectory.
	var terminal_signatures:Dictionary={}
	if Dungeon.ELEMENT_DISSIPATION.size()!=18:failures.append("elemental dissipation coverage")
	for element in Dungeon.ELEMENT_FINISH_MODE:
		if not Dungeon.ELEMENT_DISSIPATION.has(element):
			failures.append("missing dissipation "+element)
			continue
		var cue:Array=Dungeon.ELEMENT_DISSIPATION[element]
		if terminal_signatures.has(str(cue)):failures.append("duplicate dissipation profile "+element)
		terminal_signatures[str(cue)]=true
		var terminal_texture:=view.combat_pixel_texture(str(cue[0]),Color("#fff3c2"),Color("#e0a34c"))
		if terminal_texture==null or not terminal_texture.get_image().get_used_rect().has_area():failures.append("empty dissipation texture "+element)
		for step in range(101):
			var phase:float=float(step)/100.0
			for particle_index in range(5):
				var terminal:=view.elemental_dissipation_sample(element,phase,particle_index)
				var offset:=view.elemental_dissipation_offset(element,phase,particle_index,5)
				if not terminal.is_finite() or not offset.is_finite() or terminal.x<0.0 or terminal.x>1.1 or terminal.z<.3 or terminal.z>1.41 or terminal.w<0.0 or terminal.w>1.001 or offset.length()>1.3:failures.append("dissipation bounds "+element)
				if step==100 and terminal.w>.0001:failures.append("dissipation did not expire "+element)
				checks+=1
	if view.elemental_dissipation_sample("fire",.9).y<=0.0 or view.elemental_dissipation_sample("ice",.9).y>=0.0 or view.elemental_dissipation_sample("psychic",.9).x>=view.elemental_dissipation_sample("psychic",.1).x:failures.append("elemental trajectory distinction")
	checks+=1
	# Lighting is local, elemental, finite and bounded by the original pool.
	var lighting_signatures:Dictionary={}
	if Dungeon.ELEMENT_LIGHT_PROFILE.size()!=18:failures.append("elemental light profile coverage")
	for element in Dungeon.ELEMENT_FINISH_MODE:
		if not Dungeon.ELEMENT_LIGHT_PROFILE.has(element):
			failures.append("missing elemental light "+element)
			continue
		var cue:Array=Dungeon.ELEMENT_LIGHT_PROFILE[element]
		if lighting_signatures.has(str(cue)):failures.append("duplicate light profile "+element)
		lighting_signatures[str(cue)]=true
		for stage in ["launch","impact","residue"]:
			for step in range(101):
				var phase:float=float(step)/100.0
				var sample:=view.elemental_light_sample(element,phase,stage)
				var wide_sample:=view.elemental_light_sample(element,phase,stage,true)
				if not sample.is_finite() or sample.x<0.0 or sample.x>1.201 or sample.y<1.0 or sample.y>2.7 or sample.z<1.0 or sample.z>3.0:failures.append("light profile bounds "+element)
				if wide_sample.y<sample.y or wide_sample.y>3.2 or wide_sample.x!=sample.x:failures.append("wide light bounds "+element)
				if step==100 and sample.x>.0001:failures.append("light did not expire "+element)
				if stage=="launch" and step==0 and sample.x>.0001:failures.append("launch light starts abruptly "+element)
				checks+=1
	if view.cinematic_light_slot([],2,1.0)!=0 or view.cinematic_light_slot([1.0],2,2.0)!=1 or view.cinematic_light_slot([4.8,2.9],2,6.2)!=1 or view.cinematic_light_slot([4.8,2.9],2,1.9)!=-1 or view.cinematic_light_slot([2.5],1,4.2)!=0 or view.cinematic_light_slot([],0,6.0)!=-1:failures.append("light pool priority")
	checks+=6
	# Local environmental response must expire and never grow stronger on
	# empty terrain than on a confirmed hit.
	var environmental_signatures:Dictionary={}
	if Dungeon.ELEMENT_ENVIRONMENT_RESPONSE.size()!=18:failures.append("environment response coverage")
	for element in Dungeon.ELEMENT_FINISH_MODE:
		if not Dungeon.ELEMENT_ENVIRONMENT_RESPONSE.has(element):
			failures.append("missing environment response "+element)
			continue
		var signature:String=str(Dungeon.ELEMENT_ENVIRONMENT_RESPONSE[element])
		if environmental_signatures.has(signature):failures.append("duplicate environment response "+element)
		environmental_signatures[signature]=true
		for step in range(101):
			var phase:float=float(step)/100.0
			var response:=view.environmental_response_sample(element,phase)
			var terrain:=view.environmental_response_sample(element,phase,true)
			if not response.is_finite() or response.x<1.0 or response.x>3.2001 or absf(response.y)>1.0001 or response.z<0.0 or response.z>1.0 or response.w<0.0 or response.w>.5:failures.append("environment response bounds "+element)
			if absf(terrain.y-response.y*.45)>.0001 or absf(terrain.z-response.z*.45)>.0001 or absf(terrain.w-response.w*.45)>.0001:failures.append("terrain response strength "+element)
			if step==100 and (absf(response.y)+response.z+response.w)>.0001:failures.append("environment response not expired "+element)
			checks+=1
	var old_mark:Dictionary={"at":Vector3(1,0,1),"age":.95,"life":1.0,"element":"water","terrain_only":false,"color":Color.BLUE}
	var live_mark:Dictionary={"at":Vector3(4,0,2),"age":.05,"life":1.0,"element":"flying","terrain_only":false,"color":Color.WHITE}
	var picked:=view.exterior_response_pick([live_mark,old_mark])
	if picked.is_empty() or Vector4(picked.pulse).x!=4.0:failures.append("environment impulse priority")
	old_mark.age=1.0;live_mark.age=1.0
	if not view.exterior_response_pick([live_mark,old_mark]).is_empty():failures.append("expired exterior impulse")
	checks+=2
	# Local shader warps must have distinct authored profiles, bounded amplitudes,
	# exact neutral endpoints, and a deterministic low-tier fallback.
	var distortion_signatures:Dictionary={}
	var distortion_families:Dictionary={}
	if Dungeon.ELEMENT_DISTORTION.size()!=18:failures.append("elemental distortion coverage")
	for element in Dungeon.ELEMENT_FINISH_MODE:
		if not Dungeon.ELEMENT_DISTORTION.has(element):
			failures.append("missing distortion "+element)
			continue
		var cue:Vector3=Dungeon.ELEMENT_DISTORTION[element]
		if distortion_signatures.has(str(cue)):failures.append("duplicate distortion profile "+element)
		distortion_signatures[str(cue)]=true
		distortion_families[int(cue.x)]=true
		for stage in ["launch","impact"]:
			for step in range(101):
				var phase:float=float(step)/100.0
				var high_sample:=view.elemental_distortion_sample(element,phase,stage,0)
				var medium_sample:=view.elemental_distortion_sample(element,phase,stage,1)
				var low_sample:=view.elemental_distortion_sample(element,phase,stage,2)
				if not high_sample.is_finite() or high_sample.x<1.0 or high_sample.x>6.0 or high_sample.y<0.0 or high_sample.y>.141 or high_sample.z<4.0 or high_sample.z>23.0:failures.append("distortion bounds "+element)
				if absf(medium_sample.y-high_sample.y*.55)>.0001 or low_sample!=Vector3.ZERO:failures.append("distortion tier fallback "+element)
				if step==100 and high_sample.y>.0001:failures.append("distortion did not expire "+element)
				if stage=="launch" and step==0 and high_sample.y>.0001:failures.append("distortion launch discontinuity "+element)
				checks+=1
		if view.elemental_distortion_sample(element,.5,"none",0)!=Vector3.ZERO:failures.append("distortion on disabled stage "+element)
		checks+=1
	if distortion_families.size()!=6:failures.append("distortion family coverage")
	checks+=1
	# V17: exact catalog membership, not the obsolete eight-move pilot count.
	var remastered:Dictionary={}
	for id in Dungeon.VISUAL_REMASTER_MOVES:
		if remastered.has(id):failures.append("duplicate remaster registration "+str(id))
		if not catalog.has(id):failures.append("unknown remaster registration "+str(id))
		remastered[id]=true
		checks+=1
	for id in catalog:
		if not remastered.has(id):failures.append("missing remaster registration "+str(id))
		checks+=1
	if remastered.size()!=catalog.size():failures.append("visual remaster coverage")
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
	# V19.4: a miss cannot trigger recoil, and a later confirmed attempt can.
	var player_tile:=Vector2i(1,0)
	var player_wave:Dictionary={"target_player":true,"points":[Vector3(0,.5,0),Vector3(1.4,.5,0)],"damage":16,"age":.21,"impact_cursor":1,"impact_times":[.2,.3,.4],"impact_waves":[{player_tile:{"damage":0,"misses":1}},{player_tile:{"damage":7}},{player_tile:{"damage":9}}]}
	if not view.latest_player_impact({},player_wave,0).is_empty():failures.append("player first miss recoil")
	player_wave.age=.31;player_wave.impact_cursor=2
	var player_second:=view.latest_player_impact({},player_wave,1)
	if player_second.is_empty() or absf(float(player_second.age)-.01)>.00001:failures.append("player second hit timing")
	if not view.latest_player_impact({},player_wave,2).is_empty():failures.append("player duplicate recoil")
	player_wave.age=.42;player_wave.impact_cursor=3
	var player_lagged:=view.latest_player_impact({},player_wave,0)
	if player_lagged.is_empty() or absf(float(player_lagged.age)-.02)>.00001:failures.append("player newest hit under lag")
	player_wave.impact_waves[2]={Vector2i(2,0):{"damage":9}}
	if not view.latest_player_impact({},player_wave,2).is_empty():failures.append("other tile must not cause player recoil")
	player_wave.target_player=false
	if not view.latest_player_impact({},player_wave,0).is_empty():failures.append("non-player recoil")
	checks+=6
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
	# V19.6 audio variants: verify each nature in impact and status phases.
	var audio_natures:Dictionary={}
	for id in catalog:
		var nature:String=str(view.combat_profile(id).element)
		if audio_natures.has(nature):continue
		audio_natures[nature]=id
		for phase in ["impact","status"]:
			var previous:=PackedByteArray()
			for variant in range(3):
				var sample:=view.combat_sound(id,phase,variant)
				var bytes:PackedByteArray=sample.data
				var peak:int=0
				for offset in range(0,bytes.size(),2):
					peak=maxi(peak,absi(bytes.decode_s16(offset)))
				if bytes.size()<1000 or peak<100 or peak>31130 or bytes.decode_s16(0)!=0 or bytes.decode_s16(bytes.size()-2)!=0:failures.append("V19.6 PCM "+nature+" "+phase)
				if bytes==previous:failures.append("V19.6 duplicate variant "+nature+" "+phase)
				if view.combat_sound(id,phase,variant).data!=bytes:failures.append("V19.6 unstable cache "+nature+" "+phase)
				previous=bytes
				checks+=3
	if audio_natures.size()!=18:failures.append("V19.6 missing acoustic nature")
	checks+=1
	# V19.7 acoustic gestures: every catalog move has a bounded semantic profile.
	var gesture_groups:Dictionary={}
	for id in catalog:
		var gesture:Vector4=view.combat_audio_gesture(id,view.combat_profile(id))
		if not gesture.is_finite() or gesture.x<60.0 or gesture.x>2000.0 or gesture.x+gesture.y<30.0 or gesture.z<1.0 or gesture.z>7.0 or gesture.w<0.0 or gesture.w>1.0:failures.append("V19.7 invalid gesture "+str(id))
		var max_sample:float=0.0
		for i in range(21):
			var progress:float=float(i)/20.0
			var sample:float=view.combat_audio_gesture_sample(gesture,progress*.2,progress,1.0,.5,-.3)
			if not is_finite(sample) or absf(sample)>1.0:failures.append("V19.7 gesture sample "+str(id))
			max_sample=maxf(max_sample,absf(sample))
		if max_sample<.005:failures.append("V19.7 silent gesture "+str(id))
		gesture_groups[str(gesture)]=true
		checks+=23
	if gesture_groups.size()<35:failures.append("V19.7 insufficient gesture variety")
	checks+=1
	for group in [["eos_262","eos_053","eos_291","eos_157"],["eos_308","eos_240","eos_239","eos_255"],["eos_064","eos_193","eos_489","eos_521"]]:
		var seen_gestures:Dictionary={}
		for id in group:
			var gesture:Vector4=view.combat_audio_gesture(id,view.combat_profile(id))
			if seen_gestures.has(str(gesture)):failures.append("V19.7 same-nature gesture collision "+id)
			seen_gestures[str(gesture)]=true
			checks+=1
	# V19.8 environmental cues are bounded, ordered and subordinate to contact.
	for id in catalog:
		var profile:Dictionary=view.combat_profile(id)
		var cues:Array=view.combat_environment_audio_plan(id,profile)
		var last_fraction:float=-1.0
		if cues.size()>2:failures.append("V19.8 excessive environmental cues "+str(id))
		for cue in cues:
			var fraction:float=float(cue.fraction)
			if not is_finite(fraction) or fraction<last_fraction or fraction<0.0 or fraction>=1.0:failures.append("V19.8 environment timing "+str(id))
			last_fraction=fraction
			if not str(cue.phase).begins_with("env_") or str(cue.anchor) not in ["travel","terrain","surface"]:failures.append("V19.8 environment phase "+str(id))
			checks+=2
		checks+=1
	var env_ids:Array=["eos_008","eos_156","eos_153","eos_477"]
	var env_phases:Array=["env_dig","env_dive","env_wind","env_vanish"]
	for i in range(env_ids.size()):
		var id:String=env_ids[i]
		var cues:Array=view.combat_environment_audio_plan(id,view.combat_profile(id))
		if cues.size()!=2 or str(cues[0].phase)!=env_phases[i] or str(cues[1].anchor)!="terrain":failures.append("V19.8 travel identity "+id)
		checks+=1
	var env_cell:=Vector2i(3,4)
	if view.combat_environment_surface_allowed({env_cell:{"damage":0}},env_cell,0,"fire"):failures.append("V19.8 false surface contact")
	if not view.combat_environment_surface_allowed({env_cell:{"damage":1}},env_cell,1,"fire"):failures.append("V19.8 missing confirmed surface")
	if not view.combat_environment_surface_allowed({},env_cell,0,"water"):failures.append("V19.8 empty terrain water")
	if view.combat_environment_surface_allowed({},env_cell,0,"ghost"):failures.append("V19.8 false spectral surface")
	checks+=4
	var env_signatures:Dictionary={}
	for kind in ["ember","splash","crystal","gravel","dig","dive","drip","static","leaves","metal","wind","land","vanish"]:
		var phase:String="env_"+kind
		var mix:Vector3=view.combat_audio_mix(60,phase,true)
		if mix.z!=0.0 or mix.x> -20.0:failures.append("V19.8 environment mix priority")
		checks+=1
		for variant in range(3):
			var audio:AudioStreamWAV=view.combat_environment_sound(phase,variant)
			var pcm:PackedByteArray=audio.data
			var peak:int=0
			for offset in range(0,pcm.size(),2):peak=maxi(peak,absi(pcm.decode_s16(offset)))
			if pcm.size()<1000 or audio.mix_rate!=22050 or audio.stereo or peak<100 or peak>31130 or pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0:failures.append("V19.8 environmental PCM "+kind)
			var signature:String=pcm.hex_encode()
			if env_signatures.has(signature):failures.append("V19.8 duplicate environmental sample "+kind)
			env_signatures[signature]=true
			if view.combat_environment_sound(phase,variant)!=audio:failures.append("V19.8 environment cache")
			checks+=3
	# V19.9 status motifs must reflect confirmed outcomes, not move chance.
	var ailment_move:Dictionary={"category":"special","inflict_status":"paralysis"}
	if view.combat_status_audio_kind(ailment_move,{"damage":5})!="":failures.append("V19.9 false proc")
	if view.combat_status_audio_kind(ailment_move,{"damage":5,"status":"Paralysis","status_changed":true})!="paralysis":failures.append("V19.9 confirmed proc")
	if view.combat_status_audio_kind({"category":"status","inflict_status":"sleep"},{"misses":1})!="":failures.append("V19.9 missed sleep")
	if view.combat_status_audio_kind({"category":"status","inflict_status":"sleep"},{"blocked":1})!="":failures.append("V19.9 blocked sleep")
	if view.combat_status_audio_kind({},{"heal":4})!="heal":failures.append("V19.9 healing")
	if view.combat_status_audio_kind({"drain_fraction":.5},{"heal":4})!="drain":failures.append("V19.9 drain")
	if view.combat_status_audio_kind({"category":"status","stat_changes":{"attack":1}},{"effects":1})!="boost":failures.append("V19.9 boost")
	if view.combat_status_audio_kind({"category":"status","stat_changes":{"attack":-1}},{"effects":1})!="weaken":failures.append("V19.9 weaken")
	var status_cell:=Vector2i(7,8)
	var status_waves:Array[Dictionary]=view.cast_impact_waves({status_cell:{"status":"Poison","attempts":[{"damage":3,"status":"Poison","status_changed":true},{"damage":0,"misses":1}]}})
	if status_waves.size()!=2 or view.combat_status_audio_kind({},status_waves[0][status_cell])!="poison" or not view.combat_status_audio_kind({},status_waves[1][status_cell]).is_empty():failures.append("V19.9 wrong proc timing")
	checks+=9
	var status_signatures:Dictionary={}
	for kind in ["heal","drain","cleanse","shield","boost","weaken","exchange","transform","sleep","confusion","poison","burn","paralysis","freeze","curse","heart","bind","trap","weather","blocked","ritual"]:
		var phase:String="status_"+kind
		var mix:Vector3=view.combat_audio_mix(60,phase,true)
		if mix.z!=(0.0 if kind=="blocked" else 1.0) or mix.x> -15.0:failures.append("V19.9 status priority "+kind)
		checks+=1
		for variant in range(3):
			var audio:AudioStreamWAV=view.combat_status_sound(phase,variant)
			var pcm:PackedByteArray=audio.data
			var peak:int=0
			for offset in range(0,pcm.size(),2):peak=maxi(peak,absi(pcm.decode_s16(offset)))
			if pcm.size()<1000 or peak<100 or peak>31130 or pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0 or audio.stereo or audio.mix_rate!=22050:failures.append("V19.9 status PCM "+kind)
			var signature:String=pcm.hex_encode()
			if status_signatures.has(signature):failures.append("V19.9 duplicate motif "+kind)
			status_signatures[signature]=true
			if view.combat_status_sound(phase,variant)!=audio:failures.append("V19.9 status cache "+kind)
			checks+=3
	# V20.0 mastering: bounded source peaks and conservative admission under load.
	var mastered:=PackedByteArray()
	mastered.resize(1024)
	for i in range(512):
		mastered.encode_s16(i*2,roundi(25000.0+7000.0*sin(float(i)*.7)))
	var master_peak:float=view.combat_audio_master_pcm(mastered)
	var measured_peak:float=0.0
	for i in range(512):
		measured_peak=maxf(measured_peak,float(absi(mastered.decode_s16(i*2)))/32767.0)
	if absf(master_peak-measured_peak)>.0001 or master_peak>Dungeon.FX_AUDIO_PEAK_LIMIT+.0001 or master_peak<.01:failures.append("V20.0 mastered peak")
	if mastered.decode_s16(0)!=0 or mastered.decode_s16(mastered.size()-2)!=0:failures.append("V20.0 mastered endpoints")
	checks+=2
	for priority in range(4):
		for step in range(71):
			var occupied:float=float(step)/100.0
			for peak in [.08,.25,.78]:
				var admitted:float=view.combat_audio_admission_db(peak,-8.0,occupied,priority)
				var ceiling:float=[.34,.46,.58,.70][priority]
				if not is_finite(admitted) or admitted> -7.9999:failures.append("V20.0 invalid admission")
				if occupied<ceiling and admitted> -40.0 and occupied+peak*db_to_linear(admitted)>ceiling+.0001:failures.append("V20.0 peak budget")
				if occupied>=ceiling and admitted> -40.0:failures.append("V20.0 over-admission")
				checks+=3
	var low_spatial:Vector2=view.combat_audio_spatial_profile(0)
	var high_spatial:Vector2=view.combat_audio_spatial_profile(3)
	if low_spatial.x>=high_spatial.x or low_spatial.y>=high_spatial.y:failures.append("V20.0 spatial priority")
	if view.combat_audio_admission_db(.5,-8.0,.58,3)<=view.combat_audio_admission_db(.5,-8.0,.58,0):failures.append("V20.0 critical headroom")
	checks+=2
	view.fx_audio_cache.clear()
	var lru_bytes:=PackedByteArray()
	lru_bytes.resize(128)
	for i in range(Dungeon.FX_AUDIO_CACHE_CAP):
		view.combat_audio_store("lru_"+str(i),lru_bytes.duplicate(),22050)
	var retained:AudioStreamWAV=view.combat_audio_cached("lru_0")
	view.combat_audio_store("lru_new",lru_bytes.duplicate(),22050)
	if retained==null or not view.fx_audio_cache.has("lru_0") or view.fx_audio_cache.has("lru_1") or view.fx_audio_cache.size()!=Dungeon.FX_AUDIO_CACHE_CAP:failures.append("V20.0 LRU eviction")
	view.fx_audio_cache.clear()
	checks+=1
	# V20.2 sub-frame synchronization across several mobile frame rates.
	for hz in [15,20,30,60,90,120]:
		var dt:float=1.0/float(hz)
		for step in range(101):
			var age:float=dt*float(step)/100.0
			var fresh_age:float=view.combat_visual_age(age,dt,true)
			var next_age:float=view.combat_visual_age(fresh_age,dt,false)
			if absf(fresh_age-age)>.000001 or absf(next_age-age-dt)>.000001:failures.append("V20.2 visual clock")
			if absf(view.combat_ground_shake_at_age(age)-maxf(0.0,.22-age*3.0))>.000001:failures.append("V20.2 aged shake")
			checks+=2
	var av_origin:=Vector3(0,.5,0)
	var av_wave:Dictionary={Vector2i.ZERO:{"effects":1},Vector2i(1,0):{"damage":5},Vector2i(2,0):{"damage":3,"crit":1}}
	if not view.combat_wave_audio_target(av_wave,av_origin).is_equal_approx(Vector3(2.8,.5,0)):failures.append("V20.2 critical audio location")
	av_wave.erase(Vector2i(2,0))
	if not view.combat_wave_audio_target(av_wave,av_origin).is_equal_approx(Vector3(1.4,.5,0)):failures.append("V20.2 damaging audio location")
	av_wave.erase(Vector2i(1,0))
	if not view.combat_wave_audio_target(av_wave,av_origin).is_equal_approx(av_origin):failures.append("V20.2 status audio location")
	if not view.combat_wave_audio_target({Vector2i(3,0):{"misses":1}},av_origin).is_equal_approx(av_origin):failures.append("V20.2 miss audio location")
	checks+=4
	view.fx_reaction_sparks.clear()
	view.queue_ultra_reaction(Vector3.ZERO,Vector3.FORWARD,false,.12)
	if view.fx_reaction_sparks.size()!=1 or absf(float(view.fx_reaction_sparks[0].age)-.12)>.000001 or not bool(view.fx_reaction_sparks[0].fresh):failures.append("V20.2 reaction initial age")
	view.queue_ultra_reaction(Vector3.ZERO,Vector3.FORWARD,false,.25)
	if view.fx_reaction_sparks.size()!=1:failures.append("V20.2 expired reaction")
	view.fx_reaction_sparks.clear()
	checks+=2
	# V20.3 motion timing: differentiated anticipation and recovery without
	# changing the contact frame, logical tiles or neutral endpoints.
	var polish_kinds:Array=["rush","contact","fang","crunch","claw","pincer","punch","uppercut","kick","lowkick","wing","tail","horn","lash","aerial","down","spin","focus","gesture","cast"]
	var polish_signatures:Dictionary={}
	for kind in polish_kinds:
		polish_signatures[str(view.cast_motion_timing(kind))]=true
		for peak in [.12,.34,.48,.64,.88]:
			var timing:Vector4=view.cast_motion_timing(kind)
			var windup:Vector3=view.attack_direction_sample(peak*timing.x*.5,peak,kind)
			var contact:Vector3=view.attack_direction_sample(peak,peak,kind)
			if absf(windup.x-1.0)>.0001 or absf(contact.y-1.0)>.0001 or absf(contact.x)>.0001:failures.append("V20.3 contact clock "+kind)
			checks+=1
			var previous:=Vector3.ZERO
			for step in range(201):
				var phase:float=float(step)/200.0
				var motion:Vector3=view.cast_motion_offset(kind,phase,peak)
				var body:Dictionary=Art.attack_body_sample(phase,peak,kind)
				if not motion.is_finite() or motion.length()>1.0 or float(body.stretch)<.84 or float(body.stretch)>1.16:failures.append("V20.3 motion bounds "+kind)
				if step>0 and motion.distance_to(previous)>.16:failures.append("V20.3 abrupt motion "+kind)
				if step in [0,200] and (motion.length()>.001 or absf(float(body.stretch)-1.0)>.001):failures.append("V20.3 rest "+kind)
				previous=motion
				checks+=3
	if polish_signatures.size()<10:failures.append("V20.3 insufficient timing variety")
	checks+=1
	for step in range(101):
		var phase:float=float(step)/100.0
		var hit:Dictionary=view.premium_hit_sample(phase)
		if float(hit.recoil)<0.0 or float(hit.recoil)>1.0 or absf(float(hit.tilt))>.10:failures.append("V20.3 recoil bounds")
		if step in [0,100] and (absf(float(hit.recoil))>.001 or absf(float(hit.squash)-1.0)>.001):failures.append("V20.3 recoil rest")
		checks+=2
	# V20.6 acoustic repair: replay every flagged move in all three variants.
	var repaired_audio_ids:Array=["lib_electric_1","lib_dark_1","eos_063","eos_064","eos_325","eos_452","eos_461","eos_522","eos_529","eos_020","alt_vinesnap","alt_sylphowl","alt_eelstrix"]
	for id in repaired_audio_ids:
		for phase in ["launch","impact"]:
			for variant in range(3):
				var pcm:PackedByteArray=view.combat_sound(id,phase,variant).data
				var metrics:Dictionary=audio_quality_metrics(pcm)
				if float(metrics.max_step)>Dungeon.FX_AUDIO_STEP_LIMIT+.0001:failures.append("V20.6 excessive sample step "+id+" "+phase)
				if float(metrics.rms)<.005 or absf(float(metrics.dc))>.025:failures.append("V20.6 weak or biased audio "+id+" "+phase)
				if pcm.decode_s16(0)!=0 or pcm.decode_s16(pcm.size()-2)!=0:failures.append("V20.6 PCM endpoints "+id+" "+phase)
				checks+=3
	# V20.7 acoustic identity: compare authored role contours and semantic status
	# families instead of accepting a common thump for unrelated attacks.
	var identity_ids:Array=["eos_154","eos_139","eos_140","eos_161","eos_176","eos_177","eos_190","eos_203","eos_226","eos_235","eos_247","eos_248","eos_250","eos_260","eos_264","eos_271","eos_275","eos_294","eos_311","eos_312","eos_314","eos_321","eos_322","eos_328"]
	var identity_signatures:Dictionary={}
	for id in identity_ids:
		var gesture:Vector4=view.combat_audio_gesture(id,view.combat_profile(id))
		var signature:String=str(gesture)
		if identity_signatures.has(signature):failures.append("V20.7 duplicate authored gesture "+id)
		identity_signatures[signature]=true
		if not gesture.is_finite() or gesture.x<50.0 or gesture.x>2000.0 or gesture.z<1.0 or gesture.z>8.0 or gesture.w<0.0 or gesture.w>1.0:failures.append("V20.7 invalid gesture "+id)
		checks+=2
	for kind in ["normal_tackle","normal_drill","normal_megapunch","normal_furyswipes","normal_bide","normal_wrap"]:
		if not Dungeon.AUDIO_ROLE_GESTURES.has(kind):failures.append("V20.7 missing authored role "+kind)
		checks+=1
	# V21.0 texture reuse: retain hot entries even under full cache pressure.
	view.fx_secondary_pack_checked=true
	view.fx_frame_pack_checked=true # Exercise the original fallback LRU independently of the baked path.
	view.fx_animated_cache.clear()
	view.fx_animated_newest=""
	var hot_frame:Texture2D=view.combat_animated_texture("eos_308",0)
	var cold_frame:Texture2D=view.combat_animated_texture("eos_308",1)
	for i in range(Dungeon.FX_ANIMATED_CACHE_CAP-2):
		view.fx_animated_cache["synthetic_"+str(i)]=cold_frame
	var initial_builds:int=view.fx_frame_builds
	if view.combat_animated_texture("eos_308",0)!=hot_frame or view.fx_frame_builds!=initial_builds:failures.append("V21.0 texture hot reuse")
	view.combat_animated_texture("eos_308",2)
	if not view.fx_animated_cache.has("animated:eos_308:0") or view.fx_animated_cache.has("animated:eos_308:1") or view.fx_animated_cache.size()!=Dungeon.FX_ANIMATED_CACHE_CAP:failures.append("V21.0 animated LRU")
	view.fx_animated_cache.clear()
	view.fx_animated_newest=""
	view.combat_textures.clear()
	view.fx_secondary_newest=""
	var hot_particle:ImageTexture=view.combat_pixel_texture("impact_star",Color.WHITE,Color.BLACK)
	var cold_particle:ImageTexture=view.combat_pixel_texture("bubble",Color.WHITE,Color.BLACK)
	for i in range(Dungeon.FX_SECONDARY_TEXTURE_CAP-2):
		view.combat_textures["synthetic_"+str(i)]=cold_particle
	var secondary_builds:int=view.fx_secondary_builds
	if view.combat_pixel_texture("impact_star",Color.WHITE,Color.BLACK)!=hot_particle or view.fx_secondary_builds!=secondary_builds:failures.append("V21.0 secondary hot reuse")
	view.combat_pixel_texture("cloud",Color.WHITE,Color.BLACK)
	if not view.combat_textures.has("impact_star"+str(Color.WHITE)+str(Color.BLACK)) or view.combat_textures.has("bubble"+str(Color.WHITE)+str(Color.BLACK)) or view.combat_textures.size()!=Dungeon.FX_SECONDARY_TEXTURE_CAP:failures.append("V21.0 secondary LRU")
	view.combat_textures.clear()
	view.fx_secondary_newest=""
	checks+=4
	# Full catalog: actual frame bytes, audio buffers, and pooled world FX.
	# A duplicate sequence or sparse animation is a review candidate, not proof
	# of poor visual quality. Preserve exact IDs in the downloadable CI report.
	var quality_rows:Array=[]
	var visual_rows:Dictionary={}
	var visual_dir:String="/tmp/kindria-visual"
	if DirAccess.make_dir_recursive_absolute(visual_dir)!=OK:failures.append("visual output directory")
	var sequence_owners:Dictionary={}
	var duplicate_groups:Dictionary={}
	var review_candidates:Array=[]
	var frame_total:int=0
	var runtime_samples:int=0
	var audio_total:int=0
	var audio_digest_owners:Dictionary={}
	var audio_similarity_groups:Dictionary={}
	var audio_review_rows:Array=[]
	var audio_cold_usec:int=0
	var audio_cached_usec:int=0
	var scene:=Node3D.new()
	root.add_child(scene)
	view.combat_fx_setup(scene)
	# Indexed geometry must expand to the exact original two triangles.
	view.ultra_trail_segment(Vector3.ZERO,Vector3.RIGHT,.1,.2,Color.RED,Color.BLUE)
	var expected_indices:=PackedInt32Array([0,1,2,0,2,3])
	if view.fx_trail_positions.size()!=4 or view.fx_trail_indices!=expected_indices or view.fx_trail_colors!=PackedColorArray([Color.RED,Color.RED,Color.BLUE,Color.BLUE]):failures.append("V21.5 ribbon topology")
	if not view.commit_fx_geometry(view.fx_trail_mesh,view.fx_trail_material,view.fx_trail_positions,view.fx_trail_colors,view.fx_trail_indices):failures.append("V21.5 ribbon submission")
	if view.fx_trail_mesh.get_surface_count()!=1 or view.fx_trail_mesh.surface_get_array_len(0)!=4 or view.fx_trail_mesh.surface_get_array_index_len(0)!=6:failures.append("V21.5 indexed mesh")
	view.fx_trail_mesh.clear_surfaces()
	view.fx_trail_started=false
	view.arc_segment(Vector3.ZERO,Vector3.RIGHT,.1,Color.WHITE)
	if view.fx_arc_positions.size()!=4 or view.fx_arc_indices!=expected_indices:failures.append("V21.5 arc topology")
	var warnings:=PackedVector3Array([Vector3(1,.045,0),Vector3(2,.045,0),Vector3(1,.045,0)])
	view.apply_combat_warning_batch(warnings)
	var warning_updates:int=view.fx_warning_batch_updates
	view.apply_combat_warning_batch(warnings)
	if view.combat_warning_batch.multimesh.visible_instance_count!=3 or view.fx_warning_batch_updates!=warning_updates:failures.append("V21.5 warning batch")
	view.apply_combat_warning_batch(PackedVector3Array())
	if view.combat_warning_batch.visible or view.combat_warning_batch.multimesh.visible_instance_count!=0:failures.append("V21.5 warning cleanup")
	checks+=6
	var batch_rects:Array[Rect2]=[Rect2(0,0,10,10),Rect2(20,0,10,10),Rect2(40,0,10,10),Rect2(60,0,10,10),Rect2(65,0,10,10)]
	var batch_keys:Array[int]=[1,1,1,1,-1]
	var safe_groups:=view.particle_batch_groups(batch_rects,batch_keys)
	if safe_groups.size()!=1 or safe_groups[0]!=[0,1,2]:failures.append("V21.6 isolated particle grouping")
	batch_rects[2]=Rect2(25,0,10,10)
	if not view.particle_batch_groups(batch_rects,batch_keys).is_empty():failures.append("V21.6 overlapping particle fallback")
	checks+=2
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
		var strip:=Image.create(48*Dungeon.FX_FRAME_COUNT,48,false,Image.FORMAT_RGBA8)
		strip.fill(Color.TRANSPARENT)
		var frame_areas:Array[int]=[]
		var edge_frames:Array[int]=[]
		var visible_pixels:Array[int]=[]
		var border_pixels:Array[int]=[]
		var peak_visible:int=0
		var visual_signature:Array=[]
		var impact_frame:int=clampi(roundi(float(profile.impact)*float(Dungeon.FX_FRAME_COUNT-1)),0,Dungeon.FX_FRAME_COUNT-1)
		for frame in range(Dungeon.FX_FRAME_COUNT):
			var image:Image=view.combat_frame_image(id,frame)
			var bytes:PackedByteArray=image.get_data()
			var occupied:int=0
			var border:int=0
			# Alpha threshold excludes nearly transparent dissipation from silhouette metrics.
			for y in range(48):
				for x in range(48):
					if bytes[(y*48+x)*4+3]<=32:continue
					occupied+=1
					if x==0 or x==47 or y==0 or y==47:border+=1
			visible_pixels.append(occupied)
			border_pixels.append(border)
			peak_visible=maxi(peak_visible,occupied)
			# Sample the actual pixels at fixed animation phases. Premultiply color
			# so invisible RGB does not make two silhouettes appear different.
			if frame in [1,4,7,10]:
				var phase_features:Array=[]
				for gy in range(6):
					for gx in range(6):
						var sums:=Vector4.ZERO
						for y in range(gy*8,gy*8+8):
							for x in range(gx*8,gx*8+8):
								var pixel:=image.get_pixel(x,y)
								sums+=Vector4(pixel.a,pixel.r*pixel.a,pixel.g*pixel.a,pixel.b*pixel.a)
						phase_features.append([roundi(sums.x*255.0/64.0),roundi(sums.y*255.0/64.0),roundi(sums.z*255.0/64.0),roundi(sums.w*255.0/64.0)])
				visual_signature.append(phase_features)
			strip.blit_rect(image,Rect2i(0,0,48,48),Vector2i(frame*48,0))
			var bounds:=image.get_used_rect()
			frame_areas.append(bounds.get_area())
			if bounds.has_area() and (bounds.position.x==0 or bounds.position.y==0 or bounds.end.x==48 or bounds.end.y==48):edge_frames.append(frame)
			sequence.update(bytes)
			var frame_hash:String=bytes.hex_encode().sha256_text()
			frame_hashes[frame_hash]=true
			if frame_hash==previous_hash:repeat_count+=1
			previous_hash=frame_hash
			if occupied==0:blank_frames.append(frame)
			if image.get_size()!=Vector2i(48,48):failures.append("full catalog frame size "+str(id))
			frame_total+=1;checks+=1
		var signature:String=sequence.finish().hex_encode()
		var element:String=str(profile.element)
		var folder:String=visual_dir+"/"+element
		if DirAccess.make_dir_recursive_absolute(folder)!=OK:failures.append("visual element directory "+element)
		if strip.save_png(folder+"/"+str(id)+".png")!=OK:failures.append("visual strip export "+str(id))
		if not visual_rows.has(element):visual_rows[element]=[]
		visual_rows[element].append({"id":id,"name":str(move.get("name",id)),"impact_frame":impact_frame,"frame_areas":frame_areas,"edge_frames":edge_frames,"visible_pixels":visible_pixels,"border_pixels":border_pixels,"visual_signature":visual_signature})
		if sequence_owners.has(signature):
			if not duplicate_groups.has(signature):duplicate_groups[signature]=[sequence_owners[signature]]
			duplicate_groups[signature].append(id)
		else:sequence_owners[signature]=id
		var reasons:Array[String]=[]
		if frame_hashes.size()<6:reasons.append("low_temporal_variation")
		if blank_frames.size()>3:reasons.append("many_low_alpha_frames")
		if repeat_count>5:reasons.append("adjacent_repeats")
		if peak_visible<170:reasons.append("small_peak_silhouette")
		var impact_visible:int=visible_pixels[impact_frame]
		if impact_visible<30:reasons.append("weak_impact_silhouette")
		var max_border_ratio:float=0.0
		for frame in range(Dungeon.FX_FRAME_COUNT):
			if visible_pixels[frame]<30:continue
			max_border_ratio=maxf(max_border_ratio,float(border_pixels[frame])/float(visible_pixels[frame]))
		if max_border_ratio>.10:reasons.append("possible_frame_clipping")
		if not reasons.is_empty():
			review_candidates.append(id)
			print("KINDRIA_VISUAL_REVIEW ",JSON.stringify({"id":id,"name":str(move.get("name",id)),"element":element,"reasons":reasons,"peak_visible":peak_visible,"impact_visible":impact_visible,"distinct_frames":frame_hashes.size(),"blank_frames":blank_frames,"max_border_ratio":max_border_ratio}))
		if peak_visible==0:failures.append("empty full sequence "+str(id))
		if frame_hashes.size()==1:failures.append("static full sequence "+str(id))
		# A transparent final frame can be intentional. A weak impact is a review
		# candidate, not a hard failure for thin beams or subtle status moves.
		var audio_form:=view.combat_audio_form(id,profile)
		var audio_peaks:Dictionary={}
		var audio_metrics:Dictionary={}
		for phase in ["launch","impact"]:
			var started:int=Time.get_ticks_usec()
			var audio:=view.combat_sound(id,phase,0)
			var cold_usec:int=Time.get_ticks_usec()-started
			started=Time.get_ticks_usec()
			var cached:AudioStreamWAV=view.combat_sound(id,phase,0)
			var cached_usec:int=Time.get_ticks_usec()-started
			audio_cold_usec+=cold_usec
			audio_cached_usec+=cached_usec
			if cached!=audio:failures.append("V20.1 cache identity "+str(id))
			var pcm:PackedByteArray=audio.data
			var metrics:Dictionary=audio_quality_metrics(pcm)
			metrics["first_lookup_usec"]=cold_usec
			metrics["cached_lookup_usec"]=cached_usec
			audio_metrics[phase]=metrics
			var digest:String=str(metrics.pcm_sha256)
			if audio_digest_owners.has(digest):failures.append("V20.1 exact audio duplicate "+str(id)+" "+phase+" vs "+str(audio_digest_owners[digest]))
			audio_digest_owners[digest]=str(id)+":"+phase
			var similarity_key:String=str(profile.element)+":"+phase+":"+str(metrics.descriptor)
			if not audio_similarity_groups.has(similarity_key):audio_similarity_groups[similarity_key]=[]
			audio_similarity_groups[similarity_key].append(id)
			var acoustic_reasons:Array[String]=[]
			if float(metrics.rms)<.005:acoustic_reasons.append("low_rms")
			if absf(float(metrics.dc))>.025:acoustic_reasons.append("dc_offset")
			if float(metrics.max_step)>.8:acoustic_reasons.append("large_sample_step")
			if not acoustic_reasons.is_empty():
				var candidate:Dictionary={"id":id,"name":str(move.get("name",id)),"element":profile.element,"phase":phase,"reasons":acoustic_reasons,"metrics":metrics}
				audio_review_rows.append(candidate)
				print("KINDRIA_AUDIO_REVIEW ",JSON.stringify(candidate))
			if float(metrics.peak)>Dungeon.FX_AUDIO_PEAK_LIMIT+.0001:failures.append("V20.1 peak ceiling "+str(id))
			if float(metrics.max_step)>Dungeon.FX_AUDIO_STEP_LIMIT+.0001:failures.append("V20.6 sample step ceiling "+str(id)+" "+phase)
			checks+=1
			checks+=2
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
			if visible>Dungeon.FX_PARTICLE_CAP or view.fx_trail_vertices>Dungeon.FX_TRAIL_VERTEX_CAP or view.fx_halos_used>Dungeon.FX_HALO_CAP or view.fx_lights_used>Dungeon.FX_LIGHT_CAP:failures.append("world pool overflow "+str(id))
			runtime_samples+=1;checks+=1
		if not view.combat_bursts.is_empty() or max_visible==0:failures.append("world cast lifetime "+str(id))
		quality_rows.append({"id":id,"element":profile.element,"role":profile.role,"category":category,"distinct_frames":frame_hashes.size(),"blank_frames":blank_frames,"adjacent_repeats":repeat_count,"peak_visible_pixels":peak_visible,"impact_frame":impact_frame,"impact_visible_pixels":impact_visible,"max_border_ratio":max_border_ratio,"visible_pixels":visible_pixels,"border_pixels":border_pixels,"review_reasons":reasons,"sequence_sha256":signature,"audio_form":audio_form,"audio_peaks":audio_peaks,"audio_metrics":audio_metrics,"max_visible_particles":max_visible})
	# Coarse similarity groups are advisory; only exact PCM duplicates fail.
	var audio_similarity_review:Dictionary={}
	for group in audio_similarity_groups:
		if audio_similarity_groups[group].size()>1:
			audio_similarity_review[group]=audio_similarity_groups[group]
			print("KINDRIA_AUDIO_SIMILARITY ",JSON.stringify({"group":group,"ids":audio_similarity_groups[group]}))
	for priority in range(4):
		var ceiling:float=view.combat_audio_priority_ceiling(priority)
		if view.combat_audio_can_admit(ceiling,priority) or not view.combat_audio_can_admit(ceiling-.01,priority):failures.append("V20.1 early admission")
		checks+=1
	var audio_report:=FileAccess.open("/tmp/kindria-audio-quality.json",FileAccess.WRITE)
	if audio_report==null:failures.append("V20.1 audio report")
	else:
		audio_report.store_string(JSON.stringify({"samples":audio_total,"first_lookup_total_usec":audio_cold_usec,"cached_lookup_total_usec":audio_cached_usec,"exact_unique_pcm":audio_digest_owners.size(),"similarity_groups":audio_similarity_review,"review_candidates":audio_review_rows}, "\t"))
		audio_report.close()
	print("KINDRIA_AUDIO_QUALITY samples=",audio_total," exact_unique=",audio_digest_owners.size()," review_groups=",audio_similarity_review.size()," review_candidates=",audio_review_rows.size()," first_lookup_usec=",audio_cold_usec," cached_lookup_usec=",audio_cached_usec)
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
		report.store_string(JSON.stringify({"moves":quality_rows,"frame_total":frame_total,"audio_total":audio_total,"runtime_samples":runtime_samples,"duplicate_sequences":duplicate_groups,"review_candidates":review_candidates,"remastered_count":remastered.size(),"alpha_threshold":32,"secondary_cache_size":view.combat_textures.size()}, "\t"))
		report.close()
	var visual_index:=FileAccess.open(visual_dir+"/index.json",FileAccess.WRITE)
	if visual_index==null:failures.append("visual index export")
	else:
		visual_index.store_string(JSON.stringify(visual_rows,"\t"))
		visual_index.close()
	print("KINDRIA_VISUAL_EXPORT sequences=",quality_rows.size()," elements=",visual_rows.size()," frames=",frame_total)
	print("KINDRIA_FULL_QUALITY moves=",quality_rows.size()," frames=",frame_total," audio=",audio_total," runtime_samples=",runtime_samples," duplicate_groups=",duplicate_groups.size()," review_candidates=",review_candidates.size())
	scene.free()
	var home:=Home.new()
	home.free()
	view.free()
	print("CINEMATIC_GAUNTLET checks=",checks," failures=",failures.size())
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
