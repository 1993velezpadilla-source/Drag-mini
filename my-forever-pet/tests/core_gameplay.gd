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
	check(pet.action("hatch"),"hatch")
	check(pet.s.coins==100 and not pet.action("hatch"),"starter wallet paid once")
	check(pet.action("field",2),"choose sky habitat")
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
	check(not pet.toggle_favorite(-1) and not pet.toggle_favorite(24),"invalid favorites rejected")
	check(pet.toggle_favorite(5) and pet.toggle_favorite(5) and not pet.favorite(5),"unfavorite species")
	pet.s.friendship=4
	wallet=pet.s.coins
	check(pet.action("breed") and pet.s.stage==0 and pet.s.generation==2,"new generation")
	check(pet.s.coins==wallet and pet.s.wardrobe!=0,"inherit wallet and wardrobe")
	check(pet.favorite(3),"favorites survive new generation")
	print("FOREVER_PET_CORE_PASS ",passed)
	quit()
