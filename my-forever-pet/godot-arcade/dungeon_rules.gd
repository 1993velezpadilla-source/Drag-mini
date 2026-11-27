extends RefCounted
# Original turn-based mystery dungeon. Seeded rooms, connected corridors, finite loot.
const DIR=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const MINION_ROSTER = [[["bramble_pup","Bramble Pup","quadruped_bound","Briar Pounce",0],["sporeling","Sporeling","mushroom_stem_steps","Spore Puff",1],["thornbeetle","Thornbeetle","six_leg_tripod","Thorn Ram",2],["leafwisp","Leafwisp","leaf_flutter","Leaf Dart",1],["rootgnawer","Rootgnawer","boar_trot","Root Tusk",0],["vinesnap","VineSnap","root_pull","Snap Vine",2],["mossmite","Mossmite","rock_roll","Moss Crash",0],["sylphowl","Sylphowl","owl_flap","Feather Needle",1],["hollow_stag","Hollow Stag","deer_prance","Antler Sweep",2],["grovetitan","Grovetitan","tree_biped_stride","Timber Slam",2],["fungal_monarch","Fungal Monarch","mycelial_tripod","Spore Crown",3]],[["reef_pup","Reef Pup","fish_tail_swim","Reef Bite",0],["jellymancer","Jellymancer","bell_jet_pulse","Sting Pulse",1],["shellguard","Shellguard","turtle_paddle","Shell Bash",2],["bubblewisp","Bubblewisp","bubble_buoyancy","Bubble Shot",1],["eelstrix","Eelstrix","eel_wave_swim","Static Lash",0],["coralcrab","Coralcrab","crab_lateral_steps","Claw Snap",0],["anemoneye","Anemoneye","pedal_disc_creep","Tentacle Snare",2],["marrowray","Marrowray","ray_fin_undulation","Fin Slice",1],["leviathorn","Leviathorn","seahorse_dorsal_pulse","Spiral Thrust",2],["abyss_colossus","Abyss Colossus","octopus_arm_crawl","Abyss Crush",2],["tidal_sovereign","Tidal Sovereign","shark_tail_drive","Tidal Bite",3]],[["starlit_pup","Starlit Pup","six_limbed_comet_skip","Star Kick",0],["lunamoth","Lunamoth","moth_wing_clap","Lunar Dust",1],["crystarok","Crystarok","crystal_knuckle_walk","Prism Smash",2],["nova_wisp","Nova Wisp","orbit_drift","Nova Bolt",1],["orbitserpent","Orbitserpent","ring_coil_advance","Orbit Lash",0],["comet_hare","Comet Hare","hind_leg_leap","Comet Drop",0],["voidspider","Voidspider","eight_leg_wave","Gravity Web",2],["nebulwing","Nebulwing","bat_fold_glide","Void Screech",1],["lunar_prowler","Lunar Prowler","feline_stalk","Moon Claw",2],["astro_golem","Astro Golem","floating_segment_stride","Meteor Fist",2],["celestial_guardian","Celestial Guardian","winged_hover","Celestial Verdict",3]]]
# Row: stable species ID, display name, anatomy-specific gait, signature move, combat class.
# Species attack contract: range, telegraph, cooldown, damage modifier, effect, magnitude, VFX identifier.
const SIGNATURE_SKILLS={"bramble_pup":[2,false,2,0,"pounce",1,"briar_arc"],"sporeling":[2,false,3,-1,"poison",2,"spore_cloud"],"thornbeetle":[2,true,2,1,"pounce",1,"horn_ram"],"leafwisp":[3,false,2,-1,"none",0,"leaf_dart"],"rootgnawer":[1,false,2,1,"mark",1,"tusk_sweep"],"vinesnap":[2,true,2,0,"weaken",1,"vine_snap"],"mossmite":[2,false,3,0,"guard",1,"rolling_moss"],"sylphowl":[3,false,3,0,"none",0,"feather_fan"],"hollow_stag":[1,true,2,2,"mark",1,"antler_arc"],"grovetitan":[1,true,3,2,"guard",2,"timber_shock"],"fungal_monarch":[2,true,3,1,"poison",3,"royal_spores"],"reef_pup":[1,false,1,0,"none",0,"reef_bite"],"jellymancer":[2,false,3,-1,"drain",1,"jelly_pulse"],"shellguard":[1,true,2,0,"guard",3,"shell_impact"],"bubblewisp":[3,false,3,-1,"weaken",1,"bubble_burst"],"eelstrix":[2,false,2,0,"drain",1,"electric_lash"],"coralcrab":[1,false,2,1,"guard",1,"double_pincer"],"anemoneye":[2,true,3,0,"weaken",2,"tentacle_snare"],"marrowray":[3,false,2,0,"mark",1,"fin_slice"],"leviathorn":[2,true,2,1,"pounce",1,"spiral_current"],"abyss_colossus":[2,true,3,2,"weaken",1,"abyss_grasp"],"tidal_sovereign":[2,true,2,3,"mark",1,"tidal_jaws"],"starlit_pup":[1,false,2,1,"none",0,"star_kick"],"lunamoth":[2,false,3,-1,"weaken",2,"lunar_dust"],"crystarok":[1,true,2,1,"guard",2,"prism_shatter"],"nova_wisp":[3,false,3,0,"drain",1,"nova_bolt"],"orbitserpent":[2,false,2,0,"mark",1,"orbit_lash"],"comet_hare":[2,false,2,1,"pounce",1,"comet_drop"],"voidspider":[2,true,3,0,"mark",2,"gravity_web"],"nebulwing":[3,false,3,-1,"drain",2,"sonic_cone"],"lunar_prowler":[1,true,2,2,"none",0,"moon_claw"],"astro_golem":[3,true,3,1,"none",0,"meteor_fist"],"celestial_guardian":[3,true,3,2,"drain",2,"celestial_verdict"]}
const ATTACK_PATTERNS={"bramble_pup":"line","sporeling":"radius","thornbeetle":"line","leafwisp":"line","rootgnawer":"front","vinesnap":"corner","mossmite":"line","sylphowl":"fan","hollow_stag":"fan","grovetitan":"radius","fungal_monarch":"radius","reef_pup":"front","jellymancer":"radius","shellguard":"front","bubblewisp":"corner","eelstrix":"line","coralcrab":"fan","anemoneye":"corner","marrowray":"line","leviathorn":"line","abyss_colossus":"radius","tidal_sovereign":"fan","starlit_pup":"front","lunamoth":"fan","crystarok":"radius","nova_wisp":"line","orbitserpent":"corner","comet_hare":"line","voidspider":"corner","nebulwing":"fan","lunar_prowler":"front","astro_golem":"corner","celestial_guardian":"cross"}
var enemy_actions:Array[Dictionary]=[]
var player_attack_fx:String="basic_strike"
var player_attack_cells:Array[Vector2i]=[]
# A footprint maps each legal target to its exact unobstructed travel path.
func attack_footprint(origin:Vector2i,forward:Vector2i,pattern:String,reach:int)->Dictionary:
	var out:Dictionary={}
	var directions:Array=[forward]
	if pattern in ["radius","cross"]:directions=DIR
	if pattern=="front":reach=1
	for d in directions:
		var path:Array[Vector2i]=[]
		for distance_index in range(1,reach+1):
			var q:Vector2i=origin+d*distance_index
			if not cells.has(q) or enemy_at(q)>=0:break
			path.append(q)
			out[q]=path.duplicate()
			if pattern in ["corner","fan","radius"]:
				for sign_side in [-1,1]:
					var turn:=Vector2i(-d.y,d.x)*int(sign_side)
					var branch:Array[Vector2i]=path.duplicate()
					var limit:int=reach-distance_index if pattern!="fan" else mini(1,reach-distance_index+1)
					for j in range(1,limit+1):
						var target:=q+turn*j
						if not cells.has(target) or enemy_at(target)>=0:break
						# Fan can hit front diagonals, but not through two blocked orthogonal cells.
						branch.append(target)
						if not out.has(target) or branch.size()<out[target].size():out[target]=branch.duplicate()
	return out
