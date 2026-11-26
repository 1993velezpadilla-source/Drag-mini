extends Node
# Independent Godot port of native PetState. Time in seconds, persisted in one wallet.
const SAVE="user://forever_pet_v1.json"
const Research=preload("res://research_data.gd")
const SPECIES=["Mosskit","Mewmew","Barkle","Dracoon","Bubblefin","Neblito","Wispurr","Octoboo","Roostik","Fayli","Pixsy","Puffowl","Fernhorn","Moonmew","Cloverbark","Emberdrake","Pearlfin","NovaNeb","Lunawisp","Reefboo","Suncrest","Aurorafay","Stardust Pixsy","Dreamowl","Ember Imp","Wisp Ghost","Bolt Bot","Mushmellow"]
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
var wallpaper_keys:Dictionary={}
const PERSONAL=["stage","field","body","eyes","color","variant","friendship","inherited_eyes","name","hunger","happy","energy","bond","waste","mistakes","germs","hygiene","toilet","soap","cells","foods","equipped","worn","training","age","food_clock","mood_clock","energy_clock","waste_clock","cell_clock","care_clock","hygiene_clock","toilet_clock","rest_clock","sleep_until","awake_until","interaction_at","companion_xp"]
const WALL_ROOMS=["room_bedroom","room_kitchen","room_bathroom","room_toy","room_garden","room_lab"]
func defaults()->Dictionary:
	return {"profiles":{},"companion_xp":0,"research_evidence":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"research_trust":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"sanctuary_mask":0,"sanctuary_progress":[0,0,0,0,0,0,0,0,0],"research_day":"","research_daily":[0,0,0],"research_claimed":0,"research_rank_xp":[0,0,0],"research_skill":0,"research_misses":[0,0,0],"research_target":[-1,-1,-1],"wallpaper_room":0,"wallpaper_x":1,"wallpaper_y":2,"wallpaper_size":1,"wallpaper_minimal":false,"wallpaper_battery":false,"wallpaper_status":true,"stage":0,"field":0,"habitat":0,"body":0,"eyes":0,"color":0,"variant":0,"generation":1,"friendship":0,"inherited_eyes":-1,"name":"","hunger":5,"happy":10,"energy":100,"bond":0,"xp":0,"waste":0,"mistakes":0,"germs":0,"hygiene":100,"toilet":100,"coins":0,"crystals":0,"materials":0,"fuel":0,"snacks":0,"medicine":0,"soap":0,"cells":[0,0,0],"foods":[0,0,0,0],"collection":0,"favorites":0,"care_day":"","care_mask":0,"care_claims":0,"care_claimed":false,"form":-1,"owned":0,"equipped":0,"installation":0,"wardrobe":0,"worn":[0,0,0,0],"theme":0,"training":0,"age":0.0,"last":0.0,"food_clock":0.0,"mood_clock":0.0,"energy_clock":0.0,"waste_clock":0.0,"cell_clock":0.0,"care_clock":0.0,"hygiene_clock":0.0,"toilet_clock":0.0,"rest_clock":0.0,"sleep_until":0.0,"awake_until":0.0,"auto_sleep":true,"trip_end":0.0,"destination":0,"trip_bonus":0,"journeys":0,"pending":[0,0,0],"daily_day":"","quest_day":"","quests":0,"claimed":0,"garden_at":0.0,"harvests":0,"interaction_at":0.0,"best":[0,0,0,0,0]}
func _ready():
	test_mode=false
	for flag in ["--test","--soak","--capture","--lane-only","--unassisted","--home-test","--home-capture","--home-touch-test"]:
		if OS.get_cmdline_user_args().has(flag): test_mode=true
	s=defaults()
	if not test_mode:
		for source in [SAVE,SAVE+".bak"]:
			if not FileAccess.file_exists(source): continue
			var data=JSON.parse_string(FileAccess.get_file_as_string(source))
			if data is Dictionary:
				for key in s:
					if not data.has(key): continue
					if s[key] is Array:
						if data[key] is Array and data[key].size()==s[key].size():
							var valid=true
							for value in data[key]:
								if not (value is int or value is float) or not is_finite(float(value)): valid=false
							if valid: s[key]=data[key]
					elif typeof(data[key])==typeof(s[key]) or (typeof(s[key]) in [TYPE_INT,TYPE_FLOAT] and typeof(data[key]) in [TYPE_INT,TYPE_FLOAT]): s[key]=data[key]
				if not data.has("habitat"): s.habitat=s.field
				s.profiles=validated_profiles(s.profiles)
				if int(s.form)>=0 and not s.profiles.has("-1"): s.profiles["-1"]=profile_snapshot()
				for key in ["wallpaper_x","wallpaper_y","wallpaper_size"]: s[key]=clampi(int(s[key]),0,2)
				for key in ["stage","field","habitat","body","eyes","variant"]:
					s[key]=clampi(int(s[key]),0,{"stage":4,"field":2,"habitat":2,"body":3,"eyes":3,"variant":1}[key])
				break
	advance(now())
	save_game()
	var timer=Timer.new()
	timer.wait_time=10.0
	timer.timeout.connect(func(): advance(now()); consume_wallpaper_action(); save_game())
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
func growth_progress()->float:
	match int(s.stage):
		0: return 0.0
		1: return clampf((float(s.cells[int(s.field)])*900+float(s.cell_clock))/3600,0,1)
		2,3: return clampf(float(s.age)/86400,0,1)
		_: return 1.0
