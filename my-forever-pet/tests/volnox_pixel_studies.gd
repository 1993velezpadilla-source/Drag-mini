extends SceneTree
const Art=preload("res://pixel_pet_art.gd")
func _initialize():
	for id in Art.ENEMY_PIXEL_PILOTS:
		var sheet:=Art.enemy_pixel_atlas(id)
		assert(sheet.get_size()==Vector2i(528,192))
		assert(sheet.save_png("/tmp/"+id+"-pixel-atlas.png")==OK)
		for dir in range(4):
			var first:=Art.enemy_pixel_cell(id,dir,"walk",1)
			var second:=Art.enemy_pixel_cell(id,dir,"walk",3)
			assert(first.get_data()!=second.get_data())
			assert(first.get_pixel(0,0).a==0.0)
	print("VOLNOX_2D_PIXEL_PILOT_PASS 3")
	quit()
