extends Node2D
class_name FlowFieldManager

@export var cell_size: int = 8


var flow_field_list: Dictionary[Vector2i, FlowField]
var flow_field_user_list: Dictionary[Vector2i, int]


func add_user_to_flow_field(target_coords: Vector2i) -> FlowField:
	print("Adding")
	flow_field_user_list.get_or_add(target_coords, 0)
	flow_field_user_list[target_coords] += 1
	
	if flow_field_list.has(target_coords):
		return flow_field_list[target_coords]
	
	var flow_field := FlowField.new()
	add_child(flow_field)
	flow_field.cell_size = cell_size
	flow_field.set_target_coords(target_coords)
	flow_field_list[target_coords] = flow_field
	return flow_field


func remove_user_from_flow_field(target_coords: Vector2i) -> void:
	print("Removing")
	flow_field_user_list[target_coords] -= 1
	if flow_field_user_list[target_coords] == 0:
		var flow_field := flow_field_list[target_coords]
		flow_field.queue_free() # Should they be removed or reused?
		remove_child(flow_field)
		flow_field_list.erase(target_coords)
		flow_field_user_list.erase(target_coords)


func get_flow_field_for_coords(target_coords: Vector2i) -> FlowField:
	if flow_field_list.has(target_coords):
		return flow_field_list[target_coords]
	
	var flow_field := FlowField.new()
	add_child(flow_field)
	flow_field.cell_size = cell_size
	flow_field.set_target_coords(target_coords)
	flow_field_list[target_coords] = flow_field
	return flow_field


func point_to_coords(point: Vector2) -> Vector2i:
	return Vector2i(point / cell_size)


func coords_to_point(coords: Vector2i) -> Vector2i:
	return Vector2(coords * cell_size)
