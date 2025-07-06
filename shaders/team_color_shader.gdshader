shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform vec4 team_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Default to red
uniform sampler2D main_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_tint : source_color = vec4(1.0); // Multiplies with texture color

void fragment() {
	vec4 tex_color = texture(main_texture, UV);
	vec3 final_albedo = team_color.rgb * tex_color.rgb * albedo_tint.rgb;
	ALBEDO = final_albedo;
	// For now, simple alpha. Could be improved with texture alpha.
	ALPHA = team_color.a * tex_color.a * albedo_tint.a;

	// Basic metallic and roughness
	METALLIC = 0.0;
	ROUGHNESS = 0.8;
	SPECULAR = 0.2;
}
