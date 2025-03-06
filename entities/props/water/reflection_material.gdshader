shader_type canvas_item;


global uniform vec2 camera_zoom; 

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float local_position = UV.y * 50.75; // UV.y / TEXTURE_PIXEL_SIZE.y;
	float screen_position = SCREEN_UV.y * (1.0 / SCREEN_PIXEL_SIZE.y) / 5.05;
	float reflected_position = (screen_position - 2.0 * local_position);
	float reflected_uv = reflected_position / 104.0; 
	
	//vec2 reflected_uv = vec2(SCREEN_UV.x, dif_uv.y);
	
	COLOR = texture(screen_texture, vec2(SCREEN_UV.x, reflected_uv));
	//COLOR = vec4(reflected_uv);
	//COLOR = vec4(UV.y);
}

// local: 9
// screen: 40

// reflect screen: 21


// dif 2 * (55 - 2.0 * 14) = 55 - 28 = 27