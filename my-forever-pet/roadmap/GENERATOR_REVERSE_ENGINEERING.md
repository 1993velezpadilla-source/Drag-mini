# V26.26 — Mystery Dungeon generator evidence ledger
Date: 2026-11-27. Target: behavioral parity, not copied game code/assets.
## REA readiness
Reviewed https://github.com/morluto/rea and its native provider requirements. REA MCP is not registered in the current session, neither rea nor Ghidra is installed in the working container, and no authorized NDS or extracted DX executable was supplied. No REA binary trace or ROM dump was performed. Do not report this as executed REA or exact parity.
When a lawful local copy is available, use a reviewed/pinned REA release and a compatible native analysis provider. For NDS use overlay 29 and the matching region symbols; for DX identify build version, executable sections and any applicable metadata. Trace floor creation, RNG state, room/corridor creation, non-enemy spawns, connectivity repair and stair interaction. Save function addresses, observed inputs/outputs, pseudocode summaries and independent test vectors; never upload proprietary game files to GitHub.
## Evidence inspected directly
- Explorers of Sky: https://github.com/EpicYoshiMaster/dungeon-mystery/blob/main/src/dungeon.ts — AssignGridCellConnections (~445, local directional random walk with 50% direction resampling), CreateRoomsAndAnchors (~292), SpawnNonEnemies (~3815, NA 0x02340D4C), player placement (~4111). The community reconstruction is GPLv3; no source copied into Kindria. Stairs use eligible room floor, exclude junctions, shops and occupied/special tiles. Leader eligible room floor excludes junctions, items, traps and enemy markers; ordinary floors can start on stairs, rescue floor excludes staircase. Room connectivity repair and full 56x32 dimensions, anchors, other layout families and spawn order still require parity work.
- https://github.com/UsernameFodder/pmdsky-debug — reverse-engineering headers/symbols; dungeon tile spawn/visibility flags and natural junctions. https://github.com/pret/pmd-sky — work-in-progress disassembly; not standalone ROM.
- Time/Darkness: https://nintendoworldreport.net/review/15984/pokemon-mystery-dungeon-explorers-of-darkness-n-explorers-of-time-nintendo-ds — contemporary observation of procedural layout and starts near exits; https://tasvideos.org/Forum/Topics/19446?CurrentPage=1 — shared series RNG discussion. Do not assume Sky executable or RNG exact match to both earlier editions.
- DX: https://github.com/tech-ticks/DreamNexus/blob/master/SkyEditor.RomEditor.Rtdx/Domain/Rtdx/Models/DungeonFloorModel.cs — directly inspected floor record with room count, enemy/item/trap min/max density, shops, Monster House, Mystery House, weather and turn limit. https://github.com/tech-ticks/DreamNexus/blob/master/SkyEditor.RomEditor.Rtdx/Domain/Rtdx/Structures/DungeonMapDataInfo.cs — fixed-map index and music selection. These schemas establish data-driven floor configuration, not the runtime layout algorithm. Exact DX spawn rules not independently confirmed.
## Kindria implementation
- [x] Normal stairs always usable; no relic gate (V26.25).
- [x] Uniform choice of player and stairs among all room interior candidates; exclude natural corridor mouths by checking adjacent walkable tiles outside room; ordinary same-tile stairs allowed; guardian finale excluded from same-tile spawn.
- [x] Directionally persistent local room-slot walk; repair disconnected components using existing corridor builder; preserve starter compact profiles and region art budgets. This is independent code, not exact 56x32 grid/anchor implementation.
- [x] Regression coverage expanded to 512 seeds, all 3 regions, reachable exits, adjacent and overlapping stairs, interior eligibility, duplicate rejection.
- [ ] Run current CI and real Android capture; verify same-tile staircase UI and companion placement.
- [ ] Implement data-driven room layout families and min/max densities per dungeon/floor; anchors, dead ends, room mergers, secondary terrain, junction metadata, fixed-map exception, spawn ordering and weighted enemy/item tables.
- [ ] Differentially compare legal reference traces for Sky, Darkness, Time, DX separately. Compare geometry and path distributions, stairs distances, RNG order, junction counts, spawn collisions and event probabilities. Report per-feature measured parity rather than claiming 1:1 without evidence.
- [ ] DX modern visual effects are a separate art/rendering track; preserve original Kindria models and portrait interface.
Commits b72c20e44474100eb9c03e3c78eaf791b117326a and 8086c52bcc33a2a3a76d796d2ad4d71e13b2039f.

