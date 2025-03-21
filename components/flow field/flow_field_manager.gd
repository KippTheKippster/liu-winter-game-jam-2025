extends Node2D
class_name FlowFieldManager

@export var flood_start_marker: Node2D
@export var cell_size: int = 8
@export var cells_rect: Rect2i = Rect2i(-25, -25, 75, 75)

var cells: Dictionary[Vector2i, int]

var flow_field_list: Dictionary[Vector2i, FlowField]
var flow_field_user_list: Dictionary[Vector2i, int]
var solid_cells: Dictionary[Vector2i, int]


func _enter_tree() -> void:
	if not is_in_group("flow_field_manager"):
		add_to_group("flow_field_manager")


func _ready() -> void:
	cells[Vector2i.ZERO] = -1
	#flood_cell.call_deferred.call_deferred(Vector2i(4, 4)) # UGLY
	for x in range(cells_rect.position.x, cells_rect.size.x):
		for y in range(cells_rect.position.y, cells_rect.size.y):
			cells[Vector2i(x, y)] = -1


func flood_cell(coords: Vector2i, count: int = 0) -> void:
	count += 1
	if count == 1024:
		print("Max flood cell reached!")
		return
	
	for i in FlowField.NeighborVectors.size():
		var neigbor_coords: Vector2i = coords + FlowField.NeighborVectors[i]
		if not cells.has(neigbor_coords) and solid_cells.get(neigbor_coords, 0) == 0:
			cells[neigbor_coords] = -1
			flood_cell(neigbor_coords, count)


func add_user_to_flow_field(target_coords: Vector2i) -> FlowField:
	flow_field_user_list.get_or_add(target_coords, 0)
	flow_field_user_list[target_coords] += 1
	
	if flow_field_list.has(target_coords):
		return flow_field_list[target_coords]
	
	var flow_field := FlowField.new()
	add_child(flow_field, true)
	
	flow_field.name = "FlowField" + str(target_coords)
	flow_field.cell_size = cell_size
	flow_field.cells = cells.duplicate()
	flow_field.solid_cells = solid_cells
	flow_field.set_target_coords(target_coords)
	flow_field_list[target_coords] = flow_field
	
	return flow_field


func remove_user_from_flow_field(target_coords: Vector2i) -> void:
	flow_field_user_list[target_coords] -= 1
	if flow_field_user_list[target_coords] == 0:
		var flow_field := flow_field_list[target_coords]
		flow_field.queue_free() # Should they be removed or reused?
		remove_child(flow_field)
		flow_field_list.erase(target_coords)
		flow_field_user_list.erase(target_coords)


func point_to_coords(point: Vector2) -> Vector2i:
	return ((point  - position) / cell_size - Vector2(0.5, 0.5)).round()


func coords_to_point(coords: Vector2i) -> Vector2i:
	return Vector2(coords * cell_size) + position + Vector2(0.5, 0.5) * cell_size


func add_solid(coords: Vector2i) -> void:
	solid_cells.get_or_add(coords, 0)
	solid_cells[coords] += 1
	#print(solid_cells[coords])


func remove_solid(coords: Vector2i, flood_cell: bool = false) -> void:
	solid_cells[coords] -= 1
	if solid_cells.get(coords) == 0:
		solid_cells.erase(coords)
	
	if flood_cell and not cells.has(coords):
		flood_cell(coords)
