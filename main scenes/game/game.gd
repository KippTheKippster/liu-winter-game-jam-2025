extends Node
class_name Game

const CommandArea = preload("res://main scenes/game/command_area.gd")

static var current_level_path: StringName = "res://levels/level_001.tscn"
static var coin_count: int = 0

@onready var ui_layer: CanvasLayer = $UiLayer
@onready var level_container: Node2D = $Level
@onready var pause_menu: Control = %PauseMenu
@onready var command_area: CommandArea = $Level/CommandArea

static var flow_field: FlowField

func _ready() -> void:
	#var level_scene := load(current_level_path) as PackedScene
	#var level := level_scene.instantiate()
	#level_container.add_child(level)
	
	ui_layer.visible = true
	pause_menu.visible = false
	flow_field = %FlowField


func _process(delta: float) -> void:
	if get_tree().get_node_count_in_group("penguin") == 0:
		GlobalUi.transition_screen.change_scene_to_file("res://main scenes/game/game.tscn", "circle")
	
	if Input.is_action_just_pressed("pause") and not command_area.active:
		toggle_paused()


func toggle_paused() -> void:
	pause_menu.visible = !pause_menu.visible
	get_tree().paused = pause_menu.visible
