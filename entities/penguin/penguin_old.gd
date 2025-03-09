extends CharacterBody2D
class_name Penguin

signal creature_target_changed
signal command_area_entered(command_area: Area2D)

@export var attack_range: float = 12.0
@export var walk_speed: float = 20.0

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var damage_instance: DamageInstance = $DamageInstance
@onready var flow_field_walker: FlowFieldWalker = $FlowFieldWalker
@onready var creature: Creature = %Creature
@onready var health_instance: HealthInstance = %HealthInstance
@onready var flip_group: FlipGroup = %FlipGroup
@onready var vertical_group: VerticalGroup = %VerticalGroup
@onready var equipment_sprite: Sprite2D = %EquipmentSprite
@onready var carry_item_sprite: Sprite2D = %CarryItemSprite
@onready var fire_particles: GPUParticles2D = %FireParticles
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var state_chart: StateChart = $StateChart
@onready var boffus_creature_detector: Creature = $BoffusCreatureDetector

#@onready var task_idle_state: AtomicState = %Idle
#@onready var task_travel_state: AtomicState = %Travel

@onready var punch_audio: AudioStreamPlayer2D = %PunchAudio
@onready var damaged_audio: AudioStreamPlayer2D = $Audio/DamagedAudio
@onready var jump_audio: AudioStreamPlayer2D = %JumpAudio
@onready var scared_audio: AudioStreamPlayer2D = %ScaredAudio

var creature_target: Creature:
	set(value):
		var old_creature := creature_target
		creature_target = value
		if creature_target != old_creature and is_node_ready():
			creature_target_changed.emit()

var walk_target: Vector2:
	get:
		return flow_field_walker.target_point
	set(value):
		flow_field_walker.target_point = value

var carriable_target: Carriable
var boffus_target: Boffus
var fishing_hole_target: FishingHole
var igloo_target: Igloo

var overlapping_water_count: int:
	set(value):
		var changed := value != overlapping_water_count
		overlapping_water_count = value
		if changed:
			if overlapping_water_count == 0:
				state_chart.send_event("effect_swim_conclude")
			else:
				state_chart.send_event("effect_swim_request")


var action_target: StringName:
	set(value):
		var old := action_target
		action_target = value
		if is_node_ready():
			if action_target != old:
				state_chart.set_expression_property("action_target", action_target)

var allow_attack: bool = true:
	set(value):
		allow_attack = value
		state_chart.set_expression_property("allow_attack", allow_attack)

var latest_damage_result: DamageResult

func _ready() -> void:
	creature_target_changed.emit.call_deferred()
	animation_tree.set("parameters/idle_blend_tree/time_scale/scale", randf_range(0.8, 1.2))
	animation_tree.set("parameters/idle_blend_tree/idle_carry_blend/blend_amount", 0.0)
	animation_tree.set("parameters/idle_blend_tree/walk_carry_blend/blend_amount", 0.0)
	animation_tree.set("parameters/idle_blend_tree/swim_blend/blend_amount", 0.0)
	animation_tree.set("parameters/idle_blend_tree/flee_blend/blend_amount", 0.0)
	carry_item_sprite.visible = false
	#state_chart.send_event.call_deferred("equip_pool_ring")
	#creature.apply_effect.call_deferred("fire")


func _process(delta: float) -> void:
	state_chart.set_expression_property("vertical_velocity", vertical_group.velocity)
	state_chart.set_expression_property("on_floor", vertical_group.is_on_floor() and vertical_group.velocity <= 0)
	if vertical_group.height == 0.0:
		animation_tree.set("parameters/idle_blend_tree/jump_blend/blend_amount", 0.0)
	else:
		animation_tree.set("parameters/idle_blend_tree/jump_blend/blend_amount", 1.0)


func _physics_process(delta: float) -> void:
	move_and_slide()


func  get_vector_to_creature_target() -> Vector2:
	return (creature_target.global_position - global_position)


func is_creature_target_in_attack_range() -> bool:
	return get_vector_to_creature_target().length() < attack_range


