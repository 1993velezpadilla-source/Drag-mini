extends SceneTree
const Art=preload("res://pixel_pet_art.gd")
const Parts=preload("res://pet_part_rig.gd")
const Fx=preload("res://pet_external_fx.gd")
func _initialize():
	assert(Parts.mood(2,90,5,0)=="sad")
	assert(Parts.mood(9,5,5,0)=="weak")
	assert(Parts.mood(9,90,5,1)=="sick")
	for dir in range(4):
		var calm:=Art.authored_cell(dir,"idle",0,"healthy")
		var weak:=Art.authored_cell(dir,"idle",0,"weak")
		assert(calm.get_data()!=weak.get_data())
	for id in ["spirit-flame","fire-breath","heart-pickup","bubbles","heal"]:
		var clip:=Fx.clip(id)
		assert(not clip.is_empty(),"imported effect "+id)
		assert(clip.frames.size()>1)
		assert(Fx.frame(id,0)!=Fx.frame(id,.2))
	var sheet:=Image.create(128,256,false,Image.FORMAT_RGBA8)
	sheet.fill(Color.WHITE)
	var part:=Parts.lpc_frame(sheet,3,1)
	assert(part!=null and part.get_size()==Vector2i(64,64))
	print("PET_ANIMATION_LIBRARY_PASS")
	quit()
