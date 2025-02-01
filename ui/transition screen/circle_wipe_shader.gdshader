// CC0 licence
// Credit Bramwell Williams

shader_type canvas_item;

instance uniform float circle_size : hint_range(0,1) = 0.5f;

void fragment() {
	COLOR.a = 1.0 - step(distance(vec2(0.5,0.5), UV), 1.0 - circle_size);
}