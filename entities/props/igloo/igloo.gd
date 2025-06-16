extends Node2D
class_name Igloo

const ARCH_JUMPER_SCENE = preload("res://entities/arch jumper/arch_jumper.tscn")
const ArchJumper = preload("res://entities/arch jumper/arch_jumper.gd")

@export var allow_eat: bool = true
@onready var creature: Creature = $Area2D/Creature
@onready var food_sprite: Sprite2D = %FoodSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var spawn_marker: Marker2D = $SpawnMarker
@onready var spawn_audio: AudioStreamPlayer2D = $SpawnAudio

const PENGUIN_SCENE: PackedScene = preload("res://entities/penguin/penguin.tscn")
const PENGUIN_EGG = preload("uid://chhebeeiphacl")
const CARRY_OBJECT_SCENE = preload("uid://dwxtrccdrpoyl")

func _process(delta: float) -> void:
	allow_eat = true
	if allow_eat:
		var food := creature.get_next_creature_target()
		if food and food.carriable and is_carry_object_type_valid(food.carriable.carry_object_type):
			food_sprite.texture = food.carriable.carry_object_type.texture
			food_sprite.offset = food.carriable.carry_object_type.offset
			#allow_eat = false
			#animation_player.play("eat")
			food.owner.queue_free()
			var arch_jumper := ARCH_JUMPER_SCENE.instantiate() as ArchJumper
			arch_jumper.global_position = food.global_position
			add_sibling(arch_jumper)
			arch_jumper.copy_carry_object_sprite(food.carriable.carry_object_type)
			arch_jumper.jump_to_point(global_position)
			arch_jumper.landed.connect(func() -> void:
				spawn_penguin()
				#allow_eat = true
				arch_jumper.queue_free()
				, ConnectFlags.CONNECT_ONE_SHOT)


func is_carry_object_type_valid(type: CarryObjectType) -> bool:
	return type.is_food()


func spawn_penguin() -> void:
	var penguin := PENGUIN_SCENE.instantiate() as Penguin
	add_sibling(penguin)
	penguin.global_position = spawn_marker.global_position
	penguin.vertical_group.jump()
	spawn_audio.play()
	#var carry_object := CARRY_OBJECT_SCENE.instantiate() as Carriable
	#add_sibling(carry_object)
	#carry_object.global_position = spawn_marker.global_position
	#add_sibling(carry_object)
	#carry_object.pickup()
	#carry_object.place(spawn_marker.global_position, 1.0, Vector2.ZERO, get_parent())
	#carry_object.carry_object_type = PENGUIN_EGG


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "eat":
		allow_eat = true
