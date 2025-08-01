extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	animation_player.play("closed")


func open() -> void:
	if animation_player.current_animation == "closed":
		animation_player.play("opened")


func close() -> void:
	if animation_player.current_animation == "opened":
		animation_player.play("closed")
