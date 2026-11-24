extends Node3D
## City Zero life simulation — separate moddable GDScript node.
## Modern car GLBs, diverse stylized pedestrians, transit, traffic and street scale.
## All routes are deterministic and offline: no network or proprietary assets.
const VEHICLES := [
    "car_2026_ev_sedan", "car_2026_crossover", "car_2026_hatchback",
    "car_2026_sportback", "car_2026_pickup", "car_2026_delivery"
]
var vehicles: Array[Dictionary] = []
var pedestrians: Array[Dictionary] = []
var signals: Array[Dictionary] = []
var time_elapsed := 0.0
var city_seed := RandomNumberGenerator.new()
var vis_distance := 67.0
var observer: Node3D
var update_accum := 0.0

func _ready() -> void:
    city_seed.seed = 20261124
    observer = get_parent().get_node_or_null("Player") as Node3D
    _build_road_intersections()
    _build_street_furniture()
    _spawn_traffic()
    _spawn_pedestrians()
    if ResourceLoader.exists("res://assets/skyline_dusk.glb"):
        _asset("skyline_dusk", Vector3.ZERO, 0.0, Vector3.ONE)
    print("CITY LIFE ACTIVE: 6 vehicle classes, %d moving cars, %d citizens, signal phases" % [vehicles.size(), pedestrians.size()])

func _asset(name: String, pos: Vector3, yaw: float = 0.0, scl: Vector3 = Vector3.ONE) -> Node3D:
    var container := Node3D.new()
    container.name = name
    container.position = pos
    container.rotation.y = yaw
    container.scale = scl
    add_child(container)
    var path := "res://assets/%s.glb" % name
    if ResourceLoader.exists(path):
        var scene: PackedScene = load(path)
        container.add_child(scene.instantiate())
    else:
        push_warning("City Life missing Blender asset: "+path)
    return container

func _box(pos: Vector3, size: Vector3, color: Color, emission: float = 0.0) -> void:
    var inst := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    inst.mesh = mesh
    inst.position = pos
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.85
    if emission > 0.01:
        material.emission_enabled = true
        material.emission = color
        material.emission_energy_multiplier = emission
    inst.material_override = material
    add_child(inst)

func _build_road_intersections() -> void:
    # Road centres at -30/0/+30 metres. Crossings are flush with sidewalks,
    # rather than stripes scattered through the roadway.
    for x in [-30.0, 0.0, 30.0]:
        for z in [-30.0, 0.0, 30.0]:
            for side in [-1.0, 1.0]:
                for k in range(8):
                    var q := -3.50 + float(k)
                    _box(Vector3(x+q,0.112,z+side*4.9),Vector3(.62,.016,1.65),Color("#eae1d4"))
                    _box(Vector3(x+side*4.9,0.113,z+q),Vector3(1.65,.016,.62),Color("#eae1d4"))
                # Curb ramp at each corner of intersection.
                for sx in [-1.0,1.0]:
                    var ramp := Vector3(x+sx*5.56,0.155,z+side*5.56)
                    _box(ramp,Vector3(1.10,.095,1.12),Color("#b3ada3"))
                    _box(ramp+Vector3(0,.057,0),Vector3(.52,.017,.74),Color("#e0b441"))
            for sx in [-1.0,1.0]:
                for sz in [-1.0,1.0]:
                    var pos := Vector3(x+sx*6.9,0,z+sz*6.9)
                    var light := _asset("traffic_signal",pos,atan2(-sx,-sz))
                    var bulbs: Array[MeshInstance3D] = []
                    for color in [Color("#f44346"),Color("#f2b940"),Color("#23e38a")]:
                        var lens := MeshInstance3D.new()
                        var sphere := SphereMesh.new()
                        sphere.radius = .137
                        sphere.height = .13
                        lens.mesh = sphere
                        var mat := StandardMaterial3D.new()
                        mat.albedo_color = color
                        mat.emission_enabled = true
                        mat.emission = color
                        mat.emission_energy_multiplier = 2.5
                        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
                        lens.material_override = mat
                        light.add_child(lens)
                        lens.position = Vector3(0,4.92-.53*float(bulbs.size()),1.34)
                        lens.visible = false
                        bulbs.append(lens)
                    signals.append({"node":light,"bulbs":bulbs,"axis":int((sx*sz)>0),"phase_offset":int(abs(x)+abs(z))%2})
    # Urban street lane separators and no-parking curb zones
    for p in [-30.0,0.0,30.0]:
        for t in range(-8,9):
            var coordinate := float(t)*5.0
            if absf(coordinate)<7.0:continue
            _box(Vector3(p+2.2,.105,coordinate),Vector3(.11,.018,1.70),Color("#e5b75c"))
            _box(Vector3(coordinate,.105,p+2.2),Vector3(1.70,.018,.11),Color("#e5b75c"))

