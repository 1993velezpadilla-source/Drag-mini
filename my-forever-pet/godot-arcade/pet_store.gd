extends Node
# Independent Godot port of native PetState. Time in seconds, persisted in one wallet.
const SAVE="user://forever_pet_v1.json"
const SPECIES=["Mosskit","Mewmew","Barkle","Dracoon","Bubblefin","Neblito","Wispurr","Octoboo","Roostik","Fayli","Pixsy","Puffowl","Fernhorn","Moonmew","Cloverbark","Emberdrake","Pearlfin","NovaNeb","Lunawisp","Reefboo","Suncrest","Aurorafay","Stardust Pixsy","Dreamowl"]
const STAGES=["Egg","Baby","Kid","Young","Adult"]
const FIELDS=["Land","Water","Sky"]
const FOODS=["Meat","Carrot","Fish","Grain"]
const FOOD_COST=[4,2,3,0]
const ITEMS=["Star cap","Berry ribbon","Moon halo","Garden bath","Cloud bed","Flower stand"]
const PRICES=[40,50,75,80,100,60]
const CLOTHES=["Explorer cap","Round glasses","Adventure tee","Midnight tuxedo","Trail sneakers","Pilot goggles","Beanie","Space suit"]
const COST=[120,150,180,240,160,170,100,300]
const SLOT=[0,1,2,2,3,1,0,2]
var s:Dictionary={}
var arcade_mode=-1
var test_mode=false
var dirty=false
func defaults()->Dictionary:
	return {"stage":0,"field":0,"body":0,"eyes":0,"color":0,"variant":0,"generation":1,"friendship":0,"inherited_eyes":-1,"name":"","hunger":5,"happy":10,"energy":100,"bond":0,"xp":0,"waste":0,"mistakes":0,"germs":0,"hygiene":100,"toilet":100,"coins":0,"crystals":0,"materials":0,"fuel":0,"snacks":0,"medicine":0,"soap":0,"cells":[0,0,0],"foods":[0,0,0,0],"collection":0,"owned":0,"equipped":0,"installation":0,"wardrobe":0,"worn":[0,0,0,0],"theme":0,"training":0,"age":0.0,"last":0.0,"food_clock":0.0,"mood_clock":0.0,"energy_clock":0.0,"waste_clock":0.0,"cell_clock":0.0,"care_clock":0.0,"hygiene_clock":0.0,"toilet_clock":0.0,"rest_clock":0.0,"sleep_until":0.0,"awake_until":0.0,"auto_sleep":true,"trip_end":0.0,"destination":0,"journeys":0,"pending":[0,0,0],"daily_day":"","quest_day":"","quests":0,"claimed":0,"garden_at":0.0,"harvests":0,"interaction_at":0.0,"best":[0,0,0,0,0]}
func _ready():
	test_mode=OS.get_cmdline_user_args().size()>0
	s=defaults()
	if not test_mode:
		var source=SAVE if FileAccess.file_exists(SAVE) else SAVE+".bak"
		if FileAccess.file_exists(source):
			var data=JSON.parse_string(FileAccess.get_file_as_string(source))
			if data is Dictionary:
				for key in s:
					if data.has(key): s[key]=data[key]
	advance(now())
	save_game()
	var timer=Timer.new()
	timer.wait_time=10.0
	timer.timeout.connect(func(): advance(now()); save_game())
	add_child(timer)
	timer.start()
func now()->float: return Time.get_unix_time_from_system()
func date_key(at:float)->String:
	var local=Time.get_datetime_dict_from_unix_time(int(at)+int(Time.get_time_zone_from_system().bias)*60)
	return "%04d-%02d-%02d"%[local.year,local.month,local.day]
func asleep(at:float)->bool:
	var local=Time.get_datetime_dict_from_unix_time(int(at)+int(Time.get_time_zone_from_system().bias)*60)
	return s.stage>0 and s.trip_end<=at and (s.sleep_until>at or (s.auto_sleep and s.awake_until<=at and (local.hour>=21 or local.hour<7)))