func reset_states() -> void:
	state_chart.send_event("carry_inactive_request")


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

"""
func _on_action_walk_state_physics_processing(delta: float) -> void:
	velocity = walk_speed * flow_field_walker.get_direction()
	#velocity = walk_speed * (walk_target - global_position).normalized()
	flip_group.flip_towards(velocity)
	if (walk_target - global_position).length() < 1.0:
		#state_chart.send_event("action_idle_request")
		action_target == "idle"
"""

func _on_action_attack_state_entered() -> void:
	allow_attack = false
	attack_cooldown_timer.start()
	velocity = walk_speed * get_vector_to_creature_target().normalized()
	var result := creature_target.health_instance.damage(damage_instance, (creature_target.global_position - global_position).normalized(), self)
	if result:
		punch_audio.play()
	
	if result and result.health_instance.is_dead():
		creature_target = null
	
	vertical_group.jump()
	state_chart.send_event("action_attack_conclude")



func request_next_task(creature_target_override: Creature = null) -> void:
	var next_creature_target := creature_target_override
	if not next_creature_target:
		next_creature_target = creature.get_next_creature_target()
	
	if next_creature_target:
		creature_target = next_creature_target
		if creature_target.owner is FishingHole and creature_target_override:
			fishing_hole_target = creature_target.owner
			flow_field_walker.target_point = creature_target.global_position
			#flow_field_walker.flow_field.set_target_coords(flow_field_walker.flow_field.point_to_coords(creature_target.global_position))
			state_chart.send_event("task_fish_request")
		elif creature_target.owner is Igloo:
			igloo_target = creature_target.owner
			flow_field_walker.target_point = creature_target.global_position
			#flow_field_walker.flow_field.set_target_coords(flow_field_walker.flow_field.point_to_coords(creature_target.global_position))
			state_chart.send_event("task_igloo_request")
		elif creature_target.owner is Boffus:
			flow_field_walker.target_point = creature_target.global_position
			#flow_field_walker.flow_field.set_target_coords(flow_field_walker.flow_field.point_to_coords(creature_target.global_position))
			boffus_target = creature_target.owner
			state_chart.send_event("task_feed_request")
		elif creature_target.carriable and creature_target.carriable.carry_object_type.penguin_interest and not carry_item_sprite.visible:
			carriable_target = creature_target.carriable
			state_chart.send_event("task_carry_request")
		elif creature_target.health_instance:
			flow_field_walker.target_point = creature_target.global_position
			#flow_field_walker.flow_field.set_target_coords(flow_field_walker.flow_field.point_to_coords(creature_target.global_position))
			state_chart.send_event("task_attack_request")
		



func _on_task_idle_state_processing(delta: float) -> void:
	#action_target = "idle"
	request_next_task()


func _on_task_travel_state_entered() -> void:
	#state_chart.send_event("action_walk_request")
	action_target = "walk"


func _on_task_travel_state_processing(delta: float) -> void:
	if (walk_target - global_position).length() < 4.0:
		state_chart.send_event("task_idle_request")
	else:
		action_target = "walk"
		#state_chart.send_event("action_walk_request")

"""
func _on_action_idle_state_entered() -> void:
	velocity = Vector2.ZERO
"""


func _on_task_attack_state_exited() -> void:
	creature_target = null


func _on_carry_active_state_entered() -> void:
	animation_tree.set("parameters/idle_blend_tree/walk_carry_blend/blend_amount", 1.0)
	animation_tree.set("parameters/idle_blend_tree/idle_carry_blend/blend_amount", 1.0)
	animation_tree.set("parameters/idle_blend_tree/swim_carry_blend/blend_amount", 1.0)
	carry_item_sprite.visible = true
	carry_item_sprite.texture = carriable_target.carry_object_type.texture
	carry_item_sprite.offset = carriable_target.carry_object_type.offset
	carriable_target.pickup()
	
	match carriable_target.carry_object_type:
		preload("res://entities/carry objects/carry object types/equipment_pool_ring.tres"):
			state_chart.send_event("equip_pool_ring")
			carriable_target = null
			state_chart.send_event("carry_inactive_request")


