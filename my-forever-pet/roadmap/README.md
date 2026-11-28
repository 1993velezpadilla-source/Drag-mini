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
- [ ] Three short floors; connected random rooms/corridors, readable exit and optional rescue objective, safe start, deterministic seeded tests.
- [ ] Gentle encounter density, original creatures, berry/coin pickups, heal/PP tutorial, no early natural traps or ambushes; advanced expeditions retain their rules.
- [ ] Waterfall: separated falling sheet and pool, crest, gravity-aligned flow, foam, ripple rings, mist, depth, water sound attenuated by distance; no water collision on paths.
- [ ] Forest: unique oak/willow silhouettes, exposed roots, layered crowns, ferns, flowering plants, mushrooms, rocks, log, leaf litter, original materials; bounded instancing and triangle counts.
- [ ] Portrait HUD: 4 equipped moves with PP/element, regular Strike zero PP, configurable floating Strike, tap/drag Aim, Bag, touch move/tap-to-walk, joystick option, minimap, stairs only when actionable; safe area and single-handed layout. Preserve user preferences and hold/drag gestures.
- [ ] Responsive state feedback: HP/PP, pickup toast, damage/miss/critical, restrained haptic opt-in, floor transition, victory reward; no intrusive UI or manipulative monetization.
- [ ] 3-floor completion, resume, pause, touch conflicts, no clipping, 30/60 FPS measurement on real Android; preserve 589-move catalog and Monster House system.

### Dungeon 001 — V26.20 implementation ledger
- [x] Source implemented: three floor identities (Fernlight Clearing, Silverbrook Falls, Ancientroot Grove), 3/4/4 room profiles, distinct teaching pickups, revealed relic/exit markers and floor-specific vista composition.
- [x] Source tests added for 12 seeds × 3 floors: exact room counts, titles, teaching reward and objective transition (180 extra assertions). Commits 34742ea2d01f5f2dee80a13599c2e5c3aeaff35f, 879742096b2d3cd9fffa551bb1cc1b3bc9a28eb3, ca211d0c3db38f1d5c17a7b50aeadb7194607b39.
- [ ] Validate V26.20 CI and actual exported forest models; Android rendered capture, HUD sizing and one-handed controls. Earlier V26.19 smoke and cinematic gauntlet passed; this is not proof of the new version.
- [ ] Next: localized cascade mist and audio, distinct grove props, objective feedback and touch acceptance.

### Dungeon 001 — V26.21 Living Waterfalls
- [x] Source implemented: localized rising mist and expanding impact foam, one GPU MultiMesh, max 3 vista anchors × 10 particles, transformed Blender pool coordinates, cached original 2-second looping spatial waterfall audio, stop old emitters on floor replacement. Starter woods only. Commit e39b26ab600214adecaf671e56f43e7679c5eff6.
- [x] Added 16 checks for particle cap, transform, audio format/loop/seam/amplitude/cache and cleanup (86763ad59b86e18a15c63a6bcf228178508e0d0b).
- [ ] Verify V26.21 CI and actual rendered waterfall mist/foam placement, audio balance and mobile frame time. F002 remains open until real Android validation.
- [ ] Next: floor-specific forest props and silhouettes, reactive undergrowth, contact shadows, then portrait GUI playtest.

### Dungeon 001 — V26.22 Living Forest Remastered
- [x] Source implemented: three floor-specific terrain pigments, canopy color/wind profiles, height variation; starter-only player proximity foliage response, unchanged navigation. Commit 173b63d971e0e5afeb836cb8acd63cb05a492780.
- [x] Blender generator updated: hanging leaf silhouettes, animated central oak crown, curved-stem fungi. Commit c0337422899ffb9e4180d24783ec0f96a5fcfa01.
- [x] 11 new profile/material regression checks authored (5161a8cbe700b82d26ac73bceb80c8fbad4fb1ba).
- [ ] Verify V26.21/V26.22 CI, Blender export geometry and actual rendered Android foliage, contact shadows, readability, and frame-time. F002/F003/F008 remain open.
- [ ] Next: portrait GUI input usability and objective feedback, plus contact-shadow polish. No new dungeon until first-map gates pass.

