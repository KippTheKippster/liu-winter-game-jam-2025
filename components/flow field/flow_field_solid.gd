extends Node2D
class_name FlowFieldSolid

var flow_field_manager: FlowFieldManager
var solid_coords: Vector2i

func _enter_tree() -> void:
	flow_field_manager = get_tree().get_first_node_in_group("flow_field_manager")
	if not flow_field_manager:
		return
	
	solid_coords = flow_field_manager.point_to_coords(global_position)
	flow_field_manager.add_solid(solid_coords)


func _exit_tree() -> void:
	flow_field_manager.remove_solid(solid_coords)
