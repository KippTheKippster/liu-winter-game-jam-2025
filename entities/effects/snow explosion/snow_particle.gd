extends Node2D

enum Size {
	SMALL,
	MEDIUM,
	LARGE
}

const SnowExplosion = preload("res://entities/effects/snow explosion/snow_explosion.gd")
const SNOW_EXPLOSION_SCENE = preload("res://entities/effects/snow explosion/snow_explosion.tscn")

@onready var vertical_group: VerticalGroup = %VerticalGroup
@onready var flip_group: FlipGroup = %FlipGroup
@onready var sprite_2d: Sprite2D = %Sprite2D

@export var size: Size
@export var speed: float = 20.0
@export var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	match size:
		Size.SMALL:
			speed = 15
			vertical_group.jump_speed = 40
		Size.MEDIUM:
			speed = 25
			vertical_group.jump_speed = 80
	
	flip_group.flip_towards(Vector2.from_angle(randf() * 2.0 * PI))
	vertical_group.height = 1.0
	vertical_group.jump()
	direction = direction.normalized()
	sprite_2d.frame_coords.x = size



func _process(delta: float) -> void:
	position += direction * speed * delta
	if vertical_group.is_on_floor():
		if size > Size.SMALL:
			var snow_explosion = load("res://entities/effects/snow explosion/snow_explosion.tscn").instantiate() # UGLY
			snow_explosion.start_size = size - 1
			owner.add_sibling(snow_explosion)
			snow_explosion.global_position = global_position
		
		queue_free()
