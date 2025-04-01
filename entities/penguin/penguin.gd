class_name Penguin
extends CharacterBody2D

const CarryObject = preload("res://entities/carry objects/carry_object.gd")
const CARRY_OBJECT_SCENE = preload("res://entities/carry objects/carry_object.tscn")

const Raft = preload("res://entities/props/raft/raft.gd")

@onready var flow_field_walker: FlowFieldWalker = $FlowFieldWalker
@onready var danger_target_detector: TargetDetector = $DangerTargetDetector
@onready var carriable_target_detector: TargetDetector = $CarriableTargetDetector
@onready var damage_instance: DamageInstance = $DamageInstance
@onready var trooper: Trooper = %Trooper
@onready var health_instance: HealthInstance = %HealthInstance
@onready var vertical_group: VerticalGroup = %VerticalGroup
@onready var flip_group: FlipGroup = %FlipGroup
@onready var equipment_sprite: Sprite2D = %EquipmentSprite
@onready var carry_object_sprite: Sprite2D = %CarryObjectSprite
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_chart: StateChart = $StateChart

@export var walk_speed: float = 20.0

var recieved_damage_result: DamageResult

var carriable: Carriable:
	set(value):
		carriable = value
		var blend_amount := 0.0
		var carry_object_type: CarryObjectType
		
		carry_object_sprite.visible = carriable != null
		if carriable:
			carry_object_type = carriable.carry_object_type
			carry_object_sprite.texture = carriable.carry_object_type.texture
			carry_object_sprite.offset = carriable.carry_object_type.offset
			blend_amount = 1.0
		
		animation_tree.set("parameters/idle_blend_tree/idle_carry_blend/blend_amount", blend_amount)
		animation_tree.set("parameters/idle_blend_tree/walk_carry_blend/blend_amount", blend_amount)
		animation_tree.set("parameters/idle_blend_tree/swim_carry_blend/blend_amount", blend_amount)
		animation_tree.set("parameters/idle_blend_tree/jump_carry_blend/blend_amount", blend_amount)

var equipment_type: CarryObjectTypeEquipment

var command_target: Target
var command_point: Vector2

var enemy_health_instance: HealthInstance
var danger_target: Target
var fishing_hole: FishingHole

var desired_action: StringName:
	set(value):
		var changed := desired_action != value
		desired_action = value
		if is_node_ready():
			if changed:
				state_chart.set_expression_property("desired_action", desired_action)

var swimming: bool:
	set(value):
		var changed := value != swimming
		swimming = value
		if changed:
			if swimming:
				animation_tree.set("parameters/idle_blend_tree/swim_blend/blend_amount", 1.0)
				if equipment_type != preload("res://entities/carry objects/carry object types/equipment_pool_ring.tres"):
					if carriable:
						throw_carriable(-velocity.normalized() * 8.0)
			else:
				animation_tree.set("parameters/idle_blend_tree/swim_blend/blend_amount", 0.0)

var in_deep_water: bool:
	set(value):
		var changed := in_deep_water != value
		in_deep_water = value
		if changed:
			if in_deep_water:
				SignalBus.penguin_entered_deep_water.emit(self)
			else:
				SignalBus.penguin_exited_deep_water.emit(self)

func _ready() -> void:
	SignalBus.penguin_borned.emit(self)
	
	animation_tree.set("parameters/idle_blend_tree/time_scale/scale", randf_range(0.8, 1.2))
	animation_tree.set("parameters/idle_blend_tree/idle_carry_blend/blend_amount", 0.0)
	animation_tree.set("parameters/idle_blend_tree/walk_carry_blend/blend_amount", 0.0)
	animation_tree.set("parameters/idle_blend_tree/swim_blend/blend_amount", 0.0)
	animation_tree.set("parameters/idle_blend_tree/flee_blend/blend_amount", 0.0)
	
	trooper.is_responsive_callable = func() -> bool:
		return not health_instance.is_dead()
	
	trooper.is_target_prioritized_callable = func(target: Target, comparator: Trooper) -> bool:
		var holder := target.owner
		if holder is Carriable:
			if carriable:
				return false
		
		if holder == fishing_hole:
			return true
		
		if fishing_hole:
			return false
		
		return (
			global_position.distance_squared_to(target.global_position) < 
			comparator.global_position.distance_squared_to(target.global_position)
			)
	
	trooper.is_target_valid_callable = func(target: Target) -> bool:
		var holder := target.owner
		if holder is Raft:
			var raft := holder as Raft
			if not raft.fuelled:
				if not carriable:
					return false
				
				if not raft.fuel_object_types.has(carriable.carry_object_type):
					return false
			
		if holder is Igloo:
			if not carriable:
				return false
			elif not holder.is_carry_object_type_valid(carriable.carry_object_type):
				return false
		
		if holder is Boffus and not carriable:
			return false
		
		return true



