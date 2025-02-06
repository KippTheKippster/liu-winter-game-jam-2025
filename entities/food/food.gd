extends Node2D

@export var food_type: FoodType = preload("uid://c4slt6xes3eqm")

@onready var vertical: Vertical = $Vertical
@onready var carriable: Carriable = $Carriable

@onready var food_sprite: Sprite2D = $Vertical/FoodSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	food_sprite.texture = food_type.texture
	food_sprite.offset = food_type.offset
	
	carriable.carry_item_texture = food_type.texture
	carriable.carry_item_offset = food_type.offset


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	carriable.enabled = vertical.is_on_floor()


func _on_carriable_placed(height: float) -> void:
	vertical.height = height
	vertical.jump()
