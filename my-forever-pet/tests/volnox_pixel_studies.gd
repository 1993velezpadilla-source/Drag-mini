extends SceneTree
const Art=preload("res://pixel_pet_art.gd")
func _initialize():
	assert(Art.ENEMY_PIXEL_PILOTS.size()==33)
	for id in Art.ENEMY_PIXEL_PILOTS:
		var sheet:=Art.enemy_pixel_atlas(id)
		assert(sheet.get_size()==Vector2i(528,192))
		assert(sheet.save_png("/tmp/"+id+"-pixel-atlas.png")==OK)
		for dir in range(4):
			var first:=Art.enemy_pixel_cell(id,dir,"walk",1)
			var second:=Art.enemy_pixel_cell(id,dir,"walk",3)
			assert(first.get_data()!=second.get_data(),id+" walk direction "+str(dir))
			assert(first.get_pixel(0,0).a==0.0)
			assert(first.get_used_rect().has_area())
			var idle:=Art.enemy_pixel_cell(id,dir,"idle")
			var defeat:=Art.enemy_pixel_cell(id,dir,"defeat")
			assert(defeat.get_used_rect().has_area() and idle.get_data()!=defeat.get_data(),id+" defeat direction "+str(dir))
	for id in ["vinesnap","marrowray","thornbeetle","comet_hare"]:
		var views:Array=[]
		for dir in range(4):
			var idle:=Art.enemy_pixel_cell(id,dir,"idle")
			assert(idle.get_used_rect().size.x>=22,id+" narrow profile "+str(dir))
			assert(idle.get_used_rect().size.y>=22,id+" flat profile "+str(dir))
			assert(not views.has(idle.get_data()),id+" duplicate orientation")
			views.append(idle.get_data())
		var a:=Art.enemy_pixel_cell(id,3,"windup")
		var b:=Art.enemy_pixel_cell(id,3,"attack",1)
		assert(a.get_data()!=b.get_data(),id+" attack silhouette")
	print("VOLNOX_REDESIGN_DIRECTION_PASS 4")
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
	print("VOLNOX_2D_PIXEL_PILOT_PASS 33")
	quit()