func _process(delta: float) -> void:
	state_chart.set_expression_property("on_floor", vertical_group.is_on_floor() and vertical_group.velocity <= 0)
	
	if velocity.is_zero_approx():
		animation_tree.set("parameters/idle_blend_tree/idle_walk_blend/blend_amount", 0.0)
	else:
		animation_tree.set("parameters/idle_blend_tree/idle_walk_blend/blend_amount", 1.0)
	
	if vertical_group.is_on_floor():
		animation_tree.set("parameters/idle_blend_tree/jump_blend/blend_amount", 0.0)
	else:
		animation_tree.set("parameters/idle_blend_tree/jump_blend/blend_amount", 1.0)
	
	danger_target = danger_target_detector.get_next_target()
	if danger_target != null:
		state_chart.send_event("request_task_panic")


func _physics_process(delta: float) -> void:
	move_and_slide()


func throw_carriable(carraible_velocity: Vector2 = Vector2.ZERO) -> void:
	carriable.place(global_position, 1.0, carraible_velocity, get_parent())
	carriable = null


func throw_new_carriable(item_type: CarryObjectType) -> void:
	var carry_object := CARRY_OBJECT_SCENE.instantiate() as CarryObject
	carry_object.carry_object_type = item_type
	carry_object.place(global_position, 1.0, Vector2.ZERO, get_parent())


func throw_items() -> void:
	if carriable: 
		throw_carriable()
	
	if equipment_type != null:
		state_chart.send_event("unequip")
		throw_new_carriable(equipment_type)


func get_command_target_point() -> Vector2:
	if is_command_target_valid():
		return command_target.global_position
	else:
		return command_point


func is_in_command_target_point_range() -> bool:
	if is_command_target_valid():
		return global_position.distance_to(command_target.global_position) <= command_target.size
	else:
		return global_position.distance_to(command_point) <= 4.0


func equip(type: CarryObjectTypeEquipment) -> void:
	equipment_type = type
	state_chart.send_event(equipment_type.state_request)


func interact_with_target(target: Target) -> void:
	var holder := target.holder
	if holder is Carriable:
		if carriable:
			throw_carriable()
		
		carriable = holder
		carriable.pickup()
		state_chart.send_event("request_task_idle")
		carriable_target_detector.active = false
		if carriable.carry_object_type is CarryObjectTypeEquipment:
			state_chart.send_event("unequip")
			carry_object_sprite.visible = false
			#equipment_type = carriable.carry_object_type
			state_chart.send_event("request_action_equip") # DANGER Could be interrupted
		
		return
	
	#var health_instance := Utils.find_child_of_class(holder, "HealthInstance") as HealthInstance
	if holder is HealthInstance:
		enemy_health_instance = holder
		desired_action = "attack"
		return
	
	if holder is Boffus:
		if carriable and carriable.carry_object_type.is_food():
			throw_carriable()
		
		state_chart.send_event("request_task_idle")
		return
	
	if holder is FishingHole:
		fishing_hole = holder
		desired_action = "fish"
		return
	
	if holder is Igloo:
		#carriable = null
		if carriable and holder.is_carry_object_type_valid(carriable.carry_object_type):
			throw_carriable()
		
		state_chart.send_event("request_task_idle")
		return
	
	if holder is Raft:
		if holder.fuelled:
			holder.add_penguin(self)
		else:
			if carriable and holder.fuel_object_types.has(carriable.carry_object_type):
				holder.provide_fuel(global_position, carriable.carry_object_type)
				carriable.queue_free()
				carriable = null
				#holder.add_penguin(self)
		
		return


func is_command_target_valid() -> bool:
	return (
		is_instance_valid(command_target) and command_target.is_inside_tree() 
		and command_target.active and (not command_target.occupant or command_target.occupant == self))


func kill() -> void:
	SignalBus.penguin_killed.emit(self)
	queue_free()


func _on_trooper_command_applied(point: Vector2, target: Target) -> void:
	command_target = target
	command_point = point
	
	state_chart.send_event("request_task_move_to_target")


func _on_health_instance_damage_received(result: DamageResult) -> void:
	recieved_damage_result = result
	state_chart.send_event("damage_recieved")


func _on_tile_detector_cell_changed(layer: TileMapLayer, current_coords: Vector2i, old_coords: Vector2i) -> void:
	var is_water_cell: bool
	var is_deep_water_cell: bool # TODO Change this to check old_coords instead
	var tile_data := layer.get_cell_tile_data(current_coords)
	if tile_data:
		is_water_cell = tile_data.get_custom_data("water")
		is_deep_water_cell =  tile_data.get_custom_data("deep_water")
	
	swimming = is_water_cell
	in_deep_water = is_deep_water_cell


#region Task States

# Idle
func _on_task_idle_state_entered() -> void:
	desired_action = "idle"
	danger_target_detector.active = true


func _on_task_idle_state_exited() -> void:
	#carriable_target_detector.active = true
	pass


