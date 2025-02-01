@icon("assets/flip_group_icon.svg")
extends Node2D
class_name FlipGroup

@export_flags("Horizontal", "Vertical") var available_flip_directions: int = 1

func transform_direction(direction: Vector2) -> Vector2:
	var parent := get_parent() as Node2D
	if parent is not Node2D:
		return direction
	
	return (direction * parent.global_scale).rotated(parent.global_rotation)


func get_transformed_scale() -> Vector2:
	return transform_direction(scale)


func limit_direction_to_available_flip_directions(direction: Vector2) -> Vector2:
	var transformed_scale := get_transformed_scale()
	if direction.x == 0 or available_flip_directions & 1 == 0:
		direction.x = transformed_scale.x
	
	if direction.y == 0 or available_flip_directions & 2 == 0:
		direction.y = transformed_scale.y
	
	return direction


func get_look_direction() -> Vector2:
	var transformed_scale := get_transformed_scale()
	var direction: Vector2
	if available_flip_directions & 1 != 0:
		direction.x = transformed_scale.x
	
	if available_flip_directions & 2 != 0:
		direction.y = transformed_scale.y
		
	return direction


func flip_towards(direction: Vector2) -> void:
	scale = transform_direction(limit_direction_to_available_flip_directions(direction).sign())


func flip_towards_point(point: Vector2) -> void:
	flip_towards(point - global_position)


func flip_towards_node(node: Node2D) -> void:
	flip_towards_point(node.global_position)
