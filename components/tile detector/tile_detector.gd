extends Node2D
class_name TileDetector

signal cell_changed(layer: TileMapLayer, current_coords: Vector2i, old_coords: Vector2i)

#var tile_map_list: Array[TileMapLayer]
var tile_map: TileMapLayer
var current_coords: Vector2i:
	set(value):
		var old_coords := current_coords
		current_coords = value
		if current_coords != old_coords:
			cell_changed.emit(tile_map, current_coords, old_coords)

func _ready() -> void:
	tile_map = get_tree().get_first_node_in_group("interactable_tile_map")
	#for node in get_tree().get_nodes_in_group("interactable_tile_map"):
	#	if node is TileMapLayer:
	#		tile_map_list.append(node)


func _process(delta: float) -> void:
	if tile_map:
		current_coords = tile_map.local_to_map(tile_map.to_local(global_position))
	#for tile_map in tile_map_list:
		
