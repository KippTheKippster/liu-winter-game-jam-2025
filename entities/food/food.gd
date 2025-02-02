extends Node2D

@onready var vertical: Vertical = $Vertical
@onready var carriable: Carriable = $Carriable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	carriable.enabled = vertical.is_on_floor()


func _on_carriable_placed(height: float) -> void:
	vertical.height = height
	vertical.jump()
