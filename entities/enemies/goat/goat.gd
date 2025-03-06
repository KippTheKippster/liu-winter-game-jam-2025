extends CharacterBody2D

@onready var creature: Creature = %Creature
@onready var flip_group: FlipGroup = %FlipGroup

@onready var state_chart: StateChart = $StateChart


func _physics_process(delta: float) -> void:
	move_and_slide()


func _on_idle_state_processing(delta: float) -> void:
	var next_target := creature.get_next_creature_target()
	if next_target:
		state_chart.send_event("charge_request")


func _on_charge_state_entered() -> void:
	var next_target := creature.get_next_creature_target()
	if not next_target:
		state_chart.send_event("charge_cancel")
		return
	
	velocity = creature.get_next_creature_target().global_position - global_position
	velocity = 40.0 * velocity.normalized()
	
	flip_group.flip_towards(velocity)


func _on_charge_state_exited() -> void:
	velocity = Vector2.ZERO
