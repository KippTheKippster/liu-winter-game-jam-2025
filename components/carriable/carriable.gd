extends Node2D
class_name Carriable

signal placed(height: float)

@export var enabled: bool
@export var carry_item_texture: Texture2D
@export var carry_item_offset: Vector2  

var old_owner_parent: Node

func pickup() -> void:
	old_owner_parent = owner.get_parent()
	old_owner_parent.remove_child(owner)


func place(place_position: Vector2, height: float = 0.0, new_parent_override: Node = null) -> void:
	if owner is Node2D:
		owner.global_position = place_position
	
	if new_parent_override:
		new_parent_override.add_child(owner)
	else:
		old_owner_parent.add_child(owner)
	print(old_owner_parent.get_path())
	placed.emit(height)
