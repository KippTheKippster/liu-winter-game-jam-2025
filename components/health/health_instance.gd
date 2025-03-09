@tool
@icon("assets/health_instance_icon.svg")
extends Node2D
class_name HealthInstance

signal damage_received(result: DamageResult)
signal died
signal health_changed(current_health: float, old_health: float)

@onready var current_health: float = base_health:
	get:
		return current_health
	set(value):
		var old_health = current_health
		current_health = min(value, base_health)
		if old_health != current_health:
			health_changed.emit(current_health, old_health)
			if is_dead() and old_health > 0:
				died.emit()

@export var enabled: bool = true
@export var immortal: bool
@export_range(0.0, 20.0, 0.001, "or_greater") var base_health: float = 1.0
@export_range(0.0, 2.0, 0.001, "or_greater") var max_immnuity_time: float = 0.0
var active_immunity_time: float
var damage_mask: int


func _process(delta: float) -> void:
	active_immunity_time = move_toward(active_immunity_time, 0, delta)


func damage(damage_instance: DamageInstance, damage_direction: Vector2 = Vector2.ZERO, damage_source: Object = null) -> DamageResult:
	if not enabled:
		return null
	
	if is_dead():
		return null
	
	if not damage_instance:
		return null
	
	if active_immunity_time > 0:
		return null
	
	active_immunity_time = max_immnuity_time
	
	var old_health := current_health
	current_health -= damage_instance.base_damage
	
	var final_damage := old_health - current_health
	
	var result := DamageResult.new()
	result.health_instance = self
	result.damage_instance = damage_instance
	result.damage_source = damage_source
	result.damage_direction = damage_direction
	result.old_health = old_health
	result.new_health = current_health
	result.final_damage = final_damage
	
	damage_received.emit(result)
	damage_instance.damage_dealt.emit(result)
	
	return result


func is_dead() -> bool:
	return current_health <= 0 and not immortal


func _get_property_list() -> Array[Dictionary]:
	var property_list: Array[Dictionary] = []
	#if get_parent() is Area2D:
	property_list.append(DamageInstance.get_damage_layer_property_list("damage_mask"))

	return property_list
