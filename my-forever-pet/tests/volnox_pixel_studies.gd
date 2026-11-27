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
			assert(first.get_used_rect().has_area())
	var front:=Art.enemy_pixel_cell("coralcrab",0,"idle")
	var rear:=Art.enemy_pixel_cell("coralcrab",1,"idle")
	var left:=Art.enemy_pixel_cell("coralcrab",2,"idle")
	var right:=Art.enemy_pixel_cell("coralcrab",3,"idle")
	assert(front.get_used_rect()!=rear.get_used_rect())
	assert(front.get_used_rect()!=right.get_used_rect())
	assert(left.get_data()!=right.get_data())
	assert(Art.enemy_pixel_cell("coralcrab",3,"attack",0).get_data()!=Art.enemy_pixel_cell("coralcrab",3,"attack",1).get_data())
	assert(Art.enemy_asset_cell("unapproved_missing_species",0,"idle",0)==null)
	# Body colors must come from the biome, not the faction accent.
	for pair in [["sporeling","#64783a"],["coralcrab","#30888c"],["nova_wisp","#34376e"]]:
		var cell:=Art.enemy_pixel_cell(str(pair[0]),0,"idle")
		var expected:=Color(str(pair[1]))
		var count:int=0
		for y in range(48):
			for x in range(48):
				if cell.get_pixel(x,y).to_rgba32()==expected.to_rgba32():count+=1
		assert(count>=10,"missing biome body palette: "+str(pair[0]))
	print("VOLNOX_BIOME_PALETTE_PASS 3")
	print("VOLNOX_CRAB_DIRECTIONAL_PASS")
	print("VOLNOX_2D_PIXEL_PILOT_PASS 15")
	quit()
