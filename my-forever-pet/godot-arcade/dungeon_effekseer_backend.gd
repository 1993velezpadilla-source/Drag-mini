extends Node3D
## Optional native renderer; never requires the extension for base-game loading.
## All effect resources must be supplied by the caller (no bundled DX assets).
const SLOT_CAP:int=6
var slots:Array[Dictionary]=[]

func prepare()->bool:
	if not ClassDB.class_exists("EffekseerEmitter3D"):return false
	if not slots.is_empty():return slots.size()==SLOT_CAP
	for i in range(SLOT_CAP):
		var node:Node3D=ClassDB.instantiate("EffekseerEmitter3D")
		node.set("autoplay",false)
		node.set("autofree",false)
		add_child(node)
		slots.append({"node":node,"busy":false,"life":0.0,"elapsed":0.0,"duration":0.0,"follows":false,"points":[],"distance":0.0})
	return true

func launch(track:Dictionary,effect:Resource,points:Array,tiles:Array,scale_factor:float,seconds:float)->int:
	if not bool(track.get("enabled",false)) or effect==null or points.is_empty() or not is_finite(scale_factor) or scale_factor<=0.0 or not is_finite(seconds):return -1
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
		slot.elapsed=0.0
		slot.duration=slot.life
		slot.distance=0.0
		for k in range(1,points.size()):slot.distance+=Vector3(points[k-1]).distance_to(Vector3(points[k]))
		slot.busy=true
		node.position=points[-1] if anchor=="target" else tiles[0] if anchor=="tiles" and not tiles.is_empty() else points[0]
		node.set("target_position",to_global(Vector3(points[-1])))
		node.call("play")
		return i
	return -1

# Each emitter owns its clock. A later cast cannot change an earlier trajectory.
func sample_path(points:Array,distance:float,progress:float)->Vector3:
	if points.is_empty():return Vector3.ZERO
	if distance<=.0001:return points[-1]
	var remaining:float=distance*clampf(progress,0.0,1.0)
	for i in range(1,points.size()):
		var a:Vector3=points[i-1];var b:Vector3=points[i]
		var segment:float=a.distance_to(b)
		if segment<=.0001:continue
		if remaining<=segment:return a.lerp(b,remaining/segment)
		remaining-=segment
	return points[-1]

func advance(dt:float)->void:
	if not is_finite(dt) or dt<0.0:return
	for slot in slots:
		if not slot.busy:continue
		var node:Node3D=slot.node
		slot.elapsed=minf(float(slot.duration),float(slot.elapsed)+dt)
		slot.life=float(slot.duration)-float(slot.elapsed)
		if slot.follows:
			node.position=sample_path(slot.points,float(slot.distance),float(slot.elapsed)/float(slot.duration))
		if slot.life<=0.0:
			node.call("stop")
			slot.busy=false
			slot.points=[]

func reset()->void:
	for slot in slots:
		slot.node.call("stop")
		slot.busy=false
		slot.points=[]