func growth_remaining()->int:
	match int(s.stage):
		1: return ceili(maxf(0,3600*(1-growth_progress())))
		2,3: return ceili(maxf(0,86400-float(s.age)))
		_: return 0
func garden_remaining(at:float)->int: return ceili(maxf(0,float(s.garden_at)-at))
func expedition_remaining(at:float)->int: return ceili(maxf(0,float(s.trip_end)-at))
func care_priority()->String:
	if s.stage==0: return "Hatch your egg to begin"
	if s.trip_end>now(): return "Exploring the world"
	if asleep(now()): return "Resting"
	if s.germs>0: return "Needs medical care"
	if s.hunger<=1: return "Hungry"
	if s.toilet<=20: return "Needs the bathroom"
	if s.hygiene<=35: return "Needs a bath"
	if s.energy<=20: return "Needs rest"
	if s.happy<=3: return "Needs playtime"
	if s.waste>0: return "Clean the room"
	return "Happy and healthy"
func level()->int: return 1+int(s.xp/100)
func companion_level()->int: return 1+int(s.companion_xp/50)
func profile_snapshot()->Dictionary:
	var result={}
	for key in PERSONAL:
		result[key]=s[key].duplicate(true) if s[key] is Array else s[key]
	return result
func validated_profiles(raw:Dictionary)->Dictionary:
	var result={}
	var template=defaults()
	var caps={"stage":4,"field":2,"body":3,"eyes":3,"variant":1,"hunger":5,"happy":10,"energy":100,"bond":100,"hygiene":100,"toilet":100,"germs":3,"waste":6,"friendship":4}
	for slot in range(-1,SPECIES.size()):
		var key=str(slot)
		if not raw.has(key) or not raw[key] is Dictionary: continue
		var entry={}
		for field in PERSONAL:
			var fallback=template[field]
			var value=raw[key].get(field,fallback)
			if fallback is Array:
				var valid=value is Array and value.size()==fallback.size()
				if valid:
					for n in value:
						if not (n is int or n is float) or not is_finite(float(n)): valid=false
				entry[field]=value.duplicate(true) if valid else fallback.duplicate(true)
			elif fallback is String: entry[field]=str(value).left(24) if value is String else fallback
			else: entry[field]=value if (value is int or value is float) and is_finite(float(value)) else fallback
		for field in caps: entry[field]=clampi(int(entry[field]),0,int(caps[field]))
		if slot>=0:entry.stage=4
		result[key]=entry
	return result
func companion_profile(slot:int)->Dictionary:
	if slot==int(s.form):return profile_snapshot()
	return s.profiles.get(str(slot),{})
func original_species()->int:
	var original=companion_profile(-1)
	if original.is_empty():return inherited_species()
	return int(original.field)*4+int(original.body)+12*int(original.variant)
func switch_companion(slot:int,at:float)->bool:
	if s.stage==0 or slot==int(s.form) or s.trip_end>at or s.pending[0]>0 or arcade_mode!=-1:return false
	if slot!=-1 and (slot<0 or slot>=SPECIES.size() or (int(s.collection)&(1<<slot))==0):return false
	if slot==-1 and not s.profiles.has("-1"):return false
	s.profiles[str(s.form)]=profile_snapshot()
	var entry:Dictionary=s.profiles.get(str(slot),{})
	if entry.is_empty():
		var fresh=defaults()
		fresh.stage=4; fresh.field=int(slot%12/4); fresh.body=slot%4; fresh.variant=1 if slot>=12 and slot<24 else 0
		for key in PERSONAL: entry[key]=fresh[key]
	for key in PERSONAL:s[key]=entry[key].duplicate(true) if entry[key] is Array else entry[key]
	s.form=slot; s.last=at
	return true
