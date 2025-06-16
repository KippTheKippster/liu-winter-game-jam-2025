extends Node
class_name FlowFieldTileMapLayerSolid

@export var active: bool = true

var layer: TileMapLayer

var flow_field_manager: FlowFieldManager

var solid_coords_list: Array[Vector2i]

func _enter_tree() -> void:
	flow_field_manager = get_tree().get_first_node_in_group("flow_field_manager")
	if not flow_field_manager:
		return
	
	if not active:
		return
	
	layer = get_parent()
	for layer_coords in layer.get_used_cells():
		var global_position = layer.to_global(layer.map_to_local(layer_coords))
		var solid_coords := flow_field_manager.point_to_coords(global_position)
		flow_field_manager.add_solid(solid_coords)
		solid_coords_list.append(solid_coords)


func _exit_tree() -> void:
	if not active:
		return
	
	#flow_field_manager.remove_solid(solid_coords, flood_cell_on_tree_exit)
	for solid_coords in solid_coords_list:
		flow_field_manager.remove_solid(solid_coords)
