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
