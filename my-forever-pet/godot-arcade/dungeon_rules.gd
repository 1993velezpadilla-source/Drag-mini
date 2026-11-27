extends RefCounted
# Original turn-based mystery dungeon. Seeded rooms, connected corridors, finite loot.
const DIR=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
# Keep the cardinal terrain generator stable; player navigation uses eight directions.
const DIR8=[Vector2i.UP,Vector2i(1,-1),Vector2i.RIGHT,Vector2i(1,1),Vector2i.DOWN,Vector2i(-1,1),Vector2i.LEFT,Vector2i(-1,-1)]
static func aim8(delta:Vector2)->Vector2i:
	if delta.length_squared()<.0001:return Vector2i.ZERO
	return DIR8[posmod(roundi((atan2(delta.y,delta.x)+PI*.5)/(PI*.25)),8)]
func step_clear(origin:Vector2i,d:Vector2i,cut_corners:bool=false)->bool:
	if not d in DIR8 or not cells.has(origin+d):return false
	if d.x==0 or d.y==0:return true
	var x:bool=cells.has(origin+Vector2i(d.x,0))
	var y:bool=cells.has(origin+Vector2i(0,d.y))
	return (x or y) if cut_corners else (x and y)
const MINION_ROSTER = [[["bramble_pup","Bramble Pup","quadruped_bound","Briar Pounce",0],["sporeling","Sporeling","mushroom_stem_steps","Spore Puff",1],["thornbeetle","Thornbeetle","six_leg_tripod","Thorn Ram",2],["leafwisp","Leafwisp","leaf_flutter","Leaf Dart",1],["rootgnawer","Rootgnawer","boar_trot","Root Tusk",0],["vinesnap","VineSnap","root_pull","Snap Vine",2],["mossmite","Mossmite","rock_roll","Moss Crash",0],["sylphowl","Sylphowl","owl_flap","Feather Needle",1],["hollow_stag","Hollow Stag","deer_prance","Antler Sweep",2],["grovetitan","Grovetitan","tree_biped_stride","Timber Slam",2],["fungal_monarch","Fungal Monarch","mycelial_tripod","Spore Crown",3]],[["reef_pup","Reef Pup","fish_tail_swim","Reef Bite",0],["jellymancer","Jellymancer","bell_jet_pulse","Sting Pulse",1],["shellguard","Shellguard","turtle_paddle","Shell Bash",2],["bubblewisp","Bubblewisp","bubble_buoyancy","Bubble Shot",1],["eelstrix","Eelstrix","eel_wave_swim","Static Lash",0],["coralcrab","Coralcrab","crab_lateral_steps","Claw Snap",0],["anemoneye","Anemoneye","pedal_disc_creep","Tentacle Snare",2],["marrowray","Marrowray","ray_fin_undulation","Fin Slice",1],["leviathorn","Leviathorn","seahorse_dorsal_pulse","Spiral Thrust",2],["abyss_colossus","Abyss Colossus","octopus_arm_crawl","Abyss Crush",2],["tidal_sovereign","Tidal Sovereign","shark_tail_drive","Tidal Bite",3]],[["starlit_pup","Starlit Pup","six_limbed_comet_skip","Star Kick",0],["lunamoth","Lunamoth","moth_wing_clap","Lunar Dust",1],["crystarok","Crystarok","crystal_knuckle_walk","Prism Smash",2],["nova_wisp","Nova Wisp","orbit_drift","Nova Bolt",1],["orbitserpent","Orbitserpent","ring_coil_advance","Orbit Lash",0],["comet_hare","Comet Hare","hind_leg_leap","Comet Drop",0],["voidspider","Voidspider","eight_leg_wave","Gravity Web",2],["nebulwing","Nebulwing","bat_fold_glide","Void Screech",1],["lunar_prowler","Lunar Prowler","feline_stalk","Moon Claw",2],["astro_golem","Astro Golem","floating_segment_stride","Meteor Fist",2],["celestial_guardian","Celestial Guardian","winged_hover","Celestial Verdict",3]]]
# Row: stable species ID, display name, anatomy-specific gait, signature move, combat class.
# Species attack contract: range, telegraph, cooldown, damage modifier, effect, magnitude, VFX identifier.
const SIGNATURE_SKILLS={"bramble_pup":[2,false,2,0,"pounce",1,"briar_arc"],"sporeling":[2,false,3,-1,"poison",2,"spore_cloud"],"thornbeetle":[2,true,2,1,"pounce",1,"horn_ram"],"leafwisp":[3,false,2,-1,"none",0,"leaf_dart"],"rootgnawer":[1,false,2,1,"mark",1,"tusk_sweep"],"vinesnap":[2,true,2,0,"weaken",1,"vine_snap"],"mossmite":[2,false,3,0,"guard",1,"rolling_moss"],"sylphowl":[3,false,3,0,"none",0,"feather_fan"],"hollow_stag":[1,true,2,2,"mark",1,"antler_arc"],"grovetitan":[1,true,3,2,"guard",2,"timber_shock"],"fungal_monarch":[2,true,3,1,"poison",3,"royal_spores"],"reef_pup":[1,false,1,0,"none",0,"reef_bite"],"jellymancer":[2,false,3,-1,"drain",1,"jelly_pulse"],"shellguard":[1,true,2,0,"guard",3,"shell_impact"],"bubblewisp":[3,false,3,-1,"weaken",1,"bubble_burst"],"eelstrix":[2,false,2,0,"drain",1,"electric_lash"],"coralcrab":[1,false,2,1,"guard",1,"double_pincer"],"anemoneye":[2,true,3,0,"weaken",2,"tentacle_snare"],"marrowray":[3,false,2,0,"mark",1,"fin_slice"],"leviathorn":[2,true,2,1,"pounce",1,"spiral_current"],"abyss_colossus":[2,true,3,2,"weaken",1,"abyss_grasp"],"tidal_sovereign":[2,true,2,3,"mark",1,"tidal_jaws"],"starlit_pup":[1,false,2,1,"none",0,"star_kick"],"lunamoth":[2,false,3,-1,"weaken",2,"lunar_dust"],"crystarok":[1,true,2,1,"guard",2,"prism_shatter"],"nova_wisp":[3,false,3,0,"drain",1,"nova_bolt"],"orbitserpent":[2,false,2,0,"mark",1,"orbit_lash"],"comet_hare":[2,false,2,1,"pounce",1,"comet_drop"],"voidspider":[2,true,3,0,"mark",2,"gravity_web"],"nebulwing":[3,false,3,-1,"drain",2,"sonic_cone"],"lunar_prowler":[1,true,2,2,"none",0,"moon_claw"],"astro_golem":[3,true,3,1,"none",0,"meteor_fist"],"celestial_guardian":[3,true,3,2,"drain",2,"celestial_verdict"]}
const ATTACK_PATTERNS={"bramble_pup":"line","sporeling":"radius","thornbeetle":"line","leafwisp":"line","rootgnawer":"front","vinesnap":"corner","mossmite":"line","sylphowl":"fan","hollow_stag":"fan","grovetitan":"radius","fungal_monarch":"radius","reef_pup":"front","jellymancer":"radius","shellguard":"front","bubblewisp":"corner","eelstrix":"line","coralcrab":"fan","anemoneye":"corner","marrowray":"line","leviathorn":"line","abyss_colossus":"radius","tidal_sovereign":"fan","starlit_pup":"front","lunamoth":"fan","crystarok":"radius","nova_wisp":"line","orbitserpent":"corner","comet_hare":"line","voidspider":"corner","nebulwing":"fan","lunar_prowler":"front","astro_golem":"corner","celestial_guardian":"cross"}
# Secondary moves have independent geometry and recovery. They do not stack status effects.
const SECONDARY_SKILLS={"bramble_pup":[1,"fan","Thorn Scratch",-1,"none",0,"slash"],"sporeling":[1,"front","Cap Bonk",-1,"none",0,"roll"],"thornbeetle":[1,"front","Mandible Cut",-1,"none",0,"slash"],"leafwisp":[1,"fan","Razor Leaves",-1,"none",0,"fan"],"rootgnawer":[2,"line","Root Needle",-2,"none",0,"dart"],"vinesnap":[1,"front","Petal Chomp",-1,"none",0,"slash"],"mossmite":[1,"radius","Pebble Scatter",-2,"none",0,"shards"],"sylphowl":[1,"fan","Talon Rake",-1,"none",0,"slash"],"hollow_stag":[2,"line","Bark Spear",-2,"none",0,"dart"],"grovetitan":[2,"corner","Root Hook",-2,"none",0,"whip"],"fungal_monarch":[3,"line","Royal Spore Jet",-2,"none",0,"cloud"],"reef_pup":[2,"line","Water Needle",-2,"none",0,"dart"],"jellymancer":[1,"front","Tentacle Flick",-1,"none",0,"whip"],"shellguard":[2,"line","Shell Disc",-2,"none",0,"roll"],"bubblewisp":[1,"radius","Foam Ring",-2,"none",0,"bubble"],"eelstrix":[1,"fan","Static Fang",-1,"none",0,"lightning"],"coralcrab":[2,"line","Brine Jet",-2,"none",0,"beam"],"anemoneye":[1,"radius","Nettle Bloom",-2,"none",0,"cloud"],"marrowray":[1,"fan","Tail Barb",-1,"none",0,"slash"],"leviathorn":[3,"line","Brackish Lance",-2,"none",0,"spiral"],"abyss_colossus":[1,"radius","Ink Veil",-2,"none",0,"cloud"],"tidal_sovereign":[3,"line","Riptide Rush",-2,"none",0,"wave"],"starlit_pup":[2,"line","Comet Spark",-2,"none",0,"dart"],"lunamoth":[1,"fan","Moon Wing",-1,"none",0,"fan"],"crystarok":[2,"line","Crystal Needle",-2,"none",0,"shards"],"nova_wisp":[1,"radius","Cinder Halo",-2,"none",0,"flame"],"orbitserpent":[1,"front","Ring Fang",-1,"none",0,"slash"],"comet_hare":[1,"fan","Lunar Kick",-1,"none",0,"slash"],"voidspider":[3,"line","Silk Dart",-2,"none",0,"web"],"nebulwing":[1,"radius","Echo Burst",-2,"none",0,"wave"],"lunar_prowler":[2,"line","Shadow Pounce",-2,"none",0,"leap"],"astro_golem":[1,"radius","Gravel Nova",-2,"none",0,"shards"],"celestial_guardian":[2,"fan","Halo Blade",-2,"none",0,"slash"]}
# Kindria original rules, based on documented RPG mechanics, not copied game source.
const TYPE_CHART={"normal":[[],["rock","steel"],["ghost"]],"fire":[["grass","ice","bug","steel"],["fire","water","rock","dragon"],[]],"water":[["fire","ground","rock"],["water","grass","dragon"],[]],"electric":[["water","flying"],["electric","grass","dragon"],["ground"]],"grass":[["water","ground","rock"],["fire","grass","poison","flying","bug","dragon","steel"],[]],"ice":[["grass","ground","flying","dragon"],["fire","water","ice","steel"],[]],"fighting":[["normal","ice","rock","dark","steel"],["poison","flying","psychic","bug","fairy"],["ghost"]],"poison":[["grass","fairy"],["poison","ground","rock","ghost"],["steel"]],"ground":[["fire","electric","poison","rock","steel"],["grass","bug"],["flying"]],"flying":[["grass","fighting","bug"],["electric","rock","steel"],[]],"psychic":[["fighting","poison"],["psychic","steel"],["dark"]],"bug":[["grass","psychic","dark"],["fire","fighting","poison","flying","ghost","steel","fairy"],[]],"rock":[["fire","ice","flying","bug"],["fighting","ground","steel"],[]],"ghost":[["psychic","ghost"],["dark"],["normal"]],"dragon":[["dragon"],["steel"],["fairy"]],"dark":[["psychic","ghost"],["fighting","dark","fairy"],[]],"steel":[["ice","rock","fairy"],["fire","water","electric","steel"],[]],"fairy":[["fighting","dragon","dark"],["fire","poison","steel"],[]]}
const NATURE_NAMES=["Hardy","Lonely","Brave","Adamant","Naughty","Bold","Docile","Relaxed","Impish","Lax","Timid","Hasty","Serious","Jolly","Naive","Modest","Mild","Quiet","Bashful","Rash","Calm","Gentle","Sassy","Careful","Quirky","Lazy"]
# Stat order: HP, attack, defense, special attack, special defense, speed.
# Save-compatible IDs, explicit independent stat pairs. Neutral natures have no modifier.
const NATURE_PAIRS=[[-1,-1],[1,2],[1,5],[1,3],[1,4],[2,1],[-1,-1],[2,5],[2,3],[2,4],[5,1],[5,2],[-1,-1],[5,3],[5,4],[3,1],[3,2],[3,5],[-1,-1],[3,4],[4,1],[4,2],[4,5],[4,3],[-1,-1],[2,5]]
const NATURE_TRAITS=["Resilient","Independent","Fearless","Determined","Mischievous","Confident","Gentle-tempered","Laid-back","Playfully cunning","Easygoing","Cautious","Impatient","Focused","Cheerful","Curious","Unassuming","Soft-spoken","Reserved","Shy","Impulsive","Peaceful","Tender","Spirited","Watchful","Unpredictable","Sleepy"]
const STAT_NAMES=["HP","Attack","Defense","Sp. Attack","Sp. Defense","Speed"]
const ENEMY_TRAINING={"bramble_pup":[["grass","normal"],"grass","normal",1,1,"physical"],"sporeling":[["grass","poison"],"poison","grass",4,1,"special"],"thornbeetle":[["bug","grass"],"bug","bug",2,2,"physical"],"leafwisp":[["grass","flying"],"grass","grass",5,1,"special"],"rootgnawer":[["ground","grass"],"ground","grass",1,1,"physical"],"vinesnap":[["grass","poison"],"grass","grass",1,2,"physical"],"mossmite":[["rock","grass"],"rock","rock",2,1,"physical"],"sylphowl":[["flying","grass"],"flying","flying",5,1,"special"],"hollow_stag":[["grass","ghost"],"grass","grass",1,2,"physical"],"grovetitan":[["grass","ground"],"ground","grass",0,2,"physical"],"fungal_monarch":[["grass","poison"],"poison","poison",4,3,"special"],"reef_pup":[["water"],"water","water",5,1,"physical"],"jellymancer":[["water","electric"],"electric","water",4,1,"special"],"shellguard":[["water","rock"],"rock","rock",2,2,"physical"],"bubblewisp":[["water","fairy"],"water","water",3,1,"special"],"eelstrix":[["water","electric"],"electric","electric",5,1,"special"],"coralcrab":[["water","bug"],"bug","water",1,1,"physical"],"anemoneye":[["water","poison"],"poison","poison",4,2,"physical"],"marrowray":[["water","flying"],"flying","water",5,1,"special"],"leviathorn":[["water","dragon"],"water","water",3,2,"physical"],"abyss_colossus":[["water","dark"],"dark","dark",0,2,"physical"],"tidal_sovereign":[["water","dark"],"water","water",1,3,"physical"],"starlit_pup":[["fairy","normal"],"fairy","fairy",5,1,"physical"],"lunamoth":[["bug","fairy"],"fairy","flying",4,1,"special"],"crystarok":[["rock","ice"],"ice","ice",2,2,"physical"],"nova_wisp":[["fire","ghost"],"fire","fire",3,1,"special"],"orbitserpent":[["dragon","psychic"],"psychic","dragon",3,1,"physical"],"comet_hare":[["normal","fairy"],"fairy","normal",5,1,"physical"],"voidspider":[["bug","dark"],"dark","bug",2,2,"special"],"nebulwing":[["flying","ghost"],"ghost","flying",5,1,"special"],"lunar_prowler":[["dark","ice"],"dark","dark",1,2,"physical"],"astro_golem":[["rock","psychic"],"rock","rock",2,2,"physical"],"celestial_guardian":[["flying","fairy"],"fairy","fairy",3,3,"special"]}
const MOVE_LIBRARY={"lib_normal_1":{"name":"Tackle Rush","type":"normal","pattern":"front","reach":1,"category":"physical","power":6,"pp":18,"learn_level":1,"mode":"leap","light":"#fff4d6","dark":"#c09d70","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48},"lib_normal_2":{"name":"Echo Slam","type":"normal","pattern":"radius","reach":2,"category":"physical","power":9,"pp":13,"learn_level":8,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.55,"caster":"attack","frame_count":12,"frame_size":48},"lib_normal_3":{"name":"Sonic Ray","type":"normal","pattern":"line","reach":4,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"beam","light":"#fff4d6","dark":"#c09d70","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_fire_1":{"name":"Ember Dart","type":"fire","pattern":"corner_front","reach":1,"category":"special","power":7,"pp":15,"learn_level":1,"mode":"dart","light":"#fff4a0","dark":"#e95237","duration":0.4,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":262,"reference_key":"EMBER","acc1":100,"acc2":88,"reference_crit":8},"lib_fire_2":{"name":"Blazing Torrent","type":"fire","pattern":"line","reach":10,"category":"special","power":18,"pp":12,"learn_level":8,"mode":"fire_stream","light":"#fff4a0","dark":"#e95237","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":53,"reference_key":"FLAMETHROWER","acc1":95,"acc2":88,"reference_crit":8},"lib_fire_3":{"name":"Cinder Vortex","type":"fire","pattern":"radius","reach":2,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"fire_ring","light":"#fff4a0","dark":"#e95237","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_water_1":{"name":"Foam Shot","type":"water","pattern":"line","reach":10,"category":"special","power":4,"pp":12,"learn_level":1,"mode":"bubble","light":"#dcffff","dark":"#329ed3","duration":0.4,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":16,"reference_key":"BUBBLE","acc1":95,"acc2":88,"reference_crit":8},"lib_water_2":{"name":"Pearl Torrent","type":"water","pattern":"line","reach":10,"category":"special","power":6,"pp":10,"learn_level":8,"mode":"bubble_beam","light":"#dcffff","dark":"#329ed3","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":255,"reference_key":"BUBBLEBEAM","acc1":95,"acc2":88,"reference_crit":8},"lib_water_3":{"name":"Surge Wall","type":"water","pattern":"fan","reach":3,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"wave","light":"#dcffff","dark":"#329ed3","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_electric_1":{"name":"Static Fang","type":"electric","pattern":"front","reach":1,"category":"physical","power":6,"pp":17,"learn_level":1,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":65,"reference_key":"THUNDERPUNCH","acc1":100,"acc2":88,"reference_crit":8},"lib_electric_2":{"name":"Arc Current","type":"electric","pattern":"line","reach":10,"category":"special","power":7,"pp":8,"learn_level":8,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":189,"reference_key":"SHOCK_WAVE","acc1":125,"acc2":125,"reference_crit":8},"lib_electric_3":{"name":"Storm Cross","type":"electric","pattern":"radius","reach":1,"category":"special","power":18,"pp":10,"learn_level":15,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":129,"reference_key":"THUNDERBOLT","acc1":88,"acc2":84,"reference_crit":8},"lib_grass_1":{"name":"Briar Whip","type":"grass","pattern":"front","reach":1,"category":"physical","power":6,"pp":18,"learn_level":1,"mode":"vine","light":"#d2f49c","dark":"#428b4b","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":182,"reference_key":"VINE_WHIP","acc1":100,"acc2":88,"reference_crit":8},"lib_grass_2":{"name":"Razor Sprout","type":"grass","pattern":"line","reach":4,"category":"special","power":9,"pp":13,"learn_level":8,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48},"lib_grass_3":{"name":"Root Quake","type":"grass","pattern":"radius","reach":2,"category":"physical","power":12,"pp":8,"learn_level":15,"mode":"quake","light":"#d2f49c","dark":"#428b4b","duration":0.7,"caster":"attack","frame_count":12,"frame_size":48},"lib_ice_1":{"name":"Frost Needle","type":"ice","pattern":"line","reach":3,"category":"special","power":6,"pp":18,"learn_level":1,"mode":"shards","light":"#efffff","dark":"#70bde3","duration":0.4,"caster":"shoot","frame_count":12,"frame_size":48},"lib_ice_2":{"name":"Glacier Ray","type":"ice","pattern":"line","reach":4,"category":"special","power":9,"pp":13,"learn_level":8,"mode":"beam","light":"#efffff","dark":"#70bde3","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48},"lib_ice_3":{"name":"Snow Spiral","type":"ice","pattern":"radius","reach":2,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"cloud","light":"#efffff","dark":"#70bde3","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_fighting_1":{"name":"Palm Burst","type":"fighting","pattern":"front","reach":1,"category":"physical","power":6,"pp":18,"learn_level":1,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48},"lib_fighting_2":{"name":"Crescent Kick","type":"fighting","pattern":"fan","reach":2,"category":"physical","power":9,"pp":13,"learn_level":8,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.55,"caster":"attack","frame_count":12,"frame_size":48},"lib_fighting_3":{"name":"Spirit Fist","type":"fighting","pattern":"line","reach":3,"category":"physical","power":12,"pp":8,"learn_level":15,"mode":"leap","light":"#ffdfbb","dark":"#d97742","duration":0.7,"caster":"attack","frame_count":12,"frame_size":48},"lib_poison_1":{"name":"Venom Flick","type":"poison","pattern":"front","reach":1,"category":"physical","power":6,"pp":18,"learn_level":1,"mode":"dart","light":"#f5c1ff","dark":"#9a49ad","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48},"lib_poison_2":{"name":"Acid Arc","type":"poison","pattern":"corner","reach":3,"category":"special","power":9,"pp":13,"learn_level":8,"mode":"cloud","light":"#f5c1ff","dark":"#9a49ad","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48},"lib_poison_3":{"name":"Toxic Bloom","type":"poison","pattern":"radius","reach":2,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"cloud","light":"#f5c1ff","dark":"#9a49ad","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_ground_1":{"name":"Fissure Slam","type":"ground","pattern":"room","reach":0,"category":"physical","power":5,"pp":10,"learn_level":1,"mode":"quake","light":"#f4cd8c","dark":"#9a623f","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":118,"reference_key":"EARTHQUAKE","acc1":80,"acc2":65,"reference_crit":8},"lib_ground_2":{"name":"Sand Drill","type":"ground","pattern":"line","reach":3,"category":"physical","power":9,"pp":13,"learn_level":8,"mode":"roll","light":"#f4cd8c","dark":"#9a623f","duration":0.55,"caster":"attack","frame_count":12,"frame_size":48},"lib_ground_3":{"name":"Mud Lance","type":"ground","pattern":"line","reach":2,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"dart","light":"#f4cd8c","dark":"#9a623f","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_flying_1":{"name":"Feather Needle","type":"flying","pattern":"line","reach":3,"category":"special","power":6,"pp":18,"learn_level":1,"mode":"dart","light":"#e6faff","dark":"#9aaceb","duration":0.4,"caster":"shoot","frame_count":12,"frame_size":48},"lib_flying_2":{"name":"Gale Scythe","type":"flying","pattern":"fan","reach":3,"category":"special","power":9,"pp":13,"learn_level":8,"mode":"fan","light":"#e6faff","dark":"#9aaceb","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48},"lib_flying_3":{"name":"Cyclone Ring","type":"flying","pattern":"radius","reach":2,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"spiral","light":"#e6faff","dark":"#9aaceb","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_psychic_1":{"name":"Mind Spear","type":"psychic","pattern":"line","reach":3,"category":"special","power":6,"pp":18,"learn_level":1,"mode":"beam","light":"#ffdcf8","dark":"#c063bc","duration":0.4,"caster":"shoot","frame_count":12,"frame_size":48},"lib_psychic_2":{"name":"Mirage Pulse","type":"psychic","pattern":"corner","reach":3,"category":"special","power":9,"pp":13,"learn_level":8,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48},"lib_psychic_3":{"name":"Astral Crush","type":"psychic","pattern":"cross","reach":3,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"radiant","light":"#ffdcf8","dark":"#c063bc","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_bug_1":{"name":"Silk Snare","type":"bug","pattern":"corner","reach":2,"category":"special","power":6,"pp":18,"learn_level":1,"mode":"silk","light":"#ebf5af","dark":"#7e9c36","duration":0.4,"caster":"shoot","frame_count":12,"frame_size":48},"lib_bug_2":{"name":"Carapace Charge","type":"bug","pattern":"line","reach":2,"category":"physical","power":9,"pp":13,"learn_level":8,"mode":"leap","light":"#ebf5af","dark":"#7e9c36","duration":0.55,"caster":"attack","frame_count":12,"frame_size":48},"lib_bug_3":{"name":"Wing Scales","type":"bug","pattern":"fan","reach":3,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"cloud","light":"#ebf5af","dark":"#7e9c36","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_rock_1":{"name":"Pebble Shot","type":"rock","pattern":"line","reach":2,"category":"physical","power":6,"pp":18,"learn_level":1,"mode":"dart","light":"#f0dec2","dark":"#a38966","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48},"lib_rock_2":{"name":"Boulder Rush","type":"rock","pattern":"line","reach":3,"category":"physical","power":9,"pp":13,"learn_level":8,"mode":"roll","light":"#f0dec2","dark":"#a38966","duration":0.55,"caster":"attack","frame_count":12,"frame_size":48},"lib_rock_3":{"name":"Crystal Avalanche","type":"rock","pattern":"fan","reach":2,"category":"physical","power":12,"pp":8,"learn_level":15,"mode":"shards","light":"#f0dec2","dark":"#a38966","duration":0.7,"caster":"attack","frame_count":12,"frame_size":48},"lib_ghost_1":{"name":"Shade Claw","type":"ghost","pattern":"front","reach":1,"category":"physical","power":6,"pp":18,"learn_level":1,"mode":"slash","light":"#e5d9ff","dark":"#8662c9","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48},"lib_ghost_2":{"name":"Phantom Thread","type":"ghost","pattern":"corner","reach":3,"category":"special","power":9,"pp":13,"learn_level":8,"mode":"whip","light":"#e5d9ff","dark":"#8662c9","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48},"lib_ghost_3":{"name":"Spectral Bloom","type":"ghost","pattern":"radius","reach":2,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"cloud","light":"#e5d9ff","dark":"#8662c9","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_dragon_1":{"name":"Drake Claw","type":"dragon","pattern":"fan","reach":1,"category":"physical","power":6,"pp":18,"learn_level":1,"mode":"slash","light":"#f6ceff","dark":"#7359d2","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48},"lib_dragon_2":{"name":"Drake Breath","type":"dragon","pattern":"line","reach":4,"category":"special","power":9,"pp":13,"learn_level":8,"mode":"fire_stream","light":"#f6ceff","dark":"#7359d2","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48},"lib_dragon_3":{"name":"Orbit Fang","type":"dragon","pattern":"corner","reach":3,"category":"physical","power":12,"pp":8,"learn_level":15,"mode":"spiral","light":"#f6ceff","dark":"#7359d2","duration":0.7,"caster":"attack","frame_count":12,"frame_size":48},"lib_dark_1":{"name":"Shadow Fang","type":"dark","pattern":"front","reach":1,"category":"physical","power":6,"pp":18,"learn_level":1,"mode":"slash","light":"#dfc3f8","dark":"#67457a","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48},"lib_dark_2":{"name":"Night Rift","type":"dark","pattern":"corner","reach":3,"category":"special","power":9,"pp":13,"learn_level":8,"mode":"web","light":"#dfc3f8","dark":"#67457a","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48},"lib_dark_3":{"name":"Void Pulse","type":"dark","pattern":"cross","reach":3,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"wave","light":"#dfc3f8","dark":"#67457a","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"lib_steel_1":{"name":"Iron Edge","type":"steel","pattern":"front","reach":1,"category":"physical","power":6,"pp":18,"learn_level":1,"mode":"slash","light":"#f0f9ff","dark":"#899eae","duration":0.4,"caster":"attack","frame_count":12,"frame_size":48},"lib_steel_2":{"name":"Alloy Spear","type":"steel","pattern":"line","reach":3,"category":"physical","power":9,"pp":13,"learn_level":8,"mode":"dart","light":"#f0f9ff","dark":"#899eae","duration":0.55,"caster":"attack","frame_count":12,"frame_size":48},"lib_steel_3":{"name":"Metal Storm","type":"steel","pattern":"fan","reach":3,"category":"physical","power":12,"pp":8,"learn_level":15,"mode":"shards","light":"#f0f9ff","dark":"#899eae","duration":0.7,"caster":"attack","frame_count":12,"frame_size":48},"lib_fairy_1":{"name":"Glimmer Shot","type":"fairy","pattern":"line","reach":2,"category":"special","power":6,"pp":18,"learn_level":1,"mode":"dart","light":"#fff0fa","dark":"#e88bc1","duration":0.4,"caster":"shoot","frame_count":12,"frame_size":48},"lib_fairy_2":{"name":"Pixie Halo","type":"fairy","pattern":"radius","reach":2,"category":"special","power":9,"pp":13,"learn_level":8,"mode":"radiant","light":"#fff0fa","dark":"#e88bc1","duration":0.55,"caster":"shoot","frame_count":12,"frame_size":48},"lib_fairy_3":{"name":"Moon Prism","type":"fairy","pattern":"cross","reach":3,"category":"special","power":12,"pp":8,"learn_level":15,"mode":"beam","light":"#fff0fa","dark":"#e88bc1","duration":0.7,"caster":"shoot","frame_count":12,"frame_size":48},"eos_001":{"name":"Iron Tail","type":"steel","pattern":"front","reach":1,"category":"physical","power":40,"pp":10,"learn_level":40,"mode":"slash","light":"#f0f9ff","dark":"#899eae","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":1,"reference_key":"IRON_TAIL","acc1":125,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_008":{"name":"Burrow Strike","type":"ground","pattern":"front","reach":1,"category":"physical","power":12,"pp":12,"learn_level":26,"mode":"quake","light":"#f4cd8c","dark":"#9a623f","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":8,"reference_key":"DIG","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"charge_phase":"underground","release_multiplier":2},"eos_016":{"name":"Bubble","type":"water","pattern":"line","reach":10,"category":"special","power":4,"pp":12,"learn_level":22,"mode":"bubble","light":"#dcffff","dark":"#329ed3","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":16,"reference_key":"BUBBLE","acc1":95,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_018":{"name":"Cut","type":"normal","pattern":"radius","reach":1,"category":"physical","power":10,"pp":10,"learn_level":25,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":18,"reference_key":"CUT","acc1":88,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true},"eos_028":{"name":"Rock Throw","type":"rock","pattern":"front","reach":1,"category":"physical","power":5,"pp":16,"learn_level":22,"mode":"roll","light":"#f0dec2","dark":"#a38966","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":28,"reference_key":"ROCK_THROW","acc1":125,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_030":{"name":"Rock Slide","type":"rock","pattern":"front","reach":1,"category":"physical","power":14,"pp":13,"learn_level":27,"mode":"roll","light":"#f0dec2","dark":"#a38966","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":30,"reference_key":"ROCK_SLIDE","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_031":{"name":"Weather Ball","type":"normal","pattern":"line","reach":10,"category":"special","power":5,"pp":15,"learn_level":22,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":31,"reference_key":"WEATHER_BALL","acc1":95,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_032":{"name":"Whirlpool","type":"water","pattern":"front","reach":1,"category":"special","power":2,"pp":17,"learn_level":21,"mode":"bubble","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":32,"reference_key":"WHIRLPOOL","acc1":100,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_036":{"name":"Air Cutter","type":"flying","pattern":"corner_front","reach":1,"category":"special","power":2,"pp":17,"learn_level":21,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":36,"reference_key":"AIR_CUTTER","acc1":125,"acc2":90,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_041":{"name":"Overheat","type":"fire","pattern":"radius","reach":1,"category":"special","power":20,"pp":10,"learn_level":30,"mode":"flame","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":41,"reference_key":"OVERHEAT","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true},"eos_042":{"name":"Aurora Beam","type":"ice","pattern":"line","reach":10,"category":"special","power":10,"pp":17,"learn_level":25,"mode":"beam","light":"#efffff","dark":"#70bde3","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":42,"reference_key":"AURORA_BEAM","acc1":95,"acc2":65,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_044":{"name":"Octazooka","type":"water","pattern":"line","reach":10,"category":"special","power":8,"pp":15,"learn_level":24,"mode":"bubble","light":"#dcffff","dark":"#329ed3","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":44,"reference_key":"OCTAZOOKA","acc1":95,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_046":{"name":"Astonish","type":"ghost","pattern":"front","reach":1,"category":"physical","power":6,"pp":17,"learn_level":23,"mode":"slash","light":"#e5d9ff","dark":"#8662c9","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":46,"reference_key":"ASTONISH","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_052":{"name":"Flame Wheel","type":"fire","pattern":"corner_front","reach":1,"category":"physical","power":12,"pp":11,"learn_level":26,"mode":"leap","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":52,"reference_key":"FLAME_WHEEL","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_053":{"name":"Flamethrower","type":"fire","pattern":"line","reach":10,"category":"special","power":18,"pp":12,"learn_level":29,"mode":"fire_stream","light":"#fff4a0","dark":"#e95237","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":53,"reference_key":"FLAMETHROWER","acc1":95,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_057":{"name":"Gust","type":"flying","pattern":"front","reach":1,"category":"special","power":4,"pp":19,"learn_level":22,"mode":"fan","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":57,"reference_key":"GUST","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_060":{"name":"Razor Gale","type":"normal","pattern":"corner_front","reach":1,"category":"special","power":16,"pp":13,"learn_level":28,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":60,"reference_key":"RAZOR_WIND","acc1":125,"acc2":100,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"charge_phase":"gather","release_multiplier":2},"eos_062":{"name":"Crunch","type":"dark","pattern":"front","reach":1,"category":"physical","power":16,"pp":13,"learn_level":28,"mode":"slash","light":"#dfc3f8","dark":"#67457a","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":62,"reference_key":"CRUNCH","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_063":{"name":"Bite","type":"dark","pattern":"front","reach":1,"category":"physical","power":7,"pp":19,"learn_level":23,"mode":"slash","light":"#dfc3f8","dark":"#67457a","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":63,"reference_key":"BITE","acc1":125,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_064":{"name":"Thunder","type":"electric","pattern":"front","reach":1,"category":"special","power":45,"pp":7,"learn_level":42,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":64,"reference_key":"THUNDER","acc1":100,"acc2":73,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_065":{"name":"Thunderpunch","type":"electric","pattern":"front","reach":1,"category":"physical","power":6,"pp":17,"learn_level":23,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":65,"reference_key":"THUNDERPUNCH","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_067":{"name":"Facade","type":"normal","pattern":"front","reach":1,"category":"physical","power":14,"pp":12,"learn_level":27,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":67,"reference_key":"FACADE","acc1":125,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_068":{"name":"Karate Chop","type":"fighting","pattern":"front","reach":1,"category":"physical","power":10,"pp":18,"learn_level":25,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":68,"reference_key":"KARATE_CHOP","acc1":100,"acc2":90,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_069":{"name":"Clamp","type":"water","pattern":"front","reach":1,"category":"physical","power":6,"pp":17,"learn_level":23,"mode":"slash","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":69,"reference_key":"CLAMP","acc1":125,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_071":{"name":"Constrict","type":"normal","pattern":"front","reach":1,"category":"physical","power":2,"pp":22,"learn_level":21,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":71,"reference_key":"CONSTRICT","acc1":88,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_072":{"name":"Brick Break","type":"fighting","pattern":"front","reach":1,"category":"physical","power":14,"pp":12,"learn_level":27,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":72,"reference_key":"BRICK_BREAK","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_073":{"name":"Rock Tomb","type":"rock","pattern":"front","reach":1,"category":"physical","power":10,"pp":12,"learn_level":25,"mode":"roll","light":"#f0dec2","dark":"#a38966","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":73,"reference_key":"ROCK_TOMB","acc1":100,"acc2":60,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_075":{"name":"Focused Fist","type":"fighting","pattern":"front","reach":1,"category":"physical","power":55,"pp":8,"learn_level":47,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":75,"reference_key":"FOCUS_PUNCH","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"charge_phase":"gather","release_multiplier":2},"eos_076":{"name":"Giga Drain","type":"grass","pattern":"front","reach":1,"category":"special","power":12,"pp":10,"learn_level":26,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":76,"reference_key":"GIGA_DRAIN","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"drain_fraction":0.5},"eos_077":{"name":"Reversal","type":"fighting","pattern":"front","reach":1,"category":"physical","power":2,"pp":12,"learn_level":21,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":77,"reference_key":"REVERSAL","acc1":70,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_078":{"name":"Smellingsalt","type":"normal","pattern":"front","reach":1,"category":"physical","power":12,"pp":15,"learn_level":26,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":78,"reference_key":"SMELLINGSALT","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_080":{"name":"Leech Life","type":"bug","pattern":"front","reach":1,"category":"physical","power":4,"pp":19,"learn_level":22,"mode":"slash","light":"#ebf5af","dark":"#7e9c36","duration":0.72,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":80,"reference_key":"LEECH_LIFE","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"drain_fraction":0.5},"eos_081":{"name":"Slash","type":"normal","pattern":"front","reach":1,"category":"physical","power":14,"pp":11,"learn_level":27,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":81,"reference_key":"SLASH","acc1":100,"acc2":88,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_082":{"name":"Silver Wind","type":"bug","pattern":"room","reach":0,"category":"special","power":6,"pp":7,"learn_level":23,"mode":"silk","light":"#ebf5af","dark":"#7e9c36","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":82,"reference_key":"SILVER_WIND","acc1":88,"acc2":70,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true},"eos_087":{"name":"Crabhammer","type":"water","pattern":"front","reach":1,"category":"physical","power":18,"pp":12,"learn_level":29,"mode":"slash","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":87,"reference_key":"CRABHAMMER","acc1":88,"acc2":88,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_090":{"name":"Cross Chop","type":"fighting","pattern":"front","reach":1,"category":"physical","power":20,"pp":10,"learn_level":30,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":90,"reference_key":"CROSS_CHOP","acc1":125,"acc2":84,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_092":{"name":"Low Kick","type":"fighting","pattern":"front","reach":1,"category":"physical","power":7,"pp":16,"learn_level":23,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":92,"reference_key":"LOW_KICK","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_093":{"name":"Ancientpower","type":"rock","pattern":"corner_front","reach":1,"category":"special","power":12,"pp":12,"learn_level":26,"mode":"shards","light":"#f0dec2","dark":"#a38966","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":93,"reference_key":"ANCIENTPOWER","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_096":{"name":"Rapid Spin","type":"normal","pattern":"front","reach":1,"category":"physical","power":4,"pp":17,"learn_level":22,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":96,"reference_key":"RAPID_SPIN","acc1":125,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_097":{"name":"Icy Wind","type":"ice","pattern":"line","reach":10,"category":"special","power":5,"pp":13,"learn_level":22,"mode":"beam","light":"#efffff","dark":"#70bde3","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":97,"reference_key":"ICY_WIND","acc1":95,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_100":{"name":"Skyfall Charge","type":"flying","pattern":"corner_front","reach":1,"category":"physical","power":50,"pp":6,"learn_level":45,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":100,"reference_key":"SKY_ATTACK","acc1":125,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"charge_phase":"gather","release_multiplier":2},"eos_101":{"name":"Powder Snow","type":"ice","pattern":"room","reach":0,"category":"special","power":4,"pp":10,"learn_level":22,"mode":"beam","light":"#efffff","dark":"#70bde3","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":101,"reference_key":"POWDER_SNOW","acc1":125,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true},"eos_103":{"name":"Meteor Mash","type":"steel","pattern":"line","reach":10,"category":"physical","power":20,"pp":9,"learn_level":30,"mode":"slash","light":"#f0f9ff","dark":"#899eae","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":103,"reference_key":"METEOR_MASH","acc1":95,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_107":{"name":"Psybeam","type":"psychic","pattern":"line","reach":10,"category":"special","power":12,"pp":17,"learn_level":26,"mode":"beam","light":"#ffdcf8","dark":"#c063bc","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":107,"reference_key":"PSYBEAM","acc1":95,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_109":{"name":"Psychic","type":"psychic","pattern":"front","reach":1,"category":"special","power":38,"pp":10,"learn_level":39,"mode":"beam","light":"#ffdcf8","dark":"#c063bc","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":109,"reference_key":"PSYCHIC","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_110":{"name":"Psycho Boost","type":"psychic","pattern":"front","reach":1,"category":"special","power":44,"pp":5,"learn_level":42,"mode":"beam","light":"#ffdcf8","dark":"#c063bc","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":110,"reference_key":"PSYCHO_BOOST","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_113":{"name":"Water Spout","type":"water","pattern":"front","reach":1,"category":"special","power":42,"pp":5,"learn_level":41,"mode":"bubble","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":113,"reference_key":"WATER_SPOUT","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_114":{"name":"Signal Beam","type":"bug","pattern":"line","reach":10,"category":"special","power":8,"pp":15,"learn_level":24,"mode":"beam","light":"#ebf5af","dark":"#7e9c36","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":114,"reference_key":"SIGNAL_BEAM","acc1":95,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_116":{"name":"Submission","type":"fighting","pattern":"front","reach":1,"category":"physical","power":15,"pp":17,"learn_level":27,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":116,"reference_key":"SUBMISSION","acc1":125,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"recoil_fraction":0.125},"eos_120":{"name":"Lick","type":"ghost","pattern":"front","reach":1,"category":"physical","power":4,"pp":20,"learn_level":22,"mode":"slash","light":"#e5d9ff","dark":"#8662c9","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":120,"reference_key":"LICK","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_121":{"name":"Flail","type":"normal","pattern":"front","reach":1,"category":"physical","power":2,"pp":17,"learn_level":21,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":121,"reference_key":"FLAIL","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_125":{"name":"Bind","type":"normal","pattern":"front","reach":1,"category":"physical","power":4,"pp":17,"learn_level":22,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":125,"reference_key":"BIND","acc1":125,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_126":{"name":"Shadow Punch","type":"ghost","pattern":"front","reach":1,"category":"physical","power":6,"pp":8,"learn_level":23,"mode":"slash","light":"#e5d9ff","dark":"#8662c9","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":126,"reference_key":"SHADOW_PUNCH","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_127":{"name":"Shadow Ball","type":"ghost","pattern":"line","reach":10,"category":"special","power":16,"pp":10,"learn_level":28,"mode":"cloud","light":"#e5d9ff","dark":"#8662c9","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":127,"reference_key":"SHADOW_BALL","acc1":95,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_129":{"name":"Thunderbolt","type":"electric","pattern":"radius","reach":1,"category":"special","power":18,"pp":10,"learn_level":29,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":129,"reference_key":"THUNDERBOLT","acc1":88,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true},"eos_132":{"name":"Extremespeed","type":"normal","pattern":"line","reach":2,"category":"physical","power":16,"pp":12,"learn_level":28,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":132,"reference_key":"EXTREMESPEED","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_133":{"name":"Extrasensory","type":"psychic","pattern":"front","reach":1,"category":"special","power":16,"pp":12,"learn_level":28,"mode":"beam","light":"#ffdcf8","dark":"#c063bc","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":133,"reference_key":"EXTRASENSORY","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_135":{"name":"Absorb","type":"grass","pattern":"front","reach":1,"category":"special","power":1,"pp":15,"learn_level":20,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":135,"reference_key":"ABSORB","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"drain_fraction":0.5},"eos_136":{"name":"Sky Uppercut","type":"fighting","pattern":"front","reach":1,"category":"physical","power":16,"pp":12,"learn_level":28,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":136,"reference_key":"SKY_UPPERCUT","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_139":{"name":"Headbutt","type":"normal","pattern":"front","reach":1,"category":"physical","power":6,"pp":17,"learn_level":23,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":139,"reference_key":"HEADBUTT","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_140":{"name":"Double Edge","type":"normal","pattern":"front","reach":1,"category":"physical","power":20,"pp":12,"learn_level":30,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":140,"reference_key":"DOUBLE_EDGE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"recoil_fraction":0.125},"eos_143":{"name":"Sand Tomb","type":"ground","pattern":"front","reach":1,"category":"physical","power":4,"pp":17,"learn_level":22,"mode":"quake","light":"#f4cd8c","dark":"#9a623f","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":143,"reference_key":"SAND_TOMB","acc1":125,"acc2":73,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_144":{"name":"Spark","type":"electric","pattern":"front","reach":1,"category":"physical","power":12,"pp":15,"learn_level":26,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":144,"reference_key":"SPARK","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_145":{"name":"Swift","type":"normal","pattern":"corner_front","reach":1,"category":"special","power":10,"pp":8,"learn_level":25,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":145,"reference_key":"SWIFT","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_147":{"name":"Smog","type":"poison","pattern":"front","reach":1,"category":"special","power":4,"pp":17,"learn_level":22,"mode":"cloud","light":"#f5c1ff","dark":"#9a49ad","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":147,"reference_key":"SMOG","acc1":100,"acc2":73,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_149":{"name":"Sacred Fire","type":"fire","pattern":"front","reach":1,"category":"physical","power":50,"pp":10,"learn_level":45,"mode":"leap","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":149,"reference_key":"SACRED_FIRE","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_151":{"name":"Sunlance","type":"grass","pattern":"corner_front","reach":1,"category":"special","power":24,"pp":9,"learn_level":32,"mode":"beam","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":151,"reference_key":"SOLARBEAM","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"charge_phase":"gather","release_multiplier":2},"eos_153":{"name":"Aerial Dive","type":"flying","pattern":"front","reach":1,"category":"physical","power":14,"pp":12,"learn_level":27,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":153,"reference_key":"FLY","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"charge_phase":"airborne","release_multiplier":2},"eos_154":{"name":"Tackle","type":"normal","pattern":"front","reach":1,"category":"physical","power":6,"pp":30,"learn_level":23,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":154,"reference_key":"TACKLE","acc1":100,"acc2":95,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_156":{"name":"Dive","type":"water","pattern":"front","reach":1,"category":"physical","power":12,"pp":12,"learn_level":26,"mode":"slash","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":156,"reference_key":"DIVE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_157":{"name":"Fire Blast","type":"fire","pattern":"corner_front","reach":1,"category":"special","power":33,"pp":9,"learn_level":36,"mode":"fire_stream","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":157,"reference_key":"FIRE_BLAST","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_158":{"name":"Waterfall","type":"water","pattern":"front","reach":1,"category":"physical","power":16,"pp":12,"learn_level":28,"mode":"slash","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":158,"reference_key":"WATERFALL","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_159":{"name":"Muddy Water","type":"water","pattern":"front","reach":1,"category":"special","power":18,"pp":10,"learn_level":29,"mode":"bubble","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":159,"reference_key":"MUDDY_WATER","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_161":{"name":"Slam","type":"normal","pattern":"front","reach":1,"category":"physical","power":16,"pp":12,"learn_level":28,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":161,"reference_key":"SLAM","acc1":100,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_162":{"name":"Twister","type":"dragon","pattern":"front","reach":1,"category":"special","power":8,"pp":15,"learn_level":24,"mode":"fire_stream","light":"#f6ceff","dark":"#7359d2","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":162,"reference_key":"TWISTER","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_166":{"name":"Egg Bomb","type":"normal","pattern":"corner_front","reach":1,"category":"physical","power":10,"pp":15,"learn_level":25,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":166,"reference_key":"EGG_BOMB","acc1":100,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_167":{"name":"Faint Attack","type":"dark","pattern":"front","reach":1,"category":"physical","power":6,"pp":25,"learn_level":23,"mode":"slash","light":"#dfc3f8","dark":"#67457a","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":167,"reference_key":"FAINT_ATTACK","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_174":{"name":"Peck","type":"flying","pattern":"front","reach":1,"category":"physical","power":4,"pp":26,"learn_level":22,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":174,"reference_key":"PECK","acc1":100,"acc2":95,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_176":{"name":"Horn Attack","type":"normal","pattern":"front","reach":1,"category":"physical","power":8,"pp":18,"learn_level":24,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":176,"reference_key":"HORN_ATTACK","acc1":100,"acc2":95,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_178":{"name":"Wing Attack","type":"flying","pattern":"front","reach":1,"category":"physical","power":6,"pp":20,"learn_level":23,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":178,"reference_key":"WING_ATTACK","acc1":100,"acc2":95,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_179":{"name":"Aerial Ace","type":"flying","pattern":"front","reach":1,"category":"physical","power":10,"pp":8,"learn_level":25,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":179,"reference_key":"AERIAL_ACE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_182":{"name":"Vine Whip","type":"grass","pattern":"front","reach":1,"category":"physical","power":6,"pp":18,"learn_level":23,"mode":"vine","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":182,"reference_key":"VINE_WHIP","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_188":{"name":"Thundershock","type":"electric","pattern":"front","reach":1,"category":"special","power":1,"pp":17,"learn_level":20,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":188,"reference_key":"THUNDERSHOCK","acc1":100,"acc2":88,"reference_crit":2,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_189":{"name":"Shock Wave","type":"electric","pattern":"line","reach":10,"category":"special","power":7,"pp":8,"learn_level":23,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":189,"reference_key":"SHOCK_WAVE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_190":{"name":"Quick Attack","type":"normal","pattern":"line","reach":2,"category":"physical","power":4,"pp":13,"learn_level":22,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":190,"reference_key":"QUICK_ATTACK","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_193":{"name":"Zap Cannon","type":"electric","pattern":"line","reach":10,"category":"special","power":20,"pp":9,"learn_level":30,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":193,"reference_key":"ZAP_CANNON","acc1":95,"acc2":65,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_198":{"name":"Poison Fang","type":"poison","pattern":"front","reach":1,"category":"physical","power":10,"pp":15,"learn_level":25,"mode":"slash","light":"#f5c1ff","dark":"#9a49ad","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":198,"reference_key":"POISON_FANG","acc1":88,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_200":{"name":"Poison Sting","type":"poison","pattern":"corner_front","reach":1,"category":"physical","power":3,"pp":19,"learn_level":21,"mode":"dart","light":"#f5c1ff","dark":"#9a49ad","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":200,"reference_key":"POISON_STING","acc1":100,"acc2":73,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_203":{"name":"Take Down","type":"normal","pattern":"front","reach":1,"category":"physical","power":8,"pp":19,"learn_level":24,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":203,"reference_key":"TAKE_DOWN","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"recoil_fraction":0.125},"eos_204":{"name":"Jump Kick","type":"fighting","pattern":"front","reach":1,"category":"physical","power":14,"pp":13,"learn_level":27,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":204,"reference_key":"JUMP_KICK","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_205":{"name":"Vault Crash","type":"flying","pattern":"front","reach":1,"category":"physical","power":16,"pp":11,"learn_level":28,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":205,"reference_key":"BOUNCE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"charge_phase":"airborne","release_multiplier":2},"eos_206":{"name":"Hi Jump Kick","type":"fighting","pattern":"front","reach":1,"category":"physical","power":16,"pp":11,"learn_level":28,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":206,"reference_key":"HI_JUMP_KICK","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_207":{"name":"Tri Attack","type":"normal","pattern":"corner_front","reach":1,"category":"special","power":6,"pp":17,"learn_level":23,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":207,"reference_key":"TRI_ATTACK","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_208":{"name":"Dragon Claw","type":"dragon","pattern":"front","reach":1,"category":"physical","power":16,"pp":10,"learn_level":28,"mode":"slash","light":"#f6ceff","dark":"#7359d2","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":208,"reference_key":"DRAGON_CLAW","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_211":{"name":"Drill Peck","type":"flying","pattern":"front","reach":1,"category":"physical","power":16,"pp":13,"learn_level":28,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":211,"reference_key":"DRILL_PECK","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_213":{"name":"Mud Slap","type":"ground","pattern":"corner_front","reach":1,"category":"special","power":4,"pp":16,"learn_level":22,"mode":"dart","light":"#f4cd8c","dark":"#9a623f","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":213,"reference_key":"MUD_SLAP","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_214":{"name":"Thief","type":"dark","pattern":"front","reach":1,"category":"physical","power":2,"pp":20,"learn_level":21,"mode":"slash","light":"#dfc3f8","dark":"#67457a","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":214,"reference_key":"THIEF","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_219":{"name":"Surf","type":"water","pattern":"front","reach":1,"category":"special","power":30,"pp":11,"learn_level":35,"mode":"bubble","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":219,"reference_key":"SURF","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_221":{"name":"Needle Arm","type":"grass","pattern":"front","reach":1,"category":"physical","power":36,"pp":11,"learn_level":38,"mode":"vine","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":221,"reference_key":"NEEDLE_ARM","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_226":{"name":"Fake Out","type":"normal","pattern":"line","reach":2,"category":"physical","power":8,"pp":12,"learn_level":24,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":226,"reference_key":"FAKE_OUT","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_228":{"name":"Pay Day","type":"normal","pattern":"front","reach":1,"category":"physical","power":8,"pp":16,"learn_level":24,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":228,"reference_key":"PAY_DAY","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_230":{"name":"Heat Wave","type":"fire","pattern":"room","reach":0,"category":"special","power":10,"pp":8,"learn_level":25,"mode":"flame","light":"#fff4a0","dark":"#e95237","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":230,"reference_key":"HEAT_WAVE","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true},"eos_234":{"name":"Confusion","type":"psychic","pattern":"front","reach":1,"category":"special","power":5,"pp":22,"learn_level":22,"mode":"beam","light":"#ffdcf8","dark":"#c063bc","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":234,"reference_key":"CONFUSION","acc1":100,"acc2":85,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_235":{"name":"Body Slam","type":"normal","pattern":"front","reach":1,"category":"physical","power":12,"pp":17,"learn_level":26,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":235,"reference_key":"BODY_SLAM","acc1":100,"acc2":85,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_238":{"name":"Frenzy Plant","type":"grass","pattern":"corner_front","reach":1,"category":"special","power":45,"pp":6,"learn_level":42,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":238,"reference_key":"FRENZY_PLANT","acc1":125,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_239":{"name":"Hydro Cannon","type":"water","pattern":"line","reach":10,"category":"special","power":33,"pp":6,"learn_level":36,"mode":"beam","light":"#dcffff","dark":"#329ed3","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":239,"reference_key":"HYDRO_CANNON","acc1":125,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_240":{"name":"Hydro Pump","type":"water","pattern":"line","reach":10,"category":"special","power":24,"pp":8,"learn_level":32,"mode":"bubble","light":"#dcffff","dark":"#329ed3","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":240,"reference_key":"HYDRO_PUMP","acc1":95,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_241":{"name":"Hyper Voice","type":"normal","pattern":"corner_front","reach":1,"category":"special","power":18,"pp":12,"learn_level":29,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":241,"reference_key":"HYPER_VOICE","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_242":{"name":"Hyper Beam","type":"normal","pattern":"line","reach":10,"category":"special","power":30,"pp":8,"learn_level":35,"mode":"beam","light":"#fff4d6","dark":"#c09d70","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":242,"reference_key":"HYPER_BEAM","acc1":95,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_243":{"name":"Superpower","type":"fighting","pattern":"front","reach":1,"category":"physical","power":24,"pp":11,"learn_level":32,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":243,"reference_key":"SUPERPOWER","acc1":125,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_244":{"name":"Steel Wing","type":"steel","pattern":"front","reach":1,"category":"physical","power":35,"pp":10,"learn_level":37,"mode":"slash","light":"#f0f9ff","dark":"#899eae","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":244,"reference_key":"STEEL_WING","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_245":{"name":"Spit Up","type":"normal","pattern":"front","reach":1,"category":"special","power":20,"pp":12,"learn_level":30,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":245,"reference_key":"SPIT_UP","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"reserve_attack":true},"eos_246":{"name":"Dynamicpunch","type":"fighting","pattern":"front","reach":1,"category":"physical","power":10,"pp":13,"learn_level":25,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":246,"reference_key":"DYNAMICPUNCH","acc1":100,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_248":{"name":"Vicegrip","type":"normal","pattern":"front","reach":1,"category":"physical","power":6,"pp":22,"learn_level":23,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":248,"reference_key":"VICEGRIP","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_250":{"name":"Pound","type":"normal","pattern":"front","reach":1,"category":"physical","power":6,"pp":27,"learn_level":23,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":250,"reference_key":"POUND","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_251":{"name":"Razor Leaf","type":"grass","pattern":"line","reach":10,"category":"physical","power":2,"pp":12,"learn_level":21,"mode":"vine","light":"#d2f49c","dark":"#428b4b","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":251,"reference_key":"RAZOR_LEAF","acc1":95,"acc2":84,"reference_crit":30,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_255":{"name":"Bubblebeam","type":"water","pattern":"line","reach":10,"category":"special","power":6,"pp":10,"learn_level":23,"mode":"bubble_beam","light":"#dcffff","dark":"#329ed3","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":255,"reference_key":"BUBBLEBEAM","acc1":95,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_260":{"name":"Scratch","type":"normal","pattern":"front","reach":1,"category":"physical","power":6,"pp":28,"learn_level":23,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":260,"reference_key":"SCRATCH","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_261":{"name":"Hyper Fang","type":"normal","pattern":"front","reach":1,"category":"physical","power":16,"pp":13,"learn_level":28,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":261,"reference_key":"HYPER_FANG","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_262":{"name":"Ember","type":"fire","pattern":"corner_front","reach":1,"category":"special","power":7,"pp":15,"learn_level":23,"mode":"flame","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":262,"reference_key":"EMBER","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_263":{"name":"Secret Power","type":"normal","pattern":"front","reach":1,"category":"physical","power":14,"pp":10,"learn_level":27,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":263,"reference_key":"SECRET_POWER","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_264":{"name":"Dizzy Punch","type":"normal","pattern":"front","reach":1,"category":"physical","power":6,"pp":17,"learn_level":23,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":264,"reference_key":"DIZZY_PUNCH","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_270":{"name":"Blizzard","type":"ice","pattern":"room","reach":0,"category":"special","power":24,"pp":7,"learn_level":32,"mode":"beam","light":"#efffff","dark":"#70bde3","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":270,"reference_key":"BLIZZARD","acc1":80,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true,"inflict_status":"freeze","status_chance":10},"eos_271":{"name":"Stomp","type":"normal","pattern":"front","reach":1,"category":"physical","power":12,"pp":17,"learn_level":26,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":271,"reference_key":"STOMP","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_272":{"name":"Blast Burn","type":"fire","pattern":"radius","reach":1,"category":"special","power":30,"pp":6,"learn_level":35,"mode":"flame","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":272,"reference_key":"BLAST_BURN","acc1":125,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true},"eos_275":{"name":"Crush Claw","type":"normal","pattern":"front","reach":1,"category":"physical","power":14,"pp":15,"learn_level":27,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":275,"reference_key":"CRUSH_CLAW","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_276":{"name":"Blaze Kick","type":"fire","pattern":"front","reach":1,"category":"physical","power":16,"pp":13,"learn_level":28,"mode":"slash","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":276,"reference_key":"BLAZE_KICK","acc1":100,"acc2":88,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_278":{"name":"Eruption","type":"fire","pattern":"corner_front","reach":1,"category":"special","power":40,"pp":6,"learn_level":40,"mode":"flame","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":278,"reference_key":"ERUPTION","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_279":{"name":"Sludge","type":"poison","pattern":"corner_front","reach":1,"category":"special","power":12,"pp":15,"learn_level":26,"mode":"cloud","light":"#f5c1ff","dark":"#9a49ad","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":279,"reference_key":"SLUDGE","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_280":{"name":"Sludge Bomb","type":"poison","pattern":"line","reach":10,"category":"special","power":18,"pp":10,"learn_level":29,"mode":"cloud","light":"#f5c1ff","dark":"#9a49ad","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":280,"reference_key":"SLUDGE_BOMB","acc1":95,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_283":{"name":"Poison Tail","type":"poison","pattern":"front","reach":1,"category":"physical","power":10,"pp":15,"learn_level":25,"mode":"dart","light":"#f5c1ff","dark":"#9a49ad","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":283,"reference_key":"POISON_TAIL","acc1":100,"acc2":88,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_287":{"name":"Covet","type":"normal","pattern":"front","reach":1,"category":"physical","power":8,"pp":27,"learn_level":24,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":287,"reference_key":"COVET","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_289":{"name":"Bone Club","type":"ground","pattern":"front","reach":1,"category":"physical","power":12,"pp":15,"learn_level":26,"mode":"quake","light":"#f4cd8c","dark":"#9a623f","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":289,"reference_key":"BONE_CLUB","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_291":{"name":"Fire Spin","type":"fire","pattern":"front","reach":1,"category":"special","power":4,"pp":19,"learn_level":22,"mode":"flame","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":291,"reference_key":"FIRE_SPIN","acc1":100,"acc2":73,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_292":{"name":"Fire Punch","type":"fire","pattern":"front","reach":1,"category":"physical","power":14,"pp":13,"learn_level":27,"mode":"slash","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":292,"reference_key":"FIRE_PUNCH","acc1":100,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_297":{"name":"Magical Leaf","type":"grass","pattern":"corner_front","reach":1,"category":"special","power":12,"pp":8,"learn_level":26,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":297,"reference_key":"MAGICAL_LEAF","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_299":{"name":"Mud Shot","type":"ground","pattern":"corner_front","reach":1,"category":"special","power":12,"pp":13,"learn_level":26,"mode":"dart","light":"#f4cd8c","dark":"#9a623f","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":299,"reference_key":"MUD_SHOT","acc1":100,"acc2":65,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_300":{"name":"Mach Punch","type":"fighting","pattern":"line","reach":2,"category":"physical","power":8,"pp":22,"learn_level":24,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":300,"reference_key":"MACH_PUNCH","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_303":{"name":"Rolling Kick","type":"fighting","pattern":"front","reach":1,"category":"physical","power":12,"pp":13,"learn_level":26,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":303,"reference_key":"ROLLING_KICK","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_308":{"name":"Water Gun","type":"water","pattern":"corner_front","reach":1,"category":"special","power":5,"pp":17,"learn_level":22,"mode":"bubble","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":308,"reference_key":"WATER_GUN","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_309":{"name":"Mist Ball","type":"psychic","pattern":"corner_front","reach":1,"category":"special","power":14,"pp":10,"learn_level":27,"mode":"beam","light":"#ffdcf8","dark":"#c063bc","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":309,"reference_key":"MIST_BALL","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_310":{"name":"Water Pulse","type":"water","pattern":"line","reach":10,"category":"special","power":12,"pp":12,"learn_level":26,"mode":"beam","light":"#dcffff","dark":"#329ed3","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":310,"reference_key":"WATER_PULSE","acc1":95,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_314":{"name":"False Swipe","type":"normal","pattern":"front","reach":1,"category":"physical","power":40,"pp":15,"learn_level":40,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":314,"reference_key":"FALSE_SWIPE","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_320":{"name":"Mega Drain","type":"grass","pattern":"front","reach":1,"category":"special","power":8,"pp":17,"learn_level":24,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":320,"reference_key":"MEGA_DRAIN","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"drain_fraction":0.5},"eos_321":{"name":"Mega Kick","type":"normal","pattern":"front","reach":1,"category":"physical","power":16,"pp":12,"learn_level":28,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":321,"reference_key":"MEGA_KICK","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_322":{"name":"Mega Punch","type":"normal","pattern":"front","reach":1,"category":"physical","power":16,"pp":12,"learn_level":28,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":322,"reference_key":"MEGA_PUNCH","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_323":{"name":"Megahorn","type":"bug","pattern":"corner_front","reach":1,"category":"physical","power":38,"pp":7,"learn_level":39,"mode":"slash","light":"#ebf5af","dark":"#7e9c36","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":323,"reference_key":"MEGAHORN","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_325":{"name":"Metal Claw","type":"steel","pattern":"front","reach":1,"category":"physical","power":10,"pp":15,"learn_level":25,"mode":"slash","light":"#f0f9ff","dark":"#899eae","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":325,"reference_key":"METAL_CLAW","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_331":{"name":"Dream Eater","type":"psychic","pattern":"front","reach":1,"category":"special","power":20,"pp":13,"learn_level":30,"mode":"beam","light":"#ffdcf8","dark":"#c063bc","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":331,"reference_key":"DREAM_EATER","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_332":{"name":"Acid","type":"poison","pattern":"corner_front","reach":1,"category":"special","power":8,"pp":17,"learn_level":24,"mode":"cloud","light":"#f5c1ff","dark":"#9a49ad","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":332,"reference_key":"ACID","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_335":{"name":"Luster Purge","type":"psychic","pattern":"front","reach":1,"category":"special","power":14,"pp":12,"learn_level":27,"mode":"beam","light":"#ffdcf8","dark":"#c063bc","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":335,"reference_key":"LUSTER_PURGE","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_336":{"name":"Leaf Blade","type":"grass","pattern":"front","reach":1,"category":"physical","power":14,"pp":12,"learn_level":27,"mode":"vine","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":336,"reference_key":"LEAF_BLADE","acc1":100,"acc2":88,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_342":{"name":"Dragonbreath","type":"dragon","pattern":"line","reach":10,"category":"special","power":12,"pp":12,"learn_level":26,"mode":"fire_stream","light":"#f6ceff","dark":"#7359d2","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":342,"reference_key":"DRAGONBREATH","acc1":95,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_344":{"name":"Ice Punch","type":"ice","pattern":"front","reach":1,"category":"physical","power":14,"pp":12,"learn_level":27,"mode":"slash","light":"#efffff","dark":"#70bde3","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":344,"reference_key":"ICE_PUNCH","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_345":{"name":"Ice Beam","type":"ice","pattern":"line","reach":10,"category":"special","power":15,"pp":8,"learn_level":27,"mode":"beam","light":"#efffff","dark":"#70bde3","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":345,"reference_key":"ICE_BEAM","acc1":95,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true,"inflict_status":"freeze","status_chance":10},"eos_348":{"name":"Armored Charge","type":"normal","pattern":"front","reach":1,"category":"physical","power":10,"pp":15,"learn_level":25,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":348,"reference_key":"SKULL_BASH","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"charge_phase":"gather","release_multiplier":2,"charge_defense":true},"eos_352":{"name":"Struggle","type":"normal","pattern":"front","reach":1,"category":"physical","power":30,"pp":1,"learn_level":35,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":352,"reference_key":"STRUGGLE","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_353":{"name":"Aeroblast","type":"flying","pattern":"line","reach":10,"category":"special","power":20,"pp":12,"learn_level":30,"mode":"fan","light":"#e6faff","dark":"#9aaceb","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":353,"reference_key":"AEROBLAST","acc1":95,"acc2":84,"reference_crit":30,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_354":{"name":"Volt Tackle","type":"electric","pattern":"line","reach":2,"category":"physical","power":24,"pp":8,"learn_level":32,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":354,"reference_key":"VOLT_TACKLE","acc1":125,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true,"recoil_fraction":0.125},"eos_430":{"name":"Hammer Arm","type":"fighting","pattern":"front","reach":1,"category":"physical","power":18,"pp":16,"learn_level":29,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":430,"reference_key":"HAMMER_ARM","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_431":{"name":"Iron Head","type":"steel","pattern":"front","reach":1,"category":"physical","power":16,"pp":12,"learn_level":28,"mode":"slash","light":"#f0f9ff","dark":"#899eae","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":431,"reference_key":"IRON_HEAD","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_432":{"name":"Aqua Jet","type":"water","pattern":"line","reach":2,"category":"physical","power":4,"pp":18,"learn_level":22,"mode":"slash","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":432,"reference_key":"AQUA_JET","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_433":{"name":"Aqua Tail","type":"water","pattern":"corner_front","reach":1,"category":"physical","power":16,"pp":11,"learn_level":28,"mode":"slash","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":433,"reference_key":"AQUA_TAIL","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_435":{"name":"Spacial Rend","type":"dragon","pattern":"room","reach":0,"category":"special","power":15,"pp":5,"learn_level":27,"mode":"fire_stream","light":"#f6ceff","dark":"#7359d2","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":435,"reference_key":"SPACIAL_REND","acc1":100,"acc2":80,"reference_crit":30,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true},"eos_436":{"name":"Dark Pulse","type":"dark","pattern":"radius","reach":1,"category":"special","power":16,"pp":10,"learn_level":28,"mode":"beam","light":"#dfc3f8","dark":"#67457a","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":436,"reference_key":"DARK_PULSE","acc1":88,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true},"eos_437":{"name":"Ominous Wind","type":"ghost","pattern":"room","reach":0,"category":"special","power":6,"pp":8,"learn_level":23,"mode":"cloud","light":"#e5d9ff","dark":"#8662c9","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":437,"reference_key":"OMINOUS_WIND","acc1":88,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true},"eos_440":{"name":"Close Combat","type":"fighting","pattern":"front","reach":1,"category":"physical","power":43,"pp":7,"learn_level":41,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":440,"reference_key":"CLOSE_COMBAT","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_441":{"name":"Wood Hammer","type":"grass","pattern":"corner_front","reach":1,"category":"physical","power":36,"pp":10,"learn_level":38,"mode":"vine","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":441,"reference_key":"WOOD_HAMMER","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"recoil_fraction":0.125},"eos_442":{"name":"Air Slash","type":"flying","pattern":"front","reach":1,"category":"special","power":15,"pp":15,"learn_level":27,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":442,"reference_key":"AIR_SLASH","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_443":{"name":"Energy Ball","type":"grass","pattern":"line","reach":10,"category":"special","power":16,"pp":11,"learn_level":28,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":443,"reference_key":"ENERGY_BALL","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_445":{"name":"Punishment","type":"dark","pattern":"front","reach":1,"category":"physical","power":1,"pp":8,"learn_level":20,"mode":"slash","light":"#dfc3f8","dark":"#67457a","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":445,"reference_key":"PUNISHMENT","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_446":{"name":"Chatter","type":"flying","pattern":"radius","reach":1,"category":"special","power":10,"pp":12,"learn_level":25,"mode":"fan","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":446,"reference_key":"CHATTER","acc1":88,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true},"eos_451":{"name":"Shadow Sneak","type":"ghost","pattern":"line","reach":2,"category":"physical","power":4,"pp":16,"learn_level":22,"mode":"slash","light":"#e5d9ff","dark":"#8662c9","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":451,"reference_key":"SHADOW_SNEAK","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_452":{"name":"Thunder Fang","type":"electric","pattern":"front","reach":1,"category":"physical","power":12,"pp":15,"learn_level":26,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":452,"reference_key":"THUNDER_FANG","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_453":{"name":"Rock Wrecker","type":"rock","pattern":"line","reach":10,"category":"physical","power":28,"pp":7,"learn_level":34,"mode":"roll","light":"#f0dec2","dark":"#a38966","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":453,"reference_key":"ROCK_WRECKER","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_454":{"name":"Focus Blast","type":"fighting","pattern":"line","reach":10,"category":"special","power":25,"pp":6,"learn_level":32,"mode":"leap","light":"#ffdfbb","dark":"#d97742","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":454,"reference_key":"FOCUS_BLAST","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_455":{"name":"Giga Impact","type":"normal","pattern":"front","reach":1,"category":"physical","power":60,"pp":4,"learn_level":50,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":455,"reference_key":"GIGA_IMPACT","acc1":125,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_458":{"name":"Grass Knot","type":"grass","pattern":"front","reach":1,"category":"special","power":1,"pp":20,"learn_level":20,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":458,"reference_key":"GRASS_KNOT","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_459":{"name":"Cross Poison","type":"poison","pattern":"front","reach":1,"category":"physical","power":15,"pp":12,"learn_level":27,"mode":"dart","light":"#f5c1ff","dark":"#9a49ad","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":459,"reference_key":"CROSS_POISON","acc1":100,"acc2":88,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_460":{"name":"Attack Order","type":"bug","pattern":"room","reach":0,"category":"physical","power":11,"pp":10,"learn_level":25,"mode":"slash","light":"#ebf5af","dark":"#7e9c36","duration":0.72,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":460,"reference_key":"ATTACK_ORDER","acc1":100,"acc2":80,"reference_crit":30,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true},"eos_461":{"name":"Ice Fang","type":"ice","pattern":"front","reach":1,"category":"physical","power":10,"pp":15,"learn_level":25,"mode":"slash","light":"#efffff","dark":"#70bde3","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":461,"reference_key":"ICE_FANG","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_462":{"name":"Ice Shard","type":"ice","pattern":"line","reach":2,"category":"physical","power":4,"pp":16,"learn_level":22,"mode":"shards","light":"#efffff","dark":"#70bde3","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":462,"reference_key":"ICE_SHARD","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_463":{"name":"Psycho Cut","type":"psychic","pattern":"corner_front","reach":1,"category":"physical","power":10,"pp":14,"learn_level":25,"mode":"slash","light":"#ffdcf8","dark":"#c063bc","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":463,"reference_key":"PSYCHO_CUT","acc1":100,"acc2":88,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_468":{"name":"Seed Flare","type":"grass","pattern":"radius","reach":1,"category":"special","power":44,"pp":5,"learn_level":42,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":468,"reference_key":"SEED_FLARE","acc1":88,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true},"eos_469":{"name":"Brine","type":"water","pattern":"front","reach":1,"category":"special","power":8,"pp":8,"learn_level":24,"mode":"bubble","light":"#dcffff","dark":"#329ed3","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":469,"reference_key":"BRINE","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_470":{"name":"X Scissor","type":"bug","pattern":"front","reach":1,"category":"physical","power":40,"pp":10,"learn_level":40,"mode":"slash","light":"#ebf5af","dark":"#7e9c36","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":470,"reference_key":"X_SCISSOR","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_471":{"name":"Natural Gift","type":"normal","pattern":"front","reach":1,"category":"physical","power":1,"pp":17,"learn_level":20,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":471,"reference_key":"NATURAL_GIFT","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_473":{"name":"Zen Headbutt","type":"psychic","pattern":"front","reach":1,"category":"physical","power":15,"pp":9,"learn_level":27,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":473,"reference_key":"ZEN_HEADBUTT","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_474":{"name":"Wring Out","type":"normal","pattern":"front","reach":1,"category":"special","power":1,"pp":10,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":474,"reference_key":"WRING_OUT","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_475":{"name":"Gyro Ball","type":"steel","pattern":"front","reach":1,"category":"physical","power":1,"pp":12,"learn_level":20,"mode":"slash","light":"#f0f9ff","dark":"#899eae","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":475,"reference_key":"GYRO_BALL","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_476":{"name":"Shadow Claw","type":"ghost","pattern":"front","reach":1,"category":"physical","power":13,"pp":10,"learn_level":26,"mode":"slash","light":"#e5d9ff","dark":"#8662c9","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":476,"reference_key":"SHADOW_CLAW","acc1":100,"acc2":88,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_477":{"name":"Shade Rift","type":"ghost","pattern":"front","reach":1,"category":"physical","power":50,"pp":6,"learn_level":45,"mode":"slash","light":"#e5d9ff","dark":"#8662c9","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":477,"reference_key":"SHADOW_FORCE","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"charge_phase":"vanish","release_multiplier":2,"pierce_guard":true},"eos_479":{"name":"Vacuum Wave","type":"fighting","pattern":"line","reach":2,"category":"special","power":11,"pp":14,"learn_level":25,"mode":"leap","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":479,"reference_key":"VACUUM_WAVE","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_481":{"name":"Stone Edge","type":"rock","pattern":"front","reach":1,"category":"physical","power":38,"pp":7,"learn_level":39,"mode":"roll","light":"#f0dec2","dark":"#a38966","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":481,"reference_key":"STONE_EDGE","acc1":100,"acc2":80,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_484":{"name":"Earth Power","type":"ground","pattern":"room","reach":0,"category":"special","power":9,"pp":8,"learn_level":24,"mode":"dart","light":"#f4cd8c","dark":"#9a623f","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":484,"reference_key":"EARTH_POWER","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true},"eos_485":{"name":"Gunk Shot","type":"poison","pattern":"line","reach":10,"category":"physical","power":22,"pp":6,"learn_level":31,"mode":"dart","light":"#f5c1ff","dark":"#9a49ad","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":485,"reference_key":"GUNK_SHOT","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_486":{"name":"Seed Bomb","type":"grass","pattern":"corner_front","reach":1,"category":"physical","power":16,"pp":11,"learn_level":28,"mode":"vine","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":486,"reference_key":"SEED_BOMB","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_488":{"name":"Assurance","type":"dark","pattern":"front","reach":1,"category":"physical","power":9,"pp":12,"learn_level":24,"mode":"slash","light":"#dfc3f8","dark":"#67457a","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":488,"reference_key":"ASSURANCE","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_489":{"name":"Charge Beam","type":"electric","pattern":"corner_front","reach":1,"category":"special","power":9,"pp":12,"learn_level":24,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":489,"reference_key":"CHARGE_BEAM","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_490":{"name":"Pluck","type":"flying","pattern":"front","reach":1,"category":"physical","power":10,"pp":15,"learn_level":25,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":490,"reference_key":"PLUCK","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_491":{"name":"Night Slash","type":"dark","pattern":"front","reach":1,"category":"physical","power":13,"pp":12,"learn_level":26,"mode":"slash","light":"#dfc3f8","dark":"#67457a","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":491,"reference_key":"NIGHT_SLASH","acc1":100,"acc2":88,"reference_crit":30,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_494":{"name":"Roar Of Time","type":"dragon","pattern":"room","reach":0,"category":"special","power":24,"pp":4,"learn_level":32,"mode":"fire_stream","light":"#f6ceff","dark":"#7359d2","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":494,"reference_key":"ROAR_OF_TIME","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true},"eos_495":{"name":"Poison Jab","type":"poison","pattern":"front","reach":1,"category":"physical","power":14,"pp":14,"learn_level":27,"mode":"dart","light":"#f5c1ff","dark":"#9a49ad","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":495,"reference_key":"POISON_JAB","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_497":{"name":"Last Resort","type":"normal","pattern":"front","reach":1,"category":"physical","power":30,"pp":7,"learn_level":35,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":497,"reference_key":"LAST_RESORT","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_498":{"name":"Dragon Rush","type":"dragon","pattern":"front","reach":1,"category":"physical","power":40,"pp":8,"learn_level":40,"mode":"slash","light":"#f6ceff","dark":"#7359d2","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":498,"reference_key":"DRAGON_RUSH","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_500":{"name":"Drain Punch","type":"fighting","pattern":"corner_front","reach":1,"category":"physical","power":13,"pp":8,"learn_level":26,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.72,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":500,"reference_key":"DRAIN_PUNCH","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"drain_fraction":0.5},"eos_501":{"name":"Mud Bomb","type":"ground","pattern":"corner_front","reach":1,"category":"special","power":12,"pp":10,"learn_level":26,"mode":"dart","light":"#f4cd8c","dark":"#9a623f","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":501,"reference_key":"MUD_BOMB","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_502":{"name":"U Turn","type":"bug","pattern":"line","reach":2,"category":"physical","power":14,"pp":12,"learn_level":27,"mode":"slash","light":"#ebf5af","dark":"#7e9c36","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":502,"reference_key":"U_TURN","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_505":{"name":"Crush Grip","type":"normal","pattern":"front","reach":1,"category":"physical","power":15,"pp":6,"learn_level":27,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":505,"reference_key":"CRUSH_GRIP","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_507":{"name":"Force Palm","type":"fighting","pattern":"front","reach":1,"category":"physical","power":12,"pp":12,"learn_level":26,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":507,"reference_key":"FORCE_PALM","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_508":{"name":"Aura Sphere","type":"fighting","pattern":"line","reach":10,"category":"special","power":16,"pp":10,"learn_level":28,"mode":"leap","light":"#ffdfbb","dark":"#d97742","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":508,"reference_key":"AURA_SPHERE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_510":{"name":"Bullet Punch","type":"steel","pattern":"line","reach":2,"category":"physical","power":4,"pp":16,"learn_level":22,"mode":"slash","light":"#f0f9ff","dark":"#899eae","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":510,"reference_key":"BULLET_PUNCH","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_511":{"name":"Power Whip","type":"grass","pattern":"front","reach":1,"category":"physical","power":42,"pp":8,"learn_level":41,"mode":"vine","light":"#d2f49c","dark":"#428b4b","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":511,"reference_key":"POWER_WHIP","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_512":{"name":"Power Gem","type":"rock","pattern":"corner_front","reach":1,"category":"special","power":12,"pp":15,"learn_level":26,"mode":"shards","light":"#f0dec2","dark":"#a38966","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":512,"reference_key":"POWER_GEM","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_515":{"name":"Sucker Punch","type":"dark","pattern":"line","reach":2,"category":"physical","power":15,"pp":7,"learn_level":27,"mode":"slash","light":"#dfc3f8","dark":"#67457a","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":515,"reference_key":"SUCKER_PUNCH","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy up to 2 tiles away","prototype":true},"eos_516":{"name":"Feint","type":"normal","pattern":"front","reach":1,"category":"physical","power":5,"pp":12,"learn_level":22,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":516,"reference_key":"FEINT","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_517":{"name":"Flare Blitz","type":"fire","pattern":"front","reach":1,"category":"physical","power":32,"pp":6,"learn_level":36,"mode":"leap","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":517,"reference_key":"FLARE_BLITZ","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_518":{"name":"Brave Bird","type":"flying","pattern":"corner_front","reach":1,"category":"physical","power":42,"pp":6,"learn_level":41,"mode":"slash","light":"#e6faff","dark":"#9aaceb","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":518,"reference_key":"BRAVE_BIRD","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"recoil_fraction":0.125},"eos_519":{"name":"Lava Plume","type":"fire","pattern":"radius","reach":1,"category":"special","power":15,"pp":10,"learn_level":27,"mode":"flame","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":519,"reference_key":"LAVA_PLUME","acc1":88,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true},"eos_521":{"name":"Discharge","type":"electric","pattern":"room","reach":0,"category":"special","power":9,"pp":8,"learn_level":24,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":521,"reference_key":"DISCHARGE","acc1":100,"acc2":70,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true},"eos_522":{"name":"Fire Fang","type":"fire","pattern":"front","reach":1,"category":"physical","power":12,"pp":13,"learn_level":26,"mode":"slash","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":522,"reference_key":"FIRE_FANG","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_523":{"name":"Magnet Bomb","type":"steel","pattern":"front","reach":1,"category":"physical","power":12,"pp":10,"learn_level":26,"mode":"slash","light":"#f0f9ff","dark":"#899eae","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":523,"reference_key":"MAGNET_BOMB","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_524":{"name":"Magma Storm","type":"fire","pattern":"front","reach":1,"category":"special","power":55,"pp":5,"learn_level":47,"mode":"flame","light":"#fff4a0","dark":"#e95237","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":524,"reference_key":"MAGMA_STORM","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_527":{"name":"Mirror Shot","type":"steel","pattern":"corner_front","reach":1,"category":"special","power":12,"pp":10,"learn_level":26,"mode":"shards","light":"#f0f9ff","dark":"#899eae","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":527,"reference_key":"MIRROR_SHOT","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_529":{"name":"Bug Bite","type":"bug","pattern":"front","reach":1,"category":"physical","power":11,"pp":12,"learn_level":25,"mode":"slash","light":"#ebf5af","dark":"#7e9c36","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":529,"reference_key":"BUG_BITE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_530":{"name":"Bug Buzz","type":"bug","pattern":"radius","reach":1,"category":"special","power":16,"pp":10,"learn_level":28,"mode":"silk","light":"#ebf5af","dark":"#7e9c36","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":530,"reference_key":"BUG_BUZZ","acc1":88,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true},"eos_531":{"name":"Wake Up Slap","type":"fighting","pattern":"front","reach":1,"category":"physical","power":12,"pp":10,"learn_level":26,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":531,"reference_key":"WAKE_UP_SLAP","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_533":{"name":"Head Smash","type":"rock","pattern":"front","reach":1,"category":"physical","power":50,"pp":5,"learn_level":45,"mode":"roll","light":"#f0dec2","dark":"#a38966","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":533,"reference_key":"HEAD_SMASH","acc1":125,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"recoil_fraction":0.25},"eos_536":{"name":"Flash Cannon","type":"steel","pattern":"corner_front","reach":1,"category":"special","power":15,"pp":11,"learn_level":27,"mode":"beam","light":"#f0f9ff","dark":"#899eae","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":536,"reference_key":"FLASH_CANNON","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_537":{"name":"Leaf Storm","type":"grass","pattern":"line","reach":10,"category":"special","power":27,"pp":5,"learn_level":33,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":537,"reference_key":"LEAF_STORM","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true},"eos_538":{"name":"Draco Meteor","type":"dragon","pattern":"room","reach":0,"category":"special","power":14,"pp":5,"learn_level":27,"mode":"fire_stream","light":"#f6ceff","dark":"#7359d2","duration":0.72,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":538,"reference_key":"DRACO_METEOR","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true},"eos_539":{"name":"Dragon Pulse","type":"dragon","pattern":"corner_front","reach":1,"category":"special","power":18,"pp":10,"learn_level":29,"mode":"beam","light":"#f6ceff","dark":"#7359d2","duration":0.42,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":539,"reference_key":"DRAGON_PULSE","acc1":100,"acc2":80,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true},"eos_541":{"name":"Rock Climb","type":"normal","pattern":"front","reach":1,"category":"physical","power":12,"pp":14,"learn_level":26,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.42,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":541,"reference_key":"ROCK_CLIMB","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true},"eos_039":{"name":"Palm Flurry","type":"normal","pattern":"front","reach":1,"category":"physical","power":4,"pp":10,"learn_level":22,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":39,"reference_key":"DOUBLESLAP","acc1":75,"acc2":55,"reference_crit":2,"reference_strikes":0,"reference_range":"Enemy in front","prototype":true,"hit_min":2,"hit_max":5},"eos_163":{"name":"Seed Volley","type":"grass","pattern":"line","reach":10,"category":"physical","power":10,"pp":10,"learn_level":25,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":163,"reference_key":"BULLET_SEED","acc1":80,"acc2":60,"reference_crit":2,"reference_strikes":0,"reference_range":"Line of sight","prototype":true,"hit_min":2,"hit_max":5},"eos_164":{"name":"Twin Needles","type":"bug","pattern":"line","reach":10,"category":"physical","power":6,"pp":10,"learn_level":23,"mode":"dart","light":"#ebf5af","dark":"#7e9c36","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":164,"reference_key":"TWINEEDLE","acc1":85,"acc2":55,"reference_crit":2,"reference_strikes":2,"reference_range":"Line of sight","prototype":true,"hit_min":2,"hit_max":2},"eos_168":{"name":"Pebble Barrage","type":"normal","pattern":"corner_front","reach":1,"category":"physical","power":1,"pp":12,"learn_level":20,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":168,"reference_key":"BARRAGE","acc1":80,"acc2":55,"reference_crit":2,"reference_strikes":0,"reference_range":"Enemy in front, cuts corners","prototype":true,"hit_min":2,"hit_max":5},"eos_175":{"name":"Rapid Palms","type":"fighting","pattern":"front","reach":1,"category":"physical","power":2,"pp":10,"learn_level":21,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":175,"reference_key":"ARM_THRUST","acc1":80,"acc2":50,"reference_crit":2,"reference_strikes":0,"reference_range":"Enemy in front","prototype":true,"hit_min":2,"hit_max":5},"eos_180":{"name":"Icicle Volley","type":"ice","pattern":"corner_front","reach":1,"category":"physical","power":2,"pp":8,"learn_level":21,"mode":"shards","light":"#efffff","dark":"#70bde3","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":180,"reference_key":"ICICLE_SPEAR","acc1":75,"acc2":45,"reference_crit":2,"reference_strikes":0,"reference_range":"Enemy in front, cuts corners","prototype":true,"hit_min":2,"hit_max":5},"eos_201":{"name":"Spike Volley","type":"normal","pattern":"line","reach":10,"category":"physical","power":3,"pp":10,"learn_level":21,"mode":"dart","light":"#fff4d6","dark":"#c09d70","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":201,"reference_key":"SPIKE_CANNON","acc1":80,"acc2":55,"reference_crit":2,"reference_strikes":0,"reference_range":"Line of sight","prototype":true,"hit_min":2,"hit_max":5},"eos_222":{"name":"Twin Kick","type":"fighting","pattern":"front","reach":1,"category":"physical","power":6,"pp":14,"learn_level":23,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":222,"reference_key":"DOUBLE_KICK","acc1":88,"acc2":87,"reference_crit":3,"reference_strikes":2,"reference_range":"Enemy in front","prototype":true,"hit_min":2,"hit_max":2},"eos_285":{"name":"Bone Flurry","type":"ground","pattern":"corner_front","reach":1,"category":"physical","power":12,"pp":8,"learn_level":26,"mode":"slash","light":"#f4cd8c","dark":"#9a623f","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":285,"reference_key":"BONE_RUSH","acc1":75,"acc2":50,"reference_crit":2,"reference_strikes":0,"reference_range":"Enemy in front, cuts corners","prototype":true,"hit_min":2,"hit_max":5},"eos_290":{"name":"Returning Bone","type":"ground","pattern":"line","reach":10,"category":"physical","power":10,"pp":14,"learn_level":25,"mode":"dart","light":"#f4cd8c","dark":"#9a623f","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":290,"reference_key":"BONEMERANG","acc1":88,"acc2":75,"reference_crit":8,"reference_strikes":2,"reference_range":"Line of sight","prototype":true,"hit_min":2,"hit_max":2},"eos_306":{"name":"Pin Volley","type":"bug","pattern":"line","reach":10,"category":"physical","power":4,"pp":10,"learn_level":22,"mode":"dart","light":"#ebf5af","dark":"#7e9c36","duration":0.6,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":306,"reference_key":"PIN_MISSILE","acc1":75,"acc2":60,"reference_crit":1,"reference_strikes":0,"reference_range":"Line of sight","prototype":true,"hit_min":2,"hit_max":5},"eos_311":{"name":"Frenzy Thrust","type":"normal","pattern":"front","reach":1,"category":"physical","power":1,"pp":12,"learn_level":20,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":311,"reference_key":"FURY_ATTACK","acc1":80,"acc2":55,"reference_crit":1,"reference_strikes":0,"reference_range":"Enemy in front","prototype":true,"hit_min":2,"hit_max":5},"eos_312":{"name":"Raking Flurry","type":"normal","pattern":"front","reach":1,"category":"physical","power":5,"pp":10,"learn_level":22,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":312,"reference_key":"FURY_SWIPES","acc1":75,"acc2":55,"reference_crit":1,"reference_strikes":0,"reference_range":"Enemy in front","prototype":true,"hit_min":2,"hit_max":5},"eos_347":{"name":"Comet Flurry","type":"normal","pattern":"front","reach":1,"category":"physical","power":3,"pp":10,"learn_level":21,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":347,"reference_key":"COMET_PUNCH","acc1":75,"acc2":60,"reference_crit":1,"reference_strikes":0,"reference_range":"Enemy in front","prototype":true,"hit_min":2,"hit_max":5},"eos_350":{"name":"Stone Volley","type":"rock","pattern":"corner_front","reach":1,"category":"physical","power":4,"pp":10,"learn_level":22,"mode":"shards","light":"#f0dec2","dark":"#a38966","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":350,"reference_key":"ROCK_BLAST","acc1":75,"acc2":60,"reference_crit":1,"reference_strikes":0,"reference_range":"Enemy in front, cuts corners","prototype":true,"hit_min":2,"hit_max":5},"eos_487":{"name":"Twin Strike","type":"normal","pattern":"front","reach":1,"category":"physical","power":3,"pp":13,"learn_level":21,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.6,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":487,"reference_key":"DOUBLE_HIT","acc1":88,"acc2":80,"reference_crit":8,"reference_strikes":2,"reference_range":"Enemy in front","prototype":true,"hit_min":2,"hit_max":2},"eos_117":{"name":"Renewal","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#d9fff0","dark":"#38b98d","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":117,"reference_key":"RECOVER","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"heal_fraction":0.5},"eos_218":{"name":"Quiet Recovery","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#d9fff0","dark":"#38b98d","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":218,"reference_key":"SLACK_OFF","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"heal_fraction":0.5},"eos_002":{"name":"Frost Tumble","type":"ice","pattern":"corner_front","reach":1,"category":"physical","power":1,"pp":15,"learn_level":20,"mode":"roll","light":"#efffff","dark":"#70bde3","duration":0.7,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":2,"reference_key":"ICE_BALL","acc1":75,"acc2":60,"reference_crit":2,"reference_strikes":5,"reference_range":"Enemy in front, cuts corners","prototype":true,"hit_min":5,"hit_max":5,"hit_multipliers":[1,1.1,1.2,1.3,1.4],"stop_on_miss":true},"eos_105":{"name":"Boulder Tumble","type":"rock","pattern":"front","reach":1,"category":"physical","power":1,"pp":14,"learn_level":20,"mode":"roll","light":"#f0dec2","dark":"#a38966","duration":0.7,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":105,"reference_key":"ROLLOUT","acc1":75,"acc2":60,"reference_crit":8,"reference_strikes":5,"reference_range":"Enemy in front","prototype":true,"hit_min":5,"hit_max":5,"hit_multipliers":[1,1.1,1.2,1.3,1.4],"stop_on_miss":true},"eos_210":{"name":"Triple Talon","type":"fighting","pattern":"front","reach":1,"category":"physical","power":8,"pp":15,"learn_level":24,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.7,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":210,"reference_key":"TRIPLE_KICK","acc1":75,"acc2":70,"reference_crit":2,"reference_strikes":3,"reference_range":"Enemy in front","prototype":true,"hit_min":3,"hit_max":3,"hit_multipliers":[1,2,3],"stop_on_miss":true},"eos_003":{"name":"Drowsy Hex","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":3,"reference_key":"YAWN","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"yawn"},"eos_004":{"name":"Dream Charm","type":"normal","pattern":"radius","reach":1,"category":"status","power":0,"pp":11,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":4,"reference_key":"LOVELY_KISS","acc1":88,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true,"inflict_status":"sleep"},"eos_034":{"name":"Lullaby Note","type":"normal","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":34,"reference_key":"SING","acc1":87,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"inflict_status":"sleep"},"eos_079":{"name":"Slumber Spores","type":"grass","pattern":"room","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#d2f49c","dark":"#428b4b","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":79,"reference_key":"SPORE","acc1":88,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true,"inflict_status":"sleep"},"eos_111":{"name":"Dream Gaze","type":"psychic","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":111,"reference_key":"HYPNOSIS","acc1":88,"acc2":60,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"inflict_status":"sleep"},"eos_231":{"name":"Drowse Pollen","type":"grass","pattern":"radius","reach":1,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#d2f49c","dark":"#428b4b","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":231,"reference_key":"SLEEP_POWDER","acc1":80,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true,"inflict_status":"sleep"},"eos_483":{"name":"Night Veil","type":"dark","pattern":"room","reach":0,"category":"status","power":0,"pp":8,"learn_level":20,"mode":"wave","light":"#dfc3f8","dark":"#67457a","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":483,"reference_key":"DARK_VOID","acc1":88,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true,"inflict_status":"sleep"},"eos_013":{"name":"Mirage Ray","type":"ghost","pattern":"front","reach":1,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":13,"reference_key":"CONFUSE_RAY","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"confusion"},"eos_171":{"name":"Discord Pulse","type":"normal","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":10,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":171,"reference_key":"SUPERSONIC","acc1":100,"acc2":55,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"inflict_status":"confusion"},"eos_191":{"name":"Bewilder Charm","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":191,"reference_key":"SWEET_KISS","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"confusion"},"eos_124":{"name":"Numbing Pollen","type":"grass","pattern":"radius","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#d2f49c","dark":"#428b4b","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":124,"reference_key":"STUN_SPORE","acc1":88,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true,"inflict_status":"paralysis"},"eos_192":{"name":"Static Lock","type":"electric","pattern":"front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"lightning","light":"#fffbb0","dark":"#e7b22c","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":192,"reference_key":"THUNDER_WAVE","acc1":65,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"paralysis"},"eos_281":{"name":"Petrifying Gaze","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":281,"reference_key":"GLARE","acc1":100,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"paralysis"},"eos_047":{"name":"Cinder Curse","type":"fire","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"flame","light":"#fff4a0","dark":"#e95237","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":47,"reference_key":"WILL_O_WISP","acc1":100,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"inflict_status":"burn"},"eos_196":{"name":"Venom Mist","type":"poison","pattern":"front","reach":1,"category":"status","power":0,"pp":27,"learn_level":20,"mode":"cloud","light":"#f5c1ff","dark":"#9a49ad","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":196,"reference_key":"POISON_GAS","acc1":88,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"poison"},"eos_197":{"name":"Virulent Hex","type":"poison","pattern":"front","reach":1,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"cloud","light":"#f5c1ff","dark":"#9a49ad","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":197,"reference_key":"TOXIC","acc1":88,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"toxic"},"eos_199":{"name":"Venom Pollen","type":"poison","pattern":"front","reach":1,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"cloud","light":"#f5c1ff","dark":"#9a49ad","duration":0.65,"caster":"shoot","frame_count":12,"frame_size":48,"reference_id":199,"reference_key":"POISONPOWDER","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"poison"},"eos_010":{"name":"Scent Trace","type":"normal","pattern":"room","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":10,"reference_key":"SWEET_SCENT","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true,"stat_changes":{"evasion":-1},"stat_halves":{}},"eos_011":{"name":"Gentle Hex","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":11,"reference_key":"CHARM","acc1":75,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"stat_changes":{},"stat_halves":{"attack":1}},"eos_027":{"name":"Shatter Cry","type":"normal","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":27,"reference_key":"SCREECH","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"stat_changes":{},"stat_halves":{"defense":1}},"eos_033":{"name":"Sorrow Veil","type":"dark","pattern":"front","reach":1,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#dfc3f8","dark":"#67457a","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":33,"reference_key":"FAKE_TEARS","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"stat_changes":{"sp_defense":-2},"stat_halves":{}},"eos_055":{"name":"Hone Edge","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":55,"reference_key":"SHARPEN","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"attack":1},"stat_halves":{}},"eos_056":{"name":"Echo Image","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":56,"reference_key":"DOUBLE_TEAM","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"evasion":1},"stat_halves":{}},"eos_058":{"name":"Firm Shell","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":58,"reference_key":"HARDEN","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"defense":1},"stat_halves":{}},"eos_070":{"name":"Shell Retreat","type":"water","pattern":"self","reach":0,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#dcffff","dark":"#329ed3","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":70,"reference_key":"WITHDRAW","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"defense":1},"stat_halves":{}},"eos_083":{"name":"Resonant Metal","type":"steel","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#f0f9ff","dark":"#899eae","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":83,"reference_key":"METAL_SOUND","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"stat_changes":{"sp_defense":-2},"stat_halves":{}},"eos_085":{"name":"Distracting Touch","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":85,"reference_key":"TICKLE","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"stat_changes":{"attack":-1,"defense":-1},"stat_halves":{}},"eos_099":{"name":"Astral Ward","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":14,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":99,"reference_key":"COSMIC_POWER","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"defense":1,"sp_defense":1},"stat_halves":{}},"eos_122":{"name":"Tail Feint","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":122,"reference_key":"TAIL_WHIP","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"stat_changes":{"defense":-1},"stat_halves":{}},"eos_142":{"name":"Dust Flick","type":"ground","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":20,"learn_level":20,"mode":"wave","light":"#f4cd8c","dark":"#9a623f","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":142,"reference_key":"SAND_ATTACK","acc1":80,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"stat_changes":{"accuracy":-1},"stat_halves":{}},"eos_146":{"name":"Mind Distortion","type":"psychic","pattern":"front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":146,"reference_key":"KINESIS","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"stat_changes":{"accuracy":-1},"stat_halves":{}},"eos_148":{"name":"Bloom Focus","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":20,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":148,"reference_key":"GROWTH","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"sp_attack":1},"stat_halves":{}},"eos_169":{"name":"Tiny Form","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":27,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":169,"reference_key":"MINIMIZE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"evasion":1},"stat_halves":{}},"eos_181":{"name":"Blade Ritual","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":7,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":181,"reference_key":"SWORDS_DANCE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"attack":2},"stat_halves":{}},"eos_186":{"name":"Iron Shell","type":"steel","pattern":"self","reach":0,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#f0f9ff","dark":"#899eae","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":186,"reference_key":"IRON_DEFENSE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"defense":2},"stat_halves":{}},"eos_195":{"name":"Rally Howl","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":27,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":195,"reference_key":"HOWL","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"attack":1},"stat_halves":{}},"eos_202":{"name":"Acid Shell","type":"poison","pattern":"self","reach":0,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#f5c1ff","dark":"#9a49ad","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":202,"reference_key":"ACID_ARMOR","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"defense":2},"stat_halves":{}},"eos_215":{"name":"Blank Mind","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":215,"reference_key":"AMNESIA","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"sp_defense":2},"stat_halves":{}},"eos_217":{"name":"Dread Growl","type":"normal","pattern":"room","reach":0,"category":"status","power":0,"pp":20,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":217,"reference_key":"GROWL","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true,"stat_changes":{"attack":-1},"stat_halves":{}},"eos_224":{"name":"Intense Gaze","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":27,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":224,"reference_key":"LEER","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"stat_changes":{"defense":-1},"stat_halves":{}},"eos_258":{"name":"Mind Barrier","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":258,"reference_key":"BARRIER","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"defense":2},"stat_halves":{}},"eos_265":{"name":"Mighty Stance","type":"fighting","pattern":"self","reach":0,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#ffdfbb","dark":"#d97742","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":265,"reference_key":"BULK_UP","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"attack":1,"defense":1},"stat_halves":{}},"eos_273":{"name":"Dazzle","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":24,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":273,"reference_key":"FLASH","acc1":100,"acc2":84,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"stat_changes":{"accuracy":-1},"stat_halves":{}},"eos_288":{"name":"Glow Focus","type":"bug","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#ebf5af","dark":"#7e9c36","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":288,"reference_key":"TAIL_GLOW","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"sp_attack":2},"stat_halves":{}},"eos_302":{"name":"Curl Guard","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":302,"reference_key":"DEFENSE_CURL","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"defense":1},"stat_halves":{}},"eos_319":{"name":"Tranquil Focus","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":19,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":319,"reference_key":"CALM_MIND","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"sp_attack":1,"sp_defense":1},"stat_halves":{}},"eos_333":{"name":"Inner Focus","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":333,"reference_key":"MEDITATE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"attack":1},"stat_halves":{}},"eos_520":{"name":"Swarm Ward","type":"bug","pattern":"self","reach":0,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#ebf5af","dark":"#7e9c36","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":520,"reference_key":"DEFEND_ORDER","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"defense":1,"sp_defense":1},"stat_halves":{}},"eos_542":{"name":"Schemer's Focus","type":"dark","pattern":"self","reach":0,"category":"status","power":0,"pp":20,"learn_level":20,"mode":"wave","light":"#dfc3f8","dark":"#67457a","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":542,"reference_key":"NASTY_PLOT","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_changes":{"sp_attack":2},"stat_halves":{}},"eos_023":{"name":"Silk Drag","type":"bug","pattern":"line","reach":10,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#ebf5af","dark":"#7e9c36","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":23,"reference_key":"STRING_SHOT","acc1":75,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true,"speed_change":-1,"stat_changes":{},"stat_halves":{}},"eos_095":{"name":"Fleet Mind","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"spiral","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":95,"reference_key":"AGILITY","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"speed_change":1,"stat_changes":{},"stat_halves":{}},"eos_106":{"name":"Dread Glance","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":14,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":106,"reference_key":"SCARY_FACE","acc1":70,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"speed_change":-1,"stat_changes":{},"stat_halves":{}},"eos_343":{"name":"Drake Rhythm","type":"dragon","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"spiral","light":"#f6ceff","dark":"#7359d2","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":343,"reference_key":"DRAGON_DANCE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"speed_change":1,"stat_changes":{"attack":1},"stat_halves":{}},"eos_351":{"name":"Cotton Snare","type":"grass","pattern":"front","reach":1,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#d2f49c","dark":"#428b4b","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":351,"reference_key":"COTTON_SPORE","acc1":70,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"speed_change":-1,"stat_changes":{},"stat_halves":{}},"eos_444":{"name":"Wind Escort","type":"flying","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"spiral","light":"#e6faff","dark":"#9aaceb","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":444,"reference_key":"TAILWIND","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"speed_change":1,"stat_changes":{},"stat_halves":{}},"eos_540":{"name":"Polished Stone","type":"rock","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"spiral","light":"#f0dec2","dark":"#a38966","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":540,"reference_key":"ROCK_POLISH","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"speed_change":2,"stat_changes":{},"stat_halves":{}},"eos_088":{"name":"Null Mist","type":"ice","pattern":"self","reach":0,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"cloud","light":"#efffff","dark":"#70bde3","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":88,"reference_key":"HAZE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"All Pokémon in the room","prototype":true,"stat_changes":{},"stat_halves":{},"reset_room_stats":true},"eos_301":{"name":"Aegis","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":10,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":301,"reference_key":"PROTECT","acc1":75,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"shield_kind":"protect","shield_min":3,"shield_max":6},"eos_305":{"name":"Deflect","type":"fighting","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#ffdfbb","dark":"#d97742","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":305,"reference_key":"DETECT","acc1":75,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"shield_kind":"protect","shield_min":3,"shield_max":6},"eos_104":{"name":"Last Stand","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":104,"reference_key":"ENDURE","acc1":75,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"shield_kind":"endure","shield_min":4,"shield_max":5},"eos_051":{"name":"Retaliation","type":"fighting","pattern":"self","reach":0,"category":"physical","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#ffdfbb","dark":"#d97742","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":51,"reference_key":"COUNTER","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"shield_kind":"counter","shield_min":7,"shield_max":12},"eos_038":{"name":"Pursuer Stance","type":"dark","pattern":"self","reach":0,"category":"physical","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#dfc3f8","dark":"#67457a","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":38,"reference_key":"PURSUIT","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"shield_kind":"counter","shield_min":7,"shield_max":12},"eos_472":{"name":"Reprisal","type":"dark","pattern":"self","reach":0,"category":"physical","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#dfc3f8","dark":"#67457a","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":472,"reference_key":"PAYBACK","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"shield_kind":"counter","shield_min":7,"shield_max":12},"eos_316":{"name":"Arcane Reversal","type":"psychic","pattern":"self","reach":0,"category":"special","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":316,"reference_key":"MIRROR_COAT","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"shield_kind":"mirror","shield_min":11,"shield_max":12},"eos_338":{"name":"Physical Ward","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":338,"reference_key":"REFLECT","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"shield_kind":"reflect","shield_min":11,"shield_max":12},"eos_259":{"name":"Arcane Ward","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":14,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":259,"reference_key":"LIGHT_SCREEN","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"shield_kind":"screen","shield_min":11,"shield_max":12},"eos_532":{"name":"Metal Rebound","type":"steel","pattern":"self","reach":0,"category":"physical","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#f0f9ff","dark":"#899eae","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":532,"reference_key":"METAL_BURST","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"shield_kind":"metal","shield_min":8,"shield_max":11},"eos_134":{"name":"Purity Ward","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":134,"reference_key":"SAFEGUARD","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"shield_kind":"safeguard","shield_min":16,"shield_max":20},"eos_074":{"name":"Battle Focus","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":27,"learn_level":20,"mode":"spiral","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":74,"reference_key":"FOCUS_ENERGY","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"focus","boon_min":2,"boon_max":4},"eos_447":{"name":"Fortune Chant","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":447,"reference_key":"LUCKY_CHANT","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"boon_kind":"lucky","boon_min":8,"boon_max":15},"eos_130":{"name":"Clear Veil","type":"ice","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#efffff","dark":"#70bde3","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":130,"reference_key":"MIST","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"mist","boon_min":11,"boon_max":14},"eos_225":{"name":"Renewing Wish","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":225,"reference_key":"WISH","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"wish","boon_min":11,"boon_max":12},"eos_015":{"name":"Herbal Purge","type":"grass","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#d2f49c","dark":"#428b4b","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":15,"reference_key":"AROMATHERAPY","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"boon_kind":"cure","boon_min":0,"boon_max":0},"eos_026":{"name":"Pure Chime","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":26,"reference_key":"HEAL_BELL","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"boon_kind":"cure","boon_min":0,"boon_max":0},"eos_339":{"name":"Cleanse","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":339,"reference_key":"REFRESH","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"boon_kind":"cure","boon_min":0,"boon_max":0},"eos_012":{"name":"Rain Ritual","type":"water","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"cloud","light":"#dcffff","dark":"#329ed3","duration":0.75,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":12,"reference_key":"RAIN_DANCE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Floor","prototype":true,"weather_set":"rain"},"eos_014":{"name":"Frostfall","type":"ice","pattern":"self","reach":0,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"cloud","light":"#efffff","dark":"#70bde3","duration":0.75,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":14,"reference_key":"HAIL","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Floor","prototype":true,"weather_set":"hail"},"eos_141":{"name":"Dune Storm","type":"rock","pattern":"self","reach":0,"category":"status","power":0,"pp":14,"learn_level":20,"mode":"cloud","light":"#f0dec2","dark":"#a38966","duration":0.75,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":141,"reference_key":"SANDSTORM","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Floor","prototype":true,"weather_set":"sandstorm"},"eos_223":{"name":"Sun Ritual","type":"fire","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"cloud","light":"#fff4a0","dark":"#e95237","duration":0.75,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":223,"reference_key":"SUNNY_DAY","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Floor","prototype":true,"weather_set":"sun"},"eos_212":{"name":"Grounding Mist","type":"ground","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"cloud","light":"#f4cd8c","dark":"#9a623f","duration":0.75,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":212,"reference_key":"MUD_SPORT","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Floor","prototype":true,"floor_sport":"mud"},"eos_307":{"name":"Dampening Mist","type":"water","pattern":"self","reach":0,"category":"status","power":0,"pp":19,"learn_level":20,"mode":"cloud","light":"#dcffff","dark":"#329ed3","duration":0.75,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":307,"reference_key":"WATER_SPORT","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Floor","prototype":true,"floor_sport":"water"},"eos_006":{"name":"Dawn Renewal","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.75,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":6,"reference_key":"MORNING_SUN","acc1":100,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Team members on the floor","prototype":true,"weather_heal":true},"eos_094":{"name":"Verdant Renewal","type":"grass","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#d2f49c","dark":"#428b4b","duration":0.75,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":94,"reference_key":"SYNTHESIS","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"weather_heal":true},"eos_173":{"name":"Lunar Renewal","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.75,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":173,"reference_key":"MOONLIGHT","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Team members on the floor","prototype":true,"weather_heal":true},"eos_020":{"name":"Crescent Fang","type":"normal","pattern":"front","reach":1,"category":"physical","power":0,"pp":17,"learn_level":20,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":20,"reference_key":"SUPER_FANG","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"half_hp"},"eos_066":{"name":"Equalizer","type":"normal","pattern":"front","reach":1,"category":"physical","power":0,"pp":12,"learn_level":20,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":66,"reference_key":"ENDEAVOR","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"equal_hp"},"eos_108":{"name":"Mind Ripple","type":"psychic","pattern":"line","reach":10,"category":"special","power":0,"pp":19,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":108,"reference_key":"PSYWAVE","acc1":95,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true,"special_rule":"psywave"},"eos_152":{"name":"Sonic Pulse","type":"normal","pattern":"line","reach":10,"category":"special","power":0,"pp":11,"learn_level":20,"mode":"beam","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":152,"reference_key":"SONICBOOM","acc1":95,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true,"special_rule":"20"},"eos_170":{"name":"Seismic Grip","type":"fighting","pattern":"front","reach":1,"category":"physical","power":0,"pp":10,"learn_level":20,"mode":"leap","light":"#ffdfbb","dark":"#d97742","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":170,"reference_key":"SEISMIC_TOSS","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"level"},"eos_216":{"name":"Night Echo","type":"ghost","pattern":"radius","reach":1,"category":"special","power":0,"pp":8,"learn_level":20,"mode":"wave","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":216,"reference_key":"NIGHT_SHADE","acc1":88,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies within a 1-tile range","prototype":true,"special_rule":"level"},"eos_341":{"name":"Drake Wrath","type":"dragon","pattern":"corner_front","reach":1,"category":"special","power":0,"pp":8,"learn_level":20,"mode":"flame","light":"#f6ceff","dark":"#7359d2","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":341,"reference_key":"DRAGON_RAGE","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"special_rule":"30"},"eos_131":{"name":"Fault Rift","type":"ground","pattern":"front","reach":1,"category":"physical","power":0,"pp":10,"learn_level":50,"mode":"quake","light":"#f4cd8c","dark":"#9a623f","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":131,"reference_key":"FISSURE","acc1":20,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"ohko"},"eos_150":{"name":"Absolute Frost","type":"ice","pattern":"front","reach":1,"category":"special","power":0,"pp":12,"learn_level":50,"mode":"shards","light":"#efffff","dark":"#70bde3","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":150,"reference_key":"SHEER_COLD","acc1":20,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"ohko"},"eos_177":{"name":"Piercing Horn","type":"normal","pattern":"front","reach":1,"category":"physical","power":0,"pp":12,"learn_level":50,"mode":"dart","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":177,"reference_key":"HORN_DRILL","acc1":20,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"ohko"},"eos_247":{"name":"Final Shear","type":"normal","pattern":"front","reach":1,"category":"physical","power":0,"pp":12,"learn_level":50,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":247,"reference_key":"GUILLOTINE","acc1":20,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"ohko"},"eos_268":{"name":"Gale Thrust","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":27,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":268,"reference_key":"WHIRLWIND","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"push"},"eos_284":{"name":"Thunderous Roar","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":14,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":284,"reference_key":"ROAR","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"push"},"eos_187":{"name":"Phase Step","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":7,"learn_level":20,"mode":"spiral","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":187,"reference_key":"TELEPORT","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"special_rule":"warp"},"eos_005":{"name":"Dread Dream","type":"ghost","pattern":"front","reach":1,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":5,"reference_key":"NIGHTMARE","acc1":88,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"nightmare"},"eos_084":{"name":"Reed Lullaby","type":"grass","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#d2f49c","dark":"#428b4b","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":84,"reference_key":"GRASSWHISTLE","acc1":88,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"inflict_status":"sleep"},"eos_086":{"name":"Silken Anchor","type":"bug","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"web","light":"#ebf5af","dark":"#7e9c36","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":86,"reference_key":"SPIDER_WEB","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"inflict_status":"stuck"},"eos_089":{"name":"Shadow Anchor","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":89,"reference_key":"MEAN_LOOK","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"stuck"},"eos_194":{"name":"Stone Anchor","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":194,"reference_key":"BLOCK","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"stuck"},"eos_329":{"name":"Siphon Seed","type":"grass","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":329,"reference_key":"LEECH_SEED","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"inflict_status":"leech"},"eos_021":{"name":"Shared Vitality","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":21,"reference_key":"PAIN_SPLIT","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"pain_split"},"eos_394":{"name":"Vacuum Arc","type":"normal","pattern":"room","reach":0,"category":"special","power":0,"pp":7,"learn_level":20,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":394,"reference_key":"VACUUM_CUT","acc1":100,"acc2":100,"reference_crit":0,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true,"special_rule":"35"},"eos_457":{"name":"Last Reserve","type":"normal","pattern":"front","reach":1,"category":"special","power":1,"pp":5,"learn_level":20,"mode":"beam","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":457,"reference_key":"TRUMP_CARD","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"pp_scaling":true},"eos_434":{"name":"Tidal Halo","type":"water","pattern":"self","reach":0,"category":"status","power":0,"pp":20,"learn_level":20,"mode":"wave","light":"#dcffff","dark":"#329ed3","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":434,"reference_key":"AQUA_RING","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"aqua","boon_min":9,"boon_max":16},"eos_098":{"name":"True Sight","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":98,"reference_key":"MIND_READER","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"sure","boon_min":10,"boon_max":12},"eos_349":{"name":"Target Lock","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":7,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":349,"reference_key":"LOCK_ON","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"sure","boon_min":10,"boon_max":12},"eos_267":{"name":"Feather Veil","type":"flying","pattern":"front","reach":1,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#e6faff","dark":"#9aaceb","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":267,"reference_key":"FEATHERDANCE","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"stat_changes":{"attack":-2},"stat_halves":{}},"eos_449":{"name":"Hive Renewal","type":"bug","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#ebf5af","dark":"#7e9c36","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":449,"reference_key":"HEAL_ORDER","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"heal_fraction":0,"heal_fixed":40},"eos_165":{"name":"Vital Share","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":165,"reference_key":"SOFTBOILED","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"heal_fraction":0.25},"eos_318":{"name":"Nourishing Wave","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":318,"reference_key":"MILK_DRINK","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Team members on the floor","prototype":true,"heal_fraction":0.25},"eos_295":{"name":"Thorn Tile","type":"ground","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"quake","light":"#f4cd8c","dark":"#9a623f","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":295,"reference_key":"SPIKES","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Special","prototype":true,"trap_kind":"spikes"},"eos_496":{"name":"Venom Tile","type":"poison","pattern":"self","reach":0,"category":"status","power":0,"pp":18,"learn_level":20,"mode":"cloud","light":"#f5c1ff","dark":"#9a49ad","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":496,"reference_key":"TOXIC_SPIKES","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Special","prototype":true,"trap_kind":"toxic"},"eos_480":{"name":"Hidden Crags","type":"rock","pattern":"self","reach":0,"category":"status","power":0,"pp":20,"learn_level":20,"mode":"shards","light":"#f0dec2","dark":"#a38966","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":480,"reference_key":"STEALTH_ROCK","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Special","prototype":true,"trap_kind":"rock"},"eos_123":{"name":"Burst Core","type":"normal","pattern":"self","reach":0,"category":"physical","power":0,"pp":12,"learn_level":20,"mode":"flame","light":"#fff4d6","dark":"#c09d70","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":123,"reference_key":"SELFDESTRUCT","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Pokémon within 1-tile range","prototype":true,"blast_radius":1,"blast_damage":40},"eos_155":{"name":"Nova Rupture","type":"normal","pattern":"self","reach":0,"category":"physical","power":0,"pp":6,"learn_level":20,"mode":"flame","light":"#fff4d6","dark":"#c09d70","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":155,"reference_key":"EXPLOSION","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Pokémon within 2-tile range","prototype":true,"blast_radius":2,"blast_damage":80},"eos_037":{"name":"Smoke Shroud","type":"normal","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":10,"learn_level":20,"mode":"cloud","light":"#fff4d6","dark":"#c09d70","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":37,"reference_key":"SMOKESCREEN","acc1":100,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"inflict_status":"whiffer"},"eos_266":{"name":"Stasis Seal","type":"psychic","pattern":"front","reach":1,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":266,"reference_key":"IMPRISON","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"paused"},"eos_293":{"name":"Final Refrain","type":"normal","pattern":"floor","reach":0,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.7,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":293,"reference_key":"PERISH_SONG","acc1":15,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies on the floor","prototype":true,"inflict_status":"perish"},"eos_115":{"name":"Echo Mind","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":115,"reference_key":"PSYCH_UP","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Facing Pokémon","prototype":true,"stat_transfer":"copy"},"eos_448":{"name":"Ward Exchange","type":"psychic","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":11,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":448,"reference_key":"GUARD_SWAP","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Facing Pokémon, cuts corners","prototype":true,"stat_transfer":"guard"},"eos_506":{"name":"Balance Exchange","type":"psychic","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":10,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":506,"reference_key":"HEART_SWAP","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Facing Pokémon, cuts corners","prototype":true,"stat_transfer":"all"},"eos_513":{"name":"Force Exchange","type":"psychic","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":513,"reference_key":"POWER_SWAP","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Facing Pokémon, cuts corners","prototype":true,"stat_transfer":"power"},"eos_514":{"name":"Inverted Stance","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":514,"reference_key":"POWER_TRICK","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_transfer":"invert"},"eos_492":{"name":"Pressure Point","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":492,"reference_key":"ACUPRESSURE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"stat_transfer":"random"},"eos_024":{"name":"Provocation","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":18,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":24,"reference_key":"SWAGGER","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"stat_changes":{"attack":2},"stat_halves":{},"inflict_status":"confusion"},"eos_045":{"name":"False Praise","type":"dark","pattern":"front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#dfc3f8","dark":"#67457a","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":45,"reference_key":"FLATTER","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"stat_changes":{"sp_attack":1},"stat_halves":{},"inflict_status":"confusion"},"eos_059":{"name":"Nerve Seal","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":9,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":59,"reference_key":"DISABLE","acc1":100,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"paralysis"},"eos_128":{"name":"Static Reservoir","type":"electric","pattern":"self","reach":0,"category":"status","power":0,"pp":20,"learn_level":20,"mode":"wave","light":"#fffbb0","dark":"#e7b22c","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":128,"reference_key":"CHARGE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_transfer":"charge"},"eos_330":{"name":"Chance Invocation","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":330,"reference_key":"METRONOME","acc1":100,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Special","prototype":true,"random_cast":true},"eos_118":{"name":"Tectonic Pulse","type":"ground","pattern":"room","reach":0,"category":"physical","power":5,"pp":10,"learn_level":20,"mode":"quake","light":"#f4cd8c","dark":"#9a623f","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":118,"reference_key":"EARTHQUAKE","acc1":80,"acc2":65,"reference_crit":8,"reference_strikes":1,"reference_range":"All in the room except user","prototype":true},"eos_296":{"name":"Seismic Surge","type":"ground","pattern":"room","reach":0,"category":"physical","power":0,"pp":15,"learn_level":20,"mode":"quake","light":"#f4cd8c","dark":"#9a623f","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":296,"reference_key":"MAGNITUDE","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All in the room except user","prototype":true,"special_rule":"magnitude"},"eos_346":{"name":"Double Rake","type":"bug","pattern":"front","reach":1,"category":"physical","power":2,"pp":12,"learn_level":20,"mode":"slash","light":"#ebf5af","dark":"#7e9c36","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":346,"reference_key":"FURY_CUTTER","acc1":88,"acc2":75,"reference_crit":8,"reference_strikes":2,"reference_range":"Enemy in front","prototype":true,"hit_min":2,"hit_max":2},"eos_360":{"name":"Crescent Sweep","type":"normal","pattern":"corner_front","reach":1,"category":"physical","power":20,"pp":10,"learn_level":20,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":360,"reference_key":"WIDE_SLASH","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Facing tile and 2 flanking tiles","prototype":true,"typeless":true,"wide_sweep":true},"eos_160":{"name":"Store Vitality","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":160,"reference_key":"STOCKPILE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"reserve_action":"store"},"eos_236":{"name":"Consume Vitality","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":236,"reference_key":"SWALLOW","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"reserve_action":"heal"},"eos_509":{"name":"Feather Rest","type":"flying","pattern":"self","reach":0,"category":"status","power":0,"pp":14,"learn_level":20,"mode":"wave","light":"#e6faff","dark":"#9aaceb","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":509,"reference_key":"ROOST","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"heal_fraction":0.5,"roost":true},"eos_009":{"name":"Wild Flurry","type":"normal","pattern":"radius","reach":1,"category":"physical","power":18,"pp":12,"learn_level":20,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":9,"reference_key":"THRASH","acc1":125,"acc2":78,"reference_crit":8,"reference_strikes":3,"reference_range":"Adjacent Pokémon","prototype":true,"hit_min":3,"hit_max":3,"rampage_random":true,"self_confuse":true},"eos_091":{"name":"Draconic Frenzy","type":"dragon","pattern":"front","reach":1,"category":"physical","power":18,"pp":6,"learn_level":20,"mode":"slash","light":"#f6ceff","dark":"#7359d2","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":91,"reference_key":"OUTRAGE","acc1":85,"acc2":50,"reference_crit":8,"reference_strikes":0,"reference_range":"Enemy in front","prototype":true,"hit_min":2,"hit_max":5,"self_confuse":true},"eos_253":{"name":"Petal Frenzy","type":"grass","pattern":"front","reach":1,"category":"special","power":7,"pp":9,"learn_level":20,"mode":"spiral","light":"#d2f49c","dark":"#428b4b","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":253,"reference_key":"PETAL_DANCE","acc1":80,"acc2":55,"reference_crit":8,"reference_strikes":0,"reference_range":"Enemy in front","prototype":true,"hit_min":2,"hit_max":5,"self_confuse":true},"eos_232":{"name":"Deep Rest","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":8,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":232,"reference_key":"REST","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"nap","boon_min":2,"boon_max":3},"eos_233":{"name":"Rooted Renewal","type":"grass","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#d2f49c","dark":"#428b4b","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":233,"reference_key":"INGRAIN","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"ingrain","boon_min":16,"boon_max":30},"eos_256":{"name":"Fate Seal","type":"steel","pattern":"self","reach":0,"category":"status","power":0,"pp":11,"learn_level":20,"mode":"wave","light":"#f0f9ff","dark":"#899eae","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":256,"reference_key":"DOOM_DESIRE","acc1":125,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"set_damage","boon_min":3,"boon_max":4},"eos_317":{"name":"Foresight Pulse","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":317,"reference_key":"FUTURE_SIGHT","acc1":125,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"set_damage","boon_min":3,"boon_max":4},"eos_112":{"name":"Wake Chorus","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":112,"reference_key":"UPROAR","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"boon_kind":"sleepless","boon_min":9999,"boon_max":9999},"eos_504":{"name":"Awake Seed","type":"grass","pattern":"line","reach":10,"category":"status","power":0,"pp":14,"learn_level":20,"mode":"dart","light":"#d2f49c","dark":"#428b4b","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":504,"reference_key":"WORRY_SEED","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Line of sight","prototype":true,"inflict_status":"sleepless"},"eos_043":{"name":"Last Eclipse","type":"dark","pattern":"room","reach":0,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#dfc3f8","dark":"#67457a","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":43,"reference_key":"MEMENTO","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true,"stat_changes":{},"stat_halves":{"attack":2,"sp_attack":2},"memento":true},"eos_456":{"name":"Clear Gust","type":"flying","pattern":"room","reach":0,"category":"status","power":0,"pp":14,"learn_level":20,"mode":"wave","light":"#e6faff","dark":"#9aaceb","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":456,"reference_key":"DEFOG","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true,"stat_changes":{"evasion":-1},"stat_halves":{},"defog":true},"eos_464":{"name":"Burden Transfer","type":"psychic","pattern":"front","reach":1,"category":"status","power":0,"pp":10,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":464,"reference_key":"PSYCHO_SHIFT","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Facing Pokémon","prototype":true,"special_rule":"shift"},"eos_277":{"name":"Mystery Parcel","type":"normal","pattern":"corner_front","reach":1,"category":"physical","power":0,"pp":19,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":277,"reference_key":"PRESENT","acc1":100,"acc2":90,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"special_rule":"present"},"eos_478":{"name":"Gravity Field","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":10,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":478,"reference_key":"GRAVITY","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Floor","prototype":true,"stat_transfer":"gravity"},"eos_493":{"name":"Magnetic Lift","type":"electric","pattern":"self","reach":0,"category":"status","power":0,"pp":13,"learn_level":20,"mode":"wave","light":"#fffbb0","dark":"#e7b22c","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":493,"reference_key":"MAGNET_RISE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"magnet","boon_min":3,"boon_max":5},"eos_061":{"name":"Stored Retort","type":"normal","pattern":"self","reach":0,"category":"physical","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":61,"reference_key":"BIDE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"bide","boon_min":4,"boon_max":4},"eos_340":{"name":"Vengeance","type":"fighting","pattern":"self","reach":0,"category":"physical","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#ffdfbb","dark":"#d97742","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":340,"reference_key":"REVENGE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"bide","boon_min":4,"boon_max":4},"eos_535":{"name":"Frozen Retort","type":"ice","pattern":"self","reach":0,"category":"physical","power":6,"pp":12,"learn_level":20,"mode":"wave","light":"#efffff","dark":"#70bde3","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":535,"reference_key":"AVALANCHE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"bide","boon_min":4,"boon_max":4},"eos_019":{"name":"Fury Stance","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":19,"reference_key":"RAGE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"rage","boon_min":5,"boon_max":10},"eos_007":{"name":"Redirecting Grip","type":"fighting","pattern":"self","reach":0,"category":"physical","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#ffdfbb","dark":"#d97742","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":7,"reference_key":"VITAL_THROW","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"vital_throw","boon_min":18,"boon_max":18},"eos_315":{"name":"Spirit Reveal","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":315,"reference_key":"FORESIGHT","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"exposed"},"eos_054":{"name":"Scent Reveal","type":"normal","pattern":"room","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":54,"reference_key":"ODOR_SLEUTH","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true,"inflict_status":"exposed"},"eos_528":{"name":"Mind Reveal","type":"psychic","pattern":"front","reach":1,"category":"status","power":0,"pp":27,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":528,"reference_key":"MIRACLE_EYE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"inflict_status":"miracle_eye"},"eos_183":{"name":"Element Shift","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":183,"reference_key":"CONVERSION","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_transfer":"conversion"},"eos_184":{"name":"Adaptive Shell","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":184,"reference_key":"CONVERSION_2","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"adapt","boon_min":11,"boon_max":11},"eos_286":{"name":"Terrain Mantle","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":286,"reference_key":"CAMOUFLAGE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"stat_transfer":"camouflage"},"eos_324":{"name":"Hidden Spark","type":"normal","pattern":"corner_front","reach":1,"category":"special","power":2,"pp":12,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":324,"reference_key":"HIDDEN_POWER","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"hidden_power":true},"eos_450":{"name":"Recovery Seal","type":"psychic","pattern":"room","reach":0,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":450,"reference_key":"HEAL_BLOCK","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All enemies in the room","prototype":true,"inflict_status":"heal_block"},"eos_237":{"name":"Hex Pact","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":237,"reference_key":"CURSE","acc1":100,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Special","prototype":true,"curse_action":true},"eos_025":{"name":"Dream Echo","type":"normal","pattern":"front","reach":1,"category":"special","power":4,"pp":16,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":25,"reference_key":"SNORE","acc1":125,"acc2":95,"reference_crit":8,"reference_strikes":1,"reference_range":"Special","prototype":true,"sleep_reactive":true},"eos_227":{"name":"Dream Invocation","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":227,"reference_key":"SLEEP_TALK","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Special","prototype":true,"sleep_reactive":true},"eos_274":{"name":"Dizzy Waltz","type":"normal","pattern":"room","reach":0,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"spiral","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":274,"reference_key":"TEETER_DANCE","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All Pokémon in the room","prototype":true,"inflict_status":"confusion"},"eos_294":{"name":"Binding Coil","type":"normal","pattern":"front","reach":1,"category":"physical","power":0,"pp":22,"learn_level":20,"mode":"spiral","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":294,"reference_key":"WRAP","acc1":100,"acc2":88,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"wrap"},"eos_254":{"name":"Bouncing Step","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":50,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":254,"reference_key":"SPLASH","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Adjacent Pokémon","prototype":true,"special_rule":"splash"},"eos_029":{"name":"Stonebreaker","type":"fighting","pattern":"front","reach":1,"category":"status","power":0,"pp":99,"learn_level":20,"mode":"slash","light":"#ffdfbb","dark":"#d97742","duration":0.65,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":29,"reference_key":"ROCK_SMASH","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Wall","prototype":true,"special_rule":"break_wall"},"eos_050":{"name":"Titan Toss","type":"normal","pattern":"front","reach":1,"category":"physical","power":0,"pp":12,"learn_level":20,"mode":"leap","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":50,"reference_key":"STRENGTH","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"hurl"},"eos_503":{"name":"Shadow Toss","type":"dark","pattern":"front","reach":1,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"leap","light":"#dfc3f8","dark":"#67457a","duration":0.65,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":503,"reference_key":"FLING","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"hurl"},"eos_048":{"name":"Trust Strike","type":"normal","pattern":"front","reach":1,"category":"physical","power":0,"pp":12,"learn_level":20,"mode":"leap","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":48,"reference_key":"RETURN","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"iq_return"},"eos_328":{"name":"Rebel Strike","type":"normal","pattern":"front","reach":1,"category":"physical","power":0,"pp":16,"learn_level":20,"mode":"slash","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":328,"reference_key":"FRUSTRATION","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"iq_frustration"},"eos_119":{"name":"Terrain Invocation","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":24,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":119,"reference_key":"NATURE_POWER","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Special","prototype":true,"special_rule":"nature_power"},"eos_326":{"name":"Heart Glance","type":"normal","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":10,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":326,"reference_key":"ATTRACT","acc1":75,"acc2":78,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"special_rule":"infatuation"},"eos_534":{"name":"Charming Gaze","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":20,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":534,"reference_key":"CAPTIVATE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"captivate"},"eos_313":{"name":"Fate Link","type":"ghost","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":313,"reference_key":"DESTINY_BOND","acc1":100,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"special_rule":"destiny_link"},"eos_017":{"name":"Echo Lock","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":17,"reference_key":"ENCORE","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"encore"},"eos_022":{"name":"Silencing Seal","type":"dark","pattern":"front","reach":1,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":22,"reference_key":"TORMENT","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"torment"},"eos_035":{"name":"Essence Drain","type":"ghost","pattern":"front","reach":1,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":35,"reference_key":"SPITE","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"spite"},"eos_172":{"name":"Defiant Call","type":"dark","pattern":"front","reach":1,"category":"status","power":0,"pp":20,"learn_level":20,"mode":"wave","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":172,"reference_key":"TAUNT","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"taunt"},"eos_298":{"name":"Arcane Reflection","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":19,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":298,"reference_key":"MAGIC_COAT","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"magic_coat","boon_min":11,"boon_max":12},"eos_334":{"name":"Stolen Blessing","type":"dark","pattern":"self","reach":0,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":334,"reference_key":"SNATCH","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"snatch","boon_min":4,"boon_max":5},"eos_040":{"name":"Mirror Veil","type":"flying","pattern":"self","reach":0,"category":"status","power":0,"pp":7,"learn_level":20,"mode":"wave","light":"#e6faff","dark":"#9aaceb","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":40,"reference_key":"MIRROR_MOVE","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"mirror_veil","boon_min":2,"boon_max":5},"eos_049":{"name":"Final Grudge","type":"ghost","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":49,"reference_key":"GRUDGE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"boon_kind":"grudge","boon_min":9999,"boon_max":9999},"eos_499":{"name":"Tempo Rift","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":10,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":499,"reference_key":"TRICK_ROOM","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Floor","prototype":true,"special_rule":"tempo_rift"},"eos_209":{"name":"Relic Exchange","type":"psychic","pattern":"front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":209,"reference_key":"TRICK","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"swap_item"},"eos_482":{"name":"Shadow Exchange","type":"dark","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":482,"reference_key":"SWITCHEROO","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"special_rule":"swap_item"},"eos_249":{"name":"Disarming Swipe","type":"dark","pattern":"front","reach":1,"category":"physical","power":0,"pp":22,"learn_level":20,"mode":"slash","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"attack","frame_count":12,"frame_size":48,"reference_id":249,"reference_key":"KNOCK_OFF","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"drop_item"},"eos_466":{"name":"Supply Seal","type":"dark","pattern":"front","reach":1,"category":"status","power":0,"pp":18,"learn_level":20,"mode":"wave","light":"#e5d9ff","dark":"#8662c9","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":466,"reference_key":"EMBARGO","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"embargo"},"eos_137":{"name":"Talent Exchange","type":"psychic","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":14,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":137,"reference_key":"SKILL_SWAP","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"special_rule":"swap_ability"},"eos_220":{"name":"Talent Mimic","type":"psychic","pattern":"front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c063bc","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":220,"reference_key":"ROLE_PLAY","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"copy_ability"},"eos_438":{"name":"Nullifying Venom","type":"poison","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#f5c1ff","dark":"#9a49ad","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":438,"reference_key":"GASTRO_ACID","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Facing Pokémon, cuts corners","prototype":true,"special_rule":"suppress_ability"},"eos_327":{"name":"Echo Strike","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":17,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":327,"reference_key":"MIMIC","acc1":100,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"copy_last"},"eos_525":{"name":"Echo Casting","type":"normal","pattern":"corner_front","reach":1,"category":"status","power":0,"pp":19,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":525,"reference_key":"COPYCAT","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front, cuts corners","prototype":true,"special_rule":"copy_last"},"eos_138":{"name":"Living Inscription","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":1,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":138,"reference_key":"SKETCH","acc1":100,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Enemy in front","prototype":true,"special_rule":"learn_last"},"eos_465":{"name":"First Echo","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":22,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":465,"reference_key":"ME_FIRST","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Facing Pokémon","prototype":true,"special_rule":"copy_boost"},"eos_257":{"name":"Feral Crescendo","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":10,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":257,"reference_key":"BELLY_DRUM","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"special_rule":"belly_drum"},"eos_337":{"name":"Script Renewal","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":10,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":337,"reference_key":"RECYCLE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Item","prototype":true,"special_rule":"recycle_manual"},"eos_282":{"name":"Wild Guise","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":1,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":282,"reference_key":"TRANSFORM","acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"special_rule":"transform_form"},"eos_304":{"name":"False Target","type":"normal","pattern":"front","reach":1,"category":"status","power":0,"pp":7,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":304,"reference_key":"SUBSTITUTE","acc1":100,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"Facing Pokémon","prototype":true,"special_rule":"decoy"},"eos_252":{"name":"Relay Step","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":252,"reference_key":"BATON_PASS","acc1":75,"acc2":125,"reference_crit":8,"reference_strikes":1,"reference_range":"All Pokémon in the room","prototype":true,"special_rule":"relay_swap"},"eos_102":{"name":"Gathering Cry","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":102,"reference_key":"FOLLOW_ME","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"User","prototype":true,"special_rule":"leader_decoy"},"eos_185":{"name":"United Spirit","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":185,"reference_key":"HELPING_HAND","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Only the allies in the room","prototype":true,"special_rule":"party_boost"},"eos_229":{"name":"Borrowed Echo","type":"normal","pattern":"self","reach":0,"category":"status","power":0,"pp":27,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":229,"reference_key":"ASSIST","acc1":100,"acc2":95,"reference_crit":8,"reference_strikes":1,"reference_range":"Special","prototype":true,"special_rule":"floor_assist"},"eos_269":{"name":"Rally Warp","type":"dark","pattern":"self","reach":0,"category":"status","power":0,"pp":15,"learn_level":20,"mode":"wave","light":"#fff4d6","dark":"#8662c9","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":269,"reference_key":"BEAT_UP","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"Team members on the floor","prototype":true,"special_rule":"party_rally"},"eos_439":{"name":"Life Offering","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":16,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":439,"reference_key":"HEALING_WISH","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"special_rule":"party_heal"},"eos_526":{"name":"Moon Renewal","type":"psychic","pattern":"self","reach":0,"category":"status","power":0,"pp":12,"learn_level":20,"mode":"wave","light":"#ffdcf8","dark":"#c09d70","duration":0.65,"caster":"cast","frame_count":12,"frame_size":48,"reference_id":526,"reference_key":"LUNAR_DANCE","acc1":125,"acc2":100,"reference_crit":8,"reference_strikes":1,"reference_range":"All team members in the room","prototype":true,"special_rule":"party_renew"}}
static func available_moves(types:Array,level:int)->Array:
	var result:Array=[]
	for id in MOVE_LIBRARY:
		var move:Dictionary=MOVE_LIBRARY[id]
		if move.type in types and int(move.learn_level)<=level:result.append(id)
	return result
const EOS_IDENTIFIED_COUNT=468
const EOS_PROTOTYPE_COUNT=468
const EOS_PARTY_COUNT=6
const EOS_FORM_POSITION_COUNT=3
const EOS_RESOURCE_MOVE_COUNT=2
const EOS_COPY_MOVE_COUNT=4
const EOS_ABILITY_COUNT=3
const EOS_HELD_ITEM_COUNT=4
const EOS_REFLECTION_SPEED_COUNT=3
const EOS_SUPPORT_CONTROL_COUNT=3
const EOS_MOVE_LOCK_COUNT=3
const EOS_BOND_CONTROL_COUNT=3
const EOS_IQ_TERRAIN_COUNT=3
const EOS_TERRAIN_HURL_COUNT=3
const EOS_SLEEP_BINDING_COUNT=5
const EOS_ADAPTIVE_MOVE_COUNT=6
const EOS_REACTIVE_MOVE_COUNT=8
const EOS_FIELD_SACRIFICE_COUNT=6
const EOS_RAMPAGE_SLEEP_COUNT=9
const EOS_RESERVE_AREA_COUNT=7
const EOS_TRANSFER_MOVE_COUNT=11
const EOS_TRAP_MOVE_COUNT=3
const EOS_BLAST_MOVE_COUNT=2
const EOS_RESTRICTION_MOVE_COUNT=3
const EOS_ADVANCED_MOVE_COUNT=16
const EOS_FIXED_DAMAGE_COUNT=7
const EOS_OHKO_COUNT=4
const EOS_DISPLACE_COUNT=3
const EOS_WEATHER_MOVE_COUNT=9
const EOS_BOON_MOVE_COUNT=7
const EOS_SHIELD_MOVE_COUNT=11
const EOS_SPEED_MOVE_COUNT=7
const EOS_STAT_MOVE_COUNT=32
const EOS_STATUS_COUNT=17
const EOS_SECONDARY_STATUS_COUNT=2
const EOS_TWO_TURN_COUNT=9
const EOS_ESCALATING_COUNT=3
const EOS_RECOIL_COUNT=7
const EOS_DRAIN_COUNT=5
const EOS_SELF_HEAL_COUNT=2
const EOS_MULTIHIT_COUNT=23
const EV_STAT_CAP=252
const EV_TOTAL_CAP=510
const IV_ENABLED=false
var trained_profile:Dictionary={}
var transformed_species:String=""
var allies:Array[Dictionary]=[]
const PASSIVE_ABILITIES=["clear_blood","wakeful","steady_heart","critical_shell","anchored"]
const SPECIES_ABILITIES={"sporeling":["clear_blood"],"shellguard":["critical_shell","anchored"],"mossmite":["anchored"],"lunamoth":["wakeful"],"starlit_pup":["steady_heart"],"crystarok":["critical_shell"]}
var player_base_abilities:Array[String]=[]
var player_abilities:Array[String]=[]
var equipped_moves:Array=[]
var move_pp:Dictionary={}
var player_attack_path:Array=[]
var last_move_hits:int=0
var dev_cast_outcome:String=""
var dev_capture_outcome:bool=false
var last_move_attempts:int=0
var last_move_healed:int=0
var last_move_recoil:int=0
var player_stages:Dictionary={}
var last_invoked_move:String=""
var stockpile_count:int=0
var active_reserve_multiplier:int=0
var magnitude_damage:int=0
var roost_active:bool=false
const ADAPT_ELEMENTS:Array[String]=["normal","fire","water","electric","grass","ice","fighting","poison","ground","flying","psychic","bug","rock","ghost","dragon","dark","steel"]
var temporary_type:String=""
var adaptive_type:String=""
var hidden_element:String="normal"
var hidden_base_power:int=2
var player_slow_turns:int=0
func initialize_hidden_power(seed_number:int)->void:
	var local_rng:=RandomNumberGenerator.new()
	local_rng.seed=seed_number+83419
	hidden_element=ADAPT_ELEMENTS[local_rng.randi_range(0,ADAPT_ELEMENTS.size()-1)]
	var powers:Array=[2,4,6,7,8,9,10,13,15]
	hidden_base_power=int(powers[local_rng.randi_range(0,powers.size()-1)])
func resolved_move_element(move:Dictionary)->String:
	if move.get("hidden_power",false):return hidden_element
	if int(move.get("reference_id",-1))==31:return weather_ball_type()
	return str(move.get("type","normal"))
func convert_element()->bool:
	var choices:Array[String]=[]
	for id in equipped_moves:
		if MOVE_LIBRARY.has(id):
			var element:String=resolved_move_element(MOVE_LIBRARY[id])
			if element in ADAPT_ELEMENTS and not choices.has(element):choices.append(element)
	if choices.is_empty():return false
	temporary_type=choices[rng.randi_range(0,choices.size()-1)]
	adaptive_type=""
	return true
func adapt_after_hit(element:String)->bool:
	if not boon_active("adapt"):return false
	var choices:Array[String]=[]
	for candidate in ADAPT_ELEMENTS:
		if type_multiplier(element,[candidate])<1.0:choices.append(candidate)
	if choices.is_empty():return false
	adaptive_type=choices[rng.randi_range(0,choices.size()-1)]
	return true
func heal_enemy(target:Dictionary,amount:int)->int:
	if int(target.get("heal_block_turns",0))>0:return 0
	var before:int=int(target.hp)
	target.hp=mini(int(target.get("max_hp",before)),before+maxi(0,amount))
	return int(target.hp)-before
func current_player_types()->Array:
	var types:Array=trained_profile.get("types",["normal"]).duplicate()
	if not temporary_type.is_empty():types=[temporary_type]
	if boon_active("adapt") and not adaptive_type.is_empty():types=[adaptive_type]
	if roost_active and "flying" in types:
		types.erase("flying")
		if types.is_empty():types.append("normal")
	return types
func store_vitality()->bool:
	if stockpile_count>=3:return false
	stockpile_count+=1
	player_stages["defense"]=mini(10,int(player_stages.get("defense",0))+1)
	player_stages["sp_defense"]=mini(10,int(player_stages.get("sp_defense",0))+1)
	return true
func consume_vitality()->int:
	var amount:int=int([0,20,40,80][stockpile_count])
	stockpile_count=0
	var before:int=hp
	hp=mini(max_hp,hp+amount)
	return hp-before
func choose_magnitude()->int:
	var roll:int=rng.randi_range(1,100)
	return 5 if roll<=5 else 10 if roll<=15 else 15 if roll<=35 else 25 if roll<=65 else 30 if roll<=85 else 35 if roll<=95 else 40
var charge_power_turns:int=0
var shield_kind:String=""
var floor_weather:String="clear"
var gravity_active:bool=false
func activate_gravity()->bool:
	if gravity_active:return false
	gravity_active=true;player_boons.erase("magnet")
	for e in enemies:e.erase("magnet_turns")
	return true
func gravity_blocks(move:Dictionary)->bool:
	return gravity_active and str(move.get("reference_key","")) in ["FLY","BOUNCE","SPLASH","JUMP_KICK","HI_JUMP_KICK","HIGH_JUMP_KICK","MAGNET_RISE"]
func shift_conditions(i:int)->bool:
	var changed:bool=false
	if poison_turns>0 and apply_enemy_status(i,"poison"):poison_turns=0;changed=true
	if self_confusion_turns>0 and apply_enemy_status(i,"confusion"):self_confusion_turns=0;changed=true
	return changed
func present_outcome(roll:int)->int:
	return -1 if roll<=20 else 25 if roll<=60 else 50 if roll<=90 else 75
func clear_enemy_wards(e:Dictionary)->void:
	for key in ["guard","mist_turns","reflect_turns","screen_turns","safeguard_turns"]:e.erase(key)
var weather_age:int=0
var floor_sports:Dictionary={}
func set_floor_weather(value:String)->bool:
	if floor_weather==value:return false
	floor_weather=value;weather_age=0
	return true
func weather_factor(element:String)->float:
	var factor:float=1.0
	match floor_weather:
		"sun":factor=1.5 if element=="fire" else .5 if element=="water" else 1.0
		"rain":factor=1.5 if element=="water" else .5 if element=="fire" else 1.0
		"cloudy":factor=.75 if element!="normal" else 1.0
		"fog":factor=.5 if element=="electric" else 1.0
	if element=="electric" and int(floor_sports.get("mud",0))>0:factor*=.5
	if element=="fire" and int(floor_sports.get("water",0))>0:factor*=.5
	return factor
func weather_ball_type()->String:
	return str({"sun":"fire","rain":"water","hail":"ice","snow":"ice","sandstorm":"rock"}.get(floor_weather,"normal"))
func weather_heal_amount()->int:
	return int({"clear":50,"sun":80,"rain":10,"hail":10,"sandstorm":20,"cloudy":30,"fog":1,"snow":1}.get(floor_weather,50))
func weather_hurts(types:Array)->bool:
	if floor_weather=="hail":return not "ice" in types
	if floor_weather=="sandstorm":return not ("rock" in types or "ground" in types or "steel" in types)
	return false
func tick_floor_weather()->void:
	for sport in floor_sports.keys():
		floor_sports[sport]=int(floor_sports[sport])-1
		if int(floor_sports[sport])<=0:floor_sports.erase(sport)
	weather_age+=1
	if weather_age%10!=0 or floor_weather not in ["hail","sandstorm"]:return
	for i in range(enemies.size()-1,-1,-1):
		var types:Array=ENEMY_TRAINING.get(enemies[i].get("species",""),[["normal"]])[0]
		if weather_hurts(types):
			enemies[i].hp=int(enemies[i].hp)-3
			if int(enemies[i].hp)<=0:remove_defeated_enemy(i)
	if weather_hurts(current_player_types()):
		hp=maxi(0,hp-3);hits+=1;combo=0
		emit_event(floor_weather.capitalize()+" · −3 HP")
		if hp<=0:finished=true;success=false;message="Weather · rescue needed"
func weather_summary()->String:
	var parts:PackedStringArray=[]
	if floor_weather!="clear":parts.append(floor_weather.capitalize())
	if gravity_active:parts.append("Gravity")
	for sport in floor_sports:parts.append(str(sport).capitalize()+" Sport "+str(floor_sports[sport]))
	return " · ".join(parts)
var player_boons:Dictionary={}
var wrap_target:Vector2i=Vector2i.ZERO
var sleep_reactions:Array[Vector2i]=[]
func bind_enemy(i:int)->bool:
	if i<0 or i>=enemies.size() or boon_active("wrapping"):return false
	if int(enemies[i].get("wrapped_turns",0))>0:return false
	var duration:int=rng.randi_range(1,5)
	enemies[i]["wrapped_turns"]=duration
	enemies[i]["wrapped_age"]=0
	enemies[i]["windup"]=false
	wrap_target=enemies[i].pos;player_boons["wrapping"]=duration
	return true
func splash_step(direction:Vector2i)->bool:
	var target:Vector2i=player+direction
	if not cells.has(target):return false
	var i:int=enemy_at(target)
	if i>=0:
		deal_special_damage(i,5)
		hp=maxi(0,hp-5);hits+=1;combo=0
		if hp==0:finished=true;success=false
	else:
		player=target;reveal()
	return true
func flush_sleep_reactions()->void:
	for p in sleep_reactions:
		if not boon_active("nap") or hp<=0:break
		var id:String="eos_025" if "eos_025" in equipped_moves else "eos_227" if "eos_227" in equipped_moves else ""
		if id.is_empty() or int(move_pp.get(id,0))<=0:continue
		move_pp[id]=int(move_pp[id])-1
		var delta:Vector2i=p-player
		var aim:Vector2i=Vector2i(signi(delta.x),signi(delta.y))
		var chosen:String=id
		if id=="eos_227":
			var candidates:Array[String]=[]
			for candidate in equipped_moves:
				if not MOVE_LIBRARY.has(candidate):continue
				var other:Dictionary=MOVE_LIBRARY[candidate]
				if int(other.power)>0 and other.category!="status" and not other.get("sleep_reactive",false) and not other.has("charge_phase") and not other.has("special_rule") and not other.has("reserve_attack") and not other.has("recoil_fraction") and not other.has("boon_kind") and not other.get("self_confuse",false):candidates.append(candidate)
			if candidates.is_empty():continue
			chosen=candidates[rng.randi_range(0,candidates.size()-1)]
		var move:Dictionary=MOVE_LIBRARY[chosen]
		var target:int=enemy_at(p)
		var response_footprint:Dictionary=attack_footprint(player,aim,str(move.pattern),int(move.reach),true)
		if target<0 or not response_footprint.has(p):continue
		if not roll_reference_hit(move,enemies[target]):continue
		var response_enemy:Dictionary=enemies[target].duplicate()
		var response_uid:int=int(response_enemy.get("uid",-1))
		var damage_index:int=last_move_damage.size()
		strike(target,true,-1,chosen)
		player_attack_fx=chosen
		player_attack_path=response_footprint[p].duplicate()
		if last_move_damage.size()>damage_index:
			visual_record_response(response_enemy,int(last_move_damage[damage_index]),"sleep_counter",attack_serial,chosen)
			var recorded:Array=visual_response_events.get(response_uid,[])
			if not recorded.is_empty() and int(recorded[-1].get("cast_serial",-1))==attack_serial:
				recorded[-1]["from"]=player
				recorded[-1]["to"]=p
				recorded[-1]["path"]=player_attack_path.duplicate()
		visual_response_cast_serial=attack_serial
		visual_response_cast_uid=response_uid
		if chosen=="eos_025" and enemy_at(p)>=0 and rng.randi_range(1,100)<=20:
			enemies[enemy_at(p)]["paused_turns"]=1
		emit_event("Sleep counter · "+str(move.name))
	sleep_reactions.clear()
var bide_damage:int=0
var bide_aim:Vector2i=Vector2i.UP
var bide_move_id:String=""
var pending_throws:Dictionary={}
func record_reactive_hit(target:Vector2i,damage:int)->void:
	if damage<=0:return
	if boon_active("nap"):sleep_reactions.append(target)
	if boon_active("bide"):bide_damage+=damage
	if boon_active("rage"):player_stages["attack"]=mini(10,int(player_stages.get("attack",0))+1)
	if boon_active("vital_throw") and maxi(absi(target.x-player.x),absi(target.y-player.y))<=1:pending_throws[target]=true
func flush_throws()->void:
	for p in pending_throws:
		var i:int=enemy_at(p)
		if i<0:continue
		var choices:Array[Vector2i]=[]
		for q in cells:
			if q!=player and enemy_at(q)<0 and maxi(absi(q.x-player.x),absi(q.y-player.y))<=3:choices.append(q)
		if choices.is_empty():continue
		choices.sort_custom(func(a,b):return a.x<b.x or (a.x==b.x and a.y<b.y))
		enemies[i].pos=choices[rng.randi_range(0,choices.size()-1)]
		enemies[i]["windup"]=false
		enemies[i].erase("stuck_turns")
	pending_throws.clear()
func finish_bide()->void:
	var target:Vector2i=player+bide_aim
	var i:int=enemy_at(target)
	var dealt:int=0
	if i>=0 and bide_damage>0:dealt=deal_special_damage(i,bide_damage*2)
	last_move_damage.clear();last_move_damage.append(dealt)
	last_move_attempts=1;last_move_hits=1 if dealt>0 else 0
	attack_serial+=1;attack_target=target;attack_power=true;player_attack_fx=bide_move_id
	player_attack_cells=[target];player_attack_path=[target]
	message="Stored retort · −%d HP"%dealt;emit_event(message)
	bide_damage=0;bide_move_id=""
func reveal_defender_types(element:String,types:Array,target:Dictionary)->Array:
	var result:Array=types.duplicate()
	if element in ["normal","fighting"] and target.get("exposed",false):result.erase("ghost")
	if element=="psychic" and target.get("miracle_eye",false):result.erase("dark")
	return result
var ingrain_age:int=0
var self_confusion_turns:int=0
func clear_negative_conditions()->void:
	poison_turns=0;weakened_strikes=0;marked_damage=0;self_confusion_turns=0
func player_wait_if_napping()->bool:
	if not finished and boon_active("hostile_sleep"):
		message="Asleep";enemy_turn();return true
	if finished or not (boon_active("nap") or boon_active("bide") or boon_active("wrapping")):return false
	message="Storing damage" if boon_active("bide") else "Binding target" if boon_active("wrapping") else "Resting"
	enemy_turn();return true
func confused_direction(aim:Vector2i)->Vector2i:
	if self_confusion_turns<=0:return aim
	return DIR8[rng.randi_range(0,DIR8.size()-1)]
var wish_fraction:float=0.0
var aqua_age:int=0
var last_critical_hits:int=0
var last_enemy_critical:bool=false
func boon_active(id:String)->bool:
	return int(player_boons.get(id,0))>0
func apply_player_boon(move:Dictionary)->bool:
	var id:String=str(move.boon_kind)
	if id=="cure":
		var changed:bool=poison_turns>0 or weakened_strikes>0 or marked_damage>0 or self_confusion_turns>0
		clear_negative_conditions()
		return changed
	if boon_active(id) or (id=="nap" and boon_active("sleepless")) or (id=="magnet" and gravity_active):return false
	if id in ["sure","focus","set_damage"]:
		for state in ["sure","focus","set_damage"]:player_boons.erase(state)
	if id=="sleepless":player_boons.erase("nap")
	player_boons[id]=rng.randi_range(int(move.boon_min),int(move.boon_max))
	if id=="wish":wish_fraction=0.0
	if id=="aqua":aqua_age=0
	if id=="ingrain":ingrain_age=0
	if id=="bide":bide_damage=0
	return true
func tick_player_boons()->void:
	if int(player_boons.get("hostile_drowse",0))==1:
		if not boon_active("sleepless") and not player_has_ability("wakeful"):player_boons["hostile_sleep"]=rng.randi_range(3,6)+1
	if boon_active("bide") and int(player_boons.bide)==1:finish_bide()
	if self_confusion_turns>0:self_confusion_turns-=1
	if boon_active("ingrain"):
		ingrain_age+=1
		if ingrain_age>=2 and (ingrain_age-2)%5==0:hp=mini(max_hp,hp+10)
	if boon_active("nap") and int(player_boons.nap)==1:
		hp=max_hp;clear_negative_conditions();emit_event("Rest complete")
	if boon_active("aqua"):
		aqua_age+=1
		if aqua_age%4==0:hp=mini(max_hp,hp+8)
	if boon_active("wish"):
		wish_fraction+=float(max_hp)*.033
		var whole:int=floori(wish_fraction)
		wish_fraction-=float(whole)
		hp=mini(max_hp,hp+whole)
	for id in player_boons.keys():
		if id in ["sleepless","grudge"]:continue
		player_boons[id]=int(player_boons[id])-1
		if int(player_boons[id])<=0:player_boons.erase(id)
	if not boon_active("wish"):wish_fraction=0.0
	if not boon_active("adapt"):adaptive_type=""
static func critical_damage(damage:int,critical:bool)->int:
	return floori(float(damage)*1.5) if critical else damage
func roll_player_critical(move:Dictionary,target:Dictionary)->bool:
	if target.get("critical_immune",false) or enemy_has_ability(target,"critical_shell") or int(target.get("lucky_turns",0))>0:return false
	if boon_active("focus"):return true
	# Legacy untrained test/sandbox combat does not have a reference profile.
	if trained_profile.is_empty() or move.is_empty():return false
	return rng.randi_range(1,100)<=clampi(int(move.get("reference_crit",8)),0,100)
func roll_enemy_critical(base_rate:int)->bool:
	if boon_active("lucky") or player_has_ability("critical_shell") or trained_profile.is_empty():return false
	return rng.randi_range(1,100)<=clampi(base_rate,0,100)
func boon_summary()->String:
	var parts:PackedStringArray=[]
	for id in player_boons:parts.append("Sleepless" if id=="sleepless" else "%s %d"%[str(id).capitalize(),player_boons[id]])
	if self_confusion_turns>0:parts.append("Confused %d"%self_confusion_turns)
	return " · ".join(parts)
var shield_turns:int=0
var counter_damage:Dictionary={}
var linked_damage:int=0
var last_counter_damage:int=0
func activate_shield(move:Dictionary)->bool:
	var kind:String=str(move.shield_kind)
	if kind==shield_kind and kind=="counter" and shield_turns>0:return false
	shield_kind=kind
	shield_turns=rng.randi_range(int(move.shield_min),int(move.shield_max))
	return true
func shield_damage(raw:int,category:String)->int:
	var damage:int=maxi(0,raw)
	if shield_turns<=0:return damage
	if shield_kind=="protect":return 0
	if (shield_kind=="reflect" and category=="physical") or (shield_kind=="screen" and category=="special"):
		return maxi(1,floori(float(damage)*.5)) if damage>0 else 0
	if shield_kind=="endure":return mini(damage,maxi(0,hp-1))
	return damage
func opposite_combat_gender(enemy:Dictionary)->bool:
	# Explicit profile values override deterministic legacy defaults.
	var own:String=str(trained_profile.get("gender","male" if skill_kind%2==0 else "female")).to_lower()
	var other:String=str(enemy.get("gender","male" if int(enemy.get("uid",0))%2==0 else "female")).to_lower()
	return own in ["male","female"] and other in ["male","female"] and own!=other

func apply_bond_control(i:int,rule:String)->bool:
	if i<0 or i>=enemies.size():return false
	var e:Dictionary=enemies[i]
	if rule=="destiny_link":
		if int(e.get("destiny_turns",0))>0:return false
		e["destiny_turns"]=11
		return true
	if not opposite_combat_gender(e):return false
	if rule=="infatuation":
		if e.get("infatuation_immune",false) or enemy_has_ability(e,"steady_heart") or int(e.get("infatuated_turns",0))>0:return false
		e["infatuated_turns"]=rng.randi_range(5,6);e["windup"]=false
		return true
	if rule=="captivate":
		if not e.has("stages"):e["stages"]={}
		if not e.has("stat_halves"):e["stat_halves"]={}
		return apply_stat_changes(e.stages,e.stat_halves,{"stat_changes":{"sp_attack":-2}})
	return false

func queue_linked_damage(damage:int)->void:
	if damage<=0:return
	for e in enemies:
		if int(e.get("destiny_turns",0))>0:
			linked_damage+=damage
			return

func flush_linked_damage()->void:
	if linked_damage<=0:return
	var amount:int=linked_damage
	linked_damage=0
	for i in range(enemies.size()-1,-1,-1):
		if int(enemies[i].get("destiny_turns",0))<=0:continue
		var dealt:int=mini(amount,int(enemies[i].hp))
		enemies[i].hp=int(enemies[i].hp)-dealt
		if dealt>0:emit_event("Fate Link −%d HP"%dealt)
		if int(enemies[i].hp)<=0:remove_defeated_enemy(i)

func queue_counter(target:Vector2i,damage:int,category:String)->void:
	queue_linked_damage(damage)
	if damage>0 and hp>0:record_reactive_hit(target,damage)
	if damage<=0 or shield_turns<=0 or hp<=0:return
	if (shield_kind=="counter" and category=="physical") or (shield_kind=="mirror" and category=="special"):
		if maxi(absi(target.x-player.x),absi(target.y-player.y))<=1:
			counter_damage[target]=int(counter_damage.get(target,0))+damage
	elif shield_kind=="metal":
		var amount:int=maxi(1,floori(float(damage)*.5))
		for e in enemies:
			var p:Vector2i=e.pos
			if maxi(absi(p.x-player.x),absi(p.y-player.y))<=1:
				counter_damage[p]=int(counter_damage.get(p,0))+amount
func flush_counters()->void:
	for p in counter_damage:
		var i:int=enemy_at(p)
		if i<0:continue
		var amount:int=mini(int(enemies[i].hp),int(counter_damage[p]))
		enemies[i].hp=int(enemies[i].hp)-amount
		last_counter_damage+=amount
		if int(enemies[i].hp)<=0:remove_defeated_enemy(i)
	counter_damage.clear()
	if last_counter_damage>0:message+=" · Rebound −%d HP"%last_counter_damage;emit_event("Rebound −%d HP"%last_counter_damage)
var travel_boosts:Array[int]=[]
var travel_steps_used:int=0
var travel_refresh:bool=false
var player_halves:Dictionary={}
const STAGE_NUMERATORS={
	"attack":[128,133,138,143,148,153,161,171,179,204,256,307,332,358,384,409,422,435,448,460,473],
	"defense":[7,12,25,38,51,64,76,102,128,179,256,332,409,486,537,588,640,691,742,793,844],
	"accuracy":[84,89,94,102,110,115,140,153,179,204,256,320,384,409,422,435,448,460,473,486,512],
	"evasion":[512,486,473,460,448,435,422,409,384,345,263,204,179,153,128,102,89,76,64,51,38]
}
static func stage_factor(stat:String,stage:int)->float:
	var group:String=stat.trim_prefix("sp_")
	return float(STAGE_NUMERATORS[group][clampi(stage,-10,10)+10])/256.0
static func stat_effect(stages:Dictionary,halves:Dictionary,stat:String)->float:
	return stage_factor(stat,int(stages.get(stat,0)))*pow(.5,int(halves.get(stat,0)))
static func apply_stat_changes(stages:Dictionary,halves:Dictionary,move:Dictionary)->bool:
	var changed:bool=false
	var deltas:Dictionary=move.get("stat_changes",{})
	for stat in deltas:
		var before:int=int(stages.get(stat,0))
		var after:int=clampi(before+int(deltas[stat]),-10,10)
		if after!=before:stages[stat]=after;changed=true
	var reductions:Dictionary=move.get("stat_halves",{})
	for stat in reductions:
		var before:int=int(halves.get(stat,0))
		var after:int=clampi(before+int(reductions[stat]),0,7)
		if after!=before:halves[stat]=after;changed=true
	return changed
func enemy_stat_effect(enemy:Dictionary,stat:String)->float:
	return stat_effect(enemy.get("stages",{}),enemy.get("stat_halves",{}),stat)
func player_stat_effect(stat:String)->float:
	if stat=="defense" and not charged_move_id.is_empty() and MOVE_LIBRARY[charged_move_id].get("charge_defense",false):
		return stage_factor(stat,int(player_stages.get(stat,0))+1)*pow(.5,int(player_halves.get(stat,0)))
	return stat_effect(player_stages,player_halves,stat)
func travel_speed()->int:
	return 1+travel_boosts.size()
func add_travel_speed(amount:int)->bool:
	var before:int=travel_boosts.size()
	for i in range(amount):
		if travel_boosts.size()<3:travel_boosts.append(rng.randi_range(4,5))
	return travel_boosts.size()>before
func slow_enemy(enemy:Dictionary)->bool:
	if int(enemy.get("slow_turns",0))>0:return false
	enemy["slow_turns"]=rng.randi_range(3,4)*2
	return true
func reset_room_stats()->void:
	player_stages.clear();player_halves.clear()
	var affected:Dictionary=attack_footprint(player,Vector2i.UP,"room",0,true)
	for e in enemies:
		if affected.has(e.pos):
			e.erase("stages");e.erase("stat_halves")
func stage_summary(stages:Dictionary,halves:Dictionary)->String:
	var parts:PackedStringArray=[]
	var labels:Dictionary={"attack":"ATK","defense":"DEF","sp_attack":"SPA","sp_defense":"SPD","accuracy":"ACC","evasion":"EVA"}
	for stat in labels:
		var stage:int=int(stages.get(stat,0))
		if stage!=0:parts.append("%s%+d"%[labels[stat],stage])
		var half:int=int(halves.get(stat,0))
		if half>0:parts.append("%s÷%d"%[labels[stat],1<<half])
	return " ".join(parts)
var charged_move_id:String=""
var charged_aim:Vector2i=Vector2i.ZERO
var charge_phase:String=""
var last_move_damage:Array[int]=[]
var speed_meter:float=0.0
var earned_ev:Array=[0,0,0,0,0,0]
var last_type_multiplier:float=1.0
static func type_multiplier(move_type:String,defender_types:Array,mode:String="explorers")->float:
	if not TYPE_CHART.has(move_type):return 1.0
	var matchups:Array=TYPE_CHART[move_type]
	var factor:float=1.0
	var seen:Dictionary={}
	for element in defender_types:
		if seen.has(element):continue
		seen[element]=true
		if element in matchups[2]:factor*=.5 if mode=="explorers" else 0.0
		elif element in matchups[0]:factor*=1.4 if mode=="explorers" else 2.0
		elif element in matchups[1]:factor*=.7 if mode=="explorers" else .5
	return factor
static func nature_pair(nature_id:int)->Array:
	if nature_id<0 or nature_id>=NATURE_PAIRS.size():return [-1,-1]
	return NATURE_PAIRS[nature_id].duplicate()
static func nature_factor(nature_id:int,stat:int)->float:
	if stat==0:return 1.0
	var pair:=nature_pair(nature_id)
	return 1.1 if stat==int(pair[0]) else .9 if stat==int(pair[1]) else 1.0
static func nature_summary(nature_id:int)->String:
	var pair:=nature_pair(nature_id)
	if int(pair[0])<0:return "Balanced · no stat changes"
	return "+10% "+STAT_NAMES[pair[0]]+" / −10% "+STAT_NAMES[pair[1]]
# Unrounded combat values ensure modifiers matter even at early levels.
static func combat_stat_value(level:int,ev:Array,nature_id:int,stat:int)->float:
	var base:Array=[45,48,48,54,50,52]
	var lv:int=clampi(level,1,100)
	var trained:float=(2.0*float(base[stat])+float(int(int(ev[stat])/4.0)))*lv/100.0
	return trained+lv+10.0 if stat==0 else (trained+5.0)*nature_factor(nature_id,stat)
func combat_stat(stat:int)->float:
	return combat_stat_value(int(trained_profile.get("level",1)),trained_profile.get("ev",[0,0,0,0,0,0]),int(trained_profile.get("nature",0)),stat)
func neutral_combat_stat(stat:int)->float:
	return combat_stat_value(int(trained_profile.get("level",1)),[0,0,0,0,0,0],0,stat)
# Original Kindria speed rule: deterministic evasion meter, no skipped turns.
func speed_evasion_rate()->float:
	if trained_profile.is_empty():return 0.0
	return clampf(.10*combat_stat(5)/neutral_combat_stat(5),.04,.25)
func speed_evade()->bool:
	if trained_profile.is_empty():return false
	speed_meter+=speed_evasion_rate()
	if speed_meter+.000001<1.0:return false
	speed_meter=maxf(0.0,speed_meter-1.0);return true
static func normalized_ev(values:Array,limit:int=EV_TOTAL_CAP)->Array:
	var result:Array=[0,0,0,0,0,0]
	var remaining:int=limit
	for i in range(mini(6,values.size())):
		if not (values[i] is int or values[i] is float) or not is_finite(float(values[i])):continue
		result[i]=clampi(int(values[i]),0,mini(EV_STAT_CAP,remaining))
		remaining-=int(result[i])
	return result
static func stat_value(base:int,level:int,ev:int,nature_id:int,stat:int)->int:
	var lv:int=clampi(level,1,100)
	var trained:int=int((2*base+int(clampi(ev,0,EV_STAT_CAP)/4.0))*lv/100.0)
	if stat==0:return trained+lv+10
	return floori(float(trained+5)*nature_factor(nature_id,stat))
static func make_pet_stats(level:int,ev:Array,nature_id:int)->Array:
	var base:Array=[45,48,48,54,50,52]
	var out:Array=[]
	for i in range(6):out.append(stat_value(base[i],level,int(ev[i]),nature_id,i))
	return out
func normalized_abilities(values:Array)->Array[String]:
	var result:Array[String]=[]
	for value in values:
		var id:String=str(value)
		if id in PASSIVE_ABILITIES and not id in result:result.append(id)
		if result.size()>=2:break
	return result

func enemy_abilities(e:Dictionary)->Array[String]:
	return normalized_abilities(e.get("abilities",[]))

func enemy_has_ability(e:Dictionary,id:String)->bool:
	return int(e.get("ability_suppressed_turns",0))<=0 and id in enemy_abilities(e)

func player_has_ability(id:String)->bool:
	return not boon_active("ability_suppressed") and id in player_abilities

func apply_ability_rule(i:int,rule:String)->bool:
	if i<0 or i>=enemies.size():return false
	var e:Dictionary=enemies[i]
	if e.get("ability_locked",false):return false
	var other:Array[String]=enemy_abilities(e)
	if rule=="suppress_ability":
		if other.is_empty() or int(e.get("ability_suppressed_turns",0))>0:return false
		e["ability_suppressed_turns"]=rng.randi_range(6,8)
		return true
	if other.is_empty():return false
	if rule=="swap_ability":
		e["abilities"]=player_abilities.duplicate()
		player_abilities=other
		return true
	if rule=="copy_ability":
		player_abilities=other.duplicate()
		return true
	return false

func configure_training(profile:Dictionary)->void:
	trained_profile=profile.duplicate(true)
	player_base_abilities=normalized_abilities(profile.get("abilities",[]))
	player_abilities=player_base_abilities.duplicate()
	if profile.has("held_item"):
		var requested:String=str(profile.held_item)
		if requested in ["","ward_band","force_band"]:held_item=requested
	speed_meter=0.0
	equipped_moves.clear();move_pp.clear()
	var learned:=available_moves(profile.get("types",[]),int(profile.get("level",1)))
	for id in profile.get("moves",[]):
		if id in learned and not id in equipped_moves and equipped_moves.size()<4:
			equipped_moves.append(id);move_pp[id]=int(MOVE_LIBRARY[id].pp)
	configure_allies(profile.get("party",[]))
	var stats:Array=trained_profile.get("stats",[])
	if stats.size()==6:
		var bonus:int=mini(35,maxi(0,int(stats[0])-int(make_pet_stats(int(profile.get("level",1)),[0,0,0,0,0,0],0)[0])))
		max_hp+=bonus;hp=max_hp
func trained_damage(raw:int,move_type:String,attacker_types:Array,defender_types:Array,attack_stat:float,defense_stat:float,_neutral_stat:float)->int:
	last_type_multiplier=type_multiplier(move_type,defender_types)
	if last_type_multiplier<=0.0:return 0
	var stab:float=1.2 if move_type in attacker_types else 1.0
	var ratio:float=clampf(maxf(1.0,attack_stat)/maxf(1.0,defense_stat),.60,1.65)
	return maxi(1,roundi(float(raw)*last_type_multiplier*stab*ratio))
func gain_enemy_ev(enemy:Dictionary)->void:
	var profile:Array=ENEMY_TRAINING.get(enemy.get("species",""),[])
	if profile.is_empty():return
	var index:int=int(profile[3]);earned_ev[index]=mini(510,int(earned_ev[index])+int(profile[4]))

var enemy_actions:Array[Dictionary]=[]
var player_attack_fx:String="basic_strike"
var player_attack_cells:Array[Vector2i]=[]
# Presentation-only strike counts for the most recent resolved reference move.
var player_visual_hits:Dictionary={}
var player_visual_hit_serial:int=-1
# Net HP losses during the response turn, separate from the initiating cast.
var visual_turn_damage:Dictionary={}
var visual_turn_damage_turn:int=-1
var visual_response_events:Dictionary={}
var visual_response_active:bool=false
var visual_response_cast_serial:int=-1
var visual_response_cast_uid:int=-1
func visual_record_response(enemy:Dictionary,amount:int,source:String,cast_serial:int=-1,move_id:String="")->void:
	if not visual_response_active:return
	var uid:int=int(enemy.get("uid",-1))
	var dealt:int=mini(maxi(0,int(enemy.hp)),maxi(0,amount))
	if uid<0 or dealt<=0:return
	if not visual_response_events.has(uid):visual_response_events[uid]=[]
	visual_response_events[uid].append({"source":source,"amount":dealt,"cast_serial":cast_serial,"move_id":move_id})

func visual_record_stage(before:Dictionary,source:String)->void:
	var losses:Dictionary=visual_hp_losses(before,visual_enemy_hp_snapshot())
	for uid in losses:
		if not visual_response_events.has(uid):visual_response_events[uid]=[]
		visual_response_events[uid].append({"source":source,"amount":int(losses[uid].before)-int(losses[uid].after)})
func visual_enemy_hp_snapshot()->Dictionary:
	var snapshot:Dictionary={}
	for enemy in enemies:
		var uid:int=int(enemy.get("uid",-1))
		if uid>=0:snapshot[uid]=maxi(0,int(enemy.hp))
	return snapshot

static func visual_hp_losses(before:Dictionary,after:Dictionary)->Dictionary:
	var result:Dictionary={}
	for uid in before:
		var start:int=int(before[uid])
		var end:int=int(after.get(uid,0))
		if end<start:result[uid]={"before":start,"after":end,"removed":not after.has(uid)}
	return result
# A footprint maps each legal target to its exact unobstructed travel path.
func attack_footprint(origin:Vector2i,forward:Vector2i,pattern:String,reach:int,player_cast:bool=false)->Dictionary:
	var out:Dictionary={}
	var directions:Array=[forward]
	if pattern in ["radius","cross"]:directions=DIR
	if pattern=="radius" and reach==1:
		for dx in range(-1,2):
			for dy in range(-1,2):
				var q:=origin+Vector2i(dx,dy)
				if q!=origin and cells.has(q):out[q]=[q]
		return out
	if pattern=="floor":
		for e in enemies:out[e.pos]=[e.pos]
		return out
	if pattern=="front":reach=1
	if pattern=="room":
		for room in rooms:
			if room.has_point(origin):
				for q in cells:
					if q!=origin and room.has_point(q):out[q]=[q]
				return out
		return out
	if pattern in ["fan","corner"] and forward.x!=0 and forward.y!=0:
		# Three octant rays: center and the two neighboring headings. No rotated two-tile jumps.
		for d in [forward,Vector2i(forward.x,0),Vector2i(0,forward.y)]:
			var ray:Array[Vector2i]=[]
			for i in range(1,reach+1):
				var p:Vector2i=origin+d*i
				if not step_clear(p-d,d):break
				var occupied:bool=enemy_at(p)>=0
				if occupied and not player_cast:break
				ray.append(p);out[p]=ray.duplicate()
				if occupied:break
		return out
	if pattern=="corner_front" and forward.x!=0 and forward.y!=0:
		for d in [forward,Vector2i(forward.x,0),Vector2i(0,forward.y)]:
			if step_clear(origin,d,true):out[origin+d]=[origin+d]
		return out
	if pattern=="corner_front":
		var q:=origin+forward
		if cells.has(q):out[q]=[q]
		for side in [-1,1]:
			var lateral:=Vector2i(-forward.y,forward.x)*int(side)
			var diagonal:=q+lateral
			if cells.has(diagonal) and (cells.has(q) or cells.has(origin+lateral)):out[diagonal]=[diagonal]
		return out
	for d in directions:
		var path:Array[Vector2i]=[]
		for distance_index in range(1,reach+1):
			var q:Vector2i=origin+d*distance_index
			if not step_clear(q-d,d):break
			var occupied:bool=enemy_at(q)>=0
			if occupied and not player_cast:break
			path.append(q)
			out[q]=path.duplicate()
			if occupied:break
			if pattern in ["corner","fan","radius"]:
				for sign_side in [-1,1]:
					var turn:=Vector2i(-d.y,d.x)*int(sign_side)
					var branch:Array[Vector2i]=path.duplicate()
					var limit:int=reach-distance_index if pattern!="fan" else mini(1,reach-distance_index+1)
					for j in range(1,limit+1):
						var target:=q+turn*j
						if not cells.has(target):break
						var branch_occupied:bool=enemy_at(target)>=0
						if branch_occupied and not player_cast:break
						# Fan can hit front diagonals, but not through two blocked orthogonal cells.
						branch.append(target)
						if not out.has(target) or branch.size()<out[target].size():out[target]=branch.duplicate()
						if branch_occupied:break
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
	player_stages.clear();player_halves.clear();charge_power_turns=0;last_invoked_move="";transformed_species=""
	stockpile_count=0;active_reserve_multiplier=0;magnitude_damage=0;roost_active=false
	travel_boosts.clear();travel_steps_used=0;travel_refresh=false
	shield_kind="";shield_turns=0;counter_damage.clear();last_counter_damage=0;linked_damage=0
	floor_weather="clear";weather_age=0;floor_sports.clear();gravity_active=false
	temporary_type="";adaptive_type="";player_slow_turns=0
	player_boons.clear();player_abilities=player_base_abilities.duplicate();wish_fraction=0.0;last_critical_hits=0;last_enemy_critical=false
	ingrain_age=0;self_confusion_turns=0
	bide_damage=0;bide_move_id="";pending_throws.clear();sleep_reactions.clear();wrap_target=Vector2i.ZERO
	clear_charge()
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
		"poison":
			if not player_has_ability("clear_blood") and (shield_kind!="safeguard" or shield_turns<=0):poison_turns=maxi(poison_turns,amount)
		"weaken":
			if not boon_active("mist") and (shield_kind!="safeguard" or shield_turns<=0):weakened_strikes=maxi(weakened_strikes,amount)
		"mark":
			if shield_kind!="safeguard" or shield_turns<=0:marked_damage=maxi(marked_damage,amount)
		"drain":energy=maxi(0,energy-amount)
		"guard":enemies[i]["guard"]=amount
		"pounce":
			var from:Vector2i=enemies[i].pos
			if int(enemies[i].get("stuck_turns",0))<=0 and distance(from,player)==2 and (from.x==player.x or from.y==player.y):
				var q:=from+Vector2i(signi(player.x-from.x),signi(player.y-from.y))
				if cells.has(q) and enemy_at(q)<0 and q!=player:enemies[i].pos=q

func enemy_profile(kind:int,uid:int)->Array:
	var pool:Array=[]
	for row in MINION_ROSTER[clampi(region,0,2)]:
		if int(row[4])==kind:pool.append(row)
	return pool[posmod(seed_value+floor_number*3+uid*5,pool.size())]
func make_enemy(p:Vector2i,life:int,kind:int,uid:int)->Dictionary:
	var profile:=enemy_profile(kind,uid)
	var e:Dictionary={"uid":uid,"pos":p,"hp":life,"max_hp":life,"kind":kind,"windup":false,"species":profile[0],"name":profile[1],"gait":profile[2],"signature":profile[3]}
	# Deterministic allocation: does not perturb the seeded floor RNG.
	if SPECIES_ABILITIES.has(profile[0]):e["abilities"]=normalized_abilities(SPECIES_ABILITIES[profile[0]])
	if kind!=3 and posmod(seed_value+floor_number+uid,3)==0:e["held_item"]="force_band" if uid%2==0 else "ward_band"
	if kind!=3 and posmod(seed_value+uid,5)==0:e["item_potions"]=1
	return e
var rng=RandomNumberGenerator.new()
var region=0
var floor_number=1
var floor_count=3
var tier=0
var player=Vector2i.ZERO
var stairs=Vector2i.ZERO
var relic=Vector2i.ZERO
var cells:Dictionary={}
var floor_bounds:Rect2i=Rect2i(1,1,34,25)
var rooms:Array[Rect2i]=[]
var enemies:Array[Dictionary]=[]
var loot:Dictionary={}
var revealed:Dictionary={}
var dev_sandbox:bool=false
var hp=36:
	set(value):
		hp=maxi(1,int(value)) if dev_sandbox else value
var max_hp=36
var potions=2
var held_item:String=""
var spare_equipment:Array[String]=[]
var energy=8
# Integer tenths avoid accumulating floating-point hunger error.
var belly_tenths:int=1000
var technique_manuals:Dictionary={}
var spent_manuals:Dictionary={}
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
var player_traps:Dictionary={}
var revealed_player_traps:Dictionary={}
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
	allies.clear()
	held_item="ward_band";spare_equipment.clear()
	belly_tenths=1000;technique_manuals.clear();spent_manuals.clear()
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
	floor_bounds=Rect2i(Vector2i.ONE,grid*9-Vector2i(2,2))
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
func reset_floor_combat_presentation()->void:
	# Enemy UIDs are local to the floor. Never reuse a previous floor's visual ledger.
	visual_turn_damage.clear();visual_turn_damage_turn=-1
	visual_response_events.clear();visual_response_active=false
	visual_response_cast_serial=-1;visual_response_cast_uid=-1
	player_visual_hits.clear();player_visual_hit_serial=-1
	enemy_actions.clear()
	player_attack_cells.clear();player_attack_path.clear()

func generate_floor():
	clear_combat_effects()
	reset_floor_combat_presentation()
	rng.seed=seed_value+floor_number*7919
	initialize_hidden_power(seed_value)
	cells.clear();rooms.clear();enemies.clear();loot.clear();revealed.clear();traps.clear();player_traps.clear();revealed_player_traps.clear();explored_rooms.clear()
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
			var life=8+(mini(floor_number,30) if dev_sandbox else floor_number)*2+tier*2
			enemies.append(make_enemy(p,life,rng.randi_range(0,2),enemies.size()))
		elif loot.size()<(14 if floor_kind==1 else 9):
			loot[p]="trail_fruit" if loot.size()==2 else "manual:eos_154" if loot.size()==5 else "potion" if loot.size()%4==0 else "material" if loot.size()%3==0 else "coin"
		elif traps.size()<(mini(12,floor_number-1) if dev_sandbox else floor_number-1):traps[p]=true
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
	place_allies()
	reveal()
	message="Guardian chamber · Rescue the creature" if not guardian_defeated else "B%d · Find the relic and stairs"%floor_number
func ally_at(p:Vector2i)->int:
	for i in range(allies.size()):
		if int(allies[i].hp)>0 and allies[i].pos==p:return i
	return -1

func free_party_tile(q:Vector2i)->bool:
	return cells.has(q) and q!=player and enemy_at(q)<0 and ally_at(q)<0 and not traps.has(q)

func place_allies()->void:
	for a in allies:a["pos"]=Vector2i(-999,-999);a["stages"]={};a["status"]={}
	rally_allies()

func configure_allies(profiles:Array)->void:
	allies.clear()
	for profile in profiles:
		if not profile is Dictionary:continue
		var species:String=str(profile.get("species",""))
		if not ENEMY_TRAINING.has(species):continue
		var cap:int=clampi(int(profile.get("max_hp",24)),1,999)
		var moves:Array[String]=[]
		var pp:Dictionary={}
		for value in profile.get("moves",[]):
			var id:String=str(value)
			if MOVE_LIBRARY.has(id) and id not in moves and moves.size()<4:
				moves.append(id);pp[id]=int(MOVE_LIBRARY[id].pp)
		allies.append({"uid":1000+allies.size(),"species":species,"pos":Vector2i(-999,-999),"hp":cap,"max_hp":cap,"moves":moves,"pp":pp,"stages":{},"status":{}})
		if allies.size()>=3:break
	place_allies()

func same_party_room(q:Vector2i)->bool:
	for room in rooms:
		if room.has_point(player):return room.has_point(q)
	return distance(player,q)<=1

func rally_allies()->int:
	var candidates:Array[Vector2i]=[]
	for q in cells:
		if distance(player,q)<=3 and free_party_tile(q):candidates.append(q)
	candidates.sort_custom(func(a,b):return distance(player,a)<distance(player,b))
	var count:int=0
	for a in allies:
		if int(a.hp)<=0 or candidates.is_empty():continue
		a.pos=candidates.pop_front();count+=1
	return count

func party_support(rule:String)->int:
	if rule=="party_rally":return rally_allies()
	if rule=="leader_decoy":
		if boon_active("decoy"):return 0
		for e in enemies:e.erase("decoy_turns")
		player_boons["decoy"]=rng.randi_range(21,50)
		return 1
	var count:int=0
	for a in allies:
		if int(a.hp)<=0 or not same_party_room(a.pos):continue
		if rule=="party_boost":
			for key in ["attack","sp_attack"]:a.stages[key]=mini(10,int(a.stages.get(key,0))+1)
		else:
			a.hp=int(a.max_hp);a.status.clear()
			if rule=="party_renew":
				for id in a.moves:a.pp[id]=int(MOVE_LIBRARY[id].pp)
		count+=1
	if count>0 and rule in ["party_heal","party_renew"]:hp=1
	return count

func floor_assist_candidates()->Array[String]:
	var pool:Array[String]=[]
	for id in equipped_moves:
		if copy_eligible(id):pool.append(id)
	for a in allies:
		if int(a.hp)<=0:continue
		for id in a.moves:
			if copy_eligible(id):pool.append(id)
	for e in enemies:
		for slot in ["primary","secondary","support"]:
			var id:String=enemy_catalog_move(e,slot)
			if copy_eligible(id):pool.append(id)
	return pool

func ally_turn_actions()->void:
	for a in allies:
		if int(a.hp)<=0 or not cells.has(a.pos):continue
		var origin:Vector2i=a.pos
		var target:int=-1
		for i in range(enemies.size()):
			if int(enemies[i].get("decoy_turns",0))>0:continue
			if distance(origin,enemies[i].pos)==1:target=i;break
		if target>=0:
			var chosen:String=""
			for id in a.moves:
				var m:Dictionary=MOVE_LIBRARY[id]
				if copy_eligible(id) and int(m.power)>0 and int(a.pp.get(id,0))>0 and str(m.category)!="status":
					chosen=id;break
			var raw:int=3
			var key:String="attack"
			if not chosen.is_empty():
				a.pp[chosen]=int(a.pp[chosen])-1
				var m:Dictionary=MOVE_LIBRARY[chosen]
				raw=maxi(1,int(m.power))
				key="sp_attack" if m.category=="special" else "attack"
			var damage:int=maxi(1,roundi(float(raw)*stage_factor(key,int(a.stages.get(key,0)))))
			deal_special_damage(target,damage)
			continue
		if distance(origin,player)>1:
			var path:Array[Vector2i]=route(origin,player,true)
			if not path.is_empty() and free_party_tile(path[0]):a.pos=path[0]

func enemy_target_ally(i:int)->bool:
	if boon_active("decoy"):return false
	var e:Dictionary=enemies[i]
	var origin:Vector2i=e.pos
	var nearest:int=-1
	var best:int=distance(origin,player)
	for j in range(allies.size()):
		if int(allies[j].hp)<=0:continue
		var gap:int=distance(origin,allies[j].pos)
		if gap<best and gap<=6:nearest=j;best=gap
	if nearest<0:return false
	var a:Dictionary=allies[nearest]
	e["windup"]=false
	if best==1:
		var damage:int=mini(int(a.hp),maxi(1,2+tier))
		a.hp=int(a.hp)-damage
		enemy_actions.append({"uid":e.get("uid",i),"phase":"attack","from":origin,"to":a.pos,"move":"Ally strike","fx":"basic_strike","damage":damage,"tiles":[a.pos],"path":[a.pos]})
		emit_event("Ally struck −%d HP"%damage)
		return true
	var path:Array[Vector2i]=route(origin,a.pos,true)
	if not path.is_empty() and free_party_tile(path[0]) and int(e.get("stuck_turns",0))<=0:
		e.pos=path[0]
		enemy_actions.append({"uid":e.get("uid",i),"phase":"move","from":origin,"to":e.pos,"gait":e.get("gait","walk")})
		return true
	return false

func enemy_at(p:Vector2i)->int:
	for i in range(enemies.size()):
		if enemies[i].pos==p:return i
	return -1
func route(a:Vector2i,b:Vector2i,avoid_enemies:bool=false,diagonal:bool=false)->Array[Vector2i]:
	var result:Array[Vector2i]=[]
	if not cells.has(a) or not cells.has(b) or a==b:return result
	var queue:Array[Vector2i]=[a]
	var previous:Dictionary={}
	previous[a]=a
	var cursor=0
	while cursor<queue.size():
		var p=queue[cursor];cursor+=1
		if p==b:break
		for d in DIR8 if diagonal else DIR:
			var q:Vector2i=p+d
			if not step_clear(p,d) or previous.has(q):continue
			if avoid_enemies and q!=b and (enemy_at(q)>=0 or ally_at(q)>=0):continue
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
func held_item_damage(amount:int,attacker_item:String,defender_item:String)->int:
	if amount<=0:return 0
	return maxi(1,amount+(1 if attacker_item=="force_band" else 0)-(1 if defender_item=="ward_band" else 0))

func drop_held_item(e:Dictionary)->bool:
	var item:String=str(e.get("held_item",""))
	if item.is_empty():return false
	var origin:Vector2i=e.pos
	for direction in [Vector2i.ZERO,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
		var q:Vector2i=origin+direction
		if not cells.has(q) or loot.has(q) or traps.has(q) or player_traps.has(q) or q==player or q==stairs or q==relic:continue
		if q!=origin and enemy_at(q)>=0:continue
		loot[q]=item;e.erase("held_item")
		return true
	return false

func apply_item_rule(i:int,rule:String)->bool:
	if i<0 or i>=enemies.size():return false
	var e:Dictionary=enemies[i]
	if rule=="embargo":
		if int(e.get("embargo_turns",0))>0:return false
		e["embargo_turns"]=rng.randi_range(5,8)
		return true
	if e.get("held_item_immune",false):return false
	if rule=="drop_item":return drop_held_item(e)
	if rule=="swap_item":
		var other:String=str(e.get("held_item",""))
		if held_item.is_empty() or other.is_empty():return false
		e["held_item"]=held_item;held_item=other
		return true
	return false

func enemy_use_potion(i:int)->bool:
	if i<0 or i>=enemies.size():return false
	var e:Dictionary=enemies[i]
	if int(e.get("embargo_turns",0))>0 or int(e.get("item_potions",0))<=0 or int(e.get("heal_block_turns",0))>0:return false
	var cap:int=int(e.get("max_hp",e.hp))
	if int(e.hp)*2>cap:return false
	if heal_enemy(e,20)<=0:return false
	e["item_potions"]=int(e.item_potions)-1
	return true

func belly_value()->int:
	return ceili(float(belly_tenths)/10.0)

func spend_belly()->bool:
	if dev_sandbox:belly_tenths=1000;return true
	if belly_tenths>0:
		belly_tenths-=1
		if belly_tenths==200:emit_event("Getting hungry")
		elif belly_tenths==100:emit_event("Very hungry")
		return true
	hp=maxi(0,hp-1)
	if hp==0:
		finished=true;success=false;message="Starvation · rescue needed";emit_event(message)
		return false
	return true

func belly_drum()->bool:
	if belly_tenths<=10:return false
	belly_tenths=10
	player_stages["attack"]=10
	player_halves.erase("attack")
	return true

func add_technique_manual(id:String)->bool:
	if not MOVE_LIBRARY.has(id):return false
	technique_manuals[id]=int(technique_manuals.get(id,0))+1
	return true

func learn_from_manual(id:String,replace_id:String="")->bool:
	if finished or boon_active("embargo") or not MOVE_LIBRARY.has(id) or int(technique_manuals.get(id,0))<=0 or id in equipped_moves:return false
	if not replace_id.is_empty() and replace_id not in equipped_moves:return false
	if replace_id.is_empty() and equipped_moves.size()>=4:return false
	# Teaching uses the same type/level eligibility as the current training system.
	if id not in available_moves(trained_profile.get("types",["normal"]),int(trained_profile.get("level",1))):return false
	if replace_id.is_empty():equipped_moves.append(id)
	else:
		equipped_moves[equipped_moves.find(replace_id)]=id
		move_pp.erase(replace_id)
	move_pp[id]=int(MOVE_LIBRARY[id].pp)
	technique_manuals[id]=int(technique_manuals[id])-1
	if int(technique_manuals[id])==0:technique_manuals.erase(id)
	spent_manuals[id]=int(spent_manuals.get(id,0))+1
	trained_profile["moves"]=equipped_moves.duplicate()
	return true

func recycle_manuals()->int:
	var restored:int=0
	for id in spent_manuals.keys():
		if id=="eos_337" or not MOVE_LIBRARY.has(id):continue
		var count:int=int(spent_manuals[id])
		if count<=0:continue
		technique_manuals[id]=int(technique_manuals.get(id,0))+count
		restored+=count
		spent_manuals.erase(id)
	return restored

func pickup():
	if not loot.has(player):return
	if player==relic and not guardian_defeated:return
	var kind:String=loot[player]
	loot.erase(player)
	if kind.begins_with("manual:"):
		var id:String=kind.trim_prefix("manual:")
		if add_technique_manual(id):message="Technique manual found · "+str(MOVE_LIBRARY[id].name);emit_event(message)
		return
	match kind:
		"coin":coins+=3;message="+3 coins"
		"potion":potions+=1;message="Healing berry found"
		"trail_fruit":belly_tenths=mini(1000,belly_tenths+500);message="Trail fruit · Belly %d"%belly_value()
		"ward_band","force_band":
			if held_item.is_empty():held_item=kind;message="Equipped "+kind.replace("_"," ").capitalize()
			else:spare_equipment.append(kind);message="Collected "+kind.replace("_"," ").capitalize()
		"material":materials+=1;message="+1 crafting material"
		"spring":hp=mini(max_hp,hp+18);energy=mini(8,energy+3);player_rested=true;message="Restorative spring · HP and skill restored"
		"relic":secured=true;message="Relic secured! Find the stairs"
	emit_event(message)
static func reserve_multiplier(remaining:int,maximum:int)->float:
	var fraction:float=float(remaining)/maxi(1,maximum)
	return 2.5 if fraction<=.2 else 2.0 if fraction<=.5 else 1.5 if fraction<=.7 else 1.0
func lay_player_trap(kind:String)->bool:
	if not cells.has(player) or traps.has(player) or player_traps.has(player) or loot.has(player) or player==stairs:return false
	var interior:bool=false
	for room in rooms:
		if room.has_point(player):
			interior=true;break
	if not interior:return false
	player_traps[player]=kind
	if kind!="rock":revealed_player_traps[player]=true
	return true
func activate_player_trap(i:int)->int:
	if i<0 or i>=enemies.size():return 0
	var e:Dictionary=enemies[i]
	var p:Vector2i=e.pos
	if not player_traps.has(p):return 0
	var kind:String=str(player_traps[p])
	revealed_player_traps[p]=true
	var types:Array=ENEMY_TRAINING.get(e.get("species",""),[["normal"]])[0]
	var amount:int=20 if kind=="spikes" else 10
	if kind=="rock":
		if "rock" in types:return 0
		amount=maxi(1,int(int(e.get("max_hp",e.hp))/8))
	var dealt:int=deal_special_damage(i,amount)
	if kind=="toxic" and enemy_at(p)>=0:apply_enemy_status(enemy_at(p),"poison")
	if dealt>0:emit_event("Trap −%d HP"%dealt)
	return dealt
func blast_move(move:Dictionary)->bool:
	if floor_weather=="rain":return false
	var radius:int=int(move.blast_radius)
	var origin:Vector2i=player
	player_attack_cells=[]
	for q in cells:
		if maxi(absi(q.x-origin.x),absi(q.y-origin.y))<=radius:player_attack_cells.append(q)
	for i in range(enemies.size()-1,-1,-1):
		var e:Dictionary=enemies[i]
		var q:Vector2i=e.pos
		if not player_attack_cells.has(q):continue
		var types:Array=ENEMY_TRAINING.get(e.get("species",""),[["normal"]])[0]
		var amount:int=int(move.blast_damage)
		if "fire" in types:amount=int(amount/2)
		var dealt:int=deal_special_damage(i,amount)
		last_move_attempts+=1;last_move_damage.append(dealt)
		if dealt>0:last_move_hits+=1
	var self_damage:int=maxi(1,int(hp/2))
	if "fire" in trained_profile.get("types",[]):self_damage=maxi(1,int(self_damage/2))
	var actual_self_damage:int=mini(hp,self_damage)
	hp=maxi(0,hp-self_damage);last_move_recoil=actual_self_damage;hits+=1;combo=0
	queue_linked_damage(actual_self_damage);flush_linked_damage()
	if hp==0:finished=true;success=false
	return true
func transfer_stats(rule:String,target:Dictionary={}) -> bool:
	if rule=="gravity":return activate_gravity()
	if rule=="conversion":return convert_element()
	if rule=="camouflage":
		temporary_type=["grass","water","rock"][posmod(floor_style,3)];adaptive_type=""
		return true
	var keys:Array=["attack","defense","sp_attack","sp_defense","accuracy","evasion"]
	if rule=="invert":
		for data in [player_stages,player_halves]:
			var before:int=int(data.get("attack",0))
			data["attack"]=int(data.get("defense",0));data["defense"]=before
		return true
	if rule=="random":
		var key:String=keys[rng.randi_range(0,3)]
		var before:int=int(player_stages.get(key,0))
		player_stages[key]=mini(10,before+2)
		return int(player_stages[key])!=before
	if rule=="charge":
		player_stages["sp_defense"]=mini(10,int(player_stages.get("sp_defense",0))+1)
		charge_power_turns=2
		return true
	if rule=="guard":keys=["defense","sp_defense"]
	if rule=="power":keys=["attack","sp_attack"]
	if not target.has("stages"):target["stages"]={}
	if not target.has("stat_halves"):target["stat_halves"]={}
	for key in keys:
		for pair in [[player_stages,target.stages],[player_halves,target.stat_halves]]:
			var old:int=int(pair[0].get(key,0))
			pair[0][key]=int(pair[1].get(key,0))
			if rule!="copy":pair[1][key]=old
	return true
func invocation_candidates(aim:Vector2i)->Array[String]:
	var candidates:Array[String]=[]
	for id in MOVE_LIBRARY:
		var move:Dictionary=MOVE_LIBRARY[id]
		if not move.get("prototype",false) or int(move.power)<=0 or move.category=="status":continue
		if move.has("charge_phase") or move.has("recoil_fraction") or move.has("pp_scaling") or move.has("special_rule") or move.has("blast_radius") or move.has("reserve_attack") or move.has("boon_kind") or move.get("sleep_reactive",false):continue
		var footprint:Dictionary=attack_footprint(player,aim,str(move.pattern),int(move.reach),true)
		for e in enemies:
			if footprint.has(e.pos):
				candidates.append(id);break
	candidates.sort()
	return candidates
# Independent fixed-damage lookup for the documented normal IQ range.
static func iq_return_damage(iq:int)->int:
	var amount:int=5
	for threshold in [50,100,200,300,400,500,600,700]:
		if iq>=threshold:amount+=5
	return amount

func terrain_invocation_id()->String:
	# Kindria biomes: forest, reef, astral ruins. Region mapping is provisional.
	return ["eos_486","eos_240","eos_207"][clampi(region,0,2)]

func special_damage_amount(move:Dictionary,target:Dictionary)->int:
	var rule:String=str(move.get("special_rule",""))
	var life:int=int(target.hp)
	var level:int=clampi(int(trained_profile.get("level",1)),1,100)
	match rule:
		"20":return 20
		"30":return 30
		"35":return 35
		"iq_return":return iq_return_damage(clampi(int(trained_profile.get("iq",0)),0,999))
		"iq_frustration":return 50-iq_return_damage(clampi(int(trained_profile.get("iq",0)),0,999))
		"magnitude":
			var types:Array=ENEMY_TRAINING.get(target.get("species",""),[["normal"]])[0]
			var affinity:float=1.0
			for type in types:
				var factor:float=type_multiplier("ground",[type])
				affinity*=.5 if factor<=0.0 else .7 if factor<1.0 else 1.4 if factor>1.0 else 1.0
			return maxi(1,roundi(float(magnitude_damage)*affinity*(1.2 if "ground" in current_player_types() else 1.0)))
		"level":return level
		"half_hp":return maxi(1,floori(float(life)*.5))
		"equal_hp":return maxi(0,life-hp)
		"psywave":
			var amount:int=maxi(1,roundi(float(level)*float(rng.randi_range(128,383))/256.0))
			var types:Array=ENEMY_TRAINING.get(target.get("species",""),[["normal"]])[0]
			var affinity:float=1.0
			for type in types:
				var factor:float=type_multiplier(str(move.type),[type])
				affinity*=.5 if factor<=0.0 else .7 if factor<1.0 else 1.4 if factor>1.0 else 1.0
			var stab:float=1.2 if str(move.type) in trained_profile.get("types",[]) else 1.0
			return maxi(1,roundi(float(amount)*affinity*stab))
		"ohko":
			# Explicit Kindria guardian protection; ordinary enemies ignore level difference.
			if int(target.get("kind",0))==3 or target.get("ohko_immune",false):return 0
			return life
	return 0
func deal_special_damage(i:int,amount:int)->int:
	if i<0 or i>=enemies.size():return 0
	if str(enemies[i].get("major_status",""))=="freeze":return 0
	var dealt:int=mini(maxi(0,amount),int(enemies[i].hp))
	enemies[i].hp=int(enemies[i].hp)-dealt
	if int(enemies[i].hp)<=0:remove_defeated_enemy(i)
	return dealt
func break_wall(direction:Vector2i)->bool:
	if not direction in DIR:return false
	var target:Vector2i=player+direction
	if not cells.has(player) or not floor_bounds.has_point(target) or cells.has(target):return false
	cells[target]=true
	floor_revision+=1
	reveal()
	return true

func hurl_enemy(i:int)->bool:
	if i<0 or i>=enemies.size():return false
	var victim:Dictionary=enemies[i]
	if victim.get("push_immune",false) or enemy_has_ability(victim,"anchored"):return false
	var origin:Vector2i=victim.pos
	var room:Rect2i=Rect2i()
	for candidate in rooms:
		if candidate.has_point(origin):room=candidate;break
	if not room.has_area():return false
	var collision:Vector2i=Vector2i(-1,-1)
	var best:int=99999
	for e in enemies:
		var q:Vector2i=e.pos
		if q==origin or not room.has_point(q):continue
		var gap:int=distance(origin,q)
		if gap<best:collision=q;best=gap
	var choices:Array[Vector2i]=[]
	for q in cells:
		if room.has_point(q) and q!=player and enemy_at(q)<0:choices.append(q)
	if choices.is_empty():return false
	choices.sort_custom(func(a,b):return a.x<b.x or (a.x==b.x and a.y<b.y))
	var landing:Vector2i=choices[rng.randi_range(0,choices.size()-1)]
	if best<99999:
		for q in choices:
			if distance(q,collision)<distance(landing,collision):landing=q
	victim.pos=landing;victim["windup"]=false;victim.erase("stuck_turns")
	if best<99999:
		var other:int=enemy_at(collision)
		if other>=0:last_move_damage.append(deal_special_damage(other,10))
		var moved:int=enemy_at(landing)
		if moved>=0:last_move_damage.append(deal_special_damage(moved,10))
	var landed:int=enemy_at(landing)
	if landed>=0:activate_player_trap(landed)
	return true

func push_enemy(i:int)->bool:
	if i<0 or i>=enemies.size():return false
	var e:Dictionary=enemies[i]
	if e.get("push_immune",false) or enemy_has_ability(e,"anchored"):return false
	var origin:Vector2i=e.pos
	var delta:Vector2i=origin-player
	var direction:=Vector2i(signi(delta.x),signi(delta.y))
	if direction==Vector2i.ZERO:return false
	e["windup"]=false;e.erase("stuck_turns")
	for step in range(1,cells.size()+1):
		var q:Vector2i=origin+direction*step
		var blocker:int=enemy_at(q)
		if not cells.has(q) or q==player or blocker>=0:
			var hit_pos:Vector2i=e.pos
			if blocker>=0 and blocker!=i:deal_special_damage(blocker,5)
			var moved_index:int=enemy_at(hit_pos)
			if moved_index>=0:deal_special_damage(moved_index,5)
			return true
		e["pos"]=q
	return true
func warp_player()->bool:
	var choices:Array[Vector2i]=[]
	for q in cells:
		if q!=player and enemy_at(q)<0 and not traps.has(q):
			choices.append(q)
	if choices.is_empty():return false
	choices.sort_custom(func(a,b):return a.x<b.x or (a.x==b.x and a.y<b.y))
	player=choices[rng.randi_range(0,choices.size()-1)]
	player_boons.erase("ingrain")
	reveal()
	return true
func strike(i:int,power:bool=false,style_override:int=-1,move_id:String="",damage_multiplier:float=1.0,override_move:Dictionary={}):
	var attack_style:int=skill_kind if style_override<0 else clampi(style_override,0,2)
	if i<0 or i>=enemies.size():return
	attack_serial+=1;attack_target=enemies[i].pos;attack_power=power
	player_attack_fx="basic_strike" if not power else ["briar_arc","leaf_dart","jelly_pulse"][attack_style]
	player_attack_cells=[attack_target]
	if power and maxi(absi(attack_target.x-player.x),absi(attack_target.y-player.y))==2:player_attack_cells.push_front(player+(attack_target-player)/2)
	player_attack_path=player_attack_cells.duplicate()
	var move:Dictionary=override_move if not override_move.is_empty() else MOVE_LIBRARY.get(move_id,{})
	var element:String=str(move.get("type","normal"))
	if move.is_empty() and power and not trained_profile.is_empty():element=str(trained_profile.types[0])
	if not move.is_empty():element=resolved_move_element(move)
	var damage:int=int(move.power) if not move.is_empty() else 10 if power else 6
	if move.get("hidden_power",false):damage=hidden_base_power
	if int(move.get("reference_id",-1))==31 and element!="normal":damage*=2
	last_type_multiplier=1.0
	if not trained_profile.is_empty():
		var enemy_info:Array=ENEMY_TRAINING.get(enemies[i].get("species",""),[["normal"],"normal","normal",0,0,"physical"])
		var stat_index:int=3 if power and attack_style==1 else 1
		if not move.is_empty():stat_index=3 if move.category=="special" else 1
		var move_type:String=element
		var defender_types:Array=reveal_defender_types(element,enemy_info[0],enemies[i])
		if gravity_active and element=="ground":defender_types.erase("flying")
		damage=trained_damage(damage,move_type,[] if move.get("typeless",false) else current_player_types(),[] if move.get("typeless",false) else defender_types,combat_stat(stat_index),neutral_combat_stat(stat_index),neutral_combat_stat(stat_index))
	var special_damage:bool=str(move.get("category","physical"))=="special" if not move.is_empty() else power and attack_style==1
	var attack_key:String="sp_attack" if special_damage else "attack"
	var defense_key:String="sp_defense" if special_damage else "defense"
	if damage>0:
		damage=maxi(1,roundi(float(damage)*player_stat_effect(attack_key)/maxf(.001,enemy_stat_effect(enemies[i],defense_key))))
	if str(enemies[i].get("major_status",""))=="freeze":
		if element=="fire":
			enemies[i].erase("major_status");enemies[i].erase("major_turns")
		else:damage=0
	var final_multiplier:float=damage_multiplier*(1.0 if move.get("typeless",false) else weather_factor(element))
	if move.get("reserve_attack",false):final_multiplier*=float(active_reserve_multiplier)
	if charge_power_turns>0 and element=="electric" and not move.is_empty():final_multiplier*=2.0
	if move.get("pp_scaling",false):final_multiplier*=reserve_multiplier(int(move_pp.get(move_id,move.pp)),int(move.pp))
	if int(move.get("reference_id",-1))==151 and floor_weather in ["rain","hail","sandstorm"]:final_multiplier*=.5
	damage=maxi(0,roundi(float(damage)*final_multiplier))
	var fixed_damage:bool=boon_active("set_damage")
	if fixed_damage and (str(enemies[i].get("major_status",""))!="freeze" or element=="fire"):damage=30
	var critical:bool=not fixed_damage and damage>0 and roll_player_critical(move,enemies[i])
	if critical:damage=critical_damage(damage,true);last_critical_hits+=1
	if weakened_strikes>0 and not fixed_damage:
		damage=maxi(0,damage-1);weakened_strikes-=1
	var guard:int=int(enemies[i].get("guard",0))
	if guard>0 and not fixed_damage and not move.get("pierce_guard",false):
		damage=maxi(0,damage-guard);enemies[i]["guard"]=0
	if not fixed_damage:damage=held_item_damage(damage,held_item,str(enemies[i].get("held_item","")))
	var dealt:int=mini(maxi(0,int(enemies[i].hp)),damage)
	if not move_id.is_empty():last_move_damage.append(dealt)
	enemies[i].hp=int(enemies[i].hp)-damage
	if move.has("drain_fraction") and dealt>0:
		var before_hp:int=hp
		hp=mini(max_hp,hp+maxi(1,floori(float(dealt)*float(move.drain_fraction))))
		last_move_healed+=hp-before_hp
	message="-%d HP · strike!"%damage
	emit_event(("Critical! " if critical else "")+"−%d HP"%damage)
	if int(enemies[i].hp)<=0:remove_defeated_enemy(i)
func remove_defeated_enemy(i:int)->void:
	if i>=0 and i<enemies.size():
		var guardian=int(enemies[i].kind)==3
		gain_enemy_ev(enemies[i])
		drop_held_item(enemies[i])
		enemies.remove_at(i);defeated+=1;combo+=1;best_combo=maxi(best_combo,combo)
		if guardian:guardian_defeated=true
		var reward=(12 if guardian else 2)+mini(3,combo-1);coins+=reward;message="Guardian defeated! +%d coins"%reward if guardian else "Enemy defeated! +%d coins · Combo %d"%[reward,combo]
		emit_event(message)
func apply_enemy_status(i:int,status:String)->bool:
	if i<0 or i>=enemies.size():return false
	var enemy:Dictionary=enemies[i]
	var types:Array=ENEMY_TRAINING.get(enemy.get("species",""),[["normal"]])[0]
	if status in ["poison","toxic"] and ("poison" in types or "steel" in types or enemy_has_ability(enemy,"clear_blood")):return false
	if status=="burn" and "fire" in types:return false
	if status=="freeze" and "ice" in types:return false
	if status in ["heal_block","curse"]:
		var key:String=status+"_turns"
		if int(enemy.get(key,0))>0:return false
		enemy[key]=rng.randi_range(5,7) if status=="heal_block" else rng.randi_range(4,5)
		if status=="curse":enemy["curse_age"]=0
		return true
	if status in ["exposed","miracle_eye"]:
		if enemy.get(status,false):return false
		enemy[status]=true
		return true
	if status=="sleepless":
		if enemy.get("sleepless",false):return false
		enemy["sleepless"]=true
		for key in ["sleep_turns","nightmare_turns","yawn_turns"]:enemy.erase(key)
		return true
	if status in ["sleep","nightmare","yawn"] and (enemy.get("sleepless",false) or enemy_has_ability(enemy,"wakeful")):return false
	if status in ["whiffer","paused","perish"]:
		var key:String=status+"_turns"
		if int(enemy.get(key,0))>0:return false
		enemy[key]=rng.randi_range(2,6) if status=="whiffer" else rng.randi_range(5,12) if status=="paused" else 4
		enemy["windup"]=false
		return true
	if status in ["nightmare","stuck","leech"]:
		var key:String=status+"_turns"
		if int(enemy.get(key,0))>0:return false
		if status=="leech" and "grass" in types:return false
		enemy[key]=rng.randi_range(4,7) if status=="nightmare" else rng.randi_range(2,5) if status=="stuck" else rng.randi_range(11,12)
		if status=="nightmare":enemy["sleep_turns"]=0;enemy["yawn_turns"]=0
		if status=="leech":enemy["leech_age"]=0
		enemy["windup"]=false
		return true
	if status in ["sleep","yawn"]:
		if int(enemy.get("nightmare_turns",0))>0:return false
		if int(enemy.get("sleep_turns",0))>0 or int(enemy.get("yawn_turns",0))>0:return false
		if status=="sleep":enemy["sleep_turns"]=rng.randi_range(3,6)
		else:enemy["yawn_turns"]=3
	elif status=="confusion":
		if int(enemy.get("confusion_turns",0))>0:return false
		enemy["confusion_turns"]=rng.randi_range(7,12)
	else:
		if str(enemy.get("major_status",""))==status:return false
		enemy["major_status"]=status
		enemy["major_turns"]=rng.randi_range(2,3) if status=="paralysis" else rng.randi_range(1,3) if status=="freeze" else -1
		enemy["status_age"]=0
	enemy["windup"]=false
	return true
func enemy_status_text(enemy:Dictionary)->String:
	var tags:PackedStringArray=[]
	if enemy.get("sleepless",false):tags.append("Sleepless")
	if enemy.get("exposed",false):tags.append("Exposed")
	if enemy.get("miracle_eye",false):tags.append("Mind revealed")
	if int(enemy.get("sleep_turns",0))>0:tags.append("Sleep")
	for state in ["nightmare","stuck","leech","whiffer","paused","perish","heal_block","curse","wrapped","infatuated","destiny","encore","taunt","embargo","decoy"]:
		if int(enemy.get(state+"_turns",0))>0:tags.append(state.capitalize())
	if int(enemy.get("ability_suppressed_turns",0))>0:tags.append("Talent suppressed")
	if not enemy.get("sealed_moves",[]).is_empty():tags.append("Sealed")
	if int(enemy.get("yawn_turns",0))>0:tags.append("Drowsy")
	if int(enemy.get("confusion_turns",0))>0:tags.append("Confused")
	var major:String=str(enemy.get("major_status",""))
	if not major.is_empty():tags.append(major.capitalize())
	if int(enemy.get("slow_turns",0))>0:tags.append("½ Speed")
	if int(enemy.get("haste_turns",0))>0:tags.append("Speed ×%d"% (1+int(enemy.get("haste_stage",0))))
	var stage_text:String=stage_summary(enemy.get("stages",{}),enemy.get("stat_halves",{}))
	if not stage_text.is_empty():tags.append(stage_text)
	return " · ".join(tags)
func tick_enemy_statuses()->void:
	for i in range(enemies.size()-1,-1,-1):
		var e:Dictionary=enemies[i]
		if int(e.get("ability_suppressed_turns",0))>0:e["ability_suppressed_turns"]=int(e.ability_suppressed_turns)-1
		if int(e.get("wrapped_turns",0))>0:
			e["wrapped_age"]=int(e.get("wrapped_age",0))+1
			e["wrapped_turns"]=int(e.wrapped_turns)-1
			if int(e.wrapped_age)%2==1:
				visual_record_response(e,6,"wrap")
				e.hp=int(e.hp)-6
				if int(e.hp)<=0:remove_defeated_enemy(i);player_boons.erase("wrapping");continue
		if int(e.get("curse_turns",0))>0:
			e["curse_turns"]=int(e.curse_turns)-1;e["curse_age"]=int(e.get("curse_age",0))+1
			if int(e.curse_age)>=2 and (int(e.curse_age)-2)%10==0:
				visual_record_response(e,maxi(1,int(int(e.get("max_hp",e.hp))/4)),"curse")
				e.hp=int(e.hp)-maxi(1,int(int(e.get("max_hp",e.hp))/4))
				if int(e.hp)<=0:remove_defeated_enemy(i);continue
		for state in ["whiffer","paused","heal_block","infatuated","destiny","encore","taunt","embargo","decoy"]:
			var key:String=state+"_turns"
			if int(e.get(key,0))>0:e[key]=int(e[key])-1
		if int(e.get("perish_turns",0))>0:
			e["perish_turns"]=int(e.perish_turns)-1
			if int(e.perish_turns)==0 and not e.get("perish_immune",false) and int(e.get("kind",0))!=3:
				visual_record_response(e,int(e.hp),"perish")
				remove_defeated_enemy(i);continue
		if int(e.get("nightmare_turns",0))>0:
			e["nightmare_turns"]=int(e.nightmare_turns)-1
			if int(e.nightmare_turns)==0:
				visual_record_response(e,8,"nightmare")
				e.hp=int(e.hp)-8
				if int(e.hp)<=0:remove_defeated_enemy(i);continue
		if int(e.get("stuck_turns",0))>0:e["stuck_turns"]=int(e.stuck_turns)-1
		if int(e.get("leech_turns",0))>0:
			e["leech_turns"]=int(e.leech_turns)-1
			e["leech_age"]=int(e.get("leech_age",0))+1
			if int(e.leech_age)%2==0:
				var siphoned:int=mini(10,int(e.hp))
				visual_record_response(e,siphoned,"leech")
				e.hp=int(e.hp)-siphoned;hp=mini(max_hp,hp+siphoned)
				if int(e.hp)<=0:remove_defeated_enemy(i);continue
		if int(e.get("slow_turns",0))>0:e["slow_turns"]=int(e.slow_turns)-1
		if int(e.get("haste_turns",0))>0:
			e["haste_turns"]=int(e.haste_turns)-1
			if int(e.haste_turns)==0:e["haste_stage"]=0
		for key in ["sleep_turns","confusion_turns"]:
			if int(e.get(key,0))>0:e[key]=int(e[key])-1
		if int(e.get("yawn_turns",0))>0:
			e["yawn_turns"]=int(e.yawn_turns)-1
			if int(e.yawn_turns)==0:e["sleep_turns"]=rng.randi_range(3,6);e["windup"]=false
		var major:String=str(e.get("major_status",""))
		if major in ["freeze","paralysis"]:
			e["major_turns"]=int(e.get("major_turns",1))-1
			if int(e.major_turns)<=0:e.erase("major_status")
		elif major in ["poison","toxic","burn"]:
			var age:int=int(e.get("status_age",0))
			var interval:int=2 if major=="toxic" else 20
			if age%interval==0:
				visual_record_response(e,2 if major=="poison" else 6,major)
				e.hp=int(e.hp)-(2 if major=="poison" else 6)
				if int(e.hp)<=0:remove_defeated_enemy(i);continue
			e["status_age"]=age+1
func enemy_turn():
	if dev_capture_outcome and dev_cast_outcome.is_empty():dev_cast_outcome=message
	var visual_before:Dictionary=visual_enemy_hp_snapshot()
	visual_turn_damage.clear()
	visual_response_events.clear();visual_response_active=true
	visual_response_cast_serial=-1;visual_response_cast_uid=-1
	if player_slow_turns>0:player_slow_turns-=1
	if charge_power_turns>0:charge_power_turns-=1
	travel_steps_used=0;travel_refresh=false
	counter_damage.clear();last_counter_damage=0;pending_throws.clear();sleep_reactions.clear()
	var old_positions:Dictionary={}
	for e in enemies:old_positions[e.pos]=true
	var stage_before:Dictionary=visual_enemy_hp_snapshot()
	if not finished:ally_turn_actions()
	visual_record_stage(stage_before,"ally")
	stage_before=visual_enemy_hp_snapshot()
	enemy_turn_actions()
	visual_record_stage(stage_before,"enemy_action")
	stage_before=visual_enemy_hp_snapshot()
	flush_linked_damage()
	visual_record_stage(stage_before,"fate_link")
	if not finished:
		stage_before=visual_enemy_hp_snapshot()
		for i in range(enemies.size()-1,-1,-1):
			if not old_positions.has(enemies[i].pos):activate_player_trap(i)
		visual_record_stage(stage_before,"trap")
		stage_before=visual_enemy_hp_snapshot()
		flush_counters()
		visual_record_stage(stage_before,"counter")
		stage_before=visual_enemy_hp_snapshot()
		flush_throws()
		visual_record_stage(stage_before,"throw")
		flush_sleep_reactions()
		tick_enemy_statuses()
		stage_before=visual_enemy_hp_snapshot()
		tick_player_boons()
		visual_record_stage(stage_before,"boon")
		stage_before=visual_enemy_hp_snapshot()
		tick_floor_weather()
		visual_record_stage(stage_before,"weather")
		if boon_active("wrapping") and enemy_at(wrap_target)<0:player_boons.erase("wrapping")
		roost_active=false
	else:counter_damage.clear()
	if shield_turns>0:
		shield_turns-=1
		if shield_turns==0:shield_kind=""
	for i in range(travel_boosts.size()-1,-1,-1):
		travel_boosts[i]-=1
		if travel_boosts[i]<=0:travel_boosts.remove_at(i)
	var visual_after:Dictionary=visual_enemy_hp_snapshot()
	visual_turn_damage=visual_hp_losses(visual_before,visual_after)
	for uid in visual_response_events:
		if not visual_turn_damage.has(uid):
			var hp_before:int=int(visual_before.get(uid,0))
			visual_turn_damage[uid]={"before":hp_before,"after":int(visual_after.get(uid,0)),"removed":not visual_after.has(uid)}
		visual_turn_damage[uid]["events"]=visual_response_events[uid].duplicate(true)
	visual_response_active=false
	visual_turn_damage_turn=turns
func finish_walk_turn()->void:
	travel_steps_used+=1
	if travel_steps_used>=travel_speed():enemy_turn()
	else:
		enemy_actions.clear();reveal()
		if not spend_belly():return
		message="Movement ×%d · %d steps left"%[travel_speed(),travel_speed()-travel_steps_used]
# Enemy kits have independent PP; basic attacks never consume a move slot.
func mirror_veil_blocks(origin:Vector2i,special:bool,pattern:String)->bool:
	return boon_active("mirror_veil") and special and distance(origin,player)==1 and pattern!="corner_front"

func apply_fatal_grudge(e:Dictionary)->bool:
	if not boon_active("grudge") or hp>0:return false
	var slot:String=str(e.get("last_move_slot",""))
	if slot not in ["primary","secondary","support"]:return false
	e["pp_"+slot]=0
	return true

func change_travel_stage(e:Dictionary,delta:int)->void:
	if delta>0:
		if int(e.get("slow_turns",0))>0:e["slow_turns"]=0
		else:e["haste_turns"]=rng.randi_range(4,5);e["haste_stage"]=mini(3,int(e.get("haste_stage",0))+1)
	else:
		if int(e.get("haste_turns",0))>0:
			e["haste_stage"]=maxi(0,int(e.get("haste_stage",0))-1)
			if int(e.haste_stage)==0:e["haste_turns"]=0
		else:slow_enemy(e)

func tempo_rift()->bool:
	if rng.randi_range(0,1)==1:
		if player_slow_turns>0:player_slow_turns=0
		else:add_travel_speed(1)
	else:
		if not travel_boosts.is_empty():travel_boosts.pop_back()
		else:player_slow_turns=rng.randi_range(3,4)*2
	for e in enemies:change_travel_stage(e,1 if rng.randi_range(0,1)==1 else -1)
	return true

func enemy_move_pp(e:Dictionary,slot:String)->int:
	return int(e.get("pp_"+slot,12 if slot=="primary" else 10))

func enemy_move_allowed(e:Dictionary,slot:String)->bool:
	if enemy_move_pp(e,slot)<=0 or slot in e.get("sealed_moves",[]):return false
	if int(e.get("encore_turns",0))>0 and str(e.get("encore_slot",""))!=slot:return false
	if slot=="support" and int(e.get("taunt_turns",0))>0:return false
	return true

# Catalog equivalents for original Kindria enemy signatures, not a replacement of their tuned AI.
const ENEMY_COPY_KITS={"bramble_pup":["eos_182","eos_154"],"sporeling":["eos_147","eos_251"],"thornbeetle":["eos_529","eos_080"],"leafwisp":["eos_443","eos_251"],"rootgnawer":["eos_289","eos_251"],"vinesnap":["eos_182","eos_486"],"mossmite":["eos_028","eos_030"],"sylphowl":["eos_057","eos_178"],"hollow_stag":["eos_486","eos_251"],"grovetitan":["eos_289","eos_182"],"fungal_monarch":["eos_280","eos_147"],"reef_pup":["eos_069","eos_308"],"jellymancer":["eos_129","eos_308"],"shellguard":["eos_030","eos_028"],"bubblewisp":["eos_016","eos_308"],"eelstrix":["eos_189","eos_144"],"coralcrab":["eos_529","eos_308"],"anemoneye":["eos_198","eos_283"],"marrowray":["eos_057","eos_308"],"leviathorn":["eos_433","eos_308"],"abyss_colossus":["eos_062","eos_063"],"tidal_sovereign":["eos_158","eos_308"],"starlit_pup":["eos_154","eos_190"],"lunamoth":["eos_145","eos_057"],"crystarok":["eos_344","eos_042"],"nova_wisp":["eos_053","eos_262"],"orbitserpent":["eos_234","eos_208"],"comet_hare":["eos_190","eos_154"],"voidspider":["eos_436","eos_114"],"nebulwing":["eos_127","eos_057"],"lunar_prowler":["eos_063","eos_515"],"astro_golem":["eos_030","eos_028"],"celestial_guardian":["eos_145","eos_207"]}
func enemy_catalog_move(e:Dictionary,slot:String)->String:
	if slot=="support":
		return "eos_058" if ENEMY_SUPPORT.get(e.get("species",""),"")=="guard" else "eos_003" if ENEMY_SUPPORT.get(e.get("species",""),"")=="drowse" else ""
	var kit:Array=ENEMY_COPY_KITS.get(e.get("species",""),[])
	if slot not in ["primary","secondary"] or kit.size()!=2:return ""
	return str(kit[0 if slot=="primary" else 1])

func copy_eligible(id:String)->bool:
	if not MOVE_LIBRARY.has(id):return false
	var m:Dictionary=MOVE_LIBRARY[id]
	return not m.has("special_rule") and not m.get("random_cast",false) and not m.has("charge_phase") and not m.get("sleep_reactive",false) and not m.has("reserve_action") and not m.has("reserve_attack") and not m.has("blast_radius") and not m.has("trap_kind") and not m.get("rampage_random",false) and not m.get("curse_action",false)

func copied_enemy_move(e:Dictionary,rule:String)->String:
	if rule=="copy_boost":
		var pool:Array[String]=[]
		for slot in ["primary","secondary"]:
			var id:String=enemy_catalog_move(e,slot)
			if copy_eligible(id) and int(MOVE_LIBRARY[id].power)>0 and str(MOVE_LIBRARY[id].category)!="status" and id not in pool:pool.append(id)
		return "" if pool.is_empty() else pool[rng.randi_range(0,pool.size()-1)]
	var last:String=str(e.get("last_move_id",""))
	return last if copy_eligible(last) else ""

func sketch_move(source:String,learned:String)->bool:
	if not copy_eligible(learned) or source not in equipped_moves or learned in equipped_moves:return false
	var index:int=equipped_moves.find(source)
	equipped_moves[index]=learned
	move_pp.erase(source)
	move_pp[learned]=int(MOVE_LIBRARY[learned].pp)
	trained_profile["moves"]=equipped_moves.duplicate()
	return true

func record_enemy_move(e:Dictionary,slot:String)->void:
	e["last_move_id"]=enemy_catalog_move(e,slot)
	e["last_move_slot"]=slot
	e["pp_"+slot]=maxi(0,enemy_move_pp(e,slot)-1)

func apply_move_lock(i:int,rule:String)->bool:
	if i<0 or i>=enemies.size():return false
	var e:Dictionary=enemies[i]
	var slot:String=str(e.get("last_move_slot",""))
	if slot not in ["primary","secondary","support"]:return false
	if rule=="encore":
		if int(e.get("encore_turns",0))>0:return false
		e["encore_slot"]=slot;e["encore_turns"]=rng.randi_range(6,11)
		if slot!="primary":e["windup"]=false
		return true
	if rule=="torment":
		var sealed:Array=e.get("sealed_moves",[])
		if slot in sealed:return false
		sealed.append(slot);e["sealed_moves"]=sealed
	elif rule=="spite":
		if enemy_move_pp(e,slot)<=0:return false
		e["pp_"+slot]=0
	else:return false
	if slot=="primary":e["windup"]=false
	return true

# Kindria-native support moves, distinct from damaging signatures.
const ENEMY_SUPPORT={"mossmite":"guard","shellguard":"guard","grovetitan":"guard","crystarok":"guard","sporeling":"drowse","lunamoth":"drowse","anemoneye":"drowse"}

func apply_taunt(i:int)->bool:
	if i<0 or i>=enemies.size():return false
	var e:Dictionary=enemies[i]
	if int(e.get("taunt_turns",0))>0:return false
	e["taunt_turns"]=rng.randi_range(10,12)
	return true

func execute_enemy_support(i:int,kind:String)->bool:
	if i<0 or i>=enemies.size():return false
	var e:Dictionary=enemies[i]
	if kind not in ["guard","drowse"] or not enemy_move_allowed(e,"support"):return false
	record_enemy_move(e,"support")
	e["support_cooldown"]=7
	if kind=="guard":
		if boon_active("snatch"):
			apply_stat_changes(player_stages,player_halves,{"stat_changes":{"defense":1}})
			emit_event("Stolen Blessing · Defense +1")
		else:
			if not e.has("stages"):e["stages"]={}
			if not e.has("stat_halves"):e["stat_halves"]={}
			apply_stat_changes(e.stages,e.stat_halves,{"stat_changes":{"defense":1}})
	elif boon_active("magic_coat") or mirror_veil_blocks(e.pos,true,"front"):
		apply_enemy_status(i,"yawn")
		emit_event("Arcane Reflection · Drowsiness reflected")
	elif not player_has_ability("wakeful") and not (shield_kind=="safeguard" and shield_turns>0):
		# Existing player sleep system is Rest-specific; use a separate action-lock.
		player_boons["hostile_drowse"]=3
	return true

func transform_form()->bool:
	var choices:Array[String]=[]
	for e in enemies:
		var species:String=str(e.get("species",""))
		if not species.is_empty() and species not in choices:choices.append(species)
	if choices.is_empty():return false
	transformed_species=choices[rng.randi_range(0,choices.size()-1)]
	return true

func apply_decoy(i:int)->bool:
	if i<0 or i>=enemies.size() or int(enemies[i].get("decoy_turns",0))>0:return false
	for e in enemies:e.erase("decoy_turns")
	player_boons.erase("decoy")
	enemies[i]["decoy_turns"]=rng.randi_range(21,50)
	enemies[i]["windup"]=false
	return true

func relay_swap(move:Dictionary)->int:
	var candidates:Array[Dictionary]=[]
	for room in rooms:
		if not room.has_point(player):continue
		for e in enemies:
			if room.has_point(e.pos):candidates.append(e)
		break
	# Seeded Fisher-Yates; no reliance on global RNG.
	for j in range(candidates.size()-1,0,-1):
		var k:int=rng.randi_range(0,j)
		var temp:Dictionary=candidates[j];candidates[j]=candidates[k];candidates[k]=temp
	var changed:int=0
	for e in candidates:
		if e.get("push_immune",false) or enemy_has_ability(e,"anchored") or not roll_reference_hit(move,e):continue
		var old:Vector2i=player
		player=e.pos;e.pos=old;e["windup"]=false
		changed+=1
	if changed>0:
		pickup();reveal()
	return changed

func decoy_action(i:int)->bool:
	var actor:Dictionary=enemies[i]
	var p:Vector2i=actor.pos
	if int(actor.get("decoy_turns",0))>0:
		var q:Vector2i=p+DIR[rng.randi_range(0,DIR.size()-1)]
		if cells.has(q) and q!=player and enemy_at(q)<0 and int(actor.get("stuck_turns",0))<=0:
			actor.pos=q
			enemy_actions.append({"uid":actor.get("uid",i),"phase":"move","from":p,"to":q,"gait":actor.get("gait","walk")})
		return true
	var target:Dictionary={}
	for e in enemies:
		if int(e.get("decoy_turns",0))>0 and int(e.hp)>0:target=e;break
	if target.is_empty():return false
	var dest:Vector2i=target.pos
	var gap:int=distance(p,dest)
	if gap>6:return false
	actor["windup"]=false
	if gap==1:
		var damage:int=mini(int(target.hp),maxi(1,2+tier))
		target.hp=int(target.hp)-damage
		enemy_actions.append({"uid":actor.get("uid",i),"phase":"attack","from":p,"to":dest,"move":"Decoy strike","fx":"basic_strike","damage":damage,"tiles":[dest],"path":[dest]})
		emit_event("Decoy struck −%d HP"%damage)
		return true
	var path:Array[Vector2i]=route(p,dest,true)
	if not path.is_empty() and path[0]!=player and path[0]!=dest and enemy_at(path[0])<0 and int(actor.get("stuck_turns",0))<=0:
		actor.pos=path[0]
		enemy_actions.append({"uid":actor.get("uid",i),"phase":"move","from":p,"to":path[0],"gait":actor.get("gait","walk")})
		return true
	return false

func enemy_turn_actions():
	enemy_actions.clear()
	turns+=1
	if not spend_belly():return
	if poison_turns>0:
		poison_turns-=1;hp=maxi(0,hp-1)
		if hp==0:
			finished=true;success=false;message="Poison · rescue needed";emit_event(message);return
	for i in range(enemies.size()):
		if int(enemies[i].hp)<=0:continue
		var p:Vector2i=enemies[i].pos
		if int(enemies[i].get("slow_turns",0))>0 and int(enemies[i].slow_turns)%2==0:continue
		var major:String=str(enemies[i].get("major_status",""))
		if int(enemies[i].get("sleep_turns",0))>0 or int(enemies[i].get("nightmare_turns",0))>0 or int(enemies[i].get("paused_turns",0))>0 or int(enemies[i].get("wrapped_turns",0))>0 or int(enemies[i].get("infatuated_turns",0))>0 or major=="freeze":continue
		if int(enemies[i].get("confusion_turns",0))>0 or major=="paralysis":
			var dir:Vector2i=DIR[rng.randi_range(0,DIR.size()-1)] if int(enemies[i].get("confusion_turns",0))>0 else Vector2i.ZERO
			var q:Vector2i=p+dir
			if major=="paralysis":
				var route_to_player:=route(p,player,true)
				if turns%2==0 and not route_to_player.is_empty():q=route_to_player[0]
				else:continue
			if cells.has(q) and q!=player and enemy_at(q)<0 and int(enemies[i].get("stuck_turns",0))<=0:
				enemies[i].pos=q
				enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":q,"gait":enemies[i].get("gait","walk")})
			elif q==player and major!="paralysis" and charge_phase not in ["underground","airborne","vanish"]:
				var confused_damage:int=shield_damage(2,"physical")
				if confused_damage>0:
					confused_damage=mini(hp,confused_damage);hp-=confused_damage;hits+=1;combo=0
					queue_counter(p,confused_damage,"physical")
				enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"attack","from":p,"to":player,"move":"Confused strike","fx":"basic_strike","damage":confused_damage,"tiles":[player],"path":[player]})
				if hp==0:apply_fatal_grudge(enemies[i]);finished=true;success=false;return
			continue
		if not boon_active("decoy") and decoy_action(i):continue
		if enemy_target_ally(i):continue
		var gap:=distance(p,player)
		if gap<=3 and not enemies[i].get("windup",false) and enemy_use_potion(i):
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"attack","from":p,"to":p,"move":"Healing berry","fx":"basic_strike","damage":0,"tiles":[p],"path":[p]})
			emit_event("Enemy recovered HP")
			continue
		var support_cd:int=int(enemies[i].get("support_cooldown",0))
		if support_cd>0:enemies[i]["support_cooldown"]=support_cd-1
		var kind:int=int(enemies[i].kind)
		var skill:=signature_skill(enemies[i])
		var primary_allowed:bool=enemy_move_allowed(enemies[i],"primary")
		var charged:bool=enemies[i].get("windup",false) and primary_allowed
		if not primary_allowed:enemies[i]["windup"]=false
		var cooldown:int=int(enemies[i].get("cooldown",0))
		var ready:bool=cooldown<=0 and primary_allowed
		if cooldown>0:enemies[i]["cooldown"]=cooldown-1
		var pattern:String=ATTACK_PATTERNS.get(enemies[i].get("species",""),"line")
		var aim:Vector2i=enemies[i].get("aim",Vector2i.ZERO) if charged else attack_aim(p,player,pattern,int(skill[0]))
		var footprint:Dictionary=attack_footprint(p,aim,pattern,int(skill[0])) if aim!=Vector2i.ZERO else {}
		var in_range:bool=footprint.has(player)
		var alternate:bool=false
		var species:String=str(enemies[i].get("species",""))
		var alt_cooldown:int=int(enemies[i].get("alt_cooldown",0))
		if alt_cooldown>0:enemies[i]["alt_cooldown"]=alt_cooldown-1
		if not charged and (not ready or not in_range) and alt_cooldown<=0 and SECONDARY_SKILLS.has(species) and enemy_move_allowed(enemies[i],"secondary"):
			var alt:Array=SECONDARY_SKILLS[species]
			var alt_aim:=attack_aim(p,player,str(alt[1]),int(alt[0]))
			if alt_aim!=Vector2i.ZERO:
				alternate=true;aim=alt_aim;pattern=str(alt[1])
				footprint=attack_footprint(p,aim,pattern,int(alt[0]))
				in_range=true;ready=true
				skill=[alt[0],false,3,alt[3],alt[4],alt[5],"alt_"+species]
		var support_kind:String=str(ENEMY_SUPPORT.get(enemies[i].get("species",""),""))
		if not charged and not (ready and in_range) and support_cd<=0 and gap<=2 and not enemies[i].get("windup",false) and not support_kind.is_empty() and enemy_move_allowed(enemies[i],"support"):
			var use_support:bool=(support_kind=="guard" and int(enemies[i].get("stages",{}).get("defense",0))<2) or (support_kind=="drowse" and not boon_active("hostile_drowse") and not boon_active("hostile_sleep"))
			if use_support and execute_enemy_support(i,support_kind):
				enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"attack","from":p,"to":p if support_kind=="guard" else player,"move":"Ward" if support_kind=="guard" else "Drowsy Hex","fx":"basic_strike","damage":0,"tiles":[p if support_kind=="guard" else player],"path":[p if support_kind=="guard" else player]})
				continue
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
			var protected_charge:bool=charge_phase in ["underground","airborne","vanish"]
			if marked_damage>0 and not protected_charge:damage+=marked_damage;marked_damage=0
			last_type_multiplier=1.0
			if not trained_profile.is_empty():
				var info:Array=ENEMY_TRAINING.get(enemies[i].get("species",""),[["normal"],"normal","normal",0,0,"physical"])
				var move_type:String=str(info[2] if alternate else info[1]) if special else "normal"
				var stat_index:int=4 if str(info[5])=="special" else 2
				var defender_types:Array=current_player_types()
				if gravity_active and move_type=="ground":defender_types.erase("flying")
				damage=trained_damage(damage,move_type,info[0],defender_types,neutral_combat_stat(stat_index),combat_stat(stat_index),neutral_combat_stat(stat_index))
			var category:String=str(ENEMY_TRAINING.get(enemies[i].get("species",""),[[], "", "", 0, 0, "physical"])[5]) if special else "physical"
			var attack_key:String="sp_attack" if category=="special" else "attack"
			var defense_key:String="sp_defense" if category=="special" else "defense"
			if damage>0:damage=maxi(1,roundi(float(damage)*enemy_stat_effect(enemies[i],attack_key)/maxf(.001,player_stat_effect(defense_key))))
			var weather_info:Array=ENEMY_TRAINING.get(enemies[i].get("species",""),[["normal"],"normal","normal",0,0,"physical"])
			var enemy_element:String=str(weather_info[2] if alternate else weather_info[1]) if special else "normal"
			damage=maxi(0,roundi(float(damage)*weather_factor(enemy_element)))
			if major=="burn":damage=roundi(float(damage)*.8)
			damage=held_item_damage(damage,str(enemies[i].get("held_item","")),held_item)
			var aim_factor:float=enemy_stat_effect(enemies[i],"accuracy")*player_stat_effect("evasion")/(263.0/256.0)
			var stage_miss:bool=aim_factor<1.0 and rng.randf()>=aim_factor
			var whiff:bool=int(enemies[i].get("whiffer_turns",0))>0 and rng.randi_range(1,100)>5
			var dodged:bool=protected_charge or whiff or stage_miss or (damage>0 and speed_evade())
			var reflected:bool=not dodged and mirror_veil_blocks(p,special,pattern)
			if reflected and damage>0:counter_damage[p]=int(counter_damage.get(p,0))+damage
			var shield_block:bool=reflected or (shield_turns>0 and shield_kind=="protect") or (boon_active("magnet") and not gravity_active and enemy_element=="ground")
			last_enemy_critical=not dodged and not shield_block and damage>0 and roll_enemy_critical(8 if special else 0)
			if last_enemy_critical:damage=critical_damage(damage,true)
			if dodged or shield_block:damage=0
			else:
				damage=mini(hp,shield_damage(damage,category))
				if damage>0:
					hp-=damage;hits+=1;combo=0;queue_counter(p,damage,category)
					adapt_after_hit(enemy_element)
			var move_name:String=str(enemies[i].get("signature","Strike")) if special else "Quick strike"
			if alternate:move_name=str(SECONDARY_SKILLS[species][2])
			var effect:String=str(skill[4]) if special else "none"
			if special:
				record_enemy_move(enemies[i],"secondary" if alternate else "primary")
				if alternate:enemies[i]["alt_cooldown"]=maxi(0,int(skill[2])-1)
				else:enemies[i]["cooldown"]=maxi(0,int(skill[2])-1)
				if not dodged and not shield_block:apply_signature_effect(i,skill)
			if dodged or shield_block or (shield_kind=="safeguard" and shield_turns>0 and effect in ["poison","weaken","mark"]) or (boon_active("mist") and effect=="weaken"):effect="none"
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"attack","from":p,"to":player,"end":enemies[i].pos,"move":move_name,"fx":skill[6] if special else "basic_strike","effect":effect,"damage":damage,"dodged":dodged,"effectiveness":last_type_multiplier,"aim":aim if special else player-p,"pattern":pattern if special else "front","tiles":footprint.keys() if special else [player],"path":footprint.get(player,[player]) if special else [player]})
			message="%s · %s! −%d HP"%[enemies[i].get("name","Enemy"),move_name,damage]
			if last_enemy_critical:message+=" · Critical!"
			if reflected:message+=" · Reflected!"
			elif shield_block:message+=" · Protected!"
			elif dodged:message+=" · Dodged!"
			elif last_type_multiplier>1.01:message+=" · Effective!"
			elif last_type_multiplier<.99:message+=" · Resisted"
			if effect!="none":message+=" · "+effect.capitalize()
			emit_event(message)
			if hp==0:
				apply_fatal_grudge(enemies[i])
				finished=true;success=false;message="Rescue needed · expedition lost";return
		elif gap<=6 and kind!=3 and int(enemies[i].get("stuck_turns",0))<=0:
			var path=route(p,player,true)
			if not path.is_empty() and path[0]!=player and enemy_at(path[0])<0:
				var steps:int=1+int(enemies[i].get("haste_stage",0)) if int(enemies[i].get("haste_turns",0))>0 else 1
				var destination:Vector2i=p
				for step in range(mini(steps,path.size())):
					if path[step]==player or enemy_at(path[step])>=0 or ally_at(path[step])>=0:break
					destination=path[step]
				enemies[i].pos=destination
				enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":destination,"gait":enemies[i].get("gait","walk")})
	for i in range(enemies.size()-1,-1,-1):
		if int(enemies[i].hp)<=0:remove_defeated_enemy(i)
	reveal()
