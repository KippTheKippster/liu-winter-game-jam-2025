@tool
extends Node2D

signal finished

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
@onready var target: Target = $Area2D/Target

@export var tile_amount: int:
	set(value):
		var max_amount := get_max_amount()
		tile_amount = clampi(value, 0, max_amount)
		if tile_amount == max_amount:
			finished.emit()
		
		update_tiles()

@export var start_amount: int = 3

@export var max_length: int = 6
@export var max_height: int = 3

@export var bridge_tile_texture: Texture2D

func _ready() -> void:
	collision_shape_2d.shape.duplicate()
	if not Engine.is_editor_hint():
		tile_amount = start_amount
	else:
		tile_amount = get_max_amount()


func update_tiles() -> void:
	if bridge_tile_texture == null or not is_node_ready():
		return
	
	tile_map_layer.clear()
	
	var rectangle_shape := collision_shape_2d.shape as RectangleShape2D
	rectangle_shape.size = Vector2(get_bridge_width(), get_bridge_height())
	collision_shape_2d.position.x = rectangle_shape.size.x / 2.0
	
	#var w = bridge_tile_texture.get_width()
	var h := bridge_tile_texture.get_height()
	tile_map_layer.position =  Vector2(0, -float(max_height) / 2 * h)
	for i in tile_amount:
		var y := i % max_height
		@warning_ignore("integer_division")
		var x := i / max_height
		tile_map_layer.set_cell(Vector2i(x, y), 0, Vector2.ZERO)
		#draw_texture(bridge_tile_texture, Vector2(x * w, y * h) + offset)


func get_tiles_width() -> int:
	@warning_ignore("integer_division")
	return tile_amount / max_height


func get_tiles_height() -> int:
	return max_height


func get_bridge_width() -> float:
	return get_tiles_width() * 8.0


func get_bridge_height() -> float:
	return get_tiles_height() * 8.0


func get_max_amount() -> int:
	return max_length * max_height