func _on_carry_inactive_state_entered() -> void:
	animation_tree.set("parameters/idle_blend_tree/idle_carry_blend/blend_amount", 0.0)
	animation_tree.set("parameters/idle_blend_tree/walk_carry_blend/blend_amount", 0.0)
	animation_tree.set("parameters/idle_blend_tree/swim_carry_blend/blend_amount", 0.0)
	carry_item_sprite.visible = false
	if carriable_target:
		carriable_target.place(global_position, 12.0)


func _on_task_carry_state_processing(delta: float) -> void:
	if not is_instance_valid(carriable_target) or not carriable_target.is_inside_tree():
		state_chart.send_event("task_idle_request")
		return
	
	if boffus_creature_detector.get_next_creature_target() != null:
		state_chart.send_event("task_flee_request")
		return
	
	if (carriable_target.global_position - global_position).length() < 12.0 and carriable_target.enabled:
		state_chart.send_event("carry_active_request")
		#state_chart.send_event("action_idle_request")
		action_target = "idle"
		state_chart.send_event("task_idle_request")
	else:
		walk_target = carriable_target.global_position
		#state_chart.send_event("action_walk_request")
		action_target = "walk"


func _on_knockback_state_entered() -> void:
	state_chart.set_expression_property("on_floor", false)
	damaged_audio.play()
	velocity = latest_damage_result.damage_direction * 30.0
	vertical_group.jump()


#func _on_health_instance_died() -> void:
#	state_chart.send_event("task_die_request")
#	action_target = "die"


func _on_action_die_state_entered() -> void:
	health_instance.immortal = false
	health_instance.current_health = 0.0
	#state_chart.send_event("extra_state_none_request")
	reset_states()
	Utils.call_delayed(self, 2.0, queue_free)
	collision_layer = 0
	collision_mask = 0
	creature.active = false
	velocity = Vector2.ZERO


func _on_health_instance_damage_received(result: DamageResult) -> void:
	latest_damage_result = result
	state_chart.send_event("damage_recieved")


func _on_knockback_state_exited() -> void:
	velocity = Vector2.ZERO


func _on_task_idle_state_entered() -> void:
	action_target = "idle"
	


func _on_attack_cooldown_timer_timeout() -> void:
	allow_attack = true


func _on_task_fish_state_physics_processing(delta: float) -> void:
	if fishing_hole_target.occupant != null and fishing_hole_target.occupant != self:
		state_chart.send_event("task_travel_request")
		return
	
	if fishing_hole_target.carriable_launcher.carriables.size() == 0:
		state_chart.send_event("task_travel_request")
		return
	
	if (walk_target - global_position).length() < 6.0:
		action_target = "fish"
	else:
		action_target = "walk"
		#state_chart.send_event("action_walk_request")


func _on_action_fish_state_entered() -> void:
	global_position = walk_target
	velocity = Vector2.ZERO
	flip_group.flip_towards(Vector2.RIGHT)
	fishing_hole_target.occupant = self
	#state_chart.send_event("extra_state_none_request")
	reset_states()


func _on_action_fish_state_exited() -> void:
	fishing_hole_target.occupant = null


func _on_feed_state_physics_processing(delta: float) -> void:
	if not carry_item_sprite.visible:
		state_chart.send_event("task_travel_request")
	
	if (walk_target - global_position).length() < 12.0 and boffus_target.allow_eat:
		#state_chart.send_event("extra_state_none_request")
		reset_states()
	else:
		action_target = "walk"


func _on_task_igloo_state_physics_processing(delta: float) -> void:
	if (walk_target - global_position).length() < 6.0 and carry_item_sprite.texture != preload("res://entities/carry objects/assets/meat_big.png"): #and igloo_target.allow_eat:
		#state_chart.send_event("extra_state_none_request")
		reset_states()
		state_chart.send_event("task_travel_request")
	else:
		action_target = "walk"


func _on_task_idle_sleep_state_entered() -> void:
	action_target = "sleep"


