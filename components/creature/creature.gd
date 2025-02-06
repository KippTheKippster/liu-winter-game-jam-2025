@tool
extends Node2D
class_name Creature

signal died

@export var creature_log: CreatureLog
@export_group("Health")
@export var free_owner_on_health_instance_died: bool = true
@export var health_instance: HealthInstance
@export var carriable: Carriable
@export_group("Creature Detection")
@export var detection_range: float = 48.0
var detection_range_squared: float
@export_flags("Enemy", "Penguin", "Food", "Fishing Hole", "Boffus", "Igloo") var creature_layer: int
@export_flags("Enemy", "Penguin", "Food", "Fishing Hole", "Boffus", "Igloo") var creature_mask: int
var active: bool = true

func _enter_tree() -> void:
	detection_range_squared = detection_range * detection_range
	if not is_in_group("creature"):
		add_to_group("creature")


func _ready() -> void:
	if health_instance:
		health_instance.died.connect(func():
			died.emit()
			)
		
		if free_owner_on_health_instance_died:
			health_instance.died.connect(func():
				owner.queue_free()
				)


func get_next_creature_target() -> Creature:
	var creatures := get_tree().get_nodes_in_group("creature")
	var closest_distance := detection_range_squared
	var closest_creature: Creature
	for creature: Creature in creatures:
		if creature_mask & creature.creature_layer > 0:
			var distance := global_position.distance_squared_to(creature.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_creature = creature
	
	return closest_creature