func wallpaper_identity()->int:
	return int(s.generation)*32+int(s.form)+2
func inherited_species()->int: return int(s.field)*4+int(s.body)+12*int(s.variant)
func species()->int:
	var selected=int(s.form)
	return selected if selected>=0 and selected<SPECIES.size() and (int(s.collection)&(1<<selected))!=0 else inherited_species()
const CARE_NAMES=["Affection","Feeding","Hygiene","Play / train","Habitat cleanup","Garden harvest"]
func care_count()->int:
	var n=0
	for i in range(6):
		if (int(s.care_mask)&(1<<i))!=0: n+=1
	return n
func care_credit(id:String):
	var group=-1
	if id in ["bond","praise"]: group=0
	elif id in ["food","cook","snack"]: group=1
	elif id in ["bath","rinse","toilet"]: group=2
	elif id in ["play","toy","train"]: group=3
	elif id=="clean": group=4
	elif id=="harvest": group=5
	if group>=0: s.care_mask=int(s.care_mask)|(1<<group)
func care_ready()->bool: return s.stage>0 and care_count()>=4 and not s.care_claimed
func next_special()->int: return 24+int(s.care_claims) if s.care_claims<4 else -1
func sanctuary_block(region:int,tier:int)->String:
	if region<0 or region>=3 or tier<0 or tier>=3:return "Unknown sanctuary"
	if s.stage==0:return "Hatch your egg first"
	if (int(s.sanctuary_mask)&Research.sanctuary_bit(region,tier))!=0:return "Sanctuary fully explored"
	if research_rank(region)<Research.sanctuary_rank(tier):return "Unlocks at local Rank %d"%Research.sanctuary_rank(tier)
	if tier>0 and (int(s.sanctuary_mask)&Research.sanctuary_bit(region,tier-1))==0:return "Complete the previous sanctuary first"
	if not available():return "Wake your companion or wait for its expedition"
	if s.germs>0 or s.hunger<1:return "Care for your pet first"
	if int(s.energy)<Research.sanctuary_cost(tier):return "Requires %d energy to recover the treasure"%Research.sanctuary_cost(tier)
	return ""
func sanctuary_collect(region:int,tier:int,index:int)->Dictionary:
	advance(now())
	var block=sanctuary_block(region,tier)
	if not block.is_empty():return {"ok":false,"message":block}
	var slot=region*3+tier
	if index<0 or index>=3:return {"ok":false,"message":"Unknown relic"}
	var bit=1<<index
	if (int(s.sanctuary_progress[slot])&bit)!=0:return {"ok":false,"message":"Relic already recovered"}
	s.sanctuary_progress[slot]=int(s.sanctuary_progress[slot])|bit
	if int(s.sanctuary_progress[slot])!=7:
		save_game()
		return {"ok":true,"complete":false,"message":"Relic fragment recovered!"}
	s.energy-=Research.sanctuary_cost(tier)
	s.sanctuary_mask=int(s.sanctuary_mask)|Research.sanctuary_bit(region,tier)
	var reward=Research.sanctuary_reward(tier)
	s.coins=mini(999999,int(s.coins)+reward)
	s.materials=mini(9999,int(s.materials)+3+tier)
	s.crystals=mini(9999,int(s.crystals)+1+tier)
	s.research_rank_xp[region]=mini(150,int(s.research_rank_xp[region])+12)
	earn(20+tier*10); save_game()
	return {"ok":true,"complete":true,"message":Research.SANCTUARY_RELICS[region][tier]+" recovered! +%d coins"%reward}
func research_rank(region:int)->int:
	return mini(5,1+int(maxi(0,int(s.research_rank_xp[region]))/30))
func research_credit(region:int,points:int):
	s.research_rank_xp[region]=mini(150,int(s.research_rank_xp[region])+points)
	s.research_daily[region]=mini(3,int(s.research_daily[region])+1)
func research_claim(region:int)->bool:
	advance(now())
	if region<0 or region>=3 or s.stage==0 or int(s.research_daily[region])<3 or (int(s.research_claimed)&(1<<region))!=0:return false
	s.research_claimed=int(s.research_claimed)|(1<<region)
	s.coins=mini(999999,int(s.coins)+25); s.materials=mini(9999,int(s.materials)+2); earn(15)
	save_game()
	return true
