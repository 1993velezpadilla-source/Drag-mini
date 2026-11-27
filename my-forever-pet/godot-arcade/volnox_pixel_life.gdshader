shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D sprite_tex : source_color, filter_nearest, repeat_disable;
uniform vec4 biome_tint : source_color = vec4(0.9,0.95,1.0,1.0);
uniform float ambient_strength : hint_range(0.0,1.0) = 0.15;
uniform float hit_flash : hint_range(0.0,1.0) = 0.0;
uniform float magic_strength : hint_range(0.0,1.0) = 0.12;
uniform float pulse_offset = 0.0;
uniform float world_phase = 0.0;
uniform int region = 0;
varying vec3 actor_world;
void vertex() {
	actor_world = MODEL_MATRIX[3].xyz;
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	mat4 facing = mat4(INV_VIEW_MATRIX[0]*scale.x,INV_VIEW_MATRIX[1]*scale.y,INV_VIEW_MATRIX[2]*scale.z,MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * facing;
}
void fragment() {
	vec4 pixel = texture(sprite_tex, UV);
	if (pixel.a < 0.5) { discard; }
	vec2 size = vec2(textureSize(sprite_tex,0));
	vec2 p = (floor(UV*size)+vec2(0.5))/size;
	vec2 texel = 1.0/size;
	float left = texture(sprite_tex,p-vec2(texel.x,0.0)).a;
	float top = texture(sprite_tex,p-vec2(0.0,texel.y)).a;
	float right = texture(sprite_tex,p+vec2(texel.x,0.0)).a;
	float bottom = texture(sprite_tex,p+vec2(0.0,texel.y)).a;
	// Pixel-quantized directional rim and underside depth. No blur or geometry deformation.
	float edge_light = clamp((1.0-left)*0.06+(1.0-top)*0.08,0.0,0.14);
	float edge_dark = clamp((1.0-right)*0.035+(1.0-bottom)*0.05,0.0,0.085);
	float local_height = 1.0-p.y;
	vec3 base = mix(pixel.rgb,pixel.rgb*biome_tint.rgb,ambient_strength);
	base *= mix(0.89,1.08,local_height)+edge_light-edge_dark;
	float material_luma = dot(pixel.rgb,vec3(0.2126,0.7152,0.0722));
	// Preserve ink outlines and keep biome modulation restrained.
	float surface = smoothstep(0.12,0.5,material_luma);
	if (region==1) {
		float caustic = max(0.0,sin(p.x*19.0+p.y*14.0+actor_world.x*.7+world_phase*1.8));
		base += vec3(0.018,0.045,0.055)*caustic*surface;
	} else if (region==0) {
		base += vec3(0.035,0.04,0.012)*edge_light*surface;
	} else {
		base += vec3(0.025,0.017,0.045)*surface*max(0.0,sin(p.y*12.0+world_phase));
	}
	float magenta = max(0.0,min(pixel.r,pixel.b)-pixel.g);
	float pulse = 0.65+0.35*sin(TIME*3.0+pulse_offset);
	ALBEDO = mix(clamp(base,vec3(0.0),vec3(1.0)),vec3(1.0,0.88,0.93),hit_flash);
	EMISSION = vec3(1.0,0.24,0.8)*magenta*magic_strength*pulse;
	ALPHA = 1.0;
}
