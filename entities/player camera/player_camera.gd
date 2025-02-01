extends Camera2D

@export var static_speed: float = 120.0

func _process(delta: float) -> void:
	position += static_speed * Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")) * delta