## V26.27 — Advanced topology implementation
- [x] Six Kindria topology families: compact (starter), horizontal, vertical, outer ring, branching, connected; seeded layouts rather than fixed maps.
- [x] Ring reserves center sector and joins adjacent outer sectors before connectivity repair; branching permits up to three non-room corridor anchors; other families have bounded anchor budgets.
- [x] Existing random room-interior player/stair placement and free stair progression unchanged.
- [x] Added 902 checks across 180 seeds covering full walkable-tile connectivity, exits, family coverage, anchor budgets/eligibility, and ring center. Commits 9d06dc22065c8bd08f5cda8f725875f488bc1878, 02b88cc5690dfe9ed60bb265a4e9af51a93ce707, 81ce2579bd8ce0ebfba40cb0496d01c4ba58cab6.
- [ ] Validate new CI and portrait rendering of wider/taller layouts; no claim of exact PMD layout probabilities or binary parity. V26.26 cinematic gauntlet 46097159478 and smoke 46097200400 passed.
- [ ] Next: room merging, maze rooms, true junction metadata and configurable density/spawn tables.


## V26.28 — Composable procedural worlds and fair free-to-play
- 24 topology families including the six existing families; normal floors choose from 23, with Compact reserved for the authored starter tutorial.
- Four room profiles (Classic, Wide, Tall, Irregular) and four link profiles (Balanced, Sparse, Local loops, Cross links). Ring retains its protected center and fixed link profile. Up to 356 selectable normal-floor recipe tuples, before actual room occupancy, size, positions, corners, connections and spawns are randomized. These are recipe combinations, not a proven count of distinct maps.
- Mobile guardrails: at most 4x4 sectors and 12 rooms; geometry connectivity is repaired before spawn; stairs remain independently sampled and open on normal floors. Existing recent-geometry history is bounded to 1,024 signatures, with bounded retries; global uniqueness is not guaranteed.
- Gauntlet expands the topology sweep to 768 seeds; coverage, geometry diversity, walkability, stairs, anchors, tutorial isolation and bounds are explicit assertions. CI/Android device validation pending.

### Product rule: free to play, never pay to win
All dungeons, procedural families, loot tables, recruitment, combat power, experience and progression must be obtainable without payment. Purchases may remove ads or provide non-stat cosmetic customization; no paid gear, boosted drop rates, extra power, paid-exclusive progression, paid retries or energy shortcuts. Ads should not interrupt combat or determine rewards or access. This is a product constraint, not an implemented billing system.
### Next replayability work
Independent biome/terrain and room-event profiles, optional treasure branches, Monster Houses, encounter/loot distributions and dungeon-specific weighted recipes; measure novelty and performance rather than merely adding map labels. Preserve portrait layout, deterministic seed reproduction, and fair grinding. Avoid forced detours or key gates on ordinary floors. Android performance and long-run repetition audits remain release gates.


## V26.29 — Procedural Dungeon Ecosystem

- Independent seeded microgeometry profiles: Open, Pillars, Offset pillars, Alcoves, Mixed. Solid interior tiles are only removed from an intact eight-neighbor ring; room centers and entrances are preserved. Final obstacle ledger removes any tile reopened by corridor carving.
- Six ecology profiles: Balanced, Foraging, Patrols, Hazards, Quiet, Mixed. Bounded spawn budgets preserve the tutorial and explicit rescue guardian finale balance. No changes to normal stairs access; no purchase inputs to generation or rewards.
- Up to 10,680 theoretical normal recipe tuples (356 topology/room/link combinations × 5 interior × 6 ecology); not a verified unique map count. Existing 1,024 geometry history and mobile room cap retained.
- Expanded the existing 768-seed gauntlet with obstacle integrity, profile coverage, tutorial isolation and first-floor budget checks. CI and real Android verification pending.
- Next: true merged rooms, passable secondary terrain with batched visual rendering, secret optional areas, biome-specific ecologies, encounter composition and long-run repetition measurement. Do not describe these as implemented yet.
- Free-to-play, never pay-to-win: optional ad removal/cosmetics only; no paid progression, drop-rate, damage, or experience advantages.


