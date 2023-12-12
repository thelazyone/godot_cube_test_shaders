shader_type spatial;
render_mode unshaded, depth_draw_opaque, depth_prepass_alpha;

// Inspired by https://godotshaders.com/shader/3d-pixel-art-outline-highlight-post-processing-shader/

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;



// User inputs:
uniform vec3 shadow_color : source_color = vec3(0.0);
uniform float check_range: hint_range(1., 8.) = 2.;
uniform float spacing_threhsold: hint_range(.1, 5.) = .5;
uniform float line_thickness: hint_range(.1, 5.) = .5; // TODO to remove!
uniform float edge_intensity: hint_range(0., 5.) = 1.5;


vec2 getDepth(vec2 screen_uv, sampler2D depth_texture, mat4 inv_projection_matrix)
{
	float raw_depth = texture(depth_texture, screen_uv)[0];
	vec3 normalized_device_coordinates = vec3(screen_uv * 2.0 - 1.0, raw_depth);
    vec4 view_space = inv_projection_matrix * vec4(normalized_device_coordinates, 1.0);	
	view_space.xyz /= view_space.w;	
	return vec2(-view_space.z, raw_depth);
}


void fragment() {
	
	// Calculating for the position 
	vec2 depth_data = getDepth(SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
	
	// Cumulative vars.
	float edge_value = 0.;
	float ridge_value = 0.; 
		
	// TODO to remove!
	vec2 pixel_normalization = vec2(1./VIEWPORT_SIZE.xy);
	
		
	// Two checks are necessary - normals and distance. 
	// if distance changes, a shadow should be drawn.
	// if normal change, a light line should be drawn instead.
	
	// Checking distances: I'm expecting no discontinuity in the gradient, for now a simple 
	// threshold would do.
	for (float x = -check_range; x <= check_range;x += 1.0){
		for (float y = -check_range; y <= check_range; y += 1.0){
			if ((x == 0.0 && y == 0.0) || (check_range*check_range < (x*x + y*y))){
				continue;
			}
			// TODO probably the +vec is not in the same dimensions.
			vec2 du_data = getDepth(SCREEN_UV + vec2(x, y) * pixel_normalization, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
			if (abs(depth_data.x - du_data.x) > spacing_threhsold)
			{
				edge_value += 1.;
			}
		}
	}
	
	ALBEDO = texture(SCREEN_TEXTURE, SCREEN_UV).rgb * shadow_color;
	float alpha_mask = edge_value * edge_intensity / (check_range * check_range);
	ALPHA = clamp(alpha_mask, 0., 1.);
}