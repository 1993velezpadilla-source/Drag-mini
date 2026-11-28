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
		var critical_before:int=last_critical_hits
		strike(target,true,-1,chosen)
		player_attack_fx=chosen
		player_attack_path=response_footprint[p].duplicate()
		player_cast_results.clear()
		var reactive_damage:int=0
		for amount in last_move_damage.slice(damage_index):reactive_damage+=int(amount)
		record_cast_result(p,reactive_damage,true,false,last_critical_hits>critical_before)
		player_cast_result_serial=attack_serial
		if last_move_damage.size()>damage_index:
			visual_record_response(response_enemy,int(last_move_damage[damage_index]),"sleep_counter",attack_serial,chosen)
			var recorded:Array=visual_response_events.get(response_uid,[])
			if not recorded.is_empty() and int(recorded[-1].get("cast_serial",-1))==attack_serial:
				recorded[-1]["from"]=player
				recorded[-1]["to"]=p
				recorded[-1]["path"]=player_attack_path.duplicate()
				recorded[-1]["results"]=player_cast_results.duplicate(true)
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
	player_cast_results.clear();record_cast_result(target,dealt,true,false,false);player_cast_result_serial=attack_serial
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
	poison_turns=0;weakened_strikes=0;marked_damage=0;self_confusion_turns=0;player_slow_turns=0
	for status in ["hostile_sleep","hostile_drowse","hostile_paralysis"]:player_boons.erase(status)
func player_wait_if_napping()->bool:
	if not finished and boon_active("hostile_paralysis") and int(player_boons.hostile_paralysis)%2==0:
		message="Paralyzed";enemy_turn();return true
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
		var changed:bool=poison_turns>0 or weakened_strikes>0 or marked_damage>0 or self_confusion_turns>0 or player_slow_turns>0 or boon_active("hostile_sleep") or boon_active("hostile_drowse") or boon_active("hostile_paralysis")
		clear_negative_conditions()
		return changed
	if boon_active(id) or (id=="nap" and boon_active("sleepless")) or (id=="magnet" and gravity_active):return false
	if id in ["sure","focus","set_damage"]:
		for state in ["sure","focus","set_damage"]:player_boons.erase(state)
	if id=="sleepless":
		for status in ["nap","hostile_sleep","hostile_drowse"]:player_boons.erase(status)
	player_boons[id]=rng.randi_range(int(move.boon_min),int(move.boon_max))
	if id=="wish":wish_fraction=0.0
	if id=="aqua":aqua_age=0
	if id=="ingrain":ingrain_age=0
	if id=="bide":bide_damage=0
	return true
func tick_player_boons()->void:
	if int(player_boons.get("hostile_drowse",0))==1:
		if not boon_active("sleepless") and not player_has_ability("wakeful") and not (shield_kind=="safeguard" and shield_turns>0):player_boons["hostile_sleep"]=rng.randi_range(3,6)+1
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
# Transient dispatch bookkeeping, never retained between enemy phases.
var enemy_phase_spent:Dictionary={}
var player_attack_fx:String="basic_strike"
var player_attack_cells:Array[Vector2i]=[]
# Presentation-only strike counts for the most recent resolved reference move.
var player_visual_hits:Dictionary={}
var player_visual_hit_serial:int=-1
# Actual per-tile attack outcomes. Serial prevents reuse after a reactive cast.
var player_cast_results:Dictionary={}
var player_cast_result_serial:int=-1
func record_cast_result(tile:Vector2i,damage:int,landed:bool,changed:bool,critical:bool)->void:
	var row:Dictionary=player_cast_results.get(tile,{"damage":0,"hits":0,"misses":0,"effects":0,"blocked":0,"crit":0})
	# Preserve the real attempt order, including misses and blocked hits.
	var attempts:Array=row.get("attempts",[])
	attempts.append({"damage":maxi(0,damage),"hits":1 if landed and damage>0 else 0,"misses":0 if landed else 1,"effects":1 if landed and changed and damage<=0 else 0,"blocked":1 if landed and damage<=0 and not changed else 0,"crit":1 if critical and damage>0 else 0})
	row["attempts"]=attempts
	row.damage=int(row.damage)+maxi(0,damage)
	if not landed:row.misses=int(row.misses)+1
	elif damage>0:row.hits=int(row.hits)+1
	elif changed:row.effects=int(row.effects)+1
	else:row.blocked=int(row.blocked)+1
	if critical and damage>0:row.crit=int(row.crit)+1
	player_cast_results[tile]=row

func record_cast_heal(tile:Vector2i,amount:int)->void:
	if amount<=0:return
	var row:Dictionary=player_cast_results.get(tile,{"damage":0,"hits":0,"misses":0,"effects":0,"blocked":0,"crit":0})
	row["heal"]=int(row.get("heal",0))+amount
	player_cast_results[tile]=row

func seal_special_cast()->void:
	# Explicit special branches supply their actual effect or heal before the enemy turn.
	if player_cast_results.is_empty():record_cast_result(attack_target,0,true,last_move_hits>0,false)
	if last_move_healed>0:record_cast_heal(player,last_move_healed)
	player_cast_result_serial=attack_serial
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
# Scoped AI caches: terrain is immutable during enemy_turn_actions. Geometry
# and occupancy are scoped to one actor's planning, before committing actions.
var ai_cache_enabled:bool=true
# Opt-in test telemetry; never enabled by normal gameplay.
var ai_recovery_trace_uid:int=-1
var ai_recovery_trace:Dictionary={}
# Optional per-phase decision evidence; never used as an AI input.
var ai_wait_audit_enabled:bool=false
var ai_wait_audit:Dictionary={}
var ai_cache_active:bool=false
var ai_actor_cache_active:bool=false
var ai_los_cache:Dictionary={}
var ai_terrain_cache:Dictionary={}
var ai_topology_cache:Dictionary={}
var ai_footprint_cache:Dictionary={}
var ai_occupancy_cache:Dictionary={}
var ai_occupancy_ready:bool=false
var ai_cache_hits:int=0
var ai_cache_misses:int=0
const AI_LOS_CAP:int=1024
const AI_FOOTPRINT_CAP:int=128
const AI_TERRAIN_CAP:int=4
const AI_TOPOLOGY_CAP:int=256

func ai_begin_turn_cache()->void:
	ai_end_turn_cache()
	ai_cache_active=ai_cache_enabled
	ai_cache_hits=0;ai_cache_misses=0
	ai_path_nodes=0;ai_path_fast_routes=0;ai_path_reused_searches=0

func ai_end_actor_cache()->void:
	ai_actor_cache_active=false
	ai_footprint_cache.clear();ai_occupancy_cache.clear();ai_occupancy_ready=false

func ai_begin_actor_cache()->void:
	ai_end_actor_cache()
	ai_actor_cache_active=ai_cache_active

func ai_end_turn_cache()->void:
	ai_end_actor_cache()
	ai_cache_active=false
	ai_los_cache.clear();ai_terrain_cache.clear();ai_topology_cache.clear()

func attack_footprint(origin:Vector2i,forward:Vector2i,pattern:String,reach:int,player_cast:bool=false)->Dictionary:
	if not ai_actor_cache_active or player_cast or pattern=="floor":
		return compute_attack_footprint(origin,forward,pattern,reach,player_cast)
	# Radius and cross are heading-independent, including their special cases.
	var heading:Vector2i=Vector2i.ZERO if pattern in ["radius","cross","room"] else forward
	var key:String="%d,%d:%d,%d:%s:%d"%[origin.x,origin.y,heading.x,heading.y,pattern,reach]
	if ai_footprint_cache.has(key):
		ai_cache_hits+=1
		return ai_footprint_cache[key]
	var result:Dictionary=compute_attack_footprint(origin,forward,pattern,reach,false)
	ai_cache_misses+=1
	if ai_footprint_cache.size()<AI_FOOTPRINT_CAP:ai_footprint_cache[key]=result
	return result

func compute_attack_footprint(origin:Vector2i,forward:Vector2i,pattern:String,reach:int,player_cast:bool=false,vacated:Vector2i=Vector2i(-99999,-99999))->Dictionary:
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
				var occupied:bool=p!=vacated and enemy_at(p)>=0
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
			var occupied:bool=q!=vacated and enemy_at(q)>=0
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
						var branch_occupied:bool=target!=vacated and enemy_at(target)>=0
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
# Hypothetical movement vacates exactly the moving actor's old tile.
# Bypass normal footprint cache: the projected occupancy is not the live board.
func enemy_projected_attack_aim(e:Dictionary,post:Vector2i,target:Vector2i,pattern:String,reach:int,prune_symmetric:bool=true)->Vector2i:
	if post==e.pos:return attack_aim(post,target,pattern,reach)
	# These footprints are independent of heading even with projected vacancy.
	# Keep the first cardinal heading and never reuse live occupancy geometry.
	var headings:Array=[DIR[0]] if prune_symmetric and pattern in ["radius","cross","room"] else DIR
	for d in headings:
		if compute_attack_footprint(post,d,pattern,reach,false,e.pos).has(target):return d
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
				if cells.has(q) and enemy_at(q)<0 and ally_at(q)<0 and q!=player:enemies[i].pos=q

func enemy_profile(kind:int,uid:int)->Array:
	var pool:Array=[]
	for row in MINION_ROSTER[clampi(region,0,2)]:
		if int(row[4])==kind:pool.append(row)
	return pool[posmod(seed_value+floor_number*3+uid*5,pool.size())]
func make_enemy(p:Vector2i,life:int,kind:int,uid:int)->Dictionary:
	var profile:=enemy_profile(kind,uid)
	var e:Dictionary={"uid":uid,"pos":p,"hp":life,"max_hp":life,"kind":kind,"windup":false,"species":profile[0],"name":profile[1],"gait":profile[2],"signature":profile[3]}
	# Learned terrain-control move, separate from the two signature slots.
	var control:String=str(ENEMY_CONTROL_KITS.get(str(profile[0]),""))
	if not control.is_empty():
		e["control_move"]=control;e["pp_control"]=int(MOVE_LIBRARY[control].pp)
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
# Bounded presentation-only queue; multiple events in a turn retain their identity.
var visual_interactions:Array[Dictionary]=[]
var attack_serial=0
var attack_target=Vector2i.ZERO
var attack_power=false
var explored_rooms:Dictionary={}
var explored_side_chambers:Dictionary={}
var last_completed_floor_material:int=0
var floor_bonus=0
var last_completed_floor_bonus:int=0
var total_bonus=0
var floor_kind=0
# Independent Kindria implementation, informed by pmdsky-debug's room/trigger contracts.
var monster_house_room:int=-1
var monster_house_triggered:bool=false
var monster_house_cleared:bool=false
var monster_house_serial:int=0
var monster_house_spawn_count:int=0
var monster_house_rng:=RandomNumberGenerator.new()
const HOUSE_PROFILES=["Classic","Swarm","Vanguard","Crossfire","Treasure lure","Trap nest"]
var monster_house_profile:int=0

func house_recipe(profile:int)->Vector3i:
	# Spawn modifier, reward budget, trap budget. No paid modifiers.
	match profile:
		1:return Vector3i(2,4,2)
		2:return Vector3i(-1,5,2)
		3:return Vector3i(0,5,3)
		4:return Vector3i(-1,7,1)
		5:return Vector3i(0,3,5)
		_:return Vector3i(0,5,3)

func house_enemy_kind(profile:int,index:int)->int:
	match profile:
		1:return 0 if index%3!=2 else 1
		2:return 2 if index%3!=2 else 0
		3:return 1 if index%3!=2 else 0
		_:return monster_house_rng.randi_range(0,2)
const MONSTER_HOUSE_UID_BASE:int=200
const MONSTER_HOUSE_CAP:int=10
var player_rested=false
var starter_woods:bool=false
const LAYOUT_HISTORY_CAP:int=1024
const LAYOUT_RETRY_CAP:int=32
var recent_layouts:Array[String]=[]
const SHAPE_HISTORY_CAP:int=4096
var recent_shapes:Array[String]=[]
var shape_signature:String=""
var shape_history_hits:int=0
var layout_signature:String=""
var layout_retries:int=0
# Family labels are Kindria-specific; the geometry is generated, never a fixed map.
const TOPOLOGY_NAMES=["Compact","Horizontal","Vertical","Ring","Branching","Connected","Cross","Tee","Elbow","U-Shaped","Zigzag","Double Wing","Spine","Twin Courtyard","Lattice","Wide Basin","Tall Basin","Corner Clusters","Staggered","Fork","Long Gallery","Deep Gallery","Broken Ring","Mosaic"]
const TOPOLOGY_GRIDS=[Vector2i(2,2),Vector2i(4,2),Vector2i(2,4),Vector2i(3,3),Vector2i(3,3),Vector2i(3,2),Vector2i(3,3),Vector2i(3,3),Vector2i(3,3),Vector2i(3,3),Vector2i(4,3),Vector2i(4,3),Vector2i(3,4),Vector2i(4,4),Vector2i(4,4),Vector2i(4,3),Vector2i(3,4),Vector2i(4,4),Vector2i(4,4),Vector2i(3,4),Vector2i(4,2),Vector2i(2,4),Vector2i(4,4),Vector2i(4,4)]
const TOPOLOGY_BRANCHES=[1,1,1,0,3,1,2,2,2,1,2,2,3,1,2,2,2,3,2,3,2,2,2,4]
# Independent dimensions of the floor recipe, not authored floor layouts.
const ROOM_PROFILES=["Classic","Wide","Tall","Irregular"]
const LINK_PROFILES=["Balanced","Sparse","Local loops","Cross links"]
var room_profile:int=0
var link_profile:int=0
# Independent, bounded microgeometry and encounter recipes; never purchase-dependent.
const INTERIOR_PROFILES=["Open","Pillars","Offset pillars","Alcoves","Mixed"]
const ECOLOGY_PROFILES=["Balanced","Foraging","Patrols","Hazards","Quiet","Mixed"]
var interior_profile:int=0
var ecology_profile:int=0
var interior_obstacles:Array[Vector2i]=[]
var ecology_rng:=RandomNumberGenerator.new()
# Structure is independent of the dungeon art, ecology, and purchase state.
const STRUCTURE_PROFILES=["Separate","Merged chambers","Grand halls","Maze passages"]
var structure_profile:int=0
var merged_room_count:int=0
var structural_walls:Array[Vector2i]=[]
var structure_rng:=RandomNumberGenerator.new()
# Extra graph grammar; no new art, locks or purchase-dependent inputs.
const NETWORK_PROFILES=["Classic","Branches","Shortcuts","Side chambers","Mixed"]
var network_profile:int=0
var network_paths:Array[Dictionary]=[]
var side_chambers:Array[Rect2i]=[]
var side_rewards:Array[Vector2i]=[]
var network_rng:=RandomNumberGenerator.new()

func network_patch_clear(patch:Dictionary,entry:Vector2i,exit:Vector2i,loop:bool)->bool:
	for q in patch:
		if not floor_bounds.has_point(q) or cells.has(q):return false
		for room in rooms:
			if room.has_point(q):return false
		for d in DIR:
			var near:Vector2i=q+d
			if cells.has(near) and near!=entry and (not loop or near!=exit):return false
	return true

func extend_network()->void:
	network_paths.clear();side_chambers.clear();side_rewards.clear()
	network_profile=0 if starter_woods or topology_family==3 or not guardian_defeated else network_rng.randi_range(0,NETWORK_PROFILES.size()-1)
	if network_profile==0:return
	var origins:Array= cells.keys()
	for i in range(origins.size()-1,0,-1):
		var j:int=network_rng.randi_range(0,i);var swap:Vector2i=origins[i];origins[i]=origins[j];origins[j]=swap
	var kinds:Array[int]=[]
	match network_profile:
		1:kinds.assign([1,1])
		2:kinds.assign([2,2])
		3:kinds.assign([3])
		4:kinds.assign([1,2,3])
	for kind in kinds:
		var placed:bool=false
		# Bounded search; gracefully skip a feature when this layout has no space.
		for index in range(mini(160,origins.size())):
			if placed:break
			var entry:Vector2i=origins[index]
			var first:int=network_rng.randi_range(0,3)
			for turn in range(4):
				var d:Vector2i=DIR[(first+turn)%4]
				var length:int=network_rng.randi_range(2,4)
				var patch:Dictionary={}
				var trail:Array[Vector2i]=[]
				for step in range(1,length+1):
					var q:Vector2i=entry+d*step
					patch[q]=true;trail.append(q)
				var bends:int=0
				if kind!=3 and network_rng.randi_range(0,1)==0:
					d=Vector2i(-d.y,d.x) if network_rng.randi_range(0,1)==0 else Vector2i(d.y,-d.x)
					var pivot:Vector2i=trail.back()
					for step in range(1,network_rng.randi_range(1,3)+1):
						var q:Vector2i=pivot+d*step
						patch[q]=true;trail.append(q)
					bends=1
				var end:Vector2i=trail.back()+d
				var chamber:=Rect2i()
				if kind==2 and not cells.has(end):continue
				if kind==3:
					chamber=Rect2i(end+d-Vector2i.ONE,Vector2i(3,3))
					for y in range(chamber.position.y,chamber.end.y):
						for x in range(chamber.position.x,chamber.end.x):patch[Vector2i(x,y)]=true
				if not network_patch_clear(patch,entry,end,kind==2):continue
				var previous_length:int=0
				if kind==2:
					var old_route:Array[Vector2i]=route(entry,end)
					previous_length=old_route.size()
					if previous_length<=trail.size()+3:continue
				for q in patch:cells[q]=true
				network_paths.append({"kind":kind,"entry":entry,"exit":end if kind==2 else trail.back(),"tiles":trail,"bends":bends,"previous_length":previous_length})
				if kind==3:
					side_chambers.append(chamber);side_rewards.append(center(chamber))
				placed=true;break
		# Allow later features to grow from the preceding branch, not only base rooms.
		if placed and kind==1:
			var added:Array=network_paths.back()["tiles"]
			for q in added:origins.push_front(q)


func carve_maze_wall(room:Rect2i)->void:
	if structure_profile!=3:return
	# A two-cell internal wall with an intact perimeter has a walkable detour.
	var starts:Array[Vector2i]=[]
	for y in range(room.position.y+1,room.end.y-1):
		for x in range(room.position.x+1,room.end.x-1):starts.append(Vector2i(x,y))
	for i in range(starts.size()-1,0,-1):
		var j:int=structure_rng.randi_range(0,i);var swap:Vector2i=starts[i];starts[i]=starts[j];starts[j]=swap
	for q in starts:
		var first:int=structure_rng.randi_range(0,1)
		for turn in range(2):
			var d:Vector2i=Vector2i.RIGHT if (first+turn)%2==0 else Vector2i.DOWN
			var end:Vector2i=q+d
			if not room.grow(-1).has_point(end) or q==center(room) or end==center(room):continue
			var halo:Rect2i=Rect2i(q,Vector2i.ONE).merge(Rect2i(end,Vector2i.ONE)).grow(1)
			var safe:bool=true
			for y in range(halo.position.y,halo.end.y):
				for x in range(halo.position.x,halo.end.x):
					if not cells.has(Vector2i(x,y)):safe=false
			if not safe:continue
			cells.erase(q);cells.erase(end);structural_walls.append(q);structural_walls.append(end)
			return

func merge_adjacent_rooms(slots:Array[Vector2i],room_slots:Dictionary)->void:
	if structure_profile!=1 and structure_profile!=2:return
	var budget:int=1 if structure_profile==1 else 2
	var used:Dictionary={}
	var replacements:Dictionary={}
	var removed:Dictionary={}
	# Merge only neighboring occupied sectors; each original room is used once.
	# Do this after corridor graph repair so its index-based graph stays intact.
	for slot in slots:
		if merged_room_count>=budget or rooms.size()-merged_room_count<=3:break
		if not room_slots.has(slot):continue
		var i:int=room_slots[slot]
		if used.has(i):continue
		var first:int=structure_rng.randi_range(0,3)
		for turn in range(4):
			var neighbor:Vector2i=slot+DIR[(first+turn)%4]
			if not room_slots.has(neighbor):continue
			var j:int=room_slots[neighbor]
			if used.has(j):continue
			var merged:Rect2i=rooms[i].merge(rooms[j])
			if merged.size.x>16 or merged.size.y>16:continue
			var safe:bool=true
			for k in range(rooms.size()):
				if k!=i and k!=j and merged.intersects(rooms[k]):safe=false
			for anchor in corridor_anchors:
				if merged.has_point(anchor):safe=false
			if not safe:continue
			for y in range(merged.position.y,merged.end.y):
				for x in range(merged.position.x,merged.end.x):cells[Vector2i(x,y)]=true
			used[i]=true;used[j]=true;replacements[i]=merged;removed[j]=true;merged_room_count+=1
			break
	var result:Array[Rect2i]=[]
	for i in range(rooms.size()):
		if not removed.has(i):result.append(replacements.get(i,rooms[i]))
	rooms.assign(result)

func carve_interior_obstacles(room:Rect2i)->void:
	if interior_profile==0:return
	var candidates:Array[Vector2i]=[]
	var middle:Vector2i=center(room)
	for y in range(room.position.y+1,room.end.y-1):
		for x in range(room.position.x+1,room.end.x-1):
			var q:=Vector2i(x,y)
			if q==middle:continue
			if interior_profile==1 and (x-room.position.x)%2!=1:continue
			if interior_profile==2 and (x+y)%2!=0:continue
			if interior_profile==3 and q.x!=room.position.x+1 and q.x!=room.end.x-2:continue
			candidates.append(q)
	for i in range(candidates.size()-1,0,-1):
		var j:int=ecology_rng.randi_range(0,i);var swap:Vector2i=candidates[i];candidates[i]=candidates[j];candidates[j]=swap
	var budget:int=1 if interior_profile==3 else (3 if interior_profile==4 else 2)
	for q in candidates:
		if budget<=0:break
		# The intact eight-neighbor ring provides a four-connected detour.
		# Never carve an entrance, room center, or adjacent obstacle.
		var safe:bool=cells.has(q)
		for dy in range(-1,2):
			for dx in range(-1,2):
				if not cells.has(q+Vector2i(dx,dy)):safe=false
		if not safe:continue
		cells.erase(q);interior_obstacles.append(q);budget-=1

func ecology_budgets(base_enemies:int,base_loot:int,base_traps:int)->Vector3i:
	if starter_woods or not guardian_defeated:return Vector3i(base_enemies,base_loot,base_traps)
	match ecology_profile:
		1:return Vector3i(maxi(2,base_enemies-1),mini(16,base_loot+3),base_traps)
		2:return Vector3i(mini(9,base_enemies+2),base_loot,base_traps)
		3:return Vector3i(base_enemies,base_loot,mini(12,base_traps+2) if floor_number>1 else base_traps)
		4:return Vector3i(maxi(2,base_enemies-2),maxi(6,base_loot-1),maxi(0,base_traps-1))
		5:return Vector3i(mini(9,base_enemies+1),mini(16,base_loot+1),base_traps)
		_:return Vector3i(base_enemies,base_loot,base_traps)

func topology_slot_allowed(family:int,q:Vector2i,grid:Vector2i)->bool:
	var edge:bool=q.x==0 or q.y==0 or q.x==grid.x-1 or q.y==grid.y-1
	match family:
		3:return q!=Vector2i(1,1)
		6:return q.x==1 or q.y==1
		7:return q.y==0 or q.x==1
		8:return q.x==0 or q.y==grid.y-1
		9:return q.x==0 or q.x==grid.x-1 or q.y==grid.y-1
		10:return q.y==0 and q.x<3 or q.y==1 and q.x>=1 or q.y==2 and q.x>=2
		11:return q.x==0 or q.x==grid.x-1 or q.y==1
		12:return q.x==1 or q.y%2==0
		13:return edge or q.x==1
		14:return true
		15:return q.y!=1 or q.x==0 or q.x==grid.x-1
		16:return q.x!=1 or q.y==0 or q.y==grid.y-1
		17:return (q.x<2 and q.y<2) or (q.x>=2 and q.y>=2) or q==Vector2i(1,2)
		18:return (q.x+q.y)%3!=0
		19:return q.y==0 or q.x==1 or (q.y==grid.y-1 and q.x!=1)
		20:return q.y==0 or q.x%2==0
		21:return q.x==0 or q.y%2==0
		22:return edge and q!=Vector2i(1,0) and q!=Vector2i(2,grid.y-1)
		_:return true
var topology_family:int=0
var corridor_anchors:Array[Vector2i]=[]

func topology_grid(family:int)->Vector2i:
	return TOPOLOGY_GRIDS[clampi(family,0,TOPOLOGY_GRIDS.size()-1)]

func topology_branch_budget(family:int)->int:
	return TOPOLOGY_BRANCHES[clampi(family,0,TOPOLOGY_BRANCHES.size()-1)]

func add_corridor_anchors(slots:Array[Vector2i],occupied:Dictionary)->void:
	# Non-room anchors provide corridor-only exploration. They are excluded
	# from player/stair room-interior placement; no new room is declared.
	var budget:int=topology_branch_budget(topology_family)
	if starter_woods and floor_number==1:return
	for slot in slots:
		if corridor_anchors.size()>=budget:break
		if occupied.has(slot):continue
		var target:Vector2i=slot*9+Vector2i(4,4)
		if cells.has(target):continue
		var nearest:int=-1
		for d in DIR:
			if occupied.has(slot+d):
				nearest=int(occupied[slot+d])
				break
		if nearest<0:continue
		# Reserve empty space at the terminal so it is not an accidental junction.
		var clear_terminal:bool=true
		for d in DIR:
			if cells.has(target+d):clear_terminal=false
		if not clear_terminal:continue
		connect_cells(center(rooms[nearest]),target)
		corridor_anchors.append(target)


# Layout history is independent of the active save and recoverable from a previous snapshot.
static func history_config_valid(config:ConfigFile)->bool:
	if not config.has_section_key("dungeons","geometry"):return false
	for key in ["geometry","canonical_shapes_v1"]:
		var entries:Variant=config.get_value("dungeons",key,[])
		if not (entries is Array or entries is PackedStringArray):return false
		for signature in entries:
			if not signature is String or signature.length()!=64 or not signature.is_valid_hex_number():return false
	return true

static func read_layout_history(path:String)->ConfigFile:
	for candidate in [path,path+".bak"]:
		var config:=ConfigFile.new()
		if config.load(candidate)==OK and history_config_valid(config):return config
	return ConfigFile.new()

static func write_layout_history(path:String,exact:Array[String],shapes:Array[String])->int:
	var config:=ConfigFile.new()
	config.set_value("dungeons","geometry",exact)
	config.set_value("dungeons","canonical_shapes_v1",shapes)
	var temp:String=path+".tmp"
	var error:int=config.save(temp)
	if error!=OK:return error
	var check:=ConfigFile.new()
	if check.load(temp)!=OK or not history_config_valid(check):return ERR_FILE_CORRUPT
	# Only back up a valid primary; never replace a healthy backup with a corrupt file.
	var previous:=ConfigFile.new()
	if previous.load(path)==OK and history_config_valid(previous):
		error=DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path+".bak"))
		if error!=OK:return error
	# A completed temporary snapshot replaces the primary on the same filesystem.
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(path))

func remember_layout(signature:String)->void:
	if signature.is_empty():return
	recent_layouts.erase(signature)
	recent_layouts.append(signature)
	while recent_layouts.size()>LAYOUT_HISTORY_CAP:recent_layouts.pop_front()

func remember_shape(signature:String)->void:
	if signature.length()!=64 or not signature.is_valid_hex_number():return
	recent_shapes.erase(signature)
	recent_shapes.append(signature)
	while recent_shapes.size()>SHAPE_HISTORY_CAP:recent_shapes.pop_front()

func canonical_shape_signature()->String:
	# Same canonical v1 encoding; normalize once and transform integer coordinates.
	if cells.is_empty():return ""
	var low:=Vector2i(2147483647,2147483647)
	var high:=Vector2i(-2147483647,-2147483647)
	for q in cells:
		low=Vector2i(mini(low.x,q.x),mini(low.y,q.y))
		high=Vector2i(maxi(high.x,q.x),maxi(high.y,q.y))
	var span:Vector2i=high-low
	var points:Array[Vector2i]=[]
	for q in cells:points.append(q-low)
	var best:String=""
	var ids:=PackedInt32Array()
	ids.resize(points.size())
	for orientation in range(8):
		var rotation:int=orientation%4
		for i in range(points.size()):
			var x:int=points[i].x if orientation<4 else span.x-points[i].x
			var y:int=points[i].y
			match rotation:
				0:ids[i]=y*128+x
				1:ids[i]=x*128+span.y-y
				2:ids[i]=(span.y-y)*128+span.x-x
				3:ids[i]=(span.x-x)*128+y
		ids.sort()
		var parts:=PackedStringArray()
		for tile_id in ids:parts.append(str(tile_id))
		var encoded:String=",".join(parts)
		if best.is_empty() or encoded<best:best=encoded
	return best.sha256_text()

func floor_layout_signature()->String:
	# Hash only the walkable geometry, not the seed, loot or exit placement.
	# Normalize translation and sort to make dictionary insertion order irrelevant.
	var min_x:int=2147483647
	var min_y:int=2147483647
	for q in cells:
		min_x=mini(min_x,q.x);min_y=mini(min_y,q.y)
	var coordinates:=PackedStringArray()
	for q in cells:coordinates.append("%d,%d"%[q.x-min_x,q.y-min_y])
	coordinates.sort()
	return ";".join(coordinates).sha256_text()

func stairs_available()->bool:
	# Only explicit legacy rescue boss finales retain the guardian rule.
	return guardian_defeated
func setup(r:int,id:int,step:int,finale:bool,patrol:bool,seed_id:int,companion:int=0,intro_woods:bool=false):
	starter_woods=intro_woods and r==0 and not patrol and not finale
	floor_number=1
	region=r;seed_value=seed_id;skill_kind=posmod(companion,3);rescue_finale=finale;specimen=id
	tier=0 if patrol or id<12 else 1 if id<24 else 2
	floor_count=3 if starter_woods else (2 if patrol else 3+tier+(1 if finale else 0))
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
# Starter-floor identity is authored, layout remains seeded and procedural.
func starter_floor_title()->String:
	return ["Fernlight Clearing","Silverbrook Falls","Ancientroot Grove"][clampi(floor_number-1,0,2)]

func starter_objective()->String:
	return "Find the stairs" if floor_number<floor_count else "Find the exit"

func starter_room_count()->int:
	return 3 if floor_number==1 else 4

# Original implementation of documented room-interior spawn eligibility.
func room_spawn_tiles()->Array[Vector2i]:
	var candidates:Array[Vector2i]=[]
	for room in rooms:
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x):
				var q:=Vector2i(x,y)
				if not cells.has(q):continue
				var junction:bool=false
				for d in DIR:
					if cells.has(q+d) and not room.has_point(q+d):
						junction=true
						break
				if not junction:candidates.append(q)
	return candidates

func layout_component(links:Dictionary)->Array[int]:
	var reached:Array[int]=[0]
	var cursor:int=0
	while cursor<reached.size():
		var i:int=reached[cursor];cursor+=1
		for j in range(rooms.size()):
			if j in reached or i==j:continue
			if links.has(Vector2i(mini(i,j),maxi(i,j))):reached.append(j)
	return reached

func build_layout():
	# Select a layout family first, then draw actual rooms and connections.
	topology_family=0 if starter_woods else rng.randi_range(1,TOPOLOGY_NAMES.size()-1)
	room_profile=0 if starter_woods else rng.randi_range(0,ROOM_PROFILES.size()-1)
	link_profile=0 if starter_woods or topology_family==3 else rng.randi_range(0,LINK_PROFILES.size()-1)
	corridor_anchors.clear()
	interior_obstacles.clear()
	structural_walls.clear();merged_room_count=0
	structure_profile=0 if starter_woods or topology_family==3 else structure_rng.randi_range(0,STRUCTURE_PROFILES.size()-1)
	interior_profile=0 if starter_woods else ecology_rng.randi_range(0,INTERIOR_PROFILES.size()-1)
	ecology_profile=0 if starter_woods else ecology_rng.randi_range(0,ECOLOGY_PROFILES.size()-1)
	var grid:Vector2i=topology_grid(topology_family)
	floor_bounds=Rect2i(Vector2i.ONE,grid*9-Vector2i(2,2))
	var slots:Array[Vector2i]=[]
	for y in range(grid.y):
		for x in range(grid.x):
			if not topology_slot_allowed(topology_family,Vector2i(x,y),grid):continue
			slots.append(Vector2i(x,y))
	for i in range(slots.size()-1,0,-1):
		var j=rng.randi_range(0,i);var swap=slots[i];slots[i]=slots[j];slots[j]=swap
	var room_count=starter_room_count() if starter_woods else rng.randi_range(4,mini(12,slots.size()))
	if topology_family==3:room_count=slots.size()
	elif topology_family==4:room_count= rng.randi_range(4,6)
	elif topology_family in [6,7,8,9,10,11,12,17,19,20,21,22]:room_count=mini(12,slots.size())
	for i in range(room_count):
		var slot=slots[i]
		var width=rng.randi_range(5,7);var height=rng.randi_range(5,7)
		if room_profile==1:width=rng.randi_range(6,7);height=rng.randi_range(4,6)
		elif room_profile==2:width=rng.randi_range(4,6);height=rng.randi_range(6,7)
		var notch:int=rng.randi_range(0,3) if room_profile==3 else -1
		if starter_woods:
			# Open tutorial clearing, elongated stream-side room, broad final grove.
			if floor_number==1 and i==0:width=7;height=7
			elif floor_number==2 and i==1:width=5;height=7
			elif floor_number==3 and i==room_count-1:width=7;height=7
		var origin=slot*9+Vector2i(rng.randi_range(1,9-width-1),rng.randi_range(1,9-height-1))
		var room=Rect2i(origin,Vector2i(width,height));rooms.append(room)
		var cut=rng.randi_range(0,3)
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x):
				var corner_x=x==room.position.x or x==room.end.x-1
				var corner_y=y==room.position.y or y==room.end.y-1
				if cut>0 and corner_x and corner_y and rng.randi_range(0,3)<cut:continue
				if notch>=0:
					var nx:bool=x<room.position.x+2 if notch%2==0 else x>=room.end.x-2
					var ny:bool=y<room.position.y+2 if notch<2 else y>=room.end.y-2
					if nx and ny:continue
				cells[Vector2i(x,y)]=true
		carve_interior_obstacles(room)
		carve_maze_wall(room)
	# Local grid walk with directional persistence, then repair connectivity.
	# This creates loops naturally instead of imposing a tree on every floor.
	var links:Dictionary={}
	var room_slots:Dictionary={}
	for i in range(room_count):room_slots[slots[i]]=i
	var cursor_slot:Vector2i=slots[rng.randi_range(0,room_count-1)]
	var direction:int=rng.randi_range(0,3)
	var connectivity:int=[5,8,10][clampi(floor_number-1,0,2)] if starter_woods else (24 if topology_family==3 else (8 if topology_family==4 else 12))
	if not starter_woods and topology_family!=3:connectivity=[connectivity,0,room_count*5,room_count*2][link_profile]
	for n in range(connectivity):
		if rng.randi_range(0,1)==0:direction=rng.randi_range(0,3)
		for turn in range(4):
			var candidate:Vector2i=cursor_slot+DIR[direction]
			if room_slots.has(candidate):
				var i:int=room_slots[cursor_slot]
				var j:int=room_slots[candidate]
				var key:=Vector2i(mini(i,j),maxi(i,j))
				if not links.has(key):
					connect_cells(center(rooms[i]),center(rooms[j]))
					links[key]=true
				cursor_slot=candidate
				break
			direction=(direction+1)%4
	# Ring family explicitly joins neighboring outer sectors, giving alternate routes.
	if topology_family==3:
		for slot in room_slots:
			for d in [Vector2i.RIGHT,Vector2i.DOWN]:
				if not room_slots.has(slot+d):continue
				var i:int=room_slots[slot]
				var j:int=room_slots[slot+d]
				var key:=Vector2i(mini(i,j),maxi(i,j))
				if not links.has(key):
					connect_cells(center(rooms[i]),center(rooms[j]));links[key]=true
	var reached:Array[int]=layout_component(links)
	while reached.size()<rooms.size():
		var best=99999;var source=0;var destination=-1
		for i in reached:
			for j in range(rooms.size()):
				if j in reached:continue
				var score=distance(center(rooms[i]),center(rooms[j]))*4+rng.randi_range(0,12)
				if score<best:best=score;source=i;destination=j
		connect_cells(center(rooms[source]),center(rooms[destination]))
		links[Vector2i(mini(source,destination),maxi(source,destination))]=true
		reached=layout_component(links)
	var extra=rng.randi_range(0,mini(4,room_count-2))
	if not starter_woods and link_profile==3:extra=rng.randi_range(3,mini(8,room_count))
	if topology_family==3 or topology_family==4 or link_profile==1:extra=0
	if starter_woods and floor_number==1:extra=0
	for n in range(extra):
		var i=rng.randi_range(0,room_count-1);var j=rng.randi_range(0,room_count-1)
		var key=Vector2i(mini(i,j),maxi(i,j))
		if i!=j and not links.has(key) and distance(center(rooms[i]),center(rooms[j]))<=20:
			connect_cells(center(rooms[i]),center(rooms[j]));links[key]=true
	add_corridor_anchors(slots,room_slots)
	merge_adjacent_rooms(slots,room_slots)
	extend_network()
	for i in range(structural_walls.size()-1,-1,-1):
		if cells.has(structural_walls[i]):structural_walls.remove_at(i)
	# Corridor carving can reopen an obstacle; retain only final solid tiles.
	for i in range(interior_obstacles.size()-1,-1,-1):
		if cells.has(interior_obstacles[i]):interior_obstacles.remove_at(i)
	# Stairs and leader are independently sampled from all room interiors.
	# Normal floors can start directly on the staircase; rescue finales cannot.
	var spawn_tiles:Array[Vector2i]=room_spawn_tiles()
	stairs=spawn_tiles[rng.randi_range(0,spawn_tiles.size()-1)]
	if not guardian_defeated:spawn_tiles.erase(stairs)
	player=spawn_tiles[rng.randi_range(0,spawn_tiles.size()-1)]
	# Optional treasure / explicit guardian anchor stays away from player and stairs.
	var choices:Array[Vector2i]=[]
	for room in rooms:
		var q:Vector2i=center(room)
		if q!=stairs and q!=player:choices.append(q)
	relic=choices[rng.randi_range(0,choices.size()-1)]
