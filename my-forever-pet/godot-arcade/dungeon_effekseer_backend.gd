extends Node3D
## Optional native renderer; never requires the extension for base-game loading.
## All effect resources must be supplied by the caller (no bundled DX assets).
const SLOT_CAP:int=6
var slots:Array[Dictionary]=[]
const PENDING_CAP:int=48
var pending:Array[Dictionary]=[]
var dropped:int=0

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

# Schedule individual audiovisual tracks with a shared cast origin but independent
# emitter clocks. The caller supplies authored resources by stage name.
# Impact stages require an explicit outcome; no damage FX on a miss.
func schedule_cast(plan:Array,resources:Dictionary,points:Array,tiles:Array,duration:float,enemy:bool,confirmed:bool)->int:
	if points.is_empty() or duration<=0.0 or not is_finite(duration):return 0
	var added:int=0
	for track in plan:
		var stage:String=str(track.stage)
		if not bool(track.enabled) or not resources.has(stage):continue
		if (stage=="ally_invoke" and enemy) or (stage=="enemy_invoke" and not enemy):continue
		if stage in ["impact","projectile_impact","area"] and not confirmed:continue
		var binding:Dictionary=resources[stage]
		var effect:Resource=binding.get("effect")
		if effect==null:continue
		var start:float=clampf(float(track.start),0.0,1.0)*duration
		var finish:float=clampf(float(track.end),0.0,1.0)*duration
		if finish<=start:continue
		if pending.size()>=PENDING_CAP:dropped+=1;continue
		pending.append({"delay":start,"track":track.duplicate(true),"effect":effect,"points":points.duplicate(),"tiles":tiles.duplicate(),"life":finish-start,"scale":float(binding.get("scale",1.0))})
		added+=1
	return added

func dispatch_due(dt:float)->void:
	# Process launch order deterministically. A late frame shortens a track,
	# rather than replaying an impact long after the underlying attack.
	var next:Array[Dictionary]=[]
	for item in pending:
		item.delay-=dt
		if float(item.delay)>0.0:
			next.append(item)
			continue
		var late:float=maxf(0.0,-float(item.delay))
		var remaining:float=float(item.life)-late
		if remaining<=0.0:continue
		var index:int=launch(item.track,item.effect,item.points,item.tiles,float(item.scale),float(item.life))
		if index<0:dropped+=1;continue
		var slot:Dictionary=slots[index]
		slot.elapsed=late
		slot.life=remaining
		if slot.follows:slot.node.position=sample_path(slot.points,float(slot.distance),late/float(slot.duration))
	pending=next

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

	dispatch_due(dt)

func reset()->void:
	pending.clear()
	dropped=0
	for slot in slots:
		slot.node.call("stop")
		slot.busy=false
		slot.points=[]
