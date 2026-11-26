extends Control
const Data=preload("res://research_data.gd")
const PixelArt=preload("res://pixel_pet_art.gd")
var pet_facing:=0
var pet_anim_clock:=0.0
var pet_moving:=false
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
const GRID=40
var navigation=AStarGrid2D.new()
var path:PackedVector2Array=[]
var trail:PackedVector2Array=[]
var shimmer=0.0
var last_touch=Vector2(-1,-1)
var last_path_at=-1.0
func setup(r:int,t:int,m:int,pet:Texture2D):
	region=r; tier=t; mask=m; companion=PixelArt.adventure_frame(0,"idle"); points=Data.sanctuary_points(r,t)
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size.y=400; mouse_filter=MOUSE_FILTER_STOP; set_meta("direct_field_input",true)
	# Keep paths wide and relics reachable. Distinct terrain on each map.
	obstacles.clear()
	var candidates=[Rect2(.39,.19,.17,.19),Rect2(.42,.53,.17,.16)] if (r+t)%2==0 else [Rect2(.30,.30,.20,.16),Rect2(.55,.62,.18,.13)]
	for rect in candidates:
		var safe=true
		for p in points:
			if rect.grow(.09).has_point(p):safe=false
		if rect.grow(.09).has_point(pos):safe=false
		if safe:obstacles.append(rect)
	navigation.region=Rect2i(0,0,GRID+1,GRID+1)
	navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for y in range(GRID+1):
		for x in range(GRID+1):
			if not can_move(Vector2(x,y)/GRID):navigation.set_point_solid(Vector2i(x,y))
	queue_redraw()
func grid_cell(p:Vector2)->Vector2i:
	return Vector2i((p*GRID).round()).clamp(Vector2i(0,0),Vector2i(GRID,GRID))
func nearest_open(p:Vector2)->Vector2i:
	var cell=grid_cell(p)
	if not navigation.is_point_solid(cell):return cell
	var best=Vector2i(-1,-1);var distance:float=INF
	for y in range(GRID+1):
		for x in range(GRID+1):
			var id=Vector2i(x,y)
			if navigation.is_point_solid(id):continue
			var dist=Vector2(id).distance_squared_to(Vector2(cell))
			if dist<distance:distance=dist;best=id
	return best
func move_to(p:Vector2):
	target=p.clamp(Vector2(.07,.07),Vector2(.93,.93))
	var start=nearest_open(pos);var finish=nearest_open(target)
	if start.x<0 or finish.x<0:return
	var ids=navigation.get_id_path(start,finish)
	if ids.is_empty():return
	path.clear()
	for id in ids:path.append(Vector2(id)/GRID)
	if can_move(target):path.append(target)
	last_touch=target;last_path_at=walk_time
	queue_redraw()
func _gui_input(event:InputEvent):
	if locked:return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		move_to(event.position/size); accept_event()
	elif event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		var p:Vector2=event.position/size
		if walk_time-last_path_at>.10 and p.distance_to(last_touch)>.035:move_to(p)
		accept_event()
func can_move(p:Vector2)->bool:
	if p.x<.05 or p.y<.05 or p.x>.95 or p.y>.95:return false
	for rect in obstacles:
		if rect.grow(.025).has_point(p):return false
	return true
func _process(dt:float):
	if locked:return
	walk_time+=dt
	shimmer=maxf(0,shimmer-dt)
	var previous:Vector2=pos
	var remaining:float=minf(dt,.05)*(.44 if region==1 else .58)
	while remaining>0.00001 and not path.is_empty():
		var next:Vector2=path[0]
		var distance:float=pos.distance_to(next)
		if distance<=remaining:
			pos=next; remaining-=distance; path.remove_at(0)
		else:
			pos=pos.move_toward(next,remaining);remaining=0
	var delta:Vector2=(pos-previous)*size
	var moving:bool=delta.length_squared()>.0025
	var direction:int=PixelArt.direction_for(delta,pet_facing)
	if moving!=pet_moving or direction!=pet_facing:pet_anim_clock=0.0
	pet_moving=moving;pet_facing=direction;pet_anim_clock+=dt
	companion=PixelArt.frame_for(pet_facing,"walk" if pet_moving else "idle",pet_anim_clock)
	if trail.is_empty() or trail[-1].distance_to(pos)>.025:
		trail.append(pos)
		if trail.size()>14:trail.remove_at(0)
	for i in range(points.size()):
		if (mask&(1<<i))==0 and pos.distance_to(points[i])<.065:
			locked=true; path.clear(); shimmer=.9; recovered.emit(i);return
	queue_redraw()
