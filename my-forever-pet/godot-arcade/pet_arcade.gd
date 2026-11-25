extends Control
const NAMES=["Star Catch","Flappy Pet","Cloud Jump","Find My Pet"]
const WORLD=Vector2(480,720)
var store:Node
var mode=0
var score=0
var elapsed=0.0
var started=false
var over=false
var claimed=false
var rng=RandomNumberGenerator.new()
var pos=Vector2(120,340)
var velocity=Vector2.ZERO
var target=Vector2(240,350)
var steer=0.0
var pipes:Array[Vector3]=[]
var platforms:Array[Vector2]=[]
var crowd:Array[Vector3]=[]
var target_index=0
var wrong=0
var zoomed=false
var camera_offset=Vector2.ZERO
var press_at=Vector2.ZERO
var drag_at=Vector2.ZERO
var dragging=false
var pet_texture:Texture2D
var other_textures:Array[Texture2D]=[]
var title:Label
var hint:Label
var done:Button
var zoom_button:Button
var playfield:Control
var combo=0
var best_combo=0
var last_target_at=0.0
var last_input_touch=-1000
var timer_bar:ProgressBar
var best_label:Label
var preview:TextureRect
var result_label:Label
var feedback=0.0
var feedback_pos=Vector2.ZERO
var feedback_text=""
var height_score=0.0
var platform_highest=0.0
var platform_serial=0
var platform_ids:Array[int]=[]
var scored_platforms:Dictionary={}
var last_label_key=""
var stage_texture:Texture2D
var prop_textures:Dictionary={}

func gap_height()->float: return maxf(84,126-score*1.6)
func pipe_speed()->float: return 185+minf(125,score*5)
func round_limit()->float: return 20.0 if mode==0 else 60.0 if mode==3 else 0.0
func flash(at:Vector2,message:String):
	feedback_pos=at; feedback_text=message; feedback=0.65
func _ready():
	store=get_node("/root/PetStore")
	if store.arcade_mode<0 or store.arcade_mode>3:
		get_tree().call_deferred("change_scene_to_file","res://hub.tscn")
		return
	mode=store.arcade_mode
	var backdrop_path="res://assets/arcade_"+["star","flappy","cloud","find"][mode]+".jpg"
	if ResourceLoader.exists(backdrop_path): stage_texture=load(backdrop_path)
	for key in ["star","platform","pipe"]:
		var pp="res://assets/premium_"+key+".png"
		if ResourceLoader.exists(pp): prop_textures[key]=load(pp)
	rng.randomize()
	for i in range(24):
		var path="res://assets/pet_%d.png"%i
		other_textures.append(load(path) if ResourceLoader.exists(path) else null)
	pet_texture=other_textures[store.species()]
	if store.s.stage==1 or store.s.stage==2:
		var growth_path="res://assets/growth_%d_%d.png"%[store.s.field,store.s.stage]
		if ResourceLoader.exists(growth_path): pet_texture=load(growth_path)
	reset_round()
	var bar=HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	bar.offset_left=14; bar.offset_top=10; bar.offset_right=-14; bar.offset_bottom=65
	add_child(bar)
	title=Label.new(); title.add_theme_font_size_override("font_size",22); title.size_flags_horizontal=SIZE_EXPAND_FILL; bar.add_child(title)
	var exit=Button.new(); exit.text="Collect / exit"; exit.custom_minimum_size=Vector2(140,50); exit.pressed.connect(finish); bar.add_child(exit)
	best_label=Label.new(); best_label.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT); best_label.position=Vector2(15,size.y-39); best_label.text="BEST "+str(store.s.best[mode]); best_label.modulate=Color("#a8d8d4"); add_child(best_label)
	timer_bar=ProgressBar.new(); timer_bar.set_anchors_and_offsets_preset(PRESET_TOP_WIDE); timer_bar.offset_left=14; timer_bar.offset_right=-14; timer_bar.offset_top=65; timer_bar.offset_bottom=72; timer_bar.show_percentage=false; timer_bar.max_value=maxf(1,round_limit()); timer_bar.value=round_limit(); timer_bar.visible=round_limit()>0; add_child(timer_bar)
	preview=TextureRect.new(); preview.texture=pet_texture; preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; preview.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT); preview.offset_left=-68; preview.offset_right=-8; preview.offset_top=-74; preview.offset_bottom=-14; preview.mouse_filter=MOUSE_FILTER_IGNORE; preview.visible=mode==3; add_child(preview)
	hint=Label.new(); hint.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE); hint.offset_top=-85; hint.offset_bottom=-40; hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_font_size_override("font_size",17); add_child(hint)
	zoom_button=Button.new(); zoom_button.text="Zoom / overview"; zoom_button.set_anchors_and_offsets_preset(PRESET_CENTER_BOTTOM); zoom_button.offset_left=-95; zoom_button.offset_right=95; zoom_button.offset_top=-43; zoom_button.offset_bottom=-5; zoom_button.pressed.connect(toggle_zoom); zoom_button.visible=mode==3; add_child(zoom_button)
	result_label=Label.new(); result_label.set_anchors_and_offsets_preset(PRESET_CENTER); result_label.offset_left=-205; result_label.offset_right=205; result_label.offset_top=-85; result_label.offset_bottom=5; result_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; result_label.add_theme_font_size_override("font_size",24); result_label.hide(); add_child(result_label)
	done=Button.new(); done.text="Collect & return"; done.set_anchors_and_offsets_preset(PRESET_CENTER); done.offset_left=-125; done.offset_right=125; done.offset_top=15; done.offset_bottom=72; done.pressed.connect(finish); done.hide(); add_child(done)
	update_labels()
