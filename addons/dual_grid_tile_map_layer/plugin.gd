@tool
extends EditorPlugin

var current_layer: DualGridTileMapLayer
var is_current_layer_selected: bool


func _enter_tree() -> void:
	EditorInterface.get_inspector().edited_object_changed.connect(_on_edited_object_changed)


func _exit_tree() -> void:
	EditorInterface.get_inspector().edited_object_changed.disconnect(_on_edited_object_changed)


func _on_edited_object_changed() -> void:
	var object := EditorInterface.get_inspector().get_edited_object()
	is_current_layer_selected = object is DualGridTileMapLayer
	if is_current_layer_selected:
		if is_instance_valid(current_layer) and current_layer != object:
			current_layer.update_display_layers()
		
		current_layer = object
	else:
		if is_instance_valid(current_layer):
			current_layer.update_display_layers()
	
	update_visibility()


func update_visibility() -> void:
	if not current_layer:
		return
	
	current_layer.enabled = is_current_layer_selected
	for layer in current_layer.get_valid_layers():
		if is_instance_valid(layer):
			layer.visible = !is_current_layer_selected