func attack_aim(origin:Vector2i,target:Vector2i,pattern:String,reach:int)->Vector2i:
	var delta:=target-origin
	var preferred:=Vector2i(signi(delta.x),0) if absi(delta.x)>absi(delta.y) else Vector2i(0,signi(delta.y))
	if preferred!=Vector2i.ZERO and attack_footprint(origin,preferred,pattern,reach).has(target):return preferred
	for d in DIR:
		if attack_footprint(origin,d,pattern,reach).has(target):return d
	return Vector2i.ZERO
func warning_tiles(enemy:Dictionary)->Array:
	if not enemy.get("windup",false):return []
	var skill:=signature_skill(enemy)
	return attack_footprint(enemy.pos,enemy.get("aim",Vector2i.DOWN),str(ATTACK_PATTERNS.get(enemy.get("species",""),"line")),int(skill[0])).keys()

var poison_turns:int=0
var weakened_strikes:int=0
var marked_damage:int=0
func signature_skill(enemy:Dictionary)->Array:
	var kind:int=int(enemy.get("kind",0))
	return SIGNATURE_SKILLS.get(str(enemy.get("species","")),[2 if kind==1 else 1,kind>=2,1,0,"none",0,"basic_strike"])
func clear_combat_effects()->void:
	poison_turns=0;weakened_strikes=0;marked_damage=0
