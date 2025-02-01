@icon("assets/effects_player_icon.svg")
extends Node2D
class_name EffectsPlayer
"""
@export_group("Health")
@export var damage_recieved_material: ShaderMaterial = preload("uid://cax15a15bjuso")
@export var died_scene: PackedScene = preload("uid://byno7yolw8v6i")
@export var material_holder: CanvasItem
@export var health_instance: HealthInstance
var flash_timer: Timer


func _ready() -> void:
	if health_instance and material_holder:
		material_holder.material = damage_recieved_material
		health_instance.damage_received.connect(func(damage_result: DamageResult):
			material_holder.set("instance_shader_parameters/flash_strength", 1.0)
			flash_timer.start()
			)
		flash_timer = Timer.new()
		flash_timer.one_shot = true
		flash_timer.wait_time = 0.05
		flash_timer.timeout.connect(func():
			material_holder.set("instance_shader_parameters/flash_strength", 0.0)
			)
		add_child(flash_timer)
	
	if health_instance and died_scene:
		health_instance.died.connect(func():
			var node := died_scene.instantiate()
			owner.add_sibling(node)
			if node is Node2D:
				node.global_position = global_position
			)
"""