### Dungeon 001 — V26.23 Premium Mobile Experience
- [x] Source implemented: 56-unit move cards, numeric and color-coded PP gauges, ready-to-release border, 66-unit floating free Strike, retained aim gestures and saved layout. Commit c70d2f5c8a8c2af46f8c020191b624cde0fed194.
- [x] 15 checks added for PP gauge bounds, thresholds, charged release, depleted PP and pointer pass-through (caa0ed188fc0d67bc796f615140fbd2f8b325ecf).
- [ ] Verify CI, real Android readability for long move names, one-handed reach, aim/strike gesture conflicts and viewport fit with joystick enabled. F004 remains open.
- [ ] Next: contextual objective/reward feedback, compact action bar and portrait touch playtest. No new dungeon until first-map gates pass.

### Dungeon 001 — V26.24 Reward & Interaction Experience
- [x] Source implemented: dedicated reward captions, color-coded feedback and four cached original audio cues, floor-cleared banner, persisted completed floor bonus. Commits d0e81125c6e5f1f5a4891d199d43d958403a6801, eeddb68ede0e6c1ea8d514ab29d2c0e2a5722536, ca0175726bdbe2e0dc4a1c51e9642ef296ec6b02.
- [x] Prior gauntlet 46095896245: 319182 checks, 1 failure (V26.22 safe initial center); explicit shader uniform initialization added in d0e81125. V26.23 smoke run 46095907377 passed. New run required before declaring correction verified.
- [x] 21 new checks authored for reward messages, audio cache and floor bonus carryover (b557b5c4bae45017a217c0b1e355aad259243e8d).
- [ ] Verify latest CI, Android reward readability, audio balance, timing, and final expedition result screen. No gameplay reward amounts changed. F006 remains open.
- [ ] Next: expedition result screen and companion continuity, then Android first-map playtest.

### Dungeon 001 + all normal dungeons — V26.25 Classic Random Stairs
- [x] User design correction: normal stairs never require relics, keys or clearing enemies. Treasure is optional (+5 coins). Only explicit legacy rescue guardian finales retain their guardian condition; review these separately if needed.
- [x] Entrance and stairs independently selected from walkable room tiles; different tile, connected layout, no forced farthest exit, legitimate adjacent/same-room lucky stairs. Shared generator applies across all regions.
- [x] Geometry-only SHA-256 signature of normalized sorted walkable coordinates; reject previously encountered layouts, up to 32 generation attempts, bounded 1024-entry local persistent history across runs. Finite capacity and retry cap mean no mathematical promise of infinite uniqueness; no server-wide tracking.
- [x] HUD/minimap/exit button use stairs availability instead of relic status; optional treasure remains marked. Commits 3fa1f45efd2b514b4717534f4a118391b606a097, c1403b577b8e29711cace38d4d1b99798079a2ff.
- [x] 388 additional checks authored across 128 seeds, three regions, reachable random stairs, lucky adjacency, no relic requirement and deterministic duplicate rejection (bb0863849718f4c5fd2280ea03498f371a55aabb).
- [ ] Validate CI, Android persistence and touch, staircase distribution and actual playtest; compare reference dungeon generation distribution without claiming exact Nintendo implementation. All earlier roadmap references to mandatory relics are superseded by this rule.

### V26.26 — Reference-backed generator research
- [x] [GENERATOR_REVERSE_ENGINEERING.md](GENERATOR_REVERSE_ENGINEERING.md) records REA prerequisites, Sky function references, Time/Darkness observations, DX floor metadata and remaining parity gaps.
- [x] Implemented local direction-persistent grid connections with repair, eligible room-interior stairs and player spawn, possible same-tile stairs on normal floors. Shared across regions; original Godot code.
- [x] Expanded generator regression coverage to 512 seeds; pending CI. Previous V26.25 cinematic gauntlet and release validation succeeded.
- [ ] REA binary inspection requires compatible local provider and authorized target copies; no binary analysis in current environment. Exact DX/Time/Darkness/Sky parity not yet established.
- [ ] Data-driven floor profiles, additional topology families, anchor corridors, secondary terrain and reference-trace comparison.

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
