extends CharacterBody2D

@onready var creature: Creature = $TreeArea/Creature
@onready var vertical: Vertical = $Vertical
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_chart: StateChart = $StateChart

@onready var tree_sprite: Sprite2D = %TreeSprite

var time_elapsed: float = 0.0

func _ready() -> void:
	state_chart.send_event.call_deferred("unburrow_request")
	creature.get_next_creature_target()


func _process(delta: float) -> void:
	time_elapsed += delta
	state_chart.send_event.call_deferred("unburrow_request")
	state_chart.set_expression_property("on_floor", vertical.is_on_floor())
	state_chart.set_expression_property("vertical_velocity", vertical.velocity)


func _on_hide_state_exited() -> void:
	animation_player.play("idle")
	tree_sprite.offset.x = 0


func _on_jump_state_entered() -> void:
	vertical.jump()


func _on_unburrow_state_processing(delta: float) -> void:
	tree_sprite.offset.x = sin(time_elapsed * 48.0)
