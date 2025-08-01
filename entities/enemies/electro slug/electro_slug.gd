extends CharacterBody2D

const ELECTRIC_TILE_SCENE = preload("uid://qhe1y6we7y2n")

const NEIGHBORS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
]

@onready var danger_target_detector: TargetDetector = $DangerTargetDetector
@onready var tile_detector: TileDetector = $TileDetector
@onready var state_chart: StateChart = $StateChart
@onready var flow_field_walker: FlowFieldWalker = $FlowFieldWalker

@export var electricity_range: int = 25
@export var max_speed: float = 12.0
@export var water_markers: Array[Marker2D] = []
var water_marker: Marker2D
var start_point: Vector2

var queue: Array[Vector2i] = []
var cells: Dictionary[Vector2i, bool] = {}
var electric_tiles: Array[Node2D] = []

var in_water: bool

func _ready() -> void:
	start_point = global_position


func global_to_coords(point: Vector2) -> Vector2i:
	var local_point := tile_detector.current_layer.to_local(point)
	var tile_coords := tile_detector.current_layer.local_to_map(local_point)
	return tile_coords


func spawn_electricity_tile(coords: Vector2i) -> Node2D:
	var tile := ELECTRIC_TILE_SCENE.instantiate() as Node2D
	add_sibling(tile)
	var local_tile_position := tile_detector.current_layer.map_to_local(coords)
	var global_tile_position = tile_detector.current_layer.to_global(local_tile_position)
	tile.global_position = global_tile_position
	return tile


func propogate(coords: Vector2i) -> void:
	#spawn_electricity_tile(coords)
	cells[coords] = true
	for neighbor in NEIGHBORS:
		var neighbor_cell := coords + neighbor
		if not cells.has(neighbor_cell) and tile_detector.get_tile_custom_data(tile_detector.current_layer, neighbor_cell, "water") == true:
			cells[neighbor_cell] = true
			queue.push_back(neighbor_cell)


func create_electricity_field() -> void:
	var n := electricity_range
	queue.resize(1)
	queue[0] = global_to_coords(global_position)
	while queue.size() > 0 and n > 0:
		var coords := queue.pop_front() as Vector2i
		propogate(coords)
		var tile := spawn_electricity_tile(coords)
		electric_tiles.push_back(tile)
		n = n - 1


func clear_electricity_field() -> void:
	for tile in electric_tiles:
		tile.queue_free()
	
	cells.clear()
	queue.clear()
	electric_tiles.clear()


func _on_tile_detector_tile_detected(layer: TileMapLayer, coords: Vector2i) -> void:
	var data = tile_detector.get_current_tile_custom_data("water")
	in_water = data == true


func navigate() -> bool:
	velocity = flow_field_walker.get_direction() * max_speed
	move_and_slide()
	return global_position.distance_squared_to(flow_field_walker.target_point) < 4.0

# States
# SearchDanger
func _on_search_danger_state_physics_processing(delta: float) -> void:
	var danger_target := danger_target_detector.get_next_target()
	if is_instance_valid(danger_target):
		state_chart.send_event("request_find_water")

# Idle
func _on_idle_state_physics_processing(delta: float) -> void:
	pass


# Find Water
func _on_find_water_state_entered() -> void:
	var closest_marker: Marker2D = null
	for marker in water_markers:
		if closest_marker == null or (
			marker.global_position.distance_squared_to(global_position) < 
			closest_marker.global_position.distance_squared_to(global_position)):
			closest_marker = marker
	
	water_marker = closest_marker
	if water_marker:
		flow_field_walker.target_point = water_marker.global_position


func _on_find_water_state_physics_processing(delta: float) -> void:
	if navigate():
		state_chart.send_event("request_shock")

# Return
func _on_return_state_physics_processing(delta: float) -> void:
	if navigate():
		state_chart.send_event("request_idle")


# Shock
func _on_shock_state_entered() -> void:
	clear_electricity_field()
	if in_water:
		create_electricity_field()

# Recharge
func _on_recharge_state_entered() -> void:
	clear_electricity_field()
	await get_tree().create_timer(2.0).timeout
	var detection_range := danger_target_detector.detection_range
	danger_target_detector.detection_range = 48.0
	var danger_target := danger_target_detector.get_next_target()
	if danger_target == null:
		flow_field_walker.target_point = start_point
		state_chart.send_event("request_return")
	else:
		state_chart.send_event("request_shock")