func reset_floor_combat_presentation()->void:
	# Enemy UIDs are local to the floor. Never reuse a previous floor's visual ledger.
	visual_turn_damage.clear();visual_turn_damage_turn=-1
	visual_response_events.clear();visual_response_active=false
	visual_response_cast_serial=-1;visual_response_cast_uid=-1
	player_visual_hits.clear();player_visual_hit_serial=-1;player_cast_results.clear();player_cast_result_serial=-1
	enemy_actions.clear()
	player_attack_cells.clear();player_attack_path.clear()

# Room encounters redistribute existing floor budgets instead of adding paid power.
const ENCOUNTER_PROFILES=["Classic","Patrol","Supply cache","Guarded cache","Hazard pocket"]
var encounter_profile:int=0
var encounter_room:int=-1
var encounter_enemy_count:int=0
var encounter_loot_count:int=0
var encounter_trap_count:int=0
var encounter_rng:=RandomNumberGenerator.new()

func encounter_free_tile(p:Vector2i)->bool:
	return cells.has(p) and p!=player and p!=stairs and p!=relic and p not in side_rewards and distance(p,player)>=4 and enemy_at(p)<0 and ally_at(p)<0 and not loot.has(p) and not traps.has(p)

func arrange_floor_encounter()->void:
	encounter_profile=0;encounter_room=-1;encounter_enemy_count=0;encounter_loot_count=0;encounter_trap_count=0
	if starter_woods or floor_number<2 or not guardian_defeated or floor_kind==3:return
	encounter_profile=encounter_rng.randi_range(0,ENCOUNTER_PROFILES.size()-1)
	if encounter_profile==0:return
	var candidates:Array[int]=[]
	for i in range(rooms.size()):
		var room:Rect2i=rooms[i]
		if room.has_point(player) or room.has_point(stairs) or room.has_point(relic):continue
		var free:int=0
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x):
				if encounter_free_tile(Vector2i(x,y)):free+=1
		if free>=6:candidates.append(i)
	if candidates.is_empty():encounter_profile=0;return
	encounter_room=candidates[encounter_rng.randi_range(0,candidates.size()-1)]
	var target:Rect2i=rooms[encounter_room]
	var spots:Array[Vector2i]=[]
	for y in range(target.position.y,target.end.y):
		for x in range(target.position.x,target.end.x):
			var p:=Vector2i(x,y)
			if encounter_free_tile(p):spots.append(p)
	for i in range(spots.size()-1,0,-1):
		var j:int=encounter_rng.randi_range(0,i);var swap:Vector2i=spots[i];spots[i]=spots[j];spots[j]=swap
	var recipe:Vector3i=[Vector3i.ZERO,Vector3i(3,0,0),Vector3i(0,4,0),Vector3i(2,3,0),Vector3i(0,1,3)][encounter_profile]
	for e in enemies:
		if encounter_enemy_count>=recipe.x or spots.is_empty():break
		if target.has_point(e.pos):continue
		e.pos=spots.pop_back();encounter_enemy_count+=1
	for p in loot.keys():
		if encounter_loot_count>=recipe.y or spots.is_empty():break
		if target.has_point(p) or p==relic or p in side_rewards or distance(p,player)<4:continue
		if loot[p] not in ["coin","material","potion","trail_fruit"]:continue
		var kind:String=loot[p]
		loot.erase(p);loot[spots.pop_back()]=kind;encounter_loot_count+=1
	for p in traps.keys():
		if encounter_trap_count>=recipe.z or spots.is_empty():break
		if target.has_point(p):continue
		var destination:Vector2i=spots.pop_back()
		traps.erase(p);traps[destination]=floor_trap_kind(destination);encounter_trap_count+=1

# Optional discoveries replace ordinary pickups. Keep the teaching manual and side rewards intact.
const TREASURE_TYPES=[["normal","grass","bug","ground","poison","flying"],["normal","water","electric","ice","rock","steel"],["normal","psychic","ghost","dark","fairy","dragon"]]
var treasure_rng:=RandomNumberGenerator.new()
var treasure_tiles:Array[Vector2i]=[]
var treasure_kinds:Array[String]=[]

func distribute_rare_treasures()->void:
	treasure_tiles.clear();treasure_kinds.clear()
	if starter_woods or floor_number<2 or not guardian_defeated or floor_kind==3:return
	var candidates:Array[Vector2i]=[]
	for p in loot:
		if p==player or p==stairs or p==relic or p in side_rewards or distance(p,player)<4:continue
		if loot[p] in ["coin","material"]:candidates.append(p)
	if candidates.is_empty():return
	for i in range(candidates.size()-1,0,-1):
		var j:int=treasure_rng.randi_range(0,i);var swap:Vector2i=candidates[i];candidates[i]=candidates[j];candidates[j]=swap
	var count:int=1 if treasure_rng.randi_range(1,100)<=45 else 0
	if floor_number>=3 and treasure_rng.randi_range(1,100)<=15:count+=1
	for i in range(mini(count,candidates.size())):
		var p:Vector2i=candidates[i]
		var item:String=""
		if treasure_rng.randi_range(1,100)<=35:
			item="ward_band" if treasure_rng.randi_range(0,1)==0 else "force_band"
		else:
			var types:Array=TREASURE_TYPES[clampi(region,0,2)]
			var element:String=types[treasure_rng.randi_range(0,types.size()-1)]
			var rank:int=1
			if tier>=1 and floor_number>=3 and treasure_rng.randi_range(1,100)<=40:rank=2
			if tier>=2 and floor_number>=4 and treasure_rng.randi_range(1,100)<=15:rank=3
			var id:String="lib_%s_%d"%[element,rank]
			if MOVE_LIBRARY.has(id):item="manual:"+id
		if item.is_empty():continue
		loot[p]=item;treasure_tiles.append(p);treasure_kinds.append(item)

# Seeded traps use an independent coordinate roll; no geometry RNG changes.
const FLOOR_TRAP_KINDS=["spike","snare","drain","hunger","weaken"]
func floor_trap_kind(p:Vector2i)->String:
	if starter_woods or floor_number<2 or not guardian_defeated:return "spike"
	var roll:int=posmod(seed_value*31+floor_number*97+region*53+p.x*71+p.y*113,100)
	if roll<40:return "spike"
	if roll<58:return "snare"
	if roll<75:return "drain"
	if roll<90:return "hunger"
	return "weaken"

func trigger_floor_trap(p:Vector2i)->bool:
	if not traps.has(p):return false
	var kind:String=str(traps[p])
	traps.erase(p)
	hits+=1;combo=0
	var protected:bool=shield_kind=="safeguard" and shield_turns>0
	match kind:
		"snare":
			if protected:message="Snare · Protected"
			else:player_slow_turns=maxi(player_slow_turns,4);message="Snare · Slowed"
		"drain":
			var lost:int=mini(2,energy)
			energy-=lost;message="Drain trap · −%d energy"%lost
		"hunger":
			var lost:int=mini(80,maxi(0,belly_tenths-10))
			belly_tenths-=lost;message="Hunger trap · Belly %d"%belly_value()
		"weaken":
			if protected or boon_active("mist"):message="Weakening trap · Protected"
			else:weakened_strikes=maxi(weakened_strikes,2);message="Weakening trap · Attack weakened"
		_:
			var lost:int=mini(3,maxi(0,hp-1))
			hp-=lost;message="Trap! −%d HP"%lost
	emit_event(message)
	return true

# Ordinary enemy ecology: retain species combat kits and existing population budgets.
const ENEMY_ECOLOGY_ROLES=["hunter","scout","sentry","roamer"]

func assign_enemy_ecology()->void:
	if starter_woods or floor_number<2 or not guardian_defeated or floor_kind==3 or dev_sandbox:return
	for e in enemies:
		if int(e.kind)==3 or bool(e.get("monster_house",false)):continue
		var uid:int=int(e.uid)
		var roll:int=posmod(seed_value*37+floor_number*101+uid*71+region*53,100)
		var role:String="hunter" if roll<40 else "scout" if roll<60 else "sentry" if roll<80 else "roamer"
		e["ecology_role"]=role
		e["ecology_home"]=e.pos
		e["ecology_search_enabled"]=true
		# Deterministic sentries may establish local watch posts on ordinary floors.
		if role=="sentry":e["ambush_enabled"]=true
		e["personality_enabled"]=true

func enemy_awareness(e:Dictionary)->int:
	if bool(e.get("monster_house",false)):return 8 if bool(e.get("house_tactical",false)) else 9999
	match str(e.get("ecology_role","hunter")):
		"scout":return 8
		"sentry":return 4
		_:return 6

# Ecology actors retain a bounded last-known target, never refresh it outside awareness.
func enemy_memory_duration(e:Dictionary)->int:
	if bool(e.get("personality_enabled",false)) and not bool(e.get("monster_house",false)) and enemy_combat_personality(e)=="hunter":return 6 if e.get("ecology_role","")=="scout" else 5
	match str(e.get("ecology_role","hunter")):
		"scout":return 6
		"sentry":return 2
		"roamer":return 3
		_:return 4

# Integer supercover traversal between tile centers. At an exact corner,
# both orthogonal neighbors must be open, matching strict diagonal movement.
func enemy_line_of_sight(origin:Vector2i,target:Vector2i)->bool:
	if not ai_cache_active:return compute_enemy_line_of_sight(origin,target)
	# Supercover LOS is symmetric; use one canonical key for either direction.
	var reversed:bool=origin.x>target.x or (origin.x==target.x and origin.y>target.y)
	var key:=Vector4i(target.x,target.y,origin.x,origin.y) if reversed else Vector4i(origin.x,origin.y,target.x,target.y)
	if ai_los_cache.has(key):
		ai_cache_hits+=1;return bool(ai_los_cache[key])
	var visible:bool=compute_enemy_line_of_sight(origin,target)
	ai_cache_misses+=1
	if ai_los_cache.size()<AI_LOS_CAP:ai_los_cache[key]=visible
	return visible

func compute_enemy_line_of_sight(origin:Vector2i,target:Vector2i)->bool:
	if not cells.has(origin) or not cells.has(target):return false
	var delta:Vector2i=target-origin
	var nx:int=absi(delta.x)
	var ny:int=absi(delta.y)
	var sx:int=signi(delta.x)
	var sy:int=signi(delta.y)
	var ix:int=0
	var iy:int=0
	var p:Vector2i=origin
	while ix<nx or iy<ny:
		var decision:int=(1+2*ix)*ny-(1+2*iy)*nx
		if decision==0:
			if not cells.has(p+Vector2i(sx,0)) or not cells.has(p+Vector2i(0,sy)):return false
			p+=Vector2i(sx,sy);ix+=1;iy+=1
		elif decision<0:
			p.x+=sx;ix+=1
		else:
			p.y+=sy;iy+=1
		if not cells.has(p):return false
	return true

func clear_enemy_search(e:Dictionary)->void:
	e.erase("search_anchor");e.erase("search_until");e.erase("search_visited");e.erase("search_claim");e.erase("search_claim_turn")

# Search intent is local and expires; only use visible peers with the same
# remembered anchor. Claims are advisory and never affect physical movement.
func enemy_hunter_search_claims(e:Dictionary,anchor:Vector2i)->Dictionary:
	var claims:Dictionary={}
	for other in enemies:
		if other.get("search_anchor",Vector2i(-9999,-9999))!=anchor or not other.has("search_claim"):continue
		var age:int=turns-int(other.get("search_claim_turn",-9999))
		if age<0 or age>1 or turns>int(other.get("search_until",-1)) or not enemy_squad_partner(e,other):continue
		var q:Vector2i=other.search_claim
		if cells.has(q) and enemy_line_of_sight(e.pos,q):claims[q]=true
	return claims

func enemy_hunter_search_step(e:Dictionary,anchor:Vector2i,visited:Dictionary,radius:int)->Vector2i:
	var origin:Vector2i=e.pos
	var claims:Dictionary=enemy_hunter_search_claims(e,anchor)
	var phase:int=posmod(int(e.get("uid",0))+turns,4)
	var budget:int=maxi(0,int(e.get("search_until",turns))-turns+1)
	var queue:Array[Vector2i]=[origin]
	var depths:Dictionary={origin:0}
	var first:Dictionary={origin:origin}
	var best:Vector2i=origin
	var destination:Vector2i=origin
	var best_score:int=-2147483647
	var cursor:int=0
	var heading:Vector2i=e.get("search_heading",Vector2i.ZERO) if turns-int(e.get("search_heading_turn",-9999))<=3 and e.get("search_heading_anchor",Vector2i.ZERO)==anchor else Vector2i.ZERO
	while cursor<queue.size():
		var here:Vector2i=queue[cursor];cursor+=1
		var depth:int=int(depths[here])
		if depth>0 and not visited.has(here) and not claims.has(here):
			var score:int=12-depth*4
			if heading in DIR:
				var offset:Vector2i=here-anchor
				score+=clampi(offset.x*heading.x+offset.y*heading.y,-2,2)*2
			if enemy_combat_personality(e)=="territorial" and distance(here,e.get("ecology_home",anchor))>radius:score-=4
			if enemy_terrain_kind(here)=="dead_end":score-=2
			if score>best_score:best_score=score;best=first[here];destination=here
		if depth>=mini(3,budget):continue
		for i in range(4):
			var q:Vector2i=here+DIR[(phase+i)%4]
			if depths.has(q) or distance(q,anchor)>radius or claims.has(q) or not enemy_ambush_safe_tile(q):continue
			depths[q]=depth+1;first[q]=q if depth==0 else first[here];queue.append(q)
	if best==origin:
		clear_enemy_search(e);return origin
	e["search_claim"]=destination;e["search_claim_turn"]=turns
	return best

func enemy_search_target(e:Dictionary)->Vector2i:
	var origin:Vector2i=e.pos
	if not e.has("search_anchor"):return origin
	var anchor:Vector2i=e.search_anchor
	if turns>int(e.get("search_until",-1)):
		clear_enemy_search(e);return origin
	var visited:Dictionary=e.get("search_visited",{})
	visited[origin]=true;e["search_visited"]=visited
	var radius:int=3 if e.get("ecology_role","")=="scout" else 2
	if bool(e.get("personality_enabled",false)):
		if enemy_combat_personality(e)=="hunter":radius=3
		return enemy_hunter_search_step(e,anchor,visited,radius)
	var phase:int=posmod(int(e.get("uid",0))+turns,4)
	for i in range(4):
		var q:Vector2i=origin+DIR[(phase+i)%4]
		if not cells.has(q) or visited.has(q) or distance(q,anchor)>radius or q==stairs or q==relic or q in side_rewards or traps.has(q) or enemy_at(q)>=0 or ally_at(q)>=0 or q==player:continue
		return q
	clear_enemy_search(e)
	return origin

# Only a witnessed voluntary cardinal step can contribute to a retreat pattern.
# Consecutive samples must agree on heading; forced displacement is not evidence.
var adaptive_walk_from:Vector2i=Vector2i.ZERO
var adaptive_walk_to:Vector2i=Vector2i.ZERO
var adaptive_walk_turn:int=-9999

func enemy_observe_movement(e:Dictionary,observed:Vector2i)->void:
	if not bool(e.get("ecology_search_enabled",false)):return
	var origin:Vector2i=e.pos
	enemy_review_prediction(e,observed)
	if charge_phase in ["underground","airborne","vanish"] or boon_active("decoy") or distance(origin,observed)>enemy_awareness(e) or not enemy_line_of_sight(origin,observed):
		e.erase("adaptive_heading");e.erase("adaptive_streak");e.erase("adaptive_seen_turn")
		return
	if int(e.get("adaptive_seen_turn",-9999))==turns:return
	var previous:Vector2i=e.get("adaptive_seen",observed)
	var consecutive:bool=int(e.get("adaptive_seen_turn",-9999))==turns-1
	var delta:Vector2i=observed-previous
	var voluntary:bool=adaptive_walk_turn==turns-1 and adaptive_walk_from==previous and adaptive_walk_to==observed
	var retreat:bool=false
	if consecutive and voluntary and delta in DIR:
		e["search_heading"]=delta;e["search_heading_turn"]=turns;e["search_heading_anchor"]=observed
		retreat=distance(origin,observed)>distance(origin,previous)
		# A flanker may be ahead of the player, while the player is fleeing
		# another visible nearby attacker. Both positions must be observable.
		if not retreat:
			for other in enemies:
				if enemy_squad_partner(e,other) and distance(other.pos,previous)<=3 and distance(other.pos,observed)>distance(other.pos,previous) and enemy_line_of_sight(other.pos,observed):
					retreat=true;break
	if retreat:
		e["adaptive_streak"]=mini(3,int(e.get("adaptive_streak",0))+1) if e.get("adaptive_heading",Vector2i.ZERO)==delta else 1
		e["adaptive_heading"]=delta
	else:
		e.erase("adaptive_heading");e.erase("adaptive_streak")
	e["adaptive_seen"]=observed;e["adaptive_seen_turn"]=turns

func enemy_retreat_prediction(e:Dictionary,target:Vector2i)->Vector2i:
	var threshold:int=1 if int(e.get("kind",0))==2 else 2
	# A personally observed ranged-hit pattern plus a witnessed retreat is
	# stronger evidence of kiting than a retreat alone.
	if bool(e.get("personality_enabled",false)) and enemy_counter_pattern(e,"ranged"):threshold=1
	if not bool(e.get("ecology_search_enabled",false)) or int(e.get("kind",0))==3 or bool(e.get("monster_house",false)):return target
	if turns<=int(e.get("prediction_retry",-9999)) or charge_phase in ["underground","airborne","vanish"] or boon_active("decoy"):return target
	if int(e.get("adaptive_seen_turn",-9999))!=turns or e.get("adaptive_seen",Vector2i.ZERO)!=target or int(e.get("adaptive_streak",0))<threshold:return target
	if enemy_survival_profile(e) not in ["aggressive","defensive"] or distance(e.pos,target)>enemy_awareness(e) or not enemy_line_of_sight(e.pos,target):return target
	var heading:Vector2i=e.get("adaptive_heading",Vector2i.ZERO)
	if heading not in DIR:return target
	var predicted:Vector2i=target+heading
	if not step_clear(target,heading) or not enemy_line_of_sight(e.pos,predicted) or predicted==stairs or predicted==relic or predicted in side_rewards or traps.has(predicted) or player_traps.has(predicted) or enemy_at(predicted)>=0 or ally_at(predicted)>=0:return target
	return predicted

# A prediction is a preference for one legal movement, never a guaranteed hit.
# Do not abandon pursuit unless the projected tile can be occupied this turn.
func enemy_adaptive_intercept_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0:return origin
	var predicted:Vector2i=enemy_retreat_prediction(e,target)
	if predicted==target or distance(origin,predicted)!=1:return origin
	return predicted

# A second projected tile is useful only at a visible real bottleneck.
# Search at most two cardinal movements; never reserve tiles or move twice.
func enemy_prediction_safe_tile(q:Vector2i,target:Vector2i)->bool:
	return cells.has(q) and q!=target and q!=player and q!=stairs and q!=relic and q not in side_rewards and not traps.has(q) and not player_traps.has(q) and enemy_at(q)<0 and ally_at(q)<0

func enemy_predictive_cutoff_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0:return origin
	var predicted:Vector2i=enemy_retreat_prediction(e,target)
	if predicted==target:return origin
	var heading:Vector2i=predicted-target
	var post:Vector2i=predicted+heading
	if not enemy_prediction_safe_tile(post,target) or not enemy_line_of_sight(origin,post) or distance(origin,post)>2:return origin
	if not cells.has(post+heading):return origin
	var openings:int=0
	for d in DIR:
		if cells.has(post+d):openings+=1
	if openings!=2:return origin
	if distance(origin,post)==1:return post
	for d in DIR:
		var q:Vector2i=origin+d
		if distance(q,post)!=1 or q==predicted or not enemy_prediction_safe_tile(q,target):continue
		if not enemy_line_of_sight(q,target) or distance(q,target)>distance(origin,target):continue
		return q
	return origin

func enemy_record_prediction(e:Dictionary,target:Vector2i)->void:
	e["prediction_turn"]=turns
	e["prediction_origin"]=target
	e["prediction_heading"]=e.get("adaptive_heading",Vector2i.ZERO)

func enemy_review_prediction(e:Dictionary,observed:Vector2i)->void:
	if not e.has("prediction_turn"):return
	var age:int=turns-int(e.prediction_turn)
	if age<=0:return
	# Only a directly witnessed voluntary deviation disproves the forecast.
	var origin:Vector2i=e.prediction_origin
	if age==1 and charge_phase not in ["underground","airborne","vanish"] and not boon_active("decoy") and distance(e.pos,observed)<=enemy_awareness(e) and enemy_line_of_sight(e.pos,observed) and adaptive_walk_turn==turns-1 and adaptive_walk_from==origin and adaptive_walk_to==observed:
		if observed-origin!=e.prediction_heading:e["prediction_retry"]=turns+2
	for key in ["prediction_turn","prediction_origin","prediction_heading"]:e.erase(key)

# Snapshot first-hand sightings before anyone moves. Only direct witnesses
# may alert nearby peers; recipients cannot retransmit reported coordinates.
const ENEMY_ALERT_RANGE:int=4
const ENEMY_ALERT_TTL:int=2

func enemy_alert_eligible(e:Dictionary)->bool:
	if not bool(e.get("ecology_search_enabled",false)) or int(e.get("kind",0))==3 or int(e.get("hp",0))<=0 or int(e.get("decoy_turns",0))>0:return false
	if int(e.get("sleep_turns",0))>0 or int(e.get("nightmare_turns",0))>0 or int(e.get("paused_turns",0))>0 or int(e.get("wrapped_turns",0))>0 or int(e.get("infatuated_turns",0))>0 or int(e.get("confusion_turns",0))>0 or str(e.get("major_status","")) in ["freeze","paralysis"]:return false
	return true

func enemy_clear_alert(e:Dictionary)->void:
	for key in ["alert_tile","alert_turn","alert_until","alert_source"]:e.erase(key)

func enemy_share_alerts(observed:Vector2i)->void:
	if boon_active("decoy"):
		for e in enemies:
			enemy_clear_alert(e)
			e.erase("contact_tile");e.erase("contact_turn")
		return
	if charge_phase in ["underground","airborne","vanish"]:return
	var witnesses:Array[Dictionary]=[]
	var listeners:Array[Dictionary]=[]
	for e in enemies:
		if int(e.get("alert_until",-1))<turns:enemy_clear_alert(e)
		if not enemy_alert_eligible(e):continue
		if distance(e.pos,observed)<=enemy_awareness(e) and enemy_line_of_sight(e.pos,observed):
			witnesses.append(e)
			if bool(e.get("personality_enabled",false)):
				e["contact_tile"]=observed;e["contact_turn"]=turns
			enemy_clear_alert(e)
		else:listeners.append(e)
	for listener in listeners:
		var best:Dictionary={}
		var best_gap:int=ENEMY_ALERT_RANGE+1
		for witness in witnesses:
			var gap:int=distance(listener.pos,witness.pos)
			if gap>mini(ENEMY_ALERT_RANGE,enemy_awareness(listener)) or gap>best_gap or distance(listener.pos,observed)>enemy_awareness(listener)+2:continue
			if not enemy_line_of_sight(listener.pos,witness.pos):continue
			if gap==best_gap and not best.is_empty() and int(witness.get("uid",0))>=int(best.get("uid",0)):continue
			best=witness;best_gap=gap
		if best.is_empty():
			enemy_share_remembered_contact(listener)
			continue
		listener["alert_tile"]=observed;listener["alert_turn"]=turns
		listener["alert_until"]=turns+ENEMY_ALERT_TTL;listener["alert_source"]=int(best.get("uid",-1))

# Only a first-hand snapshot may be reported. Reports never renew the
# original observation timestamp or populate another actor's contact memory.
func enemy_share_remembered_contact(listener:Dictionary)->void:
	if not bool(listener.get("personality_enabled",false)) or not enemy_alert_eligible(listener):return
	var best:Dictionary={}
	var best_turn:int=maxi(int(listener.get("last_seen_turn",-9999)),int(listener.get("alert_turn",-9999)))
	var best_gap:int=ENEMY_ALERT_RANGE+1
	for other in enemies:
		if not other.has("contact_tile") or not enemy_alert_eligible(other) or not enemy_squad_partner(listener,other):continue
		var seen:int=int(other.get("contact_turn",-9999))
		var age:int=turns-seen
		var tile:Vector2i=other.contact_tile
		if age<1 or age>ENEMY_ALERT_TTL or seen<=int(listener.get("last_seen_turn",-9999)) or seen<=int(listener.get("alert_turn",-9999)):continue
		if not cells.has(tile) or tile==listener.pos or distance(listener.pos,tile)>enemy_awareness(listener)+2:continue
		var gap:int=distance(listener.pos,other.pos)
		if seen<best_turn or (seen==best_turn and gap>best_gap):continue
		if seen==best_turn and gap==best_gap and not best.is_empty() and int(other.get("uid",0))>=int(best.get("uid",0)):continue
		best=other;best_turn=seen;best_gap=gap
	if best.is_empty():return
	listener["alert_tile"]=best.contact_tile;listener["alert_turn"]=best_turn
	listener["alert_until"]=best_turn+ENEMY_ALERT_TTL;listener["alert_source"]=int(best.get("uid",-1))

# Witness the loss itself, not its attacker. No hidden target coordinates
# or damage attribution are inferred from an ally disappearing.
func enemy_record_witnessed_loss(fallen:Dictionary)->void:
	if int(fallen.get("decoy_turns",0))>0:return
	for observer in enemies:
		if not bool(observer.get("personality_enabled",false)) or not enemy_alert_eligible(observer) or observer.pos==fallen.pos:continue
		if distance(observer.pos,fallen.pos)>mini(ENEMY_ALERT_RANGE,enemy_awareness(observer)) or not enemy_line_of_sight(observer.pos,fallen.pos):continue
		# Several casualties can be removed in the same turn. Do not overwrite
		# a still usable, witnessed frontline opening with a less useful loss.
		# Revalidate the prior post against current safety, reservations and sight.
		if int(observer.get("squad_loss_turn",-9999))==turns and enemy_witnessed_vacancy_step(observer,player)!=observer.pos:continue
		observer["squad_loss_turn"]=turns
		observer["squad_loss_tile"]=fallen.pos

func enemy_recent_squad_loss(e:Dictionary)->bool:
	var age:int=turns-int(e.get("squad_loss_turn",-9999))
	return age>=0 and age<=3 and bool(e.get("personality_enabled",false))

func enemy_alert_target(e:Dictionary)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_alert_eligible(e) or not e.has("alert_tile"):return origin
	var reported:Vector2i=e.alert_tile
	if turns>int(e.get("alert_until",-1)) or not cells.has(reported) or reported==origin:
		enemy_clear_alert(e);return origin
	# Prefer equally recent or newer firsthand observations.
	if int(e.get("last_seen_turn",-9999))>=int(e.get("alert_turn",-1)) and turns<=int(e.get("last_seen_until",-1)):return origin
	return reported