func move(p:Vector2i)->bool:
	if player_wait_if_napping():return true
	if not finished and player_slow_turns>0 and player_slow_turns%2==0:
		message="Slowed · wait";enemy_turn();return true
	if not charged_move_id.is_empty():return release_charge()
	if finished or not (p-player) in DIR8:return false
	p=player+confused_direction(p-player)
	if not step_clear(player,p-player):
		if self_confusion_turns>0:enemy_turn();return true
		return false
	var i=enemy_at(p)
	if ally_at(p)>=0:return false
	if i<0 and boon_active("ingrain"):
		message="Rooted · cannot walk";enemy_turn();return true
	if i>=0:strike(i)
	else:
		player=p;pickup()
		if traps.has(player):
			traps.erase(player);hp=maxi(1,hp-3);hits+=1;combo=0;message="Trap! −3 HP";emit_event(message)
	if i>=0:enemy_turn()
	else:finish_walk_turn()
	return true
func attack(power:bool=false,aim:Vector2i=Vector2i.ZERO,style_override:int=-1)->bool:
	if player_wait_if_napping():return true
	if not charged_move_id.is_empty():return release_charge()
	if self_confusion_turns>0:aim=confused_direction(aim)
	var attack_style:int=skill_kind if style_override<0 else clampi(style_override,0,2)
	if finished or (power and energy<2):return false
	var directions:Array=DIR8 if aim==Vector2i.ZERO else [aim]
	if aim!=Vector2i.ZERO and not aim in DIR8:return false
	if power and attack_style==1:
		for d in directions:
			if not step_clear(player,d) or not step_clear(player+d,d) or enemy_at(player+d)>=0:continue
			var ranged=enemy_at(player+d*2)
			if ranged>=0:energy-=2;strike(ranged,true,attack_style);enemy_turn();return true
	for d in directions:
		if not step_clear(player,d):continue
		var i=enemy_at(player+d)
		if i>=0:
			if power:energy-=2
			strike(i,power,attack_style)
			if power and attack_style==2:hp=mini(max_hp,hp+4)
			enemy_turn();return true
	message="No enemy in that direction"
	if self_confusion_turns>0:enemy_turn();return true
	return false
