extends Resource
class_name CarryObjectType

@export_file("*.gd") var carry_object_type_instance_path: String
@export_file var carriable_scene_path: String = "uid://dwxtrccdrpoyl"
@export var edible: bool = true
@export var penguin_interest: bool = true
@export_flags("Penguin", "Food", "Danger", "Penguin Carriable") var layer: int = 8
@export_group("Sprite")
@export var texture: Texture2D
@export var offset: Vector2
@export_group("Audio")
@export var pickup_audio: AudioStream
@export var place_audio: AudioStream

func apply(carriable: Carriable) -> void:
	if ResourceLoader.exists(carry_object_type_instance_path):
		var instance := (ResourceLoader.load(carry_object_type_instance_path) as GDScript).new() as CarryObjectTypeInstance
		carriable.add_child(instance)
		instance.applied.emit(carriable)


func spawn(parent: Node, point: Vector2) -> Carriable:
	var carry_object := load(carriable_scene_path).instantiate() as Carriable
	carry_object.carry_object_type = self
	parent.add_child(carry_object)
	#carry_object.place(point, 1.0, Vector2.ZERO, parent)
	return carry_object


func apply_to_sprite(sprite: Sprite2D) -> void:
	sprite.texture = texture
	sprite.offset = offset


func is_food() -> bool:
	return Utils.get_bitmask_layer_value(layer, 1)
