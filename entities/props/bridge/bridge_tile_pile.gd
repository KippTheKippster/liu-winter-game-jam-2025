@icon("uid://bub2rt3kyvgh1")
extends Node2D

const Bridge = preload("uid://bftktmcermlew")

const TOOL_BRIDGE_TILE = preload("uid://bnyh58x0lgqdx")

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var target: Target = $Area2D/Target

@export var bridge: Bridge

var tiles: Array[Carriable]

var tiles_left: int

func _ready() -> void:
	sprite_2d.visible = false
	if bridge:
		create_tiles.call_deferred()


func create_tiles() -> void:
	var amount := bridge.get_max_amount() - bridge.tile_amount
	tiles.resize(amount)
	tiles_left = amount
	for i in amount:
		var tile := TOOL_BRIDGE_TILE.spawn(self, global_position + Vector2.from_angle(TAU * randf()) * randi_range(0.0, 4.0)) as Carriable
		tile.target.active = false
		tiles[i] = tile


func take_tile() -> Carriable:
	var tile := tiles[tiles_left - 1]
	tiles_left -= 1
	#remove_child(tile)
	tile.pickup()
	tile.target.active = true
	if is_empty():
		target.active = false
	
	return tile


func is_empty() -> bool:
	return tiles_left <= 0