func _on_task_idle_state_processing(delta: float) -> void:
	var next_carriable_target := carriable_target_detector.get_next_target()
	if next_carriable_target and next_carriable_target.holder is Carriable:
		command_target = next_carriable_target
		state_chart.send_event("request_task_move_to_target")


# Move to Target
func _on_task_move_to_target_state_entered() -> void:
	if is_in_command_target_point_range():
		if is_command_target_valid():
			state_chart.send_event("request_task_interact_with_target")
		else:
			state_chart.send_event("request_task_idle")
		return
	
	flow_field_walker.target_point = get_command_target_point()
	desired_action = "walk"


func _on_task_move_to_target_state_processing(delta: float) -> void:
	flow_field_walker.target_point = get_command_target_point()
	
	if is_in_command_target_point_range():
		if is_command_target_valid():
			state_chart.send_event("request_task_interact_with_target")
		else:
			state_chart.send_event("request_task_idle")


# Interact with Target
func _on_task_interact_with_target_state_entered() -> void:
	interact_with_target(command_target)


func _on_task_interact_with_target_state_processing(delta: float) -> void:
	if not is_command_target_valid() or not is_in_command_target_point_range():
		state_chart.send_event("request_task_move_to_target")

# Panic
func _on_task_panic_state_entered() -> void:
	danger_target_detector.active = false
	animation_tree.set("parameters/idle_blend_tree/panic_blend/blend_amount", 1.0)
	flow_field_walker.reverse_path = true
	flow_field_walker.target_point = danger_target.global_position
	desired_action = "walk"
	if carriable:
		throw_carriable()


func _on_task_panic_state_exited() -> void:
	animation_tree.set("parameters/idle_blend_tree/panic_blend/blend_amount", 0.0)
	flow_field_walker.reverse_path = false
	danger_target = null


#endregion

#region Action States

# Idle

func _on_action_idle_state_entered() -> void:
	pass
	#danger_target_detector.active = true


# Walk
func _on_action_walk_state_exited() -> void:
	velocity = Vector2.ZERO


func _on_action_walk_state_physics_processing(delta: float) -> void:
	if (flow_field_walker.target_point - global_position).length() > 1.0:
		velocity = walk_speed * flow_field_walker.get_direction()
		flip_group.flip_towards(velocity)
	else:
		velocity = Vector2.ZERO


# Attack
func _on_action_attack_state_entered() -> void:
	if not is_instance_valid(enemy_health_instance):
		print("enemy_health_instance is invalid!")
		state_chart.send_event("cancel_action_attack")
		desired_action = "idle"
		#state_chart.send_event("request_task_idle") # Should actions be able to dictate tasks?
		return
	
	velocity = walk_speed * (enemy_health_instance.global_position - global_position).normalized()
	flip_group.flip_towards(velocity)
	vertical_group.jump()
	
	enemy_health_instance.damage(damage_instance)
	
	state_chart.set_expression_property("on_floor", false)


func _on_action_attack_state_exited() -> void:
	velocity = Vector2.ZERO


# Fish
func _on_action_fish_state_entered() -> void:
	fishing_hole.occupant = self
	flip_group.flip_towards(Vector2.RIGHT)
	
	global_position = fishing_hole.seat_marker.global_position
	velocity = Vector2.ZERO
	
	#carriable = null
	if carriable:
		throw_carriable(Vector2.LEFT * 10.0)
	
	fishing_hole.finished.connect(func() -> void:
		desired_action = "idle"
		, ConnectFlags.CONNECT_ONE_SHOT)


func _on_action_fish_state_exited() -> void:
	fishing_hole.occupant = null


# Equip

func _on_action_equip_state_entered() -> void:
	carry_object_sprite.visible = true


func _on_action_equip_state_exited() -> void:
	if equipment_type:
		throw_new_carriable(equipment_type)
	
	equip(carriable.carry_object_type)
	carriable.queue_free()
	carriable = null


# Knockback
func _on_action_knockback_state_entered() -> void:
	velocity = recieved_damage_result.damage_direction * 30.0
	vertical_group.jump()
	
	state_chart.set_expression_property("on_floor", false)


func _on_action_knockback_state_exited() -> void:
	velocity = Vector2.ZERO


# Stun
func _on_action_stun_state_exited() -> void:
	vertical_group.jump(vertical_group.jump_speed * 0.75)


# Die
func _on_action_die_state_entered() -> void:
	Utils.call_delayed(self, 2.0, kill)
	velocity = Vector2.ZERO
	#carriable = null
	if carriable:
		throw_carriable()
	
	trooper.responsive = false
	health_instance.immortal = false
	health_instance.current_health = 0.0

#endregion

#region Equipment

func _on_equipment_equipped_state_entered() -> void:
	#equipment_sprite.frame_coords.y = equipment_type.sprite_frame_coords_y
	equipment_sprite.visible = true


func _on_equipment_equipped_state_exited() -> void:
	pass


#endregion