func research_skill_ready(region:int)->bool:
	return region>=0 and region<3 and available() and Research.region_of(species())==region and (int(s.research_skill)&(1<<region))==0
func research_use_skill(region:int)->bool:
	advance(now())
	if not research_skill_ready(region):return false
	s.research_skill=int(s.research_skill)|(1<<region); save_game()
	return true
func research_patrol(region:int,step:int,answer:Array,phase:float)->Dictionary:
	advance(now())
	if region<0 or region>=3 or s.stage==0 or not available() or s.germs>0 or s.hunger<1 or s.energy<2:
		return {"ok":false,"message":"Your companion needs care before patrolling."}
	if int(s.research_daily[region])>=3 or step!=int(s.research_daily[region]):return {"ok":false,"message":"Daily survey complete or trail changed."}
	var target:int=Research.POOLS[region][posmod(int(date_key(now()).replace("-",""))+step,Research.POOLS[region].size())]
	if not Research.trial_success(region,target,step,answer,phase):
		s.energy-=1; save_game()
		return {"ok":true,"correct":false,"message":"Trace escaped. Try again."}
	s.energy-=2; research_credit(region,2)
	s.coins=mini(999999,int(s.coins)+3); earn(3); save_game()
	return {"ok":true,"correct":true,"message":"Patrol trace found! +3 coins · +3 XP"}
func research_target(region:int)->int:
	if region<0 or region>=3: return -1
	var current=int(s.research_target[region])
	if current in Research.POOLS[region] and current!=species() and (int(s.collection)&(1<<current))==0: return current
	return Research.next_species(region,int(s.collection),species())
func choose_research(id:int)->bool:
	if id<0 or id>=SPECIES.size() or s.stage==0 or id==species() or (int(s.collection)&(1<<id))!=0:return false
	var region=Research.region_of(id)
	if int(s.research_target[region])!=id:
		s.research_target[region]=id; s.research_misses[region]=0
		save_game()
	return true
func research_progress(id:int)->int:
	return clampi(int(s.research_evidence[id]),0,Research.needed(id)) if id>=0 and id<SPECIES.size() else 0
func research_block(kind:String,region:int)->String:
	if region<0 or region>=3: return "Unknown habitat"
	if s.stage==0: return "Hatch your egg to explore"
	if not available(): return "Wake your pet first" if asleep(now()) else "Your companion is on an expedition"
	if s.germs>0: return "Treat illness before exploring"
	if s.hunger<1: return "Feed your companion first"
	var target=research_target(region)
	if target<0: return "Every available local creature discovered"
	if kind=="track" and research_progress(target)>=Research.needed(target): return "Creature located! Begin encounter"
	if kind=="track" and s.energy<Research.cost(region,species()): return "Rest first: requires %d energy"%Research.cost(region,species())
	if kind=="encounter" and research_progress(target)<Research.needed(target): return "Find all evidence first"
	return ""
func research_survey(region:int,site:int,target:int,step:int,answer:Array,phase:float)->Dictionary:
	advance(now())
	var block=research_block("track",region)
	if not block.is_empty(): return {"ok":false,"message":block}
	if target!=research_target(region) or step!=research_progress(target) or site!=Research.correct(target,step):
		return {"ok":false,"message":"Trail has changed. Search again."}
	if not Research.trial_success(region,target,step,answer,phase):
		s.energy=maxi(0,int(s.energy)-1); save_game()
		return {"ok":true,"correct":false,"message":"The trace escaped! −1 energy. Try again."}
	var result=research_action("track",region,site)
	if result.get("correct",false) and posmod(target*7+step*3,5)==0:
		s.materials=mini(9999,int(s.materials)+1); s.coins=mini(999999,int(s.coins)+8)
		result["message"]=str(result.message)+" · Rare trace +8 coins +1 material"
		save_game()
	return result
