extends Camera2D

@export var static_speed: float = 120.0

func _process(delta: float) -> void:
	position += static_speed * Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")) * delta
	
	if Input.is_action_just_pressed("zoom_in"):
		zoom *= 2.0
		global_position = get_global_mouse_position()
	elif Input.is_action_just_pressed("zoom_out"):
		
		zoom /= 2.0
		#global_position = get_global_mouse_position() / 4.0


	zoom = zoom.clamp(Vector2(1.0, 1.0), Vector2(4.0, 4.0))
