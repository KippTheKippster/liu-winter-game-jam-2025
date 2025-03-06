extends Resource
class_name MazeProperties

@export var seed: int = 0
@export_group("Room Scene Groups")
@export var distinct_room_scene_groups: Dictionary[RoomSceneGroup, int]
@export_subgroup("Standard Room Scene Groups")
@export var room_scene_group_corridor: RoomSceneGroup = preload("res://entities/rooms/room scene groups/room_scene_group_corridor.tres")
@export var room_scene_group_start_point: RoomSceneGroup = preload("res://entities/rooms/room scene groups/room_scene_group_start_point.tres")
@export var room_scene_group_boffus: RoomSceneGroup = preload("res://entities/rooms/room scene groups/room_scene_group_boffus.tres")
@export var room_scene_group_igloo: RoomSceneGroup = preload("res://entities/rooms/room scene groups/room_scene_group_igloo.tres")
@export var room_scene_group_raft: RoomSceneGroup = preload("res://entities/rooms/room scene groups/room_scene_group_raft.tres")
@export_group("Path")
@export var path_amount: int = 8
@export var path_turn_amount: int = 4
@export var path_min_length: int = 1
@export var path_max_length: int = 2