# Two independent accuracy gates; 125 is the original bypass sentinel.
static func reference_accuracy(move:Dictionary)->float:
	var first:int=int(move.get("acc1",125))
	var second:int=int(move.get("acc2",125))
	return float(mini(100,first)*mini(100,second))/100.0
func roll_reference_hit(move:Dictionary,target:Dictionary={})->bool:
	if boon_active("sure"):return true
	var ref:int=int(move.get("reference_id",-1))
	if (ref==64 and floor_weather=="rain") or (ref==270 and floor_weather=="hail"):return true
	var first:int=int(move.get("acc1",125))
	var second:int=int(move.get("acc2",125))
	if first<100 and rng.randi_range(1,100)>first:return false
	if second>100:return true
	var factor:float=player_stat_effect("accuracy")*enemy_stat_effect(target,"evasion")/(263.0/256.0)
	if ref==64 and floor_weather=="sun":
		factor*=stage_factor("accuracy",int(player_stages.get("accuracy",0))-2)/stage_factor("accuracy",int(player_stages.get("accuracy",0)))
	var chance:float=clampf(float(second)*factor,0.0,100.0)
	return chance>=100.0 or rng.randf()*100.0<chance
func clear_charge()->void:
	charged_move_id="";charged_aim=Vector2i.ZERO;charge_phase=""