func line_of_attack(from:Vector2i,to:Vector2i,reach:int)->bool:
	var gap:=distance(from,to)
	if gap<1 or gap>reach or (from.x!=to.x and from.y!=to.y):return false
	var direction:=Vector2i(signi(to.x-from.x),signi(to.y-from.y))
	for i in range(1,gap):
		var q:=from+direction*i
		if not cells.has(q) or enemy_at(q)>=0:return false
	return cells.has(to)
func apply_signature_effect(i:int,skill:Array)->void:
	var amount:int=int(skill[5])
	match str(skill[4]):
		"poison":poison_turns=maxi(poison_turns,amount)
		"weaken":weakened_strikes=maxi(weakened_strikes,amount)
		"mark":marked_damage=maxi(marked_damage,amount)
		"drain":energy=maxi(0,energy-amount)
		"guard":enemies[i]["guard"]=amount
		"pounce":
			var from:Vector2i=enemies[i].pos
			if distance(from,player)==2 and (from.x==player.x or from.y==player.y):
				var q:=from+Vector2i(signi(player.x-from.x),signi(player.y-from.y))
				if cells.has(q) and enemy_at(q)<0 and q!=player:enemies[i].pos=q

func enemy_profile(kind:int,uid:int)->Array:
	var pool:Array=[]
	for row in MINION_ROSTER[clampi(region,0,2)]:
		if int(row[4])==kind:pool.append(row)
	return pool[posmod(seed_value+floor_number*3+uid*5,pool.size())]
func make_enemy(p:Vector2i,life:int,kind:int,uid:int)->Dictionary:
	var profile:=enemy_profile(kind,uid)
	return {"uid":uid,"pos":p,"hp":life,"max_hp":life,"kind":kind,"windup":false,"species":profile[0],"name":profile[1],"gait":profile[2],"signature":profile[3]}
