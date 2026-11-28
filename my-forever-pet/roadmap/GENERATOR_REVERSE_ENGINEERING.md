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
