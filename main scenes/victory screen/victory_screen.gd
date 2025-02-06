extends CanvasLayer

@onready var seal_sprite: AnimatedSprite2D = $SealSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	seal_sprite.rotation += 4.0 * delta


func _on_timer_timeout() -> void:
	GlobalUi.transition_screen.change_scene_to_file("res://main scenes/prologue/prologue.tscn", "mosaic")
