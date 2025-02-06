extends Resource
class_name RoomSceneGroup

@export var room_scenes: Array[PackedScene] = []

func get_random_scene() -> PackedScene:
	return room_scenes[randi() % room_scenes.size()]
