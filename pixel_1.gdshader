shader_type canvas_item;

// Setting the pixel size as an external input
uniform int pixelSize: hint_range(4, 32, 4) = 2;
uniform int colorRange: hint_range (1, 32, 1) = 16;
uniform float hardness: hint_range (0., 1.) = 0.5;

// Screen coordinated are sampled
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D screen_texture_near : hint_screen_texture, filter_nearest_mipmap;

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
	float colorRangeF = float(colorRange);
	float r = floor(output_texture[0] * colorRangeF) / colorRangeF;
	float g = floor(output_texture[1] * colorRangeF) / colorRangeF;
	float b = floor(output_texture[2] * colorRangeF) / colorRangeF;
	
	COLOR = vec4(r,g,b,output_texture[3]);;
}




