extends CanvasLayer

const TransitionScreen = preload("uid://uwjo6dcg7ekn")

@onready var transition_screen: TransitionScreen = $TransitionScreen
@onready var prev_window_mode := DisplayServer.window_get_mode()

func _ready() -> void:
	visible = true


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_fullscreen"):
		toggle_fullscreen()


func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		if prev_window_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			prev_window_mode = DisplayServer.WINDOW_MODE_WINDOWED
		
		DisplayServer.window_set_mode(prev_window_mode)
	else:
		prev_window_mode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
