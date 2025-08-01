@icon("uid://yhjpfck7w0md")
class_name Penguin
extends CharacterBody2D

const CarryObject = preload("res://entities/carry objects/carry_object.gd")
const CARRY_OBJECT_SCENE = preload("res://entities/carry objects/carry_object.tscn")

const TOOL_DYNAMITE = preload("uid://be1c6v2dam34l")
const TOOL_BRIDGE_TILE = preload("uid://bnyh58x0lgqdx")

const Raft = preload("res://entities/props/raft/raft.gd")
const Bridge = preload("uid://bftktmcermlew")
const BridgeTilePile = preload("uid://bonppi2orhad8")

var current_bridge_tile_pile: BridgeTilePile

@onready var flow_field_walker: FlowFieldWalker = $FlowFieldWalker
@onready var danger_target_detector: TargetDetector = $DangerTargetDetector
@onready var carriable_target_detector: TargetDetector = $CarriableTargetDetector
@onready var damage_instance: DamageInstance = $DamageInstance
@onready var trooper: Trooper = %Trooper
@onready var health_instance: HealthInstance = %HealthInstance
@onready var vertical_group: VerticalGroup = %VerticalGroup
@onready var flip_group: FlipGroup = %FlipGroup
@onready var penguin_sprite: Sprite2D = %PenguinSprite
@onready var equipment_sprite: Sprite2D = %EquipmentSprite
@onready var carry_object_sprite: Sprite2D = %CarryObjectSprite
@onready var fire_particles: GPUParticles2D = %FireParticles
@onready var smoke_particles: GPUParticles2D = %SmokeParticles
@onready var damaged_audio: AudioStreamPlayer2D = $Audio/DamagedAudio
@onready var scared_audio: AudioStreamPlayer2D = %ScaredAudio
@onready var electricity_audio: AudioStreamPlayer2D = %ElectricityAudio
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_chart: StateChart = $StateChart
@onready var action_stun_state: AnimationTreeState = %"Action Stun"

@export var walk_speed: float = 20.0
@export var extra_interaction_range: float = 24.0

var external_velocity: Vector2

var allow_ineraction: bool = true

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

var heavy_carriable_target: Target

var lock_carriable: bool = false

@export var equipment_type: CarryObjectTypeEquipment

var command_point: Vector2
var command_point_offset: Vector2
var command_target: Target

var enemy_health_instance: HealthInstance
var danger_target: Target
var danger_point: Vector2
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
				effect_fire_active = false
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

@export var effect_fire_wait_time: float = 2.0
var effect_fire_time_left: float = 0.0
var effect_fire_active: bool:
	set(value):
		var changed := effect_fire_active != value
		effect_fire_active = value
		if swimming:
			effect_fire_active = false
		
		fire_particles.emitting = effect_fire_active
		if changed:
			effect_fire_time_left = 0.0
			if effect_fire_active:
				scared_audio.play()
				animation_tree.set("parameters/idle_blend_tree/fire_blend/blend_amount", 1.0)
			else:
				animation_tree.set("parameters/idle_blend_tree/fire_blend/blend_amount", 0.0)
				penguin_sprite.self_modulate = Color.WHITE
			#state_chart.send_event("request_task_panic")


func _ready() -> void:
	SignalBus.penguin_borned.emit(self)
	
	if equipment_type:
		state_chart.send_event.call_deferred("equip_generic")
	
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
		
		if holder is Carriable:
			if holder.carry_object_type == equipment_type:
				return false
		
		if holder is HeavyCarriable:
			if heavy_carriable_target and heavy_carriable_target.holder == holder:
				return false
		
		if holder is Bridge:
			if not carriable or carriable.carry_object_type != TOOL_BRIDGE_TILE:
				return false
		
		return true


func _process(delta: float) -> void:
	var on_floor := vertical_group.is_on_floor() and vertical_group.velocity <= 0
	if state_chart.get_expression_property("on_floor") != on_floor:
		state_chart.set_expression_property("on_floor", on_floor)
	
	penguin_sprite.self_modulate = Color.WHITE.lerp(Color.hex(0x523722ff), effect_fire_time_left / effect_fire_wait_time)
	
	if effect_fire_active:
		effect_fire_time_left += delta
		if effect_fire_time_left >= effect_fire_wait_time:
			effect_fire_time_left = effect_fire_wait_time
			state_chart.send_event("request_action_die")
	
	if (velocity + external_velocity).is_zero_approx():
		animation_tree.set("parameters/idle_blend_tree/idle_walk_blend/blend_amount", 0.0)
	else:
		animation_tree.set("parameters/idle_blend_tree/idle_walk_blend/blend_amount", 1.0)
	
	if vertical_group.is_on_floor():
		animation_tree.set("parameters/idle_blend_tree/jump_blend/blend_amount", 0.0)
	else:
		animation_tree.set("parameters/idle_blend_tree/jump_blend/blend_amount", 1.0)



