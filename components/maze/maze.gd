extends Node2D
class_name Maze

@export var layout_texture: NoiseTexture2D

const ROOM_SCENE_GROUP_CORRIDORS: RoomSceneGroup = preload("res://entities/rooms/room scene groups/room_scene_group_corridors.tres")
const ROOM_SCENE_GROUP_ENEMIES: RoomSceneGroup = preload("res://entities/rooms/room scene groups/room_scene_group_enemies.tres")
const ROOM_SCENE_GROUP_FISHING_HOLES: RoomSceneGroup = preload("res://entities/rooms/room scene groups/room_scene_group_fishing_holes.tres")
const ROOM_SCENE_GROUP_STARTING_POINTS: RoomSceneGroup = preload("res://entities/rooms/room scene groups/room_scene_group_starting_points.tres")

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
	room_scenes[Vector2i(1, 1)] = preload("res://entities/rooms/room_start.tscn")
	room_scenes[Vector2i(0, 1)] = preload("res://entities/rooms/room_igloo.tscn")
	room_scenes[Vector2i(2, 1)] = preload("res://entities/rooms/room_boffus.tscn")
	room_scenes[Vector2i(3, 0)] = preload("res://entities/rooms/room_corridor_001.tscn")
	room_scenes[Vector2i(3, 1)] = preload("res://entities/rooms/room_corridor_002.tscn")
	room_scenes[Vector2i(3, 2)] = preload("res://entities/rooms/room_corridor_003.tscn")
	room_scenes[Vector2i(3, 2)] = preload("res://entities/rooms/room_tree_mimic_001.tscn")
	room_scenes[Vector2i(1, 2)] = preload("res://entities/rooms/room_fishing_hole_002.tscn")
	room_scenes[Vector2i(2, 2)] = preload("res://entities/rooms/room_corridor_001.tscn")
	room_scenes[Vector2i(0, 2)] = preload("res://entities/rooms/room_corridor_002.tscn")
	room_scenes[Vector2i(1, 0)] = preload("res://entities/rooms/room_corridor_003.tscn")
	room_scenes[Vector2i(2, 0)] = preload("res://entities/rooms/room_tree_mimic_002.tscn")
	room_scenes[Vector2i(0, -1)] = preload("res://entities/rooms/room_tree_mimic_001.tscn")
	room_scenes[Vector2i(0, 0)] = preload("res://entities/rooms/room_corridor_001.tscn")
	room_scenes[Vector2i(-1, -1)] = preload("res://entities/rooms/room_fishing_hole_002.tscn")
	room_scenes[Vector2i(-1, 0)] = preload("res://entities/rooms/room_tree_mimic_001.tscn")
	room_scenes[Vector2i(2, -1)] = preload("res://entities/rooms/room_fishing_hole_001.tscn")
	room_scenes[Vector2i(-1, 1)] = preload("res://entities/rooms/room_corridor_002.tscn")
	room_scenes[Vector2i(-2, 1)] = preload("res://entities/rooms/room_tree_mimic_001.tscn")
	room_scenes[Vector2i(-3, 1)] = preload("res://entities/rooms/room_tree_mimic_001.tscn")
	room_scenes[Vector2i(-4, 1)] = preload("res://entities/rooms/room_tree_mimic_001.tscn")
	room_scenes[Vector2i(-5, 1)] = preload("res://entities/rooms/room_big_meat.tscn")
	room_scenes[Vector2i(-1, 2)] = preload("res://entities/rooms/room_corridor_002.tscn")
	room_scenes[Vector2i(-1, 3)] = preload("res://entities/rooms/room_corridor_003.tscn")
	room_scenes[Vector2i(-1, 2)] = preload("res://entities/rooms/room_fishing_hole_001.tscn")
	room_scenes.clear()
	var fast_noise_lite := layout_texture.noise as FastNoiseLite
	fast_noise_lite.seed = randi()
	generate_room_layout.call_deferred()





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
	for i in 8:
		create_path(Vector2i.ZERO, Vector2i(Vector2.from_angle(randi_range(0, 3) * PI / 2.0)))
	
	
	room_scenes[Vector2i.ZERO] = ROOM_SCENE_GROUP_STARTING_POINTS.get_random_scene()
	room_scenes[Vector2i(-1, 0)] = preload("res://entities/rooms/room_igloo.tscn")
	room_scenes[Vector2i(1, 0)] = preload("res://entities/rooms/room_boffus.tscn")
	
	instantiate_rooms()


func create_path(start_coords: Vector2i, start_direction: Vector2i = Vector2i.RIGHT, turns: int = 4, min_length: int = 1, max_length: int = 2):
	var current_coords: Vector2i = start_coords
	var current_direction: Vector2 = start_direction
	for i in turns:
		print(current_direction)
		for j in randi_range(min_length, max_length):
			#print(current_coords)
			var scene_group: RoomSceneGroup
			var rand := randf()
			if rand < 0.8:
				scene_group = ROOM_SCENE_GROUP_CORRIDORS
			elif rand < 0.92:
				scene_group = ROOM_SCENE_GROUP_ENEMIES
			else:
				scene_group = ROOM_SCENE_GROUP_FISHING_HOLES
				
			room_scenes[current_coords] = scene_group.get_random_scene()
			current_coords += Vector2i(current_direction)
		
		current_direction = Vector2.from_angle(current_direction.angle() + (-1 + 2 * randi_range(0, 1)) * PI / 2.0)