func research_action(kind:String,region:int,choice:int)->Dictionary:
	advance(now())
	var block=research_block(kind,region)
	if not block.is_empty(): return {"ok":false,"message":block}
	var target=research_target(region)
	if kind not in ["track","encounter"] or choice<0 or choice>=(6 if kind=="track" else 3): return {"ok":false,"message":"Unknown action"}
	if int(s.research_target[region])!=target:
		s.research_target[region]=target; s.research_misses[region]=0
	var step=research_progress(target)
	if kind=="track":
		var bit=1<<choice
		if (int(s.research_misses[region])&bit)!=0: return {"ok":false,"message":"Already searched this site"}
		if choice!=Research.correct(target,step):
			s.energy=maxi(0,int(s.energy)-1); s.research_misses[region]=int(s.research_misses[region])|bit
			save_game()
			return {"ok":true,"correct":false,"message":"Old trail. Try another site.","species":target}
		s.energy-=Research.cost(region,species()); s.research_evidence[target]=step+1
		research_credit(region,3); s.research_misses[region]=0
		s.coins=mini(999999,int(s.coins)+4); earn(5)
		if step+1==Research.needed(target): s.materials=mini(9999,int(s.materials)+1)
		save_game()
		return {"ok":true,"correct":true,"species":target,"message":"Creature located!" if step+1==Research.needed(target) else "Fresh evidence! +4 coins · +5 XP"}
	var trust=clampi(int(s.research_trust[target]),0,2)
	if choice!=Research.answer(target,trust):
		return {"ok":true,"correct":false,"species":target,"message":"It hesitates. Observe its behavior and try again."}
	s.research_trust[target]=trust+1
	if trust==2:
		s.collection=int(s.collection)|(1<<target); s.research_target[region]=-1; s.research_misses[region]=0
		research_credit(region,8)
		var bonus=30 if target<12 else 55 if target<24 else 85
		s.coins=mini(999999,int(s.coins)+bonus); s.materials=mini(9999,int(s.materials)+2); earn(25)
		if target>=12: s.crystals=mini(9999,int(s.crystals)+1)
		s.quests=int(s.quests)|4
		save_game()
		return {"ok":true,"correct":true,"unlocked":true,"species":target,"coins":bonus,"message":"New companion discovered!"}
	save_game()
	return {"ok":true,"correct":true,"species":target,"message":"Trust increased!"}
func favorite(index:int)->bool:
	return index>=0 and index<SPECIES.size() and (int(s.favorites)&(1<<index))!=0
func toggle_favorite(index:int)->bool:
	if index<0 or index>=SPECIES.size(): return false
	s.favorites=int(s.favorites)^(1<<index)
	save_game()
	return true
func pet_name()->String:
	return s.name if not str(s.name).is_empty() else STAGES[int(s.stage)] if s.stage<2 else SPECIES[species()]
func earn(n:int):
	s.xp=mini(999900,int(s.xp)+n); s.companion_xp=mini(999900,int(s.companion_xp)+n)
func advance(at:float):
	if s.last<=0: s.last=at; return
	if at<=s.last: return
	var cursor:float=maxf(s.last,at-30*86400)
	s.last=at
	if s.stage==0: return
	var day=date_key(at)
	if s.research_day!=day:
		s.research_day=day; s.research_daily=[0,0,0]; s.research_claimed=0; s.research_skill=0
	if s.care_day!=day: s.care_day=day; s.care_mask=0; s.care_claimed=false
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
			s.stage=4; s.age-=86400; s.eyes=s.inherited_eyes if s.inherited_eyes>=0 else mini(3,int(s.mistakes/2)); s.collection=int(s.collection)|(1<<inherited_species())
	if trip>0 and at>=trip:
		s.pending=[25+int(s.destination)*20+mini(20,int(s.training/2))+int(s.trip_bonus),2+int(s.destination),1 if int(s.journeys)%3==2 or s.destination==2 else 0]
		s.trip_end=0.0; s.journeys+=1; s.quests=int(s.quests)|4; earn(35+int(s.destination)*15)
func save_game():
	if test_mode: return
	var f=FileAccess.open(SAVE+".tmp",FileAccess.WRITE)
	if f==null: return
	f.store_string(JSON.stringify(s))
	f.flush()
	f.close()
	if FileAccess.file_exists(SAVE) and JSON.parse_string(FileAccess.get_file_as_string(SAVE)) is Dictionary:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE),ProjectSettings.globalize_path(SAVE+".bak"))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE+".tmp"),ProjectSettings.globalize_path(SAVE))
	wallpaper_sync()
func wallpaper_plugin()->Object:
	return Engine.get_singleton("ForeverWallpaper") if Engine.has_singleton("ForeverWallpaper") else null
func wallpaper_image(plugin:Object,key:String,path:String)->bool:
	if wallpaper_keys.has(key): return true
	if not ResourceLoader.exists(path): return false
	var texture=load(path) as Texture2D
	if texture==null: return false
	var img=texture.get_image()
	if img==null: return false
	if img.is_compressed() and img.decompress()!=OK: return false
	var bytes=img.save_png_to_buffer()
	if bytes.is_empty(): return false
	var ok=bool(plugin.putImage(key,bytes))
	if ok: wallpaper_keys[key]=true
	return ok
