extends Control

signal transition_started
signal screen_covered
signal transition_finished

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func start(type: String = "fade", pause: bool = true) -> void:
	transition_started.emit()
	animation_player.play(type)
	if pause:
		get_tree().paused = true


func change_scene_to_file(path: String, type: String = "fade", pause: bool = true) -> void:
	start(type, pause)
	await screen_covered
	get_tree().change_scene_to_file(path)


func change_scene_to_packed(scene: PackedScene, type: String = "fade", pause: bool = true) -> void:
	start(type, pause)
	await screen_covered
	get_tree().change_scene_to_packed(scene)


func _on_screen_covered() -> void:
	pass


func _on_transition_finished() -> void:
	get_tree().paused = false


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	transition_finished.emit()
	if anim_name != "RESET":
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_animation_player_animation_started(anim_name: StringName) -> void:
	if anim_name != "RESET":
		mouse_filter = Control.MOUSE_FILTER_STOP
