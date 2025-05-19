@tool
extends TileMapLayer
class_name DualGridTileMapLayer

"""
@export var update_display_layers_button: bool:
	get:
		return false
	set(value):
		if value:
			update_display_layers()
"""

@export var create_collision: bool

var display_layers: Array[TileMapLayer] = []

var _is_updating: bool:
	get: 
		return _is_updating
	set(value):
		_is_updating = value
		var tree := get_tree()
		if is_instance_valid(tree) and _is_updating:
			await tree.process_frame
			_is_updating = false


const CORNER_OFFSET_COORDS: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(1, 1)
	]


const CORNER_ATLAS_COORDS: Dictionary = {
	[1, 1, 1, 1]: Vector2i(2, 1),
	[0, 0, 0, 1]: Vector2i(1, 3),
	[0, 0, 1, 0]: Vector2i(0, 0),
	[0, 1, 0, 0]: Vector2i(0, 2),
	[1, 0, 0, 0]: Vector2i(3, 3),
	[0, 1, 0, 1]: Vector2i(1, 0),
	[1, 0, 1, 0]: Vector2i(3, 2),
	[0, 0, 1, 1]: Vector2i(3, 0),
	[1, 1, 0, 0]: Vector2i(1, 2),
	[0, 1, 1, 1]: Vector2i(1, 1),
	[1, 0, 1, 1]: Vector2i(2, 0),
	[1, 1, 0, 1]: Vector2i(2, 2),
	[1, 1, 1, 0]: Vector2i(3, 1),
	[0, 1, 1, 0]: Vector2i(2, 3),
	[1, 0, 0, 1]: Vector2i(0, 1),
	[0, 0, 0, 0]: Vector2i(0, 3)
}


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			if Engine.is_editor_hint():
				update_display_layers_array()
				
				if not tile_set:
					tile_set = TileSet.new()
					if display_layers.size() > 0:
						var layer := display_layers[0]
						if layer.tile_set:
							tile_set.tile_size = layer.tile_set.tile_size
				
				changed.connect(_on_changed)
				changed.emit()
			else:
				enabled = true
				for layer in get_valid_layers():
					layer.visible = true
			
		NOTIFICATION_CHILD_ORDER_CHANGED:
			changed.emit()


func _on_changed() -> void:
	if _is_updating: # Prevents recursion
		return
	
	_is_updating = true
	
	#update_display_layers_array()
	update_atlas_source() 
	update_display_layers()
	update_display_layers_positions()
	update_configuration_warnings()


func _on_display_layer_changed() -> void:
	if _is_updating:
		return
	
	_is_updating = true
	
	update_atlas_source() 
	update_display_layers()
	update_display_layers_positions()
	update_configuration_warnings()


func update_display_layers_positions() -> void:
	if not tile_set:
		return
	
	for layer in display_layers:
		if layer:
			layer.position = -Vector2(tile_set.tile_size) / 2


func update_display_layers_array() -> void:
	if not Engine.is_editor_hint(): # HACK
		return
	
	var old := display_layers.duplicate()
	for layer in display_layers:
		layer.changed.disconnect(_on_display_layer_changed)
	
	display_layers.clear()
	for child in get_children():
		if child is TileMapLayer:
			child.changed.connect(_on_display_layer_changed)
			display_layers.append(child)
	
	for i in display_layers.size():
		var layer := display_layers[i]
		var old_index := old.find(layer)
		if old_index > -1 and old[old_index] != null and i != old_index:
			swap_cells_atlas_coords(Vector2i(i, 0), Vector2i(old_index, 0))
			old[i] = null
			old[old_index] = null


func swap_cells_atlas_coords(a_coords: Vector2i, b_coords: Vector2i) -> void:
	var from_cells := get_used_cells_by_id(0, a_coords)
	var to_cells := get_used_cells_by_id(0, b_coords)
	for cell in from_cells:
		set_cell(cell, 0, b_coords)
	
	for cell in to_cells:
		set_cell(cell, 0, a_coords)


func get_valid_layers() -> Array[TileMapLayer]:
	var layers:  Array[TileMapLayer] = []
	if not tile_set:
		return layers
	
	for layer in display_layers:
		if not layer:
			continue
		
		if not layer.tile_set:
			continue
		
		if layer.tile_set.tile_size != tile_set.tile_size:
			continue
		
		layers.append(layer)
	
	return layers


