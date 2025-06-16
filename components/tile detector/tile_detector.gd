extends Node2D
class_name TileDetector

signal tile_detected(layer: TileMapLayer, coords: Vector2i)

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
	
	#for node in get_tree().get_nodes_in_group("interactable_tile_map"):
	#	if node is TileMapLayer:
	#		tile_map_list.append(node)


func _process(delta: float) -> void:
	detected_tile_map_layer()
	#for tile_map in tile_map_list:


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
