# BISHAMON and Effekseer feasibility
Verified public references, not recovered original BMB assets or game source.

RTDXTools generated stubs: https://github.com/tech-ticks/RTDXTools/tree/master/Assets/Scripts/Stubs/Generated/Assembly-CSharp
- BishamonEffect declares BMB, texture/model references, referenced effects, playback clock, transforms and child generation scaling.
- effect/DataInfo declares effect/attachment identifiers, three sound cues and three script cues with frame values, two user data cues, size/offset and looping.
- effect/PlacementType declares anatomical and camera anchors.
- BMEffectScript declares environment/light color changes and dungeon shake.
- EffectViewerCtrl declares effect selection and playback.
These are metadata declarations, not executable bodies. ActCommandSystem is not verified to be the dungeon combat scheduler.

MATCHLOCK manual: https://www.matchlock.co.jp/en/manual/
Hierarchical null nodes, quads, billboards, models and stripes are supported. BMB is a compiled proprietary format. No verified public DX BMB catalogue or compatible converter was located.

Effekseer: https://github.com/effekseer/EffekseerForGodot4
Release notes: https://effekseer.github.io/Help_Godot/v4/en/history.html
Kindria CI uses Godot 4.4.1, gl_compatibility. Pin 1.70e.10 (4.4 baseline), not 1.80.2+ (4.6 baseline). A separate CI spike will load official sample effects and verify render output with the same GL renderer, plus inspect the Android ARM64 binary. A Linux GL result does not prove Android playback or performance. No dependency is installed into the production game and no sample assets are redistributed in our game.
