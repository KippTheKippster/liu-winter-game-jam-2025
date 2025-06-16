extends Node2D
class_name Trooper

signal command_applied(point: Vector2, point_offset: Vector2, target: Target)
signal selected

const SURPRISE_EFFECT_SCENE := preload("uid://bkhahnu4sqbsx")

@export var responsive: bool = true:
	set(value):
		responsive = value
		if not responsive:
			listening = false

var surprise_effect: Node2D

var listening: bool:
	set(value):
		listening = value
		if value:
			surprise_effect = SURPRISE_EFFECT_SCENE.instantiate()
			add_child(surprise_effect)
			selected.emit()
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
