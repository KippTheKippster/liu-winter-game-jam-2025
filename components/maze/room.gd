extends Node2D
class_name Room

signal layout_updated

var neigbor_directions: Array[Vector2i]

@export var walls: Dictionary[Vector2i, Node2D]

@export_flags("Right", "DownRight", "Down", "DownLeft", "Left", "UpLeft", "Up", "UpRight")
var removable_walls: int = 1 + 2 + 4 + 8 + 16 + 32 + 64 + 128

func set_room_coords(coords: Vector2i) -> void:
	var parent_2d := get_parent() as Node2D
	parent_2d.position = Vector2(coords) * Maze.ROOM_PIXEL_SIZE


func update_layout() -> void:
	for i in neigbor_directions.size():
		var direction := neigbor_directions[i]
		walls[direction].get_parent().remove_child(walls[direction])
		walls[direction].queue_free()
	
	layout_updated.emit()
