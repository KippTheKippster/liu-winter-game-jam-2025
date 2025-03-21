extends CharacterBody2D
class_name Boffus

const FOOD_PENGUIN = preload("uid://cvel35rx5kt4s")

@onready var flow_field_walker: FlowFieldWalker = $FlowFieldWalker
@onready var food_creature: Creature = %FoodCreature
@onready var food_target_detector: TargetDetector = %FoodTargetDetector
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var flip_group: FlipGroup = $FlipGroup
@onready var food_sprite: Sprite2D = %FoodSprite
@onready var time_label: Label = $TimeLabel
@onready var camera_2d: Camera2D = $Camera2D
@onready var state_chart: StateChart = $StateChart
@onready var boffus_creature: Creature = %BoffusCreature
@onready var penguin_creature: Creature = %PenguinCreature
@onready var penguin_target_detector: TargetDetector = $PenguinTargetDetector
@onready var hunt_target_detector: TargetDetector = %HuntTargetDetector
@onready var danger_target: Target = %DangerTarget

var allow_eat: bool = false

@export var time_left: float = 17.0

func _ready() -> void:
	allow_eat = false
	boffus_creature.active = false


func _process(delta: float) -> void:
	#print(allow_eat)
	pass
	"""
	if allow_eat:
		var food := creature.get_next_creature_target()
		if food and food.carriable:
			food_sprite.texture = food.carriable.carry_item_texture
			food_sprite.offset = food.carriable.carry_item_offset
			allow_eat = false
			animation_player.play("eat")
			if food.owner.carry_object_type == preload("res://entities/food/food types/food_meat_big.tres"):
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
	"""

func search_for_food(target_detector: TargetDetector) -> void:
	var target := target_detector.get_next_target()
	
	if target and target.holder is Carriable:
		food_sprite.texture = target.holder.carry_object_type.texture
		food_sprite.offset = target.holder.carry_object_type.offset
		state_chart.send_event.call_deferred("eat_request")
		if target.holder.carry_object_type == preload("uid://csgrgd3ywh8js"):
			camera_2d.enabled = true
			camera_2d.make_current()
			time_label.visible = false
			Utils.call_delayed(self, 2.0, func():
				GlobalUi.transition_screen.change_scene_to_file("res://main scenes/victory screen/victory_screen.tscn", "circle")
			)
		
		target.owner.queue_free() 
	
	if target and target.owner is Penguin2:
		var penguin := target.owner as Penguin2
		penguin.global_position = food_sprite.global_position
		#penguin.state_chart.send_event("extra_state_none_request")
		flip_group.flip_towards_node(penguin)
		penguin.throw_items()
		penguin.kill()
		food_sprite.texture = FOOD_PENGUIN.texture
		food_sprite.offset = FOOD_PENGUIN.offset
		state_chart.send_event.call_deferred("eat_request")
		


func _on_eat_state_exited() -> void:
	time_left += 40.0


func _on_sleep_state_processing(delta: float) -> void:
	time_label.text = str(roundi(time_left))
	time_left -= delta
	if time_left <= 0:
		time_left = 0.0
		state_chart.send_event("waking_request")


func _on_chase_state_entered() -> void:
	boffus_creature.active = true
	danger_target.active = true



func _on_chase_state_exited() -> void:
	boffus_creature.active = false
	danger_target.active = false


func _on_waking_state_processing(delta: float) -> void:
	search_for_food(food_target_detector)


func _on_waking_state_entered() -> void:
	allow_eat = true


func _on_waking_state_exited() -> void:
	allow_eat = false


func _on_chase_state_physics_processing(delta: float) -> void:
	move_and_slide()


func _on_shoot_state_entered() -> void:
	var target := hunt_target_detector.get_next_target()
	allow_eat = true
	if target:
		var dif := (target.global_position - global_position)
		var speed := clampf(2.0 * dif.length(), 30.0, 60.0)
		flow_field_walker.target_point = target.global_position
		velocity = speed * flow_field_walker.get_direction()
		#velocity = speed * dif.normalized() 
		
		if not velocity.is_zero_approx():
			flip_group.flip_towards(velocity)


func _on_charge_state_entered() -> void:
	#allow_eat = true
	velocity = Vector2.ZERO
	search_for_food(penguin_target_detector)


func _on_shoot_state_physics_processing(delta: float) -> void:
	velocity = velocity.normalized() * (velocity.length() - 60.0 * delta)


func _on_charge_state_exited() -> void:
	pass
	#allow_eat = false


func _on_shoot_state_exited() -> void:
	allow_eat = false
