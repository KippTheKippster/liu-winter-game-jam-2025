extends CharacterBody2D

@onready var target_detector: TargetDetector = $TargetDetector
@onready var eat_target_detector: TargetDetector = $EatTargetDetector
@onready var penguin_scared_audio: AudioStreamPlayer2D = $PenguinScaredAudio
@onready var inhale_area: Area2D = $InhaleArea
@onready var flip_group: FlipGroup = %FlipGroup
@onready var state_chart: StateChart = $StateChart

@export var inhale_force: float = 8.0

var penguin: Penguin

func apply_force() -> void:
	for body in inhale_area.get_overlapping_bodies():
		if body is Penguin:
			var dif := body.global_position - global_position
			body.external_velocity -= dif.normalized() * inhale_force


func _on_idle_state_physics_processing(delta: float) -> void:
	var next_target := target_detector.get_next_target()
	if next_target:
		inhale_area.look_at(next_target.global_position)
	
	flip_group.flip_towards(Vector2.from_angle(inhale_area.rotation))


func _on_inhale_state_physics_processing(delta: float) -> void:
	apply_force()
	
	var eat_target := eat_target_detector.get_next_target()
	if penguin == null and is_instance_valid(eat_target) and eat_target.holder is Penguin and inhale_area.overlaps_body(eat_target.holder):
		penguin = eat_target.holder
		state_chart.send_event("request_chew")


func _on_chew_state_entered() -> void:
	penguin.get_parent().remove_child(penguin)
	penguin_scared_audio.play()


func _on_chew_state_exited() -> void:
	penguin.queue_free()
	penguin = null


func _on_health_instance_died() -> void:
	queue_free()
	if penguin:
		add_sibling(penguin)
		penguin.vertical_group.jump()
