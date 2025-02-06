extends Node2D
class_name FlowField

@export var label_settings: LabelSettings

var labels: Array[Label]

var cell_size: int = 12

enum Direction { LEFT, RIGHT, UP, DOWN, NIL }
const NeighborVectors: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var cells: Dictionary[Vector2i, int]

func _ready() -> void:
	for i in 16:
		for j in 16:
			cells[Vector2i(i, j)] = -1
			labels.append(Label.new())
	
	#set_target_coordsl(Vector2i(11, 1))


#func _process(delta: float) -> void:
#	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
#		set_target_coords(get_global_mouse_position() / cell_size) 


func get_cell_value(cell: Vector2i) -> int:
	return cells.get(cell, -1)


func get_cell_direction(cell: Vector2i) -> Vector2i:
	var min_cell := cell
	for vector in NeighborVectors:
		var neighbor_cell := cell + vector
		var min_cell_value = get_cell_value(min_cell)
		var neigbor_cell_value = get_cell_value(neighbor_cell)
		if  min_cell_value == -1 or (min_cell_value > neigbor_cell_value and neigbor_cell_value != -1):
			min_cell = neighbor_cell
	
	return min_cell - cell


func set_target_coords(target_coords: Vector2i) -> void:
	for label in labels:
		label.queue_free()
	
	labels.clear()
	
	for coords in cells.keys():
		cells[coords] = -1
	
	cells[target_coords] = 0
	propogate_cells(PackedVector2Array([target_coords]))


func propogate_cells(propogating_cells: Array[Vector2i]) -> void:
	var valid_neighbors: Array[Vector2i]
	for cell in propogating_cells:
		var label := Label.new()
		add_child(label)
		
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text = str(cells.get(cell, NAN))
		label.position = cell * cell_size
		label.label_settings = label_settings
		label.set_deferred("size", Vector2.ONE * cell_size)
		labels.append(label)
	
		for vector in NeighborVectors:
			var neighbor_cell = cell + vector
			if cells.has(neighbor_cell) and cells[neighbor_cell] == -1 and is_cell_valid(neighbor_cell):
				cells[neighbor_cell] = cells[cell] + 1
				valid_neighbors.append(neighbor_cell)
	
	if valid_neighbors.size() > 0:
		propogate_cells(valid_neighbors)


func has_cell_invalid_neigbors(cell: Vector2i, include_sub_neigbors: bool = false) -> bool:
	for vector in NeighborVectors:
		if not is_cell_valid(cell + vector):
			return true
	
	if include_sub_neigbors:
		for i in NeighborVectors.size():
			if not is_cell_valid(cell + NeighborVectors[i] + NeighborVectors[(i + 1) % NeighborVectors.size()]):
				return true
	
	return false


func point_to_coords(point: Vector2) -> Vector2i:
	return Vector2i(point / cell_size)


func is_cell_valid(cell: Vector2i) -> bool:
	var invalid_cells = [
		Vector2i(3,3),
		Vector2i(4,3),
		Vector2i(3,4),
		Vector2i(4,4),
		Vector2i(4,5),
		
		Vector2i(5,3),
		Vector2i(5,4),
		Vector2i(5,5),
		Vector2i(6,3),
		Vector2i(6,4),
		Vector2i(6,5),
		Vector2i(7,3),
		Vector2i(7,4),
		Vector2i(7,5),
		Vector2i(8,3),
		Vector2i(8,4),
		Vector2i(8,5),
		
		Vector2i(6,7),
		Vector2i(6,8),
		Vector2i(6,9),
	]
	return true
	
	
	return not invalid_cells.has(cell)
