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
	var front:=Art.enemy_pixel_cell("coralcrab",0,"idle")
	var rear:=Art.enemy_pixel_cell("coralcrab",1,"idle")
	var left:=Art.enemy_pixel_cell("coralcrab",2,"idle")
	var right:=Art.enemy_pixel_cell("coralcrab",3,"idle")
	assert(front.get_used_rect()!=rear.get_used_rect())
	assert(front.get_used_rect()!=right.get_used_rect())
	assert(left.get_data()!=right.get_data())
	assert(Art.enemy_pixel_cell("coralcrab",3,"attack",0).get_data()!=Art.enemy_pixel_cell("coralcrab",3,"attack",1).get_data())
	assert(Art.enemy_asset_cell("unapproved_missing_species",0,"idle",0)==null)
	print("VOLNOX_CRAB_DIRECTIONAL_PASS")
	print("VOLNOX_2D_PIXEL_PILOT_PASS 3")
	quit()
