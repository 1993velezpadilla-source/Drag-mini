extends SceneTree
const Art=preload("res://pixel_pet_art.gd")
func _initialize():
	var atlas:=Art.editable_atlas()
	assert(atlas.get_size()==Vector2i(480,384))
	assert(atlas.save_png("/tmp/mosky-sprite-atlas.png")==OK)
	print("MOSKY_EDITABLE_ATLAS_PASS 8 directions 10 cells")
	quit()
