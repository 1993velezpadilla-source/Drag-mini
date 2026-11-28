# Kindria 2027 — Pokémon Mystery Dungeon community intelligence audit
Research date: 2026-11-27. Scope: all 11 core Pokémon Mystery Dungeon releases, grouped into seven families where mechanics overlap. This is a qualitative, purposive review of public English-language community discussions and professional reviews; no exhaustive scraping, unique-person count, representative sampling, or claim of measured hate frequency. Votes are self-selected; nostalgia, platform access and community selection bias matter. Japanese-only WiiWare evidence is sparse, so individual version sentiment is not separable. All proposed designs are original Kindria adaptations.

## Quantitative context (not market share)
GameFAQs poll, 528 votes [S1]: Explorers Time/Darkness/Sky 267 (50.57%); Super 159 (30.11%); Red/Blue 47 (8.9%); DX 27 (5.11%); Gates 25 (4.73%); Adventure Squad 3 (0.57%). Reddit multi-category poll summary June 29, 2026 [S2]: 9,734 aggregate votes, Sky 5,897, Super 1,716, Rescue Team family 1,468, Gates 653; Sky led all categories according to organizer. Votes across polls are not unique respondents; do not add the two surveys or interpret as sales. Community and contemporary professional critics disagree, especially on Explorers' repetitive gameplay.

## Reception by release family
| Release | Appreciated themes | Recurring or notable criticisms | Kindria decision | Sources / confidence |
|---|---|---|---|---|
| Red Rescue Team (GBA) / Blue Rescue Team (DS), 2005 | Visit-able Friend Areas, classic challenge, atmosphere, partner bond, roster | Team reassembly, inefficient ally AI, grind and long postgame, partner loses relevance | Save team presets; visit real habitats; keep companion present and tactics configurable | S3,S4,S5,S6; medium-high |
| Explorers of Time / Darkness, 2007 | Guild, character-driven adventure, music, mission variety, expanded content | Similar-looking floors, repetition, AI, story party restrictions | Distinct floor landmarks and objectives; meaningful ally tactics; optional narrative restrictions only when justified | S3,S4,S7,S8; medium-high |
| Explorers of Sky, 2009 | Emotional story, soundtrack, special episodes, side characters, rich postgame and fan nostalgia | IQ grind and arbitrary group restrictions; repeat missions; starter limitations; limited use of recruits during story | Original branching side episodes, persistent partner, visible talent progression, player-selected species, authored quest variants | S2,S4,S9,S10,S11,S12; high for story appeal, medium for specific complaints |
| Blazing / Stormy / Light Adventure Squad, 2009 | Unusual stack attacks, flexible party choice, cute models, interesting difficulty | Thin story, short campaign, uneven difficulty, access/localization limits | Optional synchronized duo skills later; avoid mandatory stacks; no version-exclusive content | S1,S13,S14,S15; low; no claim of per-version consensus |
| Gates to Infinity, 2012 | Paradise building, side cast, themes, soundtrack, puzzles and Mysteriosity | Slow dialogue, small roster, one mission per dungeon trip, limited postgame, simplistic battles | Adjustable text speed/skip, expandible sanctuary, multiple compatible missions, optional dynamic floor modifiers | S3,S16,S17,S18,S19; medium-high |
| Super Mystery Dungeon, 2015 | Tactical item use, move growth, broad roster, mission-linked recruitment, challenge | Abrupt difficulty spikes, slow school arc, forced story pacing, fixed or unavailable recruits, accuracy frustration | Readable threat previews, fair progression, guaranteed recruitment path plus optional discovery; never arbitrarily lock favorite ally | S3,S20,S21,S22,S23,S24; high for split on recruitment/difficulty |
| Rescue Team DX, 2020 | Illustrated art, accessibility, streamlined team management, rare qualities and convenient actions | Repetitive layouts, optional automation perceived as oversimplification, missing manual basic attack, camp menu instead of visits, polarizing art/rare-quality balance | Preserve separate zero-PP Strike, optional assists, visit-able habitats, tactile portrait interface, stronger visual landmark variety, fair traits | S4,S25,S26,S27,S28,S29; high for existence of split, not universal prevalence |

