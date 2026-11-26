extends SceneTree
# Runs the actual production PetStore without any Blender or rendering dependency.
var pet:Node
var passed=0
func _initialize():
	call_deferred("run")
func check(condition:bool,description:String):
	if not condition:
		push_error("CORE_FAIL "+description)
		quit(1)
		assert(condition,description)
	passed+=1
	print("CORE_OK ",description)
func reset(stage:int=1):
	pet.s=pet.defaults()
	pet.s.stage=stage
	pet.s.auto_sleep=false
	pet.s.last=pet.now()
	pet.s.coins=500
	pet.arcade_mode=-1
func run():
	pet=load("res://pet_store.gd").new()
	root.add_child(pet)
	reset(0)
	pet.s.coins=0
	check(pet.action("field",2),"choose sky lineage before hatch")
	check(pet.action("hatch"),"hatch")
	check(pet.s.coins==100 and not pet.action("hatch"),"starter wallet paid once")
	var original_species:int=pet.species()
	check(pet.action("field",0) and pet.species()==original_species and pet.s.field==2,"changing habitat never transforms hatched pet")
	check(pet.s.habitat==0 and not pet.action("field",0),"selected habitat retained without repeated action")
	var t:float=pet.now()
	pet.s.last=t-3601
	pet.advance(t)
	check(pet.s.stage==2 and pet.s.cells[2]==4,"offline baby evolution")
	pet.s.foods=[0,0,5,0]
	pet.advance(t+86401)
	check(pet.s.stage==3 and pet.s.body==2,"diet determines young form")
	pet.advance(t+172802)
	check(pet.s.stage==4 and (int(pet.s.collection)&(1<<10))!=0,"adult collection unlock")
	var age:float=pet.s.age
	pet.advance(t-1)
	check(pet.s.age==age,"clock rollback cannot repeat growth")
	reset(4)
	pet.s.hunger=3
	var wallet:int=pet.s.coins
	check(pet.action("food",0) and pet.s.coins==wallet-4 and pet.s.hunger==4,"paid food")
	check(pet.action("food",3) and not pet.action("food",3),"free food cannot overfeed")
	check(pet.action("daily") and not pet.action("daily"),"daily claim once")
	pet.s.waste=3
	wallet=pet.s.coins
	check(pet.action("clean") and pet.s.coins==wallet+6 and pet.s.fuel==3,"cleanup rewards")
	check(not pet.action("clean"),"cleanup cannot duplicate")
	check(pet.action("quest",1) and not pet.action("quest",1),"quest claim once")
	pet.s.hygiene=10
	check(pet.action("soap") and pet.action("rinse") and pet.s.hygiene==45,"soap and rinse")
	check(pet.action("bath") and not pet.action("bath"),"bath cannot repeat at full hygiene")
	pet.s.germs=3
	for i in range(3): check(pet.action("cell"),"treat cell "+str(i))
	check(pet.s.germs==0 and not pet.action("cell"),"healthy cells cannot be farmed")
	check(pet.action("plant") and not pet.action("plant"),"one planted crop")
	check(not pet.action("harvest"),"harvest before ready rejected")
	pet.s.garden_at=pet.now()-1
	check(pet.action("harvest") and not pet.action("harvest"),"harvest reward once")
	check(pet.action("sleep") and not pet.available(),"manual sleep prevents arcade")
	check(not pet.begin_arcade(4),"sleeping pet cannot launch game")
	check(pet.action("sleep") and pet.available(),"manual wake")
	pet.s.energy=100
	check(pet.action("trip",0),"launch expedition")
	check(not pet.action("trip",0) and not pet.available(),"expedition exclusive")
	pet.s.trip_end=pet.now()-1
	pet.advance(pet.now()+1)
	check(pet.s.pending[0]>0,"offline expedition completion")
	check(pet.action("loot") and not pet.action("loot"),"expedition loot once")
	reset(4)
	for mode in range(5):
		check(pet.begin_arcade(mode),"launch arcade "+str(mode))
		check(pet.finish_arcade(5,10)>0,"arcade reward "+str(mode))
		check(pet.finish_arcade(5,10)==0,"arcade reward cannot duplicate "+str(mode))
	check(not pet.begin_arcade(-1) and not pet.begin_arcade(5),"invalid modes rejected")
	check(pet.begin_arcade(4) and pet.finish_arcade(999,0.01,20)==0,"instant run cannot earn")
	check(pet.s.snacks==0,"instant run cannot earn snacks")
	pet.s.coins=500
	check(pet.action("clothes",0),"buy wearable")
	wallet=pet.s.coins
	check(not pet.action("clothes",0) and pet.s.coins==wallet,"duplicate purchase rejected")
	check(pet.action("wear",0) and pet.s.worn[0]==0,"unequip wearable")
	pet.s.bond=30; pet.s.training=10; pet.s.crystals=3
	check(pet.action("secret") and pet.species()==12,"secret evolution")
	check(not pet.action("secret"),"secret evolution cannot repeat")
	check(pet.toggle_favorite(3) and pet.favorite(3),"favorite species")
	check(not pet.toggle_favorite(-1) and not pet.toggle_favorite(28),"invalid favorites rejected")
	check(pet.toggle_favorite(5) and pet.toggle_favorite(5) and not pet.favorite(5),"unfavorite species")
	pet.s.friendship=4
	wallet=pet.s.coins
	check(pet.action("breed") and pet.s.stage==0 and pet.s.generation==2,"new generation")
	check(pet.s.coins==wallet and pet.s.wardrobe!=0,"inherit wallet and wardrobe")
	check(pet.favorite(3),"favorites survive new generation")
	reset(4)
	check(not pet.action("form",24),"locked companion cannot equip")
	pet.s.hunger=3; pet.s.hygiene=10
	check(pet.action("bond"),"care affection credit")
	check(pet.action("food",3),"care feeding credit")
	check(pet.action("bath"),"care hygiene credit")
	pet.s.interaction_at=0.0
	check(pet.action("play"),"care play credit")
	check(pet.care_count()==4 and pet.care_ready(),"four distinct care categories")
	check(pet.action("care_claim") and not pet.action("care_claim"),"care chest once")
	check(pet.action("form",24) and pet.species()==24,"unlock and equip devil")
	check(pet.action("form",-1) and pet.species()==0,"restore inherited form")
	reset(4)
	check(not pet.action_block("food",0).is_empty(),"full pet food disabled")
	pet.s.hunger=2; check(pet.action_block("food",0).is_empty(),"hungry pet food enabled")
	check(not pet.action_block("rinse").is_empty(),"rinse requires soap")
	check(not pet.action_block("clean").is_empty(),"clean habitat no duplicate action")
	pet.s.waste=1; check(pet.action_block("clean").is_empty(),"dirty habitat action available")
	check(not pet.action_block("harvest").is_empty(),"harvest requires crop")
	reset(4)
	check(pet.action("bond"),"first cuddle")
	check(not pet.action_block("bond").is_empty() and not pet.action("bond"),"cooldown UI matches action")
	pet.s.interaction_at=0; check(pet.action_block("bond").is_empty(),"cooldown releases")
	pet.s.energy=20; check(not pet.action_block("trip",0).is_empty() and not pet.action("trip",0),"expedition energy gate")
	pet.s.energy=100; check(pet.action_block("trip",0).is_empty(),"expedition available")
	check(not pet.action_block("breed").is_empty(),"breeding locked until friendship")
	pet.s.friendship=4; check(pet.action_block("breed").is_empty() and not pet.action("friend"),"friendship cap and breeding ready")
	check(not pet.action_block("form",24).is_empty(),"locked form control")
	pet.s.medicine=99; check(not pet.action_block("supply",0).is_empty() and not pet.action("supply",0),"inventory cap")
	check(pet.action("buy",0) and not pet.action_block("buy",0).is_empty(),"owned item cannot rebuy")
	var adult_species:int=pet.species()
	check(pet.action("field",1) and pet.species()==adult_species,"adult habitat independent of species")
	check(pet.s.habitat==1 and pet.s.field==0,"adult lineage preserved")
	reset(4)
	pet.s.habitat=0
	check(pet.action("trip",0) and pet.s.trip_bonus==5,"preferred habitat expedition bonus")
	check(pet.action("field",1) and pet.s.trip_bonus==5,"habitat cannot change active expedition reward")
	pet.s.trip_end=pet.now()-1; pet.advance(pet.now()+1)
	check(pet.s.pending[0]==30,"bonus added once to expedition reward")
	reset(1)
	var R=preload("res://research_data.gd")
	var all_ids=[]
	for r in range(3):all_ids.append_array(R.POOLS[r])
	all_ids.sort()
	check(all_ids==range(28),"all 28 creatures have habitats")
	var original:int=pet.species()
	var target:int=pet.research_target(0)
	check(target>=0 and target!=original,"starter can research another creature")
	check(pet.choose_research(24) and pet.research_target(2)==24,"target exact creature from collection")
	check(not pet.choose_research(-1) and not pet.choose_research(original),"invalid and active targets rejected")
	check(not pet.research_action("encounter",0,0).ok,"encounter requires evidence")
	var energy:int=pet.s.energy
	var wrong:int=(R.correct(target,0)+1)%6
	check(pet.research_action("track",0,wrong).ok and pet.s.energy==energy-1,"old trail costs energy")
	check(not pet.research_action("track",0,wrong).ok,"cannot search same old trail twice")
	for n in range(R.needed(target)):
		var correct:int=R.correct(target,n)
		check(R.clue(target,n,correct)==R.desired(target,n),"unique matching clue")
		check(pet.research_action("track",0,correct).correct,"evidence recorded")
	check(pet.research_progress(target)==R.needed(target),"all evidence recorded")
	check(not pet.research_action("track",0,0).ok,"no farming completed trail")
	check(not pet.research_action("encounter",0,(R.answer(target,0)+1)%3).correct,"wrong encounter choice grants no trust")
	for n in range(3):
		check(pet.research_action("encounter",0,R.answer(target,n)).correct,"trust step")
	check((int(pet.s.collection)&(1<<target))!=0 and pet.species()==original,"discover without replacing original")
	check(pet.action("form",target) and pet.species()==target,"use discovered companion")
	check(pet.action("form",-1) and pet.species()==original,"restore original")
	check(pet.research_target(0)!=target,"next research target")
	pet.s.energy=0; check(not pet.research_action("track",1,0).ok,"research energy gate")
	reset(0); check(not pet.research_action("track",0,0).ok,"egg research gate")
	reset(1)
	var land:int=pet.research_target(0)
	var land_site:int=R.correct(land,0)
	check(R.cost(0,pet.species())==1 and R.cost(1,pet.species())==2,"native territory energy advantage")
	check(not pet.research_survey(0,land_site,land,1,[],0).ok,"stale survey cannot grant evidence")
	var initial_energy:int=pet.s.energy
	check(not pet.research_survey(0,land_site,land,0,[9],0).correct and pet.s.energy==initial_energy-1,"failed memory trial costs energy")
	check(pet.research_survey(0,land_site,land,0,R.trial_sequence(0,land,0),0).correct,"land memory proof")
	check(pet.s.energy==initial_energy-2,"native companion discounts clue")
	var water:int=pet.research_target(1)
	check(not pet.research_survey(1,R.correct(water,0),water,0,[],.15).correct,"missed current")
	check(pet.research_survey(1,R.correct(water,0),water,0,[],.5).correct,"water timing proof")
	var sky:int=pet.research_target(2)
	check(pet.research_survey(2,R.correct(sky,0),sky,0,R.trial_sequence(2,sky,0),0).correct,"sky arrow proof")
	check(not R.trial_success(1,water,0,[],NAN),"invalid phase rejected")
	reset(4)
	pet.advance(pet.now()+1)
	check(pet.research_skill_ready(0) and not pet.research_skill_ready(1),"native daily skill")
	check(pet.research_use_skill(0) and not pet.research_use_skill(0),"skill cannot repeat")
	check(not pet.research_claim(0),"contract not ready")
	for n in range(3):
		var target_id:int=R.POOLS[0][posmod(int(pet.date_key(pet.now()).replace("-",""))+n,R.POOLS[0].size())]
		check(pet.research_patrol(0,n,R.trial_sequence(0,target_id,n),0).correct,"repeatable local survey")
	check(not pet.research_patrol(0,3,[],0).ok,"daily patrol cap")
	check(pet.research_claim(0) and not pet.research_claim(0),"contract one-time reward")
	check(pet.s.research_rank_xp[0]==6,"rank progress")
	pet.s.research_rank_xp[0]=120; check(pet.research_rank(0)==5,"max rank")
	pet.s.research_day="yesterday"; pet.s.last=pet.now()-2; pet.advance(pet.now())
	check(pet.s.research_daily[0]==0 and pet.research_skill_ready(0),"daily reset restores contract and skill")
	reset(4)
	check(not pet.sanctuary_block(0,0).is_empty(),"sanctuary requires rank")
	pet.s.research_rank_xp[0]=30
	check(pet.sanctuary_block(0,0).is_empty(),"rank two opens sanctuary")
	var start_wallet:int=pet.s.coins
	check(pet.sanctuary_collect(0,0,0).ok,"first relic")
	check(not pet.sanctuary_collect(0,0,0).ok,"duplicate relic blocked")
	check(pet.sanctuary_collect(0,0,1).ok,"second relic")
	check(pet.s.coins==start_wallet,"no treasure before all fragments")
	check(pet.sanctuary_collect(0,0,2).complete,"sanctuary treasure")
	check(pet.s.coins==start_wallet+40 and pet.s.energy==96,"treasure pays once and consumes energy")
	check(not pet.sanctuary_collect(0,0,2).ok,"treasure cannot repeat")
	pet.s.research_rank_xp[0]=60
	check(pet.sanctuary_block(0,1).is_empty(),"rank three and prior sanctuary open next")
	check(not pet.sanctuary_block(1,0).is_empty(),"regional rank independent")
	reset(4)
	pet.s.collection=(1<<1)|(1<<4)
	pet.s.name="Original"; pet.s.hunger=2; pet.s.bond=32; pet.s.companion_xp=75
	var old_token:int=pet.wallpaper_identity()
	check(pet.action("form",1),"adopt new companion")
	check(pet.s.name=="" and pet.s.hunger==5 and pet.s.bond==0,"independent new profile")
	check(pet.wallpaper_identity()!=old_token,"wallpaper care cannot cross companions")
	pet.s.name="Mew"; pet.s.hunger=3; pet.s.bond=8
	var shared_wallet:int=pet.s.coins
	check(pet.action("form",-1),"return original")
	check(pet.s.name=="Original" and pet.s.hunger==2 and pet.s.bond==32 and pet.s.companion_xp==75,"original stats preserved")
	check(pet.s.coins==shared_wallet,"shared wallet preserved")
	check(pet.action("form",1) and pet.s.name=="Mew" and pet.s.hunger==3 and pet.s.bond==8,"adopted stats persist")
	pet.s.pending=[3,0,0]
	check(not pet.action("form",4),"cannot swap pending expedition")
	pet.s.pending=[0,0,0]; pet.s.friendship=4
	check(not pet.action("breed"),"adopted companion cannot replace original generation")
	check(pet.action("form",-1),"restore lineage")
	check(pet.original_species()==0,"original genetics preserved")
	check(pet.validated_profiles(pet.s.profiles).has("1"),"profile save validation")
	var persisted=JSON.parse_string(JSON.stringify(pet.s.profiles))
	check(pet.validated_profiles(persisted)["1"].name=="Mew","profile JSON roundtrip")
	pet.s.friendship=4; pet.s.xp=900
	check(pet.action("breed") and pet.s.xp==900,"account level survives new generation")
	check(pet.s.profiles.has("1") and not pet.s.profiles.has("-1"),"adopted family survives new generation")
	reset(4)
	pet.s.collection=(1<<1)|(1<<4)
	check(pet.family_slots()==[-1],"family excludes not adopted species")
	check(pet.action("form",1) and pet.family_slots()==[-1,1],"family includes adopted companion")
	check(pet.rename_companion(1,"Luna") and pet.family_name_for(1)=="Luna","active rename")
	check(pet.rename_companion(-1,"Moss") and pet.family_name_for(-1)=="Moss","inactive rename")
	check(not pet.rename_companion(4,"Not adopted"),"cannot rename unadopted species")
	pet.s.hunger=1
	check(pet.family_status(1)=="Hungry","family needs status")
	check(pet.action("form",-1) and pet.s.name=="Moss" and pet.family_name_for(1)=="Luna","family names persist on switch")
	reset(4)
	pet.arcade_daily_sync(pet.now())
	var daily_mode:int=pet.arcade_daily_mode()
	var daily_target:int=pet.arcade_daily_target()
	check(not pet.arcade_claim_daily(),"daily arcade requires score")
	check(pet.begin_arcade(daily_mode),"daily game begins")
	pet.finish_arcade(daily_target,5.0)
	check(pet.s.arcade_daily_best==daily_target and pet.s.arcade_runs[daily_mode]==1,"daily progress from actual finished run")
	var coins_before:int=pet.s.coins
	check(pet.arcade_claim_daily() and pet.s.coins==coins_before+25,"daily arcade bonus paid")
	check(not pet.arcade_claim_daily(),"daily bonus one time")
	pet.s.best[0]=50
	check(pet.arcade_medal_level(0)==3,"three milestone medals earned")
	check(pet.arcade_claim_medal(0) and pet.arcade_claim_medal(0) and pet.arcade_claim_medal(0),"milestone rewards sequential")
	check(not pet.arcade_claim_medal(0),"medal rewards one time")
	pet.s.arcade_day="yesterday";pet.arcade_daily_sync(pet.now())
	check(pet.s.arcade_daily_best==0 and not pet.s.arcade_daily_claimed and pet.s.arcade_medals[0]==3,"daily resets but medals persist")
	reset(4)
	var day:String=pet.date_key(pet.now())
	check(pet.today_count(pet.now())==0 and not pet.today_claim(),"no daily bonus without activities")
	pet.s.daily_day=day;pet.s.care_day=day;pet.s.care_claimed=true
	check(pet.today_count(pet.now())==2,"overview derives gift and care flags")
	pet.s.arcade_day=day;pet.s.arcade_daily_claimed=true;pet.s.research_day=day;pet.s.research_claimed=2
	check(pet.today_count(pet.now())==4,"all four activities recognized")
	var today_wallet:int=pet.s.coins
	check(pet.today_claim() and pet.s.coins==today_wallet+35,"adventure bonus")
	check(not pet.today_claim(),"daily bonus idempotent")
	check(pet.today_count(pet.now()+86400)==0,"old tasks cannot count tomorrow")
	reset(4)
	pet.s.collection=(1<<24)|(1<<26)
	check(pet.next_special()==25,"care chest skips already discovered companions")
	pet.s.care_day=pet.date_key(pet.now());pet.s.care_mask=15
	check(pet.action("care_claim") and (int(pet.s.collection)&(1<<25))!=0,"care chest grants missing companion")
	check(pet.next_special()==27,"next undiscovered special")
	pet.s.collection=int(pet.s.collection)|(1<<27)
	check(pet.next_special()==-1,"all specials discovered no duplicate reward")
	reset(4)
	pet.field_session={}
	var session:Dictionary=pet.field_begin(0,false)
	check(not session.is_empty() and session.required>=3,"active field starts")
	check(pet.field_begin(0,false).is_empty(),"no parallel sessions")
	var target_id:int=session.id
	check(not pet.field_finish(true,0,0).correct and pet.research_progress(target_id)==0,"incomplete field cannot grant evidence")
	session=pet.field_begin(0,false)
	check(pet.field_finish(true,session.required,9.0).correct and pet.research_progress(target_id)==1,"completed active field grants evidence")
	check(not pet.field_finish(true,3,9.0).ok,"no duplicate field reward")
	pet.s.research_evidence[target_id]=R.needed(target_id)
	session=pet.field_begin(0,false)
	check(session.finale and pet.field_finish(true,session.required,10.0).unlocked,"active encounter unlocks creature")
	check(R.needed(1)==6 and R.needed(14)==9 and R.needed(24)==12,"rarity requires extended investigation")
	# Validate settlement against the production rules for every rarity, not only the UI.
	for tier in range(3):
		reset(4)
		pet.field_session={}
		var candidate:int=[1,13,24][tier]
		var region:int=R.region_of(candidate)
		pet.s.collection=1
		pet.s.research_target[region]=candidate
		pet.s.research_rank_xp[region]=120
		pet.s.research_evidence[candidate]=R.needed(candidate)
		var attempt:Dictionary=pet.field_begin(region,false)
		check(not attempt.is_empty() and attempt.finale,"encounter available tier "+str(tier))
		var coins:int=pet.s.coins
		var materials:int=pet.s.materials
		var crystals:int=pet.s.crystals
		check(not pet.field_finish(true,attempt.required,float(attempt.time_limit)+1.0,0).correct,"expired successful report rejected tier "+str(tier))
		check(pet.s.coins==coins and (int(pet.s.collection)&(1<<candidate))==0,"expired encounter cannot unlock tier "+str(tier))
		attempt=pet.field_begin(region,false)
		check(not attempt.is_empty(),"retry encounter tier "+str(tier))
		check(not pet.field_finish(true,attempt.required,NAN,0).correct,"non-finite duration rejected tier "+str(tier))
		attempt=pet.field_begin(region,false)
		check(not attempt.is_empty(),"retry after malformed report tier "+str(tier))
		var reward:Dictionary=pet.field_finish(true,attempt.required,20.0,0)
		check(reward.get("unlocked",false) and reward.get("flawless",false),"flawless encounter tier "+str(tier))
		check(pet.s.coins==coins+[35,65,100][tier],"exact coin award tier "+str(tier))
		check(pet.s.materials==materials+[2,3,4][tier] and pet.s.crystals==crystals+[0,1,2][tier],"exact crafting award tier "+str(tier))
		check((int(pet.s.collection)&(1<<candidate))!=0,"collection persisted tier "+str(tier))
		check(not pet.field_finish(true,attempt.required,20.0,0).ok,"reward replay rejected tier "+str(tier))
		reset(4)
		pet.s.collection=1
		pet.s.research_target[region]=candidate
		pet.s.research_rank_xp[region]=120
		pet.s.research_evidence[candidate]=R.needed(candidate)
		attempt=pet.field_begin(region,false)
		check(not attempt.is_empty(),"normal encounter available tier "+str(tier))
		coins=pet.s.coins
		reward=pet.field_finish(true,attempt.required,20.0,2)
		check(reward.get("unlocked",false) and not reward.get("flawless",true) and pet.s.coins==coins+[30,55,85][tier],"damage removes only flawless bonus tier "+str(tier))
	reset(4)
	pet.field_session={}
	pet.s.collection=1
	pet.s.research_target[0]=1
	var before_dungeon:int=pet.s.coins
	var before_mats:int=pet.s.materials
	var dungeon:Dictionary=pet.field_begin(0,false,true)
	check(not dungeon.is_empty() and dungeon.required==3 and dungeon.companion==pet.species(),"dungeon uses active companion and three floors")
	var settled:Dictionary=pet.field_finish(true,3,30.0,1,18,2)
	check(settled.correct and settled.evidence==3 and pet.research_progress(1)==3,"each cleared floor advances research")
	check(pet.s.coins==before_dungeon+22 and pet.s.materials==before_mats+2,"dungeon loot deposited once")
	check(not pet.field_finish(true,3,30.0,1,18,2).ok,"dungeon settlement replay blocked")
	dungeon=pet.field_begin(0,false,true)
	check(not dungeon.is_empty(),"second dungeon starts")
	settled=pet.field_finish(true,3,30.0,0,4,1)
	check(settled.correct and pet.research_progress(1)==R.needed(1),"dungeon progress reaches rescue gate")
	dungeon=pet.field_begin(0,false,true)
	check(dungeon.finale and dungeon.required==4,"rescue dungeon requires final guardian floor")
	pet.field_cancel()
	print("FOREVER_PET_CORE_PASS ",passed)
	quit()
