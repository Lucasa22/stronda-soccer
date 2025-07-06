shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

// It's good practice to provide a hint for color uniforms if they are meant for srgb colors.
uniform vec4 team_color : source_color, hint_color = vec4(0.5, 0.5, 1.0, 1.0); // Default to a pleasant blue

void fragment() {
	ALBEDO = team_color.rgb;
	METALLIC = 0.1;    // Slightly metallic to give some sheen
	ROUGHNESS = 0.7;   // Not too glossy, not too matte
	SPECULAR = 0.3;    // Moderate specular reflection
}

// void light() {
	// Optional: Add custom light interactions if needed later
// }
