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
	return 3 if id<12 else 4 if id<24 else 5
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