func wallpaper_sync()->bool:
	if test_mode: return false
	var plugin=wallpaper_plugin()
	if plugin==null: return false
	var i:int=28 if s.stage==0 else species()
	var room:int=clampi(int(s.wallpaper_room),0,WALL_ROOMS.size()-1)
	var path="res://assets/premium_egg.png" if i==28 else "res://assets/pet_%d.png"%i
	var awake_ok=wallpaper_image(plugin,"awake_%d"%i,path)
	var sleep_ok=wallpaper_image(plugin,"sleep_%d"%i,path if i==28 else "res://assets/pet_sleep_%d.png"%i)
	var room_ok=wallpaper_image(plugin,"room_%d"%room,"res://assets/"+WALL_ROOMS[room]+".jpg")
	if not (awake_ok and sleep_ok and room_ok): return false
	var snapshot=s.duplicate()
	snapshot.erase("profiles")
	snapshot["generation"]=wallpaper_identity()
	snapshot["portrait"]=i; snapshot["name"]=pet_name(); snapshot["room"]=room
	snapshot["minimal"]=s.wallpaper_minimal; snapshot["battery"]=s.wallpaper_battery; snapshot["show_status"]=s.wallpaper_status
	plugin.syncState(JSON.stringify(snapshot))
	return true
func consume_wallpaper_action():
	if test_mode: return
	var plugin=wallpaper_plugin()
	if plugin==null: return
	var request=str(plugin.consumeAction(wallpaper_identity()))
	if request=="bond": action("bond")
	elif request=="feed": action("food",3)
func _notification(what:int):
	if what==NOTIFICATION_APPLICATION_PAUSED and not s.is_empty():
		advance(now()); save_game()
	if what==NOTIFICATION_APPLICATION_RESUMED and not s.is_empty():
		advance(now())
		consume_wallpaper_action()
		save_game()
func feed(i:int):
	s.hunger=mini(5,int(s.hunger)+1); s.foods[i]+=1; s.toilet=maxi(0,int(s.toilet)-3)
	if i==species()%4: s.happy=mini(10,int(s.happy)+1); s.bond=mini(100,int(s.bond)+1)
