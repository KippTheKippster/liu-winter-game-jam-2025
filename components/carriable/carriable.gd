extends Node2D
class_name Carriable

@export var carry_item_texture: Texture2D
@export var carry_item_offset: Vector2  

var old_owner_parent: Node

func pickup() -> void:
	old_owner_parent = owner.get_parent()
	old_owner_parent.remove_child(owner)


func place(place_position: Vector2) -> void:
	if owner is Node2D:
		owner.global_position = place_position
	
	old_owner_parent.add_child(owner)