var rng=RandomNumberGenerator.new()
var region=0
var floor_number=1
var floor_count=3
var tier=0
var player=Vector2i.ZERO
var stairs=Vector2i.ZERO
var relic=Vector2i.ZERO
var cells:Dictionary={}
var rooms:Array[Rect2i]=[]
var enemies:Array[Dictionary]=[]
var loot:Dictionary={}
var revealed:Dictionary={}
var hp=36
var max_hp=36
var potions=2
var energy=8
var coins=0
var materials=0
var hits=0
var turns=0
var secured=false
var finished=false
var success=false
var message=""
var seed_value=0
var floor_revision=0
var floor_style=0
var defeated=0
var combo=0
var best_combo=0
var skill_kind=0
var traps:Dictionary={}
var rescue_finale=false
var specimen=0
var guardian_defeated=false
var event_serial=0
var last_event=""
var attack_serial=0
var attack_target=Vector2i.ZERO
var attack_power=false
var explored_rooms:Dictionary={}
var floor_bonus=0
var total_bonus=0
var floor_kind=0
var player_rested=false
func setup(r:int,id:int,step:int,finale:bool,patrol:bool,seed_id:int,companion:int=0):
	region=r;seed_value=seed_id;skill_kind=posmod(companion,3);rescue_finale=finale;specimen=id
	tier=0 if patrol or id<12 else 1 if id<24 else 2
	floor_count=2 if patrol else 3+tier+(1 if finale else 0)
	max_hp=42+4*tier;hp=max_hp
	generate_floor()
func distance(a:Vector2i,b:Vector2i)->int:
	return absi(a.x-b.x)+absi(a.y-b.y)
func center(room:Rect2i)->Vector2i:
	return room.position+Vector2i(room.size.x/2,room.size.y/2)
func connect_cells(a:Vector2i,b:Vector2i):
	var p=a;cells[p]=true
	if rng.randi_range(0,1)==0:
		while p.x!=b.x:
			p.x+=signi(b.x-p.x);cells[p]=true
		while p.y!=b.y:
			p.y+=signi(b.y-p.y);cells[p]=true
	else:
		while p.y!=b.y:
			p.y+=signi(b.y-p.y);cells[p]=true
		while p.x!=b.x:
			p.x+=signi(b.x-p.x);cells[p]=true
func build_layout():
	# Independent implementation: variable sector occupancy, random room sizes,
	# connected spanning tree, extra loops and imperfect corner cuts.
	var grids=[Vector2i(3,2),Vector2i(2,3),Vector2i(3,3),Vector2i(4,2)]
	var grid:Vector2i=grids[rng.randi_range(0,grids.size()-1)]
	var slots:Array[Vector2i]=[]
	for y in range(grid.y):
		for x in range(grid.x):slots.append(Vector2i(x,y))
	for i in range(slots.size()-1,0,-1):
		var j=rng.randi_range(0,i);var swap=slots[i];slots[i]=slots[j];slots[j]=swap
	var room_count=rng.randi_range(4,slots.size())
	for i in range(room_count):
		var slot=slots[i]
		var width=rng.randi_range(5,7);var height=rng.randi_range(5,7)
		var origin=slot*9+Vector2i(rng.randi_range(1,9-width-1),rng.randi_range(1,9-height-1))
		var room=Rect2i(origin,Vector2i(width,height));rooms.append(room)
		var cut=rng.randi_range(0,3)
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x):
				var corner_x=x==room.position.x or x==room.end.x-1
				var corner_y=y==room.position.y or y==room.end.y-1
				if cut>0 and corner_x and corner_y and rng.randi_range(0,3)<cut:continue
				cells[Vector2i(x,y)]=true
	var reached:Array[int]=[0]
	var links:Dictionary={}
	while reached.size()<rooms.size():
		var best=99999;var source=0;var destination=-1
		for i in reached:
			for j in range(rooms.size()):
				if j in reached:continue
				var score=distance(center(rooms[i]),center(rooms[j]))*4+rng.randi_range(0,12)
				if score<best:best=score;source=i;destination=j
		connect_cells(center(rooms[source]),center(rooms[destination]))
		links[Vector2i(mini(source,destination),maxi(source,destination))]=true
		reached.append(destination)
	var extra=rng.randi_range(0,mini(4,room_count-2))
	for n in range(extra):
		var i=rng.randi_range(0,room_count-1);var j=rng.randi_range(0,room_count-1)
		var key=Vector2i(mini(i,j),maxi(i,j))
		if i!=j and not links.has(key) and distance(center(rooms[i]),center(rooms[j]))<=20:
			connect_cells(center(rooms[i]),center(rooms[j]));links[key]=true
	player=center(rooms[0])
	var farthest=-1;var exit_index=1
	for i in range(1,rooms.size()):
		var steps=route(player,center(rooms[i])).size()
		if steps>farthest:farthest=steps;exit_index=i
	stairs=center(rooms[exit_index])
	var choices:Array[int]=[]
	for i in range(1,rooms.size()):
		if i!=exit_index:choices.append(i)
	relic=center(rooms[choices[rng.randi_range(0,choices.size()-1)]])
