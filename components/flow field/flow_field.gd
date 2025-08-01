extends Node2D
class_name FlowField

@export var label_settings: LabelSettings = LabelSettings.new()

var labels: Array[Label]
var color_rects: Array[ColorRect]
var solid_cells: Dictionary[Vector2i, int]

var cell_size: int = 12

#enum Direction { LEFT, RIGHT, UP, DOWN, NIL }
const NeighborVectors: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const NeighborVectorsIncludeSub: Array[Vector2i] = [
	Vector2i(1, 0), 
	Vector2i(1, 1), 
	Vector2i(0, 1), 
	Vector2i(-1, 1), 
	Vector2i(-1, 0), 
	Vector2i(-1, -1), 
	Vector2i(0, -1),
	Vector2i(1, -1)]


var cells: Dictionary[Vector2i, int]

func _ready() -> void:
	label_settings.font_size = 4

#func _ready() -> void:
#	for i in range(-24, 24):
#		for j in range(-24, 24):
#			cells[Vector2i(i, j)] = -1
#			color_rects.append(ColorRect.new())
			#labels.append(Label.new())
	
	#set_target_coordsl(Vector2i(11, 1))



#func _process(delta: float) -> void:
#	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
#		set_target_coords(get_global_mouse_position() / cell_size) 


func get_cell_value(cell: Vector2i) -> int:
	return cells.get(cell, -1)


func get_cell_direction(cell: Vector2i, include_sub_neigbors: bool = false) -> Vector2i:
	var min_cell := cell
	var vectors: Array[Vector2i] = NeighborVectors
	if include_sub_neigbors:
		vectors = NeighborVectorsIncludeSub
		#for i in NeighborVectors.size():
		#	vectors.append(NeighborVectors[i] + NeighborVectors[(i + 1) % NeighborVectors.size()])
	
	for vector in vectors:
		var neighbor_cell := cell + vector
		var min_cell_value = get_cell_value(min_cell)
		var neigbor_cell_value = get_cell_value(neighbor_cell)
		if  min_cell_value == -1 or (min_cell_value > neigbor_cell_value and neigbor_cell_value != -1 
			and is_cell_valid(cell + Vector2i.RIGHT * vector.x) and is_cell_valid(cell + Vector2i.DOWN * vector.y)):
			min_cell = neighbor_cell
	
	if get_cell_value(min_cell) == -1:
		return Vector2.ZERO
	
	return min_cell - cell


func set_target_coords(target_coords: Vector2i) -> void:
	for coords in cells.keys():
		cells[coords] = -1
	
	cells[target_coords] = 0
	
	var propogating_cells: PackedVector2Array = PackedVector2Array([target_coords])
	propogate_cells(propogating_cells)
	
	## Debug
	if get_tree().debug_navigation_hint:
		for label in labels:
			label.queue_free()
		
		for color_rect in color_rects:
			color_rect.queue_free()
		
		labels.clear()
		color_rects.clear()
	
		for cell in cells.keys():
			var color := Color.from_hsv((cells[cell] % 16) / 16.0, 1, 1, 1)
			
			
			"""
			var sprite := Sprite2D.new()
			sprite.texture = preload("res://components/flow field/assets/arrow.png")
			sprite.position = Vector2(cell * cell_size) + sprite.texture.get_size() / 2
			sprite.z_index = -1
			sprite.rotation = Vector2(get_cell_direction(cell, true)).angle()
			sprite.modulate = color
			sprite.modulate.a = 0.5
			if cells[cell] == 0:
				sprite.visible = false
			add_child(sprite)
			"""
			var label := Label.new()
			add_child(label)
			
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.text = str(cells.get(cell, NAN))
			label.position = cell * cell_size
			label.label_settings = label_settings
			label.set_deferred("size", Vector2.ONE * cell_size)
			label.modulate = color
			labels.append(label)


func propogate_cells(propogating_cells: Array[Vector2i]) -> void:
	var valid_neighbors: Array[Vector2i]
	for cell in propogating_cells:
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

func is_cell_valid(cell: Vector2i) -> bool:
	return solid_cells.get(cell, 0) == 0