func get_temp_tile_atlas_coords() -> Vector2i:
	return Vector2i(display_layers.size(), 0)


func update_atlas_source() -> void:
	if not tile_set:
		return
	
	var images: Array[Image]
	var valid_layers := get_valid_layers()
	for i in valid_layers.size():
		var layer := valid_layers[i]
		
		var layer_source := layer.tile_set.get_source(0)
		if layer_source is TileSetAtlasSource:
			images.append(layer_source.texture.get_image())
	
	#if images.size() == 0:
	#	return
	
	var tile_count := images.size() + 1

	var sewed_image := Image.create_empty((tile_count) * tile_set.tile_size.x, tile_set.tile_size.y, false, Image.FORMAT_RGBA8)
	sewed_image.fill(Color.DEEP_PINK)
	var square_rect := Rect2i(
		Vector2i((tile_count - 1) * tile_set.tile_size.x, 0),
		tile_set.tile_size / 2
	)
	
	sewed_image.fill_rect(square_rect, Color.BLACK)
	square_rect.position += tile_set.tile_size / 2
	sewed_image.fill_rect(square_rect, Color.BLACK)
	
	for i in images.size():
		var image := images[i]
		sewed_image.blit_rect(
			image,
			Rect2i(
				Vector2i(2, 1) * tile_set.tile_size.x, 
				Vector2i(1, 1) * tile_set.tile_size.x
			), 
			Vector2i(i * tile_set.tile_size.x, 0)
		)
	
	#var tmp_image := Image.create_empty(tile_set.tile_size.x, tile_set.tile_size.y, false,  Image.FORMAT_RGBA8)
	##tmp_image.fill(Color.DEEP_PINK)
	#sewed_image.blit_rect()
	
	if not tile_set.has_source(0):
		var atlas_source := TileSetAtlasSource.new()
		#atlas_source.name
		atlas_source.texture_region_size = tile_set.tile_size
		atlas_source.resource_name = "Dual Grid System"
		tile_set.add_source(atlas_source, 0)
		
	
	var source := tile_set.get_source(0)
	if source is TileSetAtlasSource:
		source.texture = ImageTexture.create_from_image(sewed_image)
		source.clear_tiles_outside_texture()
		for i in tile_count:
			var atlas_coords := Vector2i(i, 0)
			if not source.has_tile(atlas_coords):
				source.create_tile(Vector2i(i, 0))


func update_display_layers() -> void:
	for layer in get_valid_layers():
		layer.clear()
	
	for coords in get_used_cells():
		for offset in CORNER_OFFSET_COORDS:
			var index := get_cell_atlas_coords(coords).x
			if index < get_temp_tile_atlas_coords().x:
				update_display_cells(index, coords + offset)


func update_display_cells(layer_index: int, coords: Vector2i) -> void:
	var layer := display_layers[layer_index]
	var corners: Array = [0, 0, 0, 0]
	for i in CORNER_OFFSET_COORDS.size():
		var offset_coords := coords + CORNER_OFFSET_COORDS[i] - Vector2i.ONE
		var atlas_coords := get_cell_atlas_coords(offset_coords)
		if atlas_coords != -Vector2i.ONE and atlas_coords.x == layer_index:
			corners[i] = 1
	
	layer.set_cell(coords, 0, CORNER_ATLAS_COORDS[corners])


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	if not tile_set:
		warnings.append("A TileSet is required for the DualGridTileMapLayer node to work.")
		return warnings
	
	if display_layers.size() == 0:
		warnings.append("At least one TileMapLayer child node is requried for the DualGridTileMapLayer node to work.")
	
	for i in display_layers.size():
		var layer := display_layers[i]
		
		if not layer.tile_set:
			warnings.append("Display layer '" + layer.name + "' has an invalid TileSet.")
			continue
		
		if layer.tile_set.tile_size != tile_set.tile_size:
			warnings.append("Display layer '" + layer.name + "' has a tile size that does not match the tile size of the DualGridTileMapLayer node.")
			continue
	
	#if tile_set and display_tile_map_layer and display_tile_map_layer.tile_set:
	#	if tile_set.tile_size != display_tile_map_layer.tile_set.tile_size:
	#		warnings.append("Unequal tile size!")
	
	return warnings
