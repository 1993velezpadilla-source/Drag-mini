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
