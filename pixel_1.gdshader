shader_type canvas_item;

// Setting the pixel size as an external input
uniform int pixelSize: hint_range(2, 32, 2) = 2;
uniform int colorRange: hint_range (1, 64, 1) = 16;
uniform float hardness: hint_range (0., 1.) = 0.5;
uniform float dither: hint_range (0., 1.) = 0.5;

// Screen coordinated are sampled
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D screen_texture_near : hint_screen_texture, filter_nearest_mipmap;

// Simple random function from https://thebookofshaders.com/10/
float random2D (vec2 coord) {
    return fract(sin(dot(coord.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Determining whether the current point is using the bottom or top value.
float discreteWithDither (float value, float stepValue, vec2 coord) {
	
	// Calculating the remainder
	float floorValue = (stepValue * floor (value/stepValue));
	float remainderValue = value - floorValue;
	

	// if remainder is low, chances should be that the dither is on the bottom one
	if (((1. - dither) / 2.) + random2D(coord) * dither > smoothstep((1. - dither) / 2., (1. + dither) / 2., remainderValue / stepValue)) {
		return floorValue;
	}
	else
	{
		return floorValue + stepValue;
	}
}

void fragment () 
{
	// Setting the pixel size to calculate the reduction
	vec2 iRse = 1.0 / SCREEN_PIXEL_SIZE;
	float onePixelSizeX = 1.0  / iRse.x;
	float onePixelSizeY = 1.0  / iRse.y;

	float cellSizeX = float(pixelSize) * onePixelSizeX;
	float cellSizeY = float(pixelSize) * onePixelSizeY;

	// From the UV value (the rough render) of the point, calculating.
	float x = cellSizeX * floor(UV.x / cellSizeX);
	float y = cellSizeY * floor(UV.y / cellSizeY);
	
	// mixing the interpolated texture with the nearest one: if it's too close to the nearest
	// using the nearest instead.
	vec4 output_texture = texture(screen_texture, vec2(x, y));;
	//if (abs(dot(texture(screen_texture, vec2(x, y)), texture(screen_texture_near, vec2(x, y)))) < 1. - hardness) {
		//output_texture = texture(screen_texture_near, vec2(x, y));
	//}
	output_texture = texture(screen_texture_near, vec2(x, y)) * hardness + output_texture * (1. - hardness); 
	
			
	// Finally setting the output colour per pixel (and subpixel)
	// But sub-sampling the colour tones into a more 8 bit style.bool
	// TODO go for a proper palette instead!
	float colorStepF = 1. / float(colorRange);
	float r = discreteWithDither(output_texture[0], colorStepF, vec2(x, y));
	float g = discreteWithDither(output_texture[1], colorStepF, vec2(x, y));
	float b = discreteWithDither(output_texture[2], colorStepF, vec2(x, y));
	
	COLOR = vec4(r,g,b,output_texture[3]);;
}




