extends Node2D
class_name Maze

@export var generate_on_ready: bool = true
@export var maze_properties: MazeProperties

var rng := RandomNumberGenerator.new()

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
	if generate_on_ready:
		generate_room_layout.call_deferred()


func generate_room_layout():
	"""
	for x in layout_image.get_width():
		for y in layout_image.get_height():
			var normalized_pixel = (layout_image.get_pixel(x, y).r - min_value) / (max_value - min_value) 
			if normalized_pixel > 0.5:
				room_scenes[Vector2i(x, y)] = preload("res://entities/rooms/room_corridor_001.tscn")
	"""
	#for i in 8:
	#	create_path(Vector2i.ZERO, Vector2i(Vector2.from_angle(randi_range(0, 3) * PI / 2.0)),
	#	3, 1, 3)
	
	if maze_properties.seed == 0:
		rng.randomize()
	else:
		rng.seed = maze_properties.seed
	
	print("Generating Maze with seed: ", rng.seed)
	
	var end_coords_list: Array[Vector2i] = []
	
	for i in maze_properties.path_amount:
		end_coords_list.append(create_path(Vector2i.ZERO, 
		Vector2i(Vector2.from_angle(rng.randi_range(0, 3) * PI / 2.0)),
		maze_properties.path_turn_amount,
		maze_properties.path_min_length,
		maze_properties.path_max_length))
	
	var distinct_scene_groups := maze_properties.distinct_room_scene_groups.duplicate()
	#distinct_scene_groups.append(maze_properties.room_scene_group_raft)
	distinct_scene_groups[maze_properties.room_scene_group_raft] = 1
	
	for room_scene_group: RoomSceneGroup in distinct_scene_groups:
		var amount: int = distinct_scene_groups[room_scene_group]
		for i in amount:
			var index := rng.randi() % end_coords_list.size()
			room_scenes[end_coords_list[index]] = room_scene_group.get_random_scene(rng)
			end_coords_list.remove_at(index)
	
	room_scenes[Vector2i.ZERO] = maze_properties.room_scene_group_start_point.get_random_scene(rng)
	room_scenes[Vector2i(-1, 0)] = maze_properties.room_scene_group_igloo.get_random_scene(rng)
	room_scenes[Vector2i(1, 0)] = maze_properties.room_scene_group_boffus.get_random_scene(rng)
	
	instantiate_rooms()


func create_path(start_coords: Vector2i, start_direction: Vector2i = Vector2i.RIGHT, turns: int = 4, min_length: int = 1, max_length: int = 2) -> Vector2i:
	var current_coords: Vector2i = start_coords
	var current_direction: Vector2 = start_direction
	for i in turns:
		for j in rng.randi_range(min_length, max_length):
			#print(current_coords)
			var scene_group: RoomSceneGroup
			var _rand := rng.randf()
			#if rand < 0.8:
			scene_group = maze_properties.room_scene_group_corridor
			#elif rand < 0.92:
			#	scene_group = ROOM_SCENE_GROUP_ENEMIES
			#else:
			#	scene_group = ROOM_SCENE_GROUP_FISHING_HOLES
				
			room_scenes[current_coords] = scene_group.get_random_scene(rng)
			current_coords += Vector2i(current_direction)
		
		current_direction = Vector2.from_angle(current_direction.angle() + (-1 + 2 * rng.randi_range(0, 1)) * PI / 2.0)
	
	return current_coords

func instantiate_rooms() -> void: 
	for coords: Vector2i in room_scenes.keys():
		var room_root := room_scenes[coords].instantiate()
		var room := Utils.find_child_of_class(room_root, "Room", false) as Room
		room.set_room_coords(coords)
		add_child(room_root)
		room_instances[coords] = room
	
	for coords: Vector2i in room_instances.keys():
		var room := room_instances[coords]
		for vector in NEIGHBOR_VECTORS:
			if room_instances.has(coords + vector):
				room.neigbor_directions.append(vector)
	
	for room: Room in room_instances.values():
		room.update_layout()