## V26.30 — Persistent dungeon landscape identity (user-directed correction)
- User clarified that the visual landscape/theme must remain consistent within each dungeon, as in Mystery Dungeon; procedural variation is the map structure, not random biome swapping. This supersedes V26.29's proposed random microbiomes.
- Runtime visual landscape seed, terrain pigment, forest wind palette, scenic budget and coordinate decoration salts are independent of floor number and expedition RNG. Existing region asset families remain intact. Decoration placement still conforms to generated room boundaries, safe exterior space and mobile budgets; identical prop coordinates are neither required nor guaranteed.
- Starter Woods keeps one consistent visual profile across its three floors; authored floor names, teaching rewards and gameplay progression remain unchanged. Authored palette library retained for future distinct dungeons. Current identity keys are region plus starter distinction; future named dungeons may each select a fixed art profile.
- 25 additional regression assertions across four identities and six floor/seed pairs; updated prior shader uniform expectation. CI and Android visual/performance verification pending. No claim of exact reference-game parity.
- Next: actual connected room mergers, optional branches, dungeon-specific fixed art profiles, structural novelty audits and encounter variety without random biome changes. Free-to-play, never pay-to-win; portrait only.


## V26.31 — Advanced structural generation
- Four independent structural profiles: Separate, Merged chambers (up to one pair), Grand halls (up to two disjoint pairs), Maze passages (short internal wall segments with an intact walkable perimeter). Actual merged rectangular rooms replace their original room records after corridor connectivity repair, before stairs, treasure, actors and Monster House placement. No merged room exceeds 16 tiles in either dimension, overlaps another room, or contains a reserved corridor anchor; at least three rooms retained.
- Starter tutorial and outer ring remain protected. Original topology, ecology, visual identity, and normal stair rules retained. The theoretical recipe ceiling is 42,360 normal profile tuples (352 non-ring base tuples × 4 structural profiles × 5 interiors × 6 ecologies, plus 4 ring base tuples × 1 × 5 × 6); actual distinct map counts and realized merges are not guaranteed.
- Added 3,075 assertions to the 768-seed sweep: room bounds, centers, non-overlap, fully carved merged rooms, merge cap, retained solid wall tiles, protected layouts and actual generation coverage. CI and Android runtime/visual performance still pending.
- Next: optional connected side chambers and branching corridor grammar; strengthen long-run novelty measurement. Keep fixed dungeon art and free-to-play, never pay-to-win.


## V26.32 — Dynamic corridor network
- Five independently selected network profiles: Classic, Branches, Shortcuts, Side chambers and Mixed. Added patches must be inside floor bounds, outside normal room rectangles, and contact existing walkable cells only through their intended endpoints. Shortcuts require an existing longer route; each feature has a bounded candidate search. Up to three features and one 3x3 side chamber per floor. Starter, ring and explicit guardian finales retain classic network geometry.
- Side chambers are optional, reveal on entry, reserve their central material pickup from regular enemy/loot/trap placement, and are excluded from normal room-interior stairs and leader sampling. No keys, secret doors, art changes, or purchases needed. These are connected optional chambers, not hidden-wall secret rooms.
- Corrected V26.31 theoretical profile count to 42,360. V26.32 theoretical normal-floor profile ceiling: 211,320 = 352 non-ring topology/room/link combinations × 4 structure × 5 interior × 6 ecology × 5 network, plus 4 ring combinations × 5 interior × 6 ecology. Geometry, realized features and unique maps are not guaranteed by this arithmetic.
- Added 2,306 assertions to the existing 768-seed gauntlet, including path continuity, bounds/side chamber/reward integrity, protected layouts, and realized coverage of all three feature types. Runtime CI and device validation remain pending.
- Next: seeded corridor bends and longer branched chains; audit novelty history across sessions and verify Android performance, without changing each dungeon's fixed landscape or fair free-to-play progression.


