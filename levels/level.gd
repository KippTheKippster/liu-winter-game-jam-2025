extends Node2D

func _ready() -> void:
	y_sort_enabled = true
	if get_tree().current_scene == self:
		Game.current_level_path = scene_file_path
		get_tree().change_scene_to_file.call_deferred("uid://doiwfgk1hy5nb")
