shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D sprite_tex : source_color, filter_nearest, repeat_disable;
uniform vec4 biome_tint : source_color = vec4(0.9,0.95,1.0,1.0);
uniform float ambient_strength : hint_range(0.0,1.0) = 0.15;
uniform float hit_flash : hint_range(0.0,1.0) = 0.0;
uniform float magic_strength : hint_range(0.0,1.0) = 0.12;
uniform float pulse_offset = 0.0;
void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	mat4 facing = mat4(INV_VIEW_MATRIX[0]*scale.x,INV_VIEW_MATRIX[1]*scale.y,INV_VIEW_MATRIX[2]*scale.z,MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * facing;
}
void fragment() {
	vec4 pixel = texture(sprite_tex, UV);
	if (pixel.a < 0.5) { discard; }
	vec3 base = mix(pixel.rgb, pixel.rgb*biome_tint.rgb, ambient_strength);
	float magenta = max(0.0,min(pixel.r,pixel.b)-pixel.g);
	float pulse = 0.65+0.35*sin(TIME*3.0+pulse_offset);
	ALBEDO = mix(base,vec3(1.0,0.88,0.93),hit_flash);
	EMISSION = vec3(1.0,0.24,0.8)*magenta*magic_strength*pulse;
	ALPHA = 1.0;
}