func _build_street_furniture() -> void:
    for pos in [Vector3(-7,0,-7),Vector3(7,0,-7),Vector3(-7,0,7),Vector3(7,0,7),
                Vector3(-24,0,7),Vector3(24,0,-7)]:
        _asset("stop_sign",pos,PI)
    for pos in [Vector3(-24,0,-8.0),Vector3(23,0,8.1)]:
        _asset("bus_shelter",pos,0.0,Vector3.ONE)
    for pos in [Vector3(-21.0,0,-7.0),Vector3(7.7,0,-21),Vector3(20,0,7.7)]:
        _asset("fire_hydrant",pos)
    for pos in [Vector3(-9.2,0,-7),Vector3(7.1,0,-9.4),Vector3(-22,0,8.0),Vector3(20,0,7)]:
        _asset("street_bin",pos)

func _spawn_traffic() -> void:
    # Full curving and turning routes, explicit traffic-light intersection stops.
    var routes := [
        [Vector3(-2.15,0,-44),Vector3(-2.15,0,-8),Vector3(-2.15,0,8),Vector3(-2.15,0,43)],
        [Vector3(2.2,0,43),Vector3(2.2,0,8),Vector3(2.2,0,-8),Vector3(2.2,0,-44)],
        [Vector3(-44,0,2.2),Vector3(-8,0,2.2),Vector3(8,0,2.2),Vector3(44,0,2.2)],
        [Vector3(44,0,-2.1),Vector3(8,0,-2.1),Vector3(-8,0,-2.1),Vector3(-44,0,-2.1)],
        [Vector3(-32.1,0,43),Vector3(-32.1,0,30),Vector3(-32.1,0,-8),Vector3(-32.1,0,-43)],
        [Vector3(43,0,32.1),Vector3(30,0,32.1),Vector3(-8,0,32.1),Vector3(-43,0,32.1)]
    ]
    var offsets := [0.3,0.9,0.42,0.68,0.31,0.57]
    for i in range(VEHICLES.size()):
        var path: Array = routes[i]
        var starting: Vector3 = path[0]
        var node := _asset(VEHICLES[i], starting)
        var car_speed := 3.5 + float(i%4)*.80
        vehicles.append({"node":node,"route":path,"target":1,"speed":car_speed,"hold":0.0,"phase":offsets[i]})
    # Additional traffic uses same modern 2026 assets with different timing.
    for i in range(4):
        var idx := i%VEHICLES.size()
        var path: Array = routes[idx]
        var node := _asset(VEHICLES[idx],path[0])
        var second_segment: Vector3 = path[1]
        node.position = path[0].lerp(second_segment,0.55+0.07*i)
        vehicles.append({"node":node,"route":path,"target":1,"speed":3.4+float(i), "hold":0.0,"phase":0.3+i*.11})

func _spawn_pedestrians() -> void:
    # 8 visually distinct Blender-made actors. Routes deliberately stay on
    # sidewalks, with occasional conversations, stop-and-look and bus waiting.
    var routes := [
        [Vector3(-25,0,-6.1),Vector3(-17,0,-6.1),Vector3(-8,0,-6.1),Vector3(-17,0,-6.1)],
        [Vector3(21,0,-6.2),Vector3(11,0,-6.2),Vector3(7,0,-6.2),Vector3(11,0,-6.2)],
        [Vector3(-23,0,6.1),Vector3(-12,0,6.1),Vector3(-7,0,6.1),Vector3(-12,0,6.1)],
        [Vector3(21,0,6.1),Vector3(11,0,6.1),Vector3(7,0,6.1),Vector3(11,0,6.1)],
        [Vector3(-6.1,0,-23),Vector3(-6.1,0,-12),Vector3(-6.1,0,-7),Vector3(-6.1,0,-12)],
        [Vector3(6.1,0,24),Vector3(6.1,0,12),Vector3(6.1,0,7),Vector3(6.1,0,12)],
        [Vector3(-23,0,-7.1),Vector3(-21,0,-7.1),Vector3(-19,0,-7.1)],
        [Vector3(23,0,7.0),Vector3(19,0,7.0),Vector3(23,0,7.0)]
    ]
    for i in range(24):
        var design := i%8
        var route: Array = routes[i%routes.size()]
        var npc := _asset("citizen_%02d" % design,route[0],0.0)
        npc.scale = Vector3.ONE * (0.91 + 0.025*float((i*3)%8))
        pedestrians.append({"node":npc,"route":route,"target":1,"speed":0.70+float(i%5)*.14,
                            "wait":float(i%4), "phase":float(i)*1.7,"anim":float(i)*.53})