func release_charge()->bool:
	if finished or charged_move_id.is_empty():return false
	var id:String=charged_move_id
	var aim:Vector2i=charged_aim
	clear_charge()
	return execute_move(id,aim,true)
func cast_move(id:String,aim:Vector2i)->bool:
	if player_wait_if_napping():return true
	if not charged_move_id.is_empty():return release_charge()
	if finished or not id in equipped_moves or not MOVE_LIBRARY.has(id) or int(move_pp.get(id,0))<=0:return false
	if not aim in DIR8:return false
	var move:Dictionary=MOVE_LIBRARY[id]
	if gravity_blocks(move):message="Gravity blocks "+str(move.name);return false
	if move.get("sleep_reactive",false):message="Triggers automatically when attacked asleep";return false
	if move.pattern!="self" or str(move.get("special_rule",""))=="nature_power":aim=confused_direction(aim)
	if move.has("charge_phase") and not (int(move.get("reference_id",-1))==151 and floor_weather=="sun"):
		move_pp[id]=int(move_pp[id])-1
		charged_move_id=id;charged_aim=aim;charge_phase=str(move.charge_phase)
		last_move_healed=0;last_move_recoil=0;last_move_damage.clear()
		last_move_hits=0;last_move_attempts=0
		enemy_turn()
		if finished:clear_charge();return true
		message=str(move.name)+" · Charging 1/2"
		emit_event(message)
		return true
	return execute_move(id,aim,false)
