extends CanvasLayer

const TransitionScreen = preload("uid://uwjo6dcg7ekn")

@onready var transition_screen: TransitionScreen = $TransitionScreen

func _ready() -> void:
	visible = true


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reload_current_scene"):
		get_tree().reload_current_scene()
	
	if Input.is_action_pressed("fast_forward"):
		Engine.time_scale = 2.0
	else:
		Engine.time_scale = 1.0
