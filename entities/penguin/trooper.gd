extends Node2D
class_name Trooper

signal command_applied(point: Vector2, target: Target)

const SURPRISE_EFFECT_SCENE := preload("res://entities/effects/surprise/surprise_effect.tscn")

@export var responsive: bool = true:
	set(value):
		responsive = value
		if not responsive:
			selected = false

var surprise_effect: Node2D

var selected: bool:
	set(value):
		selected = value
		if value:
			surprise_effect = SURPRISE_EFFECT_SCENE.instantiate()
			add_child(surprise_effect)
		else:
			if surprise_effect:
				surprise_effect.queue_free()
				surprise_effect = null

var is_target_prioritized_callable: Callable = func(target: Target, comparator: Trooper) -> bool: return false
var is_target_valid_callable: Callable = func(target: Target, comparator: Trooper) -> bool: return false


var is_responsive_callable: Callable = func() -> bool: return true
func is_responsive() -> bool:
	return is_responsive_callable.call()


func is_target_prioritized(target: Target, comparator: Trooper) -> bool:
	return is_target_prioritized_callable.call(target, comparator)


func is_target_valid(target: Target) -> bool:
	return is_target_valid_callable.call(target)
