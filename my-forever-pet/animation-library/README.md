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
