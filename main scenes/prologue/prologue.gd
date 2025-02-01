extends CanvasLayer

var allow_input: bool = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("action_1") and allow_input:
		GlobalUi.transition_screen.change_scene_to_file("uid://doiwfgk1hy5nb", "mosaic")


func _on_timer_timeout() -> void:
	allow_input = true
