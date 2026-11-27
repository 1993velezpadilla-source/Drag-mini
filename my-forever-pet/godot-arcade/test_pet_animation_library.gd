extends SceneTree
const Art=preload("res://pixel_pet_art.gd")
const Parts=preload("res://pet_part_rig.gd")
const Fx=preload("res://pet_external_fx.gd")
func _initialize():
	assert(Parts.mood(2,90,5,0)=="sad")
	assert(Parts.mood(9,5,5,0)=="weak")
	assert(Parts.mood(9,90,5,1)=="sick")
	for dir in range(8):
		var calm:=Art.authored_cell(dir,"idle",0,"healthy")
		var weak:=Art.authored_cell(dir,"idle",0,"weak")
		assert(calm.get_data()!=weak.get_data())
	assert(Art.editable_atlas().get_size()==Vector2i(480,384))
	for i in range(8):
		var direction:=Vector2.from_angle(float(i)*PI*.25)
		var dir:int=Art.direction8_for(direction)
		assert(dir==[3,4,0,5,2,7,1,6][i])
		assert(Art.authored_cell(dir,"walk",1).get_data()!=Art.authored_cell(dir,"walk",3).get_data())
	assert(Art.editable_atlas(true).get_size()==Vector2i(672,384))
	for dir in range(4,8):
		var idle:=Art.authored_cell(dir,"idle",0)
		assert(idle.get_used_rect().has_area())
		for pose in ["attack","hurt","recover","defeat","cast"]:
			var frame:=Art.authored_cell(dir,pose,1 if pose=="attack" else 0)
			assert(frame.get_used_rect().has_area() and frame.get_data()!=idle.get_data(),"distinct diagonal "+pose)
		assert(Art.authored_cell(dir,"attack",0).get_data()!=Art.authored_cell(dir,"attack",1).get_data())
	# Rear and front diagonals must not be a shifted cardinal or one another.
	for dir in range(4,8):
		var cell:=Art.authored_cell(dir,"idle",0)
		for other in range(8):
			if other!=dir:assert(cell.get_data()!=Art.authored_cell(other,"idle",0).get_data())
	# Art identity guard: identical cardinal palette families, similar solid
	# silhouette area, original 48px cell and ground anchor.
	for dir in range(4,8):
		var diagonal:=Art.authored_cell(dir,"idle",0)
		var cardinal:=Art.authored_cell(0 if dir<6 else 1,"idle",0)
		var palette:Dictionary={}
		var cardinal_area:int=0
		var diagonal_area:int=0
		for y in range(48):
			for x in range(48):
				var pixel:=cardinal.get_pixel(x,y)
				if pixel.a>0:
					palette[pixel.to_rgba32()]=true
					cardinal_area+=1
		for y in range(48):
			for x in range(48):
				var pixel:=diagonal.get_pixel(x,y)
				if pixel.a>0:
					assert(palette.has(pixel.to_rgba32()),"original cardinal palette only")
					diagonal_area+=1
		assert(absf(float(diagonal_area)/float(cardinal_area)-1.0)<.18,"preserve round silhouette volume")
		assert(absi(diagonal.get_used_rect().end.y-cardinal.get_used_rect().end.y)<=2,"same floor anchor")
	# Android visual regression: the unmirrored rear silhouette reads NW,
	# and the reflected rear silhouette reads NE. Test every pose/frame.
	var poses:Array=["idle","walk","walk","walk","walk","attack","attack","blink","sleep","eat","hurt","recover","defeat","cast"]
	var frames:Array=[0,0,1,2,3,0,1,0,0,0,0,0,0,0]
	var strides:Array=[0,0,2,0,-2,2,-2,0,0,0,0,-1,0,1]
	for k in range(poses.size()):
		var nw:=Art.mosskit_diagonal(true,int(strides[k]),str(poses[k]),"healthy",int(frames[k]))
		var ne:=nw.duplicate() as Image
		ne.flip_x()
		assert(Art.authored_cell(7,poses[k],frames[k]).get_data()==nw.get_data(),"NW rear art orientation")
		assert(Art.authored_cell(6,poses[k],frames[k]).get_data()==ne.get_data(),"NE rear art orientation")
		assert(Art.direction8_for(Vector2(-1,-1))==7 and Art.direction8_for(Vector2(1,-1))==6)
	print("PONOKO_REAR_DIAGONAL_ORIENTATION_PASS 28")
	print("PONOKO_CARDINAL_IDENTITY_PASS 4")
	print("PONOKO_DIAGONAL_POSES_PASS 4")
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
