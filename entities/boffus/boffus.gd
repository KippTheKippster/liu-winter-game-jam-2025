extends StaticBody2D
class_name Boffus

@onready var creature: Creature = $Area2D/Creature
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var food_sprite: Sprite2D = %FoodSprite
@onready var time_label: Label = $TimeLabel
@onready var camera_2d: Camera2D = $Camera2D

@export var allow_eat: bool = true

var time_left: float = 120.0

func _process(delta: float) -> void:
	time_left -= delta
	if allow_eat:
		var food := creature.get_next_creature_target()
		if food and food.carriable:
			food_sprite.texture = food.carriable.carry_item_texture
			food_sprite.offset = food.carriable.carry_item_offset
			allow_eat = false
			animation_player.play("eat")
			if food.owner.food_type == preload("res://entities/food/food types/food_meat_big.tres"):
				camera_2d.enabled = true
				camera_2d.make_current()
				time_label.visible = false
				Utils.call_delayed(self, 2.0, func():
					GlobalUi.transition_screen.change_scene_to_file("res://main scenes/victory screen/victory_screen.tscn", "circle")
				)
			
			food.owner.queue_free()
	
	time_label.text = str(roundi(time_left))
	if time_left < 0.0:
		time_left = 0.0
		camera_2d.enabled = true
		camera_2d.make_current()
		Utils.call_delayed(self, 1.0, func():
			GlobalUi.transition_screen.change_scene_to_file("res://main scenes/game over/game_over.tscn", "circle")
			)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "eat":
		animation_player.play("idle")
		time_left += 40.0
