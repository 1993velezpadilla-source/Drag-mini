extends VBoxContainer
const Data=preload("res://research_data.gd")
signal resolved(answer:Array,phase:float)
var region:int
var target:int
var step:int
var elapsed=0.0
var phase=0.0
var active=true
var hidden=false
var sequence:Array[int]=[]
var entered:Array[int]=[]
var readout:Label
var track:ProgressBar
var prompt:Label
var buttons:Array[Button]=[]
var assisted=false
var skill_button:Button
var symbols=["▲","◆","●","■"]
func setup(r:int,id:int,n:int):
	region=r; target=id; step=n
	add_theme_constant_override("separation",8)
	prompt=Label.new(); prompt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; prompt.add_theme_font_size_override("font_size",18); add_child(prompt)
	readout=Label.new(); readout.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; readout.add_theme_font_size_override("font_size",27); add_child(readout)
	if r==1:
		prompt.text="Catch the current! Tap Collect while the marker is inside the bright center."
		var area=Control.new(); area.custom_minimum_size.y=50; add_child(area)
		track=ProgressBar.new(); track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); track.show_percentage=false; track.max_value=100; area.add_child(track)
		var zone=ColorRect.new(); zone.color=Color("#afffe660"); zone.mouse_filter=Control.MOUSE_FILTER_IGNORE; zone.anchor_left=.38; zone.anchor_right=.62; zone.anchor_top=0; zone.anchor_bottom=1; area.add_child(zone)
		var go=make_button(self,"Collect trace",func(): finish([],phase)); go.custom_minimum_size.y=60
	else:
		sequence=Data.trial_sequence(r,id,n)
		if r==2: symbols=["↑","→","↓","←"]
		prompt.text="Remember the footprints in order." if r==0 else "Follow the wind arrows in order."
		readout.text=sequence_text()
		var row=HBoxContainer.new(); add_child(row)
		for k in range(4):
			var b=make_button(row,symbols[k],func(): press_symbol(k)); b.disabled=r==0; buttons.append(b)
		if r==2: hidden=true
func add_skill(fn:Callable):
	skill_button=make_button(self,Data.ABILITIES[region]+" · use daily skill",func():
		if active and fn.call():
			assisted=true; skill_button.disabled=true; skill_button.text="Companion skill active"
			if region==0 and entered.is_empty():
				hidden=false; elapsed=0.0; readout.text=sequence_text()
				for b in buttons:b.disabled=true
			elif region==2 and entered.is_empty():
				entered.append(sequence[0]); readout.text=sequence_text())
	skill_button.add_theme_font_size_override("font_size",15)
func make_button(parent:Node,text:String,fn:Callable)->Button:
	var b=Button.new(); b.text=text; b.custom_minimum_size=Vector2(0,54); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.mouse_filter=Control.MOUSE_FILTER_PASS; b.action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE
	var st=StyleBoxFlat.new(); st.bg_color=Data.TINTS[region].darkened(.64); st.border_color=Data.TINTS[region]; st.set_border_width_all(2); st.set_corner_radius_all(14)
	b.add_theme_stylebox_override("normal",st); b.add_theme_font_size_override("font_size",22); b.pressed.connect(fn); parent.add_child(b); return b
func sequence_text()->String:
	var parts:PackedStringArray=[]
	for k in range(sequence.size()):
		parts.append("✓" if k<entered.size() else symbols[sequence[k]])
	return "  ".join(parts)
func press_symbol(k:int):
	if not active or not hidden:return
	entered.append(k)
	if entered[-1]!=sequence[entered.size()-1] or entered.size()==sequence.size():finish(entered,-1.0)
	elif region==2:readout.text=sequence_text()
	else:readout.text="%d / %d remembered"%[entered.size(),sequence.size()]
func finish(answer:Array,p:float):
	if not active:return
	active=false
	resolved.emit(answer,p)
func _process(dt:float):
	if not active:return
	elapsed+=dt
	if region==1:
		phase=0.5+0.5*sin(elapsed*(1.8 if assisted else 3.7)+float(target))
		track.value=phase*100
		readout.text="NOW!" if phase>=.38 and phase<=.62 else "Watch the current"
	elif region==0 and not hidden and elapsed>=(4.0 if assisted else 2.0):
		hidden=true; readout.text="Your turn"; prompt.text="Repeat the footprint sequence."
		for b in buttons:b.disabled=false
