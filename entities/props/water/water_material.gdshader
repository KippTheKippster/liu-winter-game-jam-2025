shader_type canvas_item;

global uniform vec2 camera_zoom = vec2(1, 1);

uniform sampler2D sky_sampler : source_color, filter_nearest, repeat_enable;
uniform vec2 sky_texture_size;
uniform sampler2D noise_sampler_1 : repeat_enable, filter_nearest;

void fragment() {
	//TEXTURE_PIXEL_SIZE
	//vec2 screen_scale = ((SCREEN_PIXEL_SIZE / TEXTURE_PIXEL_SIZE)) / camera_zoom;
	vec2 screen_scale = ((1.0 / SCREEN_PIXEL_SIZE) / sky_texture_size) / camera_zoom;

	vec4 noise_color = texture(noise_sampler_1, UV + vec2(0.025, 0.025) * TIME);
	vec2 center_offset = 0.5 * (vec2(1.0) - vec2(1.0 / (camera_zoom)));

	COLOR = texture(sky_sampler, SCREEN_UV * screen_scale + center_offset + vec2(8, 8) * SCREEN_PIXEL_SIZE * noise_color.r);
	//COLOR = noise_color;
}