extends CharacterBody2D
class_name Penguin

signal creature_target_changed

@export var attack_range: float = 12.0
@export var walk_speed: float = 20.0

@onready var damage_instance: DamageInstance = $Area2D/DamageInstance
@onready var flip_group: FlipGroup = %FlipGroup
@onready var vertical: Vertical = %Vertical
@onready var carry_item_sprite: Sprite2D = %CarryItemSprite
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_chart: StateChart = $StateChart

@export var creature_target: Creature:
	set(value):
		var old_creature := creature_target
		creature_target = value
		if creature_target != old_creature and is_node_ready():
			creature_target_changed.emit()

var walk_target: Vector2

@export var carriable: Carriable

var action_target: StringName:
	set(value):
		var old := action_target
		action_target = value
		if is_node_ready():
			if action_target != old:
				state_chart.set_expression_property("action_target", action_target)

func _ready() -> void:
	Game.penguins.append(self)
	
	creature_target_changed.emit.call_deferred()
	animation_tree.set("parameters/idle_blend_tree/time_scale/scale", randf_range(0.8, 1.2))
	animation_tree.set("parameters/walk_blend_tree/time_scale/scale", randf_range(0.8, 1.2))


func _physics_process(delta: float) -> void:
	move_and_slide()


func  get_vector_to_creature_target() -> Vector2:
	return (creature_target.global_position - global_position)


func is_creature_target_in_attack_range() -> bool:
	return get_vector_to_creature_target().length() < attack_range


#func _on_creature_target_changed() -> void:
#	state_chart.send_event("task_attack_request")


func _on_task_attack_state_entered() -> void:
	pass


func _on_task_attack_state_processing(delta: float) -> void:
	if not is_instance_valid(creature_target):
		state_chart.send_event("task_idle_request")
		return
	
	if is_creature_target_in_attack_range():
		#state_chart.send_event("action_attack_request")
		action_target = "attack"
	else:
		walk_target = creature_target.global_position
		action_target = "walk"
		#state_chart.send_event("action_walk_request")


func _on_action_walk_state_physics_processing(delta: float) -> void:
	velocity = walk_speed * (walk_target - global_position).normalized()
	flip_group.flip_towards(velocity)
	if (walk_target - global_position).length() < 1.0:
		#state_chart.send_event("action_idle_request")
		action_target == "idle"


func _on_action_attack_state_entered() -> void:
	velocity = walk_speed * get_vector_to_creature_target().normalized()
	var result := creature_target.health_instance.damage(damage_instance, (creature_target.global_position - global_position).normalized(), self)
	if result and result.health_instance.is_dead():
		creature_target = null
	
	vertical.jump()
	
	state_chart.send_event("action_attack_conclude")


func _on_task_idle_state_processing(delta: float) -> void:
	var creature := Utils.find_child_of_class(get_tree().root, "Creature") as Creature
	action_target = "idle"
	if creature:
		creature_target = creature
		state_chart.send_event("task_attack_request")


func _on_task_travel_state_processing(delta: float) -> void:
	if (walk_target - global_position).length() < 12.0:
		state_chart.send_event("task_idle_request")
	else:
		action_target = "walk"
		#state_chart.send_event("action_walk_request")


func _on_action_idle_state_entered() -> void:
	velocity = Vector2.ZERO


func _on_task_travel_state_entered() -> void:
	#state_chart.send_event("action_walk_request")
	action_target = "walk"


func _on_task_attack_state_exited() -> void:
	creature_target = null


func _on_extra_state_carry_state_entered() -> void:
	animation_tree.set("parameters/idle_blend_tree/carry_blend/blend_amount", 1.0)
	animation_tree.set("parameters/walk_blend_tree/carry_blend/blend_amount", 1.0)
	carry_item_sprite.visible = true
	carry_item_sprite.texture = carriable.carry_item_texture
	carriable.pickup()


func _on_extra_state_carry_state_exited() -> void:
	animation_tree.set("parameters/idle_blend_tree/carry_blend/blend_amount", 0.0)
	animation_tree.set("parameters/walk_blend_tree/carry_blend/blend_amount", 0.0)
	carry_item_sprite.visible = false
	carriable.place(global_position)


func _on_task_carry_state_processing(delta: float) -> void:
	if not is_instance_valid(carriable):
		state_chart.send_event("task_idle_request")
		return
	
	if (carriable.global_position - global_position).length() < 12.0:
		state_chart.send_event("extra_state_carry_request")
		#state_chart.send_event("action_idle_request")
		action_target = "idle"
		state_chart.send_event("task_idle_request")
	else:
		walk_target = carriable.global_position
		#state_chart.send_event("action_walk_request")
		action_target = "walk"
