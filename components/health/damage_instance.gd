@tool
@icon("assets/damage_instance_icon.svg")
extends Node2D
class_name DamageInstance

enum Effect {
	NONE,
	FIRE,
	ICE,
	ELECTRICITY,
}

const DAMAGE_LAYER_HINT_STRING = "World,Enemy,Penguin"

signal damage_dealt(result: DamageResult)

@export var enabled: bool = true
@export var ignore_immunity_time: bool = false
@export var apply_knockback: bool = true
@export_range(0.0, 5.0, 0.001, "or_greater") var base_damage: float = 1.0

var area: Area2D
var damage_layer: int = 1
@export var effect: Effect = Effect.NONE

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			if get_parent() is Area2D:
				area = get_parent()
				set_physics_process(true)
		NOTIFICATION_PHYSICS_PROCESS:
			if Engine.is_editor_hint():
				return
			
			if not enabled:
				return
			
			if not area:
				return
			
			for health_instance in get_overlapping_health_instances():
				health_instance.damage(self, (health_instance.global_position - global_position).normalized(), owner)
				#if result:
				#	damage_dealt.emit(result)


func get_overlapping_health_instances() -> Array[HealthInstance]:
	var health_instances: Array[HealthInstance] = []
	for overlapping_area in area.get_overlapping_areas():
		var health_instance := Utils.find_child_of_class(overlapping_area, "HealthInstance", false) as HealthInstance
		if health_instance and health_instance.damage_mask & damage_layer != 0:
			health_instances.append(health_instance)
	
	return health_instances


static func get_damage_layer_property_list(property_name: String = "damage_layer") -> Dictionary:
	return {
			"name": property_name,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_FLAGS,
			"hint_string": DAMAGE_LAYER_HINT_STRING
		}


func _get_property_list() -> Array[Dictionary]:
	var property_list: Array[Dictionary] = []
	if get_parent() is Area2D:
		property_list.append(get_damage_layer_property_list())
	
	return property_list