func enemy_pursuit_target(e:Dictionary,observed:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not e.has("ecology_role") or (bool(e.get("monster_house",false)) and not bool(e.get("house_tactical",false))):
		return observed if distance(origin,observed)<=enemy_awareness(e) else origin
	if charge_phase not in ["underground","airborne","vanish"] and not boon_active("decoy") and distance(origin,observed)<=enemy_awareness(e) and enemy_line_of_sight(origin,observed):
		clear_enemy_search(e)
		enemy_clear_alert(e)
		e["last_seen_turn"]=turns
		if e.has("ambush_post"):enemy_clear_ambush(e);e["ambush_retry"]=turns+3
		e["last_seen_player"]=observed
		e["last_seen_until"]=turns+enemy_memory_duration(e)
		return observed
	var reported:Vector2i=enemy_alert_target(e)
	if reported!=origin:
		clear_enemy_search(e)
		if e.has("ambush_post"):enemy_clear_ambush(e);e["ambush_retry"]=turns+3
		return reported
	var remembered:Vector2i=e.get("last_seen_player",origin)
	if e.has("last_seen_player") and remembered==origin and turns<=int(e.get("last_seen_until",-1)) and bool(e.get("ecology_search_enabled",false)):
		var budget:int=3 if e.get("ecology_role","")=="scout" else 1 if e.get("ecology_role","")=="sentry" else 2
		if bool(e.get("personality_enabled",false)) and enemy_combat_personality(e)=="hunter" and e.get("ecology_role","")!="sentry":budget=mini(4,budget+1)
		e["search_anchor"]=origin;e["search_until"]=turns+budget-1;e["search_visited"]={}
	if turns>int(e.get("last_seen_until",-1)) or remembered==origin or not cells.has(remembered):
		e.erase("last_seen_player");e.erase("last_seen_until")
		return enemy_search_target(e)
	return remembered

# Tactical repositioning uses the actual species attack geometry. No extra attacks
# or movement turns are granted. Only actors that can see the target may flank.
# Local floor topology, independent of the dungeon theme and current occupants.
func enemy_terrain_kind(tile:Vector2i)->String:
	if not ai_cache_active:return compute_enemy_terrain_kind(tile)
	if ai_topology_cache.has(tile):
		ai_cache_hits+=1;return str(ai_topology_cache[tile])
	var result:String=compute_enemy_terrain_kind(tile)
	ai_cache_misses+=1
	if ai_topology_cache.size()<AI_TOPOLOGY_CAP:ai_topology_cache[tile]=result
	return result

func compute_enemy_terrain_kind(tile:Vector2i)->String:
	if not cells.has(tile):return "wall"
	var openings:Array[Vector2i]=[]
	for d in DIR:
		if cells.has(tile+d):openings.append(d)
	if openings.size()<=1:return "dead_end"
	if openings.size()==2:return "corridor" if openings[0]+openings[1]==Vector2i.ZERO else "corner"
	for room in rooms:
		if room.has_point(tile):
			for d in openings:
				var q:Vector2i=tile+d
				if room.has_point(q):continue
				var count:int=0
				for side in DIR:
					if cells.has(q+side):count+=1
				if count==2 and cells.has(q+d):return "doorway"
	return "open"

# Ranged creatures value safe lateral exits and avoid clogging choke points.
# A real, currently usable friendly firing lane takes priority over terrain.
func enemy_terrain_position_bonus(e:Dictionary,q:Vector2i,target:Vector2i)->int:
	if not bool(e.get("personality_enabled",false)):return 0
	var origin:Vector2i=e.pos
	var kind:String=enemy_terrain_kind(q)
	var score:int=0
	match kind:
		"dead_end":score=-8
		"corridor","doorway":score=-4
		"corner":score=1
		"open":score=2
	var exits:int=0
	for d in DIR:
		var next:Vector2i=q+d
		if next!=origin and next!=target and enemy_ambush_safe_tile(next):exits+=1
	score+=mini(exits,3)
	for other in enemies:
		if enemy_squad_partner(e,other) and enemy_line_of_sight(other.pos,target) and enemy_relief_blocks_lane(other,q,target):return score-12
	return score

# A defensive actor can cover an approach two tiles from the player, but
# only as a fallback when an ordinary attack is not already executable.
func enemy_environment_guard_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_reinforcement_eligible(e,target) or enemy_survival_profile(e)!="defensive" or int(e.get("stuck_turns",0))>0:return origin
	if distance(origin,target)!=3 or turns<=int(e.get("environment_guard_turn",-9999))+2:return origin
	if enemy_push_attack_coverage(e,target)>0:return origin
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	for d in DIR:
		var q:Vector2i=origin+d
		if distance(q,target)!=2 or not enemy_ambush_safe_tile(q) or reserved.has(q) or not enemy_line_of_sight(q,target):continue
		if enemy_terrain_kind(q) not in ["corridor","doorway"]:continue
		var support:bool=false
		var blocked:bool=false
		for other in enemies:
			if not enemy_squad_partner(e,other) or not enemy_line_of_sight(other.pos,target):continue
			if enemy_relief_blocks_lane(other,q,target):blocked=true;break
			if distance(other.pos,target)==1 and int(other.hp)*2>maxi(1,int(other.get("max_hp",other.hp))):support=true
		if not blocked and support:return q
	return origin

# Only committed pursuit movements are remembered. A stationary visible target
# makes an immediate reversal a possible failed flank, not a permanent taboo.
func enemy_strategy_record_step(e:Dictionary,origin:Vector2i,destination:Vector2i,target:Vector2i)->void:
	if not bool(e.get("personality_enabled",false)) or target!=player or charge_phase in ["underground","airborne","vanish"] or boon_active("decoy"):return
	if distance(origin,target)>enemy_awareness(e) or not enemy_line_of_sight(origin,target) or distance(origin,destination)!=1:return
	e["strategy_from"]=origin;e["strategy_to"]=destination;e["strategy_target"]=target;e["strategy_turn"]=turns

func enemy_strategy_reversal(e:Dictionary,proposed:Vector2i,target:Vector2i)->bool:
	return bool(e.get("personality_enabled",false)) and enemy_opportunity_eligible(e) and target==player and charge_phase not in ["underground","airborne","vanish"] and int(e.get("strategy_turn",-9999))==turns-1 and e.get("strategy_target",Vector2i.ZERO)==target and e.get("strategy_to",Vector2i.ZERO)==e.pos and e.get("strategy_from",Vector2i.ZERO)==proposed

func enemy_strategy_attack_tile(e:Dictionary,q:Vector2i,target:Vector2i)->bool:
	if distance(q,target)==1:return true
	var species:String=str(e.get("species",""))
	var skill:Array=signature_skill(e)
	if int(e.get("cooldown",0))<=0 and enemy_move_allowed(e,"primary") and enemy_projected_attack_aim(e,q,target,str(ATTACK_PATTERNS.get(species,"line")),int(skill[0]))!=Vector2i.ZERO:return true
	if int(e.get("alt_cooldown",0))<=0 and SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary"):
		var alt:Array=SECONDARY_SKILLS[species]
		return enemy_projected_attack_aim(e,q,target,str(alt[1]),int(alt[0]))!=Vector2i.ZERO
	return false

# A stalled pursuit may take a short lateral detour, but only if it opens
# a genuinely useful attack position. Never override intentional waits.
# A fully occupied cardinal frontline can be a successful encirclement,
# not a navigation defect. Every occupying actor must be a live visible peer.
# Physical congestion is distinct from an active tactical frontline.
# Sleeping or otherwise incapacitated peers still occupy real tiles.
func enemy_occupied_frontline(e:Dictionary,target:Vector2i)->bool:
	if not enemy_opportunity_eligible(e) or distance(e.pos,target)<=1:return false
	if enemy_strategy_attack_tile(e,e.pos,target):return false
	var occupied:int=0
	for d in DIR:
		var q:Vector2i=target+d
		if not cells.has(q):continue
		if not enemy_line_of_sight(e.pos,q):return false
		var index:int=enemy_at(q)
		if index<0 or int(enemies[index].get("hp",0))<=0:return false
		occupied+=1
	return occupied>=2

func enemy_encircled_frontline(e:Dictionary,target:Vector2i)->bool:
	if not enemy_opportunity_eligible(e) or not enemy_live_contact(e,target) or distance(e.pos,target)<=1:return false
	if enemy_strategy_attack_tile(e,e.pos,target):return false
	# Walls close cardinal approach lanes too, but a wall alone is not a squad.
	# Require at least two active peers and never treat traps as solid walls.
	var frontline_count:int=0
	for d in DIR:
		var q:Vector2i=target+d
		if not cells.has(q):continue
		var index:int=enemy_at(q)
		if index<0 or not enemy_squad_partner(e,enemies[index]):return false
		frontline_count+=1
	return frontline_count>=2

# Local memo tables belong to one pure planning call. No cached occupancy
# result survives a movement, attack, target change or enemy turn.
func enemy_recovery_lane_blocked(peers:Array[Dictionary],q:Vector2i,target:Vector2i,memo:Dictionary)->bool:
	if memo.has(q):return bool(memo[q])
	var blocked:bool=false
	for other in peers:
		if enemy_relief_blocks_lane(other,q,target):blocked=true;break
	memo[q]=blocked
	return blocked

func enemy_recovery_attack_tile(e:Dictionary,q:Vector2i,target:Vector2i,memo:Dictionary)->bool:
	if memo.has(q):return bool(memo[q])
	# A footprint may bend around a corner, but a recovery destination must
	# also satisfy the live dispatcher\'s perception from that projected tile.
	var legal:bool=distance(q,target)<=enemy_awareness(e) and enemy_line_of_sight(q,target) and enemy_strategy_attack_tile(e,q,target)
	memo[q]=legal
	return legal

# Hold states are short-lived evidence, not persistent orders. Expire them
# before dispatch even if the actor is sleeping or chooses another action.
func enemy_expire_frontline_holds(e:Dictionary)->void:
	# Staging evidence is local to a committed position and a two-turn window.
	if e.has("stage_turn") or e.has("stage_target") or e.has("stage_position"):
		var stage_age:int=turns-int(e.get("stage_turn",-9999))
		if stage_age<0 or stage_age>2 or not e.has("stage_target") or e.get("stage_position",Vector2i(-9999,-9999))!=e.pos:
			e.erase("stage_turn");e.erase("stage_target");e.erase("stage_position")
	for key in ["reserve_hold","congestion_hold","lane_hold"]:
		var age:int=turns-int(e.get(key+"_turn",-9999))
		if age<0 or age>2:
			e.erase(key+"_turn");e.erase(key+"_target")

# A nearby free attack post is an immediate opportunity, not a long detour.
# This fallback runs only after normal pursuit and deliberate holds are resolved.
# A cheap adjacent opportunity is not a long detour and must not start
# the detour cooldown. Commit telemetry only after the movement succeeds.
func enemy_commit_recovery(e:Dictionary,origin:Vector2i,destination:Vector2i,mode:String)->void:
	if destination==origin or mode not in ["immediate","detour","party","stage"]:return
	e["recovery_turn"]=turns;e["recovery_mode"]=mode
	if mode in ["detour","party"]:e["unstall_turn"]=turns
	if mode!="stage":
		e.erase("stage_turn");e.erase("stage_target");e.erase("stage_position")
	elif mode=="stage":
		e["stage_turn"]=turns;e["stage_target"]=player;e["stage_position"]=destination

# A witnessed vacant frontline post is a concrete opportunity. Prefer it
# only when it is adjacent, still empty, safe, and directly useful.
func enemy_witnessed_vacancy_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_opportunity_eligible(e) or not enemy_live_contact(e,target) or int(e.get("stuck_turns",0))>0:return origin
	if shield_turns>0 and shield_kind=="protect":return origin
	if turns-int(e.get("squad_loss_turn",-9999)) not in [0,1] or not e.has("squad_loss_tile"):return origin
	if enemy_strategy_attack_tile(e,origin,target):return origin
	var post:Vector2i=e.squad_loss_tile
	if distance(origin,post)!=1 or distance(post,target)!=1 or not enemy_ambush_safe_tile(post):return origin
	if not enemy_line_of_sight(origin,post) or not enemy_line_of_sight(post,target):return origin
	if enemy_pack_reserved_posts(e,target).has(post):return origin
	for other in enemies:
		if enemy_squad_partner(e,other) and enemy_relief_blocks_lane(other,post,target):return origin
	return post

func enemy_immediate_recovery_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_opportunity_eligible(e) or not enemy_live_contact(e,target) or int(e.get("stuck_turns",0))>0:return origin
	if shield_turns>0 and shield_kind=="protect":return origin
	if distance(origin,target)!=2 or enemy_strategy_attack_tile(e,origin,target):return origin
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var memo:Dictionary={}
	var best:Vector2i=origin
	var best_score:int=-2147483647
	for d in DIR:
		var q:Vector2i=origin+d
		if distance(q,target)!=1 or not enemy_ambush_safe_tile(q) or reserved.has(q) or not enemy_line_of_sight(q,target):continue
		if enemy_recovery_lane_blocked(peers,q,target,memo):continue
		var score:int=enemy_terrain_position_bonus(e,q,target)
		if enemy_strategy_reversal(e,q,target):score-=4
		if score>best_score:best=q;best_score=score
	return best

# A visible opening in a crowded frontline is evidence for a short detour,
# rather than a reason to wait for a second failed pursuit.
func enemy_trace_recovery(e:Dictionary,stage:String,step:Vector2i)->void:
	if ai_recovery_trace_uid<0 or int(e.get("uid",-1))!=ai_recovery_trace_uid:return
	var origin:Vector2i=e.pos
	var posts:Array[Dictionary]=[]
	var reserved:Dictionary=enemy_pack_reserved_posts(e,player)
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var memo:Dictionary={}
	for y in range(origin.y-3,origin.y+4):
		for x in range(origin.x-3,origin.x+4):
			var q:=Vector2i(x,y)
			if distance(origin,q)>3 or not cells.has(q):continue
			var index:int=enemy_at(q)
			var lane_owners:Array[int]=[]
			var lane_evidence:Array[Dictionary]=[]
			for peer in peers:
				if enemy_relief_blocks_lane(peer,q,player):
					lane_owners.append(int(peer.get("uid",-1)))
					lane_evidence.append({"uid":int(peer.get("uid",-1)),"pos":peer.pos,"species":peer.get("species",""),"windup":bool(peer.get("windup",false)),"aim":peer.get("aim",Vector2i.ZERO),"spent":enemy_phase_spent.has(int(peer.get("uid",-1))),"cooldown":int(peer.get("cooldown",0)),"alt_cooldown":int(peer.get("alt_cooldown",0)),"pp_primary":enemy_move_pp(peer,"primary"),"pp_secondary":enemy_move_pp(peer,"secondary")})
			posts.append({"tile":q,"enemy":int(enemies[index].get("uid",-1)) if index>=0 else -1,"ally":ally_at(q),"safe":enemy_ambush_safe_tile(q),"reserved":reserved.has(q),"lane_blocked":enemy_recovery_lane_blocked(peers,q,player,memo),"lane_owners":lane_owners,"lane_evidence":lane_evidence,"sees_target":enemy_line_of_sight(q,player),"attack_post":enemy_recovery_attack_tile(e,q,player,{})})
	ai_recovery_trace={"turn":turns,"uid":ai_recovery_trace_uid,"stage":stage,"origin":origin,"player":player,"step":step,"stall_count":int(e.get("stall_count",0)),"stall_turn":int(e.get("stall_turn",-1)),"open_frontline":enemy_open_frontline_detour(e,player),"protect":shield_turns>0 and shield_kind=="protect","posts":posts}

# A free tile is not a useful melee opening if occupying it interrupts a
# currently usable friendly firing lane. Require actual visible evidence.
func enemy_firing_lane_frontline(e:Dictionary,target:Vector2i)->bool:
	if not enemy_opportunity_eligible(e) or not enemy_live_contact(e,target) or int(e.get("stuck_turns",0))>0 or distance(e.pos,target)<=1:return false
	if shield_turns>0 and shield_kind=="protect":return false
	if enemy_strategy_attack_tile(e,e.pos,target):return false
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var memo:Dictionary={}
	var occupied:int=0
	var lanes:int=0
	for d in DIR:
		var q:Vector2i=target+d
		if not cells.has(q):continue
		if not enemy_line_of_sight(e.pos,q):return false
		var index:int=enemy_at(q)
		if index>=0 and int(enemies[index].get("hp",0))>0:
			occupied+=1
		elif enemy_ambush_safe_tile(q) and enemy_recovery_lane_blocked(peers,q,target,memo):
			lanes+=1
		else:return false
	return occupied>=2 and lanes>0

# A recent lane hold may be invalidated by visible movement or a broken
# formation. Do not require the old crowd to still exist before retrying.
# Capture the actual actor-time occupancy, not the end-of-phase board.
# This is evidence only: a guarded frontline is not automatically proof
# that every possible alternative action was exhausted.
func enemy_audit_frontline_wait(e:Dictionary,target:Vector2i)->void:
	if not ai_wait_audit_enabled or not enemy_live_contact(e,target):return
	var occupied:int=0
	var guards:int=0
	var free:int=0
	var lane:int=0
	var unknown:int=0
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var memo:Dictionary={}
	for d in DIR:
		var q:Vector2i=target+d
		if not cells.has(q):continue
		if not enemy_line_of_sight(e.pos,q):unknown+=1;continue
		var index:int=enemy_at(q)
		if index>=0 and int(enemies[index].get("hp",0))>0:occupied+=1
		elif ally_at(q)>=0:guards+=1
		elif enemy_ambush_safe_tile(q):
			if enemy_recovery_lane_blocked(peers,q,target,memo):lane+=1
			else:free+=1
		else:unknown+=1
	var reason:String="unresolved"
	if unknown==0 and free==0:
		if lane>0 and occupied>=2 and guards==0:reason="friendly_lane"
		elif guards>0 and occupied+guards>=2:reason="opposing_guard"
		elif occupied>=2 and lane==0:reason="occupied_frontline"
	ai_wait_audit[int(e.get("uid",-1))]={"turn":turns,"position":e.pos,"target":target,"reason":reason,"occupied":occupied,"guards":guards,"free":free,"lanes":lane,"unknown":unknown}

func enemy_released_firing_post(e:Dictionary,target:Vector2i)->bool:
	if not enemy_opportunity_eligible(e) or not enemy_live_contact(e,target) or int(e.get("stuck_turns",0))>0:return false
	if shield_turns>0 and shield_kind=="protect":return false
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var memo:Dictionary={}
	for d in DIR:
		var q:Vector2i=target+d
		if enemy_ambush_safe_tile(q) and not reserved.has(q) and enemy_line_of_sight(e.pos,q) and not enemy_recovery_lane_blocked(peers,q,target,memo):return true
	return false

func enemy_open_frontline_detour(e:Dictionary,target:Vector2i)->bool:
	if not enemy_opportunity_eligible(e) or not enemy_live_contact(e,target) or int(e.get("stuck_turns",0))>0:return false
	if shield_turns>0 and shield_kind=="protect":return false
	var occupied:int=0
	var open:bool=false
	for d in DIR:
		var q:Vector2i=target+d
		if not cells.has(q) or not enemy_line_of_sight(e.pos,q):continue
		var index:int=enemy_at(q)
		if index>=0 and int(enemies[index].get("hp",0))>0:occupied+=1
		elif enemy_ambush_safe_tile(q):open=true
	return occupied>=2 and open

# Prepare just outside an active firing lane rather than occupy its reserved
# attack post. Stop at distance two so a waiting actor cannot orbit the lane.
func enemy_firing_lane_stage_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	# Staging has its own short anti-oscillation interval, not a detour cooldown.
	if e.get("stage_target",Vector2i.ZERO)==target and e.get("stage_position",Vector2i(-9999,-9999))==origin and turns-int(e.get("stage_turn",-9999)) in [0,1,2]:return origin
	if not enemy_open_frontline_detour(e,target) or enemy_strategy_attack_tile(e,origin,target):return origin
	if int(e.get("stall_count",0))<1 or int(e.get("stall_turn",-9999))!=turns-1 or e.get("stall_target",Vector2i.ZERO)!=target:return origin
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var memo:Dictionary={}
	var best:Vector2i=origin
	var best_score:int=-2147483647
	for d in DIR:
		var post:Vector2i=target+d
		if distance(origin,post)!=3 or not enemy_ambush_safe_tile(post) or reserved.has(post) or not enemy_line_of_sight(origin,post):continue
		if not enemy_recovery_lane_blocked(peers,post,target,memo):continue
		for heading in DIR:
			var q:Vector2i=origin+heading
			if distance(q,post)!=2 or not enemy_ambush_safe_tile(q) or reserved.has(q) or enemy_strategy_reversal(e,q,target):continue
			if not enemy_line_of_sight(q,post) or not enemy_line_of_sight(q,target) or enemy_recovery_lane_blocked(peers,q,target,memo):continue
			# At distance two, require a real intermediate tile that can reach
			# the post once its firing reservation expires. The final post
			# remains reserved; no movement into it is authorized here.
			var has_access:bool=false
			for access_dir in DIR:
				var access:Vector2i=q+access_dir
				if distance(access,post)!=1 or not enemy_ambush_safe_tile(access) or reserved.has(access):continue
				if not enemy_line_of_sight(access,target) or enemy_recovery_lane_blocked(peers,access,target,memo):continue
				has_access=true;break
			if not has_access:continue
			var score:int=enemy_terrain_position_bonus(e,q,target)+distance(origin,target)-distance(q,target)
			if score>best_score:best=q;best_score=score
	return best

func enemy_unstall_step(e:Dictionary,target:Vector2i,allow_staging:bool=true)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_opportunity_eligible(e) or not enemy_live_contact(e,target) or int(e.get("stuck_turns",0))>0:return origin
	if shield_turns>0 and shield_kind=="protect":return origin
	if distance(origin,target)<=1 or enemy_strategy_attack_tile(e,origin,target):return origin
	# A reserve immediately retries when a previously closed frontline opens.
	# A recently observed escape of one or two tiles also invalidates the old
	# formation. Live contact above is mandatory; this does not reveal hidden movement.
	var old_reserve_target:Vector2i=e.get("reserve_hold_target",target)
	var old_congestion_target:Vector2i=e.get("congestion_hold_target",target)
	var reserve_reentry:bool=distance(old_reserve_target,target)<=2 and turns-int(e.get("reserve_hold_turn",-9999)) in [1,2] and not enemy_encircled_frontline(e,target)
	var congestion_reentry:bool=distance(old_congestion_target,target)<=2 and turns-int(e.get("congestion_hold_turn",-9999)) in [1,2] and not enemy_occupied_frontline(e,target)
	var lane_reentry:bool=false
	var old_lane_target:Vector2i=e.get("lane_hold_target",target)
	if turns-int(e.get("lane_hold_turn",-9999)) in [1,2] and distance(old_lane_target,target)<=2:
		lane_reentry=enemy_released_firing_post(e,target)
	# A committed staging move consumes a turn, so its old stall timestamp
	# is no longer consecutive. Retry a newly released post without requiring
	# another idle turn, but keep the same live-contact and safety checks.
	var stage_reentry:bool=false
	var staged_target:Vector2i=e.get("stage_target",target)
	if turns-int(e.get("stage_turn",-9999)) in [1,2] and e.get("stage_position",Vector2i(-9999,-9999))==origin and distance(staged_target,target)<=2:
		stage_reentry=enemy_released_firing_post(e,target)
	# A witnessed casualty can open a new route before the normal stall
	# threshold. Only retry once per recent loss after a committed detour.
	var loss_turn:int=int(e.get("squad_loss_turn",-9999))
	var loss_reentry:bool=turns-loss_turn in [0,1] and int(e.get("unstall_turn",-9999))<loss_turn and int(e.get("stall_count",0))>=1 and e.get("stall_target",Vector2i.ZERO)==target and int(e.get("stall_turn",-9999))==turns-1 and not enemy_occupied_frontline(e,target)
	var early_detour:bool=false
	if not reserve_reentry and not congestion_reentry and not loss_reentry and not lane_reentry and not stage_reentry:
		if int(e.get("stall_count",0))<1 or e.get("stall_target",Vector2i.ZERO)!=target or int(e.get("stall_turn",-9999))!=turns-1:return origin
		if turns<=int(e.get("unstall_turn",-9999))+3:return origin
		if int(e.get("stall_count",0))<2:
			if not enemy_open_frontline_detour(e,target):return origin
			early_detour=true
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	# Partner eligibility is invariant throughout this pure planning call.
	var recovery_peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):recovery_peers.append(other)
	var lane_memo:Dictionary={}
	var attack_memo:Dictionary={}
	var best:Vector2i=origin
	var best_score:int=-2147483647
	for d in DIR:
		var q:Vector2i=origin+d
		if not enemy_ambush_safe_tile(q) or reserved.has(q) or not enemy_line_of_sight(q,target) or enemy_strategy_reversal(e,q,target):continue
		if enemy_recovery_lane_blocked(recovery_peers,q,target,lane_memo):continue
		var value:int=0
		if enemy_recovery_attack_tile(e,q,target,attack_memo):value=20
		else:
			for next_dir in DIR:
				var post:Vector2i=q+next_dir
				if post==origin or reserved.has(post) or not enemy_ambush_safe_tile(post) or not enemy_line_of_sight(post,target):continue
				if not enemy_recovery_lane_blocked(recovery_peers,post,target,lane_memo) and enemy_recovery_attack_tile(e,post,target,attack_memo):value=10;break
		if value==0:continue
		var score:int=value+enemy_terrain_position_bonus(e,q,target)+distance(origin,target)-distance(q,target)
		if score>best_score:best_score=score;best=q
	if best!=origin:return best
	# Local two-step options failed. Search a bounded safe detour around the
	# occupied frontline, keeping the observed target fixed for this decision.
	# Only the first step is executed; no teleport, extra turn or hidden tracking.
	var queue:Array[Vector2i]=[origin]
	var depth:Dictionary={origin:0}
	var first:Dictionary={}
	var cursor:int=0
	while cursor<queue.size() and cursor<96:
		var tile:Vector2i=queue[cursor];cursor+=1
		if tile!=origin and enemy_recovery_attack_tile(e,tile,target,attack_memo):return first[tile]
		# A witnessed opening can be four steps away around two occupied posts.
		# Retain the node cap, safe tiles and normal one-step action budget.
		if int(depth[tile])>=(4 if early_detour else 6):continue
		for d in DIR:
			var q:Vector2i=tile+d
			if depth.has(q) or not enemy_ambush_safe_tile(q) or reserved.has(q):continue
			if tile==origin and enemy_strategy_reversal(e,q,target):continue
			if enemy_recovery_lane_blocked(recovery_peers,q,target,lane_memo):continue
			depth[q]=int(depth[tile])+1
			first[q]=q if tile==origin else first[tile]
			queue.append(q)
	return enemy_firing_lane_stage_step(e,target) if allow_staging else origin

# When the visible player cannot be approached, a stalled actor may seek
# a legal attack position against a personally visible opposing ally.
# This is movement planning only; normal party targeting resolves the attack.
# A recovery route must lead to a target the ordinary dispatcher can use.
# Preserve boss tactics, area attack priority and credible finishing moves.
func enemy_party_pursuit_allowed(e:Dictionary,finish_priority:bool)->bool:
	return not finish_priority and not allies.is_empty() and not boon_active("decoy") and not bool(e.get("boss_tactical",false)) and not enemy_has_party_area_attack(e)

func enemy_unstall_party_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_opportunity_eligible(e) or not enemy_live_contact(e,target) or int(e.get("stuck_turns",0))>0 or allies.is_empty():return origin
	var stalls:int=int(e.get("stall_count",0))
	if stalls<1 or e.get("stall_target",Vector2i.ZERO)!=target or int(e.get("stall_turn",-9999))!=turns-1:return origin
	# A visible opposing creature guarding an adjacent player post is concrete
	# evidence for early recovery. Unrelated allies retain the two-stall gate.
	var early:bool=stalls==1
	if early and shield_turns>0 and shield_kind=="protect":return origin
	if turns<=int(e.get("unstall_turn",-9999))+3 or enemy_strategy_attack_tile(e,origin,target):return origin
	if not enemy_party_pursuit_allowed(e,enemy_risk_has_finisher(e)):return origin
	var visible:Array[Vector2i]=[]
	for a in allies:
		var q:Vector2i=a.pos
		if early and distance(q,target)!=1:continue
		if int(a.hp)>0 and distance(origin,q)<=enemy_awareness(e) and enemy_line_of_sight(origin,q):visible.append(q)
	if visible.is_empty():return origin
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var lane_memo:Dictionary={}
	var queue:Array[Vector2i]=[origin]
	var depth:Dictionary={origin:0}
	var first:Dictionary={}
	var cursor:int=0
	while cursor<queue.size() and cursor<48:
		var tile:Vector2i=queue[cursor];cursor+=1
		if tile!=origin:
			for a in visible:
				# A basic attack is guaranteed available in melee; keep the
				# projected opponent strictly nearer than the player so normal
				# party dispatch can also execute it when learned PP is empty.
				if distance(tile,a)==1 and distance(tile,target)>1 and enemy_line_of_sight(tile,a):return first[tile]
		if int(depth[tile])>=3:continue
		for d in DIR:
			var q:Vector2i=tile+d
			if depth.has(q) or reserved.has(q) or not enemy_ambush_safe_tile(q):continue
			if tile==origin and enemy_strategy_reversal(e,q,target):continue
			if enemy_recovery_lane_blocked(peers,q,target,lane_memo):continue
			depth[q]=int(depth[tile])+1;first[q]=q if tile==origin else first[tile];queue.append(q)
	return origin

func enemy_record_stall(e:Dictionary,target:Vector2i)->void:
	if not enemy_opportunity_eligible(e) or not enemy_live_contact(e,target) or int(e.get("stuck_turns",0))>0 or (shield_turns>0 and shield_kind=="protect"):return
	if int(e.get("stall_turn",-9999))==turns:return
	e["stall_count"]=mini(3,int(e.get("stall_count",0))+1) if e.get("stall_target",Vector2i.ZERO)==target and int(e.get("stall_turn",-9999))==turns-1 else 1
	e["stall_target"]=target;e["stall_turn"]=turns

func enemy_strategy_alternative(e:Dictionary,proposed:Vector2i,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_strategy_reversal(e,proposed,target) or enemy_strategy_attack_tile(e,proposed,target):return proposed
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var best:Vector2i=proposed
	var best_score:int=-2147483647
	for d in DIR:
		var q:Vector2i=origin+d
		if q==proposed or not enemy_ambush_safe_tile(q) or reserved.has(q) or not enemy_line_of_sight(q,target):continue
		if distance(q,target)>=distance(origin,target):continue
		var blocked:bool=false
		for other in enemies:
			if enemy_squad_partner(e,other) and enemy_line_of_sight(other.pos,target) and enemy_relief_blocks_lane(other,q,target):blocked=true;break
		if blocked:continue
		var score:int=enemy_terrain_position_bonus(e,q,target)+8*int(enemy_strategy_attack_tile(e,q,target))
		if score>best_score:best_score=score;best=q
	# If no better route exists, allow the reversal rather than freeze.
	return best

# Compare next-turn attack options across the four legal neighboring tiles.
# Project the actor vacating its original tile without mutating live occupancy.
func enemy_decision_attack_value(e:Dictionary,post:Vector2i,target:Vector2i)->float:
	var best:float=0.0
	if distance(post,target)==1:best=float(enemy_opportunity_damage(e,[],false,true))
	var species:String=str(e.get("species",""))
	var skill:Array=signature_skill(e)
	if not bool(skill[1]) and enemy_move_allowed(e,"primary") and int(e.get("cooldown",0))<=0:
		if enemy_projected_attack_aim(e,post,target,str(ATTACK_PATTERNS.get(species,"line")),int(skill[0]))!=Vector2i.ZERO:
			best=maxf(best,enemy_attack_score(e,skill,false))
	if SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary") and int(e.get("alt_cooldown",0))<=0:
		var alt:Array=SECONDARY_SKILLS[species]
		if enemy_projected_attack_aim(e,post,target,str(alt[1]),int(alt[0]))!=Vector2i.ZERO:
			best=maxf(best,enemy_attack_score(e,[alt[0],false,3,alt[3],alt[4],alt[5],"alt_"+species],true))
	return best

func enemy_decision_position_plan(e:Dictionary,target:Vector2i)->Dictionary:
	var origin:Vector2i=e.pos
	if target!=player or not enemy_opportunity_eligible(e) or int(e.get("kind",0))==3 or int(e.get("stuck_turns",0))>0:return {}
	if charge_phase in ["underground","airborne","vanish"] or (shield_turns>0 and shield_kind=="protect") or bool(e.get("monster_house",false)):return {}
	if enemy_decision_attack_value(e,origin,target)>0.0:return {}
	# Leave PP-exhausted melee actors to the existing pack and crowd planners.
	var species:String=str(e.get("species",""))
	var primary:Array=signature_skill(e)
	var primary_ready:bool=not bool(primary[1]) and enemy_move_allowed(e,"primary") and int(e.get("cooldown",0))<=0
	var secondary_ready:bool=SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary") and int(e.get("alt_cooldown",0))<=0
	if not primary_ready and not secondary_ready:return {}
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var best:Dictionary={}
	var best_score:float=0.0
	var gap:int=distance(origin,target)
	var phase:int=posmod(int(e.get("uid",0))+turns,4)
	for j in range(4):
		var q:Vector2i=origin+DIR[(phase+j)%4]
		if not enemy_ambush_safe_tile(q) or reserved.has(q) or not enemy_line_of_sight(q,target):continue
		if distance(q,target)>enemy_awareness(e):continue
		var blocked:bool=false
		for other in enemies:
			if enemy_squad_partner(e,other) and enemy_line_of_sight(other.pos,target) and enemy_relief_blocks_lane(other,q,target):blocked=true;break
		if blocked:continue
		var value:float=enemy_decision_attack_value(e,q,target)
		if value<=0.0:continue
		var score:float=value*3.0+float(gap-distance(q,target))*1.5+float(enemy_terrain_position_bonus(e,q,target))*.5
		if enemy_combat_personality(e)=="cautious" and distance(q,target)==1 and gap>1:score-=3.0
		if enemy_strategy_reversal(e,q,target):score-=2.0
		if enemy_repeated_push(e):score-=float(enemy_push_exposure(e,q,target))*.5
		if score>best_score:best_score=score;best={"step":q,"value":value,"score":score}
	return best

# A bounded lookahead compares firing posts two or three ordinary steps away.
# The target is the currently observed tile, not a guaranteed future position.
# Recompute next turn; never execute the forecast or spend its PP in advance.
const ENEMY_FORESIGHT_DEPTH:int=3
const ENEMY_FORESIGHT_NODE_CAP:int=25

func enemy_foresight_kits(e:Dictionary)->Array[Dictionary]:
	var kits:Array[Dictionary]=[]
	var species:String=str(e.get("species",""))
	var primary:Array=signature_skill(e)
	if enemy_move_allowed(e,"primary") and int(e.get("cooldown",0))<=0 and int(primary[0])>=2:
		var value:float=enemy_attack_score(e,primary,false)
		if bool(primary[1]):value*=.65
		if value>0.0:kits.append({"pattern":str(ATTACK_PATTERNS.get(species,"line")),"reach":int(primary[0]),"value":value,"charged":bool(primary[1]),"slot":"primary"})
	if SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary") and int(e.get("alt_cooldown",0))<=0:
		var alt:Array=SECONDARY_SKILLS[species]
		var value:float=enemy_attack_score(e,[alt[0],false,3,alt[3],alt[4],alt[5],"alt_"+species],true)
		if int(alt[0])>=2 and value>0.0:kits.append({"pattern":str(alt[1]),"reach":int(alt[0]),"value":value,"charged":false,"slot":"secondary"})
	return kits

func enemy_foresight_post_value(e:Dictionary,kits:Array[Dictionary],post:Vector2i,target:Vector2i)->float:
	var value:float=0.0
	for kit in kits:
		if enemy_projected_attack_aim(e,post,target,str(kit.pattern),int(kit.reach))!=Vector2i.ZERO:value=maxf(value,float(kit.value))
	return value

func enemy_foresight_plan(e:Dictionary,target:Vector2i)->Dictionary:
	var origin:Vector2i=e.pos
	if target!=player or not enemy_opportunity_eligible(e) or int(e.get("kind",0))==3 or int(e.get("stuck_turns",0))>0:return {}
	if bool(e.get("monster_house",false)) or charge_phase in ["underground","airborne","vanish"] or (shield_turns>0 and shield_kind=="protect"):return {}
	if distance(origin,target)<=1:return {}
	var kits:Array[Dictionary]=enemy_foresight_kits(e)
	if kits.is_empty() or enemy_foresight_post_value(e,kits,origin,target)>0.0:return {}
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other) and enemy_line_of_sight(other.pos,target):peers.append(other)
	var queue:Array[Vector2i]=[origin]
	var depths:Dictionary={origin:0}
	var first:Dictionary={origin:origin}
	var cursor:int=0
	var best:Dictionary={}
	var best_score:float=0.0
	var phase:int=posmod(int(e.get("uid",0))+turns,4)
	var gap:int=distance(origin,target)
	while cursor<queue.size():
		var here:Vector2i=queue[cursor];cursor+=1
		var depth:int=int(depths[here])
		if depth>0:
			var value:float=enemy_foresight_post_value(e,kits,here,target)
			if value>0.0:
				# A direct firing post is handled by the one-step planner.
				if depth==1:return {}
				var score:float=value*3.0/float(depth)+float(gap-distance(here,target))+float(enemy_terrain_position_bonus(e,here,target))*.25
				if enemy_strategy_reversal(e,first[here],target):score-=2.0
				if enemy_combat_personality(e)=="cautious" and distance(here,target)==1:score-=3.0
				# Prefer the shortest useful firing route; score breaks ties.
				if score>0.0 and (best.is_empty() or depth<int(best.depth) or (depth==int(best.depth) and score>best_score)):
					best_score=score;best={"step":first[here],"post":here,"depth":depth,"score":score}
		if depth>=ENEMY_FORESIGHT_DEPTH:continue
		for j in range(4):
			if queue.size()>=ENEMY_FORESIGHT_NODE_CAP:break
			var q:Vector2i=here+DIR[(phase+j)%4]
			if depths.has(q) or reserved.has(q) or not enemy_ambush_safe_tile(q) or not enemy_line_of_sight(q,target):continue
			if distance(q,target)>enemy_awareness(e):continue
			var blocked:bool=false
			for other in peers:
				if enemy_relief_blocks_lane(other,q,target):blocked=true;break
			if blocked:continue
			depths[q]=depth+1;first[q]=q if depth==0 else first[here];queue.append(q)
	if not best.is_empty():best["nodes"]=cursor
	return best

func enemy_tactical_step(e:Dictionary,target:Vector2i,pattern:String,reach:int)->Vector2i:
	var origin:Vector2i=e.pos
	if not bool(e.get("ecology_search_enabled",false)) or reach<2 or not enemy_line_of_sight(origin,target):return origin
	if distance(origin,target)>enemy_awareness(e) or int(e.get("stuck_turns",0))>0:return origin
	if target==player and not enemy_live_contact(e,target):return origin
	if attack_aim(origin,target,pattern,reach)!=Vector2i.ZERO:return origin
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var lane_memo:Dictionary={}
	var best:Vector2i=origin
	var best_score:int=-2147483647
	var phase:int=posmod(int(e.get("uid",0))+turns,4)
	for i in range(4):
		var q:Vector2i=origin+DIR[(phase+i)%4]
		if not cells.has(q) or q==target or q==player or q==stairs or q==relic or q in side_rewards or traps.has(q) or player_traps.has(q) or enemy_at(q)>=0 or ally_at(q)>=0:continue
		if reserved.has(q) or enemy_recovery_lane_blocked(peers,q,target,lane_memo):continue
		if distance(q,target)>enemy_awareness(e) or not enemy_line_of_sight(q,target) or enemy_projected_attack_aim(e,q,target,pattern,reach)==Vector2i.ZERO:continue
		# Ranged kits favor useful stand-off positions over clustering at melee range.
		var gap:int=distance(q,target)
		var score:int=20-absi(gap-reach)*3+enemy_terrain_position_bonus(e,q,target)
		if score>best_score:best_score=score;best=q
	return best

# Bounded local formation search: a second attacker finds a separate firing lane
# instead of queuing behind a nearby enemy. Search never spends PP or rolls RNG.
func enemy_cooperative_step(e:Dictionary,target:Vector2i,pattern:String,reach:int)->Vector2i:
	var origin:Vector2i=e.pos
	if not bool(e.get("ecology_search_enabled",false)) or int(e.get("kind",0))==3 or int(e.get("stuck_turns",0))>0:return origin
	if distance(origin,target)>enemy_awareness(e) or not enemy_line_of_sight(origin,target):return origin
	if target==player and not enemy_live_contact(e,target):return origin
	if attack_aim(origin,target,pattern,reach)!=Vector2i.ZERO:return origin
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var firing_peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):firing_peers.append(other)
	var lane_memo:Dictionary={}
	var partners:Array[Vector2i]=[]
	for other in enemies:
		var op:Vector2i=other.pos
		if op==origin or int(other.hp)<=0 or distance(op,target)>2 or distance(origin,op)>4:continue
		if int(other.get("sleep_turns",0))>0 or int(other.get("nightmare_turns",0))>0 or str(other.get("major_status",""))=="freeze":continue
		if enemy_line_of_sight(origin,op) and enemy_line_of_sight(op,target):partners.append(op)
	if partners.is_empty():return origin
	var occupied:Dictionary=navigation_occupancy()
	var queue:Array[Vector2i]=[origin]
	var depths:Dictionary={origin:0}
	var first_steps:Dictionary={origin:origin}
	var best:Vector2i=origin
	var best_score:int=-2147483647
	var cursor:int=0
	var phase:int=posmod(int(e.get("uid",0))+turns,4)
	while cursor<queue.size():
		var here:Vector2i=queue[cursor];cursor+=1
		var depth:int=int(depths[here])
		if depth>0 and distance(here,target)<=enemy_awareness(e) and enemy_line_of_sight(here,target) and enemy_projected_attack_aim(e,here,target,pattern,reach)!=Vector2i.ZERO:
			var separation:int=8
			for op in partners:separation=mini(separation,distance(here,op))
			# Shortest usable lane first; prefer separation only among equal-length routes.
			var score:int=100-depth*16+mini(separation,4)*2- absi(distance(here,target)-reach)
			if score>best_score:best_score=score;best=first_steps[here]
		if depth>=3:continue
		for j in range(4):
			var q:Vector2i=here+DIR[(phase+j)%4]
			if depths.has(q) or not cells.has(q) or occupied.has(q) or q==player or q==target or q==stairs or q==relic or q in side_rewards or traps.has(q) or player_traps.has(q):continue
			if reserved.has(q) or enemy_recovery_lane_blocked(firing_peers,q,target,lane_memo):continue
			depths[q]=depth+1;first_steps[q]=q if depth==0 else first_steps[here];queue.append(q)
	return best

# Original species personalities. Courage is not a random per-turn roll.
# Species temperament is orthogonal to patrol role and survival profile.
# Decision bonuses are never applied to actual damage or status duration.
func enemy_combat_personality(e:Dictionary)->String:
	match str(e.get("species","")):
		"rootgnawer","hollow_stag","shellguard","crystarok","astro_golem":return "territorial"
		"bramble_pup","thornbeetle","reef_pup","starlit_pup","comet_hare","lunar_prowler","leviathorn":return "hunter"
		"mossmite","grovetitan","coralcrab","anemoneye","voidspider":return "defender"
		"vinesnap","eelstrix","orbitserpent","jellymancer","sporeling":return "opportunist"
		"leafwisp","sylphowl","bubblewisp","marrowray","lunamoth","nova_wisp","nebulwing":return "cautious"
		_:return "steadfast"

func enemy_personality_bonus(e:Dictionary,skill:Array,utility:float)->float:
	if not bool(e.get("personality_enabled",false)) or int(e.get("kind",0))==3:return 0.0
	var effect:String=str(skill[4])
	match enemy_combat_personality(e):
		"hunter":
			if not bool(skill[1]):return .65
		"defender":
			if effect=="guard" and utility>0.0:return .8
		"opportunist":
			if effect in ["poison","weaken","mark","drain"] and utility>0.0:return .8
		"cautious":
			if not bool(skill[1]) and int(skill[0])>=2:return .55
		"territorial":
			if effect in ["mark","guard"] and utility>0.0:return .5
	return 0.0

func enemy_personality_control_bonus(e:Dictionary)->float:
	if not bool(e.get("personality_enabled",false)):return 0.0
	return .65 if enemy_combat_personality(e)=="opportunist" else 0.0

func enemy_territorial_idle_step(e:Dictionary)->Vector2i:
	var origin:Vector2i=e.pos
	if not bool(e.get("personality_enabled",false)) or enemy_combat_personality(e)!="territorial" or bool(e.get("monster_house",false)) or bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0:return origin
	var home:Vector2i=e.get("ecology_home",origin)
	if home==origin or not cells.has(home):return origin
	var path:Array[Vector2i]=route(origin,home,true)
	if path.is_empty() or not enemy_ambush_safe_tile(path[0]):return origin
	return path[0]

# Cautious ranged species can spend an ordinary movement action to improve
# spacing against a visible, currently empowered opponent, at most twice.
func enemy_cautious_spacing_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_live_contact(e,target):return origin
	if not bool(e.get("personality_enabled",false)) or enemy_combat_personality(e)!="cautious" or bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0 or int(e.get("spacing_count",0))>=2:return origin
	if target!=player or distance(origin,target)!=1 or not enemy_line_of_sight(origin,target):return origin
	if int(player_stages.get("attack",0))<2 and int(player_stages.get("sp_attack",0))<2 and not enemy_recent_threat(e) and not enemy_counter_pattern(e,"close"):return origin
	var skill:Array=signature_skill(e)
	var pattern:String=str(ATTACK_PATTERNS.get(e.get("species",""),"line"))
	if int(skill[0])<2 or not enemy_move_allowed(e,"primary") or int(e.get("cooldown",0))>0:return origin
	var best:Vector2i=origin
	for d in DIR:
		var q:Vector2i=origin+d
		if distance(q,target)!=2 or not enemy_ambush_safe_tile(q) or not enemy_line_of_sight(q,target):continue
		if enemy_projected_attack_aim(e,q,target,pattern,int(skill[0]))==Vector2i.ZERO:continue
		for onward in DIR:
			var next:Vector2i=q+onward
			if next!=origin and enemy_ambush_safe_tile(next):return q
	return best

func enemy_survival_profile(e:Dictionary)->String:
	match str(e.get("species","")):
		"sporeling","leafwisp","sylphowl","bubblewisp","jellymancer","marrowray","lunamoth","nova_wisp","nebulwing":return "cautious"
		"mossmite","shellguard","crystarok","grovetitan","anemoneye","vinesnap","voidspider","astro_golem":return "defensive"
		"bramble_pup","thornbeetle","rootgnawer","reef_pup","eelstrix","coralcrab","starlit_pup","orbitserpent","comet_hare","lunar_prowler","hollow_stag","leviathorn":return "aggressive"
		_:return "steadfast"

