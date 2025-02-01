extends Node
class_name Game

static var current_level_path: StringName = "res://levels/level_001.tscn"
static var coin_count: int = 0

@onready var ui_layer: CanvasLayer = $UiLayer
@onready var level_container: Node2D = $LevelContainer
@onready var pause_menu: Control = %PauseMenu

static var penguins: Array[Penguin] = []

func _ready() -> void:
	penguins.clear()
	
	var level_scene := load(current_level_path) as PackedScene
	var level := level_scene.instantiate()
	level_container.add_child(level)
	
	ui_layer.visible = true
	pause_menu.visible = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_paused()
	
	if Input.is_action_just_pressed("action_1"):
		for penguin in penguins:
			penguin.walk_target = penguin.get_global_mouse_position()
			penguin.state_chart.send_event("task_travel_request")


func toggle_paused() -> void:
	pause_menu.visible = !pause_menu.visible
	get_tree().paused = pause_menu.visible