## What to preserve vs. avoid (design decisions, not survey percentages)
P0: narrative agency and partner continuity; manual combat with four moves plus Strike; fast mobile input; varied generated floor objectives and visible landmarks; useful items; accurate enemy/ally behavior; no unnecessary dialogue pauses, no mandatory autoplay, no sudden untelegraphed difficulty walls.
P1: mission batching; optional team tactics; visit-able sanctuary and camp habitats; choice-based recruits with transparent requirements; enemy threats and item descriptions; difficulty options that do not alter paid rewards; short sessions with safe save/resume.
P2: story episodes, merchant/shop, traps, orbs, hidden floors, rare enemies, cooperative attacks, dungeon modifiers, expanded sanctuary. Never implement all of these in the beginner map merely to check a box.
Disputed: automation, old IQ vs rare qualities, fixed vs random recruitment, hard vs accessible difficulty, pixel vs illustrated 3D. Offer choices where practical, with sensible defaults. No exploitative retention mechanisms or monetized power.

## Dungeon 001: Enchanted Woods acceptance gates (all open; proposals, not implemented by this audit)
- [ ] F001 forest layout: three compact seeded floors, distinct silhouettes and a navigational landmark per floor, accessible paths, no repeated mandatory detours.
- [ ] F002 waterfall: separate falling sheet, pool ripples, impact foam and bounded mist; coherent downward flow, audible spatial water; real Godot screenshots and Android capture.
- [ ] F003 art: unique tree crowns, visible roots, foreground/midground/background separation, fauna and original ambient music; no clutter hiding enemies or tiles.
- [ ] F004 controls: four attack slots with readable PP, explicit zero-PP Strike, aim tap/drag, Bag, optional joystick, toggleable assist default manual; saved preferences; one-handed touch and safe-area checks.
- [ ] F005 companion: an original named companion with short meaningful dialogue, reliable follow behavior and combat tactics; no repeated instruction screens.
- [ ] F006 reward loop: clear rescue goal, useful loot, progression feedback, no compulsory repeated runs; short retry path and understandable loss rules.
- [ ] F007 difficulty: no natural traps/Monster Houses in starter profile; teach enemy telegraphs and counterplay; advanced profiles unchanged.
- [ ] F008 performance: real Android build, p50/p95/p99 frame-time and touch tests; target 60 FPS when device supports it, stable 30 fallback, no unsupported performance claims.
- [ ] F009 first-time playtest: target 5-10 minute initial expedition (hypothesis, not measured), measure time to first move, first attack, first pickup and completion; ask what players enjoyed, where they were confused, why they quit.
- [ ] F010 release gate: resolve crashes, blocked corridors, UI overlaps, accidental taps and input conflicts; preserve 589 moves and existing advanced mechanics. Only then proceed to dungeon 002.