## V26.33 — Infinite structural diversity
- Straight and one-bend corridor branches and shortcuts, with later features able to originate from newly carved branch tiles. Shortcuts must reduce the previous path by at least three steps; existing patch isolation, floor bounds, room exclusion and optional chamber budgets preserved.
- Added canonical shape fingerprint over eight rotations/reflections with translation normalization, in addition to the legacy exact-geometry signature. A separate bounded 4,096-entry canonical history is saved in the existing user://kindria_layout_history.cfg; existing 1,024-entry exact history remains compatible. Old exact-only saves cannot be retroactively canonicalized because they contain hashes, not tile geometry. The 32-attempt cap remains, so uniqueness is best-effort, not a mathematical guarantee. Save errors now generate warnings.
- Expanded 768-seed gauntlet with bend validation, shortcut improvement, canonical diversity threshold, symmetry invariance, distinct shape discrimination, deduplicated history and canonical-only retry. Six additional explicit assertions, plus checks folded into the per-seed network integrity assertion. CI and actual Android performance/roundtrip persistence validation pending.
- No changes to landscape art, monetization or normal stair rules. Next: audit runtime and CI failures, profile generation cost on mobile, test long-session history rollover and persistent roundtrip, then improve structural variety based on measured results.


## V26.34 — Procedural stress and compatible shape-hash optimization
- Replaced per-orientation repeated point rotation and bounding-box passes with a single normalization, direct integer coordinate transforms, and reused packed ID buffer. Canonical v1 encoding unchanged. Independently compared old and new encoding formulas in JavaScript across 2,048 generated point sets: zero mismatches. This is an algebraic implementation check, not executed Godot or Android evidence.
- Added 512 synthetic floors across 128 four-floor sequences, three regions and tiers; canonical history carried into each new expedition object. Checks cover uniqueness, normal stair access, tile connectivity and geometry budget. Some synthetic fourth floors exceed normal low-tier expedition length intentionally to exercise the generator directly, not gameplay progression. Added 64 runtime reference-hash comparisons, 4,096-entry rollover and ConfigFile text serialization checks. New 2,115 assertions. Report includes median/P95/max generation microseconds, unique shapes, retries, largest floor and reference/optimized hash costs.
- Godot executable unavailable in current local environment and PR-filtered workflow lookup returned no runs for V26.33 test commit. New runtime assertions and Android performance remain unverified. Do not claim a speedup, CI pass, or 512 unique floors until logs confirm it. ConfigFile serialization is not a device disk-restart test.
- Preserve fixed visual landscape per dungeon, portrait mode, normal unrestricted stairs and free-to-play without paid power. Next: obtain actual CI and device results, fix any failures before expanding more generation families.


## V26.35 — Procedural reliability: actual CI triage
- Retrieved real branch workflow runs via GitHub Actions collection. V26.34 smoke passed (46098803131); cinematic 46098786926 and release 46098786882 failed in GDScript parsing because V26.33's canonical fixture local `sample` collided with an existing loop variable. Renamed only the canonical fixture variable; no assertions removed (74ed0d33ff46761713a3488297347d3bfd7108c9).
- New cinematic 46098858626, release 46098858653, smoke 46098858656 started. Results pending at inspection. Do not treat the previous smoke pass as procedural stress success. Retain 24 topology families, fixed scenery, free normal stairs and non-pay-to-win progression; defer further features until runtime results are reviewed.


## V26.36 — Independent procedural validation
- Added a standalone headless Godot 4.6 test that copies the actual dungeon_rules.gd into a minimal temporary project, independently of graphical assets and combat visual export. Tests 256 four-floor expeditions (1,024 generated normal floors), canonical history shared across expeditions, all 23 normal topology families, connectivity, room bounds, enemy/reward placement, stairs and three guardian finales. 6,151 explicit assertions; emits timing percentiles and observed feature counts. No gameplay changes.
- Workflow .github/workflows/kindria-procedural.yml triggers on generator/test/workflow changes and preserves logs; separate concurrency group avoids canceling the cinematic gauntlet. Test commit dc9903c6f9d76d43f48afec261319f49d4bab0d2, workflow 02ee0c1f6a00b29c30d1effa418afe16adac1bf4. Initial workflow run not yet listed at inspection. Prior corrected cinematic/release jobs passed import and were still executing, not yet green. Actual Android benchmark remains pending.
- Keep fixed landscapes, procedural geometry, portrait and fair free-to-play. Do not certify uniqueness or generation speed until measured results are available.


