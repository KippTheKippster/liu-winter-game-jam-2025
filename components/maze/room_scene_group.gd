extends Resource
class_name RoomSceneGroup

@export var room_scenes: Array[PackedScene] = []

func get_random_scene(rng: RandomNumberGenerator) -> PackedScene:
	return room_scenes[rng.randi() % room_scenes.size()]