# A retreat is a single ordinary movement action, capped per injury episode.
# Pure evaluation: no healing, attack, PP, RNG or position mutation.
# Local threat assessment uses recent personally received damage and visible
# combatants. It cannot inspect player inventory or predict unobserved moves.
func enemy_risk_snapshot(e:Dictionary,target:Vector2i)->Dictionary:
	var origin:Vector2i=e.pos
	if target!=player or not enemy_opportunity_eligible(e) or charge_phase in ["underground","airborne","vanish"]:return {}
	var friendly:int=1
	var hostile:int=1
	var support:Array[Vector2i]=[]
	for other in enemies:
		if not enemy_squad_partner(e,other) or int(other.get("decoy_turns",0))>0 or not enemy_line_of_sight(other.pos,target):continue
		if int(other.hp)*2<=maxi(1,int(other.get("max_hp",other.hp))):continue
		if distance(other.pos,target)>mini(4,enemy_awareness(other)):continue
		friendly+=1
		if enemy_push_attack_coverage(other,target)>0:support.append(other.pos)
	for a in allies:
		if int(a.hp)<=0 or distance(origin,a.pos)>mini(4,enemy_awareness(e)) or not enemy_line_of_sight(origin,a.pos) or distance(target,a.pos)>3:continue
		hostile+=1
	var life:int=int(e.hp)
	var cap:int=maxi(1,int(e.get("max_hp",life)))
	var age:int=turns-int(e.get("incoming_turn",-9999))
	var recent:int=int(e.get("incoming_damage",0)) if age>=0 and age<=3 else 0
	var risk:int=0
	if life*2<=cap:risk+=2
	if recent>=life:risk+=3
	elif recent*4>=cap:risk+=1
	risk+=clampi(hostile-friendly,0,2)*2
	if enemy_recent_squad_loss(e):risk+=2
	if not support.is_empty():risk-=1
	if friendly>hostile:risk-=1
	return {"risk":maxi(0,risk),"friendly":friendly,"hostile":hostile,"support":support,"recent":recent}

func enemy_risk_has_finisher(e:Dictionary)->bool:
	if hp<=0 or not enemy_opportunity_eligible(e):return false
	if enemy_basic_finish(e):return true
	if int(e.get("whiffer_turns",0))>0 or enemy_stat_effect(e,"accuracy")*player_stat_effect("evasion")/(263.0/256.0)<.85:return false
	var species:String=str(e.get("species",""))
	var skill:Array=signature_skill(e)
	if not bool(skill[1]) and int(e.get("cooldown",0))<=0 and enemy_move_allowed(e,"primary") and attack_aim(e.pos,player,str(ATTACK_PATTERNS.get(species,"line")),int(skill[0]))!=Vector2i.ZERO and enemy_opportunity_damage(e,skill,false)>=hp:return true
	if int(e.get("alt_cooldown",0))<=0 and SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary"):
		var alt:Array=SECONDARY_SKILLS[species]
		return attack_aim(e.pos,player,str(alt[1]),int(alt[0]))!=Vector2i.ZERO and enemy_opportunity_damage(e,[alt[0],false,3,alt[3],alt[4],alt[5],"alt_"+species],true)>=hp
	return false

# One ordinary safer step, with a retry interval, not indefinite retreat.
func enemy_reinforcement_eligible(e:Dictionary,target:Vector2i)->bool:
	return target==player and enemy_opportunity_eligible(e) and charge_phase not in ["underground","airborne","vanish"] and (not bool(e.get("monster_house",false)) or bool(e.get("house_tactical",false)))

# A hold is a normal spent turn, and is only worthwhile if a visible
# teammate later in the turn order can approach a genuine attack position.
func enemy_reinforcement_wait(e:Dictionary,target:Vector2i)->bool:
	if not enemy_reinforcement_eligible(e,target) or int(e.get("stuck_turns",0))>0 or turns<=int(e.get("reinforcement_turn",-9999))+4:return false
	if enemy_survival_profile(e) not in ["cautious","defensive"]:return false
	var gap:int=distance(e.pos,target)
	if gap<3 or gap>4 or enemy_push_attack_coverage(e,target)>0 or enemy_risk_has_finisher(e) or enemy_has_party_area_attack(e):return false
	var after_actor:bool=false
	for other in enemies:
		if other.pos==e.pos:
			after_actor=true;continue
		if not after_actor or not enemy_squad_partner(e,other) or int(other.get("stuck_turns",0))>0 or bool(other.get("windup",false)) or int(other.get("slow_turns",0))>0:continue
		if int(other.hp)*2<=maxi(1,int(other.get("max_hp",other.hp))) or not enemy_line_of_sight(other.pos,target):continue
		var other_gap:int=distance(other.pos,target)
		if other_gap!=2 or enemy_push_attack_coverage(other,target)>0:continue
		for d in DIR:
			var q:Vector2i=other.pos+d
			if distance(q,target)==1 and enemy_ambush_safe_tile(q):return true
	return false

# A wounded cautious creature can retreat toward a teammate with a real
# attack lane on a plausible next pursuit tile. The player need not follow.
func enemy_lure_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_reinforcement_eligible(e,target) or enemy_survival_profile(e)!="cautious" or int(e.get("stuck_turns",0))>0 or turns<=int(e.get("lure_turn",-9999))+4:return origin
	if int(e.hp)*2>maxi(1,int(e.get("max_hp",e.hp))) or not enemy_recent_threat(e) or distance(origin,target)!=2 or enemy_risk_has_finisher(e) or enemy_has_party_area_attack(e):return origin
	var pursuit_tiles:Array[Vector2i]=[]
	for d in DIR:
		var tile:Vector2i=target+d
		if distance(tile,origin)==1 and enemy_ambush_safe_tile(tile):pursuit_tiles.append(tile)
	if pursuit_tiles.is_empty():return origin
	var best:Vector2i=origin
	var best_score:int=0
	for d in DIR:
		var q:Vector2i=origin+d
		if not enemy_ambush_safe_tile(q) or distance(q,target)<=2:continue
		var safe_exit:bool=false
		for onward in DIR:
			if q+onward!=origin and enemy_ambush_safe_tile(q+onward):safe_exit=true;break
		if not safe_exit:continue
		var exposed:bool=false
		for a in allies:
			if int(a.hp)>0 and enemy_line_of_sight(origin,a.pos) and distance(origin,a.pos)<=enemy_awareness(e) and distance(q,a.pos)<distance(origin,a.pos):exposed=true;break
		if exposed:continue
		var score:int=0
		for other in enemies:
			if not enemy_squad_partner(e,other) or int(other.hp)*2<=maxi(1,int(other.get("max_hp",other.hp))) or distance(q,other.pos)>=distance(origin,other.pos):continue
			if enemy_relief_blocks_lane(other,q,target):continue
			for tile in pursuit_tiles:
				if enemy_push_attack_coverage(other,tile)>=2:
					score+=2;break
		if score>best_score:best_score=score;best=q
	return best

func enemy_risk_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if int(e.get("stuck_turns",0))>0 or turns<=int(e.get("risk_move_turn",-9999))+3:return origin
	if bool(e.get("monster_house",false)) and not bool(e.get("house_tactical",false)):return origin
	var profile:String=enemy_survival_profile(e)
	if profile not in ["cautious","defensive"]:return origin
	var gap:int=distance(origin,target)
	if gap<1 or gap>3:return origin
	var report:Dictionary=enemy_risk_snapshot(e,target)
	if int(report.get("risk",0))<(4 if profile=="cautious" else 6) or enemy_risk_has_finisher(e) or enemy_has_party_area_attack(e):return origin
	var best:Vector2i=origin
	var best_score:int=-2147483647
	for d in DIR:
		var q:Vector2i=origin+d
		if not enemy_ambush_safe_tile(q) or distance(q,target)<=gap:continue
		var exits:int=0
		for onward in DIR:
			if q+onward!=origin and enemy_ambush_safe_tile(q+onward):exits+=1
		if exits==0:continue
		var exposure:int=0
		for a in allies:
			if int(a.hp)>0 and distance(origin,a.pos)<=mini(4,enemy_awareness(e)) and enemy_line_of_sight(origin,a.pos) and distance(q,a.pos)<distance(origin,a.pos):exposure+=1
		if exposure>0:continue
		var score:int=exits*2+(0 if enemy_line_of_sight(q,target) else 3)
		for tile in report.get("support",[]):
			if distance(q,tile)<distance(origin,tile):score+=3
		if score>best_score:best_score=score;best=q
	return best

func enemy_retreat_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_live_contact(e,target):return origin
	if not bool(e.get("ecology_search_enabled",false)) or bool(e.get("monster_house",false)) or int(e.get("kind",0))==3:return origin
	if bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0 or int(e.get("retreat_steps",0))>=2:return origin
	if enemy_survival_profile(e)!="cautious":return origin
	var cap:int=int(e.get("max_hp",0))
	if cap<=0 or int(e.hp)<=0 or int(e.hp)*3>cap:return origin
	var gap:int=distance(origin,target)
	if gap<1 or gap>3 or gap>enemy_awareness(e) or not enemy_line_of_sight(origin,target):return origin
	var best:Vector2i=origin
	var best_score:int=-2147483647
	var phase:int=posmod(int(e.get("uid",0))+turns,4)
	for j in range(4):
		var q:Vector2i=origin+DIR[(phase+j)%4]
		if not cells.has(q) or q==player or q==target or q==stairs or q==relic or q in side_rewards or traps.has(q) or player_traps.has(q) or enemy_at(q)>=0 or ally_at(q)>=0:continue
		if distance(q,target)<=gap:continue
		# Prefer a tile with a safe onward exit, rather than backing into a dead end.
		var exits:int=0
		for d in DIR:
			var next:Vector2i=q+d
			if next==origin or next==player or next==target or next==stairs or next==relic or next in side_rewards or not cells.has(next) or traps.has(next) or player_traps.has(next) or enemy_at(next)>=0 or ally_at(next)>=0:continue
			exits+=1
		if exits==0:continue
		var score:int=exits*3+(0 if enemy_line_of_sight(q,target) else 2)
		if score>best_score:best_score=score;best=q
	return best

# A defensive creature may interpose on an actual cardinal attack lane.
# No artificial shield, damage redirection, healing or additional turn.
func enemy_protector_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not bool(e.get("ecology_search_enabled",false)) or bool(e.get("monster_house",false)) or int(e.get("kind",0))==3:return origin
	if enemy_survival_profile(e)!="defensive" or bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0:return origin
	if distance(origin,target)>enemy_awareness(e) or not enemy_line_of_sight(origin,target):return origin
	var best:Vector2i=origin
	var best_score:int=-2147483647
	var phase:int=posmod(int(e.get("uid",0))+turns,4)
	for friend in enemies:
		var wounded:Vector2i=friend.pos
		var cap:int=int(friend.get("max_hp",0))
		var life:int=int(friend.hp)
		if wounded==origin or cap<=0 or life<=0 or life*3>cap or distance(origin,wounded)>3:continue
		if int(friend.get("decoy_turns",0))>0 or bool(friend.get("monster_house",false)):continue
		var threat:int=distance(wounded,target)
		if threat<2 or threat>4 or (wounded.x!=target.x and wounded.y!=target.y):continue
		if not enemy_line_of_sight(origin,wounded) or not enemy_line_of_sight(wounded,target):continue
		var toward:Vector2i=Vector2i(signi(target.x-wounded.x),signi(target.y-wounded.y))
		# Do not duplicate a screen already occupied by another creature.
		var screened:bool=false
		for lane_step in range(1,threat):
			if enemy_at(wounded+toward*lane_step)>=0:screened=true;break
		if screened:continue
		var q:Vector2i=wounded+toward
		if distance(origin,q)!=1 or not cells.has(q) or q==player or q==target or q==stairs or q==relic or q in side_rewards or traps.has(q) or player_traps.has(q) or enemy_at(q)>=0 or ally_at(q)>=0:continue
		var rank:int=DIR.find(q-origin)
		var score:int=100-int(100.0*float(life)/float(cap))-posmod(rank-phase,4)
		if score>best_score:best_score=score;best=q
	return best

# A small learned control kit, never an implicit ability shared by every enemy.
const ENEMY_CONTROL_KITS={"sylphowl":"eos_268","nebulwing":"eos_268","rootgnawer":"eos_284","hollow_stag":"eos_284","lunar_prowler":"eos_284","leviathorn":"eos_284","eelstrix":"eos_192","voidspider":"eos_124","sporeling":"eos_079","lunamoth":"eos_034","anemoneye":"eos_111","coralcrab":"eos_085","orbitserpent":"eos_033","bramble_pup":"eos_122","bubblewisp":"eos_171"}

# Pure prediction of the same trajectory used by execution. A floor trap stops
# the push and activates immediately; collision never overlaps creatures.
# Evaluate actual learned attack coverage at a hypothetical landing tile.
# Charged attacks retain their fixed telegraph; no state or RNG is changed.
func enemy_push_attack_coverage(e:Dictionary,tile:Vector2i)->int:
	var origin:Vector2i=e.pos
	# The landing tile is hypothetical; validate the actor and its remaining
	# action independently of whether the player currently occupies that tile.
	if not enemy_alert_eligible(e) or enemy_phase_spent.has(int(e.get("uid",-1))):return 0
	var slow:int=int(e.get("slow_turns",0))
	if slow>0 and slow%2==0:return 0
	if distance(origin,tile)>enemy_awareness(e) or not enemy_line_of_sight(origin,tile) or int(e.get("whiffer_turns",0))>0:return 0
	var species:String=str(e.get("species",""))
	var skill:Array=signature_skill(e)
	var pattern:String=str(ATTACK_PATTERNS.get(species,"line"))
	if bool(e.get("windup",false)):
		var aim:Vector2i=e.get("aim",Vector2i.ZERO)
		return 2 if aim!=Vector2i.ZERO and enemy_move_allowed(e,"primary") and attack_footprint(origin,aim,pattern,int(skill[0])).has(tile) and enemy_attack_score(e,skill,false)>0.0 else 0
	if int(e.get("cooldown",0))<=0 and not bool(skill[1]) and enemy_move_allowed(e,"primary") and attack_aim(origin,tile,pattern,int(skill[0]))!=Vector2i.ZERO and enemy_attack_score(e,skill,false)>0.0:return 2
	if int(e.get("alt_cooldown",0))<=0 and SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary"):
		var alt:Array=SECONDARY_SKILLS[species]
		if attack_aim(origin,tile,str(alt[1]),int(alt[0]))!=Vector2i.ZERO and enemy_attack_score(e,[alt[0],false,3,alt[3],alt[4],alt[5],"alt_"+species],true)>0.0:return 2
	return 1 if distance(origin,tile)==1 else 0

# Count only living party members visible to this observer and able to cover
# the indicated tile by proximity and an unobstructed geometric line.
func enemy_formation_support_count(e:Dictionary,tile:Vector2i)->int:
	var count:int=0
	for a in allies:
		if int(a.hp)<=0 or distance(e.pos,a.pos)>enemy_awareness(e) or not enemy_line_of_sight(e.pos,a.pos):continue
		if distance(tile,a.pos)<=2 and enemy_line_of_sight(a.pos,tile):count+=1
	return count

func enemy_formation_separation_bonus(e:Dictionary,target:Vector2i,destination:Vector2i)->int:
	if target==destination:return 0
	var before:int=enemy_formation_support_count(e,target)
	var after:int=enemy_formation_support_count(e,destination)
	return clampi((before-after)*2,-4,4)

func enemy_push_position_bonus(e:Dictionary,target:Vector2i,destination:Vector2i)->int:
	if not bool(e.get("ecology_search_enabled",false)) or target==destination:return 0
	var gained:int=0
	var lost:int=0
	var after_actor:bool=false
	for other in enemies:
		if int(other.get("uid",-1))==int(e.get("uid",-2)) or other.pos==e.pos:
			after_actor=true;continue
		if not after_actor or not enemy_squad_partner(e,other):continue
		var before:int=enemy_push_attack_coverage(other,target)
		var after:int=enemy_push_attack_coverage(other,destination)
		gained+=maxi(0,after-before);lost+=maxi(0,before-after)
	var separation:int=enemy_formation_separation_bonus(e,target,destination)
	return clampi(gained*2-lost*2,-4,4)+separation

func enemy_push_plan(e:Dictionary,target:Vector2i)->Dictionary:
	var origin:Vector2i=e.pos
	if distance(origin,target)!=1 or not enemy_line_of_sight(origin,target):return {}
	var direction:Vector2i=target-origin
	var path:Array[Vector2i]=[]
	var collision:Vector2i=target
	var kind:String=""
	var score:int=0
	for step in range(1,cells.size()+1):
		var q:Vector2i=target+direction*step
		if not cells.has(q):
			collision=q;kind="wall";score=3;break
		if ally_at(q)>=0:
			collision=q;kind="party";score=8;break
		if enemy_at(q)>=0:
			collision=q;kind="enemy";score=-3;break
		path.append(q)
		if traps.has(q):
			kind="trap";score=8;break
	# Score only hazards/targets the actor can actually observe.
	var destination:Vector2i=target if path.is_empty() else path.back()
	var position_bonus:int=0
	if distance(origin,destination)>enemy_awareness(e) or not enemy_line_of_sight(origin,destination):score=0
	elif kind in ["party","enemy"] and (distance(origin,collision)>enemy_awareness(e) or not enemy_line_of_sight(origin,collision)):score=0
	elif kind!="enemy":
		if destination==stairs or destination==relic:score=0
		else:
			if kind=="trap":
				var trap_kind:String=str(traps.get(destination,""))
				if (shield_turns>0 and shield_kind=="safeguard" and trap_kind in ["snare","weaken"]) or (trap_kind=="weaken" and boon_active("mist")) or (trap_kind=="snare" and player_slow_turns>=4) or (trap_kind=="weaken" and weakened_strikes>=2) or (trap_kind=="drain" and energy<=0) or (trap_kind=="hunger" and belly_tenths<=10):score=1
			position_bonus=enemy_push_position_bonus(e,target,destination)
			score+=position_bonus
	return {"path":path,"destination":destination,"collision":collision,"kind":kind,"score":score,"position_bonus":position_bonus}

# Set up a useful knockback angle on this turn, then cast on a later turn.
func enemy_control_setup_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_live_contact(e,target) or int(e.get("whiffer_turns",0))>0:return origin
	var id:String=str(e.get("control_move",""))
	if not bool(e.get("ecology_search_enabled",false)) or (bool(e.get("monster_house",false)) and not bool(e.get("house_tactical",false))) or bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0:return origin
	if int(e.get("control_cooldown",0))>0 or not MOVE_LIBRARY.has(id) or str(MOVE_LIBRARY[id].get("special_rule",""))!="push" or not enemy_move_allowed(e,"control"):return origin
	if player_has_ability("anchored") or boon_active("ingrain") or charge_phase in ["underground","airborne","vanish"] or (shield_turns>0 and shield_kind=="protect") or boon_active("magic_coat"):return origin
	if not enemy_line_of_sight(origin,target) or distance(origin,target)!=2:return origin
	var best:Vector2i=origin
	var best_score:int=4
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var memo:Dictionary={}
	for d in DIR:
		var q:Vector2i=origin+d
		if distance(q,target)!=1 or not cells.has(q) or q==stairs or q==relic or q in side_rewards or traps.has(q) or player_traps.has(q) or enemy_at(q)>=0 or ally_at(q)>=0:continue
		if reserved.has(q) or enemy_recovery_lane_blocked(peers,q,target,memo):continue
		if mirror_veil_blocks(q,true,"front"):continue
		var hypothetical:Dictionary=e.duplicate()
		hypothetical["pos"]=q
		var score:int=int(enemy_push_plan(hypothetical,target).get("score",0))
		# Do not spend a preparation turn on an angle whose projected
		# knockback already loses to an ordinary attack from that tile.
		if score<=best_score:continue
		if bool(e.get("personality_enabled",false)) and not enemy_push_utility_wins(e,float(score),enemy_decision_attack_value(e,q,target)):continue
		best=q;best_score=score
	return best

# Estimate a real follow-up, using only the actor's existing attack kit.
# No new action, PP, damage or RNG is consumed by this evaluation.
# Forecast only the next deterministic periodic tick. No healing, traps,
# random reactions or later player actions are assumed.
func enemy_combo_survives_next_tick(e:Dictionary)->bool:
	var remaining:int=int(e.get("hp",0))
	if int(e.get("curse_turns",0))>0:
		var age:int=int(e.get("curse_age",0))+1
		if age>=2 and (age-2)%10==0:remaining-=maxi(1,int(int(e.get("max_hp",e.hp))/4))
	if remaining<=0:return false
	if int(e.get("leech_turns",0))>0 and (int(e.get("leech_age",0))+1)%2==0:remaining-=10
	if remaining<=0:return false
	remaining-=enemy_major_periodic_damage(e)
	return remaining>0

func enemy_combo_followup(e:Dictionary,move:Dictionary,wait:int)->float:
	var origin:Vector2i=e.pos
	if not enemy_alert_eligible(e) or not enemy_live_contact(e,player):return 0.0
	# Same-phase support requires an action that has not already been spent.
	# A future-turn self follow-up is still a valid forecast.
	if wait<=0 and enemy_phase_spent.has(int(e.get("uid",-1))):return 0.0
	# The next status tick can guarantee sleep or defeat before a future action.
	# Do not roll sleep duration or mutate the real actor during a forecast.
	if wait>0:
		var yawn:int=int(e.get("yawn_turns",0))
		var perish:int=int(e.get("perish_turns",0))
		if yawn>0 and yawn<=wait:return 0.0
		if perish>0 and perish<=wait and not bool(e.get("perish_immune",false)):return 0.0
		if not enemy_combo_survives_next_tick(e):return 0.0
	# Slow skips even positive countdown phases, not every slowed turn.
	# Forecast the next ordinary phase with the same countdown convention.
	var projected_slow:int=maxi(0,int(e.get("slow_turns",0))-maxi(0,wait))
	if projected_slow>0 and projected_slow%2==0:return 0.0
	if int(e.get("whiffer_turns",0))>0:return 0.0
	var status:String=str(move.get("inflict_status",""))
	var info:Array=ENEMY_TRAINING.get(e.get("species",""),[["normal"],"normal","normal",0,0,"physical"])
	var defense:String="sp_defense" if str(info[5])=="special" else "defense"
	var delta:int=int(move.get("stat_changes",{}).get(defense,0))
	var current:int=int(player_stages.get(defense,0))
	var gain:float=0.0
	if status in ["sleep","paralysis"]:gain=.30
	elif status=="confusion":gain=.15
	elif delta<0 and current>-2:
		var next:int=maxi(-2,current+delta)
		gain=clampf(stage_factor(defense,current)/maxf(.001,stage_factor(defense,next))-1.0,0.0,.60)
	if gain<=0.0:return 0.0
	var best:float=0.0
	var species:String=str(e.get("species",""))
	var skill:Array=signature_skill(e)
	var pattern:String=str(ATTACK_PATTERNS.get(species,"line"))
	if bool(e.get("windup",false)):
		var fixed_aim:Vector2i=e.get("aim",Vector2i.ZERO)
		if fixed_aim!=Vector2i.ZERO and enemy_move_allowed(e,"primary",wait) and attack_footprint(origin,fixed_aim,pattern,int(skill[0])).has(player):
			return minf(3.0,maxf(0.0,enemy_combo_damage_score(e,skill,false))*gain)
		return 0.0
	# The forecast is for the indicated action phase, not a multi-turn rollout.
	# An unstarted windup would spend that phase charging, never dealing damage.
	if not bool(skill[1]) and int(e.get("cooldown",0))<=wait and enemy_move_allowed(e,"primary",wait) and enemy_area_aim(e,pattern,int(skill[0]))!=Vector2i.ZERO:
		best=maxf(best,enemy_combo_damage_score(e,skill,false))
	if int(e.get("alt_cooldown",0))<=wait and not bool(e.get("windup",false)) and SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary",wait):
		var alt:Array=SECONDARY_SKILLS[species]
		if enemy_area_aim(e,str(alt[1]),int(alt[0]))!=Vector2i.ZERO:
			best=maxf(best,enemy_combo_damage_score(e,[alt[0],false,3,alt[3],alt[4],alt[5],"alt_"+species],true))
	return minf(3.0,maxf(0.0,best)*gain)

# A geometrically valid hit is not a useful damage follow-up if the
# current defensive state makes its actual damage zero.
func enemy_combo_damage_score(e:Dictionary,skill:Array,secondary:bool)->float:
	if enemy_opportunity_damage(e,skill,secondary)<=0:return 0.0
	# Discount damage forecasts by the same stage accuracy roll used in combat.
	# Do not predict the player's deterministic speed meter across squad turns.
	var accuracy:float=clampf(enemy_stat_effect(e,"accuracy")*player_stat_effect("evasion")/(263.0/256.0),0.0,1.0)
	if int(e.get("whiffer_turns",0))>0:return 0.0
	return enemy_attack_score(e,skill,secondary)*accuracy

func enemy_combo_setup_bonus(e:Dictionary,move:Dictionary)->float:
	if not enemy_alert_eligible(e) or not enemy_live_contact(e,player):return 0.0
	var own:float=minf(1.5,enemy_combo_followup(e,move,1)*.5)
	var first:float=0.0
	var second:float=0.0
	var after_actor:bool=false
	for other in enemies:
		if other.pos==e.pos:
			after_actor=true;continue
		# Earlier actors have already spent their action this round.
		if not after_actor or not enemy_squad_partner(e,other):continue
		var value:float=enemy_combo_followup(other,move,0)
		if value>first:second=first;first=value
		elif value>second:second=value
	return minf(4.5,own+first+second*.5)

# Evaluate only the explicitly learned status move. Crowd-control windows
# are shared across attackers so a pack cannot indefinitely stun-lock the player.
# Visible gathering attacks use the same front/corner-front geometry as release.
# Hidden charge phases and unrecognized patterns never disclose their aim.
func enemy_visible_charge_threat(e:Dictionary)->Dictionary:
	if not enemy_opportunity_eligible(e) or charge_phase!="gather" or not MOVE_LIBRARY.has(charged_move_id) or not charged_aim in DIR8:return {}
	var move:Dictionary=MOVE_LIBRARY[charged_move_id]
	if str(move.get("charge_phase",""))!="gather" or str(move.get("pattern","")) not in ["front","corner_front"] or int(move.get("power",0))<=0:return {}
	return attack_footprint(player,charged_aim,str(move.pattern),int(move.reach),true)

func enemy_charge_evasion_step(e:Dictionary)->Vector2i:
	var origin:Vector2i=e.pos
	if enemy_survival_profile(e) not in ["cautious","defensive"] or int(e.get("stuck_turns",0))>0:return origin
	var threat:Dictionary=enemy_visible_charge_threat(e)
	if not threat.has(origin) or enemy_risk_has_finisher(e):return origin
	var best:Vector2i=origin
	var best_score:int=-2147483647
	var reserved:Dictionary=enemy_pack_reserved_posts(e,player)
	for d in DIR:
		var q:Vector2i=origin+d
		if threat.has(q) or not enemy_ambush_safe_tile(q) or reserved.has(q):continue
		var score:int=enemy_terrain_position_bonus(e,q,player)
		# Do not evade into a tightly packed group if an equally safe tile exists.
		var nearby:int=0
		for other in enemies:
			if enemy_squad_partner(e,other) and distance(q,other.pos)==1:nearby+=1
		score-=mini(nearby,3)*2
		if enemy_strategy_attack_tile(e,q,player):score+=4
		if score>best_score:best_score=score;best=q
	return best

func enemy_charge_push_bonus(e:Dictionary,plan:Dictionary)->int:
	if not enemy_visible_charge_threat(e).has(e.pos) or plan.is_empty():return 0
	var destination:Vector2i=plan.get("destination",player)
	if destination==player or destination==stairs or destination==relic or str(plan.get("kind",""))=="enemy" or not enemy_line_of_sight(e.pos,destination) or distance(e.pos,destination)>enemy_awareness(e):return 0
	var move:Dictionary=MOVE_LIBRARY[charged_move_id]
	var shifted:Dictionary=attack_footprint(destination,charged_aim,str(move.pattern),int(move.reach),true)
	return 3 if not shifted.has(e.pos) else 0

func enemy_status_utility(e:Dictionary,move:Dictionary)->float:
	# Status-only control follows the same live-contact contract as knockback.
	if not enemy_live_contact(e,player) or int(e.get("whiffer_turns",0))>0:return 0.0
	var origin:Vector2i=e.pos
	var gap:int=distance(origin,player)
	if gap<1 or gap>enemy_awareness(e) or not enemy_line_of_sight(origin,player):return 0.0
	if enemy_status_aim(origin,move)==Vector2i.ZERO:return 0.0
	if (shield_turns>0 and shield_kind in ["protect","safeguard"]) or boon_active("magic_coat") or mirror_veil_blocks(origin,true,str(move.pattern)) or charge_phase in ["underground","airborne","vanish"]:return 0.0
	var status:String=str(move.get("inflict_status",""))
	var utility:float=0.0
	if status in ["sleep","paralysis","confusion"]:
		if boon_active("hostile_control_recovery") or boon_active("hostile_sleep") or boon_active("hostile_drowse") or boon_active("hostile_paralysis") or boon_active("nap") or self_confusion_turns>0:return 0.0
		match status:
			"sleep":
				if boon_active("sleepless") or player_has_ability("wakeful") or boon_active("nap"):return 0.0
				utility=3.0
			"paralysis":
				utility=2.5
			"confusion":
				utility=2.0
	else:
		if boon_active("mist"):return 0.0
		var deltas:Dictionary=move.get("stat_changes",{})
		for stat in deltas:
			var current:int=int(player_stages.get(stat,0))
			var reduction:int=mini(maxi(0,current+2),maxi(0,-int(deltas[stat])))
			if reduction>0:utility+=minf(2.5,float(reduction)*1.5)
		if utility<=0.0:return 0.0
	# Sleep uses the existing player wait gate; it delays release, never erases PP or charge.
	if status=="sleep" and enemy_visible_charge_threat(e).has(origin):utility+=3.0
	utility+=enemy_combo_setup_bonus(e,move)+enemy_personality_control_bonus(e)
	if enemy_move_pp(e,"control")<=2:utility*=.85
	return utility*enemy_status_hit_chance(e,move)

# Match the two independent accuracy rolls in status execution, including
# stage modifiers on the second roll and the catalog's always-hit sentinel.
func enemy_status_second_accuracy(e:Dictionary,move:Dictionary)->float:
	var second:int=int(move.get("acc2",125))
	if second>100:return 100.0
	var factor:float=enemy_stat_effect(e,"accuracy")*player_stat_effect("evasion")/(263.0/256.0)
	return clampf(float(second)*factor,0.0,100.0)

func enemy_status_hit_chance(e:Dictionary,move:Dictionary)->float:
	if int(e.get("whiffer_turns",0))>0:return 0.0
	return clampf(float(move.get("acc1",125)),0.0,100.0)*enemy_status_second_accuracy(e,move)/10000.0

func enemy_status_aim(origin:Vector2i,move:Dictionary)->Vector2i:
	var pattern:String=str(move.pattern)
	var reach:int=int(move.reach)
	if pattern in ["corner_front","fan","corner"]:
		for d in DIR8:
			if attack_footprint(origin,d,pattern,reach).has(player):return d
	return attack_aim(origin,player,pattern,reach)

func enemy_execute_status_control(i:int,move:Dictionary)->bool:
	var e:Dictionary=enemies[i]
	var origin:Vector2i=e.pos
	var utility:float=enemy_status_utility(e,move)
	if utility<=0.0:return false
	var aim:Vector2i=enemy_status_aim(origin,move)
	if aim==Vector2i.ZERO:return false
	var best_damage:float=0.0
	var signature_ready:bool=false
	var skill:Array=signature_skill(e)
	if int(e.get("cooldown",0))<=0 and enemy_move_allowed(e,"primary") and enemy_area_aim(e,str(ATTACK_PATTERNS.get(e.get("species",""),"line")),int(skill[0]))!=Vector2i.ZERO:
		signature_ready=true
		best_damage=enemy_combo_damage_score(e,skill,false)
	var species:String=str(e.get("species",""))
	if int(e.get("alt_cooldown",0))<=0 and SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary"):
		var alt:Array=SECONDARY_SKILLS[species]
		if enemy_area_aim(e,str(alt[1]),int(alt[0]))!=Vector2i.ZERO:
			signature_ready=true
			best_damage=maxf(best_damage,enemy_combo_damage_score(e,[alt[0],false,3,alt[3],alt[4],alt[5],"alt_"+species],true))
	# Quick strike is the dispatcher fallback only when no signature is ready.
	# Preserve legacy status behavior and the existing multi-target priority.
	if bool(e.get("personality_enabled",false)) and not signature_ready and distance(origin,player)==1:
		var accuracy:float=clampf(enemy_stat_effect(e,"accuracy")*player_stat_effect("evasion")/(263.0/256.0),0.0,1.0)
		best_damage=maxf(best_damage,float(enemy_opportunity_damage(e,[],false,true))*accuracy)
	if utility<=best_damage+.25:return false
	record_enemy_move(e,"control")
	e["control_cooldown"]=5
	for cd_key in ["support_cooldown","cooldown","alt_cooldown"]:
		if int(e.get(cd_key,0))>0:e[cd_key]=int(e[cd_key])-1
	var first:int=int(move.get("acc1",125))
	var second:int=int(move.get("acc2",125))
	var miss:bool=int(e.get("whiffer_turns",0))>0 or (first<100 and rng.randi_range(1,100)>first) or (second<=100 and rng.randf()*100.0>=enemy_status_second_accuracy(e,move))
	var status:String=str(move.get("inflict_status",""))
	if not miss:
		match status:
			"sleep":player_boons["hostile_sleep"]=3;player_boons["hostile_control_recovery"]=8
			"paralysis":player_boons["hostile_paralysis"]=5;player_boons["hostile_control_recovery"]=9
			"confusion":self_confusion_turns=4;player_boons["hostile_control_recovery"]=8
			_:
				var changes:Dictionary={}
				for stat in move.get("stat_changes",{}):
					if int(move.stat_changes[stat])<0 and int(player_stages.get(stat,0))>-2:changes[stat]=maxi(-2-int(player_stages.get(stat,0)),int(move.stat_changes[stat]))
				apply_stat_changes(player_stages,player_halves,{"stat_changes":changes})
	var footprint:Dictionary=attack_footprint(origin,aim,str(move.pattern),int(move.reach))
	enemy_actions.append({"uid":e.get("uid",i),"phase":"attack","from":origin,"to":player,"move":move.name,"fx":"basic_strike","effect":status if not miss else "none","damage":0,"dodged":miss,"tiles":footprint.keys(),"path":footprint.get(player,[player])})
	emit_event(str(move.name)+(" · Missed" if miss else " · Tactical control"))
	return true

# Compare the existing knockback tactical score with the best immediate
# attack estimate. This is a decision heuristic, not predicted exact HP loss.
# Preserve a credible response to a telegraphed attack and legacy non-tactical AI.
func enemy_push_preferred(e:Dictionary,plan:Dictionary)->bool:
	if plan.is_empty():return false
	var escape_bonus:int=enemy_charge_push_bonus(e,plan)
	var utility:float=float(plan.get("score",0))+float(escape_bonus)
	if utility<5.0:return false
	if escape_bonus>0 or not bool(e.get("personality_enabled",false)):return true
	return enemy_push_utility_wins(e,utility,enemy_decision_attack_value(e,e.pos,player))

func enemy_push_utility_wins(e:Dictionary,utility:float,direct:float)->bool:
	# Conserve scarce control PP when a comparable direct action exists.
	var adjusted:float=utility-(.5 if enemy_move_pp(e,"control")<=2 else 0.0)
	return utility>=5.0 and adjusted>direct+.25

func enemy_execute_control(i:int)->bool:
	var e:Dictionary=enemies[i]
	var id:String=str(e.get("control_move",""))
	if not bool(e.get("ecology_search_enabled",false)) or bool(e.get("windup",false)) or (bool(e.get("monster_house",false)) and not bool(e.get("house_tactical",false))):return false
	if int(e.get("control_cooldown",0))>0 or not MOVE_LIBRARY.has(id) or not enemy_move_allowed(e,"control"):return false
	var learned:Dictionary=MOVE_LIBRARY[id]
	if str(learned.get("special_rule",""))!="push":
		if str(learned.get("category",""))!="status":return false
		return enemy_execute_status_control(i,learned)
	if player_has_ability("anchored") or boon_active("ingrain") or charge_phase in ["underground","airborne","vanish"] or (shield_turns>0 and shield_kind=="protect") or mirror_veil_blocks(e.pos,true,"front") or boon_active("magic_coat"):return false
	# Unlike ordinary attacks, this control move always misses under Whiffer.
	# Preserve PP and let the ordinary dispatcher select another action.
	if not enemy_live_contact(e,player) or int(e.get("whiffer_turns",0))>0:return false
	if enemy_risk_has_finisher(e):return false
	var plan:Dictionary=enemy_push_plan(e,player)
	if not enemy_push_preferred(e,plan):return false
	var origin:Vector2i=player
	record_enemy_move(e,"control")
	e["control_cooldown"]=3
	for cd_key in ["support_cooldown","cooldown","alt_cooldown"]:
		if int(e.get(cd_key,0))>0:e[cd_key]=int(e[cd_key])-1
	var damage:int=0
	var miss:bool=int(e.get("whiffer_turns",0))>0 or rng.randf()>clampf(enemy_stat_effect(e,"accuracy")*player_stat_effect("evasion")/(263.0/256.0),0.0,1.0)
	if not miss:
		player=plan.destination
		if plan.kind=="trap":
			trigger_floor_trap(player)
		elif plan.kind in ["party","enemy","wall"]:
			damage=mini(hp,shield_damage(5,"physical"));hp-=damage
			if damage>0:hits+=1;combo=0
			if plan.kind=="party":
				var ai:int=ally_at(plan.collision)
				if ai>=0:allies[ai].hp=maxi(0,int(allies[ai].hp)-5)
			elif plan.kind=="enemy":
				var ei:int=enemy_at(plan.collision)
				if ei>=0:enemies[ei].hp=maxi(0,int(enemies[ei].hp)-5)
		reveal()
	enemy_actions.append({"uid":e.get("uid",i),"phase":"attack","from":e.pos,"to":origin,"move":MOVE_LIBRARY[id].name,"fx":"basic_strike","effect":"push","damage":damage,"dodged":miss,"tiles":[origin],"path":[origin],"player_end":player,"push_path":plan.path if not miss else []})
	emit_event(str(MOVE_LIBRARY[id].name)+(" · Missed" if miss else " · Knockback"))
	return true

