extends Control
const Data=preload("res://research_data.gd")
signal recovered(index:int)
var region=0
var tier=0
var mask=0
var companion:Texture2D
var points:Array[Vector2]=[]
var pos=Vector2(.5,.88)
var target=Vector2(.5,.88)
var walk_time=0.0
var locked=false
var obstacles:Array[Rect2]=[]
func setup(r:int,t:int,m:int,pet:Texture2D):
	region=r; tier=t; mask=m; companion=pet; points=Data.sanctuary_points(r,t)
	custom_minimum_size.y=400; mouse_filter=MOUSE_FILTER_STOP
	# Keep paths wide and relics reachable. Distinct terrain on each map.
	obstacles=[Rect2(.39,.19,.17,.19),Rect2(.42,.53,.17,.16)] if (r+t)%2==0 else [Rect2(.30,.30,.20,.16),Rect2(.55,.62,.18,.13)]
	queue_redraw()
func _gui_input(event:InputEvent):
	if locked:return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		target=(event.position/size).clamp(Vector2(.07,.07),Vector2(.93,.93)); accept_event()
	elif event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		target=(event.position/size).clamp(Vector2(.07,.07),Vector2(.93,.93)); accept_event()
func can_move(p:Vector2)->bool:
	for rect in obstacles:
		if rect.grow(.025).has_point(p):return false
	return true
func _process(dt:float):
	if locked:return
	walk_time+=dt
	var next=pos.move_toward(target,dt*(.40 if region==1 else .48))
	if can_move(next):pos=next
	else:
		var x=Vector2(next.x,pos.y);var y=Vector2(pos.x,next.y)
		if can_move(x):pos=x
		if can_move(y):pos=y
	for i in range(points.size()):
		if (mask&(1<<i))==0 and pos.distance_to(points[i])<.065:
			locked=true; recovered.emit(i);return
	queue_redraw()
func _draw():
	if size.x<=0 or size.y<=0:return
	var tint=Data.TINTS[region]
	for k in range(28):
		var y=float(k)/28
		draw_rect(Rect2(0,size.y*y,size.x,size.y/28+1),tint.darkened(.80).lerp(tint.darkened(.48),y))
	var rng=RandomNumberGenerator.new();rng.seed=980+region*71+tier*13
	for i in range(45):
		var p=Vector2(rng.randf(),rng.randf())*size
		var radius=rng.randf_range(4,16)
		if region==0:
			draw_circle(p,radius,tint.darkened(.60));draw_circle(p-Vector2(2,3),radius*.6,tint.darkened(.35))
		elif region==1:draw_arc(p,radius,0,TAU,18,Color("#96e8ef44"),2,true)
		else:draw_circle(p,radius*.3,Color("#e9dcff77"))
	for box in obstacles:
		var r=Rect2(box.position*size,box.size*size)
		draw_rect(r.grow(3),Color("#16223c"));draw_rect(r,tint.darkened(.55));draw_rect(r,tint.darkened(.15),false,2)
		for i in range(3):draw_line(r.position+Vector2(r.size.x*i/3,0),r.position+Vector2(r.size.x*i/3,r.size.y),tint.darkened(.35),2)
	for i in range(points.size()):
		var p=points[i]*size
		if (mask&(1<<i))!=0:
			draw_arc(p,15,0,TAU,24,Color("#8fddb7"),2,true);continue
		var distance=pos.distance_to(points[i])
		if distance<.28:
			var glow=12+sin(walk_time*4+i)*3
			draw_circle(p,glow*1.6,Color("#ffdf7644"))
			draw_colored_polygon(PackedVector2Array([p+Vector2(0,-12),p+Vector2(9,0),p+Vector2(0,12),p+Vector2(-9,0)]),Color("#ffe69e"))
		else:draw_circle(p,3,Color("#ffd98660"))
	var at=pos*size
	draw_circle(at,23,Color("#16172a99"))
	draw_arc(at,30,0,TAU,40,tint,2,true)
	if companion!=null:draw_texture_rect(companion,Rect2(at-Vector2(34,40),Vector2(68,68)),false)
	else:draw_circle(at,12,tint)
