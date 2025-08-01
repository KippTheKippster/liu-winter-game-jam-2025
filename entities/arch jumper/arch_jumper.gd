extends Node2D

const ARCH_JUMPER_SCENE = preload("res://entities/arch jumper/arch_jumper.tscn")

signal landed

@onready var vertical_group: VerticalGroup = $VerticalGroup
@onready var sprite_2d: Sprite2D = $VerticalGroup/Sprite2D

var horizontal_velocity: Vector2


func _process(delta: float) -> void:
	if not vertical_group.is_on_floor():
		position += horizontal_velocity * delta


func jump_to_point(point: Vector2) -> void:
	vertical_group.jump()
	var time := 2.0 * (vertical_group.velocity / vertical_group.gravity)
	var dif := point - global_position
	horizontal_velocity = (dif / time) 
	Utils.call_delayed(self, time, func() -> void: landed.emit())
	#print(time)


func copy_carry_object_sprite(type: CarryObjectType) -> void:
	sprite_2d.texture = type.texture
	sprite_2d.offset = type.offset


static func spawn(spawner: Node2D, carry_object_type: CarryObjectType, start_point: Vector2, target_point: Vector2, on_landed_callable: Callable) -> Node2D:
	var arch_jumper := ARCH_JUMPER_SCENE.instantiate() as Node2D
	spawner.add_sibling(arch_jumper)
	arch_jumper.global_position = start_point
	arch_jumper.copy_carry_object_sprite(carry_object_type)
	arch_jumper.jump_to_point(target_point)
	arch_jumper.landed.connect(func() -> void:
		on_landed_callable.call(); arch_jumper.queue_free(), 
		ConnectFlags.CONNECT_ONE_SHOT)
	return arch_jumper