func _on_command_area_entered(command_area: Area2D) -> void:
	state_chart.send_event("command_area_entered")


func _on_task_idle_stand_state_entered() -> void:
	action_target = "idle"


func _on_action_sleep_state_exited() -> void:
	vertical_group.jump(vertical_group.jump_speed * 0.6)


func _on_task_die_state_entered() -> void:
	action_target = "die"


#func _on_vertical_jumped() -> void:
	#punch_audio.play()
	#jump_audio.play()


func _on_action_stun_state_entered() -> void:
	pass


func _on_action_stun_state_exited() -> void:
	vertical_group.jump(vertical_group.jump_speed * 0.6)


func _on_action_idle_walk_state_entered() -> void:
	animation_tree.set("parameters/idle_blend_tree/idle_walk_blend/blend_amount", 1.0)


func _on_action_idle_stand_state_entered() -> void:
	animation_tree.set("parameters/idle_blend_tree/idle_walk_blend/blend_amount", 0.0)
	
	velocity = Vector2.ZERO


func _on_action_idle_walk_state_processing(delta: float) -> void:
	pass # Replace with function body.


func _on_action_idle_walk_state_physics_processing(delta: float) -> void:
	#velocity = walk_speed * (walk_target - global_position).normalized()
	if (walk_target - global_position).length() > 1.0:
		#state_chart.send_event("action_idle_request")
		velocity = walk_speed * flow_field_walker.get_direction()
		flip_group.flip_towards(velocity)
	else:
		velocity = Vector2.ZERO


func _on_effect_swim_state_entered() -> void:
	print("HOHOHO")
	animation_tree.set("parameters/idle_blend_tree/swim_blend/blend_amount", 1.0)
	walk_speed *= 0.75


func _on_effect_swim_state_exited() -> void:
	animation_tree.set("parameters/idle_blend_tree/swim_blend/blend_amount", 0.0)
	walk_speed /= 0.75


func _on_task_flee_state_entered() -> void:
	flow_field_walker.reverse_path = true
	#state_chart.send_event("extra_state_none_request")
	reset_states()
	animation_tree.set("parameters/idle_blend_tree/flee_blend/blend_amount", 1.0)
	scared_audio.play()


func _on_task_flee_state_exited() -> void:
	flow_field_walker.reverse_path = false
	animation_tree.set("parameters/idle_blend_tree/flee_blend/blend_amount", 0.0)


func _on_task_flee_state_processing(delta: float) -> void:
	var creature := boffus_creature_detector.get_next_creature_target()
	if creature:
		walk_target = creature.global_position
		action_target = "walk"
	else:
		state_chart.send_event("task_flee_conclude")


func _on_reactive_task_state_processing(delta: float) -> void:
	var creature := boffus_creature_detector.get_next_creature_target()
	if creature and creature.owner is Boffus:
		state_chart.send_event("task_flee_request")


func _on_creature_effect_applied(effect: StringName) -> void:
	match effect:
		"fire":
			state_chart.send_event("effect_burn_request")


func _on_creature_effect_removed(effect: StringName) -> void:
	match effect:
		"fire":
			pass


func _on_effect_burn_state_entered() -> void:
	fire_particles.emitting = true
	walk_target = global_position + 16.0 * Vector2.from_angle(randf() * 2.0 * PI)
	action_target = "walk"
	state_chart.send_event("task_flee_request")


func _on_effect_burn_state_processing(delta: float) -> void:
	state_chart.send_event("task_flee_request")
	vertical_group.modulate = vertical_group.modulate.lerp(Color("452200"), delta / 6.5)


func _on_effect_burn_state_exited() -> void:
	fire_particles.emitting = false
	vertical_group.modulate = Color.WHITE
	state_chart.send_event("task_idle_request")


func _on_equipment_free_state_entered() -> void:
	equipment_sprite.visible = false


func _on_equipment_free_state_exited() -> void:
	equipment_sprite.visible = true


func _on_equipment_pool_ring_state_entered() -> void:
	equipment_sprite.frame_coords.y = 0