func generate_floor():
	clear_combat_effects()
	enemy_actions.clear()
	rng.seed=seed_value+floor_number*7919
	cells.clear();rooms.clear();enemies.clear();loot.clear();revealed.clear();traps.clear();explored_rooms.clear()
	floor_bonus=0;player_rested=false
	floor_style=posmod(seed_value+floor_number,3)
	floor_kind=0 if floor_number==1 else posmod(seed_value*3+floor_number*7,5)
	secured=false;guardian_defeated=not (rescue_finale and floor_number==floor_count);floor_revision+=1
	build_layout()

	var spots:Array= cells.keys()
	for i in range(spots.size()-1,0,-1):
		var j=rng.randi_range(0,i);var temp=spots[i];spots[i]=spots[j];spots[j]=temp
	var count=mini(7,2+floor_number+tier)
	if floor_kind==1:count=maxi(2,count-2)
	if floor_kind==2:count=mini(8,count+1)
	for p in spots:
		if p==player or p==stairs or p==relic or distance(p,player)<4:continue
		if enemies.size()<count:
			var life=8+floor_number*2+tier*2
			enemies.append(make_enemy(p,life,rng.randi_range(0,2),enemies.size()))
		elif loot.size()<(14 if floor_kind==1 else 9):
			loot[p]="potion" if loot.size()%4==0 else "material" if loot.size()%3==0 else "coin"
		elif traps.size()<floor_number-1:traps[p]=true
		else:break
	loot[relic]="relic"
	if floor_kind==3:
		var spring=center(rooms[1])
		if enemy_at(spring)>=0 or spring==relic or spring==stairs:
			for p in spots:
				if rooms[1].has_point(p) and enemy_at(p)<0 and p!=relic and p!=stairs:
					spring=p;break
		if spring!=relic and spring!=stairs and enemy_at(spring)<0:
			loot[spring]="spring";traps.erase(spring)
	if not guardian_defeated:
		var life=24+6*tier
		enemies.append(make_enemy(relic,life,3,99))
	# A guaranteed immediate pickup introduces the loop on every floor.
	for d in DIR:
		var p:Vector2i=player+d
		if cells.has(p) and not loot.has(p):
			loot[p]="coin";break
	energy=mini(8,energy+2)
	reveal()
	message="Guardian chamber · Rescue the creature" if not guardian_defeated else "B%d · Find the relic and stairs"%floor_number
func enemy_at(p:Vector2i)->int:
	for i in range(enemies.size()):
		if enemies[i].pos==p:return i
	return -1
func route(a:Vector2i,b:Vector2i,avoid_enemies:bool=false)->Array[Vector2i]:
	var result:Array[Vector2i]=[]
	if not cells.has(a) or not cells.has(b) or a==b:return result
	var queue:Array[Vector2i]=[a]
	var previous:Dictionary={}
	previous[a]=a
	var cursor=0
	while cursor<queue.size():
		var p=queue[cursor];cursor+=1
		if p==b:break
		for d in DIR:
			var q:Vector2i=p+d
			if not cells.has(q) or previous.has(q):continue
			if avoid_enemies and q!=b and enemy_at(q)>=0:continue
			previous[q]=p;queue.append(q)
	if not previous.has(b):return result
	var p=b
	while p!=a:
		result.push_front(p);p=previous[p]
	return result
