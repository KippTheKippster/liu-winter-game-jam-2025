extends Node2D
class_name Room

var neigbor_directions: Array[Vector2i]

var maze_parent: Maze

@export var walls: Dictionary[Vector2i, Node2D]

func set_room_coords(coords: Vector2i) -> void:
	var parent_2d := get_parent() as Node2D
	parent_2d.position = Vector2(coords) * Maze.ROOM_PIXEL_SIZE


func update_layout() -> void:
	for direction in neigbor_directions:
		walls[direction].get_parent().remove_child(walls[direction])
		walls[direction].queue_free()
