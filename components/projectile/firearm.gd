@tool
@icon("assets/firearm_icon.svg")
extends Node2D
class_name Firearm

signal pre_fired
signal projectile_fired(projectile: Projectile)
signal projectile_instantiated(projectile: Projectile)

@export var projectile_scene: PackedScene:
	set(value):
		projectile_scene = value
@export var projectile_start_speed: float = 240.0

@export_range(0.0, 2.0, 0.01, "or_greater") var reload_wait_time: float = 0.1
var reload_time_left: float

var projectile_damage_layer: int = 1


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	reload_time_left = move_toward(reload_time_left, 0.0, delta)


func can_fire() -> bool:
	return reload_time_left == 0


func fire() -> Projectile:
	if not can_fire():
		return null
	
	pre_fired.emit()
	
	reload_time_left = reload_wait_time
	
	var projectile := instantiate_projectile(projectile_scene)
	
	projectile_fired.emit(projectile)
	
	return projectile


func fire_towards(direction: Vector2) -> Projectile:
	var projectile := fire()
	if not projectile:
		return null
	
	projectile.set_velocity(direction * projectile.get_velocity().length())
	return projectile


func fire_at_point(point: Vector2) -> Projectile:
	var projectile := fire()
	if not projectile:
		return null
	
	projectile.set_direction_to_target_point(point)
	return projectile


func fire_at_node(node: Node2D) -> Projectile:
	return fire_at_point(node.global_position)


func instantiate_projectile(scene: PackedScene) -> Projectile:
	var root = scene.instantiate()
	owner.add_sibling(root)
	
	if root is Node2D:
		root.global_position = global_position
	
	var projectile := Utils.find_child_of_class(root, "Projectile", true) as Projectile
	if not projectile:
		push_error("Firearm trying to instaniate scene without a 'Projectile' child: ", get_path())
		owner.remove_child(root)
		root.queue_free()
		return null
	
	projectile.firearm_owner = self
	projectile.set_damage_layer(projectile_damage_layer)
	projectile.set_velocity(projectile_start_speed * Vector2.from_angle(global_rotation)) # NOTE 'global_rotation' can give incorrect angle if it has a negative scale
	
	projectile_instantiated.emit(projectile)
	
	return projectile


func is_point_reachable(point: Vector2) -> bool:
	var dummy_projectile: Projectile = instantiate_projectile(projectile_scene)
	if is_instance_valid(dummy_projectile):
		var is_reachable: bool = dummy_projectile.is_point_reachable_callable.call(point)
		dummy_projectile.owner.queue_free()
		dummy_projectile.owner.remove_child(dummy_projectile)
		return is_reachable
	
	return false


func _get_property_list() -> Array[Dictionary]:
	var property_list: Array[Dictionary] = []
	property_list.append(DamageInstance.get_damage_layer_property_list("projectile_damage_layer"))
	return property_list


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not projectile_scene:
		warnings.append("A projectile scene is required for the node to work.")
	
	return warnings