# Occupy a real narrow exit adjacent to the player rather than standing in
# another attacker's way. The player can still fight through or choose another exit.
# A visible peer that has already started charging this round can be
# supported by occupying a plausible escape tile outside its fixed footprint.
# The player remains free to move, attack, wait or use an item.
func enemy_counterplay_charge_tiles(e:Dictionary,target:Vector2i)->Dictionary:
	var covered:Dictionary={}
	var announced:Dictionary={}
	for action in enemy_actions:
		if str(action.get("phase",""))=="windup":announced[int(action.get("uid",-1))]=true
	if announced.is_empty():return covered
	for other in enemies:
		if other.pos==e.pos:break
		if not announced.has(int(other.get("uid",-2))) or not enemy_squad_partner(e,other) or not bool(other.get("windup",false)) or not enemy_move_allowed(other,"primary"):continue
		if int(other.get("whiffer_turns",0))>0 or int(other.get("slow_turns",0))>0:continue
		if distance(other.pos,target)>enemy_awareness(other) or not enemy_line_of_sight(other.pos,target):continue
		var skill:Array=signature_skill(other)
		var aim:Vector2i=other.get("aim",Vector2i.ZERO)
		if not bool(skill[1]) or aim==Vector2i.ZERO or enemy_attack_score(other,skill,false)<=0.0:continue
		var footprint:Dictionary=attack_footprint(other.pos,aim,str(ATTACK_PATTERNS.get(other.get("species",""),"line")),int(skill[0]))
		if not footprint.has(target):continue
		for tile in footprint:
			if enemy_line_of_sight(e.pos,tile):covered[tile]=true
	return covered

func enemy_counterplay_escape_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if target!=player or not enemy_opportunity_eligible(e) or int(e.get("stuck_turns",0))>0 or bool(e.get("monster_house",false)):return origin
	if charge_phase in ["underground","airborne","vanish"] or (shield_turns>0 and shield_kind=="protect"):return origin
	if enemy_survival_profile(e) not in ["aggressive","defensive"] or int(e.hp)*2<=maxi(1,int(e.get("max_hp",e.hp))):return origin
	if distance(origin,target)<2 or distance(origin,target)>3 or enemy_decision_attack_value(e,origin,target)>0.0:return origin
	var covered:Dictionary=enemy_counterplay_charge_tiles(e,target)
	if covered.is_empty():return origin
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var best:Vector2i=origin
	var best_score:int=-2147483647
	var phase:int=posmod(int(e.get("uid",0))+turns,4)
	for j in range(4):
		var q:Vector2i=origin+DIR[(phase+j)%4]
		var delta:Vector2i=q-target
		if delta not in DIR8 or not step_clear(target,delta) or covered.has(q) or reserved.has(q) or not enemy_ambush_safe_tile(q):continue
		if not enemy_line_of_sight(origin,q) or not enemy_line_of_sight(q,target):continue
		var blocked:bool=false
		for other in enemies:
			if enemy_squad_partner(e,other) and enemy_line_of_sight(other.pos,target) and enemy_relief_blocks_lane(other,q,target):blocked=true;break
		if blocked:continue
		var score:int=enemy_terrain_position_bonus(e,q,target)+4*int(distance(q,target)==1)
		for d in DIR:
			var onward:Vector2i=q+d
			if onward!=target and not covered.has(onward) and enemy_ambush_safe_tile(onward):score+=1
		if enemy_strategy_reversal(e,q,target):score-=3
		if score>best_score:best_score=score;best=q
	return best

func enemy_exit_block_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_live_contact(e,target):return origin
	if not bool(e.get("ecology_search_enabled",false)) or (bool(e.get("monster_house",false)) and not bool(e.get("house_tactical",false))) or int(e.get("kind",0))==3 or int(e.get("stuck_turns",0))>0:return origin
	if enemy_survival_profile(e) not in ["aggressive","defensive"] or bool(e.get("windup",false)) or distance(origin,target)>3 or not enemy_line_of_sight(origin,target):return origin
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var memo:Dictionary={}
	for d in DIR:
		var q:Vector2i=origin+d
		if distance(q,target)!=1 or not cells.has(q) or q==stairs or q==relic or q in side_rewards or traps.has(q) or player_traps.has(q) or enemy_at(q)>=0 or ally_at(q)>=0:continue
		if reserved.has(q) or enemy_recovery_lane_blocked(peers,q,target,memo):continue
		var openings:int=0
		for side in DIR:
			if cells.has(q+side):openings+=1
		# A three-way doorway is valid when it is outside the player's room.
		var doorway:bool=false
		if openings==3:
			for room in rooms:
				if room.has_point(target) and not room.has_point(q):doorway=true;break
		if openings!=2 and not doorway:continue
		var continuation:Vector2i=q+(q-target)
		if cells.has(continuation) and (continuation==origin or enemy_at(continuation)<0) and ally_at(continuation)<0:return q
	return origin

# Congestion recovery is deliberately a fallback, not a new movement budget.
# A blocked actor can yield a firing lane to a visible ranged partner.
func enemy_crowd_yield_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not bool(e.get("ecology_search_enabled",false)) or int(e.get("kind",0))==3 or int(e.get("stuck_turns",0))>0 or bool(e.get("windup",false)):return origin
	if not enemy_live_contact(e,target):return origin
	if origin.x!=target.x and origin.y!=target.y:return origin
	var heading:Vector2i=Vector2i(signi(target.x-origin.x),signi(target.y-origin.y))
	var partner:Vector2i=origin-heading
	var index:int=enemy_at(partner)
	if index<0:return origin
	var rear:Dictionary=enemies[index]
	if not enemy_squad_partner(e,rear) or not enemy_live_contact(rear,target):return origin
	# Only yield for an executable shot in the remaining enemy phase.
	if enemy_phase_spent.has(int(rear.get("uid",-1))) or int(rear.get("whiffer_turns",0))>0:return origin
	if int(rear.get("slow_turns",0))>0 and int(rear.slow_turns)%2==0:return origin
	var gap:int=distance(partner,target)
	var species:String=str(rear.get("species",""))
	var primary:Array=signature_skill(rear)
	var can_fire:bool=not bool(rear.get("windup",false)) and int(rear.get("cooldown",0))<=0 and enemy_move_allowed(rear,"primary") and str(ATTACK_PATTERNS.get(species,"line"))=="line" and int(primary[0])>=gap
	if not can_fire and not bool(rear.get("windup",false)) and int(rear.get("alt_cooldown",0))<=0 and enemy_move_allowed(rear,"secondary") and SECONDARY_SKILLS.has(species):
		var alt:Array=SECONDARY_SKILLS[species]
		can_fire=str(alt[1])=="line" and int(alt[0])>=gap
	if not can_fire:return origin
	# Verify the yielding actor is the only creature obstructing the ray.
	for step in range(2,gap):
		var tile:Vector2i=partner+heading*step
		if not cells.has(tile) or enemy_at(tile)>=0 or ally_at(tile)>=0:return origin
	var lateral:Vector2i=Vector2i(-heading.y,heading.x)
	var best:Vector2i=origin
	var best_score:int=-1
	for d in [lateral,-lateral]:
		var q:Vector2i=origin+d
		if not cells.has(q) or q==stairs or q==relic or q in side_rewards or traps.has(q) or player_traps.has(q) or enemy_at(q)>=0 or ally_at(q)>=0:continue
		if e.get("crowd_previous",origin)==q and turns-int(e.get("crowd_turn",-9999))<=2:continue
		var exits:int=0
		for onward in DIR:
			var next:Vector2i=q+onward
			if next!=origin and next!=target and cells.has(next) and enemy_at(next)<0 and ally_at(next)<0 and not traps.has(next) and not player_traps.has(next):exits+=1
		if exits>best_score:best=q;best_score=exits
	return best

func enemy_crowd_hold(e:Dictionary,next:Vector2i,target:Vector2i)->bool:
	# Hold for one subsequent turn only while the firing lane remains usable.
	if not bool(e.get("ecology_search_enabled",false)) or target!=e.get("crowd_target",Vector2i.ZERO) or turns-int(e.get("crowd_turn",-9999))!=1:return false
	if next!=e.get("crowd_previous",e.pos):return false
	var rear_tile:Vector2i=e.get("crowd_partner",e.pos)
	var index:int=enemy_at(rear_tile)
	return index>=0 and enemy_live_contact(e,target) and enemy_squad_partner(e,enemies[index]) and enemy_relief_blocks_lane(enemies[index],next,target)

# Idle sentries choose a nearby watch post from room geometry alone.
# No attack, RNG, hidden player tracking or extra action is granted.
func enemy_ambush_safe_tile(q:Vector2i)->bool:
	return cells.has(q) and q!=player and q!=stairs and q!=relic and not q in side_rewards and not traps.has(q) and not player_traps.has(q) and enemy_at(q)<0 and ally_at(q)<0

# Ambushes coordinate only with visible, awake peers and their local plans.
func enemy_ambush_claim_score(e:Dictionary,post:Vector2i,entry:Vector2i,gate:Vector2i)->int:
	var score:int=0
	for other in enemies:
		if not enemy_squad_partner(e,other) or not enemy_alert_eligible(other) or not other.has("ambush_post"):continue
		var age:int=turns-int(other.get("ambush_plan_turn",-9999))
		if age<0 or age>5:continue
		var other_post:Vector2i=other.ambush_post
		if not enemy_line_of_sight(e.pos,other_post):continue
		if other_post==post:return -1000
		if other.get("ambush_gate",Vector2i.ZERO)!=gate:continue
		# Opposite sides of an entry are complementary; do not stack one lane.
		var peer_offset:Vector2i=other_post-entry
		var post_offset:Vector2i=post-entry
		if peer_offset.x*post_offset.x+peer_offset.y*post_offset.y<0:score+=8
		elif distance(other_post,post)<=1:score-=8
		else:score+=2
	return clampi(score,-16,16)

func enemy_ambush_attack_ready(e:Dictionary,post:Vector2i,entry:Vector2i)->bool:
	if distance(post,entry)==1:return true
	var skill:Array=signature_skill(e)
	var species:String=str(e.get("species",""))
	if enemy_move_allowed(e,"primary") and int(e.get("cooldown",0))<=0 and attack_aim(post,entry,str(ATTACK_PATTERNS.get(species,"line")),int(skill[0]))!=Vector2i.ZERO:return true
	if SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary") and int(e.get("alt_cooldown",0))<=0:
		var alt:Array=SECONDARY_SKILLS[species]
		if attack_aim(post,entry,str(alt[1]),int(alt[0]))!=Vector2i.ZERO:return true
	return false

func enemy_ambush_plan(e:Dictionary)->Dictionary:
	var origin:Vector2i=e.pos
	if not bool(e.get("ambush_enabled",false)) or int(e.get("kind",0))==3 or bool(e.get("monster_house",false)) or bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0:return {}
	var home:Vector2i=e.get("ecology_home",origin)
	var queue:Array[Vector2i]=[origin]
	var depths:Dictionary={origin:0}
	var first:Dictionary={origin:origin}
	var cursor:int=0
	while cursor<queue.size():
		var here:Vector2i=queue[cursor];cursor+=1
		var depth:int=int(depths[here])
		if depth>=3:continue
		for d in DIR:
			var q:Vector2i=here+d
			if depths.has(q) or distance(home,q)>3 or not enemy_ambush_safe_tile(q):continue
			depths[q]=depth+1;first[q]=q if depth==0 else first[here];queue.append(q)
	var skill:Array=signature_skill(e)
	var species:String=str(e.get("species",""))
	var ranged:bool=int(skill[0])>=2 and enemy_move_allowed(e,"primary")
	var pattern:String=str(ATTACK_PATTERNS.get(species,"line"))
	var best:Dictionary={}
	var best_score:int=-2147483647
	# Examine only nearby entry tiles; outside corridor must continue away.
	for entry in queue:
		for room in rooms:
			if not room.has_point(entry):continue
			for d in DIR:
				var gate:Vector2i=entry+d
				if room.has_point(gate) or not cells.has(gate) or not cells.has(gate+d) or gate==stairs or gate==relic:continue
				var openings:int=0
				for side in DIR:
					if cells.has(gate+side):openings+=1
				if openings>2:continue
				for q in queue:
					if q==entry or not room.has_point(q) or distance(q,entry)>3 or not enemy_line_of_sight(q,entry):continue
					if q==origin and (q==stairs or q==relic or q in side_rewards or traps.has(q) or player_traps.has(q)):continue
					var range_to_entry:int=distance(q,entry)
					var legal_attack:bool=attack_aim(q,entry,pattern,int(skill[0]))!=Vector2i.ZERO if ranged else range_to_entry==1
					var coordinated:bool=bool(e.get("personality_enabled",false))
					if coordinated:legal_attack=enemy_ambush_attack_ready(e,q,entry)
					if not legal_attack:continue
					var side_cover:bool=(q.x-entry.x)*d.x+(q.y-entry.y)*d.y==0
					var score:int=12-int(depths[q])*2
					if ranged:score+=range_to_entry*3
					elif side_cover:score+=5
					if not enemy_line_of_sight(q,gate+d):score+=4
					if coordinated:
						var claim_score:int=enemy_ambush_claim_score(e,q,entry,gate)
						if claim_score<=-1000:continue
						score+=claim_score
						if not enemy_line_of_sight(q,gate):score+=5
					if score>best_score:
						best_score=score;best={"post":q,"entry":entry,"gate":gate,"step":first[q]}
	return best

func enemy_clear_ambush(e:Dictionary)->void:
	e.erase("ambush_post");e.erase("ambush_entry");e.erase("ambush_gate");e.erase("ambush_plan_turn")

func enemy_ambush_step(e:Dictionary)->Vector2i:
	var origin:Vector2i=e.pos
	if not bool(e.get("ambush_enabled",false)) or int(e.get("stuck_turns",0))>0 or bool(e.get("windup",false)):return origin
	if e.has("ambush_post"):
		var post:Vector2i=e.ambush_post
		var entry:Vector2i=e.ambush_entry
		var gate:Vector2i=e.ambush_gate
		if bool(e.get("personality_enabled",false)):
			if turns-int(e.get("ambush_plan_turn",-9999))>5 or not enemy_ambush_attack_ready(e,post,entry) or (post==origin and (traps.has(post) or player_traps.has(post))):
				enemy_clear_ambush(e);e["ambush_retry"]=turns+3
				return origin
		if cells.has(entry) and cells.has(gate) and cells.has(post) and (post==origin or enemy_ambush_safe_tile(post)):
			if post==origin:return origin
			var home:Vector2i=e.get("ecology_home",origin)
			var queue:Array[Vector2i]=[origin]
			var depths:Dictionary={origin:0}
			var first:Dictionary={origin:origin}
			var cursor:int=0
			while cursor<queue.size():
				var here:Vector2i=queue[cursor];cursor+=1
				var depth:int=int(depths[here])
				if depth>=3:continue
				for d in DIR:
					var q:Vector2i=here+d
					if depths.has(q) or distance(home,q)>3 or not enemy_ambush_safe_tile(q):continue
					depths[q]=depth+1;first[q]=q if depth==0 else first[here]
					if q==post:return first[q]
					queue.append(q)
		enemy_clear_ambush(e)
		e["ambush_retry"]=turns+3
		return origin
	if turns<int(e.get("ambush_retry",-9999)):return origin
	var plan:Dictionary=enemy_ambush_plan(e)
	if plan.is_empty():
		e["ambush_retry"]=turns+3
		return origin
	e["ambush_post"]=plan.post;e["ambush_entry"]=plan.entry;e["ambush_gate"]=plan.gate;e["ambush_plan_turn"]=turns
	return plan.step

func enemy_patrol_destination(e:Dictionary)->Vector2i:
	var origin:Vector2i=e.pos
	if str(e.get("ecology_role","hunter"))!="roamer" or int(e.get("stuck_turns",0))>0:return origin
	var home:Vector2i=e.get("ecology_home",origin)
	var phase:int=posmod(turns+int(e.get("uid",0)),4)
	for i in range(4):
		var delta:Vector2i=DIR[(phase+i)%4]
		var q:Vector2i=origin+delta
		if not step_clear(origin,delta) or q==player or q==stairs or q==relic or q in side_rewards or enemy_at(q)>=0 or ally_at(q)>=0 or traps.has(q):continue
		if distance(q,home)>3 and distance(q,home)>=distance(origin,home):continue
		return q
	return origin

func generate_floor():
	adaptive_walk_turn=-9999
	clear_combat_effects()
	reset_floor_combat_presentation()
	rng.seed=seed_value+floor_number*7919
	ecology_rng.seed=seed_value+floor_number*65537+region*4099+197
	structure_rng.seed=seed_value+floor_number*131071+region*12289+311
	network_rng.seed=seed_value+floor_number*196613+region*16381+419
	encounter_rng.seed=seed_value+floor_number*262147+region*32771+521
	treasure_rng.seed=seed_value+floor_number*32452843+region*65537+617
	initialize_hidden_power(seed_value)
	cells.clear();rooms.clear();enemies.clear();loot.clear();revealed.clear();traps.clear();player_traps.clear();revealed_player_traps.clear();explored_rooms.clear();explored_side_chambers.clear()
	floor_bonus=0;player_rested=false
	floor_style=posmod(seed_value+floor_number,3)
	floor_kind=0 if starter_woods or floor_number==1 else posmod(seed_value*3+floor_number*7,5)
	secured=false;guardian_defeated=not (rescue_finale and floor_number==floor_count);floor_revision+=1
	visual_interactions.clear()
	layout_retries=0;shape_history_hits=0
	for attempt in range(LAYOUT_RETRY_CAP):
		cells.clear();rooms.clear()
		build_layout()
		layout_signature=floor_layout_signature()
		shape_signature=canonical_shape_signature()
		var repeated_shape:bool=recent_shapes.has(shape_signature)
		if repeated_shape:shape_history_hits+=1
		if not recent_layouts.has(layout_signature) and not repeated_shape:break
		layout_retries+=1
	remember_layout(layout_signature)
	remember_shape(shape_signature)
	monster_house_room=-1;monster_house_triggered=false;monster_house_cleared=false;monster_house_spawn_count=0;monster_house_profile=0
	monster_house_rng.seed=seed_value+floor_number*104729+region*8191+3011

	var spots:Array= cells.keys()
	for i in range(spots.size()-1,0,-1):
		var j=rng.randi_range(0,i);var temp=spots[i];spots[i]=spots[j];spots[j]=temp
	var count=1+floor_number if starter_woods else mini(7,2+floor_number+tier)
	if floor_kind==1:count=maxi(2,count-2)
	if floor_kind==2:count=mini(8,count+1)
	var budgets:Vector3i=ecology_budgets(count,14 if floor_kind==1 else 9,0 if starter_woods else (mini(12,floor_number-1) if dev_sandbox else floor_number-1))
	count=budgets.x
	for p in spots:
		if p==player or p==stairs or p==relic or p in side_rewards or distance(p,player)<4:continue
		if enemies.size()<count:
			var life=8+(mini(floor_number,30) if dev_sandbox else floor_number)*2+tier*2
			enemies.append(make_enemy(p,life,rng.randi_range(0,2),enemies.size()))
		elif loot.size()<budgets.y:
			loot[p]="trail_fruit" if loot.size()==2 else "manual:eos_154" if loot.size()==5 else "potion" if loot.size()%4==0 else "material" if loot.size()%3==0 else "coin"
		elif traps.size()<budgets.z:traps[p]=floor_trap_kind(p)
		else:break
	loot[relic]="relic"
	for reward in side_rewards:loot[reward]="material"
	if starter_woods:
		# Replace (not add to) an ordinary pickup with the floor's teaching reward.
		var tutorial_reward:String=["potion","trail_fruit","manual:eos_154"][clampi(floor_number-1,0,2)]
		for q in spots:
			if q!=relic and loot.get(q,"")=="coin":
				loot[q]=tutorial_reward
				break
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
		var boss:Dictionary=make_enemy(relic,life,3,99)
		boss_initialize(boss);enemies.append(boss)
	# A guaranteed immediate pickup introduces the loop on every floor.
	for d in DIR:
		var p:Vector2i=player+d
		if cells.has(p) and not loot.has(p):
			loot[p]="coin";break
	arrange_floor_encounter()
	assign_enemy_ecology()
	distribute_rare_treasures()
	energy=mini(8,energy+2)
	place_allies()
	prepare_monster_house()
	reveal()
	message=starter_objective() if starter_woods else ("Guardian chamber · Rescue the creature" if not guardian_defeated else "B%d · Find the stairs"%floor_number)
func monster_house_chance()->int:
	# Kindria expeditions are shorter than EOS dungeons: tune per tier.
	if starter_woods or floor_number<2 or not guardian_defeated or floor_kind==3:return 0
	return mini(22,8+tier*4+mini(6,(floor_number-2)*2))

func monster_house_candidates()->Array[int]:
	var valid:Array[int]=[]
	for i in range(rooms.size()):
		var room:Rect2i=rooms[i]
		if i==encounter_room or room.has_point(player) or room.has_point(relic):continue
		var free_count:int=0
		for y in range(room.position.y,room.end.y):
			for x in range(room.position.x,room.end.x):
				var p:=Vector2i(x,y)
				if cells.has(p) and p!=stairs and enemy_at(p)<0 and ally_at(p)<0:free_count+=1
		if free_count>=12:valid.append(i)
	return valid

func prepare_monster_house(force:bool=false)->bool:
	if monster_house_room>=0 or starter_woods:return false
	if not force and monster_house_rng.randi_range(1,100)>monster_house_chance():return false
	var candidates:=monster_house_candidates()
	if candidates.is_empty():return false
	monster_house_room=candidates[monster_house_rng.randi_range(0,candidates.size()-1)]
	monster_house_profile=monster_house_rng.randi_range(0,HOUSE_PROFILES.size()-1)
	var room:Rect2i=rooms[monster_house_room]
	var spots:Array[Vector2i]=[]
	for y in range(room.position.y,room.end.y):
		for x in range(room.position.x,room.end.x):
			var p:=Vector2i(x,y)
			if cells.has(p) and p!=stairs and p!=relic and enemy_at(p)<0 and ally_at(p)<0 and not loot.has(p) and not traps.has(p):spots.append(p)
	for i in range(spots.size()-1,0,-1):
		var j:int=monster_house_rng.randi_range(0,i);var swap:Vector2i=spots[i];spots[i]=spots[j];spots[j]=swap
	var recipe:Vector3i=house_recipe(monster_house_profile)
	var rewards:Array[String]=["coin","material","potion","trail_fruit","manual:eos_154","material","coin"]
	var reward_count:int=mini(recipe.y,spots.size())
	for i in range(reward_count):loot[spots[i]]=rewards[i]
	for i in range(reward_count,mini(reward_count+recipe.z,spots.size())):traps[spots[i]]=floor_trap_kind(spots[i])
	return true

func monster_house_remaining()->int:
	var count:int=0
	for e in enemies:
		if bool(e.get("monster_house",false)) and int(e.hp)>0:count+=1
	return count

# House formations use actual species kits, not new artificial attacks.
func house_tactical_role(e:Dictionary)->String:
	var skill:Array=signature_skill(e)
	var profile:String=enemy_survival_profile(e)
	if profile=="defensive":return "guard"
	if int(skill[0])>=3:return "ranged"
	if not str(e.get("control_move","")).is_empty() or ENEMY_SUPPORT.get(e.get("species",""),"")=="drowse":return "controller"
	return "vanguard"

func house_spawn_tile(e:Dictionary,spots:Array[Vector2i],room:Rect2i)->Vector2i:
	var role:String=house_tactical_role(e)
	var best:Vector2i=spots[0]
	var best_score:int=-2147483647
	for q in spots:
		var gap:int=distance(q,player)
		var score:int=-absi(gap-(3 if role in ["ranged","controller"] else 2))*4
		if traps.has(q) or player_traps.has(q):score-=30
		if enemy_line_of_sight(q,player):score+=3
		# Preserve a little breathing room at the trigger tile.
		if gap==1:score-=8
		if role=="guard":
			for d in DIR:
				if cells.has(q+d) and not room.has_point(q+d):score+=5
		if role=="ranged":
			var pattern:String=str(ATTACK_PATTERNS.get(e.get("species",""),"line"))
			if attack_aim(q,player,pattern,int(signature_skill(e)[0]))!=Vector2i.ZERO:score+=5
		if score>best_score:best_score=score;best=q
	return best

# Roles are recalculated from living, visible teammates; species kits never change.
func enemy_relief_candidate(e:Dictionary,target:Vector2i)->bool:
	if not bool(e.get("personality_enabled",false)) or not enemy_alert_eligible(e) or bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0:return false
	if bool(e.get("monster_house",false)) and not bool(e.get("house_tactical",false)):return false
	var life:int=int(e.hp)
	if life*2<=maxi(1,int(e.get("max_hp",life))):return false
	var gap:int=distance(e.pos,target)
	if gap<2 or gap>4 or not enemy_line_of_sight(e.pos,target):return false
	var role:String=str(e.get("house_role",""))
	if role=="guard" or enemy_survival_profile(e)=="defensive":return true
	var species:String=str(e.get("species",""))
	var has_control:bool=MOVE_LIBRARY.has(str(e.get("control_move",""))) and enemy_move_allowed(e,"control")
	var has_support:bool=not str(ENEMY_SUPPORT.get(species,"")).is_empty() and enemy_move_allowed(e,"support")
	return role in ["controller","ranged"] and not enemy_move_allowed(e,"primary") and (not SECONDARY_SKILLS.has(species) or not enemy_move_allowed(e,"secondary")) and not has_control and not has_support

func enemy_relief_ranged_ready(e:Dictionary,target:Vector2i)->bool:
	# A ranged kit is not evidence of actual backup. The attack must reach
	# the observed target through the current geometry and be executable.
	if not enemy_alert_eligible(e) or not enemy_live_contact(e,target):return false
	if distance(e.pos,target)<2 or int(e.get("whiffer_turns",0))>0 or int(e.get("slow_turns",0))>0:return false
	if enemy_phase_spent.has(int(e.get("uid",-1))):return false
	var species:String=str(e.get("species",""))
	var skill:Array=signature_skill(e)
	var pattern:String=str(ATTACK_PATTERNS.get(species,"line"))
	if bool(e.get("windup",false)):
		var aim:Vector2i=e.get("aim",Vector2i.ZERO)
		return aim!=Vector2i.ZERO and enemy_move_allowed(e,"primary") and attack_footprint(e.pos,aim,pattern,int(skill[0])).has(target)
	if int(e.get("cooldown",0))<=0 and not bool(skill[1]) and enemy_move_allowed(e,"primary") and int(skill[0])>=2 and attack_aim(e.pos,target,pattern,int(skill[0]))!=Vector2i.ZERO:return true
	if int(e.get("alt_cooldown",0))<=0 and enemy_move_allowed(e,"secondary") and SECONDARY_SKILLS.has(species):
		var alt:Array=SECONDARY_SKILLS[species]
		return int(alt[0])>=2 and attack_aim(e.pos,target,str(alt[1]),int(alt[0]))!=Vector2i.ZERO
	return false

func enemy_relief_blocks_lane(friend:Dictionary,q:Vector2i,target:Vector2i)->bool:
	var origin:Vector2i=friend.pos
	# A firing reservation is only valid for an actor capable of a deliberate
	# attack. Keep this guard local so direct and indirect callers agree.
	if int(friend.get("hp",0))<=0 or int(friend.get("decoy_turns",0))>0:return false
	for status in ["sleep_turns","nightmare_turns","paused_turns","wrapped_turns","infatuated_turns","confusion_turns"]:
		if int(friend.get(status,0))>0:return false
	if str(friend.get("major_status","")) in ["freeze","paralysis"]:return false
	# A slowed actor skips even remaining-duration turns in the real dispatcher.
	# Do not reserve a firing lane for an attack that cannot execute this phase.
	if int(friend.get("slow_turns",0))>0 and int(friend.slow_turns)%2==0:return false
	# A completed ordinary action cannot claim another shot this phase.
	# An already telegraphed windup remains a deliberate tactical commitment.
	if enemy_phase_spent.has(int(friend.get("uid",-1))) and not bool(friend.get("windup",false)):return false
	# A committed line attack protects its announced footprint, not the
	# current location of a player who may have moved or disappeared.
	if bool(friend.get("windup",false)):
		var committed_aim:Vector2i=friend.get("aim",Vector2i.ZERO)
		if committed_aim==Vector2i.ZERO or not enemy_move_allowed(friend,"primary") or str(ATTACK_PATTERNS.get(str(friend.get("species","")),"line"))!="line":return false
		return attack_footprint(origin,committed_aim,"line",int(signature_skill(friend)[0])).has(q)
	# Ordinary low-confidence shots do not justify exclusive squad access.
	# A committed telegraph remains protected, even when accuracy is impaired.
	if int(friend.get("whiffer_turns",0))>0:return false
	# Ordinary reservations require firsthand contact with the player; only
	# a committed telegraph can retain its previously announced geometry.
	if target==player and not enemy_live_contact(friend,target):return false
	# A cardinal firing lane must stay clear if it currently reaches the target.
	if origin.x!=target.x and origin.y!=target.y:return false
	var heading:Vector2i=Vector2i(signi(target.x-origin.x),signi(target.y-origin.y))
	var gap:int=distance(origin,target)
	if distance(origin,q)+distance(q,target)!=gap or q==origin or q==target:return false
	var species:String=str(friend.get("species",""))
	var skill:Array=signature_skill(friend)
	if enemy_move_allowed(friend,"primary") and int(friend.get("cooldown",0))<=0 and str(ATTACK_PATTERNS.get(species,"line"))=="line":
		if attack_footprint(origin,heading,"line",int(skill[0])).has(target):return true
	if enemy_move_allowed(friend,"secondary") and int(friend.get("alt_cooldown",0))<=0 and SECONDARY_SKILLS.has(species):
		var alt:Array=SECONDARY_SKILLS[species]
		if str(alt[1])=="line" and attack_footprint(origin,heading,"line",int(alt[0])).has(target):return true
	return false

func enemy_relief_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if target!=player or charge_phase in ["underground","airborne","vanish"] or boon_active("decoy") or not enemy_relief_candidate(e,target):return origin
	var backup:Array[Dictionary]=[]
	var wounded:bool=false
	var gap:int=distance(origin,target)
	for other in enemies:
		if not enemy_squad_partner(e,other) or not enemy_line_of_sight(other.pos,target):continue
		if bool(e.get("monster_house",false)) and int(e.get("monster_house_spawn_serial",-1))!=int(other.get("monster_house_spawn_serial",-2)):continue
		var other_gap:int=distance(other.pos,target)
		var life:int=int(other.hp)
		var cap:int=maxi(1,int(other.get("max_hp",life)))
		if other_gap==1:
			if life*2>cap:return origin
			wounded=true
		elif enemy_relief_ranged_ready(other,target):backup.append(other)
		if enemy_relief_candidate(other,target):
			if other_gap<gap or (other_gap==gap and int(other.get("uid",0))<int(e.get("uid",0))):return origin
	if not wounded and backup.is_empty():return origin
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var best:Vector2i=origin
	var best_score:int=-2147483647
	for d in DIR:
		var q:Vector2i=origin+d
		if distance(q,target)>=gap or not enemy_ambush_safe_tile(q) or reserved.has(q) or not enemy_line_of_sight(q,target):continue
		var blocked:bool=false
		for friend in backup:
			if enemy_relief_blocks_lane(friend,q,target):blocked=true;break
		if blocked:continue
		var score:int=-distance(q,target)*4
		for friend in backup:score+=mini(3,distance(q,friend.pos))
		if score>best_score:best_score=score;best=q
	return best

# Dynamic reserve role: a healthy melee or defensive actor may replace a
# lost front line. Only viable candidates compete; a blocked peer cannot veto.
func enemy_reserve_candidate(e:Dictionary,target:Vector2i)->bool:
	if target!=player or charge_phase in ["underground","airborne","vanish"] or not enemy_opportunity_eligible(e) or int(e.get("stuck_turns",0))>0:return false
	if bool(e.get("monster_house",false)) and not bool(e.get("house_tactical",false)):return false
	var gap:int=distance(e.pos,target)
	if gap<2 or gap>4 or int(e.hp)*2<=maxi(1,int(e.get("max_hp",e.hp))):return false
	if enemy_survival_profile(e) not in ["aggressive","defensive"]:return false
	# A creature with an immediate ranged attack should keep its firing role.
	return enemy_push_attack_coverage(e,target)==0

func enemy_reserve_route(e:Dictionary,target:Vector2i)->Dictionary:
	var origin:Vector2i=e.pos
	var backup:Array[Dictionary]=[]
	var vacancy:bool=enemy_recent_squad_loss(e)
	for other in enemies:
		if not enemy_squad_partner(e,other) or not enemy_line_of_sight(other.pos,target):continue
		if bool(e.get("monster_house",false)) and int(e.get("monster_house_spawn_serial",-1))!=int(other.get("monster_house_spawn_serial",-2)):continue
		if distance(other.pos,target)==1:
			if int(other.hp)*2>maxi(1,int(other.get("max_hp",other.hp))):return {}
			vacancy=true
		elif enemy_relief_ranged_ready(other,target) and enemy_push_attack_coverage(other,target)>0:
			backup.append(other);vacancy=true
	if not vacancy:return {}
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var queue:Array[Vector2i]=[origin]
	var depths:Dictionary={origin:0}
	var first:Dictionary={origin:origin}
	var cursor:int=0
	while cursor<queue.size():
		var here:Vector2i=queue[cursor];cursor+=1
		var depth:int=int(depths[here])
		if depth>0 and distance(here,target)==1:return {"step":first[here],"post":here,"cost":depth}
		if depth>=3:continue
		for d in DIR:
			var q:Vector2i=here+d
			if depths.has(q) or reserved.has(q) or not enemy_ambush_safe_tile(q) or not enemy_line_of_sight(q,target):continue
			var blocked:bool=false
			for friend in backup:
				if enemy_relief_blocks_lane(friend,q,target):blocked=true;break
			if blocked:continue
			depths[q]=depth+1;first[q]=q if depth==0 else first[here];queue.append(q)
	return {}

func enemy_dynamic_reserve_plan(e:Dictionary,target:Vector2i)->Dictionary:
	if not enemy_reserve_candidate(e,target):return {}
	var plan:Dictionary=enemy_reserve_route(e,target)
	if plan.is_empty():return {}
	for other in enemies:
		if not enemy_squad_partner(e,other) or not enemy_reserve_candidate(other,target):continue
		if bool(e.get("monster_house",false)) and int(e.get("monster_house_spawn_serial",-1))!=int(other.get("monster_house_spawn_serial",-2)):continue
		var alternative:Dictionary=enemy_reserve_route(other,target)
		if alternative.is_empty():continue
		if int(alternative.cost)<int(plan.cost) or (int(alternative.cost)==int(plan.cost) and int(other.get("uid",0))<int(e.get("uid",0))):return {}
	return plan

func house_formation_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not bool(e.get("house_tactical",false)) or int(e.get("stuck_turns",0))>0 or bool(e.get("windup",false)):return origin
	if not enemy_line_of_sight(origin,target) or distance(origin,target)>enemy_awareness(e):return origin
	var role:String=str(e.get("house_role",""))
	if role in ["vanguard","controller"]:return origin
	var best:Vector2i=origin
	var best_score:int=0
	for d in DIR:
		var q:Vector2i=origin+d
		if not cells.has(q) or q==target or q==player or q==stairs or q==relic or q in side_rewards or traps.has(q) or player_traps.has(q) or enemy_at(q)>=0 or ally_at(q)>=0:continue
		if not enemy_line_of_sight(q,target):continue
		var score:int=0
		if role=="ranged":
			var skill:Array=signature_skill(e)
			var pattern:String=str(ATTACK_PATTERNS.get(e.get("species",""),"line"))
			if attack_aim(q,target,pattern,int(skill[0]))==Vector2i.ZERO:continue
			score=6+distance(q,target)-absi(distance(q,target)-int(skill[0]))*3
		elif role=="guard":
			for other in enemies:
				if not enemy_squad_partner(e,other) or str(other.get("house_role",""))!="ranged" or int(other.get("monster_house_spawn_serial",-1))!=int(e.get("monster_house_spawn_serial",-2)):continue
				var op:Vector2i=other.pos
				if distance(q,op)!=1 or distance(q,target)>=distance(op,target) or distance(q,target)>3:continue
				# Stand beside the ranged creature without plugging its own line.
				if (q.x==target.x and q.x==op.x) or (q.y==target.y and q.y==op.y):continue
				score=maxi(score,10-distance(q,target))
		if score>best_score:best_score=score;best=q
	return best

