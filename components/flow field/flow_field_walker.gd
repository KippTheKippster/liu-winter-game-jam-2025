extends Node2D
class_name FlowFieldWalker

@export var max_path_follow_length: int = 10

var flow_field_manager: FlowFieldManager
var flow_field: FlowField
"""
var target_point: Vector2:
	get:
		return flow_field_manager.coords_to_point(target_coords)
	set(value):
		target_coords = flow_field_manager.point_to_coords(value)

var target_coords: Vector2i:
	set(value):
		var old_value := target_coords
		target_coords = value
		if old_value != target_coords:
			if flow_field:
				flow_field_manager.remove_user_from_flow_field(old_value)
			
			flow_field = flow_field_manager.add_user_to_flow_field(target_coords)
"""
var target_coords: Vector2i:
	get:
		return flow_field_manager.point_to_coords(target_point)
	set(value):
		target_point = flow_field_manager.coords_to_point(value)


var target_point: Vector2:
	set(value):
		var old_coords := target_coords
		target_point = value
		var new_coords := target_coords
		if old_coords != new_coords:
			if flow_field:
				flow_field_manager.remove_user_from_flow_field(old_coords)
			
			flow_field = flow_field_manager.add_user_to_flow_field(new_coords)


func _ready() -> void:
	flow_field_manager = Utils.find_child_of_class(get_tree().root, "FlowFieldManager")


func get_direction() -> Vector2:
	var cell_size := flow_field.cell_size
	#var cell := (global_position / cell_size - Vector2(0.5, 0.5)).round()
	var cell := flow_field_manager.point_to_coords(global_position)
	var cell_path = get_cell_path(cell)
	var direction := Vector2.ZERO
	for i in cell_path.size():
		direction += Vector2(cell_path[i]).normalized()
	
	if direction == Vector2.ZERO or flow_field.get_cell_value(cell) < max_path_follow_length:
		direction += (target_point - global_position).normalized()
	
	return direction.normalized()


func get_cell_path(start_cell: Vector2i) -> Array[Vector2i]:
	var current_cell: Vector2i = start_cell
	var cell_path: Array[Vector2i] = [flow_field.get_cell_direction(current_cell, true)]
	cell_path.resize(max_path_follow_length)
	var used_directions: Array[Vector2i] = []
	
	# Stores cells that will be used for traversel and stores which directions will be used
	for i in range(1, max_path_follow_length):
		current_cell += cell_path[i - 1]
		var direction := flow_field.get_cell_direction(current_cell, true)
		cell_path[i] = direction
		if not used_directions.has(direction):
			used_directions.append(direction)
	
	current_cell = start_cell
	
	# Travels through the path to find where lerping the directions would lead to collision and truncates path til that point 
	for i in cell_path.size() - 1:
		for direction in used_directions:
			if not flow_field.is_cell_valid(current_cell + direction):
				cell_path.resize(i + 1)
				return cell_path
		
		current_cell += cell_path[i + 1]
	
	return cell_path

"""
func set_target_point(point: Vector2) -> void:
	_target_point = point
	_target_coords = flow_field_manager.point_to_coords(_target_point)
	flow_field = flow_field_manager.add_user_to_flow_field(_target_coords)


func clear_target_point() -> void:
	if flow_field:
		flow_field_manager.remove_user_from_flow_field(_target_coords)
"""