func reset_round():
	match mode:
		0: new_target()
		1:
			pos=Vector2(120,340); velocity=Vector2.ZERO
			for i in range(4): pipes.append(Vector3(540+i*230,rng.randf_range(185,535),0))
		2:
			pos=Vector2(240,560); velocity.y=-540
			var x=240.0
			for i in range(7):
				if i>0: x=clampf(x+rng.randf_range(-145,145),65,415)
				platforms.append(Vector2(x,600-i*92)); platform_ids.append(i)
			platform_serial=7
		3: shuffle_crowd()
func new_target():
	target=Vector2(rng.randf_range(45,435),rng.randf_range(55,665))
	last_target_at=elapsed
func shuffle_crowd():
	crowd.clear(); target_index=rng.randi_range(0,71)
	for i in range(72):
		var id=rng.randi_range(0,22)
		if id>=store.species(): id+=1
		crowd.append(Vector3(35+(i%8)*65+rng.randf_range(-9,9),50+int(i/8)*75+rng.randf_range(-10,10),-1 if i==target_index else id))
	zoomed=false; camera_offset=Vector2.ZERO
func board_rect()->Rect2:
	var available_size=Vector2(size.x-24,size.y-155)
	var scale_factor=minf(available_size.x/WORLD.x,available_size.y/WORLD.y)
	var dims=WORLD*scale_factor
	return Rect2(Vector2((size.x-dims.x)*0.5,75+(available_size.y-dims.y)*0.5),dims)
func to_world(p:Vector2)->Vector2:
	var r=board_rect()
	return (p-r.position)*WORLD/r.size