func available()->bool: return s.stage>0 and not asleep(now()) and s.trip_end<=now()
func level()->int: return 1+int(s.xp/100)
func species()->int: return int(s.field)*4+int(s.body)+12*int(s.variant)
func pet_name()->String:
	return s.name if not str(s.name).is_empty() else STAGES[int(s.stage)] if s.stage<2 else SPECIES[species()]
func earn(n:int): s.xp=mini(999900,int(s.xp)+n)
func advance(at:float):
	if s.last<=0: s.last=at; return
	if at<=s.last: return
	var cursor:float=maxf(s.last,at-30*86400)
	s.last=at
	if s.stage==0: return
	var day=date_key(at)
	if s.quest_day!=day: s.quest_day=day; s.quests=0; s.claimed=0
	var trip:float=s.trip_end
	while cursor<at:
		var dt:float=minf(at-cursor,60.0-fposmod(cursor,60.0))
		for boundary in [s.sleep_until,s.awake_until,trip]:
			if boundary>cursor: dt=minf(dt,boundary-cursor)
		var sleeping=asleep(cursor)
		var old_waste=int(s.waste)
		var old_mistakes=int(s.mistakes)
		cursor+=dt
		s.age+=dt
		if sleeping:
			s.rest_clock+=dt
			s.energy=mini(100,int(s.energy)+int(s.rest_clock/60))
			s.rest_clock=fposmod(s.rest_clock,60)
		else:
			for clock in ["food_clock","mood_clock","energy_clock","waste_clock","hygiene_clock","toilet_clock"]: s[clock]+=dt
			for rule in [["food_clock","hunger",900 if s.stage==1 else 2700,1,0],["mood_clock","happy",1500 if s.stage==1 else 3600,1,0],["energy_clock","energy",300,1,0],["waste_clock","waste",2700,-1,6],["hygiene_clock","hygiene",600,3,0],["toilet_clock","toilet",480,5,0]]:
				var count=int(s[rule[0]]/rule[2])
				s[rule[0]]=fposmod(s[rule[0]],rule[2])
				s[rule[1]]=mini(rule[4],int(s[rule[1]])+count) if rule[3]<0 else maxi(rule[4],int(s[rule[1]])-count*rule[3])
			if s.stage>=2 and (s.hunger==0 or s.happy==0):
				s.care_clock+=dt
				s.mistakes=mini(6,int(s.mistakes)+int(s.care_clock/900))
				s.care_clock=fposmod(s.care_clock,900)
			else: s.care_clock=0.0
		if s.germs==0 and ((old_waste<6 and s.waste>=6) or (old_mistakes<3 and s.mistakes>=3)): s.germs=3
		if s.stage==1:
			s.cell_clock+=dt
			s.cells[int(s.field)]=mini(4,int(s.cells[int(s.field)])+int(s.cell_clock/900))
			s.cell_clock=fposmod(s.cell_clock,900)
			if s.cells[int(s.field)]>=4: s.stage=2; s.age=0.0; s.body=s.field
		elif s.stage==2 and s.age>=86400:
			s.stage=3; s.age-=86400; s.body=s.foods.find(s.foods.max())
		elif s.stage==3 and s.age>=86400:
			s.stage=4; s.age-=86400; s.eyes=s.inherited_eyes if s.inherited_eyes>=0 else mini(3,int(s.mistakes/2)); s.collection=int(s.collection)|(1<<species())
	if trip>0 and at>=trip:
		s.pending=[25+int(s.destination)*20+mini(20,int(s.training/2)),2+int(s.destination),1 if int(s.journeys)%3==2 or s.destination==2 else 0]
		s.trip_end=0.0; s.journeys+=1; s.quests=int(s.quests)|4; earn(35+int(s.destination)*15)
func save_game():
	if test_mode: return
	var f=FileAccess.open(SAVE+".tmp",FileAccess.WRITE)
	if f==null: return
	f.store_string(JSON.stringify(s))
	f.flush()
	f.close()
	if FileAccess.file_exists(SAVE): DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE),ProjectSettings.globalize_path(SAVE+".bak"))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE+".tmp"),ProjectSettings.globalize_path(SAVE))
