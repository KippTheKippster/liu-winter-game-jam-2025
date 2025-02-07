extends CanvasLayer


func _on_timer_timeout() -> void:
	GlobalUi.transition_screen.change_scene_to_file("uid://doiwfgk1hy5nb", "mosaic")
