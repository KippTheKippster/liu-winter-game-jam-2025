@tool
extends Sprite2D

@onready var canvas_group: CanvasGroup = $"../CanvasGroup"

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set("instance_shader_parameters/scale", get_viewport_transform().get_scale())
	else:
		set("instance_shader_parameters/scale", get_viewport().get_camera_2d().zoom)
	
	canvas_group.