func _physics_process(delta: float) -> void:
	var pre := velocity
	velocity = pre + external_velocity
	move_and_slide()
	velocity = pre
	external_velocity = Vector2.ZERO
	
	if is_on_wall():
		flow_field_walker.force_center = true
	
	danger_target = danger_target_detector.get_next_target()
	if danger_target != null:
		state_chart.send_event("request_task_panic")


func throw_carriable(carraible_velocity: Vector2 = Vector2.ZERO) -> Carriable:
	var thrown_carriable := carriable
	carriable.place(global_position, 1.0, carraible_velocity, get_parent())
	carriable = null
	return thrown_carriable


func throw_new_carriable(item_type: CarryObjectType) -> void:
	var carry_object := load(item_type.carriable_scene_path).instantiate() as Carriable
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
		var extra_range := 0.0
		if is_ranged_interaction_allowed(command_target):
			extra_range = extra_interaction_range
		
		return global_position.distance_to(command_target.global_position) <= command_target.size + extra_range
	else:
		return global_position.distance_to(command_point) <= 0.5


func equip(type: CarryObjectTypeEquipment) -> void:
	equipment_type = type
	state_chart.send_event(equipment_type.state_request)


func is_ranged_interaction_allowed(target: Target) -> bool:
	if carriable and carriable.carry_object_type == TOOL_DYNAMITE:
		return true
	
	return false


func interact_with_target(target: Target) -> void:
	var holder := target.holder
	if holder is Carriable:
		if equipment_type != holder.carry_object_type and not lock_carriable:
			if carriable:
				throw_carriable()
			
			state_chart.send_event("cancel_action_equip")
			
			carriable = holder
			carriable.pickup()
			state_chart.send_event("request_task_idle")
			carriable_target_detector.active = false
			if carriable .carry_object_type is CarryObjectTypeEquipment:
				state_chart.send_event("unequip") # Does this achieve anything?
				carry_object_sprite.visible = false
				#equipment_type = carriable.carry_object_type
				state_chart.send_event("request_action_equip") # DANGER Could be interrupted
			
			return
	
	if holder is HeavyCarriable:
		if holder.add_carrier(self):
			heavy_carriable_target = target
			target.occupant = self
			state_chart.send_event("request_action_heavy_carry")
			return
	
	if holder is HealthInstance:
		if carriable and carriable.carry_object_type == TOOL_DYNAMITE:
			var dir = (holder.global_position - global_position).normalized()
			var thrown_carriable := throw_carriable(dir * 24.0)
			thrown_carriable.position += dir * 2.0
			if not thrown_carriable.ignite:
				var backtraces = Engine.capture_script_backtraces()
				print(backtraces)
			
			thrown_carriable.ignite()
		else:
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
			#holder.add_penguin(self)
			flow_field_walker.target_point = holder.global_position
			vertical_group.landed.connect((func(raft: Raft) -> void:
				if global_position.distance_to(raft.global_position) < 12.0:
					if is_inside_tree():
						raft.add_penguin(self)
				).bind(holder), ConnectFlags.CONNECT_ONE_SHOT)
			
			if carriable:
				throw_carriable()
			
			if vertical_group.is_on_floor():
				vertical_group.jump()
		else:
			if carriable and holder.fuel_object_types.has(carriable.carry_object_type):
				holder.provide_fuel(global_position, carriable.carry_object_type)
				carriable.queue_free()
				carriable = null
				#holder.add_penguin(self)
		
		return
	
	if holder is Bridge:
		if carriable and carriable.carry_object_type == TOOL_BRIDGE_TILE:
			if holder.tile_amount != holder.get_max_amount():
				carriable.place(global_position, 0.0)
				holder.tile_amount += 1
				carriable.queue_free()
				carriable = null
				return
	
	if holder is BridgeTilePile:
		if carriable:
			throw_carriable()
		
		if not holder.is_empty():
			carriable = holder.take_tile()
			
			return
			#current_bridge_tile_pile = holder
		#if carriable # TODO Add check!


func is_command_target_valid() -> bool:
	return (
		is_instance_valid(command_target) and command_target.is_inside_tree() 
		and command_target.active and (not command_target.occupant or command_target.occupant == self))


func kill() -> void:
	if equipment_type:
		var carry_object := CARRY_OBJECT_SCENE.instantiate() as CarryObject
		carry_object.carry_object_type = equipment_type
		carriable = carry_object
		throw_carriable()
	
	SignalBus.penguin_killed.emit(self)
	queue_free()


func _on_trooper_command_applied(point: Vector2, offset: Vector2, target: Target) -> void:
	command_target = target
	command_point = point + offset
	#command_point_offset = Vector2.RIGHT * 8.0 # offset FIXME
	
	if command_target:
		var holder := command_target.holder
		if holder is BridgeTilePile:
			current_bridge_tile_pile = holder
			state_chart.send_event("request_command_build_bridge")
			return
	
	state_chart.send_event("request_command_free")
	state_chart.send_event("request_task_move_to_target")


