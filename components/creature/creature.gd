@tool
extends Node2D
class_name Creature

@export_group("Health")
@export var free_owner_on_health_instance_died: bool = true
@export var health_instance: HealthInstance
@export_group("Creature Detection")
@export_flags("Player", "Enemy") var creature_layer: int
@export_flags("Player", "Enemy") var creature_mask: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if health_instance:
		if free_owner_on_health_instance_died:
			health_instance.died.connect(func():
				owner.queue_free()
				)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
