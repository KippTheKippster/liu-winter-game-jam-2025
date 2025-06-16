@tool
extends CanvasModulate

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var duration: float = 5.0
@export_range(0.0, 1.0, 0.001) var time: float = 0.0:
	set(value):
		time = value
		update_color()

@export var color_range: Gradient


func _ready() -> void:
	if not Engine.is_editor_hint():
		start()

func start() -> void:
	#var tween := create_tween()
	#tween.tween_method(update_color, 0.0, 1.0, duration)
	#time = 0.0
	#tween.tween_property(self, "time", 1.0, duration)
	animation_player.speed_scale = 1.0 / duration
	animation_player.play("progress")


func update_color() -> void:
	color = color_range.sample(time)