func _on_health_instance_damage_received(result: DamageResult) -> void:
	recieved_damage_result = result
	if recieved_damage_result.damage_instance.effect == DamageInstance.Effect.FIRE:
		danger_point = result.damage_instance.global_position
		state_chart.send_event("request_task_panic")
		effect_fire_active = true
	elif recieved_damage_result.damage_instance.effect == DamageInstance.Effect.ELECTRICITY:
		state_chart.send_event("electricity_received")
		return
	
	if recieved_damage_result.final_damage > 0:
		state_chart.send_event("damage_received")
		damaged_audio.play() 
	elif result.damage_instance.apply_knockback:
		state_chart.send_event("request_action_knockback")
		damaged_audio.play() 


func _on_tile_detector_tile_detected(layer: TileMapLayer, coords: Vector2i) -> void:
	var is_water_cell: bool
	var is_deep_water_cell: bool # TODO Change this to check old_coords instead
	var tile_data := layer.get_cell_tile_data(coords)
	if tile_data:
		if tile_data.has_custom_data("water"):
			is_water_cell = tile_data.get_custom_data("water")
		
		if tile_data.has_custom_data("deep_water"):
			is_deep_water_cell = tile_data.get_custom_data("deep_water")
	
	swimming = is_water_cell
	in_deep_water = is_deep_water_cell


func _on_trooper_selected() -> void:
	state_chart.send_event("selected")


func _on_tree_exiting() -> void:
	state_chart.send_event("tree_exiting")

#region Command States
func _on_command_build_bridge_state_entered() -> void:
	state_chart.send_event("request_task_move_to_target")


func _on_command_build_bridge_state_processing(delta: float) -> void:
	if not carriable or carriable.carry_object_type != TOOL_BRIDGE_TILE:
		if current_bridge_tile_pile.is_empty():
			state_chart.send_event("request_command_free")
			state_chart.send_event("request_task_idle")
			state_chart.send_event("request_action_idle")
			return
		
		command_target = current_bridge_tile_pile.target
	else:
		command_target = current_bridge_tile_pile.bridge.target

#endregion

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
			global_position = command_point
			state_chart.send_event("request_task_idle")
		return
	
	flow_field_walker.target_point_offset = command_point_offset
	flow_field_walker.target_point = get_command_target_point()
	desired_action = "walk"


func _on_task_move_to_target_state_processing(delta: float) -> void:
	flow_field_walker.target_point_offset = command_point_offset
	flow_field_walker.target_point = get_command_target_point()
	
	if is_in_command_target_point_range():
		if is_command_target_valid():
			state_chart.send_event("request_task_interact_with_target")
		else:
			global_position = command_point
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
	if danger_target:
		flow_field_walker.target_point = danger_target.global_position # FIXME Sometimes this is called when it is null
	else:
		flow_field_walker.target_point = danger_point
	
	desired_action = "walk"
	if carriable:
		throw_carriable()
	
	scared_audio.play()


func _on_task_panic_state_exited() -> void:
	animation_tree.set("parameters/idle_blend_tree/panic_blend/blend_amount", 0.0)
	flow_field_walker.reverse_path = false
	#danger_target = null


#endregion

#region Action States

# Idle
func _on_action_idle_sleep_state_exited() -> void:
	vertical_group.jump(vertical_group.jump_speed * 0.6)


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
	lock_carriable = true


func _on_action_equip_state_exited() -> void:
	if equipment_type:
		throw_new_carriable(equipment_type)
		equipment_type = null
	
	if carriable: # and carriable.carry_object_type is CarryObjectTypeEquipment: # HACK BRUH
		equip(carriable.carry_object_type)
		carriable.queue_free()
		carriable = null
	
	lock_carriable = false


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


# Electricity
func _on_action_electricity_state_entered() -> void:
	velocity = Vector2.ZERO
	health_instance.enabled = false
	electricity_audio.play()
	scared_audio.play()
	smoke_particles.emitting = true


func _on_action_electricity_state_exited() -> void:
	health_instance.enabled = true
	vertical_group.landed.connect(func(): smoke_particles.emitting = false, ConnectFlags.CONNECT_ONE_SHOT)


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

# Heavy Carriable
func _on_action_heavy_carry_state_entered() -> void:
	pass
	#state_chart.send_event("request_task_idle")
	#trooper.command_applied.connect(state_chart.send_event.bind("cancel_action_heavy_carry"), ConnectFlags.CONNECT_ONE_SHOT)


func _on_action_heavy_carry_state_exited() -> void:
	#if is_instance_valid(heavy_carriable):
	var heavy_carriable := heavy_carriable_target.holder as HeavyCarriable
	heavy_carriable.remove_carrier(self)
	heavy_carriable_target.occupant = null
	heavy_carriable_target = null


func _on_action_heavy_carry_state_physics_processing(delta: float) -> void:
	if heavy_carriable_target == command_target:
		global_position = command_target.global_position
	else:
		state_chart.send_event("cancel_action_heavy_carry")


#endregion

#region Equipment

func _on_equipment_equipped_state_entered() -> void:
	#equipment_sprite.frame_coords.y = equipment_type.sprite_frame_coords_y
	equipment_sprite.visible = true


func _on_equipment_equipped_state_exited() -> void:
	pass


#endregion