func reveal():
	for i in range(rooms.size()):
		if rooms[i].has_point(player) and not explored_rooms.has(i):
			explored_rooms[i]=true
	for p in cells:
		if distance(p,player)<=5:revealed[p]=true
	for room in rooms:
		if room.has_point(player):
			for p in cells:
				if room.has_point(p):revealed[p]=true
func emit_event(value:String):
	last_event=value;event_serial+=1
func pickup():
	if not loot.has(player):return
	if player==relic and not guardian_defeated:return
	var kind:String=loot[player]
	loot.erase(player)
	match kind:
		"coin":coins+=3;message="+3 coins"
		"potion":potions+=1;message="Healing berry found"
		"material":materials+=1;message="+1 crafting material"
		"spring":hp=mini(max_hp,hp+18);energy=mini(8,energy+3);player_rested=true;message="Restorative spring · HP and skill restored"
		"relic":secured=true;message="Relic secured! Find the stairs"
	emit_event(message)
func strike(i:int,power:bool=false):
	if i<0 or i>=enemies.size():return
	attack_serial+=1;attack_target=enemies[i].pos;attack_power=power
	player_attack_fx="basic_strike" if not power else ["briar_arc","nova_bolt","jelly_pulse"][skill_kind]
	player_attack_cells=[attack_target]
	if power and distance(player,attack_target)==2:player_attack_cells.push_front(player+(attack_target-player)/2)
	var damage:int=10 if power else 6
	if weakened_strikes>0:
		damage=maxi(1,damage-1);weakened_strikes-=1
	var guard:int=int(enemies[i].get("guard",0))
	if guard>0:
		damage=maxi(1,damage-guard);enemies[i]["guard"]=0
	enemies[i].hp=int(enemies[i].hp)-damage
	message="-%d HP · strike!"%damage
	emit_event("−%d HP"%damage)
	if int(enemies[i].hp)<=0:
		var guardian=int(enemies[i].kind)==3
		enemies.remove_at(i);defeated+=1;combo+=1;best_combo=maxi(best_combo,combo)
		if guardian:guardian_defeated=true
		var reward=(12 if guardian else 2)+mini(3,combo-1);coins+=reward;message="Guardian defeated! +%d coins"%reward if guardian else "Enemy defeated! +%d coins · Combo %d"%[reward,combo]
		emit_event(message)
