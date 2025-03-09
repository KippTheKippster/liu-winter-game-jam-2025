extends CharacterBody2D

const SNOW_EXPLOSION_SCENE = preload("res://entities/effects/snow explosion/snow_explosion.tscn")
const SnowExplosion = preload("res://entities/effects/snow explosion/snow_explosion.gd")

@onready var creature: Creature = $TreeArea/Creature
@onready var vertical_group: VerticalGroup = $VerticalGroup
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_chart: StateChart = $StateChart

@onready var tree_sprite: Sprite2D = %TreeSprite

var time_elapsed: float = 0.0

func _ready() -> void:
	creature.active = false
	#state_chart.send_event.call_deferred("unburrow_request")
	#creature.get_next_creature_target()


func _physics_process(delta: float) -> void:
	move_and_slide()


func _process(delta: float) -> void:
	time_elapsed += delta
	state_chart.set_expression_property("on_floor", vertical_group.is_on_floor())
	state_chart.set_expression_property("vertical_velocity", vertical_group.velocity)


func _on_hide_state_exited() -> void:
	animation_player.play("idle")
	creature.active = true
	creature.detection_range_squared = 96.0 * 96.0
	tree_sprite.offset.x = 0
	
	var snow_explosion := SNOW_EXPLOSION_SCENE.instantiate() as SnowExplosion
	snow_explosion.position = position
	add_sibling(snow_explosion)


func _on_jump_state_entered() -> void:
	vertical_group.jump()


func _on_jump_state_exited() -> void:
	velocity = Vector2.ZERO


func _on_unburrow_state_processing(delta: float) -> void:
	tree_sprite.offset.x = sin(time_elapsed * 48.0)


func _on_burrow_state_processing(delta: float) -> void:
	var target := creature.get_next_creature_target()
	if target:
		state_chart.send_event("unburrow_request")


func _on_crouch_state_exited() -> void:
	var target := creature.get_next_creature_target()
	if creature.get_next_creature_target():
		velocity = (target.global_position - global_position).normalized() * 20.0
