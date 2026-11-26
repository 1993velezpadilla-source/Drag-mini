extends RefCounted
# Imported PixelFX atlas: only baked images/metadata are used on device.
static var clips:Dictionary={}
static var absent:Dictionary={}
static func clip(id:String)->Dictionary:
	if clips.has(id):return clips[id]
	if absent.has(id):return {}
	var prefix:="res://assets/pet_fx/"+id
	var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(prefix+".json")) if FileAccess.file_exists(prefix+".json") else null
	var texture:=load(prefix+".png") as Texture2D if ResourceLoader.exists(prefix+".png") else null
	if not data is Dictionary or texture==null:
		absent[id]=true
		return {}
	var frames:Array=[]
	for entry in data.get("frames",[]):
		var r:Dictionary=entry.frame
		var atlas:=AtlasTexture.new()
		atlas.atlas=texture;atlas.region=Rect2(float(r.x),float(r.y),float(r.w),float(r.h));atlas.filter_clip=true
		frames.append(atlas)
	if frames.is_empty():return {}
	var meta:Dictionary=data.meta.pixelfx
	var result={"frames":frames,"fps":float(meta.fps),"loop":bool(meta.loop),"pivot":Vector2(float(meta.pivot[0]),float(meta.pivot[1]))}
	clips[id]=result
	return result
static func frame(id:String,time:float)->Texture2D:
	var c:=clip(id)
	if c.is_empty():return null
	var frames:Array=c.frames
	var index:=maxi(0,int(floor(time*float(c.fps))))
	index=posmod(index,frames.size()) if bool(c.loop) else mini(index,frames.size()-1)
	return frames[index] as Texture2D
static func world_effect(actor:Node3D,id:String,time:float,active:bool,height:float=1.5)->void:
	var node:=actor.get_node_or_null("PetExternalFx") as Sprite3D
	if not active:
		if node!=null:node.hide()
		return
	var tex:=frame(id,time)
	if tex==null:
		if node!=null:node.hide()
		return
	if node==null:
		node=Sprite3D.new();node.name="PetExternalFx";node.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		node.shaded=false;node.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		actor.add_child(node)
	node.texture=tex;node.pixel_size=height/float(tex.get_height())
	node.position=Vector3(0,height*.8,.05);node.show()