func enemy_turn():
	enemy_actions.clear()
	turns+=1
	if poison_turns>0:
		poison_turns-=1;hp=maxi(0,hp-1)
		if hp==0:
			finished=true;success=false;message="Poison · rescue needed";emit_event(message);return
	for i in range(enemies.size()):
		var p:Vector2i=enemies[i].pos
		var gap:=distance(p,player)
		var kind:int=int(enemies[i].kind)
		var skill:=signature_skill(enemies[i])
		var charged:bool=enemies[i].get("windup",false)
		var cooldown:int=int(enemies[i].get("cooldown",0))
		var ready:bool=cooldown<=0
		if cooldown>0:enemies[i]["cooldown"]=cooldown-1
		var pattern:String=ATTACK_PATTERNS.get(enemies[i].get("species",""),"line")
		var aim:Vector2i=enemies[i].get("aim",Vector2i.ZERO) if charged else attack_aim(p,player,pattern,int(skill[0]))
		var footprint:Dictionary=attack_footprint(p,aim,pattern,int(skill[0])) if aim!=Vector2i.ZERO else {}
		var in_range:bool=footprint.has(player)
		if charged and not in_range:
			enemies[i].windup=false
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"cancel","from":p,"to":p+aim,"move":enemies[i].get("signature","Strike")})
			continue
		if ready and in_range and bool(skill[1]) and not charged:
			enemies[i].windup=true;enemies[i]["aim"]=aim
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"windup","from":p,"to":p+aim,"move":enemies[i].get("signature","Heavy attack"),"fx":skill[6],"tiles":footprint.keys()})
			message="%s charging %s!"%[enemies[i].get("name","Enemy"),enemies[i].get("signature","Heavy attack")]
			continue
		if (ready and in_range) or (gap==1 and not ready):
			enemies[i].windup=false
			var special:bool=ready and in_range
			var damage:int=2+tier+int(floor_number/3)+(2 if kind>=2 else 0)
			if special:damage=maxi(1,damage+int(skill[3]))
			else:damage=maxi(1,damage-1)
			if marked_damage>0:damage+=marked_damage;marked_damage=0
			hp=maxi(0,hp-damage);hits+=1;combo=0
			var move_name:String=str(enemies[i].get("signature","Strike")) if special else "Quick strike"
			var effect:String=str(skill[4]) if special else "none"
			if special:
				enemies[i]["cooldown"]=maxi(0,int(skill[2])-1)
				apply_signature_effect(i,skill)
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"attack","from":p,"to":player,"end":enemies[i].pos,"move":move_name,"fx":skill[6] if special else "basic_strike","effect":effect,"damage":damage,"aim":aim if special else player-p,"pattern":pattern if special else "front","tiles":footprint.keys() if special else [player],"path":footprint.get(player,[player]) if special else [player]})
			message="%s · %s! −%d HP"%[enemies[i].get("name","Enemy"),move_name,damage]
			if effect!="none":message+=" · "+effect.capitalize()
			emit_event(message)
			if hp==0:
				finished=true;success=false;message="Rescue needed · expedition lost";return
		elif gap<=6 and kind!=3:
			var path=route(p,player,true)
			if not path.is_empty() and path[0]!=player and enemy_at(path[0])<0:
				enemies[i].pos=path[0]
				enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":path[0],"gait":enemies[i].get("gait","walk")})
	reveal()
func move(p:Vector2i)->bool:
	if finished or not cells.has(p) or distance(player,p)!=1:return false
	var i=enemy_at(p)
	if i>=0:strike(i)
	else:
		player=p;pickup()
		if traps.has(player):
			traps.erase(player);hp=maxi(1,hp-3);hits+=1;combo=0;message="Trap! −3 HP";emit_event(message)
	enemy_turn()
	return true
func attack(power:bool=false,aim:Vector2i=Vector2i.ZERO)->bool:
	if finished or (power and energy<2):return false
	var directions:Array=DIR if aim==Vector2i.ZERO else [aim]
	if power and skill_kind==1:
		for d in directions:
			if not cells.has(player+d) or enemy_at(player+d)>=0:continue
			var ranged=enemy_at(player+d*2)
			if ranged>=0:energy-=2;strike(ranged,true);enemy_turn();return true
	for d in directions:
		var i=enemy_at(player+d)
		if i>=0:
			if power:energy-=2
			strike(i,power)
			if power and skill_kind==2:hp=mini(max_hp,hp+4)
			enemy_turn();return true
	message="No enemy in that direction";return false
func heal()->bool:
	if finished or potions<=0 or hp==max_hp:return false
	potions-=1;hp=mini(max_hp,hp+20);message="Recovered HP";emit_event(message);enemy_turn();return true
func descend()->bool:
	if finished or player!=stairs or not secured:return false
	floor_bonus=mini(6,maxi(0,explored_rooms.size()-2)*2);coins+=floor_bonus;total_bonus+=floor_bonus
	if floor_number>=floor_count:
		finished=true;success=true;message="Expedition complete!";return true
	floor_number+=1;hp=mini(max_hp,hp+10);generate_floor();return true
