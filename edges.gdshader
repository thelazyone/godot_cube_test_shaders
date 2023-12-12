shader_type spatial;
render_mode unshaded, depth_draw_opaque, depth_prepass_alpha;

// Inspired by https://godotshaders.com/shader/3d-pixel-art-outline-highlight-post-processing-shader/

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;



// User inputs:
uniform vec3 shadow_color : source_color = vec3(0.0);
uniform float line_thickness: hint_range(0.1, 8.) = 2.;
uniform float edge_sensitivity: hint_range(0., 10.) = 1.;
uniform float edge_threshold_min: hint_range(0., 10.) = .5;
uniform float edge_threshold_max: hint_range(0., 20.) = .8;
uniform float edge_threshold_ridges: hint_range(0., 20.) = 10.;
uniform float border_intensity: hint_range(0., 20.) = 5.;
uniform float dd_diff_thresh: hint_range(0., 1.) = .1;



vec2 getDepth(vec2 screen_uv, sampler2D depth_texture, mat4 inv_projection_matrix)
{
	float raw_depth = texture(depth_texture, screen_uv)[0];
	vec3 normalized_device_coordinates = vec3(screen_uv * 2.0 - 1.0, raw_depth);
    vec4 view_space = inv_projection_matrix * vec4(normalized_device_coordinates, 1.0);	
	view_space.xyz /= view_space.w;	
	return vec2(-view_space.z, raw_depth);
}


void fragment() {
	vec2 pixel_thickness = vec2(1./VIEWPORT_SIZE.xy)*line_thickness;

	float depth_diff = 0.0;
	float ridge_diff = 0.0;
	float neg_depth_diff = .5;
	
	vec2 depth_data = getDepth(SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
	float depth = depth_data.x;
	vec3 color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	vec3 minpoint_color = vec3(0.0); // setting as 00 to start
	
	vec2 min_depth_data = depth_data;
	float min_depth = 9999999.9; // set at max_float
	

	vec3 normal = texture(NORMAL_TEXTURE, SCREEN_UV).rgb * 2.0 - 1.0;
	
	for (float x = -line_thickness; x <= line_thickness;x += 1.0){
		for (float y = -line_thickness; y <= line_thickness; y += 1.0){
			if ((x == 0.0 && y == 0.0) || (line_thickness*line_thickness < (x*x + y*y))){
				continue;
			}
			
			// Calculating the depht of the end point and the mid-point between the center and the xy
			//***************************************
			//****OO--_******************************
			//**********---__************************
			//****************--dd--_****************			
			//************************---__**********
			//******************************--du*****
			//***************************************
			vec2 du_data = getDepth(SCREEN_UV+1.0*vec2(x, y)*pixel_thickness, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
			vec2 dd_data = getDepth(SCREEN_UV+0.5*vec2(x, y)*pixel_thickness, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
			float du = du_data.x;
			float dd = dd_data.x;
			
			// the difference between the two dephts indicate that the point is at an edge.
			float dd_diff = abs((depth - dd) - (dd - du)) * edge_sensitivity;
			
			if (dd_diff < dd_diff_thresh) 
			{
				continue;
			}
			
			depth_diff += 1000.;
			continue;
			
			float val = abs(depth - du) / (x*x + y*y) * dd_diff * dd_diff;
			val = clamp(val, edge_threshold_min, edge_threshold_max);
			depth_diff += clamp(val, edge_threshold_min, edge_threshold_max);
			ridge_diff += clamp(val, edge_threshold_max, edge_threshold_ridges);
			
			// If a point of min_depht is found, sets the color as the one at the endpoint.
			if (du < min_depth){
				min_depth = du;
				min_depth_data = du_data;
				minpoint_color = texture(SCREEN_TEXTURE, SCREEN_UV+vec2(x, y)*pixel_thickness).rgb;
				minpoint_color *= clamp(0.5+ 0.5*dot(normalize(vec2(x, y)), (vec2(0.0, 1.0))), 0.0, 1.0);
			}
			
			vec3 normal_on_xy = texture(NORMAL_TEXTURE, SCREEN_UV+vec2(x, y)*pixel_thickness).rgb * 2.0 - 1.0;
			depth_diff += (1.0-abs(dot(normal_on_xy, normal)))/max(min(dd, depth), 2.0);
		}
	}

	depth_diff = smoothstep(.2, .3, depth_diff / (line_thickness * line_thickness));

	ALBEDO = minpoint_color * shadow_color;

	float alpha_mask = depth_diff;
	DEPTH = min_depth_data.y*alpha_mask + depth_data.y*(1.0-alpha_mask);
	ALPHA = clamp((alpha_mask) * border_intensity, 0., 1.);
}