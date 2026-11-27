extends Node3D
## Optional native renderer; never requires the extension for base-game loading.
## All effect resources must be supplied by the caller (no bundled DX assets).
const SLOT_CAP:int=6
var slots:Array[Dictionary]=[]

func prepare()->bool:
	if not ClassDB.class_exists("EffekseerEmitter3D"):return false
	for i in range(SLOT_CAP):
		var node:Node3D=ClassDB.instantiate("EffekseerEmitter3D")
		add_child(node)
		node.set("autoplay",false)
		slots.append({"node":node,"busy":false,"life":0.0,"follows":false,"points":[]})
	return true

func launch(track:Dictionary,effect:Resource,points:Array,tiles:Array,scale_factor:float,seconds:float)->int:
	if not bool(track.get("enabled",false)) or effect==null or points.is_empty():return -1
	for i in range(slots.size()):
		var slot:Dictionary=slots[i]
		if slot.busy:continue
		var node:Node3D=slot.node
		node.call("stop")
		node.set("effect",effect)
		node.scale=Vector3.ONE*scale_factor
		var anchor:String=str(track.anchor)
		slot.follows=anchor=="path"
		slot.points=points.duplicate()
		slot.life=maxf(seconds,.02)
		slot.busy=true
		node.position=points[-1] if anchor=="target" else tiles[0] if anchor=="tiles" and not tiles.is_empty() else points[0]
		node.call("set_target_position",points[-1])
		node.call("play")
		return i
	return -1

func advance(dt:float,path_progress:float)->void:
	for slot in slots:
		if not slot.busy:continue
		var node:Node3D=slot.node
		slot.life-=dt
		if slot.life<=0.0:
			node.call("stop")
			slot.busy=false
			continue
		if slot.follows:
			var p:Array=slot.points
			var f:float=clampf(path_progress,0.0,1.0)*float(p.size()-1)
			var index:int=mini(floori(f),p.size()-1)
			node.position=Vector3(p[index]).lerp(Vector3(p[mini(index+1,p.size()-1)]),f-float(index))

func reset()->void:
	for slot in slots:
		slot.node.call("stop")
		slot.busy=false
		slot.points=[]
