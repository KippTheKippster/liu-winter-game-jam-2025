extends Node

@export var enabled: bool = true:
	set(value):
		enabled = value
		set_process(enabled)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reload_current_scene"):
		get_tree().reload_current_scene()
	
	if Input.is_action_just_pressed("fast_forward"):
		Engine.time_scale *= 2.0
	elif Input.is_action_just_released("fast_forward"):
		Engine.time_scale = 1.0
	
	if Input.is_action_just_pressed("speed_increase"):
		Engine.time_scale *= 2.0
	elif Input.is_action_just_pressed("speed_decrease"):
		Engine.time_scale /= 2.0
