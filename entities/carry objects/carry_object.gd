extends Carriable

@onready var vertical_group: VerticalGroup = $VerticalGroup

@onready var object_sprite: Sprite2D = %ObjectSprite

var velocity: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_sprite.call_deferred()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	enabled = vertical_group.is_on_floor()
	if not vertical_group.is_on_floor():
		position += velocity * delta


func _on_carry_object_type_changed() -> void:
	if is_node_ready():
		update_sprite.call_deferred()


func update_sprite() -> void:
	if carry_object_type:
		visible = true
		object_sprite.texture = carry_object_type.texture
		object_sprite.offset = carry_object_type.offset
	else:
		visible = false


func _on_placed(height: float, new_velocity: Vector2) -> void:
	velocity = new_velocity
	vertical_group.height = height
	vertical_group.jump()
