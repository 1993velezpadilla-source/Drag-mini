# Combat Lab execution audit
- 468 EoS-derived prototypes, 54 original learnable moves, 67 original DEV-only enemy/basic adaptations = 589 entries.
- All display records include effective runtime power, PP, accuracy gates, crit, range and strike counts. Default values are from the existing runtime, not invented EoS records.
- The 67 original adaptations use 6 + existing enemy damage modifier (minimum 1), existing enemy PP caps 12/10, existing category, geometry and element. Basic Strike is free. Effects are player-side interpretations of enemy behaviors, not EoS equivalents and not part of player learnsets.
- FX only is explicit. Rejected gameplay casts show the reason and do not silently become animations.
- Audit executes each ID on an isolated generic target, records outcomes; condition-dependent failures are not proof of a bug or proof of fidelity. Dedicated fixtures and individual EoS rules/visual verification remain required.
- References: https://mysterydungeonwiki.com/wiki/Explorers_of_Sky:List_of_Moves ; https://github.com/UsernameFodder/damage-eos ; https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_battle_(Mystery_Dungeon).

## Body-travel presentation
Fly, Bounce, Dig and other explicitly classified body-travel attacks follow their resolved tile path to the target at impact, then retrace it while facing the original tile. This is a presentation-only displacement; no extra turns, loot or permanent player relocation. Underground/vanish moves hide during approach and reappear at impact; aerial moves have vertical arcs. Ranged projectiles stay at the caster. New visual regression covers 32 direction/move combinations and captures impact/return. This is an original presentation decision; exact EoS animation parity is not yet verified.

## Execution audit follow-up
Actual run 46009724821: 589 entries attempted, 587 accepted, 2 sleep-reactive prerequisites rejected, 67 native damage paths exercised. A single seed produced 64 zero-damage positive-power cases (misses/conditions not yet differentiated). This pass stages the two sleep-reactive prerequisites through the actual reactive dispatcher in DEV only, snapshots the player outcome before enemy turns overwrite it, and retries zero-damage entries under seven additional seeds. It adds pooled floor-aligned Dig holes, soil debris, Fly/Bounce air trails/landing rings, and charge-phase particles. No claim of exact EoS parity or final visual approval.
