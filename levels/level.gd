extends Node2D
class_name Level

@export var camera_limit: Rect2i
@export var start_marker: Marker2D
var start_position: Vector2
@export_file("*.tscn", "*.scn") var next_level_path: String = "res://levels/level_001.tscn"

func _ready() -> void:
	y_sort_enabled = true
	start_position = start_marker.global_position
	if get_tree().current_scene == self:
		Game.current_level_path = scene_file_path
		get_tree().change_scene_to_file.call_deferred("uid://doiwfgk1hy5nb")