func execute_move(id:String,aim:Vector2i,releasing:bool,invocation_id:String="",invoked_multiplier:float=1.0)->bool:
	var move:Dictionary=MOVE_LIBRARY[id]
	var pp_id:String=id if invocation_id.is_empty() else invocation_id
	if invocation_id.is_empty():last_invoked_move=""
	last_move_healed=0;last_move_recoil=0;last_move_damage.clear();last_critical_hits=0
	if str(move.get("special_rule",""))=="floor_assist":
		var pool:Array[String]=floor_assist_candidates()
		if not pool.is_empty() and roll_reference_hit(move):
			var chosen:String=pool[rng.randi_range(0,pool.size()-1)]
			if not gravity_blocks(MOVE_LIBRARY[chosen]):
				last_invoked_move=chosen
				if execute_move(chosen,aim,false,pp_id):return true
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · No valid invocation";emit_event(message);enemy_turn();return true
	if str(move.get("special_rule","")) in ["leader_decoy","party_boost","party_rally","party_heal","party_renew"]:
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move):last_move_hits=party_support(str(move.special_rule))
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		for a in allies:
			if int(a.hp)>0 and same_party_room(a.pos):player_attack_cells.append(a.pos)
		message=str(move.name)+" · "+("%d affected"%last_move_hits if last_move_hits>0 else "No target")
		emit_event(message);enemy_turn();return true
	if str(move.get("special_rule","")) in ["transform_form","relay_swap"]:
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		var origin:Vector2i=player
		if move.special_rule=="relay_swap":last_move_hits=relay_swap(move)
		elif roll_reference_hit(move) and transform_form():last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[origin,player]
		message=str(move.name)+" · "+("Active" if last_move_hits>0 else "Failed");emit_event(message);enemy_turn();return true
	if str(move.get("special_rule","")) in ["belly_drum","recycle_manual"]:
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		var detail:String="Failed"
		if roll_reference_hit(move):
			if move.special_rule=="belly_drum":
				if belly_drum():last_move_hits=1;detail="Attack maximized · Belly 1"
			else:
				var restored:int=recycle_manuals()
				if restored>0:last_move_hits=1;detail="%d manuals restored"%restored
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+detail;emit_event(message);enemy_turn();return true
	if str(move.get("special_rule","")) in ["copy_last","copy_boost","learn_last"]:
		var copy_rule:String=str(move.special_rule)
		var copy_area:Dictionary=attack_footprint(player,aim,str(move.pattern),int(move.reach),true)
		var copied:String=""
		var target:Vector2i=player+aim
		for e in enemies:
			if copy_area.has(e.pos):
				target=e.pos
				if roll_reference_hit(move,e):copied=copied_enemy_move(e,copy_rule)
				break
		if not copied.is_empty() and copy_rule!="learn_last":
			var borrowed:Dictionary=MOVE_LIBRARY[copied]
			if not gravity_blocks(borrowed):
				last_invoked_move=copied
				if execute_move(copied,aim,false,pp_id,1.5 if copy_rule=="copy_boost" else 1.0):return true
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if copy_rule=="learn_last" and not copied.is_empty() and sketch_move(id,copied):last_move_hits=1;last_invoked_move=copied
		attack_serial+=1;attack_target=target;attack_power=false;player_attack_fx=id
		player_attack_cells=[target];player_attack_path=[target]
		message=str(move.name)+" · "+("Learned "+str(MOVE_LIBRARY[copied].name) if last_move_hits>0 else "No valid copy")
		emit_event(message);enemy_turn();return true
	if str(move.get("special_rule",""))=="tempo_rift":
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move) and tempo_rift():last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · Movement shifted";emit_event(message);enemy_turn();return true
	if str(move.get("special_rule",""))=="nature_power":
		var chosen:String=terrain_invocation_id()
		last_invoked_move=chosen
		# Dispatch exactly once; debit the invocation's PP, not the borrowed attack.
		return execute_move(chosen,aim,false,pp_id)
	if str(move.get("special_rule",""))=="break_wall":
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move) and break_wall(aim):last_move_hits=1
		attack_serial+=1;attack_target=player+aim;attack_power=false;player_attack_fx=id
		player_attack_cells=[attack_target];player_attack_path=[attack_target]
		message=str(move.name)+" · "+("Wall opened" if last_move_hits>0 else "No breakable wall")
		emit_event(message);enemy_turn();return true
	if str(move.get("special_rule",""))=="splash":
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		var directions:Array[Vector2i]=[]
		for dx in range(-1,2):
			for dy in range(-1,2):
				if dx!=0 or dy!=0:directions.append(Vector2i(dx,dy))
		var origin:Vector2i=player
		if splash_step(directions[rng.randi_range(0,7)]):last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[origin,player]
		message=str(move.name);emit_event(message)
		if finished:turns+=1;return true
		enemy_turn();return true
	if move.get("curse_action",false):
		var ghost:bool="ghost" in current_player_types()
		var target:int=enemy_at(player+aim) if ghost else -1
		if ghost and target<0:message="No target for "+str(move.name);return false
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move,enemies[target] if ghost else {}):
			if ghost:
				if apply_enemy_status(target,"curse"):
					hp=maxi(1,hp-maxi(1,int(hp/2)));last_move_hits=1
			else:
				player_stages["attack"]=mini(10,int(player_stages.get("attack",0))+1)
				player_stages["defense"]=mini(10,int(player_stages.get("defense",0))+1)
				if not travel_boosts.is_empty():travel_boosts.pop_back()
				else:player_slow_turns=rng.randi_range(3,4)*2
				last_move_hits=1
		attack_serial+=1;attack_target=player+aim if ghost else player;attack_power=false;player_attack_fx=id
		player_attack_cells=[attack_target];player_attack_path=[attack_target]
		message=str(move.name)+" · "+("Active" if last_move_hits>0 else "Failed")
		emit_event(message);enemy_turn();return true
	if move.get("rampage_random",false):
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=3;last_move_hits=0
		player_attack_cells=[]
		var hit_cells:Array[Vector2i]=[]
		var last:Vector2i=player
		for hit in range(3):
			var dir:Vector2i=Vector2i(rng.randi_range(-1,1),rng.randi_range(-1,1))
			while dir==Vector2i.ZERO:dir=Vector2i(rng.randi_range(-1,1),rng.randi_range(-1,1))
			var target:Vector2i=player+dir
			var current:int=enemy_at(target)
			if current>=0 and roll_reference_hit(move,enemies[current]):
				strike(current,true,-1,id);last_move_hits+=1;last=target;hit_cells.append(target)
		self_confusion_turns=rng.randi_range(7,12)
		attack_serial+=1;attack_target=last;attack_power=true;player_attack_fx=id
		player_attack_cells=hit_cells;player_attack_path=hit_cells.duplicate()
		message=str(move.name)+" · %d/3 hits · Confused"%last_move_hits
		emit_event(message);enemy_turn();return true
	if move.has("reserve_action"):
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move):
			if move.reserve_action=="store":last_move_hits=1 if store_vitality() else 0
			elif stockpile_count>0:last_move_healed=consume_vitality();last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+("Stored %d/3"%stockpile_count if move.reserve_action=="store" else "+%d HP"%last_move_healed)
		emit_event(message);enemy_turn();return true
	if move.get("random_cast",false):
		var choices:Array[String]=invocation_candidates(aim)
		if not choices.is_empty() and roll_reference_hit(move):
			var chosen:String=choices[rng.randi_range(0,choices.size()-1)]
			last_invoked_move=chosen
			return execute_move(chosen,aim,false,id)
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · No valid invocation";emit_event(message);enemy_turn();return true
	if move.has("stat_transfer") and move.pattern=="self":
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move) and transfer_stats(str(move.stat_transfer)):last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+stage_summary(player_stages,player_halves)
		emit_event(message);enemy_turn();return true
	if move.has("trap_kind") or move.has("blast_radius"):
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=0;last_move_hits=0
		player_attack_cells=[player]
		var applied:bool=false
		if roll_reference_hit(move):
			if move.has("trap_kind"):applied=lay_player_trap(str(move.trap_kind))
			else:applied=blast_move(move)
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_path=[player]
		message=str(move.name)+" · "+("Active" if applied else "Failed")
		emit_event(message)
		if finished:turns+=1;enemy_actions.clear();return true
		enemy_turn();return true
	if str(move.get("special_rule",""))=="warp":
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=1 if warp_player() else 0
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+("Warped" if last_move_hits>0 else "No destination")
		emit_event(message);enemy_turn();return true
	if move.has("weather_set") or move.has("floor_sport") or move.has("weather_heal"):
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move):
			if move.has("weather_set"):
				if set_floor_weather(str(move.weather_set)):last_move_hits=1
			elif move.has("floor_sport"):
				floor_sports[str(move.floor_sport)]=rng.randi_range(10,11);last_move_hits=1
			else:
				var before_hp:int=hp
				hp=mini(max_hp,hp+weather_heal_amount());last_move_healed=hp-before_hp
				last_move_hits=1 if last_move_healed>0 else 0
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+(("+%d HP"%last_move_healed) if move.has("weather_heal") else weather_summary())
		emit_event(message);enemy_turn();return true
	if move.has("boon_kind"):
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move) and apply_player_boon(move):
			last_move_hits=1
			if move.boon_kind=="bide":bide_aim=aim;bide_move_id=id
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+("Active" if last_move_hits>0 else "No effect")
		emit_event(message);enemy_turn();return true
	if move.has("shield_kind"):
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move) and activate_shield(move):last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+(shield_kind.capitalize() if last_move_hits>0 else "Failed")
		emit_event(message);enemy_turn();return true
	if move.has("stat_changes") and move.pattern=="self":
		move_pp[pp_id]=int(move_pp[pp_id])-1
		var changed:bool=apply_stat_changes(player_stages,player_halves,move)
		var speed_added:bool=false
		if int(move.get("speed_change",0))>0:speed_added=add_travel_speed(int(move.speed_change))
		if move.get("reset_room_stats",false):reset_room_stats();changed=true
		last_move_attempts=1;last_move_hits=1 if changed or speed_added else 0
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+stage_summary(player_stages,player_halves)
		if speed_added:
			message+=" · Movement ×%d"%travel_speed()
			enemy_actions.clear();travel_steps_used=0;travel_refresh=true;emit_event(message);return true
		emit_event(message);enemy_turn();return true
	if move.has("heal_fraction"):
		if hp>=max_hp and not move.get("roost",false):message="HP already full";return false
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		var before_hp:int=hp
		if roll_reference_hit(move):
			hp=mini(max_hp,hp+int(move.get("heal_fixed",maxi(1,floori(float(max_hp)*float(move.heal_fraction))))))
			if move.get("roost",false):roost_active=true
			last_move_hits=1
		last_move_healed=hp-before_hp
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · +%d HP"%last_move_healed
		emit_event("+%d HP"%last_move_healed)
		enemy_turn()
		return true
	var footprint:=attack_footprint(player,aim,str(move.pattern),int(move.reach),true)
	var targets:Array=[]
	for i in range(enemies.size()):
		if footprint.has(enemies[i].pos):targets.append(i)
	if targets.is_empty():
		if move.get("defog",false) and floor_weather=="fog":
			move_pp[pp_id]=int(move_pp[pp_id])-1;set_floor_weather("clear")
			last_move_attempts=1;last_move_hits=1;attack_serial+=1;attack_target=player;player_attack_fx=id;attack_power=false
			player_attack_cells=[player];player_attack_path=[player];message="Fog cleared";enemy_turn();return true
		message="No target in "+str(move.name)+" range"
		if self_confusion_turns>0 and not releasing:
			move_pp[pp_id]=int(move_pp[pp_id])-1;enemy_turn();return true
		if releasing:
			attack_serial+=1;attack_target=player+aim;player_attack_fx=id;attack_power=true
			player_attack_cells=[attack_target];player_attack_path=[attack_target]
			enemy_turn();return true
		return false
	var area_attack:bool=str(move.pattern) in ["fan","radius","cross","room","floor"] or move.get("wide_sweep",false)
	if not area_attack:
		targets.sort_custom(func(a,b):return footprint[enemies[a].pos].size()<footprint[enemies[b].pos].size())
		targets.resize(1)
	var primary:Vector2i=enemies[int(targets[0])].pos
	var travel:Array=footprint[primary].duplicate()
	var hit_tiles:Array[Vector2i]=[]
	for i in targets:hit_tiles.append(enemies[i].pos)
	targets.sort();targets.reverse()
	if not releasing:move_pp[pp_id]=int(move_pp[pp_id])-1
	if move.get("reserve_attack",false):
		active_reserve_multiplier=stockpile_count;stockpile_count=0
		if active_reserve_multiplier<=0:
			message=str(move.name)+" · No stored power";enemy_turn();return true
	if str(move.get("special_rule",""))=="magnitude":magnitude_damage=choose_magnitude()
	var missed:int=0
	player_visual_hits.clear()
	last_move_hits=0
	last_move_attempts=0
	# One action and one PP, with a separate accuracy check per strike.
	var count:int=rng.randi_range(int(move.get("hit_min",1)),int(move.get("hit_max",1))) if move.has("hit_min") else 1
	for i in targets:
		var target:Vector2i=enemies[i].pos
		for hit in range(count):
			# Never strike an unrelated enemy after the original target faints.
			var current:int=enemy_at(target)
			if current<0:break
			last_move_attempts+=1
			var visual_uid:int=int(enemies[current].get("uid",-1))
			var damage_start:int=last_move_damage.size()
			if roll_reference_hit(move,enemies[current]):
				if move.has("special_rule"):
					if move.special_rule=="push":
						if push_enemy(current):last_move_hits+=1
						else:missed+=1
					elif move.special_rule=="decoy":
						if apply_decoy(current):last_move_hits+=1
						else:missed+=1
					elif move.special_rule in ["swap_ability","copy_ability","suppress_ability"]:
						if apply_ability_rule(current,str(move.special_rule)):last_move_hits+=1
						else:missed+=1
					elif move.special_rule in ["swap_item","drop_item","embargo"]:
						if apply_item_rule(current,str(move.special_rule)):last_move_hits+=1
						else:missed+=1
					elif move.special_rule=="taunt":
						if apply_taunt(current):last_move_hits+=1
						else:missed+=1
					elif move.special_rule in ["encore","torment","spite"]:
						if apply_move_lock(current,str(move.special_rule)):last_move_hits+=1
						else:missed+=1
					elif move.special_rule in ["infatuation","captivate","destiny_link"]:
						if apply_bond_control(current,str(move.special_rule)):last_move_hits+=1
						else:missed+=1
					elif move.special_rule=="hurl":
						if hurl_enemy(current):last_move_hits+=1
						else:missed+=1
					elif move.special_rule=="wrap":
						if bind_enemy(current):last_move_hits+=1
						else:missed+=1
					elif move.special_rule=="shift":
						if shift_conditions(current):last_move_hits+=1
						else:missed+=1
					elif move.special_rule=="present":
						var victim:Dictionary=enemies[current]
						var amount:int=present_outcome(rng.randi_range(1,100))
						if amount<0:
							var cap:int=int(victim.get("max_hp",victim.hp))
							heal_enemy(victim,maxi(1,int(cap/4)))
						else:last_move_damage.append(deal_special_damage(current,amount))
						last_move_hits+=1
					elif move.special_rule=="pain_split":
						var victim:Dictionary=enemies[current]
						var shared:int=maxi(1,floori(float(hp+int(victim.hp))*.5))
						victim.hp=mini(int(victim.get("max_hp",victim.hp)),shared)
						hp=mini(max_hp,shared);last_move_hits+=1
					else:
						var amount:int=special_damage_amount(move,enemies[current])
						var dealt:int=deal_special_damage(current,amount)
						last_move_damage.append(dealt)
						if dealt>0:last_move_hits+=1;emit_event("−%d HP"%dealt)
						else:missed+=1
				elif move.category=="status":
					if move.has("stat_transfer"):
						if transfer_stats(str(move.stat_transfer),enemies[current]):last_move_hits+=1
						else:missed+=1
					elif move.has("stat_changes"):
						var target_enemy:Dictionary=enemies[current]
						if not target_enemy.has("stages"):target_enemy["stages"]={}
						if not target_enemy.has("stat_halves"):target_enemy["stat_halves"]={}
						var changed:bool=apply_stat_changes(target_enemy.stages,target_enemy.stat_halves,move)
						if int(move.get("speed_change",0))<0 and slow_enemy(target_enemy):changed=true
						if move.has("inflict_status") and apply_enemy_status(current,str(move.inflict_status)):changed=true
						if move.get("defog",false):clear_enemy_wards(target_enemy);changed=true
						if changed:last_move_hits+=1
						else:missed+=1
					elif apply_enemy_status(current,str(move.inflict_status)):last_move_hits+=1
					else:missed+=1
				else:
					var multipliers:Array=move.get("hit_multipliers",[1.0])
					strike(current,true,-1,id,float(multipliers[mini(hit,multipliers.size()-1)])*float(move.get("release_multiplier",1.0))*invoked_multiplier)
					last_move_hits+=1
					var survivor:int=enemy_at(target)
					if survivor>=0 and move.has("inflict_status") and rng.randi_range(1,100)<=int(move.get("status_chance",100)):
						apply_enemy_status(survivor,str(move.inflict_status))
			else:
				missed+=1
				if move.get("stop_on_miss",false):break
			if visual_uid>=0:
				for amount in last_move_damage.slice(damage_start):
					if int(amount)>0:player_visual_hits[visual_uid]=int(player_visual_hits.get(visual_uid,0))+1
	if last_move_hits==0 or move.category=="status" or move.has("special_rule"):attack_serial+=1
	attack_target=primary;player_attack_fx=id;player_attack_path=travel
	player_attack_cells=hit_tiles
	player_visual_hit_serial=attack_serial
	message=(str(MOVE_LIBRARY[pp_id].name)+" → " if pp_id!=id else "")+str(move.name)+" · PP %d/%d"%[move_pp[pp_id],MOVE_LIBRARY[pp_id].pp]
	if move.category=="status":message+=" · %d affected"%last_move_hits;emit_event(message)
	if count>1:message+=" · %d/%d hits"%[last_move_hits,last_move_attempts]
	if last_critical_hits>0:message+=" · %d critical"%last_critical_hits
	if missed>0:message+=" · %d missed"%missed
	if move.get("defog",false) and floor_weather=="fog":set_floor_weather("clear")
	if move.get("memento",false) and last_move_hits>0:
		hp=1;warp_player();message+=" · HP 1 · Warped"
	if move.get("self_confuse",false):
		self_confusion_turns=rng.randi_range(7,12);message+=" · Confused"
	active_reserve_multiplier=0
	if last_move_healed>0:message+=" · +%d HP"%last_move_healed;emit_event("+%d HP"%last_move_healed)
	if move.has("recoil_fraction") and last_move_damage.any(func(d):return d>0):
		last_move_recoil=mini(hp,maxi(1,floori(float(max_hp)*float(move.recoil_fraction))))
		hp-=last_move_recoil;hits+=1;combo=0
		queue_linked_damage(last_move_recoil);flush_linked_damage()
		message+=" · Recoil −%d HP"%last_move_recoil
		emit_event("Recoil −%d HP"%last_move_recoil)
		if hp<=0:
			finished=true;success=false;turns+=1;enemy_actions.clear();return true
	enemy_turn()
	return true
