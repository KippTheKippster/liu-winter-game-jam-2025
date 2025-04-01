extends Node2D
class_name FlowFieldWalker

@export var active: bool = true
@export var reverse_path: bool
@export var max_path_follow_length: int = 10
@export var cell_margin: float = 2.0

var used: bool

var flow_field_manager: FlowFieldManager
var flow_field: FlowField
var current_coords: Vector2i

var target_coords: Vector2i:
	get:
		if not active:
			return Vector2i.ZERO
		
		return flow_field_manager.point_to_coords(target_point)
	set(value):
		if not active:
			return
		
		target_point = flow_field_manager.coords_to_point(value)


var target_point: Vector2:
	set(value): 
		used = true
		var old_coords := target_coords
		target_point = value
		var new_coords := target_coords
		if old_coords != new_coords:
			if flow_field:
				flow_field_manager.remove_user_from_flow_field(old_coords)
				flow_field = null
			
			flow_field = flow_field_manager.add_user_to_flow_field(new_coords)


func _enter_tree() -> void:
	flow_field_manager = Utils.find_child_of_class(get_tree().root, "FlowFieldManager")
	if not flow_field_manager:
		push_error("FlowFieldWalker unable to find FlowFieldManager!")
		active = false
		return
	
	if used:
		target_point = target_point
	else:
		current_coords = flow_field_manager.point_to_coords(global_position)


func _exit_tree() -> void:
	if flow_field_manager and flow_field:
		flow_field_manager.remove_user_from_flow_field(target_coords)
		flow_field = null


func _process(delta: float) -> void:
	if not active:
		return
	
	if flow_field_manager.coords_to_point(current_coords).distance_to(global_position) > flow_field_manager.cell_size + cell_margin:
		current_coords = flow_field_manager.point_to_coords(global_position)


func get_direction() -> Vector2:
	if not active:
		return Vector2.ZERO
	
	var coords := current_coords #flow_field_manager.point_to_coords(global_position) #current_coords #
	var cell_path := get_cell_path(coords)
	var direction := Vector2.ZERO
	var direction_sign := 1 
	if reverse_path:
		cell_path.reverse()
		direction_sign = -1
	
	for i in cell_path.size():
		direction += Vector2(cell_path[i]).normalized() * direction_sign
	
	var cell_value := flow_field.get_cell_value(coords)
	if direction == Vector2.ZERO and cell_value == -1:
		return Vector2.ZERO 
	
	if direction == Vector2.ZERO or cell_value < max_path_follow_length:
		if cell_path.size() == max_path_follow_length:
			direction += (target_point - global_position).normalized() * direction_sign
	
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