# Read-only action status used by every care control. The authoritative
# action still validates state and time when executed.
func action_block(id:String,i:int=0)->String:
	var at=now()
	if id=="hatch": return "" if s.stage==0 else "Already hatched"
	if id=="field": return "Unknown habitat" if i<0 or i>=FIELDS.size() else "Already selected" if int(s.habitat)==i else ""
	if id=="auto": return ""
	if s.stage==0 and id not in ["buy","use","theme","quest","loot","harvest"]: return "Hatch your egg first"
	match id:
		"daily": return "Come back tomorrow" if s.daily_day==date_key(at) else ""
		"care_claim": return "Chest already collected today" if s.care_claimed else "" if care_ready() else "Complete four different care activities"
		"clean": return "" if s.waste>0 else "Habitat is clean"
		"sleep","lamp": return "Pet is exploring" if s.trip_end>at else ""
		"plant": return "Crop already planted" if s.garden_at>0 else "Requires 5 coins" if s.coins<5 else ""
		"harvest": return "Plant a seed first" if s.garden_at==0 else "Ready in "+str(ceili((s.garden_at-at)/60))+" min" if s.garden_at>at else ""
		"theme": return "" if i>=0 and i<3 and (i==0 or level()>=i+1) else "Unlocks at level "+str(i+1)
		"craft": return "" if s.materials>=3 else "Requires 3 materials"
		"loot": return "" if s.pending[0]>0 else "No rewards to collect"
		"quest": return "" if i>=0 and i<3 and (int(s.quests)&(1<<i))!=0 and (int(s.claimed)&(1<<i))==0 else "Quest not ready or already claimed"
		"secret": return "" if int(s.form)==-1 and s.stage==4 and s.variant==0 and s.bond>=30 and s.training>=10 and s.crystals>=3 else "Adult, 30 bond, 10 training, 3 crystals"
	if id in ["food","cook","snack","medicine","cell","soap","rinse","bath","toilet","bond","play","toy","train","praise","trip","friend","breed"]:
		if s.trip_end>at: return "Pet is exploring"
		if asleep(at): return "Wake your pet first"
	match id:
		"food":
			if i<0 or i>=FOODS.size(): return "Unknown food"
			return "Pet is full" if s.hunger>=5 else "Requires "+str(FOOD_COST[i])+" coins" if s.coins<FOOD_COST[i] else ""
		"cook": return "Pet is full" if s.hunger>=5 else "Requires 2 materials" if s.materials<2 else ""
		"snack": return "No snacks" if s.snacks<=0 else "Pet is full and happy" if s.hunger>=5 and s.happy>=10 else ""
		"medicine": return "No medicine" if s.medicine<=0 else "Pet is healthy" if s.germs==0 else ""
		"cell": return "" if s.germs>0 else "All cells healthy"
		"soap": return "Rinse first" if s.soap>=3 else "Pet is clean" if s.hygiene>=100 else ""
		"rinse": return "" if s.soap>0 else "Apply soap first"
		"bath": return "Pet is clean" if s.hygiene>=100 and s.soap==0 else ""
		"toilet": return "" if s.toilet<100 else "No bathroom need"
		"bond","play","toy","train","praise":
			var cost=4 if id=="train" else 3 if id in ["play","toy"] else 0
			return "Needs rest" if s.energy<cost else "Give your pet a moment" if at-s.interaction_at<1.5 else ""
		"trip":
			if i<0 or i>2: return "Unknown destination"
			if s.stage<2: return "Available at Kid stage"
			if s.germs>0: return "Treat illness first"
			if s.hunger<2: return "Feed your pet first"
			if s.energy<25: return "Requires 25 energy"
			if s.pending[0]>0: return "Collect previous rewards first"
			if level()<1+i*2: return "Unlocks at level "+str(1+i*2)
			if s.fuel<i: return "Requires "+str(i)+" fuel"
		"breed": return "" if int(s.form)==-1 and s.stage==4 and s.friendship>=4 and s.pending[0]==0 else "Requires adult, friendship 4, collected rewards"
		"friend": return "" if s.friendship<4 else "Friendship complete"
		"form":
			if i==int(s.form): return "Already active"
			if s.trip_end>at or s.pending[0]>0 or arcade_mode!=-1:return "Finish your current activity first"
			if i!=-1 and (i<0 or i>=SPECIES.size() or (int(s.collection)&(1<<i))==0): return "Companion locked"
		"supply":
			if i<0 or i>1: return "Unknown supply"
			var key="medicine" if i==0 else "snacks"
			var price=12 if i==0 else 5
			return "Inventory full" if s[key]>=99 else "Requires "+str(price)+" coins" if s.coins<price else ""
		"buy","use":
			if i<0 or i>=ITEMS.size(): return "Unknown item"
			var owned=(int(s.owned)&(1<<i))!=0
			return ("Already owned" if owned else "Requires "+str(PRICES[i])+" coins" if s.coins<PRICES[i] else "") if id=="buy" else "" if owned else "Not owned"
		"clothes","wear":
			if i<0 or i>=CLOTHES.size(): return "Unknown garment"
			var owned=(int(s.wardrobe)&(1<<i))!=0
			return ("Already owned" if owned else "Requires "+str(COST[i])+" coins" if s.coins<COST[i] else "") if id=="clothes" else "" if owned else "Not owned"
	return ""
