# Rescue Team DX: verified public reverse-engineering findings

Reference: https://github.com/tech-ticks/DreamNexus (MIT), master tree 40699bd74f21f30a683630c3217b30e5b409eb5c. The editor is not the complete game source. The announced Unity decompilation has no public repository in the announcement examined: https://www.reddit.com/r/decomps/comments/1xbf1h0/pok%C3%A9mon_mystery_dungeon_rescue_team_dx_decompiled/

## Observed architecture
- WazaDataInfo.cs: 18-byte move entry, action index at 0x0c.
- ActDataInfo.cs: 160-byte action entry, four independent gameplay effect records, each with eight typed parameters; min/max accuracy, power and PP; category/type, range, area, target and hit-count index.
- ActEffectDataInfo.cs: 76-byte visual/audio record. ActionCollection.cs joins both action tables by index. Separate visual references for ally invocation, enemy invocation, caster, area, impact, projectile and projectile impact. Separate sound references for invocation (ally/enemy), initiation, impact and projectile launch.
- ChargedMoves.cs: 10-byte entries joining base move/action to final move/action. ActDataInfo comments identify Solar Beam's charge action 76 and release action 668.
- ActionController.Visuals.cs resolves the graphics and sound references using their respective symbol collections. RtdxRom.cs loads effect_symbol.bin as an ASCII SIR0 string list.
- Hyperbeam (https://github.com/tech-ticks/hyperbeam) exposes native IL2CPP integration headers. RTDXTools (https://github.com/tech-ticks/RTDXTools) contains Unity editor tooling and generated class stubs, not verified complete implementations.

## Kindria translation (proposal, not claims about DX runtime)
Use separate gameplay actions and presentation tracks. For each original move keep caster invocation, source socket, projectile, area, hit/miss confirmation, impact and recovery independent; optionally use distinct opponent invocation. Charged attacks should have separate charge and release track definitions. A material shared by two moves must not force identical choreography. Bind original meshes, shaders, particles and sound resources to each track. Do not assume undocumented fields represent duration, scale, placement or camera parameters.

## Data acquisition status
No extracted copy of DX or verified effect prefab/particle values is available in this project. The accompanying read-only tool accepts a user's own already-extracted data files and reports reference IDs and known fields. It neither extracts a ROM nor redistributes original artwork or data. Keep exported reference reports local; no claim of 1:1 timing or asset equivalence until independently inspected. Synthetic fixtures only until actual inputs are supplied.
