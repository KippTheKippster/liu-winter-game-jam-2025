extends Node2D
class_name Igloo

var allow_eat: bool = true
@onready var creature: Creature = $Area2D/Creature
@onready var food_sprite: Sprite2D = %FoodSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var spawn_marker: Marker2D = $SpawnMarker

const PENGUIN_SCENE: PackedScene = preload("res://entities/penguin/penguin.tscn")
const PENGUIN_EGG = preload("uid://chhebeeiphacl")
const CARRY_OBJECT_SCENE = preload("uid://dwxtrccdrpoyl")

func _process(delta: float) -> void:
	if allow_eat:
		var food := creature.get_next_creature_target()
		if food and food.carriable:
			food_sprite.texture = food.carriable.carry_object_type.texture
			food_sprite.offset = food.carriable.carry_object_type.offset
			allow_eat = false
			animation_player.play("eat")
			food.owner.queue_free()


func spawn_penguin() -> void:
	#var penguin := PENGUIN_SCENE.instantiate() as Penguin
	#add_sibling(penguin)
	#penguin.global_position = spawn_marker.global_position
	#penguin.vertical_group.jump()
	var carry_object := CARRY_OBJECT_SCENE.instantiate() as Carriable
	#add_sibling(carry_object)
	#carry_object.global_position = spawn_marker.global_position
	#add_sibling(carry_object)
	#carry_object.pickup()
	carry_object.place(spawn_marker.global_position, 1.0, self)
	carry_object.carry_object_type = PENGUIN_EGG


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "eat":
		allow_eat = true
