extends Node2D
class_name TargetDetector

@export var active: bool = true
@export var range: float = 48.0:
	set(value):
		range = value
		#range_squared = pow(value, 2.0)

@export_flags("Penguin", "Food", "Danger", "Penguin Carriable") var mask: int

var range_squared: float:
	set(value):
		range_squared = value
		#range = pow(range_squared, 0.5)

func _ready() -> void:
	range_squared = range * range


func get_next_target() -> Target:
	if not active:
		return
	
	var targets := get_tree().get_nodes_in_group("target")
	var closest_distance := range_squared
	var closest_target: Target
	for target: Target in targets:
		if target.active and mask & target.layer > 0:
			var distance := global_position.distance_squared_to(target.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_target = target
	
	return closest_target
