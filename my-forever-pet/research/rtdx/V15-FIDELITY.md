# V15 — Evidence-first RTDX fidelity

Research target: Nintendo Switch Rescue Team DX, not Explorers of Sky or main-series Pokémon. The 589-entry Kindria catalog includes original native moves, so no exact RTDX counterpart is assumed for them.

## Evidence gate

See [v15-reference-evidence.json](v15-reference-evidence.json). The index contains 26 named stills; 14 were visually inspected, two full-size fetches failed, ten remain indexed only. Video sources were located, not watched frame by frame. No clip timestamps, durations, particle counts, exact frame rates, or engine internals are asserted without evidence. A single screenshot only verifies a visible phase, not an entire animation. Preserve attribution URLs; do not bundle third-party art, gameplay footage or ROMs into the game or repository.

For each reference move, identify original name and actual Kindria ID, isolate a clearly labeled cast, mark source timecodes and capture rate, then measure anticipation, origin socket, path, direction, extent in tiles, contact silhouette, secondary material, damage/reaction sync and fade. Record multiple targets, misses, and repeated strikes when available. Mark absent or ambiguous evidence rather than extrapolating from element. For original Kindria moves, use an explicitly named analog, never label them an exact recreation.

## Initial correction

Bug Buzz: replace generic insect swarm presentation with warm caster-centered acoustic rings and side sound flashes. Signal Beam: replace multicolor strands with a narrow blue tapered path and white leading sparkle. Use original procedural particles and existing pool. Preserve current gameplay and animation duration until video timing is measured. No claim of 1:1 fidelity is made. Existing V14 finish profiles remain available for other moves. Review real dungeon captures and Android frame pacing before accepting each move.

## V15.1 — contact and fire

Rechecked original Ember, Scratch, Peck and Sacred Fire stills. Sacred Fire is flagged as indirect capture by the archive. Use original 64px soft-alpha masks, compact orange Ember, blue Sacred Fire clouds, a white curved Scratch mark and a small directional golden Peck wedge. No exact timing claims; no global exposure alteration. The 1080p60 boss compilation is indexed, not frame-inspected. New runtime probes capture four actual dungeon phases and assert contact misses do not emit actor marks. The previous V15 Godot, Android plugin and dungeon probe workflows completed successfully.

## V15.2 — contact, psychic and solar

Five previously inspected reference stills inform revised effects (Air Cutter, Low Kick, Psychic, Psywave, Solar Beam). Four archive pages reopened; Air Cutter and Solar Beam page reload failed, so their existing observations were used without claiming new inspection. Quick Attack already belongs to the full tile travel route and receives a regression test, not a new inferred return timing. Solar Beam maps to eos_151 (Sunlance); charge and release effects are separate. Psychic uses a local tint and energy echoes, not an unverified full-screen or actor silhouette clone. All five effect timings remain engine approximations, no frame-level video timing verified.

## V15.3 — Sand Attack and source-quality gate

Confirmed Dust Flick (eos_142) is SAND_ATTACK in the original reference catalog. Based on the existing inspected Sand Attack still, replace generic particles with an original soft gray-beige dust cloud and a yellow downward glyph only when an accuracy-lowering effect is recorded. Environmental dust can remain on misses. Existing timing is not a measured DX timing. Growl and Hyper Beam archive pages were accessible, but image retrieval failed again; no visual changes were inferred. Hyper Beam is flagged as indirect capture. The DX list documents different PP and ranges for Growl and Hyper Beam; preserve Kindria's current balance and record differences for review. No new animation timing was verified from video.

## V15.4 — multiple confirmed impacts and temporal evidence

Hyper Beam research distinguishes standard 4-tile reach and local blast from gigantic 10-tile piercing variant. Sources: Bulbapedia Hyper Beam and Japanese pokemysdundx move list. No gameplay changes. Growl thumbnail and Hyper Beam full image retrieval failed; no new visual inference. Two additional gameplay sources indexed, not frame-inspected. Existing screenshot-grounded moves now give localized damage marks to up to five confirmed damaged tiles, including a secondary hit when primary misses. Ember and Sacred Fire use their distinct orange and blue contact palettes. The five-tile limit is Kindria's performance budget, not measured DX behavior.

New measure_capture.py uses ffprobe's actual decoded presentation timestamps, and manual stage labels to calculate milliseconds without assuming 30/60 fps. Run --self-test for synthetic verification. For real footage, provide --video local.mp4 --annotations labels.json --output local-measurement.json. The labels file requires source, move_id, and frames (cast_start, effect_end mandatory, other stages optional). Keep footage and outputs local; only verified observations and independently authored parameters belong in the repository. No real clip was acquired or measured in V15.4.

## V15.5 — consistent confirmed targets and additional still

Aurora Veil's archived 800x450 preview loaded: a pale wide veil and white/cyan glints; hail is active, so snow motes may be weather. No exact Kindria equivalent is assigned. Growl and Hyper Beam images failed retrieval again. Hyper Beam file caption names Rayquaza; the screenshot cannot establish the standard-size variant. No real clip timing obtained. Unified confirmed-cell selection for observed FX; Scratch, Peck, and Solar Beam now handle every confirmed damaged cell up to the existing five-target budget, with deterministic ordering and no effects for heal/status-only rows. New probe tests all three.

## V15.6 — continuous beam geometry and new references

Laser Focus and Precipice Blades preview images inspected; recorded visible shapes and caveats in evidence JSON. Neither is assigned an unrelated Kindria move ID. Precipice Blades is flagged indirect capture and shows a giant boss. Growl and Hyper Beam image requests failed. Additional full demo gameplay indexed only. Replaced discrete repeated stamps in Signal Beam and Solar Beam with continuous camera-facing original strips clipped to actual path length, including bends. This is a Kindria rendering correction based on previously observed narrow continuous rays, not a newly measured DX timing. Added long-path and clipped-segment regression tests; no video timing measured. Gameplay untouched.

## V15.7 — repair graphical regression gate

The V15.1 workflow run 46033373998 failed at effekseer_dungeon_probe.gd:582 after passing the preceding support checks. The legacy motion loop requires more than one particle for every attack, conflicting with the intentional single-wedge Peck renderer. The test now checks exactly one particle, exact original wedge texture and zero marks on miss for Peck, while retaining the legacy >1 condition for other moves. This is a test contract repair, not a change to the attack renderer. The graphical probe gets a 720-second limit because the cumulative suite grew. New run not yet certified. Smart Strike and Spotlight archive previews inspected and documented; Smart Strike screenshot also shows Tackle in the log, so individual spark attribution remains uncertain. Growl, Hyper Beam and Liquidation retrieval did not succeed. No real video timing measured.

## V15.8 — evidence ledger

Three more archived previews inspected: Stomping Tantrum, Tearful Look and Toxic Thread. Their actual visible phase is documented separately from any hypothetical animation; no exact current catalog match. Throat Chop preview and Liquidation page failed. Added a machine-checkable 589-ID ledger, generated from actual rules and observed renderer IDs. It distinguishes authored but unverified designs from still-grounded implementations and the existing Quick Attack route regression. 477 records have reference keys, which do not prove DX availability; 12 have still-grounded renderers, one has an existing route regression, and 576 have neither. Zero verified temporal measurements. CI now validates ledger freshness; no game effect or balance changes in this commit.
