shader_type canvas_item;

global uniform vec2 camera_zoom = vec2(1, 1);

uniform sampler2D sky_sampler : source_color, filter_nearest, repeat_enable;
uniform vec2 sky_texture_size;
uniform sampler2D noise_sampler_1 : repeat_enable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

varying vec2 a;

void vertex() {
	a = (CANVAS_MATRIX * MODEL_MATRIX * vec4(0, 0, 0, 0)).xy;
	//VERTEX.x += 4.0;
}

void fragment() {
	
	//TEXTURE_PIXEL_SIZE
	//vec2 screen_scale = ((SCREEN_PIXEL_SIZE / TEXTURE_PIXEL_SIZE)) / camera_zoom;
	vec2 screen_scale = ((1.0 / SCREEN_PIXEL_SIZE) / sky_texture_size) / camera_zoom;
	
	vec4 noise_color = texture(noise_sampler_1, UV + vec2(0.025, 0.025) * TIME);
	vec2 center_offset = 0.5 * (vec2(1.0) - vec2(1.0 / (camera_zoom)));
	
	noise_color.r = 0.0;
	
	COLOR = texture(sky_sampler, SCREEN_UV * screen_scale + center_offset + vec2(8, 8) * SCREEN_PIXEL_SIZE * noise_color.r);
	//COLOR = noise_color;
	
	vec2 screen_resolution = 1.0 / SCREEN_PIXEL_SIZE; 
	
	vec2 screen_coords = SCREEN_UV * screen_resolution;
	vec2 offset = UV * SCREEN_UV * screen_resolution; 
	
	float uv_height = SCREEN_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.y;
	
	//COLOR = texture(screen_texture, vec2(SCREEN_UV.x, SCREEN_UV.y + uv_height * UV.y * 2.0)); 
	// COLOR = texture(screen_texture, (FRAGCOORD.xy  ) * SCREEN_PIXEL_SIZE); 
	//COLOR = texture(screen_texture, vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y + a.y));
	//COLOR = vec4(1.0);
}  