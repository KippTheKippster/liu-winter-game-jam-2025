extends Node2D
class_name Maze

const NEIGHBOR_VECTORS: Array[Vector2i] = [
	Vector2i( 1,  0),
	Vector2i( 1,  1),
	Vector2i( 0,  1),
	Vector2i(-1,  1),
	Vector2i(-1,  0),
	Vector2i(-1, -1),
	Vector2i( 0, -1),
	Vector2i( 1, -1),

]

const ROOM_PIXEL_SIZE: Vector2 = Vector2(64, 64)
var room_scenes: Dictionary[Vector2i, PackedScene]
var room_instances: Dictionary[Vector2i, Room]

func _ready() -> void:
	room_scenes[Vector2i.ZERO] = preload("res://entities/rooms/room_template.tscn")
	room_scenes[Vector2i.RIGHT] = preload("res://entities/rooms/room_template.tscn")
	room_scenes[2 * Vector2i.RIGHT] = preload("res://entities/rooms/room_template.tscn")
	room_scenes[Vector2i.DOWN + Vector2i.RIGHT] = preload("res://entities/rooms/room_template.tscn")
	
	instantiate_rooms()


func instantiate_rooms() -> void: 
	for coords: Vector2i in room_scenes.keys():
		var room_root := room_scenes[coords].instantiate()
		var room := Utils.find_child_of_class(room_root, "Room", false) as Room
		room.set_room_coords(coords)
		room.maze_parent = self
		add_child(room_root)
		room_instances[coords] = room
	
	for coords: Vector2i in room_instances.keys():
		var room := room_instances[coords]
		for vector in NEIGHBOR_VECTORS:
			if room_instances.has(coords + vector):
				room.neigbor_directions.append(vector)
	
	for room: Room in room_instances.values():
		room.update_layout()
