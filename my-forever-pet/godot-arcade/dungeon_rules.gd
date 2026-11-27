extends RefCounted
# Original turn-based mystery dungeon. Seeded rooms, connected corridors, finite loot.
const DIR=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const MINION_ROSTER = [[["bramble_pup","Bramble Pup","quadruped_bound","Briar Pounce",0],["sporeling","Sporeling","mushroom_stem_steps","Spore Puff",1],["thornbeetle","Thornbeetle","six_leg_tripod","Thorn Ram",2],["leafwisp","Leafwisp","leaf_flutter","Leaf Dart",1],["rootgnawer","Rootgnawer","boar_trot","Root Tusk",0],["vinesnap","VineSnap","root_pull","Snap Vine",2],["mossmite","Mossmite","rock_roll","Moss Crash",0],["sylphowl","Sylphowl","owl_flap","Feather Needle",1],["hollow_stag","Hollow Stag","deer_prance","Antler Sweep",2],["grovetitan","Grovetitan","tree_biped_stride","Timber Slam",2],["fungal_monarch","Fungal Monarch","mycelial_tripod","Spore Crown",3]],[["reef_pup","Reef Pup","fish_tail_swim","Reef Bite",0],["jellymancer","Jellymancer","bell_jet_pulse","Sting Pulse",1],["shellguard","Shellguard","turtle_paddle","Shell Bash",2],["bubblewisp","Bubblewisp","bubble_buoyancy","Bubble Shot",1],["eelstrix","Eelstrix","eel_wave_swim","Static Lash",0],["coralcrab","Coralcrab","crab_lateral_steps","Claw Snap",0],["anemoneye","Anemoneye","pedal_disc_creep","Tentacle Snare",2],["marrowray","Marrowray","ray_fin_undulation","Fin Slice",1],["leviathorn","Leviathorn","seahorse_dorsal_pulse","Spiral Thrust",2],["abyss_colossus","Abyss Colossus","octopus_arm_crawl","Abyss Crush",2],["tidal_sovereign","Tidal Sovereign","shark_tail_drive","Tidal Bite",3]],[["starlit_pup","Starlit Pup","six_limbed_comet_skip","Star Kick",0],["lunamoth","Lunamoth","moth_wing_clap","Lunar Dust",1],["crystarok","Crystarok","crystal_knuckle_walk","Prism Smash",2],["nova_wisp","Nova Wisp","orbit_drift","Nova Bolt",1],["orbitserpent","Orbitserpent","ring_coil_advance","Orbit Lash",0],["comet_hare","Comet Hare","hind_leg_leap","Comet Drop",0],["voidspider","Voidspider","eight_leg_wave","Gravity Web",2],["nebulwing","Nebulwing","bat_fold_glide","Void Screech",1],["lunar_prowler","Lunar Prowler","feline_stalk","Moon Claw",2],["astro_golem","Astro Golem","floating_segment_stride","Meteor Fist",2],["celestial_guardian","Celestial Guardian","winged_hover","Celestial Verdict",3]]]
# Row: stable species ID, display name, anatomy-specific gait, signature move, combat class.
var enemy_actions:Array[Dictionary]=[]
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
	var damage=10 if power else 6
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
	for i in range(enemies.size()):
		var p:Vector2i=enemies[i].pos
		var gap=distance(p,player)
		var kind:int=enemies[i].kind
		var straight=p.x==player.x or p.y==player.y
		var ranged=kind==1 and gap==2 and straight and cells.has(p+(player-p)/2) and enemy_at(p+(player-p)/2)<0
		var heavy=kind>=2
		var charged:bool=enemies[i].get("windup",false)
		if charged and gap!=1:
			enemies[i].windup=false
			continue
		if gap==1 and heavy and not charged:
			enemies[i].windup=true
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"windup","from":p,"to":player,"move":enemies[i].get("signature","Heavy attack")})
			message="Guardian charging!" if kind==3 else "Heavy attack incoming!"
			continue
		if gap==1 or ranged:
			enemies[i].windup=false
			var damage=2+tier+int(floor_number/3)+(2 if heavy else 0)
			hp=maxi(0,hp-damage);hits+=1;combo=0
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"attack","from":p,"to":player,"move":enemies[i].get("signature","Strike")})
			message="%s · %s! −%d HP"%[enemies[i].get("name","Enemy"),enemies[i].get("signature","Strike"),damage];emit_event(message)
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
func attack(power:bool=false)->bool:
	if finished or (power and energy<2):return false
	if power and skill_kind==1:
		# A ranged strike reaches two tiles only through traversable ground.
		for d in DIR:
			if not cells.has(player+d) or enemy_at(player+d)>=0:continue
			var ranged=enemy_at(player+d*2)
			if ranged>=0:energy-=2;strike(ranged,true);enemy_turn();return true
	for d in DIR:
		var i=enemy_at(player+d)
		if i>=0:
			if power:energy-=2
			strike(i,power)
			if power and skill_kind==2:hp=mini(max_hp,hp+4)
			enemy_turn();return true
	message="No enemy in reach";return false
func heal()->bool:
	if finished or potions<=0 or hp==max_hp:return false
	potions-=1;hp=mini(max_hp,hp+20);message="Recovered HP";emit_event(message);enemy_turn();return true
func descend()->bool:
	if finished or player!=stairs or not secured:return false
	floor_bonus=mini(6,maxi(0,explored_rooms.size()-2)*2);coins+=floor_bonus;total_bonus+=floor_bonus
	if floor_number>=floor_count:
		finished=true;success=true;message="Expedition complete!";return true
	floor_number+=1;hp=mini(max_hp,hp+10);generate_floor();return true