func trigger_monster_house()->bool:
	if finished or monster_house_triggered or monster_house_room<0 or monster_house_room>=rooms.size():return false
	var room:Rect2i=rooms[monster_house_room]
	if not room.has_point(player):return false
	var spots:Array[Vector2i]=[]
	for y in range(room.position.y,room.end.y):
		for x in range(room.position.x,room.end.x):
			var p:=Vector2i(x,y)
			var delta:Vector2i=p-player
			if maxi(absi(delta.x),absi(delta.y))>4 or not cells.has(p) or p==player or p==stairs or p==relic or enemy_at(p)>=0 or ally_at(p)>=0:continue
			spots.append(p)
	for i in range(spots.size()-1,0,-1):
		var j:int=monster_house_rng.randi_range(0,i);var swap:Vector2i=spots[i];spots[i]=spots[j];spots[j]=swap
	var recipe:Vector3i=house_recipe(monster_house_profile)
	var count:int=mini(spots.size(),clampi(5+tier+mini(3,floor_number/2)+recipe.x,1,MONSTER_HOUSE_CAP))
	monster_house_triggered=true;monster_house_spawn_count=count;monster_house_serial+=1
	for i in range(count):
		var life:int=8+mini(floor_number,30)*2+tier*2
		var kind:int=house_enemy_kind(monster_house_profile,i)
		var e:=make_enemy(spots[0],life,kind,MONSTER_HOUSE_UID_BASE+i)
		var tile:Vector2i=house_spawn_tile(e,spots,room) if monster_house_profile in [2,3] else spots[0]
		spots.erase(tile)
		e.pos=tile
		e["monster_house"]=true;e["monster_house_spawn_serial"]=monster_house_serial
		e["house_tactical"]=true;e["house_role"]=house_tactical_role(e)
		e["personality_enabled"]=true
		e["ecology_search_enabled"]=true;e["ecology_role"]="hunter"
		e["last_seen_player"]=player;e["last_seen_until"]=turns+3
		enemies.append(e);revealed[tile]=true
	message="Monster House! · %d enemies"%count
	emit_event(message);visual_interaction("monster_house",player)
	return true

func update_monster_house()->void:
	if not monster_house_triggered:
		trigger_monster_house()
	elif not monster_house_cleared and monster_house_remaining()==0:
		monster_house_cleared=true
		if not finished:
			message="Monster House cleared!"
			emit_event(message);visual_interaction("monster_house_clear",player)

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
			var before_stages:Dictionary=a.stages.duplicate()
			for key in ["attack","sp_attack"]:a.stages[key]=mini(10,int(a.stages.get(key,0))+1)
			record_cast_result(a.pos,0,true,a.stages!=before_stages,false)
		else:
			var healed:int=maxi(0,int(a.max_hp)-int(a.hp))
			var cleared:bool=not a.status.is_empty()
			a.hp=int(a.max_hp);a.status.clear()
			record_cast_heal(a.pos,healed)
			if healed==0:record_cast_result(a.pos,0,true,cleared or rule=="party_renew",false)
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

