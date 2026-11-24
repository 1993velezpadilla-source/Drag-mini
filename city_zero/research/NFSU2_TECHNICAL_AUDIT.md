# City Zero — NFS Underground 2 vehicle systems reverse-engineering dossier
**As-of:** 2026-11-24  
**Scope:** public source-code/document research, specifically the modded browser fork and the original game/interop ecosystem.  
**Evidence labels:** VERIFIED_SOURCE = directly in linked source; AUTHOR_STATEMENT = author-associated public statement; REPORTED = independently reported; UNTESTED = no actual live runtime verification.

## 1. Provenance: do not merge different projects
- **Target:** https://nfsu2mod.xyz/ (fan-operated browser game; not synonymous with https://nfsu2.xyz/).
- **Maintainer's launch post:** https://www.reddit.com/r/NFSU2/comments/1xiuj53/nfsu2xyz_but_with_addons/ . AUTHOR_STATEMENT: the site was built using https://github.com/th0mk/nfsu2-web, added cars, enhanced customization, free roam, and server chat.
- **Maintainer-associated source:** https://github.com/DJSN4KE/nfsu2mod-tools . VERIFIED_SOURCE: save conversion from this specific modded site's profiles to original PC v1.2. It documents stock vs added car identities and part hashes, **not** the full current proprietary site runtime.
- **Upstream browser source:** https://github.com/th0mk/nfsu2-web . VERIFIED_SOURCE: native x86-to-C recompile to WebAssembly, WebGPU replacing Direct3D 9, Web Audio and Rust multiplayer server. Archived; development went private 2026-11-09. Do not assume subsequent live changes are public.
- **Recompiler:** https://github.com/TalhaMudo/NFSU2Recomp . Upstream independent technical work.
- Source-based roster: [nfsu2mod_car_roster.json](nfsu2mod_car_roster.json). **31 stock player car IDs, 39 added IDs, 15 traffic IDs** in the retrieved author-associated tool snapshot. Later posts advertise 47 additions. **Eight not identified from the snapshot; do not invent them.**
- Runtime browser probe exists at tools/nfsu2_browser_probe.mjs. A CI configuration exists, but **do not mark live gameplay or screenshots verified until an actual job log and capture prove they worked**. Browser denial / network restrictions are separate from game engine findings.

