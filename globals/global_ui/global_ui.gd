extends CanvasLayer

const TransitionScreen = preload("uid://uwjo6dcg7ekn")

@onready var transition_screen: TransitionScreen = $TransitionScreen

@onready var prev_window_mode := DisplayServer.window_get_mode()

func _ready() -> void:
	visible = true


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_fullscreen"):
		toggle_fullscreen()
	
	if Input.is_action_just_pressed("reload_current_scene"):
		get_tree().reload_current_scene()
	
	if Input.is_action_pressed("fast_forward"):
		Engine.time_scale = 2.0
	else:
		Engine.time_scale = 1.0


func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		prev_window_mode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		if prev_window_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			prev_window_mode = DisplayServer.WINDOW_MODE_WINDOWED
		
		DisplayServer.window_set_mode(prev_window_mode)
