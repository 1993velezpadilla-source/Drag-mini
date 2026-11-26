extends RefCounted
# Existing LPC layer format; composition is separate from gameplay and species.
const SLOTS=["tail","wing_left","wing_right","ears","eyes","mouth","fins","crest","horns","limbs","aura","flame","accessory"]
const DIR_ROWS=[2,0,1,3] # LPC up, left, down, right -> front, rear, left, right
static func mood(happiness:float,energy:float,hunger:float,germs:int)->String:
	if germs>0:return "sick"
	if energy<=20 or hunger<=1:return "weak"
	if happiness<=3:return "sad"
	if happiness>=8 and energy>=60:return "happy"
	return "healthy"
static func lpc_frame(sheet:Image,direction:int,index:int)->Image:
	if sheet==null or sheet.get_width()%64!=0 or sheet.get_height()%64!=0:return null
	var row:int=DIR_ROWS[clampi(direction,0,3)] if sheet.get_height()>=256 else 0
	var count:int=sheet.get_width()/64
	return sheet.get_region(Rect2i(posmod(index,maxi(1,count))*64,row*64,64,64))
static func composite(body:Image,parts:Array,dir:int,frame:int)->Image:
	var result:=Image.create(body.get_width(),body.get_height(),false,Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	for pass_id in [0,1]:
		for part in parts:
			var sheet:Image=part.get("back" if pass_id==0 else "front")
			if sheet==null:continue
			var cell:=lpc_frame(sheet,dir,frame)
			if cell==null:continue
			cell.convert(Image.FORMAT_RGBA8)
			var size_px:int=clampi(int(part.get("size",48)),8,96)
			cell.resize(size_px,size_px,Image.INTERPOLATE_NEAREST)
			var offset:Vector2i=part.get("offset",Vector2i.ZERO)
			var at:=Vector2i((body.get_width()-size_px)/2,(body.get_height()-size_px)/2)+offset
			result.blend_rect(cell,Rect2i(0,0,size_px,size_px),at)
		if pass_id==0:result.blend_rect(body,Rect2i(Vector2i.ZERO,body.get_size()),Vector2i.ZERO)
	return result
