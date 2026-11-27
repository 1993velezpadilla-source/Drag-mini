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
