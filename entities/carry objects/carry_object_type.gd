extends Resource
class_name CarryObjectType

@export_file("*.gd") var carry_object_type_instance_path: String
@export var eatable: bool = true
@export var penguin_interest: bool = true
@export var texture: Texture2D
@export var offset: Vector2

func apply(carriable: Carriable) -> void:
	if ResourceLoader.exists(carry_object_type_instance_path):
		var instance := (ResourceLoader.load(carry_object_type_instance_path) as GDScript).new() as CarryObjectTypeInstance
		carriable.add_child(instance)
		instance.applied.emit(carriable)
