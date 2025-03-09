extends Node2D

const SnowParticle = preload("res://entities/effects/snow explosion/snow_particle.gd")

@export var start_size: SnowParticle.Size
@export var snow_particles: Array[SnowParticle] = []

func _enter_tree() -> void:
	for snow_particle in snow_particles:
		snow_particle.size = start_size


func _process(delta: float) -> void:
	if get_child_count(true) == 0:
		queue_free()