func _gui_input(event:InputEvent):
	if over: return
	if event is InputEventScreenTouch:
		last_input_touch=Time.get_ticks_msec()
		if event.pressed: begin_press(event.position)
		else: end_press(event.position)
	elif event is InputEventScreenDrag:
		last_input_touch=Time.get_ticks_msec(); move_press(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and Time.get_ticks_msec()-last_input_touch>250:
		if event.pressed: begin_press(event.position)
		else: end_press(event.position)
	elif event is InputEventMouseMotion and dragging: move_press(event.position)
func begin_press(p:Vector2):
	if not board_rect().has_point(p): return
	press_at=to_world(p); drag_at=press_at; dragging=true
	started=true
	match mode:
		0:
			if press_at.distance_to(target)<48:
				combo+=1; best_combo=maxi(combo,best_combo)
				var points=1+mini(3,int(combo/5))
				score+=points; flash(target,"+"+str(points)); new_target()
			else: combo=0
		1: velocity.y=-370
		2: steer=clampf((press_at.x-pos.x)/55,-1,1)
func move_press(p:Vector2):
	if not dragging: return
	var point=to_world(p)
	if mode==2: steer=clampf((point.x-pos.x)/55,-1,1)
	if mode==3 and zoomed:
		camera_offset-=(point-drag_at)
		camera_offset=camera_offset.clamp(Vector2.ZERO,Vector2(75,75))
	drag_at=point
func end_press(p:Vector2):
	if not dragging: return
	var point=to_world(p)
	dragging=false
	steer=0
	if mode!=3 or point.distance_to(press_at)>20: return
	var nearest=-1; var best=32.0
	for i in range(crowd.size()):
		var v=crowd[i]
		var dist=point.distance_to(crowd_point(v))
		if dist<best: best=dist; nearest=i
	if nearest<0: return
	if nearest==target_index:
		score+=1; flash(crowd_point(crowd[nearest]),"FOUND!")
		if score>=8: over=true
		else: shuffle_crowd()
	else:
		wrong+=1; flash(point,"TRY AGAIN")
		if wrong>=5: over=true
func toggle_zoom():
	zoomed=not zoomed; camera_offset=Vector2(35,35) if zoomed else Vector2.ZERO
	queue_redraw()
func crowd_point(v:Vector3)->Vector2:
	return Vector2(v.x,v.y)*(1.12 if zoomed else 0.88)-camera_offset+Vector2(5,25)
func _physics_process(dt:float):
	feedback=maxf(0,feedback-dt)
	if started and not over:
		elapsed+=dt
		match mode:
			0:
				if elapsed-last_target_at>maxf(0.65,2.4-score*0.05): combo=0; new_target()
				if elapsed>=20: over=true
			1:
				velocity.y+=920*dt; pos.y+=velocity.y*dt
				var gap=gap_height()
				var speed=pipe_speed()
				for i in range(pipes.size()):
					pipes[i].x-=speed*dt
					var p=pipes[i]
					if absf(p.x-pos.x)<57 and (pos.y-20<p.y-gap or pos.y+20>p.y+gap): over=true
					if p.x+35<pos.x-20 and p.z==0 and not over: score+=1; pipes[i].z=1; flash(pos,"+1")
					if p.x< -65:
						var far=0.0
						for pipe in pipes: far=maxf(far,pipe.x)
						pipes[i]=Vector3(far+230,rng.randf_range(185,535),0)
				if pos.y<20 or pos.y>700: over=true
			2:
				if Input.is_action_pressed("ui_left"): steer=-1
				elif Input.is_action_pressed("ui_right"): steer=1
				elif not dragging: steer=0
				var old_y=pos.y
				pos.x=fposmod(pos.x+steer*310*dt,WORLD.x)
				velocity.y+=850*dt; pos.y+=velocity.y*dt
				for i in range(platforms.size()):
					var p=platforms[i]
					if velocity.y>0 and old_y+23<=p.y and pos.y+23>=p.y and absf(pos.x-p.x)<62:
						pos.y=p.y-23; velocity.y=-570
						if not scored_platforms.has(platform_ids[i]):
							scored_platforms[platform_ids[i]]=true; score+=1; flash(pos,"+1")
						break
				if pos.y<285:
					var shift=285-pos.y; pos.y=285; height_score+=shift
					for i in range(platforms.size()):
						platforms[i].y+=shift
						if platforms[i].y>750:
							var high=720.0; var x=240.0
							for p in platforms:
								if p.y<high: high=p.y; x=p.x
							platforms[i]=Vector2(clampf(x+rng.randf_range(-150,150),65,415),high-92-minf(40,score*1.5))
							scored_platforms.erase(platform_ids[i]); platform_ids[i]=platform_serial; platform_serial+=1
				if pos.y>760: over=true
			3:
				if elapsed>=60: over=true
		# Flappy and Cloud Jump are endless skill runs; only timed modes have a limit.
	if is_instance_valid(title): update_labels()
	queue_redraw()
func update_labels():
	var key="%d:%d:%d:%d:%s:%s"%[score,combo,wrong,ceili(elapsed),started,over]
	if key==last_label_key: return
	last_label_key=key
	title.text=NAMES[mode]+"  •  "+str(score)
	timer_bar.value=maxf(0,round_limit()-elapsed)
	hint.text="Tap stars • Combo ×%d • %ds"%[combo,ceili(maxf(0,20-elapsed))] if mode==0 else "Tap to flap" if mode==1 else "Hold left / right to steer" if mode==2 else "Find your pet • %d/5 misses • %ds"%[wrong,ceili(maxf(0,60-elapsed))]
	if not started: hint.text="Tap the game to start"
	if over:
		hint.text="Round complete • Score "+str(score); done.show()
		var reward=mini(100,score*[2,6,4,10][mode]) if elapsed>=1.0 else 0
		result_label.text="ROUND COMPLETE\n%d points  •  +%d coins"%[score,reward]; result_label.show()
func finish():
	if claimed: return
	claimed=true
	store.finish_arcade(score,elapsed)
	get_tree().change_scene_to_file("res://hub.tscn")
func draw_pet(center:Vector2,diameter:float,texture:Texture2D,tint:Color=Color.WHITE):
	if texture!=null:
		draw_texture_rect(texture,Rect2(center-Vector2.ONE*diameter/2,Vector2.ONE*diameter),false,tint)
	else:
		draw_circle(center,diameter*0.34,Color("#92c97e")*tint)
		draw_circle(center+Vector2(-diameter*.13,-diameter*.05),diameter*.035,Color("#162b38"))
		draw_circle(center+Vector2(diameter*.13,-diameter*.05),diameter*.035,Color("#162b38"))
func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),Color("#102332"))
	var r=board_rect()
	if r.size.x<=0 or r.size.y<=0: return
	draw_rect(r,Color("#234f64"))
	draw_set_transform(r.position,0,r.size/WORLD)
	if stage_texture!=null: draw_texture_rect(stage_texture,Rect2(Vector2.ZERO,WORLD),false)
	else:
		for i in range(9):
			var y=i*82.0
			draw_rect(Rect2(0,y,480,82),Color("#2d6279") if i%2==0 else Color("#305b72"))
	for i in range(7):
		var x=fposmod(i*113-elapsed*12,560)-40
		var y=65+fposmod(i*137,620)
		draw_circle(Vector2(x,y),33,Color("#ffffff16"))
		draw_circle(Vector2(x+28,y+5),24,Color("#ffffff16"))
	match mode:
		0:
			draw_circle(target,44,Color("#f9cf8e42"))
			var points=PackedVector2Array()
			for i in range(10):
				var angle=-PI/2+i*TAU/10
				points.append(target+Vector2(cos(angle),sin(angle))*(38 if i%2==0 else 17))
			if prop_textures.has("star"): draw_texture_rect(prop_textures.star,Rect2(target-Vector2.ONE*52,Vector2.ONE*104),false)
			else: draw_colored_polygon(points,Color("#ffda80"))
			draw_pet(Vector2(240,660),90,pet_texture)
		1:
			var gap=gap_height()
			for pipe in pipes:
				var x=pipe.x
				var upper=Rect2(x-35,0,70,maxf(0,pipe.y-gap))
				var lower=Rect2(x-35,pipe.y+gap,70,maxf(0,720-pipe.y-gap))
				if prop_textures.has("pipe"):
					var texture:Texture2D=prop_textures.pipe
					var region=Rect2(Vector2.ZERO,texture.get_size())
					draw_texture_rect_region(texture,upper,region)
					draw_texture_rect_region(texture,lower,region)
				else:
					draw_rect(upper,Color("#87bc97")); draw_rect(lower,Color("#87bc97"))
			draw_pet(pos,80,pet_texture)
		2:
			for p in platforms:
				if prop_textures.has("platform"): draw_texture_rect(prop_textures.platform,Rect2(p.x-62,p.y-12,124,38),false)
				else:
					draw_rect(Rect2(p.x-52,p.y,104,13),Color("#bce2cc"))
					draw_rect(Rect2(p.x-48,p.y+13,96,8),Color("#65a6a4"))
			draw_pet(pos,78,pet_texture)
		3:
			for i in range(crowd.size()):
				var v=crowd[i]; var p=crowd_point(v)
				if p.x<25 or p.x>455 or p.y<25 or p.y>695: continue
				draw_pet(p,58 if zoomed else 47,pet_texture if i==target_index else other_textures[int(v.z)])
	if feedback>0:
		var p=feedback_pos-Vector2(0,(1-feedback/0.65)*36)
		draw_string(ThemeDB.fallback_font,p,feedback_text,HORIZONTAL_ALIGNMENT_CENTER,-1,24,Color(1,.90,.55,feedback/0.65))
	draw_set_transform(Vector2.ZERO)
	# Mask the off-board geometry while retaining a crisp playfield.
	var ink=Color("#102332")
	draw_rect(Rect2(0,0,size.x,r.position.y),ink)
	draw_rect(Rect2(0,r.end.y,size.x,maxf(0,size.y-r.end.y)),ink)
	draw_rect(Rect2(0,r.position.y,r.position.x,r.size.y),ink)
	draw_rect(Rect2(r.end.x,r.position.y,maxf(0,size.x-r.end.x),r.size.y),ink)
	draw_rect(r,Color("#93c6c2"),false,2)
	if over: draw_rect(r,Color("#102332a0"))
