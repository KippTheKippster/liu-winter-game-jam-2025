extends Node2D
class_name TileDetector

signal tile_detected(layer: TileMapLayer, coords: Vector2i)

@export var auto_detect: bool = true

var tile_map_layer_list: Array[TileMapLayer]
#var tile_map: TileMapLayer
#var current_coords: Vector2i:
#	set(value):
#		var old_coords := current_coords
#		current_coords = value
#		if current_coords != old_coords:
#			cell_changed.emit(tile_map, current_coords, old_coords)

var current_layer: TileMapLayer
var current_coords: Vector2i

func _ready() -> void:
	for node in get_tree().get_nodes_in_group("interactable_tile_map"):
		if node is TileMapLayer:
			tile_map_layer_list.push_back(node)
	
	set_process(auto_detect)
	
	#for node in get_tree().get_nodes_in_group("interactable_tile_map"):
	#	if node is TileMapLayer:
	#		tile_map_list.append(node)


func _process(delta: float) -> void:
	detected_tile_map_layer()
	#for tile_map in tile_map_list:


func get_tile_custom_data(layer: TileMapLayer, coords: Vector2i, layer_name: StringName) -> Variant:
	var tile_data := layer.get_cell_tile_data(coords)
	if tile_data:
		if tile_data.has_custom_data(layer_name):
			return tile_data.get_custom_data(layer_name)
	
	return null


func has_tile_custom_data(layer: TileMapLayer, coords: Vector2i, layer_name: StringName) -> bool:
	return get_tile_custom_data(layer, coords, layer_name) != null


func get_current_tile_custom_data(layer_name: StringName) -> Variant:
	return get_tile_custom_data(current_layer, current_coords, layer_name)


func has_current_tile_custom_data(layer_name: StringName) -> bool:
	return has_tile_custom_data(current_layer, current_coords, layer_name)



func detected_tile_map_layer() -> void:
	var layer: TileMapLayer
	var coords: Vector2i
	for i in tile_map_layer_list.size():
		var index := tile_map_layer_list.size() - 1 - i
		layer = tile_map_layer_list[index]
		coords = layer.local_to_map(layer.to_local(global_position))
		var tile_data := layer.get_cell_tile_data(coords)
		if tile_data:
			break
	
	if layer != current_layer or coords != current_coords:
		current_layer = layer
		current_coords = coords
		tile_detected.emit(layer, coords)
