shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 team_color : source_color = vec4(0.5, 0.5, 1.0, 1.0);
uniform bool is_dribbling_active = false;
uniform float dribble_glow_intensity : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	ALBEDO = team_color.rgb;
	METALLIC = 0.1;
	ROUGHNESS = 0.7;
	SPECULAR = 0.3;

	if (is_dribbling_active) {
		EMISSION = ALBEDO * dribble_glow_intensity;
	} else {
		EMISSION = vec3(0.0);
	}
}

// void light() {
	// Optional: Add custom light interactions if needed later
// }
