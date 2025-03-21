@tool
extends Node2D

@onready var reflection_sprite: Sprite2D = %ReflectionSprite
#@onready var shader_material: ShaderMaterial = reflection_sprite.material

var i = 1

func _process(delta: float) -> void:
	if reflection_sprite:
		if Engine.is_editor_hint():
			reflection_sprite.set("instance_shader_parameters/scale", get_viewport_transform().get_scale())
		else:
			reflection_sprite.set("instance_shader_parameters/scale", get_viewport().get_camera_2d().zoom)
			

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Penguin2:
		body.overlapping_water_count += 1


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Penguin2:
		body.overlapping_water_count -= 1
