extends RefCounted
const REGIONS=["Whisperwood","Coral Depths","Starfall Isles"]
const SUB=["Land · forest tracks & ancient ruins","Water · currents & submerged relics","Sky · wind trails & floating sanctuaries"]
const POOLS=[[1,2,6,10,0,27,13,14,18,22,12],[4,7,16,19,25],[8,3,11,9,5,15,20,23,21,17,24,26]]
const SITES=[["Fern clearing","Mushroom grove","Old oak","Ruined arch","Brook","Crystal hollow"],["Coral garden","Shell ridge","Kelp forest","Sunken arch","Tide pool","Deep grotto"],["Cloud bridge","Wind shrine","Floating garden","Moon arch","Star ridge","Aether gate"]]
const CLUES=[["Fresh footprints","Tuft of fur","Broken twig","Glowing spores","Tiny scratches","Unusual feather"],["Bubble trail","Shimmering scale","Disturbed sand","Coral scratch","Glowing pearl","Ripple pattern"],["Drifting feather","Wind spiral","Star dust","Rune glow","Cloud imprint","Floating spark"]]
const RIDDLES=[
	["A small animal pressed its paws into soft earth.","Something shed a soft coat while passing.","A creature snapped a branch on its way through.","A living glow lingers near damp mushrooms.","Something sharp scored the bark.","A soft plume fell from a passing creature."],
	["A stream of tiny air pockets rises toward the surface.","A reflective fragment glints on the seabed.","A swimming creature disturbed the sediment.","A hard shell scraped against a reef.","A round luminous treasure lies in the current.","Circular waves remain from a recent movement."],
	["A soft plume floats across the islands.","The breeze curls around a passing creature.","Luminous grains sparkle along the trail.","An ancient marking suddenly lights up.","A passing body left a shape in the mist.","A small bright ember drifts without falling."]]
const SIGNALS=[["prints","fur","twig","spore","scratch","feather"],["bubble","scale","sand","scratch","pearl","ripple"],["feather","wind","star","rune","cloud","spark"]]
const OPTIONS=[["Offer a berry","Stay still","Hum softly"],["Release bubbles","Offer a sea snack","Wait quietly"],["Follow the breeze","Play a soft chime","Hold out a hand"]]
const HINTS=[["It sniffs the ground for food.","It backs away from sudden movements.","It perks up at gentle sounds."],["It playfully chases bubbles.","It noses around for a snack.","It hides when the water is disturbed."],["It drifts along the wind.","It responds to a gentle melody.","It floats closer to an open hand."]]
const TINTS=[Color("#83d4a0"),Color("#78d7f0"),Color("#d4b2ff")]
static func region_of(id:int)->int:
	for r in range(3):
		if id in POOLS[r]: return r
	return 0
static func needed(id:int)->int:
	return 6 if id<12 else 9 if id<24 else 12
static func desired(id:int,step:int)->int:
	return posmod(id*3+step*5+int(id/3),6)
static func correct(id:int,step:int)->int:
	return posmod(id*7+step*5+int(id/5),6)
static func clue(id:int,step:int,site:int)->int:
	return posmod(desired(id,step)+site-correct(id,step),6)
static func answer(id:int,trust:int)->int:
	return posmod(id+trust*2,3)
static func next_species(r:int,collection:int,active:int)->int:
	for id in POOLS[r]:
		if id!=active and (collection&(1<<id))==0: return id
	return -1
static func discovered(r:int,collection:int)->int:
	var n=0
	for id in POOLS[r]:
		if (collection&(1<<id))!=0:n+=1
	return n

const ABILITIES=["Trail sense","Current rider","Wind glide"]
static func cost(region:int,companion:int)->int:
	return 1 if region_of(companion)==region else 2
static func trial_sequence(region:int,id:int,step:int)->Array[int]:
	var result:Array[int]=[]
	for k in range(3 if region==0 else 4):
		result.append(posmod(id*3+step*7+k*5+k*k,4))
	return result
static func trial_success(region:int,id:int,step:int,answer:Array,phase:float)->bool:
	if region==1:return is_finite(phase) and phase>=.38 and phase<=.62
	return answer==trial_sequence(region,id,step)

# Sanctuaries are permanent one-time discoveries, not timed expeditions.
const SANCTUARIES=[["Ancient Oak","Moonlit Ruins","Emerald Heart"],["Pearl Cavern","Sunken Temple","Abyssal Crown"],["Wind Citadel","Star Observatory","Celestial Gate"]]
const SANCTUARY_RELICS=[["Amber seed","Moon bark","Emerald heart"],["Pearl fragment","Coral idol","Abyssal crown"],["Wind crystal","Star prism","Celestial key"]]
static func sanctuary_points(region:int,tier:int)->Array[Vector2]:
	var points:Array[Vector2]=[]
	var layouts=[[Vector2(.20,.22),Vector2(.80,.25),Vector2(.74,.72)],[Vector2(.78,.19),Vector2(.19,.45),Vector2(.76,.77)],[Vector2(.24,.19),Vector2(.80,.48),Vector2(.26,.76)]]
	for i in range(3):points.append(layouts[posmod(region+tier,3)][i])
	return points
static func sanctuary_rank(tier:int)->int:return tier+2
static func sanctuary_bit(region:int,tier:int)->int:return 1<<(region*3+tier)
static func sanctuary_cost(tier:int)->int:return 4+tier*2
static func sanctuary_reward(tier:int)->int:return 40+tier*25