# Ordinary party pursuit must not repeatedly choose a shortest route that
# its own movement rules reject. Use the fast route when safe; otherwise
# look for a short legal approach to the personally observed opponent.
func enemy_safe_party_approach(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if int(e.get("stuck_turns",0))>0 or distance(origin,target)>enemy_awareness(e) or not enemy_line_of_sight(origin,target):return origin
	# Only coordinate against a player position this actor can actually see.
	var reserved:Dictionary={}
	var peers:Array[Dictionary]=[]
	var lane_memo:Dictionary={}
	var coordinate:bool=enemy_live_contact(e,player)
	if coordinate:
		reserved=enemy_pack_reserved_posts(e,player)
		for other in enemies:
			if enemy_squad_partner(e,other):peers.append(other)
	var direct:Array[Vector2i]=route(origin,target,true)
	if direct.size()>1:
		var safe:bool=true
		for k in range(direct.size()-1):
			if not free_party_tile(direct[k]) or player_traps.has(direct[k]) or reserved.has(direct[k]) or (coordinate and enemy_recovery_lane_blocked(peers,direct[k],player,lane_memo)):safe=false;break
		if safe:return direct[0]
	var queue:Array[Vector2i]=[origin]
	var depths:Dictionary={origin:0}
	var first:Dictionary={}
	var cursor:int=0
	while cursor<queue.size() and cursor<128:
		var tile:Vector2i=queue[cursor];cursor+=1
		if tile!=origin and distance(tile,target)==1:return first[tile]
		if int(depths[tile])>=8:continue
		for d in DIR:
			var q:Vector2i=tile+d
			if depths.has(q) or not free_party_tile(q) or player_traps.has(q) or reserved.has(q):continue
			if coordinate and enemy_recovery_lane_blocked(peers,q,player,lane_memo):continue
			depths[q]=int(depths[tile])+1;first[q]=q if tile==origin else first[tile];queue.append(q)
	return origin

# Prefer the nearest *reachable* observed opponent. A sealed or trapped
# opponent must not veto a different legal target. Equal distances retain
# party order for deterministic behavior and existing priority semantics.
func enemy_party_approach_plan(e:Dictionary)->Dictionary:
	var origin:Vector2i=e.pos
	# Compare distances only against a personally observed player. A hidden
	# player's actual coordinates must not alter the choice of a visible ally.
	var max_gap:int=mini(6,enemy_awareness(e))
	if enemy_live_contact(e,player):max_gap=mini(max_gap,distance(origin,player)-1)
	for gap in range(1,max_gap+1):
		for j in range(allies.size()):
			var a:Dictionary=allies[j]
			if int(a.hp)<=0 or distance(origin,a.pos)!=gap or not enemy_line_of_sight(origin,a.pos):continue
			if gap==1:return {"index":j,"gap":gap,"step":origin}
			var step:Vector2i=enemy_safe_party_approach(e,a.pos)
			if step!=origin:return {"index":j,"gap":gap,"step":step}
	return {}

func enemy_target_ally(i:int)->bool:
	if boon_active("decoy"):return false
	var e:Dictionary=enemies[i]
	var origin:Vector2i=e.pos
	var tactical:bool=bool(e.get("ecology_search_enabled",false))
	if tactical:
		if bool(e.get("windup",false)):return false
		if enemy_execute_party_attack(i,enemy_party_attack_plan(e)):return true
	var nearest:int=-1
	var best:int=distance(origin,player)
	var planned_step:Vector2i=origin
	if tactical:
		var plan:Dictionary=enemy_party_approach_plan(e)
		if plan.is_empty():return false
		nearest=int(plan.index);best=int(plan.gap);planned_step=plan.step
	else:
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
		enemy_record_squad_focus(e,int(a.get("uid",1000+nearest)),damage)
		enemy_actions.append({"uid":e.get("uid",i),"phase":"attack","from":origin,"to":a.pos,"move":"Ally strike","fx":"basic_strike","damage":damage,"tiles":[a.pos],"path":[a.pos]})
		emit_event("Ally struck −%d HP"%damage)
		enemy_tick_all_cooldowns(e);return true
	var step:Vector2i=planned_step
	if not tactical:
		var path:Array[Vector2i]=route(origin,a.pos,true)
		if not path.is_empty() and free_party_tile(path[0]):step=path[0]
	if step!=origin and int(e.get("stuck_turns",0))<=0:
		e.pos=step
		enemy_actions.append({"uid":e.get("uid",i),"phase":"move","from":origin,"to":e.pos,"gait":e.get("gait","walk")})
		enemy_tick_all_cooldowns(e);return true
	return false

func enemy_at(p:Vector2i)->int:
	for i in range(enemies.size()):
		if enemies[i].pos==p:return i
	return -1
# Snapshot occupancy once per search, preserving enemy_at/ally_at semantics.
func navigation_occupancy()->Dictionary:
	if ai_actor_cache_active and ai_occupancy_ready:
		ai_cache_hits+=1;return ai_occupancy_cache
	var blocked:Dictionary={}
	for e in enemies:blocked[e.pos]=true
	for a in allies:
		if int(a.hp)>0:blocked[a.pos]=true
	if ai_actor_cache_active:
		ai_occupancy_cache=blocked;ai_occupancy_ready=true;ai_cache_misses+=1
	return blocked

# A straight cardinal route is the unique shortest route if every tile is
# legal. Otherwise use the same FIFO neighbor order as the reference BFS.
var ai_path_nodes:int=0
var ai_path_fast_routes:int=0
var ai_path_reused_searches:int=0

func ai_straight_route(a:Vector2i,b:Vector2i,blocked:Dictionary)->Array[Vector2i]:
	var result:Array[Vector2i]=[]
	if a.x!=b.x and a.y!=b.y:return result
	var d:Vector2i=Vector2i(signi(b.x-a.x),signi(b.y-a.y))
	var gap:int=distance(a,b)
	for i in range(1,gap+1):
		var q:Vector2i=a+d*i
		if not cells.has(q) or (q!=b and blocked.has(q)):
			result.clear();return result
		result.append(q)
	return result

func ai_reconstruct_route(previous:Dictionary,a:Vector2i,b:Vector2i)->Array[Vector2i]:
	var result:Array[Vector2i]=[]
	var p:Vector2i=b
	while p!=a:
		result.append(p);p=previous[p]
	result.reverse()
	return result

# For pursuit of the player, a failed direct search already contains every
# reachable tile in exactly the order used by the old fallback search.
func ai_combined_player_route(origin:Vector2i,target:Vector2i)->Array[Vector2i]:
	var result:Array[Vector2i]=[]
	if origin==target or not cells.has(origin) or not cells.has(target):return result
	var blocked:Dictionary=navigation_occupancy()
	var straight:Array[Vector2i]=ai_straight_route(origin,target,blocked)
	if not straight.is_empty():
		ai_path_fast_routes+=1;return straight
	var previous:Dictionary={origin:origin}
	var queue:Array[Vector2i]=[origin]
	var cursor:int=0
	while cursor<queue.size():
		var p:Vector2i=queue[cursor];cursor+=1
		ai_path_nodes+=1
		for d in DIR:
			var q:Vector2i=p+d
			if previous.has(q) or not cells.has(q) or (q!=target and blocked.has(q)):continue
			previous[q]=p
			if q==target:return ai_reconstruct_route(previous,origin,target)
			queue.append(q)
	var distances:Dictionary=ai_terrain_distances(target)
	if not distances.has(origin):return result
	ai_path_reused_searches+=1
	var best:Vector2i=origin
	var best_distance:int=int(distances[origin])
	for p in queue:
		var remaining:int=int(distances.get(p,2147483647))
		if remaining<best_distance:
			best=p;best_distance=remaining
			if remaining==1:break
	return ai_reconstruct_route(previous,origin,best)

func route(a:Vector2i,b:Vector2i,avoid_enemies:bool=false,diagonal:bool=false)->Array[Vector2i]:
	var result:Array[Vector2i]=[]
	if not cells.has(a) or not cells.has(b) or a==b:return result
	var blocked:Dictionary=navigation_occupancy() if avoid_enemies else {}
	if ai_cache_active and not diagonal:
		var straight:Array[Vector2i]=ai_straight_route(a,b,blocked)
		if not straight.is_empty():
			ai_path_fast_routes+=1;return straight
	var queue:Array[Vector2i]=[a]
	var previous:Dictionary={}
	previous[a]=a
	var cursor=0
	while cursor<queue.size():
		var p=queue[cursor];cursor+=1
		ai_path_nodes+=1
		if p==b:break
		for d in DIR8 if diagonal else DIR:
			var q:Vector2i=p+d
			if not step_clear(p,d) or previous.has(q):continue
			if avoid_enemies and q!=b and blocked.has(q):continue
			previous[q]=p
			if ai_cache_active and q==b:return ai_reconstruct_route(previous,a,b)
			queue.append(q)
	if not previous.has(b):return result
	var p=b
	while p!=a:
		result.append(p);p=previous[p]
	result.reverse()
	return result

# When a corridor is blocked, approach the nearest reachable point measured
# by real terrain distance, not Manhattan distance through walls.
func ai_terrain_distances(target:Vector2i)->Dictionary:
	if ai_cache_active and ai_terrain_cache.has(target):
		ai_cache_hits+=1;return ai_terrain_cache[target]
	var distances:Dictionary={target:0}
	var terrain_queue:Array[Vector2i]=[target]
	var cursor:int=0
	while cursor<terrain_queue.size():
		var p:Vector2i=terrain_queue[cursor];cursor+=1
		for d in DIR:
			var q:Vector2i=p+d
			if not cells.has(q) or distances.has(q):continue
			distances[q]=int(distances[p])+1;terrain_queue.append(q)
	if ai_cache_active:
		ai_cache_misses+=1
		if ai_terrain_cache.size()<AI_TERRAIN_CAP:ai_terrain_cache[target]=distances
	return distances

func enemy_approach_route(origin:Vector2i,target:Vector2i)->Array[Vector2i]:
	if ai_cache_active and target==player:return ai_combined_player_route(origin,target)
	var direct:Array[Vector2i]=route(origin,target,true)
	if not direct.is_empty() or origin==target:return direct
	if not cells.has(origin) or not cells.has(target):return direct
	var distances:Dictionary=ai_terrain_distances(target)
	var cursor:int=0
	if not distances.has(origin):return direct
	var blocked:Dictionary=navigation_occupancy()
	var previous:Dictionary={origin:origin}
	var queue:Array[Vector2i]=[origin]
	var best:Vector2i=origin
	var best_distance:int=int(distances[origin])
	cursor=0
	while cursor<queue.size():
		var p:Vector2i=queue[cursor];cursor+=1
		ai_path_nodes+=1
		var remaining:int=int(distances.get(p,2147483647))
		if remaining<best_distance:
			best_distance=remaining;best=p
			if remaining==1:break
		for d in DIR:
			var q:Vector2i=p+d
			if not cells.has(q) or previous.has(q) or blocked.has(q) or q==player:continue
			previous[q]=p;queue.append(q)
	var p:Vector2i=best
	while p!=origin:
		direct.append(p);p=previous[p]
	direct.reverse()
	return direct

func exploration_count()->int:
	return explored_rooms.size()+explored_side_chambers.size()

func exploration_total()->int:
	return rooms.size()+side_chambers.size()

func exploration_coin_bonus()->int:
	return mini(6,maxi(0,exploration_count()-2)*2)

func exploration_material_bonus()->int:
	if starter_woods or not guardian_defeated or rooms.is_empty():return 0
	return 1 if exploration_count()==exploration_total() else 0

func reveal():
	for i in range(side_chambers.size()):
		if side_chambers[i].has_point(player):explored_side_chambers[i]=true
	for i in range(rooms.size()):
		if rooms[i].has_point(player) and not explored_rooms.has(i):
			explored_rooms[i]=true
	for p in cells:
		if distance(p,player)<=5:revealed[p]=true
	for room in rooms+side_chambers:
		if room.has_point(player):
			for p in cells:
				if room.has_point(p):revealed[p]=true
func emit_event(value:String):
	last_event=value;event_serial+=1
func visual_interaction(kind:String,cell:Vector2i)->void:
	visual_interactions.append({"kind":kind,"cell":cell,"floor":floor_revision})
	if visual_interactions.size()>16:visual_interactions.pop_front()
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
		if add_technique_manual(id):
			message="Technique manual found · "+str(MOVE_LIBRARY[id].name);emit_event(message)
			visual_interaction("manual",player)
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
		"relic":secured=true;coins+=5;message="Optional treasure · +5 coins"
	emit_event(message)
	if kind in ["coin","potion","trail_fruit","ward_band","force_band","material","spring","relic"]:visual_interaction(kind,player)
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
		record_cast_result(q,dealt,true,false,false)
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
	enemy_record_push_pressure(e)
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
# Explorers of Sky conventional attack: typeless, physical, base power 1,
# 93% base accuracy, zero inherent crit, half damage multiplier, no PP.
# Kindria uses its own creature stat scale and neutral defense fallback.
const REGULAR_ATTACK={"name":"Strike","type":"typeless","typeless":true,"category":"physical","power":1,"acc1":93,"acc2":125,"reference_crit":0,"pattern":"front","reach":1}
static func regular_attack_damage(attack_value:float,defense_value:float,level:int,variance:float=1.0)->int:
	var a:float=clampf(attack_value,1.0,999.0)
	var d:float=clampf(defense_value,1.0,999.0)
	var argument:float=clampf(10.0*(clampi(level,1,100)+(a-d)/8.0)+500.0,1.0,4095.0)
	var raw:float=153.0/256.0*(a+1.0)-d/2.0+50.0*log(argument)-311.0
	return maxi(0,roundi(clampf(raw,1.0,999.0)*.5*clampf(variance,.875,1.125)))
func strike(i:int,power:bool=false,style_override:int=-1,move_id:String="",damage_multiplier:float=1.0,override_move:Dictionary={}):
	var attack_style:int=skill_kind if style_override<0 else clampi(style_override,0,2)
	if i<0 or i>=enemies.size():return
	attack_serial+=1;attack_target=enemies[i].pos;attack_power=power
	player_attack_fx="basic_strike" if not power else ["briar_arc","leaf_dart","jelly_pulse"][attack_style]
	player_attack_cells=[attack_target]
	if power and maxi(absi(attack_target.x-player.x),absi(attack_target.y-player.y))==2:player_attack_cells.push_front(player+(attack_target-player)/2)
	player_attack_path=player_attack_cells.duplicate()
	var regular:bool=not power and move_id.is_empty() and override_move.is_empty()
	var move:Dictionary=REGULAR_ATTACK if regular else override_move if not override_move.is_empty() else MOVE_LIBRARY.get(move_id,{})
	if regular and not roll_reference_hit(move,enemies[i]):
		last_type_multiplier=1.0
		player_cast_results.clear();record_cast_result(attack_target,0,false,false,false);player_cast_result_serial=attack_serial
		message="Strike missed";emit_event(message);return
	var element:String=str(move.get("type","normal"))
	if move.is_empty() and power and not trained_profile.is_empty():element=str(trained_profile.types[0])
	if not move.is_empty() and not regular:element=resolved_move_element(move)
	var damage:int=int(move.power) if not move.is_empty() else 10 if power else 6
	if move.get("hidden_power",false):damage=hidden_base_power
	if int(move.get("reference_id",-1))==31 and element!="normal":damage*=2
	last_type_multiplier=1.0
	if regular:
		var level:int=int(trained_profile.get("level",1))
		var defense:float=float(enemies[i].get("defense_stat",neutral_combat_stat(2)))
		damage=regular_attack_damage(combat_stat(1)*player_stat_effect("attack"),defense*enemy_stat_effect(enemies[i],"defense"),level,rng.randf_range(.875,1.125))
	elif not trained_profile.is_empty():
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
	if damage>0 and not regular:
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
	if move_id.is_empty():
		player_cast_results.clear();record_cast_result(attack_target,dealt,true,false,critical);player_cast_result_serial=attack_serial
	else:last_move_damage.append(dealt)
	enemy_remember_incoming(enemies[i],dealt,element)
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
		enemy_record_witnessed_loss(enemies[i])
		gain_enemy_ev(enemies[i])
		drop_held_item(enemies[i])
		enemies.remove_at(i);defeated+=1;combo+=1;best_combo=maxi(best_combo,combo)
		if guardian:guardian_defeated=true
		visual_interaction("guardian_win" if guardian else "enemy_win",player)
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
func enemy_major_periodic_damage(e:Dictionary)->int:
	var major:String=str(e.get("major_status",""))
	if major not in ["poison","toxic","burn"]:return 0
	var interval:int=2 if major=="toxic" else 20
	if int(e.get("status_age",0))%interval!=0:return 0
	return 2 if major=="poison" else 6

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
			var damage:int=enemy_major_periodic_damage(e)
			if damage>0:
				visual_record_response(e,damage,major)
				e.hp=int(e.hp)-damage
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
	update_monster_house()
func finish_walk_turn()->void:
	travel_steps_used+=1
	if travel_steps_used>=travel_speed():enemy_turn()
	else:
		enemy_actions.clear();reveal()
		if not spend_belly():return
		message="Movement ×%d · %d steps left"%[travel_speed(),travel_speed()-travel_steps_used]
		update_monster_house()
# Enemy kits have independent PP; basic attacks never consume a move slot.
func mirror_veil_blocks(origin:Vector2i,special:bool,pattern:String)->bool:
	return boon_active("mirror_veil") and special and distance(origin,player)==1 and pattern!="corner_front"

func apply_fatal_grudge(e:Dictionary)->bool:
	if not boon_active("grudge") or hp>0:return false
	var slot:String=str(e.get("last_move_slot",""))
	if slot not in ["primary","secondary","support","control"]:return false
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
	return int(e.get("pp_"+slot,0 if slot=="control" else 12 if slot=="primary" else 10))

# Estimate the existing damage formula without rolling RNG or mutating combat state.
# Area kits choose a legal heading that hits the player and as many visible
# party members as possible. Single-target moves retain their original behavior.
func enemy_area_pattern(pattern:String)->bool:
	return pattern in ["fan","radius","cross","corner","room","corner_front"]

func enemy_area_allies(origin:Vector2i,footprint:Dictionary)->Array[int]:
	var targets:Array[int]=[]
	for i in range(allies.size()):
		var a:Dictionary=allies[i]
		if int(a.hp)>0 and footprint.has(a.pos) and enemy_line_of_sight(origin,a.pos):targets.append(i)
	return targets

func enemy_area_aim(e:Dictionary,pattern:String,reach:int)->Vector2i:
	var origin:Vector2i=e.pos
	var best:Vector2i=attack_aim(origin,player,pattern,reach)
	if not bool(e.get("ecology_search_enabled",false)) or not enemy_area_pattern(pattern) or not enemy_line_of_sight(origin,player) or allies.is_empty():return best
	var best_count:int=-1
	if best!=Vector2i.ZERO:best_count=enemy_area_allies(origin,attack_footprint(origin,best,pattern,reach)).size()
	for d in DIR:
		var footprint:Dictionary=attack_footprint(origin,d,pattern,reach)
		if not footprint.has(player):continue
		var count:int=enemy_area_allies(origin,footprint).size()
		if count>best_count:best=d;best_count=count
	return best

func enemy_area_bonus(e:Dictionary,pattern:String,reach:int,aim:Vector2i)->float:
	if aim==Vector2i.ZERO or not bool(e.get("ecology_search_enabled",false)) or not enemy_area_pattern(pattern):return 0.0
	return 1.5*float(enemy_area_allies(e.pos,attack_footprint(e.pos,aim,pattern,reach)).size())

func enemy_has_party_area_attack(e:Dictionary)->bool:
	if not bool(e.get("ecology_search_enabled",false)) or allies.is_empty() or not enemy_live_contact(e,player):return false
	var skill:Array=signature_skill(e)
	var pattern:String=str(ATTACK_PATTERNS.get(e.get("species",""),"line"))
	var charged:bool=bool(e.get("windup",false))
	if enemy_move_allowed(e,"primary") and (charged or int(e.get("cooldown",0))<=0):
		var aim:Vector2i=e.get("aim",Vector2i.ZERO) if charged else enemy_area_aim(e,pattern,int(skill[0]))
		if enemy_area_bonus(e,pattern,int(skill[0]),aim)>0.0 and attack_footprint(e.pos,aim,pattern,int(skill[0])).has(player):return true
	if charged:return false
	var species:String=str(e.get("species",""))
	if int(e.get("alt_cooldown",0))<=0 and SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary"):
		var alt:Array=SECONDARY_SKILLS[species]
		var aim:Vector2i=enemy_area_aim(e,str(alt[1]),int(alt[0]))
		return enemy_area_bonus(e,str(alt[1]),int(alt[0]),aim)>0.0
	return false

# Resolve each living party member once, independently of the player's dodge,
# shield or critical. Preserve the player-facing effectiveness state.
# Shared party hit estimate used by target choice and actual damage resolution.
func enemy_party_damage_estimate(e:Dictionary,a:Dictionary,skill:Array,secondary:bool)->Dictionary:
	var info:Array=ENEMY_TRAINING.get(e.get("species",""),[["normal"],"normal","normal",0,0,"physical"])
	var element:String=str(info[2] if secondary else info[1])
	var category:String=str(info[5])
	var attack_key:String="sp_attack" if category=="special" else "attack"
	var defense_key:String="sp_defense" if category=="special" else "defense"
	var raw:int=maxi(1,2+tier+int(floor_number/3)+(2 if int(e.get("kind",0))>=2 else 0)+int(skill[3]))
	var types:Array=ENEMY_TRAINING.get(a.get("species",""),[["normal"]])[0].duplicate()
	if gravity_active and element=="ground":types.erase("flying")
	var effectiveness:float=type_multiplier(element,types)
	var amount:float=float(raw)*effectiveness*(1.2 if element in info[0] else 1.0)*weather_factor(element)
	amount*=enemy_stat_effect(e,attack_key)/maxf(.001,stat_effect(a.get("stages",{}),a.get("stat_halves",{}),defense_key))
	if str(e.get("major_status",""))=="burn":amount*=.8
	var factor:float=enemy_stat_effect(e,"accuracy")*stat_effect(a.get("stages",{}),a.get("stat_halves",{}),"evasion")/(263.0/256.0)
	var damage:int=held_item_damage(maxi(0,roundi(amount)),str(e.get("held_item","")),str(a.get("held_item","")))
	return {"damage":damage,"accuracy":clampf(factor,0.0,1.0),"effectiveness":effectiveness}

func enemy_resolve_party_hit(e:Dictionary,index:int,skill:Array,secondary:bool)->Dictionary:
	var a:Dictionary=allies[index]
	var estimate:Dictionary=enemy_party_damage_estimate(e,a,skill,secondary)
	var factor:float=float(estimate.accuracy)
	var missed:bool=(factor<1.0 and rng.randf()>=factor) or (int(e.get("whiffer_turns",0))>0 and rng.randi_range(1,100)>5)
	var damage:int=0 if missed else mini(int(a.hp),int(estimate.damage))
	a.hp=int(a.hp)-damage
	enemy_remember_result(e,int(a.get("uid",1000+index)),"secondary" if secondary else "primary",float(estimate.effectiveness),missed,false)
	return {"uid":a.get("uid",1000+index),"tile":a.pos,"damage":damage,"dodged":missed,"effectiveness":estimate.effectiveness}

func enemy_apply_area_damage(e:Dictionary,origin:Vector2i,footprint:Dictionary,pattern:String,skill:Array,secondary:bool)->Array[Dictionary]:
	var results:Array[Dictionary]=[]
	if not bool(e.get("ecology_search_enabled",false)) or not enemy_area_pattern(pattern):return results
	for index in enemy_area_allies(origin,footprint):
		results.append(enemy_resolve_party_hit(e,index,skill,secondary))
	return results

# Select immediate learned attacks against vulnerable visible party members.
# No speculative knowledge of hidden actors and no RNG during scoring.
# A local squad remembers actual successful attacks for two turns. Observers
# must independently see both the attacking companion and the live target.
func enemy_record_squad_focus(e:Dictionary,target_uid:int,damage:int)->void:
	if damage<=0 or not bool(e.get("ecology_search_enabled",false)):return
	e["squad_focus_uid"]=target_uid
	e["squad_focus_turn"]=turns

func enemy_squad_partner(e:Dictionary,other:Dictionary)->bool:
	if e.pos==other.pos or int(other.hp)<=0 or int(other.get("decoy_turns",0))>0 or not bool(other.get("ecology_search_enabled",false)):return false
	if distance(e.pos,other.pos)>mini(4,enemy_awareness(e)) or not enemy_line_of_sight(e.pos,other.pos):return false
	if int(other.get("sleep_turns",0))>0 or int(other.get("nightmare_turns",0))>0 or int(other.get("paused_turns",0))>0 or int(other.get("wrapped_turns",0))>0 or int(other.get("infatuated_turns",0))>0 or int(other.get("confusion_turns",0))>0 or str(other.get("major_status","")) in ["freeze","paralysis"]:return false
	return true

func enemy_squad_focus_bonus(e:Dictionary,target_uid:int,tile:Vector2i)->float:
	if not bool(e.get("ecology_search_enabled",false)) or distance(e.pos,tile)>enemy_awareness(e) or not enemy_line_of_sight(e.pos,tile):return 0.0
	if target_uid==-1:
		if tile!=player or hp<=0:return 0.0
	else:
		var index:int=ally_at(tile)
		if index<0 or int(allies[index].get("uid",1000+index))!=target_uid:return 0.0
	var count:int=0
	for other in enemies:
		var age:int=turns-int(other.get("squad_focus_turn",-9999))
		if age<0 or age>2 or int(other.get("squad_focus_uid",-9999))!=target_uid:continue
		if not enemy_squad_partner(e,other):continue
		if distance(other.pos,tile)>enemy_awareness(other) or not enemy_line_of_sight(other.pos,tile):continue
		count+=1
		if count>=2:break
	return float(count)*1.25

# Local interception: reserve a free adjacent escape tile on the opposite side
# of an engaged partner. At most three cardinal steps are considered.
# Short-lived, local intentions prevent multiple hunters choosing the same flank.
# Claims are advisory, never physical blockers or promises of extra movement.
func enemy_pack_reserved_posts(e:Dictionary,target:Vector2i)->Dictionary:
	var out:Dictionary={}
	# An advisory flank claim cannot reveal a concealed or unwitnessed player.
	if target==player and not enemy_live_contact(e,target):return out
	for other in enemies:
		if not other.has("pack_post"):continue
		var age:int=turns-int(other.get("pack_turn",-9999))
		var post:Vector2i=other.pack_post
		if age<0 or age>1 or other.get("pack_target",Vector2i.ZERO)!=target or bool(other.get("windup",false)) or int(other.get("stuck_turns",0))>0:continue
		if distance(other.pos,post)>2 or distance(post,target)!=1 or not enemy_ambush_safe_tile(post):continue
		if not enemy_squad_partner(e,other):continue
		# A skipped slow phase cannot justify holding an otherwise useful post.
		if int(other.get("slow_turns",0))>0 and int(other.slow_turns)%2==0:continue
		if target==player and not enemy_live_contact(other,target):continue
		if not enemy_line_of_sight(other.pos,target) or not enemy_line_of_sight(e.pos,post):continue
		out[post]=true
	return out

func enemy_pack_commit(e:Dictionary,target:Vector2i,post:Vector2i)->void:
	e["pack_post"]=post;e["pack_target"]=target;e["pack_turn"]=turns

func enemy_squad_intercept_step(e:Dictionary,target:Vector2i)->Vector2i:
	return enemy_pack_intercept_plan(e,target).get("step",e.pos)

# Prefer distinct attack directions and avoid occupying a visible partner's
# firing line. Positional bonuses do not create collision or attack effects.
func enemy_formation_post_bonus(e:Dictionary,post:Vector2i,target:Vector2i)->int:
	if not bool(e.get("personality_enabled",false)) or distance(post,target)!=1:return 0
	var score:int=0
	var distinct:bool=false
	var opposite:bool=false
	for other in enemies:
		if not enemy_squad_partner(e,other) or not enemy_line_of_sight(other.pos,target):continue
		if enemy_relief_blocks_lane(other,post,target):return -12
		if distance(other.pos,target)!=1:continue
		if other.pos-target==target-post:opposite=true
		elif other.pos!=post:distinct=true
	if opposite:score+=4
	elif distinct:score+=2
	# An isolated target is easier to surround, but never ignore real obstacles.
	if enemy_formation_support_count(e,target)==0:score+=2
	return score

func enemy_pack_intercept_plan(e:Dictionary,target:Vector2i)->Dictionary:
	var origin:Vector2i=e.pos
	if not bool(e.get("ecology_search_enabled",false)) or (bool(e.get("monster_house",false)) and not bool(e.get("house_tactical",false))) or int(e.get("kind",0))==3 or int(e.get("stuck_turns",0))>0 or bool(e.get("windup",false)):return {}
	if enemy_survival_profile(e) not in ["aggressive","defensive"] or distance(origin,target)>mini(5,enemy_awareness(e)) or not enemy_line_of_sight(origin,target):return {}
	var engaged:Array[Vector2i]=[]
	for other in enemies:
		if enemy_squad_partner(e,other) and distance(other.pos,target)==1 and enemy_line_of_sight(other.pos,target):engaged.append(other.pos)
	if engaged.is_empty() or target!=player or charge_phase in ["underground","airborne","vanish"] or boon_active("decoy"):return {}
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var occupied:Dictionary=navigation_occupancy()
	var queue:Array[Vector2i]=[origin]
	var depth:Dictionary={origin:0}
	var first:Dictionary={origin:origin}
	var best:Vector2i=origin
	var best_post:Vector2i=origin
	var best_score:int=-2147483647
	var cursor:int=0
	while cursor<queue.size():
		var here:Vector2i=queue[cursor];cursor+=1
		var steps:int=int(depth[here])
		if steps>0 and distance(here,target)==1 and not reserved.has(here) and enemy_line_of_sight(here,target):
			var separation:int=8
			for op in engaged:separation=mini(separation,distance(here,op))
			var onward:Vector2i=here+(here-target)
			var score:int=separation*6-steps*4+(5 if cells.has(onward) and not occupied.has(onward) else 0)+enemy_formation_post_bonus(e,here,target)
			for a in allies:
				if int(a.hp)>0 and distance(target,a.pos)<=3 and enemy_line_of_sight(origin,a.pos) and distance(here,a.pos)<distance(target,a.pos):score+=2
			if score>best_score:best_score=score;best=first[here];best_post=here
		if steps>=3:continue
		for d in DIR:
			var q:Vector2i=here+d
			if depth.has(q) or not cells.has(q) or occupied.has(q) or reserved.has(q) or q==target or q==player or q==stairs or q==relic or q in side_rewards or traps.has(q) or player_traps.has(q):continue
			depth[q]=steps+1;first[q]=q if steps==0 else first[here];queue.append(q)
	return {} if best==origin else {"step":best,"post":best_post}

# Relative opportunity from observable local formation and actual hit chance.
# Missing or hidden allies are never counted as known supporting creatures.
func enemy_target_exposure(e:Dictionary,tile:Vector2i,target_uid:int)->float:
	if not bool(e.get("personality_enabled",false)) or distance(e.pos,tile)>enemy_awareness(e) or not enemy_line_of_sight(e.pos,tile):return 0.0
	var support:int=0
	if target_uid==-1 and (hp<=0 or tile!=player or charge_phase in ["underground","airborne","vanish"] or boon_active("decoy")):return 0.0
	if target_uid!=-1 and hp>0 and charge_phase not in ["underground","airborne","vanish"] and not boon_active("decoy") and distance(player,tile)<=2 and distance(e.pos,player)<=enemy_awareness(e) and enemy_line_of_sight(e.pos,player) and enemy_line_of_sight(tile,player):support+=1
	for index in range(allies.size()):
		var friend:Dictionary=allies[index]
		if int(friend.hp)<=0 or int(friend.get("uid",1000+index))==target_uid:continue
		if distance(e.pos,friend.pos)>enemy_awareness(e) or distance(tile,friend.pos)>2 or not enemy_line_of_sight(e.pos,friend.pos) or not enemy_line_of_sight(tile,friend.pos):continue
		support+=1
		if support>=2:break
	return 1.25 if support==0 else .5 if support==1 else 0.0

func enemy_party_opportunity_value(e:Dictionary,a:Dictionary,index:int,skill:Array,secondary:bool)->float:
	var life:int=int(a.hp)
	if life<=0 or distance(e.pos,a.pos)>enemy_awareness(e) or not enemy_line_of_sight(e.pos,a.pos):return 0.0
	var estimate:Dictionary=enemy_party_damage_estimate(e,a,skill,secondary)
	var chance:float=float(estimate.accuracy)
	if int(e.get("whiffer_turns",0))>0:chance*=.05
	var expected:float=float(mini(life,int(estimate.damage)))*chance
	if expected<=0.0:return 0.0
	var cap:int=maxi(life,int(a.get("max_hp",life)))
	var uid:int=int(a.get("uid",1000+index))
	var slot:String="secondary" if secondary else "primary"
	var knockout:float=2.5*chance if int(estimate.damage)>=life else 0.0
	var tactical:float=(1.0-float(life)/float(cap))*1.5+enemy_squad_focus_bonus(e,uid,a.pos)
	tactical+=enemy_target_exposure(e,a.pos,uid)
	if bool(e.get("personality_enabled",false)):tactical*=chance
	return (expected+knockout)*enemy_observed_attack_weight(e,uid,slot)+tactical

# Utility scores include status and personality benefits; they are not HP
# damage. Award a finishing preference only for a credible immediate hit.
func enemy_party_player_ko_bonus(e:Dictionary,skill:Array,secondary:bool,basic:bool=false)->float:
	if not enemy_live_contact(e,player) or bool(e.get("windup",false)) or int(e.get("whiffer_turns",0))>0:return 0.0
	if basic:
		if distance(e.pos,player)!=1:return 0.0
	else:
		var slot:String="secondary" if secondary else "primary"
		if bool(skill[1]) or not enemy_move_allowed(e,slot) or int(e.get("alt_cooldown" if secondary else "cooldown",0))>0:return 0.0
		var species:String=str(e.get("species",""))
		var pattern:String=str(SECONDARY_SKILLS[species][1]) if secondary and SECONDARY_SKILLS.has(species) else str(ATTACK_PATTERNS.get(species,"line"))
		if attack_aim(e.pos,player,pattern,int(skill[0]))==Vector2i.ZERO:return 0.0
	var accuracy:float=clampf(enemy_stat_effect(e,"accuracy")*player_stat_effect("evasion")/(263.0/256.0),0.0,1.0)
	if accuracy<.85 or enemy_opportunity_damage(e,skill,secondary,basic)<hp:return 0.0
	return 2.5*accuracy

# Party comparisons have their own geometry- and accuracy-checked KO
# premium. Do not also add the generic positional opportunity premium.
func enemy_party_player_attack_value(e:Dictionary,skill:Array,secondary:bool)->float:
	return enemy_attack_score(e,skill,secondary,false)+enemy_party_player_ko_bonus(e,skill,secondary)

func enemy_party_attack_plan(e:Dictionary,reuse_scores:bool=true)->Dictionary:
	var origin:Vector2i=e.pos
	if not bool(e.get("ecology_search_enabled",false)) or bool(e.get("windup",false)) or allies.is_empty() or int(e.get("kind",0))==3:return {}
	var primary:Array=signature_skill(e)
	var species:String=str(e.get("species",""))
	var kits:Array=[]
	if int(e.get("cooldown",0))<=0 and enemy_move_allowed(e,"primary") and not bool(primary[1]):
		kits.append({"slot":"primary","skill":primary,"pattern":str(ATTACK_PATTERNS.get(species,"line")),"name":str(e.get("signature","Strike"))})
	if int(e.get("alt_cooldown",0))<=0 and enemy_move_allowed(e,"secondary") and SECONDARY_SKILLS.has(species):
		var alt:Array=SECONDARY_SKILLS[species]
		kits.append({"slot":"secondary","skill":[alt[0],false,3,alt[3],alt[4],alt[5],"alt_"+species],"pattern":str(alt[1]),"name":str(alt[2])})
	var player_value:float=0.0
	# Scores depend on the kit, not on which valid heading reaches the player.
	var player_kit_values:Dictionary={}
	var player_context:float=0.0
	var player_visible:bool=enemy_live_contact(e,player)
	var player_protected:bool=(shield_turns>0 and shield_kind=="protect") or charge_phase in ["underground","airborne","vanish"]
	if player_visible and not player_protected and distance(origin,player)==1:player_value=float(maxi(1,1+tier))+enemy_party_player_ko_bonus(e,[],false,true)
	if player_visible and not player_protected and int(e.get("cooldown",0))<=0 and enemy_move_allowed(e,"primary") and attack_aim(origin,player,str(ATTACK_PATTERNS.get(species,"line")),int(primary[0]))!=Vector2i.ZERO:
		player_kit_values["primary"]=enemy_party_player_attack_value(e,primary,false)
		player_value=maxf(player_value,float(player_kit_values["primary"]))
	if player_visible and not player_protected:
		player_context=(1.0-float(hp)/float(maxi(1,max_hp)))*1.5+enemy_squad_focus_bonus(e,-1,player)+enemy_target_exposure(e,player,-1)
	if player_value>0.0:player_value+=player_context
	var best:Dictionary={}
	var best_score:float=player_value+.25
	for kit in kits:
		var skill:Array=kit.skill
		var pattern:String=kit.pattern
		var secondary:bool=kit.slot=="secondary"
		# All candidate headings share the same actor, kit and target state.
		# The memo is local to this pure plan; it cannot survive a real action.
		var ally_values:Dictionary={}
		var scarcity:float=.85 if enemy_move_pp(e,str(kit.slot))<=2 else 1.0
		# Radial, cross and room footprints are invariant to heading. Preserve
		# the first heading for deterministic ties and the exhaustive reference.
		var headings:Array=[DIR[0]] if reuse_scores and pattern in ["radius","cross","room"] else DIR
		for d in headings:
			var footprint:Dictionary=attack_footprint(origin,d,pattern,int(skill[0]))
			if player_visible and footprint.has(player):
				if not player_protected:
					if not player_kit_values.has(kit.slot):player_kit_values[kit.slot]=enemy_party_player_attack_value(e,skill,secondary)
					var value:float=float(player_kit_values[kit.slot])+player_context
					best_score=maxf(best_score,value+.25)
				continue
			var candidates:Array[int]=enemy_area_allies(origin,footprint)
			if candidates.is_empty():continue
			if not enemy_area_pattern(pattern):
				# A line hits the first opposing creature, never shoots through it.
				var nearest:int=-1
				var nearest_gap:int=99999
				for index in candidates:
					var gap:int=distance(origin,allies[index].pos)
					if gap<nearest_gap:nearest=index;nearest_gap=gap
				candidates.clear();candidates.append(nearest)
			var score:float=0.0
			var targets:Array[int]=[]
			for index in candidates:
				var a:Dictionary=allies[index]
				if distance(origin,a.pos)>enemy_awareness(e):continue
				var opportunity:float=0.0
				if reuse_scores and ally_values.has(index):opportunity=float(ally_values[index])
				else:
					opportunity=enemy_party_opportunity_value(e,a,index,skill,secondary)
					if reuse_scores:ally_values[index]=opportunity
				if opportunity<=0.0:continue
				score+=opportunity
				targets.append(index)
			score*=scarcity
			if not targets.is_empty() and score>best_score:
				best_score=score
				best={"slot":kit.slot,"skill":skill,"pattern":pattern,"name":kit.name,"aim":d,"footprint":footprint,"targets":targets,"score":score}
	# A later player-facing heading may have raised the comparison threshold.
	if not best.is_empty() and float(best.score)<best_score:return {}
	return best

func enemy_execute_party_attack(i:int,plan:Dictionary)->bool:
	if plan.is_empty():return false
	var e:Dictionary=enemies[i]
	var slot:String=str(plan.slot)
	if not enemy_move_allowed(e,slot):return false
	var origin:Vector2i=e.pos
	var skill:Array=plan.skill
	var target_tile:Vector2i=allies[int(plan.targets[0])].pos
	var results:Array[Dictionary]=[]
	for index in plan.targets:
		if int(allies[index].hp)>0:results.append(enemy_resolve_party_hit(e,index,skill,slot=="secondary"))
	if results.is_empty():return false
	for hit in results:
		if int(hit.damage)>0:
			enemy_record_squad_focus(e,int(hit.uid),int(hit.damage));break
	record_enemy_move(e,slot)
	var cd:String="alt_cooldown" if slot=="secondary" else "cooldown"
	for key in ["cooldown","alt_cooldown","control_cooldown","support_cooldown"]:
		if key!=cd and int(e.get(key,0))>0:e[key]=int(e[key])-1
	e[cd]=maxi(0,int(skill[2])-1)
	var footprint:Dictionary=plan.footprint
	enemy_actions.append({"uid":e.get("uid",i),"phase":"attack","from":origin,"to":target_tile,"move":plan.name,"fx":skill[6],"damage":0,"party_hits":results,"aim":plan.aim,"pattern":plan.pattern,"tiles":footprint.keys(),"path":footprint.get(target_tile,[target_tile])})
	emit_event(str(plan.name)+" · Party targeted")
	return true

# Personal combat observations are bounded to recent, resolved attacks.
# Dodges and temporary protection must never be mistaken for type immunity.
const ENEMY_MEMORY_CAP:int=8
const ENEMY_MEMORY_TTL:int=6

func enemy_remember_result(e:Dictionary,target_uid:int,slot:String,effectiveness:float,dodged:bool,blocked:bool)->void:
	if not bool(e.get("ecology_search_enabled",false)) or dodged or blocked or slot not in ["primary","secondary"]:return
	var memory:Dictionary=e.get("combat_observations",{})
	var key:String=str(target_uid)+":"+slot
	if not memory.has(key) and memory.size()>=ENEMY_MEMORY_CAP:
		var oldest:String=""
		var oldest_turn:int=2147483647
		for id in memory:
			if int(memory[id].turn)<oldest_turn:
				oldest=str(id);oldest_turn=int(memory[id].turn)
		memory.erase(oldest)
	memory[key]={"turn":turns,"effectiveness":effectiveness}
	e["combat_observations"]=memory

func enemy_observed_attack_weight(e:Dictionary,target_uid:int,slot:String)->float:
	if not bool(e.get("ecology_search_enabled",false)):return 1.0
	var memory:Dictionary=e.get("combat_observations",{})
	var key:String=str(target_uid)+":"+slot
	if not memory.has(key):return 1.0
	var sample:Dictionary=memory[key]
	var age:int=turns-int(sample.turn)
	if age<0 or age>ENEMY_MEMORY_TTL:return 1.0
	var effectiveness:float=float(sample.effectiveness)
	if effectiveness<=0.0:return .55
	if effectiveness<.99:return .85
	if effectiveness>1.01:return 1.10
	return 1.0

func enemy_remember_incoming(e:Dictionary,damage:int,element:String)->void:
	if damage<=0 or not bool(e.get("ecology_search_enabled",false)):return
	if not enemy_live_contact(e,player):return
	e["incoming_turn"]=turns;e["incoming_damage"]=damage;e["incoming_element"]=element
	# A multi-hit cast is one observation, not several independent decisions.
	var gap:int=distance(e.pos,player)
	var mode:String="ranged" if gap>=2 else "close"
	var previous:int=int(e.get("counter_hit_turn",-9999))
	if previous==turns:return
	var streak:int=int(e.get("counter_hit_streak",0))
	e["counter_hit_streak"]=mini(3,streak+1) if turns-previous<=3 and turns>previous and str(e.get("counter_hit_mode",""))==mode else 1
	e["counter_hit_turn"]=turns;e["counter_hit_mode"]=mode

# Remember only actual successful player push attempts on this creature.
# Multi-hit effects on the same turn count once, and never grant immunity.
func enemy_record_push_pressure(e:Dictionary)->void:
	if not bool(e.get("personality_enabled",false)) or not bool(e.get("ecology_search_enabled",false)):return
	if not enemy_live_contact(e,player):return
	var last:int=int(e.get("push_pressure_turn",-9999))
	if last==turns:return
	e["push_pressure_count"]=mini(3,int(e.get("push_pressure_count",0))+1) if turns>last and turns-last<=4 else 1
	e["push_pressure_turn"]=turns

func enemy_repeated_push(e:Dictionary)->bool:
	var age:int=turns-int(e.get("push_pressure_turn",-9999))
	return bool(e.get("personality_enabled",false)) and int(e.get("push_pressure_count",0))>=2 and age>=0 and age<=4

# Compare local displacement exposure, not a prediction of the next cast.
# Cardinal lanes are easier to repeat; nearby visible companions increase
# collision risk. Geometry is sampled only within four tiles.
func enemy_push_exposure(e:Dictionary,post:Vector2i,target:Vector2i)->int:
	var delta:Vector2i=post-target
	var heading:=Vector2i(signi(delta.x),signi(delta.y))
	if heading==Vector2i.ZERO:return 999
	var risk:int=3 if delta.x==0 or delta.y==0 else 0
	for n in range(1,5):
		var q:Vector2i=post+heading*n
		if not cells.has(q):break
		if not enemy_line_of_sight(e.pos,q):break
		var index:int=enemy_at(q)
		if index>=0 and q!=e.pos:
			risk+=5;break
		risk+=1
	return risk

func enemy_push_adaptation_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_repeated_push(e) or not enemy_opportunity_eligible(e) or target!=player or charge_phase in ["underground","airborne","vanish"] or int(e.get("stuck_turns",0))>0:return origin
	if bool(e.get("monster_house",false)) or turns<=int(e.get("push_adapt_turn",-9999))+2:return origin
	var gap:int=distance(origin,target)
	if gap<2 or gap>4 or enemy_push_attack_coverage(e,target)>0:return origin
	var initial:int=enemy_push_exposure(e,origin,target)
	var best:Vector2i=origin
	var best_score:int=0
	for d in DIR:
		var q:Vector2i=origin+d
		if not enemy_ambush_safe_tile(q) or not enemy_line_of_sight(q,target) or distance(q,target)>gap+1:continue
		var blocked:bool=false
		for other in enemies:
			if enemy_squad_partner(e,other) and enemy_line_of_sight(other.pos,target) and enemy_relief_blocks_lane(other,q,target):blocked=true;break
		if blocked:continue
		var exposure:int=enemy_push_exposure(e,q,target)
		var score:int=(initial-exposure)*2+gap-distance(q,target)
		if score>best_score and exposure<initial:best_score=score;best=q
	return best

func enemy_counter_pattern(e:Dictionary,mode:String)->bool:
	var age:int=turns-int(e.get("counter_hit_turn",-9999))
	return bool(e.get("ecology_search_enabled",false)) and int(e.get("counter_hit_streak",0))>=2 and str(e.get("counter_hit_mode",""))==mode and age>=0 and age<=3

# Aggressive melee actors under repeated ranged fire may break the firing
# lane for one turn while approaching, rather than walking straight at it.
func enemy_counter_cover_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_live_contact(e,target):return origin
	if not bool(e.get("personality_enabled",false)) or enemy_survival_profile(e)!="aggressive" or not enemy_counter_pattern(e,"ranged") or bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0:return origin
	if int(e.get("kind",0))==3 or bool(e.get("monster_house",false)) or target!=player or distance(origin,target)<3 or distance(origin,target)>enemy_awareness(e) or not enemy_line_of_sight(origin,target):return origin
	if turns<=int(e.get("counter_cover_turn",-9999))+2:return origin
	# Do not trade a ready legal learned attack for cover.
	var skill:Array=signature_skill(e)
	var species:String=str(e.get("species",""))
	if int(e.get("cooldown",0))<=0 and enemy_move_allowed(e,"primary") and attack_aim(origin,target,str(ATTACK_PATTERNS.get(species,"line")),int(skill[0]))!=Vector2i.ZERO:return origin
	if int(e.get("alt_cooldown",0))<=0 and SECONDARY_SKILLS.has(species) and enemy_move_allowed(e,"secondary"):
		var alt:Array=SECONDARY_SKILLS[species]
		if attack_aim(origin,target,str(alt[1]),int(alt[0]))!=Vector2i.ZERO:return origin
	for d in DIR:
		var q:Vector2i=origin+d
		if distance(q,target)>=distance(origin,target) or not enemy_ambush_safe_tile(q) or enemy_line_of_sight(q,target):continue
		return q
	return origin

# A visible full shield is a reason to spend the turn on positioning or
# holding, not repeatedly burn learned PP. Existing windups are respected.
func enemy_counter_protected(e:Dictionary,target:Vector2i)->bool:
	return enemy_opportunity_eligible(e) and enemy_live_contact(e,target) and shield_turns>0 and shield_kind=="protect"

func enemy_counter_protected_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not enemy_counter_protected(e,target) or int(e.get("stuck_turns",0))>0:return origin
	var reserved:Dictionary=enemy_pack_reserved_posts(e,target)
	var peers:Array[Dictionary]=[]
	for other in enemies:
		if enemy_squad_partner(e,other):peers.append(other)
	var lane_memo:Dictionary={}
	var step:Vector2i=enemy_exit_block_step(e,target)
	if step!=origin and not reserved.has(step) and not enemy_recovery_lane_blocked(peers,step,target,lane_memo):return step
	if distance(origin,target)<=1:return origin
	for d in DIR:
		var q:Vector2i=origin+d
		if distance(q,target)<distance(origin,target) and enemy_ambush_safe_tile(q) and not reserved.has(q) and enemy_line_of_sight(q,target) and not enemy_recovery_lane_blocked(peers,q,target,lane_memo):return q
	# Protect does not prevent positioning. If direct approach is blocked,
	# prepare a safe adjacent post without attacking or spending learned PP.
	if distance(origin,target)>3 or enemy_strategy_attack_tile(e,origin,target):return origin
	var queue:Array[Vector2i]=[origin]
	var depth:Dictionary={origin:0}
	var first:Dictionary={}
	var cursor:int=0
	while cursor<queue.size() and cursor<32:
		var tile:Vector2i=queue[cursor];cursor+=1
		if tile!=origin and distance(tile,target)==1:return first[tile]
		if int(depth[tile])>=3:continue
		for d in DIR:
			var q:Vector2i=tile+d
			if depth.has(q) or not enemy_ambush_safe_tile(q) or reserved.has(q) or not enemy_line_of_sight(q,target):continue
			if tile==origin and enemy_strategy_reversal(e,q,target):continue
			if enemy_recovery_lane_blocked(peers,q,target,lane_memo):continue
			depth[q]=int(depth[tile])+1;first[q]=q if tile==origin else first[tile];queue.append(q)
	return origin

func enemy_recent_threat(e:Dictionary)->bool:
	var age:int=turns-int(e.get("incoming_turn",-9999))
	return age>=0 and age<=3 and int(e.get("incoming_damage",0))*4>=maxi(1,int(e.get("max_hp",e.hp)))

# Pure non-critical damage estimate mirrors the player-facing resolution order.
# Do not count status utility, critical rolls or learned-memory multipliers as HP.
# Shared pure damage calculation. Resolution owns RNG, mark consumption,
# criticals and hit side effects; planning can never mutate those states.
func enemy_player_damage_base(e:Dictionary,skill:Array,secondary:bool,basic:bool,mark:int)->Dictionary:
	var info:Array=ENEMY_TRAINING.get(e.get("species",""),[["normal"],"normal","normal",0,0,"physical"])
	var element:String="normal" if basic else str(info[2] if secondary else info[1])
	var category:String="physical" if basic else str(info[5])
	var damage:int=maxi(1,2+tier+int(floor_number/3)+(2 if int(e.get("kind",0))>=2 else 0)+(-1 if basic else int(skill[3])))+maxi(0,mark)
	var effectiveness:float=1.0
	if not trained_profile.is_empty():
		var types:Array=current_player_types()
		if gravity_active and element=="ground":types.erase("flying")
		effectiveness=type_multiplier(element,types)
		var stat:int=4 if str(info[5])=="special" else 2
		damage=maxi(1,roundi(float(damage)*effectiveness*(1.2 if element in info[0] else 1.0)*clampf(maxf(1.0,neutral_combat_stat(stat))/maxf(1.0,combat_stat(stat)),.60,1.65))) if effectiveness>0.0 else 0
	var attack_key:String="sp_attack" if category=="special" else "attack"
	var defense_key:String="sp_defense" if category=="special" else "defense"
	if damage>0:damage=maxi(1,roundi(float(damage)*enemy_stat_effect(e,attack_key)/maxf(.001,player_stat_effect(defense_key))))
	damage=maxi(0,roundi(float(damage)*weather_factor(element)))
	if str(e.get("major_status",""))=="burn":damage=roundi(float(damage)*.8)
	damage=held_item_damage(damage,str(e.get("held_item","")),held_item)
	return {"damage":damage,"effectiveness":effectiveness,"element":element,"category":category}

func enemy_opportunity_damage(e:Dictionary,skill:Array,secondary:bool,basic:bool=false)->int:
	var origin:Vector2i=e.pos
	if charge_phase in ["underground","airborne","vanish"] or (shield_turns>0 and shield_kind=="protect"):return 0
	var species:String=str(e.get("species",""))
	var pattern:String="front" if basic else str(SECONDARY_SKILLS[species][1]) if secondary and SECONDARY_SKILLS.has(species) else str(ATTACK_PATTERNS.get(species,"line"))
	if mirror_veil_blocks(origin,not basic,pattern):return 0
	var estimate:Dictionary=enemy_player_damage_base(e,skill,secondary,basic,marked_damage)
	if boon_active("magnet") and not gravity_active and str(estimate.element)=="ground":return 0
	return shield_damage(int(estimate.damage),str(estimate.category))

# Shared live-contact contract for optional tactical decisions. Remembered
# targets remain available to pursuit/search, not real-time counterplay.
func enemy_live_contact(e:Dictionary,target:Vector2i)->bool:
	return target==player and hp>0 and not boon_active("decoy") and charge_phase not in ["underground","airborne","vanish"] and distance(e.pos,target)<=enemy_awareness(e) and enemy_line_of_sight(e.pos,target)

func enemy_opportunity_eligible(e:Dictionary)->bool:
	return bool(e.get("personality_enabled",false)) and enemy_alert_eligible(e) and not bool(e.get("windup",false)) and enemy_live_contact(e,player)

func enemy_basic_finish(e:Dictionary)->bool:
	if not enemy_opportunity_eligible(e) or distance(e.pos,player)!=1 or hp<=0 or hp>enemy_opportunity_damage(e,[],false,true):return false
	if int(e.get("whiffer_turns",0))>0 or enemy_stat_effect(e,"accuracy")*player_stat_effect("evasion")/(263.0/256.0)<1.0:return false
	# Keep valuable multi-target opportunities instead of blindly conserving PP.
	return not enemy_has_party_area_attack(e)

func enemy_opportunity_bonus(e:Dictionary,skill:Array,secondary:bool)->float:
	if not enemy_opportunity_eligible(e) or bool(skill[1]) or hp<=0:return 0.0
	var damage:int=enemy_opportunity_damage(e,skill,secondary)
	if damage<hp:return 0.0
	var accuracy:float=clampf(enemy_stat_effect(e,"accuracy")*player_stat_effect("evasion")/(263.0/256.0),0.0,1.0)
	if int(e.get("whiffer_turns",0))>0:accuracy*=.05
	return 3.0*accuracy

func enemy_attack_score(e:Dictionary,skill:Array,secondary:bool,include_opportunity:bool=true)->float:
	var info:Array=ENEMY_TRAINING.get(e.get("species",""),[["normal"],"normal","normal",0,0,"physical"])
	var element:String=str(info[2] if secondary else info[1])
	var raw:float=float(maxi(1,2+tier+int(floor_number/3)+(2 if int(e.get("kind",0))>=2 else 0)+int(skill[3])))
	if not trained_profile.is_empty():
		var types:Array=current_player_types().duplicate()
		if gravity_active and element=="ground":types.erase("flying")
		var stat:int=4 if str(info[5])=="special" else 2
		raw*=type_multiplier(element,types)*(1.2 if element in info[0] else 1.0)*clampf(neutral_combat_stat(stat)/maxf(1.0,combat_stat(stat)),.60,1.65)
	raw*=weather_factor(element)
	var effect:String=str(skill[4])
	var protected:bool=shield_kind=="safeguard" and shield_turns>0
	var utility:float=0.0
	match effect:
		"poison":
			if not protected and poison_turns<=0 and not player_has_ability("clear_blood"):utility=1.5
		"weaken":
			if not protected and not boon_active("mist") and weakened_strikes<=0:utility=1.0
		"mark":
			if not protected and marked_damage<=0:utility=1.0
		"drain":
			if energy>0:utility=.8
		"guard":
			if int(e.get("guard",0))<=0:utility=.6
	var slot:String="secondary" if secondary else "primary"
	if bool(e.get("ecology_search_enabled",false)):
		var attack_key:String="sp_attack" if str(info[5])=="special" else "attack"
		var defense_key:String="sp_defense" if str(info[5])=="special" else "defense"
		raw*=enemy_stat_effect(e,attack_key)/maxf(.001,player_stat_effect(defense_key))
		if str(e.get("major_status",""))=="burn":raw*=.8
		if (shield_turns>0 and shield_kind=="protect") or charge_phase in ["underground","airborne","vanish"]:raw=0.0;utility=0.0
	var score:float=raw+utility
	if score>0.0:score+=enemy_personality_bonus(e,skill,utility)
	if bool(skill[1]):
		var control_window:bool=bool(e.get("ecology_search_enabled",false)) and (int(player_boons.get("hostile_sleep",0))>=2 or int(player_boons.get("hostile_paralysis",0))>=3)
		score*=.90 if control_window else .70
	if enemy_move_pp(e,slot)<=2:score*=.85
	return score*enemy_observed_attack_weight(e,-1,slot)+(enemy_opportunity_bonus(e,skill,secondary) if include_opportunity else 0.0)

func enemy_move_allowed(e:Dictionary,slot:String,wait:int=0)->bool:
	if enemy_move_pp(e,slot)<=0 or slot in e.get("sealed_moves",[]):return false
	# Status timers tick between action phases; seals and PP do not.
	var elapsed:int=maxi(0,wait)
	if int(e.get("encore_turns",0))>elapsed and str(e.get("encore_slot",""))!=slot:return false
	if slot in ["support","control"] and int(e.get("taunt_turns",0))>elapsed:return false
	return true

# Catalog equivalents for original Kindria enemy signatures, not a replacement of their tuned AI.
const ENEMY_COPY_KITS={"bramble_pup":["eos_182","eos_154"],"sporeling":["eos_147","eos_251"],"thornbeetle":["eos_529","eos_080"],"leafwisp":["eos_443","eos_251"],"rootgnawer":["eos_289","eos_251"],"vinesnap":["eos_182","eos_486"],"mossmite":["eos_028","eos_030"],"sylphowl":["eos_057","eos_178"],"hollow_stag":["eos_486","eos_251"],"grovetitan":["eos_289","eos_182"],"fungal_monarch":["eos_280","eos_147"],"reef_pup":["eos_069","eos_308"],"jellymancer":["eos_129","eos_308"],"shellguard":["eos_030","eos_028"],"bubblewisp":["eos_016","eos_308"],"eelstrix":["eos_189","eos_144"],"coralcrab":["eos_529","eos_308"],"anemoneye":["eos_198","eos_283"],"marrowray":["eos_057","eos_308"],"leviathorn":["eos_433","eos_308"],"abyss_colossus":["eos_062","eos_063"],"tidal_sovereign":["eos_158","eos_308"],"starlit_pup":["eos_154","eos_190"],"lunamoth":["eos_145","eos_057"],"crystarok":["eos_344","eos_042"],"nova_wisp":["eos_053","eos_262"],"orbitserpent":["eos_234","eos_208"],"comet_hare":["eos_190","eos_154"],"voidspider":["eos_436","eos_114"],"nebulwing":["eos_127","eos_057"],"lunar_prowler":["eos_063","eos_515"],"astro_golem":["eos_030","eos_028"],"celestial_guardian":["eos_145","eos_207"]}
func enemy_catalog_move(e:Dictionary,slot:String)->String:
	if slot=="control":return str(e.get("control_move",""))
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
	if slot not in ["primary","secondary","support","control"]:return false
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
		player_boons["hostile_control_recovery"]=12
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
		if cells.has(q) and q!=player and enemy_at(q)<0 and ally_at(q)<0 and int(actor.get("stuck_turns",0))<=0:
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
	if not path.is_empty() and path[0]!=player and path[0]!=dest and enemy_at(path[0])<0 and ally_at(path[0])<0 and int(actor.get("stuck_turns",0))<=0:
		actor.pos=path[0]
		enemy_actions.append({"uid":actor.get("uid",i),"phase":"move","from":p,"to":path[0],"gait":actor.get("gait","walk")})
		return true
	return false

# Rescue guardians retain their original attacks and telegraphs. Phase changes
# alter decisions, never damage, HP, PP, immunities or action count.
const BOSS_CONTROL_KITS={"fungal_monarch":"eos_079","abyss_colossus":"eos_284","tidal_sovereign":"eos_284","celestial_guardian":"eos_033"}

func boss_combat_phase(e:Dictionary)->int:
	var cap:int=maxi(1,int(e.get("max_hp",e.hp)))
	var life:int=int(e.hp)
	return 2 if life*3<=cap else 1 if life*3<=cap*2 else 0

func boss_tactical_style(e:Dictionary)->String:
	match str(e.get("species","")):
		"fungal_monarch":return "zone"
		"abyss_colossus":return "pressure"
		"tidal_sovereign":return "crossfire"
		"celestial_guardian":return "sentinel"
		_:return "pressure"

func boss_initialize(e:Dictionary)->void:
	e["boss_tactical"]=true;e["boss_home"]=e.pos;e["boss_phase"]=0
	e["ecology_search_enabled"]=true;e["ecology_role"]="sentry"
	var id:String=str(BOSS_CONTROL_KITS.get(str(e.get("species","")),""))
	if MOVE_LIBRARY.has(id):
		e["control_move"]=id;e["pp_control"]=int(MOVE_LIBRARY[id].pp)

func boss_observe_phase(e:Dictionary)->void:
	if not bool(e.get("boss_tactical",false)):return
	var phase:int=boss_combat_phase(e)
	if phase==int(e.get("boss_phase",0)):return
	e["boss_phase"]=phase
	emit_event(str(e.get("name","Guardian"))+" · "+(["Survey","Pressure","Last stand"][phase]))

func boss_attack_preference(e:Dictionary,secondary:bool)->float:
	if not bool(e.get("boss_tactical",false)):return 0.0
	var phase:int=boss_combat_phase(e)
	var style:String=boss_tactical_style(e)
	# Keep the charged signature attractive early; vary with remaining life.
	if secondary:
		if phase==2:return 1.5 if style in ["pressure","crossfire"] else .75
		if phase==1 and style=="crossfire":return 1.0
	else:
		if phase==0 and style in ["zone","sentinel"]:return 1.0
	return 0.0

func boss_reposition_step(e:Dictionary,target:Vector2i)->Vector2i:
	var origin:Vector2i=e.pos
	if not bool(e.get("boss_tactical",false)) or bool(e.get("windup",false)) or int(e.get("stuck_turns",0))>0:return origin
	if distance(origin,target)>enemy_awareness(e) or not enemy_line_of_sight(origin,target):return origin
	var home:Vector2i=e.get("boss_home",origin)
	var style:String=boss_tactical_style(e)
	var phase:int=boss_combat_phase(e)
	var preferred:int=1 if style=="pressure" or (phase==2 and style=="crossfire") else 2 if style=="zone" else 3
	var skill:Array=signature_skill(e)
	var species:String=str(e.get("species",""))
	var pattern:String=str(ATTACK_PATTERNS.get(species,"line"))
	var best:Vector2i=origin
	var best_score:int=-absi(distance(origin,target)-preferred)*3
	if enemy_move_allowed(e,"primary") and attack_aim(origin,target,pattern,int(skill[0]))!=Vector2i.ZERO:best_score+=5
	if enemy_move_allowed(e,"secondary") and SECONDARY_SKILLS.has(species):
		var current_alt:Array=SECONDARY_SKILLS[species]
		if attack_aim(origin,target,str(current_alt[1]),int(current_alt[0]))!=Vector2i.ZERO:best_score+=3
	for d in DIR:
		var q:Vector2i=origin+d
		if not cells.has(q) or q==target or q==player or q==stairs or (q==relic and q!=home) or q in side_rewards or traps.has(q) or player_traps.has(q) or enemy_at(q)>=0 or ally_at(q)>=0 or distance(q,home)>4:continue
		if not enemy_line_of_sight(q,target):continue
		var score:int=-absi(distance(q,target)-preferred)*3
		if enemy_move_allowed(e,"primary") and attack_aim(q,target,pattern,int(skill[0]))!=Vector2i.ZERO:score+=5
		if enemy_move_allowed(e,"secondary") and SECONDARY_SKILLS.has(species):
			var alt:Array=SECONDARY_SKILLS[species]
			if attack_aim(q,target,str(alt[1]),int(alt[0]))!=Vector2i.ZERO:score+=3
		if score>best_score:best_score=score;best=q
	return best

func enemy_tick_all_cooldowns(e:Dictionary)->void:
	for key in ["cooldown","alt_cooldown","support_cooldown","control_cooldown"]:
		if int(e.get(key,0))>0:e[key]=int(e[key])-1

# A completed action consumes the reserve's waiting state. This also covers
# early dispatch branches (party attacks, control, retreat, evasion, etc.).
func enemy_clear_acted_frontline_holds()->void:
	var acted:Dictionary={}
	for action in enemy_actions:
		if str(action.get("phase","")) in ["move","attack"]:
			acted[int(action.get("uid",-1))]=true
	if acted.is_empty():return
	for e in enemies:
		if not acted.has(int(e.get("uid",-2))):continue
		e.erase("reserve_hold_turn");e.erase("reserve_hold_target")
		e.erase("congestion_hold_turn");e.erase("congestion_hold_target")
		e.erase("lane_hold_turn");e.erase("lane_hold_target")
		# Any subsequent ordinary move or attack supersedes staging evidence.
		if int(e.get("stage_turn",-9999))!=turns or e.get("stage_position",Vector2i(-9999,-9999))!=e.pos:
			e.erase("stage_turn");e.erase("stage_target");e.erase("stage_position")

func enemy_turn_actions():
	if ai_wait_audit_enabled or not ai_wait_audit.is_empty():ai_wait_audit.clear()
	if ai_recovery_trace_uid>=0:ai_recovery_trace.clear()
	enemy_phase_spent.clear()
	ai_begin_turn_cache()
	enemy_turn_actions_impl()
	enemy_phase_spent.clear()
	ai_end_turn_cache()
	enemy_clear_acted_frontline_holds()

func enemy_turn_actions_impl():
	enemy_actions.clear()
	turns+=1
	if not spend_belly():return
	if poison_turns>0:
		poison_turns-=1;hp=maxi(0,hp-1)
		if hp==0:
			finished=true;success=false;message="Poison · rescue needed";emit_event(message);return
	enemy_share_alerts(player)
	var previous_uid:int=-1
	for i in range(enemies.size()):
		if previous_uid>=0:enemy_phase_spent[previous_uid]=true
		previous_uid=int(enemies[i].get("uid",-1))
		ai_begin_actor_cache()
		if int(enemies[i].hp)<=0:continue
		var p:Vector2i=enemies[i].pos
		if enemies[i].has("reserve_hold_turn") or enemies[i].has("congestion_hold_turn") or enemies[i].has("lane_hold_turn") or enemies[i].has("stage_turn") or enemies[i].has("stage_target") or enemies[i].has("stage_position"):enemy_expire_frontline_holds(enemies[i])
		if int(enemies[i].get("slow_turns",0))>0 and int(enemies[i].slow_turns)%2==0:
			enemy_tick_all_cooldowns(enemies[i]);continue
		var major:String=str(enemies[i].get("major_status",""))
		if int(enemies[i].get("sleep_turns",0))>0 or int(enemies[i].get("nightmare_turns",0))>0 or int(enemies[i].get("paused_turns",0))>0 or int(enemies[i].get("wrapped_turns",0))>0 or int(enemies[i].get("infatuated_turns",0))>0 or major=="freeze":
			enemy_tick_all_cooldowns(enemies[i]);continue
		if int(enemies[i].get("confusion_turns",0))>0 or major=="paralysis":
			enemy_tick_all_cooldowns(enemies[i])
			var dir:Vector2i=DIR[rng.randi_range(0,DIR.size()-1)] if int(enemies[i].get("confusion_turns",0))>0 else Vector2i.ZERO
			var q:Vector2i=p+dir
			if major=="paralysis":
				var route_to_player:=route(p,player,true)
				if turns%2==0 and not route_to_player.is_empty():q=route_to_player[0]
				else:continue
			if cells.has(q) and q!=player and enemy_at(q)<0 and ally_at(q)<0 and int(enemies[i].get("stuck_turns",0))<=0:
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
		if not boon_active("decoy") and decoy_action(i):
			enemy_tick_all_cooldowns(enemies[i]);continue
		enemy_observe_movement(enemies[i],player)
		boss_observe_phase(enemies[i])
		var finish_priority:bool=enemy_opportunity_eligible(enemies[i]) and enemy_risk_has_finisher(enemies[i])
		# A credible immediate finish must precede optional party pursuit.
		if enemy_party_pursuit_allowed(enemies[i],finish_priority) and enemy_target_ally(i):continue
		var gap:=distance(p,player)
		var pursuit_target:Vector2i=enemy_pursuit_target(enemies[i],player)
		if not finish_priority and gap<=3 and not enemies[i].get("windup",false) and enemy_use_potion(i):
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"attack","from":p,"to":p,"move":"Healing berry","fx":"basic_strike","damage":0,"tiles":[p],"path":[p]})
			emit_event("Enemy recovered HP")
			enemy_tick_all_cooldowns(enemies[i]);continue
		# React to a visible telegraph before ordinary positioning; a successful
		# learned control or one safe movement consumes the entire enemy turn.
		if not finish_priority and enemy_visible_charge_threat(enemies[i]).has(p):
			if enemy_execute_control(i):
				if hp<=0:
					apply_fatal_grudge(enemies[i]);finished=true;success=false;message="Rescue needed · expedition lost";return
				continue
			var charge_evade:Vector2i=enemy_charge_evasion_step(enemies[i])
			if charge_evade!=p:
				enemies[i].pos=charge_evade
				enemy_tick_all_cooldowns(enemies[i])
				enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":charge_evade,"gait":enemies[i].get("gait","walk")})
				continue
		var survival_cap:int=int(enemies[i].get("max_hp",0))
		if survival_cap>0 and int(enemies[i].hp)*2>survival_cap:enemies[i].erase("retreat_steps")
		# Resolve lethal opportunities before optional positioning and support.
		var lure_step:Vector2i=p if finish_priority else enemy_lure_step(enemies[i],player)
		if lure_step!=p:
			enemies[i].pos=lure_step;enemies[i]["lure_turn"]=turns
			enemy_tick_all_cooldowns(enemies[i])
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":lure_step,"gait":enemies[i].get("gait","walk")})
			continue
		if not finish_priority and enemy_reinforcement_wait(enemies[i],player):
			enemies[i]["reinforcement_turn"]=turns
			enemy_tick_all_cooldowns(enemies[i])
			continue
		var risk_step:Vector2i=p if finish_priority else enemy_risk_step(enemies[i],player)
		if risk_step!=p:
			enemies[i].pos=risk_step;enemies[i]["risk_move_turn"]=turns
			enemy_tick_all_cooldowns(enemies[i])
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":risk_step,"gait":enemies[i].get("gait","walk")})
			continue
		var retreat:Vector2i=p if finish_priority else enemy_retreat_step(enemies[i],player)
		if retreat!=p:
			enemies[i].pos=retreat
			enemies[i]["retreat_steps"]=int(enemies[i].get("retreat_steps",0))+1
			for cd_key in ["support_cooldown","cooldown","alt_cooldown","control_cooldown"]:
				if int(enemies[i].get(cd_key,0))>0:enemies[i][cd_key]=int(enemies[i][cd_key])-1
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":retreat,"gait":enemies[i].get("gait","walk")})
			continue
		if gap>3 and gap<=enemy_awareness(enemies[i]) and enemy_line_of_sight(p,player):enemies[i].erase("spacing_count")
		var spacing:Vector2i=p if finish_priority else enemy_cautious_spacing_step(enemies[i],player)
		if spacing!=p:
			enemies[i].pos=spacing;enemies[i]["spacing_count"]=int(enemies[i].get("spacing_count",0))+1
			enemy_tick_all_cooldowns(enemies[i])
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":spacing,"gait":enemies[i].get("gait","walk")})
			continue
		var push_adapt:Vector2i=p if finish_priority else enemy_push_adaptation_step(enemies[i],player)
		if push_adapt!=p:
			enemies[i].pos=push_adapt;enemies[i]["push_adapt_turn"]=turns
			enemy_tick_all_cooldowns(enemies[i])
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":push_adapt,"gait":enemies[i].get("gait","walk")})
			continue
		var cover_step:Vector2i=p if finish_priority else enemy_counter_cover_step(enemies[i],player)
		if cover_step!=p:
			enemies[i].pos=cover_step;enemies[i]["counter_cover_turn"]=turns
			enemy_tick_all_cooldowns(enemies[i])
			enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":cover_step,"gait":enemies[i].get("gait","walk")})
			continue
		if enemy_counter_protected(enemies[i],player) and not enemy_has_party_area_attack(enemies[i]):
			var protected_step:Vector2i=enemy_counter_protected_step(enemies[i],player)
			if ai_recovery_trace_uid>=0:enemy_trace_recovery(enemies[i],"protect",protected_step)
			if ai_wait_audit_enabled and protected_step==p:ai_wait_audit[int(enemies[i].get("uid",-1))]={"turn":turns,"target":player,"reason":"protect","position":p}
			enemy_tick_all_cooldowns(enemies[i])
			if protected_step!=p:
				enemies[i].pos=protected_step
				enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":protected_step,"gait":enemies[i].get("gait","walk")})
			continue
		var basic_finish:bool=enemy_basic_finish(enemies[i])
		var control_cd:int=int(enemies[i].get("control_cooldown",0))
		if control_cd>0:enemies[i]["control_cooldown"]=control_cd-1
		if not finish_priority and control_cd<=0 and enemy_execute_control(i):
			if hp<=0:
				apply_fatal_grudge(enemies[i]);finished=true;success=false;message="Rescue needed · expedition lost";return
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
		var aim:Vector2i=enemies[i].get("aim",Vector2i.ZERO) if charged else enemy_area_aim(enemies[i],pattern,int(skill[0]))
		var footprint:Dictionary=attack_footprint(p,aim,pattern,int(skill[0])) if aim!=Vector2i.ZERO else {}
		var house_visible:bool=not bool(enemies[i].get("ecology_search_enabled",false)) or (gap<=enemy_awareness(enemies[i]) and enemy_line_of_sight(p,player))
		var in_range:bool=footprint.has(player) and (charged or house_visible)
		var alternate:bool=false
		var species:String=str(enemies[i].get("species",""))
		var alt_cooldown:int=int(enemies[i].get("alt_cooldown",0))
		if alt_cooldown>0:enemies[i]["alt_cooldown"]=alt_cooldown-1
		if not charged and (not ready or not in_range or bool(enemies[i].get("ecology_search_enabled",false))) and alt_cooldown<=0 and SECONDARY_SKILLS.has(species) and enemy_move_allowed(enemies[i],"secondary"):
			var alt:Array=SECONDARY_SKILLS[species]
			var alt_aim:=enemy_area_aim(enemies[i],str(alt[1]),int(alt[0]))
			var alt_skill:Array=[alt[0],false,3,alt[3],alt[4],alt[5],"alt_"+species]
			var prefer_alt:bool=not ready or not in_range or enemy_attack_score(enemies[i],alt_skill,true)+enemy_area_bonus(enemies[i],str(alt[1]),int(alt[0]),alt_aim)+boss_attack_preference(enemies[i],true)>enemy_attack_score(enemies[i],skill,false)+enemy_area_bonus(enemies[i],pattern,int(skill[0]),aim)+boss_attack_preference(enemies[i],false)+.25
			if finish_priority and not basic_finish:
				var primary_lethal:bool=ready and in_range and not bool(skill[1]) and enemy_opportunity_damage(enemies[i],skill,false)>=hp
				var secondary_lethal:bool=alt_aim!=Vector2i.ZERO and enemy_opportunity_damage(enemies[i],alt_skill,true)>=hp
				if primary_lethal!=secondary_lethal:prefer_alt=secondary_lethal
			if alt_aim!=Vector2i.ZERO and prefer_alt and house_visible:
				alternate=true;aim=alt_aim;pattern=str(alt[1])
				footprint=attack_footprint(p,aim,pattern,int(alt[0]))
				in_range=true;ready=true
				skill=alt_skill
		if basic_finish:
			ready=false;in_range=false;alternate=false
		var support_kind:String=str(ENEMY_SUPPORT.get(enemies[i].get("species",""),""))
		if not basic_finish and not charged and not (ready and in_range) and support_cd<=0 and gap<=2 and not enemies[i].get("windup",false) and not support_kind.is_empty() and enemy_move_allowed(enemies[i],"support"):
			var use_support:bool=(support_kind=="guard" and int(enemies[i].get("stages",{}).get("defense",0))<2) or (support_kind=="drowse" and not boon_active("hostile_drowse") and not boon_active("hostile_sleep") and not boon_active("hostile_paralysis") and self_confusion_turns<=0 and not boon_active("hostile_control_recovery") and not boon_active("sleepless") and not player_has_ability("wakeful") and not (shield_turns>0 and shield_kind in ["protect","safeguard"]) and not boon_active("magic_coat") and enemy_line_of_sight(p,player))
			if use_support and execute_enemy_support(i,support_kind):
				enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"attack","from":p,"to":p if support_kind=="guard" else player,"move":"Ward" if support_kind=="guard" else "Drowsy Hex","fx":"basic_strike","damage":0,"tiles":[p if support_kind=="guard" else player],"path":[p if support_kind=="guard" else player]})
				continue
		if not charged and bool(enemies[i].get("boss_tactical",false)) and (not (ready and in_range) or (shield_turns>0 and shield_kind=="protect")):
			var boss_step:Vector2i=boss_reposition_step(enemies[i],player)
			if boss_step!=p:
				enemies[i].pos=boss_step
				enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":boss_step,"gait":enemies[i].get("gait","walk")})
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
		if (ready and in_range) or (gap==1 and not (ready and in_range)):
			enemies[i].windup=false
			var special:bool=ready and in_range
			var protected_charge:bool=charge_phase in ["underground","airborne","vanish"]
			var hit_base:Dictionary=enemy_player_damage_base(enemies[i],skill,alternate,not special,0 if protected_charge else marked_damage)
			if marked_damage>0 and not protected_charge:marked_damage=0
			var damage:int=int(hit_base.damage)
			last_type_multiplier=float(hit_base.effectiveness)
			var category:String=str(hit_base.category)
			var enemy_element:String=str(hit_base.element)
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
				enemy_remember_result(enemies[i],-1,"secondary" if alternate else "primary",last_type_multiplier,dodged,shield_block)
				record_enemy_move(enemies[i],"secondary" if alternate else "primary")
				if alternate:enemies[i]["alt_cooldown"]=maxi(0,int(skill[2])-1)
				else:enemies[i]["cooldown"]=maxi(0,int(skill[2])-1)
				if not dodged and not shield_block:
					ai_end_actor_cache()
					apply_signature_effect(i,skill)
			if dodged or shield_block or (shield_kind=="safeguard" and shield_turns>0 and effect in ["poison","weaken","mark"]) or (boon_active("mist") and effect=="weaken"):effect="none"
			var party_hits:Array[Dictionary]=[]
			if special:party_hits=enemy_apply_area_damage(enemies[i],p,footprint,pattern,skill,alternate)
			if damage>0:enemy_record_squad_focus(enemies[i],-1,damage)
			else:
				for hit in party_hits:
					if int(hit.damage)>0:
						enemy_record_squad_focus(enemies[i],int(hit.uid),int(hit.damage));break
			enemy_actions.append({"party_hits":party_hits,"uid":enemies[i].get("uid",i),"phase":"attack","from":p,"to":player,"end":enemies[i].pos,"move":move_name,"fx":skill[6] if special else "basic_strike","effect":effect,"damage":damage,"dodged":dodged,"effectiveness":last_type_multiplier,"aim":aim if special else player-p,"pattern":pattern if special else "front","tiles":footprint.keys() if special else [player],"path":footprint.get(player,[player]) if special else [player]})
			message="%s · %s! −%d HP"%[enemies[i].get("name","Enemy"),move_name,damage]
			if last_enemy_critical:message+=" · Critical!"
			if reflected:message+=" · Reflected!"
			elif shield_block:message+=" · Protected!"
			elif dodged:message+=" · Dodged!"
			elif last_type_multiplier>1.01:message+=" · Effective!"
			elif last_type_multiplier<.99:message+=" · Resisted"
			if effect!="none":message+=" · "+effect.capitalize()
			if not party_hits.is_empty():message+=" · %d party targets"%party_hits.size()
			emit_event(message)
			if hp==0:
				apply_fatal_grudge(enemies[i])
				finished=true;success=false;message="Rescue needed · expedition lost";return
		elif pursuit_target!=p and kind!=3 and int(enemies[i].get("stuck_turns",0))<=0:
			var path:Array[Vector2i]=[]
			var tactical:Vector2i=enemy_protector_step(enemies[i],pursuit_target) if not charged and pursuit_target==player else p
			if tactical==p and not charged and pursuit_target==player:
				tactical=enemy_control_setup_step(enemies[i],player)
			# A concrete witnessed opening takes priority over speculative positioning.
			var recovery_mode:String=""
			if tactical==p and not charged and pursuit_target==player:
				tactical=enemy_witnessed_vacancy_step(enemies[i],player)
				if tactical!=p:recovery_mode="immediate"
			var reserve_plan:Dictionary={}
			if tactical==p and not charged and pursuit_target==player:
				reserve_plan=enemy_dynamic_reserve_plan(enemies[i],player)
				tactical=reserve_plan.get("step",p)
			if tactical==p and not charged and pursuit_target==player:
				tactical=enemy_relief_step(enemies[i],player)
			if tactical==p and not charged and pursuit_target==player:
				tactical=house_formation_step(enemies[i],player)
			var predictive_move:bool=false
			if tactical==p and not charged and pursuit_target==player:
				tactical=enemy_adaptive_intercept_step(enemies[i],player)
				if tactical==p:tactical=enemy_predictive_cutoff_step(enemies[i],player)
				predictive_move=tactical!=p
			if tactical==p and not charged and pursuit_target==player:
				tactical=enemy_counterplay_escape_step(enemies[i],player)
			if tactical==p and not charged and pursuit_target==player:
				tactical=enemy_exit_block_step(enemies[i],player)
			var environment_guard:bool=false
			if tactical==p and not charged and pursuit_target==player:
				tactical=enemy_environment_guard_step(enemies[i],player)
				environment_guard=tactical!=p
			if tactical==p and not charged and pursuit_target==player:
				tactical=enemy_decision_position_plan(enemies[i],player).get("step",p)
			if tactical==p and ready and not charged and not in_range and pursuit_target==player:
				tactical=enemy_tactical_step(enemies[i],pursuit_target,pattern,int(skill[0]))
			if tactical==p and not charged and pursuit_target==player:
				if ready:
					tactical=enemy_cooperative_step(enemies[i],pursuit_target,pattern,int(skill[0]))
				if tactical==p and alt_cooldown<=0 and SECONDARY_SKILLS.has(species) and enemy_move_allowed(enemies[i],"secondary"):
					var flank_alt:Array=SECONDARY_SKILLS[species]
					tactical=enemy_cooperative_step(enemies[i],pursuit_target,str(flank_alt[1]),int(flank_alt[0]))
			var pack_plan:Dictionary={}
			if tactical==p and not charged and pursuit_target==player:
				pack_plan=enemy_pack_intercept_plan(enemies[i],player)
				tactical=pack_plan.get("step",p)
			if tactical==p and not charged and pursuit_target==player:
				tactical=enemy_foresight_plan(enemies[i],player).get("step",p)
			var intentional_hold:bool=false
			if tactical!=p:path.append(tactical)
			else:
				path=enemy_approach_route(p,pursuit_target) if enemies[i].has("ecology_role") else route(p,pursuit_target,true)
				if not path.is_empty() and enemy_crowd_hold(enemies[i],path[0],pursuit_target):
					path.clear();intentional_hold=true
				elif not charged and pursuit_target==player:
					var heading:Vector2i=Vector2i(signi(player.x-p.x),signi(player.y-p.y))
					if path.is_empty() or path[0]==p+heading or distance(path[0],player)>=distance(p,player):
						var yield_tile:Vector2i=enemy_crowd_yield_step(enemies[i],player)
						if yield_tile!=p:
							enemies[i]["crowd_previous"]=p;enemies[i]["crowd_turn"]=turns
							enemies[i]["crowd_target"]=player;enemies[i]["crowd_partner"]=p-heading
							path.clear();path.append(yield_tile)
			if path.is_empty() and not charged and not intentional_hold and pursuit_target==player:
				var recovery:Vector2i=enemy_immediate_recovery_step(enemies[i],player)
				recovery_mode="immediate"
				if recovery==p:
					recovery=enemy_unstall_step(enemies[i],player,false);recovery_mode="detour"
				if recovery==p:
					recovery=enemy_unstall_party_step(enemies[i],player);recovery_mode="party"
				if recovery==p:
					recovery=enemy_firing_lane_stage_step(enemies[i],player);recovery_mode="stage"
				if ai_recovery_trace_uid>=0:enemy_trace_recovery(enemies[i],recovery_mode if recovery!=p else "no_recovery",recovery)
				if recovery!=p:
					path.append(recovery)
				else:
					enemy_record_stall(enemies[i],player)
					if ai_wait_audit_enabled:enemy_audit_frontline_wait(enemies[i],player)
					# A verified closed frontline is actionable evidence on the first
					# failed pursuit. Only speculative detours need repeated stalls.
					if int(enemies[i].get("stall_turn",-1))==turns and enemy_encircled_frontline(enemies[i],player):
						enemies[i]["reserve_hold_turn"]=turns
						enemies[i]["reserve_hold_target"]=player
						enemies[i].erase("congestion_hold_turn");enemies[i].erase("congestion_hold_target")
						enemies[i].erase("lane_hold_turn");enemies[i].erase("lane_hold_target")
					elif int(enemies[i].get("stall_turn",-1))==turns and enemy_occupied_frontline(enemies[i],player):
						enemies[i]["congestion_hold_turn"]=turns
						enemies[i]["congestion_hold_target"]=player
						enemies[i].erase("reserve_hold_turn");enemies[i].erase("reserve_hold_target")
						enemies[i].erase("lane_hold_turn");enemies[i].erase("lane_hold_target")
					elif int(enemies[i].get("stall_turn",-1))==turns and enemy_firing_lane_frontline(enemies[i],player):
						enemies[i]["lane_hold_turn"]=turns;enemies[i]["lane_hold_target"]=player
						enemies[i].erase("reserve_hold_turn");enemies[i].erase("reserve_hold_target")
						enemies[i].erase("congestion_hold_turn");enemies[i].erase("congestion_hold_target")
			if not path.is_empty() and not charged and pursuit_target==player and int(enemies[i].get("crowd_turn",-9999))<turns-1:
				var strategy_step:Vector2i=enemy_strategy_alternative(enemies[i],path[0],player)
				if strategy_step!=path[0]:
					path.clear();path.append(strategy_step)
					predictive_move=false;environment_guard=false;pack_plan.clear();reserve_plan.clear();recovery_mode=""
			if not path.is_empty() and path[0]!=player and enemy_at(path[0])<0:
				var steps:int=1+int(enemies[i].get("haste_stage",0)) if int(enemies[i].get("haste_turns",0))>0 else 1
				var destination:Vector2i=p
				for step in range(mini(steps,path.size())):
					if path[step]==player or enemy_at(path[step])>=0 or ally_at(path[step])>=0:break
					destination=path[step]
				if destination!=p:
					if not recovery_mode.is_empty():enemy_commit_recovery(enemies[i],p,destination,recovery_mode)
					if predictive_move:enemy_record_prediction(enemies[i],player)
					if environment_guard:enemies[i]["environment_guard_turn"]=turns
					if not pack_plan.is_empty():enemy_pack_commit(enemies[i],player,pack_plan.post)
					if not reserve_plan.is_empty():enemy_pack_commit(enemies[i],player,reserve_plan.post)
					if not charged:enemy_strategy_record_step(enemies[i],p,destination,pursuit_target)
					enemies[i].erase("reserve_hold_turn");enemies[i].erase("reserve_hold_target")
					enemies[i].erase("congestion_hold_turn");enemies[i].erase("congestion_hold_target")
					enemies[i].erase("lane_hold_turn");enemies[i].erase("lane_hold_target")
					enemies[i].pos=destination
					enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":destination,"gait":enemies[i].get("gait","walk")})
		elif not charged and kind!=3 and not boon_active("decoy"):
			var patrol:Vector2i=enemy_ambush_step(enemies[i])
			if patrol==p and not enemies[i].has("ambush_post"):
				patrol=enemy_territorial_idle_step(enemies[i])
				if patrol==p:patrol=enemy_patrol_destination(enemies[i])
			if patrol!=p:
				enemies[i].pos=patrol
				enemy_actions.append({"uid":enemies[i].get("uid",i),"phase":"move","from":p,"to":patrol,"gait":enemies[i].get("gait","walk")})
	ai_end_actor_cache()
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
		adaptive_walk_from=player;adaptive_walk_to=p;adaptive_walk_turn=turns
		player=p;pickup()
		trigger_floor_trap(player)
	if i>=0:enemy_turn()
	else:finish_walk_turn()
	return true