## V26.37 — Verified procedural baseline and full-history endurance
- Actual Godot 4.6 standalone CI PASS, run 46098953506, job 140836763723, commit 02ee0c1f6a00b29c30d1effa418afe16adac1bf4: 1,024 floors, 1,024 unique canonical shapes, all 23 normal families, all 20 structure/network pairs, zero retries, six same-tile stair starts, 370 optional chambers, 6,151 checks, zero failures. Linux runner logical generation median 1.795 ms, P95 3.047 ms, max 4.604 ms. Not Android frame or rendering timings; no universal uniqueness guarantee.
- Extended standalone test with optional 4,608-floor/1,152-expedition endurance mode crossing the 4,096-entry canonical history capacity, checking oldest-entry rollover, and 64 forced seeded repeat tests to exercise canonical rejection directly. Added a required CI step and preserved separate logs. New tests 4650492d5fbc0f060d94eedea88b9d8ff3886ea4; workflow 751fb2a1978398604e7d7c3a14df0689169b0cf2. Endurance results pending. Full cinematic/release and device performance remain separate release gates.


## V26.38 — Verified full gauntlet and endurance CI repair
- Cinematic gauntlet 46098858626 passed 338,008 checks, zero failures; release validation 46098858653 passed. Logs: 768 unique topology geometries across 24 families, 295 realized base recipes, 4,236 solid interior tiles, 439 room merges, 1,170 maze tiles, 357 branches, 249 shortcuts, 247 side chambers, 162 curved paths. Separate 512-floor stress passed with 512 unique shapes. Legacy hash aggregate 82.070 ms vs optimized 72.350 ms on the measured sample (Linux, not Android).
- Standalone 46099033179 passed 1,024 floors, 1,024 unique shapes, 64 forced repeat retries, 6,216 checks, zero failures. Endurance workflow runs 46099038564/46099047024 had no jobs because the YAML was malformed by a JavaScript replacement-string dollar expansion. Rebuilt the affected tail without replacement interpolation (e171def4f788763700d83ea5804d30f9766d6b7e). Corrected workflow 46099120361 started; 4,608-floor result remains pending.
- Legacy core gameplay run 46098946330 failed at dungeon_test.gd line 34 (old 4–9 room assumption). Updated test to 3–12 rooms, canonical signatures, same-tile stairs and optional relic progression, isolated pickup/ambush behavior and linear BFS connectivity; code commit 7f20d6c29af0753d09b03291d3acb4955fc4ca690. New core results pending; no production gameplay changes this pass. Device disk restart and Android performance remain unverified.


## V26.39 — Verified endurance and recoverable history
- Actual Godot 4.6 run 46099120361 PASS: 4,608/4,608 unique floors, 23 normal families, 20 structure/network pairs, 0 natural retries, 24 same-tile stair starts, 1,679 optional chambers, 128 history rollover checks, 64 forced repeat retries, 27,848 checks, zero failures. Linux median 1.656 ms, P95 2.752 ms, max 4.073 ms. Short 1,024-floor run also passed 6,216 checks. These are observed sample results, not an unlimited uniqueness guarantee or Android benchmark.
- History writes now validate a temporary ConfigFile before replacing the primary, retain a previous valid snapshot, reject malformed signature arrays, and recover from a corrupt/missing primary using the backup. Legacy exact-only saves remain readable. View delegates to shared gameplay rules helpers; dev sandbox writes remain disabled. No gameplay or art changes. Commits c47cd188021590865be23b0cb54fd2050e77fce0 and 9cc1165d8827c237c0f830525ce22f04de688bbf.
- Added eight actual disk I/O assertions for legacy read, replacement, backup recovery and resumed writes in standalone test (398854b259f43e9c69c1b9f964c6cd0be50e35c0). New CI and actual Android restart/power-loss verification pending. Backup is previous snapshot, not a promise of zero lost history after corruption. Legacy gameplay run 46099146739 was still in progress at initial inspection.


