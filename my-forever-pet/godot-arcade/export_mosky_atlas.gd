extends SceneTree
const Art=preload("res://pixel_pet_art.gd")
func _initialize():
	var atlas:=Art.editable_atlas()
	assert(atlas.get_size()==Vector2i(480,384))
	assert(atlas.save_png("/tmp/mosky-sprite-atlas.png")==OK)
	var combat:=Art.editable_atlas(true)
	assert(combat.get_size()==Vector2i(672,384))
	assert(combat.save_png("/tmp/ponoko-combat-atlas.png")==OK)
	print("MOSKY_EDITABLE_ATLAS_PASS 8 directions 10 cells")
	print("PONOKO_COMBAT_ATLAS_PASS 8 directions 14 cells")
	quit()
