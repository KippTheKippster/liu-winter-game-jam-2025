extends Node2D
class_name Carriable

signal placed(height: float)
signal enabled_changed
signal carry_object_type_changed

@export var enabled: bool:
	set(value):
		enabled = value
		enabled_changed.emit()


@export var carry_object_type: CarryObjectType = preload("uid://c4slt6xes3eqm"):
	set(value):
		carry_object_type = value
		carry_object_type_changed.emit()
		carry_object_type.apply(self)


var old_owner_parent: Node

func pickup() -> void:
	old_owner_parent = get_parent()
	old_owner_parent.remove_child(self)


func place(place_position: Vector2, height: float = 1.0, velocity: Vector2 = Vector2.ZERO, new_parent_override: Node = null) -> void:
	if new_parent_override:
		new_parent_override.add_child(self)
	else:
		old_owner_parent.add_child(self)
	
	global_position = place_position
	
	placed.emit(height, velocity)
