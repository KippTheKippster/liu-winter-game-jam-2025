@tool
extends Node2D
class_name Level

const Raft = preload("uid://dw4yqocvldxan")

@export var hub: bool
@export var camera_limit: Rect2i:
	set(value):
		camera_limit = value
		queue_redraw()

@export var main_start_marker: Marker2D
@export var special_start_markers: Node2D 
@export var raft: Raft
var start_position: Vector2
@export_file("*.tscn", "*.scn") var next_level_path: String = "uid://cti12nwlj0c2n"

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	y_sort_enabled = true
	start_position = main_start_marker.global_position
	if get_tree().current_scene == self:
		print(scene_file_path)
		Game.current_level_path = scene_file_path
		get_tree().change_scene_to_file.call_deferred("uid://doiwfgk1hy5nb")


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	
	draw_rect(camera_limit, Color.REBECCA_PURPLE, false)
