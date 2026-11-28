# Kindria 2027 | Mystery Dungeon master roadmap
Scope: Explorers of Sky/Darkness gameplay, Rescue Team DX visual reference, original Godot/Blender implementation. Portrait only. No copied ROM assets, names in reference inventory are research labels, not production branding.
Status legend: [x] source reviewed or existing implementation explicitly identified (not a passed test); [ ] implementation or verification pending. Work one map at a time. First: Whisperwood / Enchanted Woods.

## Evidence and workflow
- [x] Public sources: https://github.com/morluto/rea (REA methodology), https://github.com/pret/pmd-sky, https://github.com/UsernameFodder/pmdsky-debug, https://github.com/SkyTemple/skytemple, https://github.com/tech-ticks/DreamNexus
- [x] https://bulbapedia.bulbagarden.net/wiki/Mystery_dungeons ; https://www.serebii.net/dungeonrescueteamdx/dungeon/ ; https://bulbapedia.bulbagarden.net/wiki/Template:PMD2_locations ; https://mysterydungeonwiki.com/wiki/Rescue_Team_DX:Tiny_Woods
- [ ] REA local provider setup on authorized game copy; record source version, evidence, confidence, independent design and test per feature. No ROM available in current session; no claim of binary extraction.
- [ ] Audit licenses before reuse; clean original code and art. No third-party Pokémon assets in shipping game.
- [ ] Every task: evidence -> original spec -> implementation -> deterministic tests -> Blender export audit -> actual Godot render -> Android touch/FPS/thermal capture -> acceptance. Do not mark complete from source-only checks.


## Community evidence (2026-11-27)
See [COMMUNITY_INTELLIGENCE.md](COMMUNITY_INTELLIGENCE.md) for the audit of all 11 core releases and 35 public sources, including surveys, community critiques, disagreements and acceptance gates F001–F010. This is qualitative evidence, not representative polling.
- [ ] P0: preserve manual zero-PP Strike, optional assistance, persistent companion and saved team selection; avoid forced autoplay and arbitrary party locks.
- [ ] P0: make floors feel different through landmarks, objectives, terrain and enemy behavior; no padding through mandatory repeated missions.
- [ ] P0: adjustable dialogue speed, skip seen dialogue, fast retry, clear controls and meaningful early rewards.
- [ ] P1: visitable habitats, mission batching, transparent recruitment and difficulty options; keep original story and soundtrack central.
- [ ] Playtest first dungeon with consenting players before promotion to Dungeon 002; record qualitative feedback and actual Android frame/touch metrics.

## P0 | first map only
- [ ] Three short floors; connected random rooms/corridors, readable exit and rescue objective, safe start, deterministic seeded tests.
- [ ] Gentle encounter density, original creatures, berry/coin pickups, heal/PP tutorial, no early natural traps or ambushes; advanced expeditions retain their rules.
- [ ] Waterfall: separated falling sheet and pool, crest, gravity-aligned flow, foam, ripple rings, mist, depth, water sound attenuated by distance; no water collision on paths.
- [ ] Forest: unique oak/willow silhouettes, exposed roots, layered crowns, ferns, flowering plants, mushrooms, rocks, log, leaf litter, original materials; bounded instancing and triangle counts.
- [ ] Portrait HUD: 4 equipped moves with PP/element, regular Strike zero PP, configurable floating Strike, tap/drag Aim, Bag, touch move/tap-to-walk, joystick option, minimap, stairs only when actionable; safe area and single-handed layout. Preserve user preferences and hold/drag gestures.
- [ ] Responsive state feedback: HP/PP, pickup toast, damage/miss/critical, restrained haptic opt-in, floor transition, victory reward; no intrusive UI or manipulative monetization.
- [ ] 3-floor completion, resume, pause, touch conflicts, no clipping, 30/60 FPS measurement on real Android; preserve 589-move catalog and Monster House system.

## P1 | dungeon simulation
- [x] Existing procedural layout, turn logic, movement, four moves, PP, regular attack, 18 types, status, traps, Monster House: audit individually, not certified.
- [ ] Room graph, variants, dead ends, corridors, visibility/fog of war, room/terrain restrictions, diagonals and corner rules, water/lava/chasm/walls, spawn safety, enemy pathfinding, ally AI tactics, turn scheduling, speed, waiting, auto-explore optional.
- [ ] Floor cap/wind warnings, hunger/fullness, healing/recovery, weather, terrain status, stairs, hidden stairs, checkpoints, boss chambers, treasure floors, locked doors/keys, hidden loot, special floors, secret bazaar, secret room.
- [ ] Monster House: warning, spawn cap, traps/loot, clear condition, rewards, exit/reset. Optional tough enemies and shiny-equivalent originals.
- [ ] Rescue requests, escort, item retrieval, outlaw chase/team, challenge letters, secret treasure, multi-mission, rescue after defeat, difficulty ranks, rewards and failure loss rules.

## P2 | items and progression
- [ ] Inventory slots, stacking, inspect, pickup/drop/swap/throw/use/give, ground items, sorting, equipped gear, sticky/cleanse, price/value, save and restore.
- [ ] Orbs: escape, reveal/map, radar, item finder, room damage, petrify, slumber, slow, quick, warp, rollcall, switcher, decoy, cleanse, trap reveal/removal, weather, terrain, wall traversal, stairs reveal; specify targeting, exclusions, duration, AI behavior and tests per item.
- [ ] Seeds: reviving, sleep, stun, blast, warp, hunger, joy/XP, doom, healing, speed, blind/confuse; berries, food, PP restore, drinks, training items, throwable projectiles, manuals, keys, treasure boxes, evolution items, exclusive equipment.
- [ ] Trap catalogue: poison, sleep, slow, seal, PP drain, sticky, warp, pitfall, summon, explosion, mud, spin/confusion, hunger, item loss, trip, chestnut-like, spikes, toxic spikes, stat reset tile (beneficial, distinct). Reveal, immunity, trigger priority and prevention.
- [ ] In-dungeon merchant (original character; Kecleon reference): shop boundary, prices, buy/sell, pending bill, pay before leaving, theft detection, merchant response, save/load, no unfair accidental theft.
- [ ] Guild/base, mission board, town shops, bank, storage, appraisal, move tutor/linking, dojo, recruitment, team roster, camps, affinity/quality, leveling, evolution, specialization, rare loot.
- [ ] DX optional QoL: auto mode, recommended move, recruitment camps, rare qualities, move growth, party quick swap. Keep explicit manual controls.

## P3 | visual/audio pipeline
- [ ] Reference DX visual behaviors (not claim of exact shaders): layered terrain, illustrated color palette, animated scenery, silhouettes, camera readability, atmospheric separation, contact shadows, environmental reaction.
- [ ] Original meshes and shaders per biome: forest, coast, cave, mountain, waterfall, snow, desert, volcano, reef, celestial, ruins, storm, dark forest.
- [ ] Local particles, depth-aware water, ambient creatures, smooth lighting, original soundscape and music, attack effects synchronized to turn results; avoid extra lights and expensive full-screen effects on mobile.
- [ ] Validate actual GLBs, mesh counts/UV/materials, fixed seeds with screenshots (real engine only), no blocked cells, no UI overlap. Budget by device, adaptive presentation only; gameplay never changes with quality.
- [ ] Map catalog in DUNGEON_REFERENCE.md; one approved vertical slice before next dungeon.