## V26.40 — Process restart validation and combat fixture compatibility
- Actual V26.39 procedural CI run 46099239451 passed both short and endurance suites, including eight disk history assertions. Endurance: 4,608 unique floors, 27,856 checks, zero failures; Linux median 2.669 ms, P95 4.557 ms, max 7.588 ms. Short: 1,024 unique, 6,224 checks, zero failures.
- Added actual separate-process history write/read modes, with same-seed regeneration checked using persisted canonical history alone; workflow now requires KINDRIA_HISTORY_RESTART_PASS. Commits 861ae0612d909198324bcecdba237efa06b5079c and 4690e3d6f1429a5954bc4801c76fb8d99a838bcc. This new test is pending CI; Android process restart remains unverified.
- Legacy core run 46099146739 progressed beyond navigation to line 82, where the combat fixture assumed obsolete regular strike damage. Updated fixture to explicitly check zero energy consumption, then isolate finishing strike at 1 HP; guardian fixture uses a powered finishing attack rather than accuracy-gated free strike. Commit b2bef6ba7377eaf81f2905d8f10ce331a24134cf. Full core rerun pending. No production gameplay balance changes.


## V26.41 — Monster House encounter diversity
- V26.40 restart validation 46099310887 passed: separate processes saved and reloaded canonical history, rejected the same-seed layout with one retry, and generated a different signature. Endurance 4,608 unique floors, 27,856 checks, zero failures. Linux only; Android restart still unverified.
- Six seeded Monster House recipes: Classic, Swarm, Vanguard, Crossfire, Treasure lure, Trap nest. Vary bounded enemy count, composition by existing combat class, and loot/trap budgets. Original encounter chance and cap retained, no locks on ordinary stairs, no new art, and reward placement excludes allies. Combat class emphasis is not a guarantee of a specific species or attack range. Commit 790e7aa4d93185af7a4c2b32ab27f5220809851f.
- Standalone tests force encounters across 192 seeds, requiring all profiles, legal unique spawn locations, bounded counts, expected composition, no duplicate activation and free normal stairs. Commit 3300c8180118daa382772616e4e4dbc0480b8872. Runtime validation of the new encounter recipes and Android gameplay remain pending; no claim of balance verification or reference-game exact parity.


## V26.42 — Dynamic ordinary room encounters
- V26.41 procedural CI 46099401041 passed 28,625 checks across 4,608 unique floors; 192 forced Monster Houses covered all six profiles: Classic 25, Swarm 36, Vanguard 36, Crossfire 34, Treasure lure 30, Trap nest 31. No failures; distribution is from forced tests, not natural encounter odds.
- Five ordinary room profiles: Classic, Patrol, Supply cache, Guarded cache, Hazard pocket. Dedicated seeded RNG; up to three existing enemies, four existing ordinary pickups or three existing traps redistributed according to recipe. No added resource/enemy budget, no geometry/art changes. Excludes leader, staircase and relic rooms; retains side chamber rewards, first-floor/tutorial/guardian/restorative floor isolation, and prevents Monster House overlap. Actual movement depends on available room tiles and existing supplies. Commit a2cae84f1c27376e868cc80393308e4435e25f92.
- Added coverage, relocation limits, room exclusion and realization checks to independent procedural suite (f1b1f30dadfc5f8ce6e21ad17927afda344dff79). 4 additional counted checks per generated floor plus 5 global checks. New runtime CI and Android encounter balance remain pending; no claim of exact PMD parity.


## V26.43 — Regional treasure discoveries
- Verified V26.42 procedural CI 46099494826: 4,608 unique floors, 47,062 checks, zero failures; normal encounter distribution Classic 2434, Patrol 544, Supply cache 549, Guarded cache 533, Hazard pocket 548. Core run 46099494903 passed 720 dungeon floors and then failed an obsolete fixed Strike training assertion at line 226. Updated that fixture to use the typeless regular attack damage formula and bounded variance with sure-hit boon; no production combat changes (44eb9b4510b58e8228ff59ff82af43bd19390edb).
- Added seeded optional treasure replacement, up to one discovery on floor 2 and two on floor 3+, with a 45% primary roll and 15% additional roll from floor 3. Each replacement uses an existing ordinary coin/material slot, selects ward/force band or a regional library technique manual, with level-8 and level-15 manual ranks gated by tier and floor. Regional type pools include normal plus five region-specific elements. No change to teaching manual, side chamber material, geometry, stairs, starter/guardian/restorative floors, or paid progression. Existing pickup and manual eligibility rules retained; a discovered manual is not necessarily immediately teachable. Commit c0746ec580b3d4bb0cbf2aa68f950bd533771aad.
- Added per-floor treasure placement/rank/type checks and global coverage gate (f0ef756f8cdd124436e282d4c444cec9b23920b6). New CI and Android balance pending. No exact PMD parity claim.
