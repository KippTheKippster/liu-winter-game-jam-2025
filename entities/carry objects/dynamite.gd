extends Carriable

const EXPLOSION_SCENE = preload("uid://d2fg37q8vew2b")

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var target: Target = $Area2D/Target
@onready var danger_target: Target = $Area2D/DangerTarget
@onready var timer: Timer = $Timer
@onready var vertical_group: VerticalGroup = $VerticalGroup
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _physics_process(delta: float) -> void:
	enabled = vertical_group.is_on_floor()
	if not vertical_group.is_on_floor():
		move_and_slide()


func ignite() -> void:
	target.active = false
	danger_target.active = true
	sprite_2d.frame = 1
	animation_player.play("burn")
	timer.start()


func _on_timer_timeout() -> void:
	var explosion := EXPLOSION_SCENE.instantiate() as Node2D
	explosion.position = position
	add_sibling(explosion)
	
	queue_free()


func _on_placed(height: float, new_velocity: Vector2) -> void:
	#velocity = new_velocity
	vertical_group.height = height
	vertical_group.jump()
	velocity = new_velocity