func _draw():
	if size.x<=0 or size.y<=0:return
	var tint:Color=Data.TINTS[region]
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
		var mid=r.get_center()
		draw_rect(Rect2(r.position+Vector2(5,8),r.size),Color("#101a2b99"))
		if region==0:
			for j in range(5):
				var p=r.position+Vector2(r.size.x*(.15+.18*j),r.size.y*(.38+.12*(j%2)))
				draw_rect(Rect2(p-Vector2(4,0),Vector2(8,r.size.y*.44)),Color("#83564a"))
				draw_circle(p, r.size.x*.29,Color("#163c33"))
				draw_circle(p-Vector2(3,4),r.size.x*.23,tint.darkened(.42))
				draw_circle(p-Vector2(6,8),r.size.x*.10,tint.darkened(.18))
		elif region==1:
			draw_rect(r,tint.darkened(.67));draw_rect(r,tint.darkened(.20),false,3)
			for j in range(4):
				var p=r.position+Vector2(r.size.x*(.13+j*.24),r.size.y*.80)
				for k in range(3):
					draw_line(p,p+Vector2((k-1)*10,-r.size.y*(.45+.15*(k%2))),Color("#ed9caf"),5,true)
				draw_circle(p,5,Color("#ffd7c6"))
		else:
			draw_colored_polygon(PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(mid.x,r.end.y+16),Vector2(r.position.x,r.end.y)]),tint.darkened(.57))
			draw_rect(r,tint.darkened(.31));draw_rect(r,tint.lightened(.12),false,2)
			draw_colored_polygon(PackedVector2Array([mid-Vector2(0,20),mid+Vector2(13,0),mid+Vector2(0,20),mid-Vector2(13,0)]),Color("#f4d7ff"))
	for i in range(trail.size()):
		draw_circle(trail[i]*size,2.0+float(i)/trail.size()*2,Color(tint.r,tint.g,tint.b,float(i)/trail.size()*.45))
	if not path.is_empty():
		var dest:Vector2=path[-1]*size
		draw_arc(dest,10+sin(walk_time*5)*2,0,TAU,28,tint,2,true)
	for i in range(points.size()):
		var p:Vector2=points[i]*size
		if (mask&(1<<i))!=0:
			draw_arc(p,15,0,TAU,24,Color("#8fddb7"),2,true);continue
		var distance:float=pos.distance_to(points[i])
		if distance<.28:
			var glow:float=12+sin(walk_time*4+i)*3
			draw_circle(p,glow*1.6,Color("#ffdf7644"))
			draw_colored_polygon(PackedVector2Array([p+Vector2(0,-12),p+Vector2(9,0),p+Vector2(0,12),p+Vector2(-9,0)]),Color("#ffe69e"))
		else:pass
	var at=pos*size
	draw_circle(at,23,Color("#16172a99"))
	draw_arc(at,30,0,TAU,40,tint,2,true)
	if shimmer>0:
		draw_arc(at,30+45*(1-shimmer/.9),0,TAU,48,Color(1,.84,.44,shimmer/.9),3,true)
	if companion!=null:
		var hop:float=absf(sin(pet_anim_clock*TAU*3.5))*4.0 if pet_moving else sin(pet_anim_clock*2.5)*.8
		draw_texture_rect(companion,Rect2(at-Vector2(34,48+hop),Vector2(68,68)),false)
	else:draw_circle(at,12,tint)