# Internal sandbox only. Lab actions cannot be used by a production export.
static func dev_tools_available()->bool:
	return OS.is_debug_build() or OS.has_feature("kindria_dev")

func enable_dev_sandbox()->bool:
	if not dev_tools_available():return false
	dev_sandbox=true
	rescue_finale=false
	guardian_defeated=true
	dev_refill()
	return true

func dev_refill()->void:
	if not dev_sandbox:return
	hp=max_hp;belly_tenths=1000;energy=8
	potions=maxi(potions,99);coins=maxi(coins,9999);materials=maxi(materials,9999)
	for id in equipped_moves:
		if MOVE_LIBRARY.has(id):move_pp[id]=int(MOVE_LIBRARY[id].pp)

func dev_next_floor()->bool:
	if not dev_sandbox or not dev_tools_available():return false
	finished=false;success=false
	floor_number+=1
	generate_floor()
	dev_refill()
	return true

# Enemy signatures are original Kindra skills, not Pokémon move records.
# DEV-only player adaptations have explicit balancing and use the same damage,
# status and target geometry pipeline. They do not alter player learnsets.
const DEV_NATIVE_MOVES={"basic_strike":{"name":"Basic Strike","type":"normal","category":"physical","pattern":"front","reach":1,"power":6,"pp":0,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"description":"Basic attack. Free; does not consume PP."},"briar_arc":{"name":"Briar Pounce","type":"grass","category":"physical","pattern":"line","reach":2,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"pounce","effect_amount":1,"species":"bramble_pup","description":"Inflicts damage and advances the caster toward the target.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_bramble_pup":{"name":"Thorn Scratch","type":"normal","category":"physical","pattern":"fan","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"bramble_pup","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"spore_cloud":{"name":"Spore Puff","type":"poison","category":"special","pattern":"radius","reach":2,"power":5,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"poison","effect_amount":2,"species":"sporeling","description":"Inflicts damage and may poison the target.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_sporeling":{"name":"Cap Bonk","type":"grass","category":"special","pattern":"front","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"sporeling","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"horn_ram":{"name":"Thorn Ram","type":"bug","category":"physical","pattern":"line","reach":2,"power":7,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"pounce","effect_amount":1,"species":"thornbeetle","description":"Inflicts damage and advances the caster toward the target.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_thornbeetle":{"name":"Mandible Cut","type":"bug","category":"physical","pattern":"front","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"thornbeetle","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"leaf_dart":{"name":"Leaf Dart","type":"grass","category":"special","pattern":"line","reach":3,"power":5,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"leafwisp","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_leafwisp":{"name":"Razor Leaves","type":"grass","category":"special","pattern":"fan","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"leafwisp","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"tusk_sweep":{"name":"Root Tusk","type":"ground","category":"physical","pattern":"front","reach":1,"power":7,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"mark","effect_amount":1,"species":"rootgnawer","description":"Inflicts damage and lowers the target's Defense.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_rootgnawer":{"name":"Root Needle","type":"grass","category":"physical","pattern":"line","reach":2,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"rootgnawer","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"vine_snap":{"name":"Snap Vine","type":"grass","category":"physical","pattern":"corner","reach":2,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"weaken","effect_amount":1,"species":"vinesnap","description":"Inflicts damage and lowers the target's Attack.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_vinesnap":{"name":"Petal Chomp","type":"grass","category":"physical","pattern":"front","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"vinesnap","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"rolling_moss":{"name":"Moss Crash","type":"rock","category":"physical","pattern":"line","reach":2,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"guard","effect_amount":1,"species":"mossmite","description":"Inflicts damage and grants the caster a Defense boost.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_mossmite":{"name":"Pebble Scatter","type":"rock","category":"physical","pattern":"radius","reach":1,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"mossmite","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"feather_fan":{"name":"Feather Needle","type":"flying","category":"special","pattern":"fan","reach":3,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"sylphowl","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_sylphowl":{"name":"Talon Rake","type":"flying","category":"special","pattern":"fan","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"sylphowl","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"antler_arc":{"name":"Antler Sweep","type":"grass","category":"physical","pattern":"fan","reach":1,"power":8,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"mark","effect_amount":1,"species":"hollow_stag","description":"Inflicts damage and lowers the target's Defense.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_hollow_stag":{"name":"Bark Spear","type":"grass","category":"physical","pattern":"line","reach":2,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"hollow_stag","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"timber_shock":{"name":"Timber Slam","type":"ground","category":"physical","pattern":"radius","reach":1,"power":8,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"guard","effect_amount":2,"species":"grovetitan","description":"Inflicts damage and grants the caster a Defense boost.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_grovetitan":{"name":"Root Hook","type":"grass","category":"physical","pattern":"corner","reach":2,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"grovetitan","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"royal_spores":{"name":"Spore Crown","type":"poison","category":"special","pattern":"radius","reach":2,"power":7,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"poison","effect_amount":3,"species":"fungal_monarch","description":"Inflicts damage and may poison the target.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_fungal_monarch":{"name":"Royal Spore Jet","type":"poison","category":"special","pattern":"line","reach":3,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"fungal_monarch","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"reef_bite":{"name":"Reef Bite","type":"water","category":"physical","pattern":"front","reach":1,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"reef_pup","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_reef_pup":{"name":"Water Needle","type":"water","category":"physical","pattern":"line","reach":2,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"reef_pup","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"jelly_pulse":{"name":"Sting Pulse","type":"electric","category":"special","pattern":"radius","reach":2,"power":5,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"drain","effect_amount":1,"species":"jellymancer","description":"Inflicts damage and drains the target's last move PP.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_jellymancer":{"name":"Tentacle Flick","type":"water","category":"special","pattern":"front","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"jellymancer","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"shell_impact":{"name":"Shell Bash","type":"rock","category":"physical","pattern":"front","reach":1,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"guard","effect_amount":3,"species":"shellguard","description":"Inflicts damage and grants the caster a Defense boost.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_shellguard":{"name":"Shell Disc","type":"rock","category":"physical","pattern":"line","reach":2,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"shellguard","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"bubble_burst":{"name":"Bubble Shot","type":"water","category":"special","pattern":"corner","reach":3,"power":5,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"weaken","effect_amount":1,"species":"bubblewisp","description":"Inflicts damage and lowers the target's Attack.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_bubblewisp":{"name":"Foam Ring","type":"water","category":"special","pattern":"radius","reach":1,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"bubblewisp","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"electric_lash":{"name":"Static Lash","type":"electric","category":"special","pattern":"line","reach":2,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"drain","effect_amount":1,"species":"eelstrix","description":"Inflicts damage and drains the target's last move PP.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_eelstrix":{"name":"Static Fang","type":"electric","category":"special","pattern":"fan","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"eelstrix","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"double_pincer":{"name":"Claw Snap","type":"bug","category":"physical","pattern":"fan","reach":1,"power":7,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"guard","effect_amount":1,"species":"coralcrab","description":"Inflicts damage and grants the caster a Defense boost.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_coralcrab":{"name":"Brine Jet","type":"water","category":"physical","pattern":"line","reach":2,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"coralcrab","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"tentacle_snare":{"name":"Tentacle Snare","type":"poison","category":"physical","pattern":"corner","reach":2,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"weaken","effect_amount":2,"species":"anemoneye","description":"Inflicts damage and lowers the target's Attack.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_anemoneye":{"name":"Nettle Bloom","type":"poison","category":"physical","pattern":"radius","reach":1,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"anemoneye","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"fin_slice":{"name":"Fin Slice","type":"flying","category":"special","pattern":"line","reach":3,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"mark","effect_amount":1,"species":"marrowray","description":"Inflicts damage and lowers the target's Defense.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_marrowray":{"name":"Tail Barb","type":"water","category":"special","pattern":"fan","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"marrowray","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"spiral_current":{"name":"Spiral Thrust","type":"water","category":"physical","pattern":"line","reach":2,"power":7,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"pounce","effect_amount":1,"species":"leviathorn","description":"Inflicts damage and advances the caster toward the target.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_leviathorn":{"name":"Brackish Lance","type":"water","category":"physical","pattern":"line","reach":3,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"leviathorn","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"abyss_grasp":{"name":"Abyss Crush","type":"dark","category":"physical","pattern":"radius","reach":2,"power":8,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"weaken","effect_amount":1,"species":"abyss_colossus","description":"Inflicts damage and lowers the target's Attack.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_abyss_colossus":{"name":"Ink Veil","type":"dark","category":"physical","pattern":"radius","reach":1,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"abyss_colossus","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"tidal_jaws":{"name":"Tidal Bite","type":"water","category":"physical","pattern":"fan","reach":2,"power":9,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"mark","effect_amount":1,"species":"tidal_sovereign","description":"Inflicts damage and lowers the target's Defense.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_tidal_sovereign":{"name":"Riptide Rush","type":"water","category":"physical","pattern":"line","reach":3,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"tidal_sovereign","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"star_kick":{"name":"Star Kick","type":"fairy","category":"physical","pattern":"front","reach":1,"power":7,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"starlit_pup","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_starlit_pup":{"name":"Comet Spark","type":"fairy","category":"physical","pattern":"line","reach":2,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"starlit_pup","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"lunar_dust":{"name":"Lunar Dust","type":"fairy","category":"special","pattern":"fan","reach":2,"power":5,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"weaken","effect_amount":2,"species":"lunamoth","description":"Inflicts damage and lowers the target's Attack.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_lunamoth":{"name":"Moon Wing","type":"flying","category":"special","pattern":"fan","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"lunamoth","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"prism_shatter":{"name":"Prism Smash","type":"ice","category":"physical","pattern":"radius","reach":1,"power":7,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"guard","effect_amount":2,"species":"crystarok","description":"Inflicts damage and grants the caster a Defense boost.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_crystarok":{"name":"Crystal Needle","type":"ice","category":"physical","pattern":"line","reach":2,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"crystarok","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"nova_bolt":{"name":"Nova Bolt","type":"fire","category":"special","pattern":"line","reach":3,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"drain","effect_amount":1,"species":"nova_wisp","description":"Inflicts damage and drains the target's last move PP.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_nova_wisp":{"name":"Cinder Halo","type":"fire","category":"special","pattern":"radius","reach":1,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"nova_wisp","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"orbit_lash":{"name":"Orbit Lash","type":"psychic","category":"physical","pattern":"corner","reach":2,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"mark","effect_amount":1,"species":"orbitserpent","description":"Inflicts damage and lowers the target's Defense.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_orbitserpent":{"name":"Ring Fang","type":"dragon","category":"physical","pattern":"front","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"orbitserpent","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"comet_drop":{"name":"Comet Drop","type":"fairy","category":"physical","pattern":"line","reach":2,"power":7,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"pounce","effect_amount":1,"species":"comet_hare","description":"Inflicts damage and advances the caster toward the target.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_comet_hare":{"name":"Lunar Kick","type":"normal","category":"physical","pattern":"fan","reach":1,"power":5,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"comet_hare","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"gravity_web":{"name":"Gravity Web","type":"dark","category":"special","pattern":"corner","reach":2,"power":6,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"mark","effect_amount":2,"species":"voidspider","description":"Inflicts damage and lowers the target's Defense.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_voidspider":{"name":"Silk Dart","type":"bug","category":"special","pattern":"line","reach":3,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"voidspider","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"sonic_cone":{"name":"Void Screech","type":"ghost","category":"special","pattern":"fan","reach":3,"power":5,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"drain","effect_amount":2,"species":"nebulwing","description":"Inflicts damage and drains the target's last move PP.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_nebulwing":{"name":"Echo Burst","type":"flying","category":"special","pattern":"radius","reach":1,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"nebulwing","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"moon_claw":{"name":"Moon Claw","type":"dark","category":"physical","pattern":"front","reach":1,"power":8,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"lunar_prowler","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_lunar_prowler":{"name":"Shadow Pounce","type":"dark","category":"physical","pattern":"line","reach":2,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"lunar_prowler","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"meteor_fist":{"name":"Meteor Fist","type":"rock","category":"physical","pattern":"corner","reach":3,"power":7,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"astro_golem","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_astro_golem":{"name":"Gravel Nova","type":"rock","category":"physical","pattern":"radius","reach":1,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"astro_golem","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"celestial_verdict":{"name":"Celestial Verdict","type":"fairy","category":"special","pattern":"cross","reach":3,"power":8,"pp":12,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"drain","effect_amount":2,"species":"celestial_guardian","description":"Inflicts damage and drains the target's last move PP.","balance":"Kindra original · DEV player adaptation, not an EoS reference."},"alt_celestial_guardian":{"name":"Halo Blade","type":"fairy","category":"special","pattern":"fan","reach":2,"power":4,"pp":10,"acc1":125,"acc2":125,"reference_crit":8,"reference_strikes":1,"native":true,"native_effect":"none","effect_amount":0,"species":"celestial_guardian","description":"Inflicts damage.","balance":"Kindra original · DEV player adaptation, not an EoS reference."}}
static func dev_move_record(id:String)->Dictionary:
	if DEV_NATIVE_MOVES.has(id):return DEV_NATIVE_MOVES[id].duplicate(true)
	if not MOVE_LIBRARY.has(id):return {}
	var m:Dictionary=MOVE_LIBRARY[id].duplicate(true)
	m["acc1"]=int(m.get("acc1",125));m["acc2"]=int(m.get("acc2",125))
	m["reference_crit"]=int(m.get("reference_crit",8))
	m["reference_strikes"]=m.get("reference_strikes",m.get("hit_max",1))
	return m

func dev_cast_native(id:String,aim:Vector2i)->bool:
	if not dev_sandbox or not dev_tools_available() or not DEV_NATIVE_MOVES.has(id) or not aim in DIR8:return false
	var m:Dictionary=DEV_NATIVE_MOVES[id]
	var footprint:=attack_footprint(player,aim,str(m.pattern),int(m.reach),true)
	var targets:Array[Vector2i]=[]
	for enemy in enemies:
		if footprint.has(enemy.pos):targets.append(enemy.pos)
	if targets.is_empty():message="No target in "+str(m.name)+" range";return false
	targets.sort_custom(func(a:Vector2i,b:Vector2i):return footprint[a].size()<footprint[b].size())
	if not str(m.pattern) in ["fan","radius","cross","room","floor"]:targets.resize(1)
	last_move_damage.clear();last_move_healed=0;last_move_recoil=0;last_move_hits=0;last_move_attempts=0;last_critical_hits=0
	player_visual_hits.clear()
	var origin:Vector2i=player
	for target in targets:
		var index:int=enemy_at(target)
		if index<0:continue
		last_move_attempts+=1
		var uid:int=int(enemies[index].get("uid",-1))
		if not roll_reference_hit(m,enemies[index]):continue
		var before:int=last_move_damage.size()
		strike(index,true,-1,id,1.0,m)
		last_move_hits+=1
		for amount in last_move_damage.slice(before):
			if int(amount)>0 and uid>=0:player_visual_hits[uid]=int(player_visual_hits.get(uid,0))+1
		index=enemy_at(target)
		if index>=0:
			var effect:String=str(m.native_effect)
			var amount:int=int(m.effect_amount)
			match effect:
				"poison":apply_enemy_status(index,"poison")
				"weaken","mark":
					var stages:Dictionary=enemies[index].get("stages",{}).duplicate()
					var key:String="attack" if effect=="weaken" else "defense"
					stages[key]=clampi(int(stages.get(key,0))-amount,-10,10);enemies[index]["stages"]=stages
				"drain":
					var slot:String=str(enemies[index].get("last_move_slot","primary"))
					if not slot in ["primary","secondary","support"]:slot="primary"
					enemies[index]["pp_"+slot]=maxi(0,enemy_move_pp(enemies[index],slot)-amount)
		if str(m.native_effect)=="guard":
			player_stages["defense"]=clampi(int(player_stages.get("defense",0))+int(m.effect_amount),-10,10)
		elif str(m.native_effect)=="pounce" and targets.size()==1 and footprint[target].size()>1:
			var next:Vector2i=footprint[target][0]
			if step_clear(player,next-player) and enemy_at(next)<0 and ally_at(next)<0:player=next;pickup()
	attack_serial+=1;attack_target=targets[0];attack_power=true;player_attack_fx=id
	player_attack_cells=targets.duplicate();player_attack_path=footprint[targets[0]].duplicate()
	player_visual_hit_serial=attack_serial
	message=str(m.name)+" · %d/%d hits"%[last_move_hits,last_move_attempts]
	if player!=origin:message+=" · Advanced"
	emit_event(message);enemy_turn();dev_refill()
	return true

func dev_cast_move(id:String,aim:Vector2i)->bool:
	dev_cast_outcome="";dev_capture_outcome=true
	var result:bool=dev_cast_move_impl(id,aim)
	dev_capture_outcome=false
	if not result or dev_cast_outcome.is_empty():dev_cast_outcome=message
	return result

func dev_cast_move_impl(id:String,aim:Vector2i)->bool:
	if DEV_NATIVE_MOVES.has(id):return dev_cast_native(id,aim)
	if not dev_sandbox or not dev_tools_available() or not MOVE_LIBRARY.has(id) or not aim in DIR8:return false
	# Bypass equipment/species requirements without changing the saved learnset.
	var move:Dictionary=MOVE_LIBRARY[id]
	if not charged_move_id.is_empty():
		if charged_move_id==id:
			var used:bool=release_charge()
			move_pp[id]=int(move.pp);dev_refill();return used
		clear_charge()
	if gravity_blocks(move):message="Gravity blocks "+str(move.name);return false
	if move.get("sleep_reactive",false):
		# DEV explicitly stages the prerequisite (sleep + incoming hit) using
		# the actual reactive dispatcher. Never turn this into a normal cast.
		var target:Vector2i=player+aim
		if enemy_at(target)<0:message="Sleep reaction requires adjacent enemy";return false
		var old_equipped:Array=equipped_moves.duplicate()
		var old_pp:Dictionary=move_pp.duplicate()
		var old_nap:int=int(player_boons.get("nap",0))
		equipped_moves.assign([id,"eos_154"])
		move_pp[id]=int(move.pp)
		player_boons["nap"]=maxi(2,old_nap)
		last_move_damage.clear();last_move_healed=0;last_move_recoil=0;last_move_hits=0;last_move_attempts=1
		sleep_reactions.clear();record_reactive_hit(target,1);flush_sleep_reactions()
		last_move_hits=1 if not last_move_damage.is_empty() else 0
		equipped_moves.assign(old_equipped);move_pp=old_pp
		if old_nap>0:player_boons["nap"]=old_nap
		else:player_boons.erase("nap")
		message=str(move.name)+" · DEV sleep + incoming hit fixture · "+("Triggered" if last_move_hits>0 else "Missed")
		return true
	move_pp[id]=int(move.pp)
	if move.has("charge_phase") and not (int(move.get("reference_id",-1))==151 and floor_weather=="sun"):
		charged_move_id=id;charged_aim=aim;charge_phase=str(move.charge_phase)
		move_pp[id]=int(move.pp)-1
		last_move_healed=0;last_move_damage.clear();last_move_recoil=0;last_move_hits=0;last_move_attempts=0
		enemy_turn();message=str(move.name)+" · Charging 1/2 · tap again to release";dev_refill();return true
	var used:bool=execute_move(id,aim,false)
	move_pp[id]=int(move.pp);dev_refill()
	return used

func heal()->bool:
	if player_wait_if_napping():return true
	if not charged_move_id.is_empty():return release_charge()
	if finished or potions<=0 or hp==max_hp or boon_active("embargo"):return false
	potions-=1;hp=mini(max_hp,hp+20);message="Recovered HP";emit_event(message);enemy_turn();return true
func descend()->bool:
	if player_wait_if_napping():return true
	if not charged_move_id.is_empty():return release_charge()
	if finished or player!=stairs or not secured:return false
	floor_bonus=mini(6,maxi(0,explored_rooms.size()-2)*2);coins+=floor_bonus;total_bonus+=floor_bonus
	if floor_number>=floor_count and not dev_sandbox:
		finished=true;success=true;message="Expedition complete!";return true
	floor_number+=1;hp=mini(max_hp,hp+10);generate_floor();return true