## Source registry (direct URLs, paraphrased rather than copied)
S1 https://gamefaqs.gamespot.com/boards/160809-pokemon-super-mystery-dungeon/80537726 — favorite poll.
S2 https://www.reddit.com/r/MysteryDungeon/comments/1uivpbb/pmd_poll_results_summary/ — June 2026 multi-poll results.
S3 https://www.reddit.com/r/MysteryDungeon/comments/1ibyhzy — cross-series best/worst.
S4 https://www.reddit.com/r/MysteryDungeon/comments/1wzm3yd/what_are_some_things_you_dislike_about_in_each/ — October 2026 complaints.
S5 https://www.nintendolife.com/reviews/gba/pokemon-mystery-dungeon-red-rescue-team — original retrospective.
S6 https://www.reddit.com/r/MysteryDungeon/comments/104ux09 — cross-generation specific complaints.
S7 https://www.gamespot.com/reviews/pokemon-mystery-dungeon-explorers-of-time-review/1900-6190121/ — critical review.
S8 https://nintendoworldreport.net/review/15984/pokemon-mystery-dungeon-explorers-of-darkness-n-explorers-of-time-nintendo-ds — both versions.
S9 https://www.nintendolife.com/reviews/wiiu-eshop/pokemon_mystery_dungeon_explorers_of_sky_ds — Sky retrospective.
S10 https://www.reddit.com/r/MysteryDungeon/comments/1ctm60b/what_small_flaws_does_explorers_of_sky_have/ — fan critique.
S11 https://www.gamesradar.com/games/pokemon/my-favorite-pokemon-game-has-been-trapped-on-one-console-for-15-years-and-i-desperately-need-nintendo-to-let-more-people-play-it/ — Sky story and extras.
S12 https://www.reddit.com/r/MysteryDungeon/comments/11gopxt — soundtrack attachment.
S13 https://www.reddit.com/r/MysteryDungeon/comments/12zqwxi/so_whats_up_with_the_adventure_squad_games/ — player experiences with stacking.
S14 https://www.reddit.com/r/MysteryDungeon/comments/1qr0cia/unheard_of_mystery_dungeon_game/ — short campaigns and difficulty.
S15 https://pokemondungeon.com/pokemon-mystery-dungeon-wiiware/ — trilogy mechanics and limited reception.
S16 https://www.reddit.com/r/MysteryDungeon/comments/1futlfo — Gates appreciation.
S17 https://www.reddit.com/r/MysteryDungeon/comments/185tldc — Gates story vs gameplay.
S18 https://www.gamespot.com/reviews/pokemon-mystery-dungeon-gates-to-infinity-review/1900-6406381/ — Gates critical review.
S19 https://gamefaqs.gamespot.com/boards/281230-pokemon-mystery-dungeon-rescue-team-dx/78347956 — Paradise and floor modifiers.
S20 https://www.reddit.com/r/MysteryDungeon/comments/qifflj — Super mixed reception.
S21 https://www.reddit.com/r/MysteryDungeon/comments/o7kn6z — Connection Orb trade-offs.
S22 https://www.nintendolife.com/reviews/3ds/pokemon_super_mystery_dungeon — difficulty and repetition.
S23 https://www.gamesradar.com/pokemon-super-mystery-dungeon-review/ — positive tactical/recruitment review.
S24 https://www.reddit.com/r/MysteryDungeon/comments/j1i98o — progression and difficulty criticism.
S25 https://www.reddit.com/r/MysteryDungeon/comments/1ac8ojm — manual attack, automation, IQ debate.
S26 https://www.reddit.com/r/MysteryDungeon/comments/1crnfll — missing visitable camps and positive rare qualities.
S27 https://www.reddit.com/r/MysteryDungeon/comments/1rzka90/what_do_you_guys_think_of_pokemon_mystery/ — DX art and controls.
S28 https://www.digitaltrends.com/gaming/pokemon-mystery-dungeon-rescue-team-dx-review/ — simplification and repetitive gameplay.
S29 https://www.reddit.com/r/MysteryDungeon/comments/1wv8nq1/opinion_on_dx_art_style/ — divergent preferences on art.
S30 https://www.smogon.com/articles/spinoff-spotlight-pmd — cross-series retrospective.
S31 https://www.reddit.com/r/MysteryDungeon/comments/1wnq9jw/gates_to_infinity_is_so_overhated/ — Gates counterpoint.
S32 https://www.destructoid.com/reviews/review-pokemon-super-mystery-dungeon/ — tactical customization and challenge.
S33 https://www.gamespot.com/articles/pokemon-mystery-dungeon-rescue-team-dx-review-roun/1100-6474481/ — critic disagreement.
S34 https://www.reddit.com/r/MysteryDungeon/comments/1s6mtvy/whats_public_opinion_on_rescue_team_dx/ — divergent art/difficulty opinions.
S35 https://www.reddit.com/r/MysteryDungeon/comments/1u6g3p1/pmd_poll_no_4_which_game_has_the_best_soundtrack/ — selection-bias discussion.
Limitations: some Reddit full-page fetches were blocked; search excerpts and accessible indexed comments were used. No direct Nintendo player telemetry or Japanese community sample. This audit is a design input, not proof of market demand, feature completion or performance.
