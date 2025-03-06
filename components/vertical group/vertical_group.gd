extends Node2D
class_name VerticalGroup

signal jumped

@export var gravity: float = 500.0
@export var jump_speed: float = 120.0
var velocity: float = 0.0
var height: float = 0.0:
	get:
		return -position.y
	set(value):
		position.y = -value

@export var shadow_texture: Texture2D = preload("uid://b66xiyyeuy5u8")
var shadow_sprite: Sprite2D

func _ready() -> void:
	shadow_sprite = Sprite2D.new()
	shadow_sprite.texture = shadow_texture
	shadow_sprite.top_level = true
	shadow_sprite.show_behind_parent = true
	shadow_sprite.z_index = -1
	shadow_sprite.name = "ShadowSprite"
	add_child(shadow_sprite)


func _process(delta: float) -> void:
	velocity -= gravity * delta
	height += velocity * delta
	if height < 0.0:
		height = 0.0
		velocity = 0.0
	
	shadow_sprite.visible = not is_on_floor()
	shadow_sprite.global_position = global_position + height * Vector2.DOWN


func is_on_floor() -> bool:
	return height == 0.0


func jump(speed_override: float = 0.0) -> void:
	if speed_override:
		velocity = speed_override
	else:
		velocity = jump_speed
	
	jumped.emit()
