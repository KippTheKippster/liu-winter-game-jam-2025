extends TileMapLayer

@export var overlapping_tile_map_layers: Array[TileMapLayer] = []

func _ready() -> void:
	if overlapping_tile_map_layers.size() == 0:
		printerr("TileMapLayerDifference is Missing OverlappingTileMapLayers")
		return
	
	for layer in overlapping_tile_map_layers:
		for cell in layer.get_used_cells():
			var coords := local_to_map(layer.to_global(layer.map_to_local(cell)))
			var tile_data := get_cell_tile_data(coords)
			if tile_data != null:
				set_cell(coords)
