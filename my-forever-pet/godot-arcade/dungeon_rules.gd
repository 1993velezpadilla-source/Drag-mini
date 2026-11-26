extends RefCounted
# Original turn-based mystery dungeon. Seeded rooms, connected corridors, finite loot.
const DIR=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
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
func setup(r:int,id:int,step:int,finale:bool,patrol:bool,seed_id:int):
	region=r;seed_value=seed_id
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
func generate_floor():
	rng.seed=seed_value+floor_number*7919
	cells.clear();rooms.clear();enemies.clear();loot.clear();revealed.clear()
	secured=false;floor_revision+=1
	for y in range(2):
		for x in range(3):
			var room=Rect2i(Vector2i(1+x*7+rng.randi_range(0,1),1+y*7+rng.randi_range(0,1)),Vector2i(rng.randi_range(4,5),rng.randi_range(4,5)))
			rooms.append(room)
			for j in range(room.position.y,room.end.y):
				for i in range(room.position.x,room.end.x):cells[Vector2i(i,j)]=true
	for i in range(1,6):
		if i%3!=0:connect_cells(center(rooms[i-1]),center(rooms[i]))
		else:connect_cells(center(rooms[i-3]),center(rooms[i]))
	connect_cells(center(rooms[2]),center(rooms[5]))
	player=center(rooms[0]);stairs=center(rooms[5]);relic=center(rooms[4])
	var spots:Array= cells.keys()
	for i in range(spots.size()-1,0,-1):
		var j=rng.randi_range(0,i);var temp=spots[i];spots[i]=spots[j];spots[j]=temp
	var count=mini(7,2+floor_number+tier)
	for p in spots:
		if p==player or p==stairs or p==relic or distance(p,player)<4:continue
		if enemies.size()<count:
			enemies.append({"pos":p,"hp":8+floor_number*2+tier*2,"kind":rng.randi_range(0,2)})
		elif loot.size()<9:
			loot[p]="potion" if loot.size()%4==0 else "material" if loot.size()%3==0 else "coin"
		else:break
	loot[relic]="relic"
	# A guaranteed immediate pickup introduces the loop on every floor.
	for d in DIR:
		var p:Vector2i=player+d
		if cells.has(p) and not loot.has(p):
			loot[p]="coin";break
	energy=mini(8,energy+2)
	reveal()
	message="B%d · Find the relic and stairs"%floor_number
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
	for p in cells:
		if distance(p,player)<=5:revealed[p]=true
	for room in rooms:
		if room.has_point(player):
			for p in cells:
				if room.has_point(p):revealed[p]=true
func pickup():
	if not loot.has(player):return
	var kind:String=loot[player]
	loot.erase(player)
	match kind:
		"coin":coins+=3;message="+3 coins"
		"potion":potions+=1;message="Healing berry found"
		"material":materials+=1;message="+1 crafting material"
		"relic":secured=true;message="Relic secured! Find the stairs"
func strike(i:int,power:bool=false):
	if i<0 or i>=enemies.size():return
	var damage=10 if power else 6
	enemies[i].hp=int(enemies[i].hp)-damage
	message="-%d HP · strike!"%damage
	if int(enemies[i].hp)<=0:
		enemies.remove_at(i);coins+=2;message="Enemy defeated! +2 coins"
func enemy_turn():
	turns+=1
	for i in range(enemies.size()):
		var p:Vector2i=enemies[i].pos
		var gap=distance(p,player)
		if gap==1:
			var damage=2+tier+int(floor_number/3)
			hp=maxi(0,hp-damage);hits+=1
			message="Hit! −%d HP"%damage
			if hp==0:
				finished=true;success=false;message="Rescue needed · expedition lost";return
		elif gap<=6:
			var path=route(p,player)
			if not path.is_empty() and path[0]!=player and enemy_at(path[0])<0:enemies[i].pos=path[0]
	reveal()
func move(p:Vector2i)->bool:
	if finished or not cells.has(p) or distance(player,p)!=1:return false
	var i=enemy_at(p)
	if i>=0:strike(i)
	else:
		player=p;pickup()
	enemy_turn()
	return true
func attack(power:bool=false)->bool:
	if finished or (power and energy<2):return false
	for d in DIR:
		var i=enemy_at(player+d)
		if i>=0:
			if power:energy-=2
			strike(i,power);enemy_turn();return true
	message="No enemy in reach";return false
func heal()->bool:
	if finished or potions<=0 or hp==max_hp:return false
	potions-=1;hp=mini(max_hp,hp+20);message="Recovered HP";enemy_turn();return true
func descend()->bool:
	if finished or player!=stairs or not secured:return false
	if floor_number>=floor_count:
		finished=true;success=true;message="Expedition complete!";return true
	floor_number+=1;hp=mini(max_hp,hp+10);generate_floor();return true
