extends Node2D

@export var break_scene: PackedScene
@export var break_audio: AudioStream

var occupant: Node2D
var prev_process_mode: ProcessMode

func _ready() -> void:
	for child in get_children():
		if not child.is_in_group("internal"):
			if child is Node2D:
				occupant = child
				prev_process_mode = occupant.process_mode
				occupant.process_mode = Node.PROCESS_MODE_DISABLED
				break


func _on_health_instance_died() -> void:
	Utils.play_audio_2d(break_audio, global_position, get_parent())
	queue_free()
	if occupant is Carriable:
		remove_child(occupant)
		occupant.place(global_position, 1.0, Vector2.ZERO, get_parent())		
	else:
		occupant.reparent(get_parent())
	
	if occupant is Penguin:
		occupant.vertical_group.jump()
	
	occupant.process_mode = prev_process_mode
	var instance := break_scene.instantiate() as Node2D
	instance.position = position
	add_sibling(instance)
