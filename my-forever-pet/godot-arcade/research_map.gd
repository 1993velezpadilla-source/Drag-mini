extends Control
const Data=preload("res://research_data.gd")
signal site_selected(site:int)
var region:int=0
var points=[Vector2(.16,.66),Vector2(.36,.30),Vector2(.65,.20),Vector2(.84,.46),Vector2(.65,.78),Vector2(.38,.85)]
var markers:Array[Button]=[]
var scout=Vector2(.5,.56)
var scout_pulse=0.0
var traveling=false
func setup(r:int,id:int,n:int,mask:int):
	region=r
	custom_minimum_size.y=340
	mouse_filter=MOUSE_FILTER_PASS
	for i in range(6):
		var b=Button.new(); b.custom_minimum_size=Vector2(88,58); b.mouse_filter=MOUSE_FILTER_PASS
		b.action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE; b.focus_mode=FOCUS_NONE
		b.text=Data.SIGNALS[r][Data.clue(id,n,i)].capitalize()+"\n"+str(i+1)
		b.tooltip_text=Data.SITES[r][i]
		b.add_theme_font_size_override("font_size",13)
		var st=StyleBoxFlat.new(); st.bg_color=Color("#23223bee"); st.border_color=Data.TINTS[r]; st.set_border_width_all(2); st.set_corner_radius_all(14)
		b.add_theme_stylebox_override("normal",st)
		var disabled=st.duplicate() as StyleBoxFlat; disabled.bg_color=Color("#24252d"); disabled.border_color=Color("#777777")
		b.add_theme_stylebox_override("disabled",disabled)
		b.disabled=(mask&(1<<i))!=0
		if b.disabled:b.text="Searched"
		b.pressed.connect(func(): investigate(i))
		add_child(b); markers.append(b)
	resized.connect(reflow)
	reflow.call_deferred()
func investigate(i:int):
	if traveling:return
	traveling=true
	for b in markers:b.disabled=true
	var tw=create_tween()
	tw.tween_property(self,"scout",points[i],.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func(): site_selected.emit(i))
func _process(dt:float):
	if is_visible_in_tree():
		scout_pulse=fposmod(scout_pulse+dt*2.2,TAU)
		queue_redraw()
func reflow():
	for i in range(markers.size()):
		markers[i].position=(points[i]*size-markers[i].custom_minimum_size*.5).clamp(Vector2(4,4),(size-markers[i].custom_minimum_size-Vector2(4,4)).max(Vector2(4,4)))
		markers[i].size=markers[i].custom_minimum_size
	queue_redraw()
func _draw():
	var w=size.x; var h=size.y
	if w<=0 or h<=0:return
	var tones=[[Color("#183b36"),Color("#337b50"),Color("#73b279")],[Color("#142c58"),Color("#215f8e"),Color("#47b4bd")],[Color("#25234e"),Color("#6955a4"),Color("#b0a5e0")]][region]
	for i in range(30):
		var y=float(i)/30
		draw_rect(Rect2(0,h*y,w,h/30+1),tones[0].lerp(tones[1],y))
	var rng=RandomNumberGenerator.new(); rng.seed=700+region
	if region==0:
		var river=PackedVector2Array([Vector2(w*.06,0),Vector2(w*.19,h*.24),Vector2(w*.45,h*.46),Vector2(w*.50,h*.72),Vector2(w*.85,h)])
		draw_polyline(river,Color("#216473"),32,true); draw_polyline(river,Color("#70b8b5"),19,true)
	elif region==1:
		for j in range(7):
			var y=h*(j+1)/8.0
			draw_polyline(PackedVector2Array([Vector2(0,y),Vector2(w*.3,y-14),Vector2(w*.7,y+8),Vector2(w,y-9)]),Color("#9ce6f04a"),3,true)
	else:
		for p in points:
			draw_circle(p*size+Vector2(0,10),47,Color("#453a70"));draw_circle(p*size,45,Color("#9c8ac8"))
	for i in range(36):
		var p=Vector2(rng.randf_range(0,w),rng.randf_range(0,h))
		var radius=rng.randf_range(9,35)
		if region==0:
			draw_circle(p+Vector2(2,6),radius,Color("#153e39"))
			draw_circle(p,radius,tones[1].lerp(tones[2],rng.randf_range(.0,.6)))
			draw_circle(p-Vector2(radius*.25,radius*.2),radius*.42,tones[2].darkened(.12))
		elif region==1:
			draw_arc(p,radius,0,TAU,24,Color("#7ce9eb45"),2,true)
			for j in range(3):draw_line(p,p+Vector2((j-1)*radius*.7,-radius),tones[2].darkened(.1),4,true)
		else:
			draw_circle(p,radius*.9,Color("#c7b6ef35"))
			draw_circle(p+Vector2(radius*.6,0),radius*.7,Color("#dfd7ff45"))
			draw_circle(p-Vector2(radius*.3,radius*.4),2,Color("#fff0c4"))
	var route=PackedVector2Array()
	for point in points:route.append(point*size)
	route.append(route[0])
	draw_polyline(route,Color("#10233b"),11,true)
	draw_polyline(route,Data.TINTS[region].darkened(.30),4,true)
	for i in range(6):
		draw_circle(points[i]*size,34,Color("#132238bb"))
		draw_arc(points[i]*size,35,0,TAU,36,Data.TINTS[region],2,true)
	var here=scout*size
	draw_circle(here,18+sin(scout_pulse)*3,Color("#ffdc8766"))
	draw_circle(here,12,Color("#f8d788"))
	draw_circle(here,7,Color("#fff6e5"))