func attack(power:bool=false,aim:Vector2i=Vector2i.ZERO,style_override:int=-1)->bool:
	if player_wait_if_napping():return true
	if not charged_move_id.is_empty():
		if power:return release_charge()
		message="Release the charged move first";return false
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
	last_move_hits=0;last_move_attempts=0
	player_cast_results.clear();player_cast_result_serial=-1
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
		message=str(move.name)+" · No valid invocation";emit_event(message);seal_special_cast();enemy_turn();return true
	if str(move.get("special_rule","")) in ["leader_decoy","party_boost","party_rally","party_heal","party_renew"]:
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move):last_move_hits=party_support(str(move.special_rule))
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		for a in allies:
			if int(a.hp)>0 and same_party_room(a.pos):player_attack_cells.append(a.pos)
		message=str(move.name)+" · "+("%d affected"%last_move_hits if last_move_hits>0 else "No target")
		emit_event(message);seal_special_cast();enemy_turn();return true
	if str(move.get("special_rule","")) in ["transform_form","relay_swap"]:
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		var origin:Vector2i=player
		if move.special_rule=="relay_swap":last_move_hits=relay_swap(move)
		elif roll_reference_hit(move) and transform_form():last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[origin,player]
		message=str(move.name)+" · "+("Active" if last_move_hits>0 else "Failed");emit_event(message);seal_special_cast();enemy_turn();return true
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
		message=str(move.name)+" · "+detail;emit_event(message);seal_special_cast();enemy_turn();return true
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
		emit_event(message);seal_special_cast();enemy_turn();return true
	if str(move.get("special_rule",""))=="tempo_rift":
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move) and tempo_rift():last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · Movement shifted";emit_event(message);seal_special_cast();enemy_turn();return true
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
		emit_event(message);seal_special_cast();enemy_turn();return true
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
		message=str(move.name);emit_event(message);seal_special_cast()
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
		emit_event(message);seal_special_cast();enemy_turn();return true
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
			if current>=0:
				var damage_index:int=last_move_damage.size()
				var critical_before:int=last_critical_hits
				var landed:bool=roll_reference_hit(move,enemies[current])
				if landed:
					strike(current,true,-1,id);last_move_hits+=1;last=target;hit_cells.append(target)
				var dealt:int=0
				for amount in last_move_damage.slice(damage_index):dealt+=int(amount)
				record_cast_result(target,dealt,landed,false,last_critical_hits>critical_before)
		self_confusion_turns=rng.randi_range(7,12)
		attack_serial+=1;attack_target=last;attack_power=true;player_attack_fx=id
		player_attack_cells=hit_cells;player_attack_path=hit_cells.duplicate()
		message=str(move.name)+" · %d/3 hits · Confused"%last_move_hits
		emit_event(message);seal_special_cast();enemy_turn();return true
	if move.has("reserve_action"):
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move):
			if move.reserve_action=="store":last_move_hits=1 if store_vitality() else 0
			elif stockpile_count>0:last_move_healed=consume_vitality();last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+("Stored %d/3"%stockpile_count if move.reserve_action=="store" else "+%d HP"%last_move_healed)
		emit_event(message);seal_special_cast();enemy_turn();return true
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
		message=str(move.name)+" · No valid invocation";emit_event(message);seal_special_cast();enemy_turn();return true
	if move.has("stat_transfer") and move.pattern=="self":
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move) and transfer_stats(str(move.stat_transfer)):last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+stage_summary(player_stages,player_halves)
		emit_event(message);seal_special_cast();enemy_turn();return true
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
		if move.has("trap_kind"):last_move_hits=1 if applied else 0;last_move_attempts=1
		emit_event(message);seal_special_cast()
		if finished:turns+=1;enemy_actions.clear();return true
		enemy_turn();return true
	if str(move.get("special_rule",""))=="warp":
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=1 if warp_player() else 0
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+("Warped" if last_move_hits>0 else "No destination")
		emit_event(message);seal_special_cast();enemy_turn();return true
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
		emit_event(message);seal_special_cast();enemy_turn();return true
	if move.has("boon_kind"):
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move) and apply_player_boon(move):
			last_move_hits=1
			if move.boon_kind=="bide":bide_aim=aim;bide_move_id=id
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+("Active" if last_move_hits>0 else "No effect")
		emit_event(message);seal_special_cast();enemy_turn();return true
	if move.has("shield_kind"):
		move_pp[pp_id]=int(move_pp[pp_id])-1
		last_move_attempts=1;last_move_hits=0
		if roll_reference_hit(move) and activate_shield(move):last_move_hits=1
		attack_serial+=1;attack_target=player;attack_power=false;player_attack_fx=id
		player_attack_cells=[player];player_attack_path=[player]
		message=str(move.name)+" · "+(shield_kind.capitalize() if last_move_hits>0 else "Failed")
		emit_event(message);seal_special_cast();enemy_turn();return true
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
			enemy_actions.clear();travel_steps_used=0;travel_refresh=true;emit_event(message);seal_special_cast();return true
		emit_event(message);seal_special_cast();enemy_turn();return true
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
		emit_event("+%d HP"%last_move_healed);seal_special_cast()
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
			var hits_before:int=last_move_hits
			var critical_before:int=last_critical_hits
			var status_before:String=enemy_status_text(enemies[current])
			var landed:bool=roll_reference_hit(move,enemies[current])
			if landed:
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
			var dealt_total:int=0
			for amount in last_move_damage.slice(damage_start):
				dealt_total+=int(amount)
				if int(amount)>0 and visual_uid>=0:player_visual_hits[visual_uid]=int(player_visual_hits.get(visual_uid,0))+1
			var changed:bool=last_move_hits>hits_before and (move.category=="status" or move.has("special_rule") and last_move_damage.size()==damage_start)
			var remaining:int=enemy_at(target)
			var status_after:String=enemy_status_text(enemies[remaining]) if remaining>=0 else ""
			if landed and not status_after.is_empty() and status_after!=status_before:
				changed=true
			record_cast_result(target,dealt_total,landed,changed,last_critical_hits>critical_before)
			if landed and changed and not status_after.is_empty() and status_after!=status_before:
				player_cast_results[target]["status"]=status_after
				# Preserve the status delta on the attempt that actually caused it.
				var before_tags:PackedStringArray=status_before.split(" · ",false)
				var new_tags:PackedStringArray=[]
				for tag in status_after.split(" · ",false):
					if not before_tags.has(tag):new_tags.append(tag)
				var attempts:Array=player_cast_results[target]["attempts"]
				attempts[-1]["status"]=" · ".join(new_tags)
				attempts[-1]["status_changed"]=true
			if not landed and move.get("stop_on_miss",false):break
	if last_move_hits==0 or move.category=="status" or move.has("special_rule"):attack_serial+=1
	attack_target=primary;player_attack_fx=id;player_attack_path=travel
	player_attack_cells=hit_tiles
	player_visual_hit_serial=attack_serial;player_cast_result_serial=attack_serial
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
	if last_move_healed>0:
		record_cast_heal(player,last_move_healed)
		message+=" · +%d HP"%last_move_healed;emit_event("+%d HP"%last_move_healed)
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
const DEV_RULE_DESCRIPTIONS={"20":"Deals 20 fixed damage.","30":"Deals 30 fixed damage.","35":"Deals 35 fixed damage.","half_hp":"Deals half of the target's current HP.","equal_hp":"Reduces the target toward the user's current HP.","psywave":"Deals variable level-based psychic damage.","level":"Deals damage based on the user's level.","ohko":"Attempts to defeat the target in one hit.","push":"Pushes the target away.","warp":"Warps the user to another tile.","pain_split":"Shares current HP between user and target, capped by maximum HP.","magnitude":"Deals variable ground damage based on a randomly selected magnitude.","shift":"Transfers negative conditions between combatants.","present":"Randomly damages or heals the target.","wrap":"Binds the target and user in place.","splash":"Moves the user to a random nearby tile.","break_wall":"Opens a wall tile immediately ahead.","hurl":"Throws the target across the room.","iq_return":"Deals fixed damage that increases with IQ.","iq_frustration":"Deals fixed damage that decreases with IQ.","nature_power":"Invokes an attack based on the terrain.","infatuation":"Infatuates an eligible opposite-gender target.","captivate":"Lowers an opposite-gender target's Special Attack.","destiny_link":"Links incoming damage to the target.","encore":"Locks the target into its last used move.","torment":"Seals the target's last used move.","spite":"Drains the target's last used move PP.","taunt":"Prevents non-damaging support moves.","tempo_rift":"Randomly alters travel speed stages.","swap_item":"Exchanges held items with the target.","drop_item":"Drops the target's held item.","embargo":"Blocks the target's consumable items.","swap_ability":"Exchanges abilities with the target.","copy_ability":"Copies the target's abilities.","suppress_ability":"Temporarily suppresses target abilities.","copy_last":"Invokes the target's last eligible move.","learn_last":"Replaces this move with the target's last eligible move.","copy_boost":"Uses an eligible target attack at increased power.","belly_drum":"Maximizes Attack at the cost of hunger.","recycle_manual":"Restores spent technique manuals.","transform_form":"Copies a hostile creature's visual form.","decoy":"Makes the target a decoy for other enemies.","relay_swap":"Swaps positions with enemies in the room.","leader_decoy":"Makes the leader a decoy.","party_boost":"Raises allies' Attack and Special Attack.","floor_assist":"Invokes an eligible move from the floor's creatures.","party_rally":"Rallies living allies near the leader.","party_heal":"Heals allies in the room at the cost of the user's HP.","party_renew":"Heals allies and restores their PP at the cost of the user's HP."}
const DEV_BOON_DESCRIPTIONS={"focus":"Increases critical-hit potential.","lucky":"Protects against critical hits.","mist":"Protects against stat reductions.","wish":"Gradually restores HP.","cure":"Clears the user's negative conditions.","aqua":"Periodically restores HP.","sure":"Makes attacks bypass accuracy checks while active.","nap":"Sleeps, then restores HP and clears conditions.","ingrain":"Roots the user and periodically restores HP.","set_damage":"Sets ordinary attack damage to a fixed amount.","sleepless":"Prevents sleep.","magnet":"Grants temporary immunity to ground attacks.","bide":"Stores incoming damage and releases a retaliatory hit.","rage":"Raises Attack when damaged.","vital_throw":"Retaliates against nearby attackers with a throw.","adapt":"Changes defensive type after being hit.","magic_coat":"Reflects supported status effects.","snatch":"Steals supported enemy buffs.","mirror_veil":"Reflects adjacent non-basic attacks.","grudge":"Drains the last enemy move PP on a fatal hit."}
const DEV_SHIELD_DESCRIPTIONS={"protect":"Blocks incoming attacks temporarily.","endure":"Prevents an otherwise fatal hit from reducing HP below one.","counter":"Retaliates against adjacent physical attackers.","mirror":"Retaliates against adjacent special attackers.","reflect":"Reduces physical damage.","screen":"Reduces special damage.","metal":"Reflects part of incoming damage to nearby enemies.","safeguard":"Protects against supported negative conditions."}
const DEV_TRANSFER_DESCRIPTIONS={"copy":"Copies the target's stat changes.","guard":"Exchanges defensive stat changes.","all":"Exchanges stat changes with the target.","power":"Exchanges offensive stat changes.","invert":"Swaps Attack and Defense changes.","random":"Randomly raises a combat stat.","charge":"Raises Special Defense and boosts the next electric attack.","gravity":"Activates gravity on the floor.","conversion":"Adopts an element from an equipped move.","camouflage":"Adopts a type based on the terrain."}
const DEV_TARGET_DESCRIPTIONS={"self":"User","front":"One enemy directly ahead","corner_front":"Enemy in front; can cut corners","line":"First enemy along the aimed line","fan":"Enemies in the forward spread","corner":"Enemies in the forward corner spread","radius":"Enemies around the user","cross":"Enemies along the cross","room":"Targets in the room","floor":"Targets on the floor"}

static func dev_move_description(m:Dictionary)->String:
	var parts:Array[String]=[]
	if m.has("description"):parts.append(str(m.description))
	if m.has("special_rule"):parts.append(str(DEV_RULE_DESCRIPTIONS.get(str(m.special_rule),"Executes "+str(m.special_rule).replace("_"," ")+".")))
	if m.has("boon_kind"):parts.append(str(DEV_BOON_DESCRIPTIONS.get(str(m.boon_kind),"Applies "+str(m.boon_kind)+".")))
	if m.has("shield_kind"):parts.append(str(DEV_SHIELD_DESCRIPTIONS.get(str(m.shield_kind),"Grants a defensive ward.")))
	if m.has("stat_transfer"):parts.append(str(DEV_TRANSFER_DESCRIPTIONS.get(str(m.stat_transfer),"Changes combat stats.")))
	if parts.is_empty() and int(m.power)>0:parts.append("Deals "+str(m.category)+" "+str(m.type)+" damage.")
	if m.has("heal_fraction"):parts.append("Restores "+str(roundi(float(m.heal_fraction)*100.0))+"% maximum HP.")
	if m.has("heal_fixed"):parts.append("Restores "+str(m.heal_fixed)+" HP.")
	if m.get("weather_heal",false):parts.append("Healing depends on current weather.")
	if m.has("inflict_status"):parts.append("Applies "+str(m.inflict_status).replace("_"," ")+" (chance "+str(m.get("status_chance",100))+"% after a hit).")
	if m.has("stat_changes"):
		for stat in m.stat_changes:
			var amount:int=int(m.stat_changes[stat])
			if amount!=0:parts.append(("Raises " if amount>0 else "Lowers ")+str(stat).replace("_"," ")+" by "+str(absi(amount))+" stage(s).")
	if m.has("stat_halves"):
		for stat in m.stat_halves:
			if m.stat_halves[stat]:parts.append("Halves "+str(stat).replace("_"," ")+".")
	if m.has("speed_change"):parts.append("Changes travel speed by "+str(m.speed_change)+" stage(s).")
	if m.get("reset_room_stats",false):parts.append("Resets room stat changes.")
	if m.has("weather_set"):parts.append("Changes floor weather to "+str(m.weather_set)+".")
	if m.has("floor_sport"):parts.append("Applies a floor-wide "+str(m.floor_sport).replace("_"," ")+" field effect.")
	if m.has("trap_kind"):parts.append("Places a "+str(m.trap_kind).replace("_"," ")+" trap.")
	if m.has("blast_radius"):parts.append("Explodes across "+str(m.blast_radius)+" tiles.")
	if m.has("reserve_action"):parts.append("Stores energy." if m.reserve_action=="store" else "Consumes stored energy to heal.")
	if m.get("reserve_attack",false):parts.append("Consumes stored energy to multiply damage.")
	if m.get("random_cast",false):parts.append("Invokes a random eligible move.")
	if m.has("hit_min"):parts.append("Strikes "+str(m.hit_min)+"–"+str(m.hit_max)+" times.")
	if m.has("drain_fraction"):parts.append("Restores "+str(roundi(float(m.drain_fraction)*100.0))+"% of damage dealt as HP.")
	if m.has("recoil_fraction"):parts.append("Costs "+str(roundi(float(m.recoil_fraction)*100.0))+"% maximum HP on a successful hit.")
	if m.has("charge_phase"):parts.append("Charges on turn one; releases on turn two.")
	if m.get("sleep_reactive",false):parts.append("Triggers when attacked while asleep.")
	if m.get("self_confuse",false):parts.append("Confuses the user afterward.")
	if m.get("hidden_power",false):parts.append("Power and type depend on the user's profile.")
	if m.get("curse_action",false):parts.append("Effect depends on the user's type.")
	if m.get("defog",false):parts.append("Clears fog and supported enemy wards.")
	if m.get("memento",false):parts.append("Reduces the user to one HP and warps them after a successful effect.")
	if m.get("roost",false):parts.append("Temporarily removes flying-type protection.")
	if m.get("pp_scaling",false):parts.append("Damage depends on remaining PP.")
	if m.get("rampage_random",false):parts.append("Uses a rampage attack pattern.")
	if m.get("pierce_guard",false):parts.append("Bypasses the target's guard.")
	if m.get("charge_defense",false):parts.append("Raises defense during charge.")
	if parts.is_empty():parts.append("Applies a non-damaging combat effect; individual rule review required.")
	return " ".join(parts)

static func dev_move_record(id:String)->Dictionary:
	if not DEV_NATIVE_MOVES.has(id) and not MOVE_LIBRARY.has(id):return {}
	var m:Dictionary=DEV_NATIVE_MOVES[id].duplicate(true) if DEV_NATIVE_MOVES.has(id) else MOVE_LIBRARY[id].duplicate(true)
	m["acc1"]=int(m.get("acc1",125));m["acc2"]=int(m.get("acc2",125))
	m["reference_crit"]=int(m.get("reference_crit",8))
	m["reference_strikes"]=m.get("reference_strikes",m.get("hit_max",1))
	m["what_it_does"]=dev_move_description(m)
	m["target_rule"]=str(DEV_TARGET_DESCRIPTIONS.get(str(m.pattern),str(m.pattern).replace("_"," ")))
	m["condition_text"]="None beyond target and accuracy checks."
	if m.has("charge_phase"):m.condition_text="Two-turn charge: "+str(m.charge_phase)+"."
	if m.get("sleep_reactive",false):m.condition_text="User asleep and struck by an enemy."
	if m.get("reserve_attack",false) or m.get("reserve_action","")=="heal":m.condition_text="Requires stored energy."
	if m.get("boon_kind","")=="bide":m.condition_text="Requires incoming damage before retaliation."
	if str(m.get("special_rule","")) in ["party_boost","party_rally","party_heal","party_renew"]:m.condition_text="Requires living allies."
	if str(m.get("special_rule","")) in ["copy_last","learn_last","encore","torment","spite"]:m.condition_text="Target must have used an eligible move."
	if str(m.get("special_rule","")) in ["swap_item","drop_item"]:m.condition_text="Requires held item(s)."
	if str(m.get("special_rule",""))=="break_wall":m.condition_text="Requires a wall directly ahead."
	if str(m.get("special_rule","")) in ["infatuation","captivate"]:m.condition_text="Requires an eligible opposite-gender target."
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
	player_visual_hits.clear();player_cast_results.clear();player_cast_result_serial=-1
	var origin:Vector2i=player
	for target in targets:
		var index:int=enemy_at(target)
		if index<0:continue
		last_move_attempts+=1
		var uid:int=int(enemies[index].get("uid",-1))
		if not roll_reference_hit(m,enemies[index]):
			record_cast_result(target,0,false,false,false);continue
		var before:int=last_move_damage.size()
		var critical_before:int=last_critical_hits
		strike(index,true,-1,id,1.0,m)
		last_move_hits+=1
		var dealt_total:int=0
		for amount in last_move_damage.slice(before):
			dealt_total+=int(amount)
			if int(amount)>0 and uid>=0:player_visual_hits[uid]=int(player_visual_hits.get(uid,0))+1
		record_cast_result(target,dealt_total,true,false,last_critical_hits>critical_before)
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
	player_visual_hit_serial=attack_serial;player_cast_result_serial=attack_serial
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
	potions-=1;hp=mini(max_hp,hp+20);message="Recovered HP";emit_event(message);visual_interaction("eat",player);enemy_turn();return true
func descend()->bool:
	if player_wait_if_napping():return true
	if not charged_move_id.is_empty():return release_charge()
	if finished or player!=stairs or not stairs_available():return false
	floor_bonus=exploration_coin_bonus();coins+=floor_bonus;total_bonus+=floor_bonus
	last_completed_floor_bonus=floor_bonus
	last_completed_floor_material=exploration_material_bonus();materials+=last_completed_floor_material
	if floor_number>=floor_count and not dev_sandbox:
		finished=true;success=true;message="Expedition complete!";return true
	floor_number+=1;hp=mini(max_hp,hp+10);generate_floor();return true
