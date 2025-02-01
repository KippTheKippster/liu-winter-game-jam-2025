@icon("assets/projectile_icon.svg")
extends Node2D
class_name Projectile

signal body_entered(body: Node2D)
signal damage_dealt(damage_result: DamageResult)
signal destroyed

@export_range(0.0, 10.0, 0.0001, "or_greater") var free_wait_time: = 1.0

@export var max_pierce_count: int = 0
var pierce_count: int:
	set(value):
		pierce_count = value
		if pierce_count > max_pierce_count:
			destroy()

var firearm_owner: Firearm

var destroy_callable: Callable = func() -> void: 
	if owner.is_queued_for_deletion():
		return
	
	owner.queue_free()
	destroyed.emit()


#var set_direction_callable: Callable = func(direction: Vector2) -> void:
#	set_velocity(get_speed() )
#var get_direction_callable: Callable = func() -> Vector2:
#	return get_velocity().normalized()
#var set_speed_callable: Callable


var set_velocity_callable: Callable
var get_velocity_callable: Callable
var set_direction_to_target_point_callable: Callable
var set_damage_layer_callable: Callable = func(layer: int) -> void:
	get_damage_instance().damage_layer = layer

var get_damage_instance_callable: Callable = func() -> DamageInstance: return null
var get_area_callable: Callable = func() -> Area2D: return null

var is_point_reachable_callable: Callable = func(point: Vector2) -> bool: return true 


func _ready() -> void:
	_ready_deferred.call_deferred()


func _ready_deferred() -> void:
	var damage_instance := get_damage_instance()
	if damage_instance:
		damage_instance.damage_dealt.connect(func(damage_result: DamageResult) -> void: damage_dealt.emit(damage_result))
	
	damage_dealt.connect(func(damage_result: DamageResult) -> void: pierce_count += 1)
	
	var area := get_area()
	if area:
		area.body_entered.connect(func(body: Node2D) -> void: body_entered.emit(body))
	
	if free_wait_time > 0.0:
		Utils.call_delayed(self, free_wait_time, destroy)


func destroy() -> void:
	destroy_callable.call()

func set_direction_to_target_point(point: Vector2) -> void:
	set_direction_to_target_point_callable.call(point)


func set_damage_layer(layer: int) -> void:
	set_damage_layer_callable.call(layer)


func set_velocity(velocity: Vector2) -> void:
	set_velocity_callable.call(velocity)


func get_damage_instance() -> DamageInstance:
	return get_damage_instance_callable.call() 


func get_area() -> Area2D:
	return get_area_callable.call()


func get_velocity() -> Vector2:
	return get_velocity_callable.call()
