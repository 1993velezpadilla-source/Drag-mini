# Reusable creature animation library
Only Mosky remains playable. LPC anatomy uses independently layered 64px sprites,
four directional rows for idle and walk; hurt is a one-row strip. The imported
parts remain authoring assets, not active pets. Adapt pivots per creature.
PixelFX uses pinned upstream MIT code to bake transparent spirit flame, fire breath,
heart pickup, bubbles and heal sprites in CI; no runtime third-party code.
Reward and affection use heart pickup; other effects are reserved for future
species. Retain the MIT license file. Godot Skeleton2D, Bone2D, AnimationPlayer and
SpriteFrames are compatible authoring paths for non-pixel rigs baked to atlases.
Mosky's native mood variants use the original silhouette, with lowered ears
and tail when weak/sad/sick; those are our own adaptation, not imported artwork.

## Slot animation contract (iteration 61)
Existing LPC 64px strips remain the source of reusable anatomical art; this change introduces pose/mood clip selection, independent slot frame counts, loop versus one-shot playback, directional/mood offsets and back/body/front composition. Missing artwork uses the existing supplied slot strip, not generated replacement anatomy. Four-direction and layering tests use synthetic color fixtures solely to validate the contract. Production LPC assets still require per-species pivot fitting and visual approval before attaching them to Mosky; its approved skin and Pet Dash remain unchanged. CI for the new contract is pending.

## Iteration 62: upstream anatomy import pilot
Pinned Universal LPC generator commit 86a3719ee4a7e2e9fb27c7c152e29a741d3e930a. Verified source definitions for cat and wolf tails (JaidynReiman, CC-BY 3.0+ option) and bat/feathered wings (ElizaWy, JaidynReiman, feathered also Stephen Challener/Redshrike; OGA-BY 3.0). CI imports original idle, walk, slash, spellcast, hurt and jump front/back PNGs, validates frame geometry, records SHA256 and credits, and creates raw-part contact sheets. These are review artifacts only, not shipping assets; preserve license notices and review pivots before any runtime integration. No Mosky art changes. New importer run pending.