func feed(i:int):
	s.hunger=mini(5,int(s.hunger)+1); s.foods[i]+=1; s.toilet=maxi(0,int(s.toilet)-3)
	if i==species()%4: s.happy=mini(10,int(s.happy)+1); s.bond=mini(100,int(s.bond)+1)
func action(id:String,i:int=0)->bool:
	var at=now()
	advance(at)
	var ready=available()
	var ok=true
	match id:
		"hatch":
			if s.stage!=0: return false
			s.stage=1; s.age=0.0; s.last=at
			if s.generation==1 and s.coins==0: s.coins=100
		"field":
			if s.stage>1 or i<0 or i>2: return false
			s.field=i
		"food":
			if not ready or i<0 or i>3 or s.hunger>=5 or s.coins<FOOD_COST[i]: return false
			s.coins-=FOOD_COST[i]; feed(i)
		"clean":
			if s.stage==0 or s.waste==0: return false
			s.coins+=int(s.waste)*2; s.fuel+=s.waste; s.waste=0; s.waste_clock=0; s.quests=int(s.quests)|2
		"cell":
			if not ready or s.germs<=0: return false
			s.germs-=1
		"bond","play","train","praise","toy":
			var cost=4 if id=="train" else 3 if id=="play" or id=="toy" else 0
			if not ready or s.energy<cost or at-s.interaction_at<1.5: return false
			s.interaction_at=at; s.energy-=cost; s.bond=mini(100,int(s.bond)+1); s.quests=int(s.quests)|1
			if id=="train": s.training=mini(100,int(s.training)+1)
			else: s.happy=mini(10,int(s.happy)+2)
			earn(2+cost)
		"sleep","lamp":
			if s.stage==0 or s.trip_end>at: return false
			if asleep(at): s.sleep_until=0.0; s.awake_until=at+900
			else: s.sleep_until=at+1800
		"auto": s.auto_sleep=not s.auto_sleep; s.awake_until=0.0
		"daily":
			if s.stage==0 or s.daily_day==date_key(at): return false
			s.daily_day=date_key(at); s.coins+=20; s.materials+=1
		"quest":
			if i<0 or i>2 or (int(s.quests)&(1<<i))==0 or (int(s.claimed)&(1<<i))!=0: return false
			s.claimed=int(s.claimed)|(1<<i); s.coins+=15; earn(10)
		"craft":
			if s.stage==0 or s.materials<3: return false
			s.materials-=3; s.crystals+=1
		"secret":
			if s.stage!=4 or s.variant!=0 or s.bond<30 or s.training<10 or s.crystals<3: return false
			s.crystals-=3; s.variant=1; s.collection=int(s.collection)|(1<<species())
		"cook":
			if not ready or s.materials<2 or s.hunger>=5: return false
			s.materials-=2; feed(3)
			if s.hunger<5: feed(3)
			s.happy=mini(10,int(s.happy)+2); earn(5)
		"bath":
			if not ready: return false
			s.hygiene=100; s.soap=0; s.hygiene_clock=0; s.bond=mini(100,int(s.bond)+1)
		"soap":
			if not ready or s.soap>=3 or s.hygiene>=100: return false
			s.soap+=1
		"rinse":
			if not ready or s.soap==0: return false
			s.hygiene=mini(100,int(s.hygiene)+int(s.soap)*35); s.soap=0; s.hygiene_clock=0; earn(2)
		"toilet":
			if not ready or s.toilet>=100: return false
			s.toilet=100; s.toilet_clock=0; earn(2)
		"supply":
			var key="medicine" if i==0 else "snacks"
			var price=12 if i==0 else 5
			if s.stage==0 or s.coins<price or s[key]>=99: return false
			s.coins-=price; s[key]+=1
		"snack":
			if not ready or s.snacks<=0 or (s.hunger>=5 and s.happy>=10): return false
			s.snacks-=1
			if s.hunger<5: feed(3)
			s.happy=mini(10,int(s.happy)+2); earn(3)
		"medicine":
			if not ready or s.medicine<=0 or s.germs==0: return false
			s.medicine-=1; s.germs=0; earn(3)
		"plant":
			if s.stage==0 or s.garden_at!=0 or s.coins<5: return false
			s.coins-=5; s.garden_at=at+1200
		"harvest":
			if s.garden_at==0 or at<s.garden_at: return false
			s.garden_at=0; s.coins+=9; s.materials+=2; s.snacks+=1; s.harvests+=1; earn(5)
		"theme":
			if i<0 or i>2 or (i>0 and level()<i+1): return false
			s.theme=i
		"buy","use":
			if i<0 or i>=ITEMS.size(): return false
			var bit=1<<i
			if id=="buy":
				if (int(s.owned)&bit)!=0 or s.coins<PRICES[i]: return false
				s.coins-=PRICES[i]; s.owned=int(s.owned)|bit
			else:
				if (int(s.owned)&bit)==0: return false
				var key="equipped" if i<3 else "installation"
				s[key]=0 if s[key]==i+1 else i+1
		"clothes","wear":
			if i<0 or i>=CLOTHES.size() or s.stage==0: return false
			var bit=1<<i
			if id=="clothes":
				if (int(s.wardrobe)&bit)!=0 or s.coins<COST[i]: return false
				s.coins-=COST[i]; s.wardrobe=int(s.wardrobe)|bit
			if (int(s.wardrobe)&bit)==0: return false
			s.worn[SLOT[i]]=0 if s.worn[SLOT[i]]==i+1 else i+1
		"trip":
			if not ready or s.stage<2 or s.germs>0 or s.hunger<2 or s.energy<25 or s.pending[0]>0 or i<0 or i>2 or level()<1+i*2 or s.fuel<i: return false
			s.fuel-=i; s.energy-=25; s.destination=i; s.trip_end=at+(10+i*10)*60
		"loot":
			if s.pending[0]<=0: return false
			s.coins+=s.pending[0]; s.materials+=s.pending[1]; s.crystals+=s.pending[2]; s.pending=[0,0,0]
		"friend":
			if not ready: return false
			s.friendship=mini(4,int(s.friendship)+2)
		"breed":
			if not ready or s.stage!=4 or s.friendship<4 or s.pending[0]>0: return false
			var old=s.duplicate(true)
			s=defaults()
			for key in ["coins","crystals","materials","fuel","snacks","medicine","collection","owned","equipped","installation","wardrobe","worn","theme","garden_at","harvests","best","daily_day","quest_day","quests","claimed","journeys","auto_sleep"]: s[key]=old[key]
			s.generation=old.generation+1; s.inherited_eyes=2; s.eyes=2; s.color=1; s.last=at
		_: ok=false
	if ok:
		s.coins=clampi(int(s.coins),0,999999); s.snacks=mini(99,int(s.snacks)); s.materials=mini(9999,int(s.materials)); s.crystals=mini(9999,int(s.crystals))
		save_game()
	return ok
func begin_arcade(mode:int)->bool:
	if not available() or s.energy<5 or arcade_mode!=-1: return false
	arcade_mode=mode
	return true
func finish_arcade(score:int,seconds:float,snacks:int=0)->int:
	if arcade_mode<0: return 0
	var mode=arcade_mode
	arcade_mode=-1
	var reward=mini(100,maxi(0,score)*[2,6,4,10,3][mode]) if seconds>=1.0 else 0
	s.best[mode]=maxi(int(s.best[mode]),score)
	s.coins=mini(999999,int(s.coins)+reward); s.snacks=mini(99,int(s.snacks)+clampi(snacks,0,20))
	if reward>0: s.energy=maxi(0,int(s.energy)-3); s.happy=mini(10,int(s.happy)+2); s.food_clock+=300; earn(mini(10,int(reward/5)))
	save_game()
	return reward