func action(id:String,i:int=0)->bool:
	var at=now()
	advance(at)
	var ready=available()
	var ok=true
	match id:
		"hatch":
			if s.stage!=0: return false
			s.stage=1; s.field=int(s.habitat); s.age=0.0; s.last=at
			if s.generation==1 and s.coins==0: s.coins=100
		"field":
			if i<0 or i>=FIELDS.size() or int(s.habitat)==i: return false
			s.habitat=i
			# Before hatching the egg chooses its lineage. After hatching a
			# habitat change is a preference for future expeditions, not a mutation.
			if s.stage==0: s.field=i
		"food":
			if not ready or i<0 or i>3 or s.hunger>=5 or s.coins<FOOD_COST[i]: return false
			s.coins-=FOOD_COST[i]; feed(i)
		"clean":
			if s.stage==0 or s.waste==0: return false
			s.coins+=int(s.waste)*2; s.fuel+=s.waste; s.waste=0; s.waste_clock=0; s.quests=int(s.quests)|2
		"cell":
			if not ready or s.germs<=0: return false
			s.germs-=1
			if s.germs==0: earn(5)
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
		"care_claim":
			if not care_ready(): return false
			var unlocked=next_special()
			s.care_claimed=true; s.care_claims+=1; s.coins+=25; s.materials+=2; earn(15)
			if unlocked>=24: s.collection=int(s.collection)|(1<<unlocked)
		"form":
			if s.stage==0: return false
			if i!=-1 and (i<0 or i>=SPECIES.size() or (int(s.collection)&(1<<i))==0): return false
			if not switch_companion(i,at):return false
		"quest":
			if i<0 or i>2 or (int(s.quests)&(1<<i))==0 or (int(s.claimed)&(1<<i))!=0: return false
			s.claimed=int(s.claimed)|(1<<i); s.coins+=15; earn(10)
		"craft":
			if s.stage==0 or s.materials<3: return false
			s.materials-=3; s.crystals+=1
		"secret":
			if int(s.form)!=-1 or s.stage!=4 or s.variant!=0 or s.bond<30 or s.training<10 or s.crystals<3: return false
			s.crystals-=3; s.variant=1; s.collection=int(s.collection)|(1<<inherited_species())
		"cook":
			if not ready or s.materials<2 or s.hunger>=5: return false
			s.materials-=2; feed(3)
			if s.hunger<5: feed(3)
			s.happy=mini(10,int(s.happy)+2); earn(5)
		"bath":
			if not ready or (s.hygiene>=100 and s.soap==0): return false
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
			if i<0 or i>1 or s.stage==0 or s.coins<price or s[key]>=99: return false
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
			s.fuel-=i; s.energy-=25; s.destination=i; s.trip_bonus=5 if i==int(s.habitat) else 0; s.trip_end=at+(10+i*10)*60
		"loot":
			if s.pending[0]<=0: return false
			s.coins+=s.pending[0]; s.materials+=s.pending[1]; s.crystals+=s.pending[2]; s.pending=[0,0,0]
		"friend":
			if not ready or s.friendship>=4: return false
			s.friendship=mini(4,int(s.friendship)+2)
		"breed":
			if not ready or int(s.form)!=-1 or s.stage!=4 or s.friendship<4 or s.pending[0]>0: return false
			var old=s.duplicate(true)
			s=defaults()
			for key in ["profiles","sanctuary_mask","sanctuary_progress","research_day","research_daily","research_claimed","research_rank_xp","research_skill","research_evidence","research_trust","research_misses","research_target","wallpaper_room","wallpaper_x","wallpaper_y","wallpaper_size","wallpaper_minimal","wallpaper_battery","wallpaper_status","coins","crystals","materials","fuel","snacks","medicine","collection","favorites","care_day","care_mask","care_claims","care_claimed","owned","equipped","installation","wardrobe","worn","theme","garden_at","harvests","best","daily_day","quest_day","quests","claimed","journeys","auto_sleep"]: s[key]=old[key]
			s.profiles.erase("-1"); s.generation=old.generation+1; s.habitat=int(old.habitat); s.field=int(old.habitat); s.inherited_eyes=2; s.eyes=2; s.color=1; s.last=at
		_: ok=false
	if ok:
		care_credit(id)
		s.coins=clampi(int(s.coins),0,999999); s.snacks=mini(99,int(s.snacks)); s.materials=mini(9999,int(s.materials)); s.crystals=mini(9999,int(s.crystals))
		save_game()
	return ok
func arcade_block(mode:int)->String:
	if mode<0 or mode>=5: return "Unknown game"
	if s.stage==0: return "Hatch your egg first"
	if s.trip_end>now(): return "Pet is exploring"
	if asleep(now()): return "Wake your pet first"
	if s.energy<5: return "Needs at least 5 energy"
	if arcade_mode!=-1: return "Another game is active"
	return ""
func begin_arcade(mode:int)->bool:
	if not arcade_block(mode).is_empty(): return false
	arcade_mode=mode
	return true
func finish_arcade(score:int,seconds:float,snacks:int=0)->int:
	if arcade_mode<0: return 0
	var mode=arcade_mode
	arcade_mode=-1
	if not is_finite(seconds) or seconds<1.0: return 0
	score=clampi(score,0,1000000)
	var reward=mini(100,score*[2,6,4,10,3][mode])
	s.best[mode]=maxi(int(s.best[mode]),score)
	s.coins=mini(999999,int(s.coins)+reward); s.snacks=mini(99,int(s.snacks)+clampi(snacks,0,20))
	if reward>0: s.energy=maxi(0,int(s.energy)-3); s.happy=mini(10,int(s.happy)+2); s.food_clock+=300; earn(mini(10,int(reward/5)))
	save_game()
	return reward