func _signal_is_green(car_position: Vector3, travel: Vector3) -> bool:
    # Alternating axis priority, short all-red clearance before switching.
    var phase := fposmod(time_elapsed,20.0)
    if phase>17.5:return false
    if absf(travel.x)>absf(travel.z):
        return phase>=9.0
    return phase<8.0

func _near_red_light(p: Vector3, target: Vector3) -> bool:
    var travel := (target-p).normalized()
    for intersection in [-30.0,0.0,30.0]:
        if absf(travel.z)>0.8 and absf(p.z-intersection)<7.1 and absf(p.z-intersection)>4.1:
            if signf(intersection-p.z)==signf(travel.z) and not _signal_is_green(p,travel):
                return true
        if absf(travel.x)>0.8 and absf(p.x-intersection)<7.1 and absf(p.x-intersection)>4.1:
            if signf(intersection-p.x)==signf(travel.x) and not _signal_is_green(p,travel):
                return true
    return false

func _update_signal_lenses() -> void:
    var phase := fposmod(time_elapsed,20.0)
    for traffic_info in signals:
        var bulbs: Array = traffic_info["bulbs"]
        var greens := phase < 8.0 if int(traffic_info["axis"]) == 0 else phase >= 9.0 and phase < 17.5
        var yellow := (phase >= 8.0 and phase < 9.0) if int(signal["axis"]) == 0 else (phase >= 17.5 and phase < 19.0)
        (bulbs[0] as MeshInstance3D).visible = not greens and not yellow
        (bulbs[1] as MeshInstance3D).visible = yellow
        (bulbs[2] as MeshInstance3D).visible = greens

func _process(delta: float) -> void:
    time_elapsed += delta
    update_accum += delta
    if update_accum >= .18:
        update_accum = 0.0
        _update_signal_lenses()
    # There is no expensive scene reconstruction per frame. Only actor transforms.
    for i in range(vehicles.size()):
        var car_data: Dictionary = vehicles[i]
        var node: Node3D = car_data["node"]
        var route: Array = car_data["route"]
        var target_idx: int = car_data["target"]
        var point: Vector3 = route[target_idx]
        var direction := point-node.position
        if direction.length()<0.45:
            target_idx = (target_idx+1)%route.size()
            car_data["target"]=target_idx
            point=route[target_idx]
            direction=point-node.position
        var must_stop := _near_red_light(node.position,point)
        # Simple queueing: don't teleport through car ahead in the same lane.
        if not must_stop:
            for j in range(vehicles.size()):
                if i==j:continue
                var other: Node3D = vehicles[j]["node"]
                if node.position.distance_to(other.position)<3.6:
                    if direction.normalized().dot(other.position-node.position)>0.15:
                        must_stop=true
                        break
        if not must_stop and direction.length()>0.03:
            var movement := direction.normalized()
            node.position += movement*float(car_data["speed"])*delta
            node.rotation.y = lerp_angle(node.rotation.y,atan2(-movement.x,-movement.z),minf(1.0,delta*4.0))
        if observer != null:node.visible = node.position.distance_to(observer.position)<vis_distance
    for data in pedestrians:
        var npc: Node3D = data["node"]
        data["wait"]=maxf(0.0,float(data["wait"])-delta)
        var route: Array = data["route"]
        var point: Vector3 = route[data["target"]]
        var diff := point-npc.position
        if diff.length()<0.18:
            data["target"]=(int(data["target"])+1)%route.size()
            data["wait"]=1.0+float(city_seed.randi_range(0,4))*.52
        elif float(data["wait"])<=0.0:
            var travel := diff.normalized()
            npc.position+=travel*float(data["speed"])*delta
            npc.rotation.y=lerp_angle(npc.rotation.y,atan2(travel.x,travel.z),minf(1.0,delta*6))
            npc.position.y=absf(sin(time_elapsed*7.0+float(data["anim"])))*.025
        if observer != null:npc.visible = npc.position.distance_to(observer.position)<vis_distance
