extends CanvasLayer

@onready var penguin_sprite: AnimatedSprite2D = %PenguinSprite

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(penguin_sprite, "position", penguin_sprite.position + 66 * Vector2.RIGHT, 4.0)


func _on_timer_timeout() -> void:
	GlobalUi.transition_screen.change_scene_to_file("uid://doiwfgk1hy5nb", "mosaic")
