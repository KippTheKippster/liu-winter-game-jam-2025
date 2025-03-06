@tool
extends StaticBody2D

@onready var tree_sprite: Sprite2D = $TreeSprite

@export var randomize_on_ready: bool = true
@export_enum("No Snow", "Light Snow", "Full Snow") var type: int:
	set(value):
		type = value
		if is_node_ready():
			update_sprite()

@export_tool_button("Randomize Type") var randomize_type_callable: Callable = func() -> void:
	type = randi_range(0, 2)

func _ready() -> void:
	if not Engine.is_editor_hint():
		randomize_type_callable.call()
	
	update_sprite()


func update_sprite() -> void: 
	tree_sprite.frame = type
