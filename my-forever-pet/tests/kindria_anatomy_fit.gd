extends SceneTree
const Art=preload("res://pixel_pet_art.gd")
const Parts=preload("res://pet_part_rig.gd")
const ROOT="/tmp/kindria-lpc"
const POSES=["idle","walk","attack","cast","hurt","jump"]
const CANDIDATES=[["mosky","cat_tail","tail",32],["bramble_pup","wolf_tail","tail",32],["nebulwing","bat_wings","wing_left",40],["sylphowl","feathered_wings","wing_left",40]]
func _initialize():
	call_deferred("run")

func base_cell(id:String,dir:int,pose:String,frame:int)->Image:
	var body_pose:String="attack" if pose in ["attack","cast"] else "walk" if pose in ["walk","jump"] else "idle" if id=="mosky" else pose
	var index:int=frame%2 if body_pose=="attack" else frame
	return Art.authored_cell(dir,body_pose,index,"healthy") if id=="mosky" else Art.enemy_asset_cell(id,dir,body_pose,index)

func run()->void:
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"/manifest.json"))
	var reports:Array=[]
	var failures:Array[String]=[]
	var total:int=0
	DirAccess.make_dir_recursive_absolute(ROOT+"/fitting")
	for candidate in CANDIDATES:
		var id:String=str(candidate[0])
		var part_name:String=str(candidate[1])
		var source_part:Dictionary=source.parts[part_name]
		var clips:Dictionary={}
		for pose in POSES:
			var layers:Dictionary={}
			for layer in ["front","back"]:
				var path:String=ROOT+"/"+str(source_part.clips[pose][layer].path)
				var im:=Image.load_from_file(path)
				if im==null or im.is_empty():
					failures.append("missing source "+path)
					continue
				im.convert(Image.FORMAT_RGBA8)
				layers[layer]=im
			clips[pose]=layers
		var part:Dictionary={"slot":str(candidate[2]),"size":int(candidate[3]),"clips":clips}
		var sheet:=Image.create(1152,576,false,Image.FORMAT_RGBA8)
		sheet.fill(Color("#252c34"))
		var samples:Array=[]
		var changed:int=0
		var clipped:int=0
		for pose_index in range(POSES.size()):
			var pose:String=POSES[pose_index]
			for dir in range(4):
				for phase in range(3):
					var progress:float=[0.0,.5,.999][phase]
					var body:=base_cell(id,dir,pose,phase)
					if body==null or body.get_size()!=Vector2i(48,48):
						failures.append("invalid body "+id)
						continue
					var output:=Parts.composite_pose(body,[part],dir,pose,"healthy",progress)
					var padded:=Image.create(96,96,false,Image.FORMAT_RGBA8)
					padded.fill(Color.TRANSPARENT)
					padded.blit_rect(body,Rect2i(0,0,48,48),Vector2i(24,24))
					var wide:=Parts.composite_pose(padded,[part],dir,pose,"healthy",progress)
					var outside:int=0
					for y in range(96):
						for x in range(96):
							if (x<24 or x>=72 or y<24 or y>=72) and wide.get_pixel(x,y).a>.01:outside+=1
					if outside>0:clipped+=1
					var changed_pixels:int=0
					var silhouette_delta:int=0
					for y in range(48):
						for x in range(48):
							var original:Color=body.get_pixel(x,y)
							var fitted:Color=output.get_pixel(x,y)
							if original.to_rgba32()!=fitted.to_rgba32():changed_pixels+=1
							if (original.a>.01)!=(fitted.a>.01):silhouette_delta+=1
					if changed_pixels>0:changed+=1
					var x0:int=(dir*3+phase)*96
					var y0:int=pose_index*96
					sheet.blend_rect(body,Rect2i(0,0,48,48),Vector2i(x0,y0+24))
					sheet.blend_rect(output,Rect2i(0,0,48,48),Vector2i(x0+48,y0+24))
					samples.append({"pose":pose,"direction":dir,"progress":progress,"changed_pixels":changed_pixels,"silhouette_delta_pixels":silhouette_delta,"outside_canvas_pixels":outside})
					total+=1
		if changed==0:failures.append("no visible effect "+id)
		if sheet.save_png(ROOT+"/fitting/"+id+"-"+part_name+".png")!=OK:failures.append("preview export "+id)
		reports.append({"creature":id,"source_part":part_name,"license":source_part.chosen_license,"size":candidate[3],"samples":samples,"changed_samples":changed,"clipped_samples":clipped,"approved":false})
	var out:=FileAccess.open(ROOT+"/fitting/audit.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"candidate_count":reports.size(),"samples":total,"errors":failures,"candidates":reports},"\t"))
	out.close()
	if total!=288:failures.append("incomplete coverage")
	print("KINDRIA_LPC_FIT_AUDIT candidates=",reports.size()," samples=",total," errors=",failures)
	if failures.is_empty():
		print("KINDRIA_LPC_FIT_PASS")
		quit(0)
	else:quit(1)
