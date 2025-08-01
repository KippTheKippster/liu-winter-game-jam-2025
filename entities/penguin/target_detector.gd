extends Node2D
class_name TargetDetector

@export var active: bool = true
@export var detection_range: float = 48.0

@export_flags("Penguin", "Food", "Danger", "Penguin Carriable") var mask: int

var range_squared: float:
	set(value):
		range_squared = value
		#range = pow(range_squared, 0.5)


func get_next_target() -> Target:
	if not active:
		return
	
	var targets := get_tree().get_nodes_in_group("target")
	var closest_distance := detection_range * detection_range
	var closest_target: Target
	for target: Target in targets:
		if target.active and mask & target.layer > 0:
			var distance := global_position.distance_squared_to(target.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_target = target
	
	
	AudioServer
	
	return closest_target
