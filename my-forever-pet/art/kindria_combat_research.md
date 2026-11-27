# Kindria combat research and implementation
Public references (not copied game source):
- https://github.com/pret/pmd-red — community Red Rescue Team decompilation.
- https://github.com/UsernameFodder/damage-eos — community Explorers of Sky damage reimplementation.
- https://github.com/UsernameFodder/pmdsky-debug — documented structures.
- https://github.com/pret/pokeemerald — core-series Emerald decompilation.
- https://github.com/evandixon/Sky-Editor — PMD data tools.
- https://github.com/evandixon/SkyEditor.RomEditor.Rtdx — DX data tool, requires game files.
- https://bulbapedia.bulbagarden.net/wiki/Pok%C3%A9mon_battle_(Mystery_Dungeon)
- https://bulbapedia.bulbagarden.net/wiki/List_of_moves_by_range_in_the_Pok%C3%A9mon_Mystery_Dungeon_series
- https://bulbapedia.bulbagarden.net/wiki/Nature
- https://bulbapedia.bulbagarden.net/wiki/Effort_values
Original Kindria decisions: modern 18-type matchup chart with Explorers 1.4/0.7/0.5 multipliers, STAB 1.2; alternate classic chart 2/0.5/0 for testing. Dual affinities multiply. 25 standard nature combinations plus original Lazy (+defense/-speed). No IVs. EV earned by species, banked by stat, allocated manually, 252 per stat and 510 total. Successful expedition settlement only; no import of ROM assets or code. Mosky currently Grass, future species may have dual typing. Damage is an original bounded ratio model for existing small dungeon damage rather than an exact PMD formula. Speed stat is calculated but initiative/evasion behavior is deferred. Further balancing, ability hooks, nature care animations and other game-specific data remain future tasks.
