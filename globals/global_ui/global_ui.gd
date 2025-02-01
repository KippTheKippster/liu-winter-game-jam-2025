extends CanvasLayer

const TransitionScreen = preload("uid://uwjo6dcg7ekn")

@onready var transition_screen: TransitionScreen = $TransitionScreen

func _ready() -> void:
	visible = true


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reload_current_scene"):
		get_tree().reload_current_scene()
