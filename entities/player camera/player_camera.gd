extends Camera2D

@export var static_speed: float = 120.0
@export var boost_speed: float = 240.0

var max_zoom: float = 4.0
var min_zoom: float = 1.0


func _process(delta: float) -> void:
	var speed: float = static_speed
	if Input.is_action_pressed("camera_speed_boost"):
		speed = boost_speed
	
	position += speed * Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")) * delta
	
	if Input.is_action_just_pressed("zoom_in"):
		if zoom.x < max_zoom:
			zoom *= 2.0
			global_position = get_global_mouse_position()
	elif Input.is_action_just_pressed("zoom_out"):
		if zoom.x > min_zoom:
			global_position += (global_position - get_global_mouse_position())
			zoom /= 2.0
			
		#global_position = get_global_mouse_position() / 4.0
	
	zoom = zoom.clamp(Vector2(1.0, 1.0), Vector2(4.0, 4.0))
	
	RenderingServer.global_shader_parameter_set("camera_zoom", zoom)