## 2. Original car data structure
According to https://nfsmodderscorner.blogspot.com/p/need-for-speed-underground-2.html and the independent https://github.com/whoismept/OpenUG2/blob/main/docs/FORMATS.md:
\`\`\`
GAME_ROOT/
  CARS/XNAME/
    GEOMETRY.BIN          # named model parts and LODs
    TEXTURES.BIN          # body, lights, windows, audio and trim texture packs
    VINYLS.BIN            # optional, car-specific UV decals
    PARTS_ANIMATIONS.BIN  # optional, hood/doors/trunk and split-hood pivots + animation
  CARS/WHEELS/...         # generic aftermarket wheel meshes
  GLOBAL/GLOBALB.BUN or GlobalB.lzc
                          # CarTypeInfo, DBModelParts, position/wheel/performance/part metadata
  FRONTEND/FRONTB.LZC    # maker/model branding and menu resources
  LANGUAGES/*.BIN        # strings
\`\`\`
Alternative codebase https://github.com/mininxd/NFSU2-World-Editor imports a stock car into Blender from real GEOMETRY.BIN + TEXTURES.BIN, assembling KIT00/BASE and wheels with axle information from GLOBALB. Coordinates are **Z-up** in the original and retained for its Blender importer. It supports no-edit byte-identical geometry roundtrip. It does not automatically provide all aftermarket variants or make redistribution rights appear.
Alternative extraction https://github.com/bdrtr/PryHUB outputs .glb / .obj / PNG from a legally owned installation, including parser handling for compressed formats. Both are tools, not bundled copyrighted models.

## 3. Real interchangeable geometry naming: independent slots
Examples grounded in actual modding documentation and Unlimiter:
- \`X_KIT00_BODY_A\`, \`X_KIT00_FRONT_BUMPER_A\`, \`X_KIT00_REAR_BUMPER_A\`, \`X_KIT00_SKIRT_A\`.
- \`X_KIT00_HOOD_A\`, \`X_KIT00_HOOD_UNDER_A\`, \`X_KIT00_TRUNK_A\`, \`X_KIT00_TRUNK_UNDER_A\`.
- \`X_KIT00_ENGINE_A\`, \`X_KIT00_DOOR_LEFT_A\`, \`X_KIT00_DOOR_RIGHT_A\`.
- \`X_KIT00_HEADLIGHT_LEFT_A\`, \`X_KIT00_BRAKELIGHT_A\`, \`X_KIT00_SPOILER_A\`.
- \`X_KIT00_TRUNK_AUDIO_A\`, \`X_KIT01_TRUNK_AUDIO_A\`, \`X_KIT02_TRUNK_AUDIO_A\`, \`X_KIT03_TRUNK_AUDIO_A\`.
- LOD suffixes A/B/C/(D) denote alternative detailed meshes, not driving directions.
- \`KITWxx\` represents widebody overrides; \`STYLExx\` replaces individual style families.
- Mod-compatible vehicle configuration must be keyed by **vehicle xname + slot + compatible part family**, not merely by mesh name or universal index. Part names/hashes and source mesh ownership matter; missing parts must remain unavailable, not borrow unrelated car parts silently.

References: https://github.com/nlgxzef/NFSU2Unlimiter/blob/master/UnlimiterData/_General.ini ,
https://nfsmodderscorner.blogspot.com/p/need-for-speed-underground-2.html ,
https://github.com/kateusz/OpenUG2-R36S/blob/main/docs/VEHICLE_CUSTOMIZATION.md .

## 4. Animated bonnets, hoods, doors and trunk
- \`PARTS_ANIMATIONS.BIN\` is the source animation family. Public MIT-licensed editing code: https://github.com/TVasya/PartAnimatorulator . It supports hinge pivot positions, rotations, car xname/hashes and interpolated animation frames; **this is source reference, not a license to include EA binary animations**.
- Distinct documented pivot identifiers include:
  \`_ZAM_HOOD_REG\`, \`_ZAM_HOOD_FRONT\`, \`_ZAM_LEFT_HOOD_SPLIT\`, \`_ZAM_RIGHT_HOOD_SPLIT\`, \`_ZAM_FRONT_HOOD_SPLIT\`, \`_ZAM_BACK_HOOD_SPLIT\`, \`_ZAM_LEFT_DOOR_REG\`, \`_ZAM_RIGHT_DOOR_REG\`, \`_ZAM_LEFT_DOOR_SCISSOR\`, \`_ZAM_RIGHT_DOOR_SCISSOR\`, \`_ZAM_LEFT_DOOR_SUICIDE\`, \`_ZAM_RIGHT_DOOR_SUICIDE\`, \`_ZAM_TRUNK_REG\`. There are additional widebody door pivots.
- Split hoods have a rotated pivot compensated by their original animation; for City Zero, author pivot/origin in Blender and export as named Godot Node3D transform; **never just rotate the whole car roof**.
- Mount door panels, spoiler and rear license plate to appropriate moving parent. Unlimiter's \`LinkLicensePlateToTrunk\`, \`LinkRearWindowDecalToTrunk\` and \`LinkSpoiler\` prove these relationships must be configured per car.
- In upstream web free roam, parked \`O\`/controller D-pad toggles opens hood, trunk and doors; nearby peers see opening and internal items. See https://github.com/th0mk/nfsu2-web/blob/main/CHANGELOG.md (2026-11-05) and https://github.com/th0mk/nfsu2-web/blob/main/docs/web/PLAYING.md .
- In an independent renderer, treat hood/trunk open state (including transition) as affecting visibility of \`HOOD_UNDER\`, \`TRUNK_UNDER\` and attached lighting; an Unlimiter code path explicitly reads hood animation location index 0 and trunk location index 1: https://github.com/nlgxzef/NFSU2Unlimiter/blob/master/CarRenderInfo.h .

## 5. Trunk audio subsystem: source-based attachment system
**This is NOT a static decoration painted on the hatch.** The real part names include a layout (\`KITxx_TRUNK_AUDIO\`) and an unlit variant. CarToolkit documents:
- \`MARKER_AUDIO_COMP_0\` to \`MARKER_AUDIO_COMP_11\` (twelve named component mount points).
- \`MARKER_TRUNK_NEON_START_0\` through \`_3\` and matching \`END_0\` through \`_3\`.
- Additional engine and cabin neon START/END attachment markers.
- Material family \`AUDIO_SKIN\` and \`TRUNK_AUDIO_UNLIT\` model naming.
- \`TrunkAudio = 1\` belongs to Car Specialties, with \`X_KITxx_TRUNK_AUDIO\` and separately configurable \`TrunkPaint\`, \`TrunkNeon\`.
- Source-code attribute \`SHOWTRUNK\` can enable showing audio through a custom trunk. Renderer must apply an explicit visibility policy, not hardwire “hidden unless open” for every car.
- Most original retail audio components were a **visual customization**. City Zero's functional positional music playback, amplifier gain and subwoofer animation are **new City Zero implementation goals**, not an existing NFSU2 behavior to misrepresent.
- Audio components can be speaker, amplifier, subwoofer, screen, and decorative NOS installation; exact attachment compatibility is per layout and installed parts list. Do not invent all slot-to-product mappings.

## 6. Materials, decals, wheels, LOD and physics
- CARSKIN/body paint uses UV/material masks; paint should not recolor rubber, brakes, glass, chrome, or backing wheel geometry.
- Headlights / brakelights have dynamic ON/OFF and sometimes glass variants; source https://github.com/chrystianfarias/NFSU2Unity/blob/main/docs/formats/cartypeinfo-and-parts.md .
- VINYLS.BIN texture keys are **car specific**, so another car's vinyl atlas cannot be blindly pasted onto a different UV body. The OpenUG2 docs describe layered vinyl texturing and currently incomplete selection.
- Independent front/rear bumpers, side skirts, full body kits, spoiler, mirrors, headlights, exhaust, wheels and roof; split hood and specialty categories are separate.
- Wheel fit includes real wheel anchors, rim size, width, offset and camber. Never scale entire car to resize wheels; vehicle geometry, material, and physics are separate transactions.
- NFSU2 source LOD types are not rotation sprites. Real 3D Godot models should support arbitrary camera directions.
- A single visible car may have many model/material variants, but do not load every full-resolution body kit into the GPU at once on Android. Use residency, streaming, LOD and source-based performance measurements.

## 7. Modern 3D migration pipeline for City Zero
1. Obtain **licensed or self-created meshes** for commercial redistribution. If studying a personal NFSU2 install, keep its original assets private. Never commit original game meshes, archive payloads, textures, saves, fonts or soundbanks into City Zero.
2. Use **NFSU2-World-Editor** and/or **PryHUB** on the user's *own* game for references and interoperability testing, not as a game asset delivery network.
3. In Blender inspect silhouette, wheelbase, axles, body proportions, lighting, doors/trunk gaps, engine and interior. Separate named meshes; assign pivots/attachment nodes and materials. All hoods, trunks and wheels must appear physically connected when closed.
4. Export Godot-friendly glTF 2.0 \`.glb\` with named nodes. Do not trust an apparently successful export: validate node, mesh, poly and attachment coverage with \`tools/cityzero_vehicle_inventory.py\` (this repo).
5. Import into Godot 4.6. Scene tree: \`VehicleBody\`; \`HoodPivot\`; \`TrunkPivot\` with \`TrunkAudioLayout\` and audio component sockets; \`DoorLeftPivot\`; \`DoorRightPivot\`; independent wheel and suspension nodes, light emission meshes.
6. Runtime supports opening closed/open/animating states; switching compatible parts, stock reset, saved configurations and explicit rollback if replacement assets are missing.
7. For multiplayer send **car xname, part IDs, hinge states, chosen layout and component IDs**; not proprietary mesh data. Nearby peers perform their own rendering. Keep network payload bounded, validate ranges/server ownership, do not trust client price/unlock flags.
8. Benchmark on actual Android hardware for vehicle triangle count, material count, GPU memory, animation cost, draw calls and frame pacing while opening trunks and rendering multiple cars.

## 8. Explicit acceptance criteria
- [ ] Vehicle geometry matches a checked real-car photographic reference; documented model provenance and permission.
- [ ] Full 360-degree view, physically plausible wheel placement, four mounted wheel meshes with correct steer/spin pivots.
- [ ] Stock + at least two independently swappable compatible bumpers, wheel/rim sets and spoilers without full vehicle reinstantiate.
- [ ] Bonnet opens smoothly on correct pivot; engine and underside revealed; no body clipping.
- [ ] Trunk opens smoothly on correct pivot; correctly seated audio box, 1+ speaker and amplifier, trunk light/neon visible.
- [ ] Audio layouts expose explicit sockets \`MARKER_AUDIO_COMP_0..11\`; incompatible components cannot mount.
- [ ] Every item can be previewed, installed, removed, stock restored, saved and loaded without losing the car.
- [ ] Headlights/brakes dynamically change only their own materials.
- [ ] Multiplayer sees the exact same body/parts/hinge state.
- [ ] Actual Android visual screenshots **and** per-frame timing capture pass adversarial review. Headless unit tests alone do not prove visual fidelity.

## 9. Remaining evidence gates
- **Live modded fork runtime:** request logs and screenshots from an actual successful Chromium/GitHub Actions job. Do not claim current car count, live UI state or FPS from source docs alone.
- **Exact current 47 additions:** only 39 named from the author-associated save-revert source snapshot; reconcile against site's current credits/saves when accessible.
- **Licensed production 3D assets:** choose/commission independently licensed OEM-accurate meshes; public code and NFSU2 files do not grant car-model rights.
- **Real-world fit specs:** independently confirm each car's wheelbase/track and panel dimensions; do not derive from another model's placeholder shape.

## Source registry
- https://github.com/DJSN4KE/nfsu2mod-tools
- https://www.reddit.com/r/NFSU2/comments/1xiuj53/nfsu2xyz_but_with_addons/
- https://github.com/th0mk/nfsu2-web
- https://github.com/TalhaMudo/NFSU2Recomp
- https://github.com/whoismept/OpenUG2
- https://github.com/kateusz/OpenUG2-R36S/blob/main/docs/VEHICLE_CUSTOMIZATION.md
- https://github.com/nlgxzef/NFSU2Unlimiter
- https://github.com/TVasya/PartAnimatorulator
- https://github.com/mininxd/NFSU2-World-Editor
- https://github.com/bdrtr/PryHUB
- https://github.com/pauliquib/nfsu2-addcars
- https://github.com/chrystianfarias/NFSU2Unity
- https://nfsmodderscorner.blogspot.com/p/need-for-speed-underground-2.html


## 10. Struct-level original render data (verified source, not live-site dump)

The public [NFSU2Unlimiter CarRenderInfo.h](https://github.com/nlgxzef/NFSU2Unlimiter/blob/master/CarRenderInfo.h) retains an offset-checked original 32-bit render structure. High-value fields for an interoperable architecture:

| NFSU2 render field | Original relative offset | Implication for City Zero |
|---|---:|---|
| \`mCarPartModels[63][2][4]\` | \`0x17A8\` | Many independent named part slots, each with multiple pieces and up to four LODs; treat parts as separate mesh resources |
| \`TrunkAudioModels[2][4]\` | \`0x21B4\` | Base trunk layout has distinct model pieces and LODs |
| \`TrunkAudioCompModels[12][2][4]\` | \`0x2274\` | Twelve speaker/amplifier component attachment slots with distinct pieces and LODs |
| \`TrunkAudioEmptyModels[3][2]\` | \`0x2B74\` | Multiple appearance/empty configurations; don't permanently bake a single box into trunk mesh |
| \`LightMaterial_Audio\` | \`0x039C\` | Trunk audio has separately material-controlled surface and color |
| \`TrunkNeonColour\` | \`0x0374\` | Trunk neon has independent color state |
| \`TrunkNeonMarkers\` | \`0x2CF8\` | Dedicated lighting marker chain, independent of underglow and cabin neon |
| \`WheelYRenderOffset[4][2]\` | \`0x0400\` | Separate wheel position compensation for normal vs widebody |
| \`WheelWidths[4]\` | \`0x0420\` | Wheel fit is a per-wheel dimension, not body-wide scaling |
| \`TheCarPartCuller\` | \`0x2D60\` | Part visibility/culling is explicit; interior/undersides require state-aware rendering |

The original engine's byte offsets are **documentation only** and must NOT be hard-coded into the Godot replacement. City Zero's representation is a typed scene tree and compatibility catalog. This evidence confirms that speaker layouts are structured 3D resources, not an “audio decal.” A model naming convention doesn't provide the licensed component mesh itself.

## 11. Implemented City Zero source files (status: committed, not blanket runtime-certified)

- \`city_zero/vehicle_runtime/CityZeroModularVehicle.gd\`: hood/trunk/door articulated pivots, stock reset, compatible part scenes, speaker sockets, state IDs.
- \`city_zero/vehicle_runtime/CityZeroTrunkAudio.gd\`: independent per-car 3D audio stream bus, spectrum analyser, subtle speaker-cone motion, no bundled copyrighted music.
- \`city_zero/vehicle_runtime/CityZeroShowroom.gd\`: 3D garage with actual imported licensed GLB and original animation-clip controls, touch orbit and two-finger pinch zoom.
- \`city_zero/scenes/vehicle_showroom.tscn\`: launchable Godot scene, external CC0 GLB must first be obtained via the CI workflow.
- \`city_zero/vehicle_runtime/test_modular_vehicle.gd\`, \`test_trunk_audio.gd\`, \`test_cc0_model.gd\`: headless and rendering probes.
- \`.github/workflows/cityzero-real-car-reference.yml\`: downloads CC0 asset, validates glTF binary and node geometry, imports in Godot and attempts a real PNG capture.
- All code is to be treated as **candidate implementation** until exact GitHub Actions tests, visual screenshots and actual Android play tests pass. The game is not yet a finished online vehicle system.
