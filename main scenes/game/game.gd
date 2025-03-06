extends Node
class_name Game

const CommandArea = preload("res://main scenes/game/command_area.gd")

static var current_level_path: StringName = "res://levels/level_001.tscn"
static var coin_count: int = 0

@onready var ui_layer: CanvasLayer = $UiLayer
@onready var raft_depart_menu: Control = %RaftDepartMenu
@onready var level_container: Node2D = $Level
@onready var pause_menu: Control = %PauseMenu
@onready var command_area: CommandArea = $Level/CommandArea

@export var load_level_on_ready: bool = false

func _ready() -> void:
	if load_level_on_ready:
		var level_scene := load(current_level_path) as PackedScene
		var level := level_scene.instantiate()
		level_container.add_child(level)
	
	ui_layer.visible = true
	pause_menu.visible = false
	#sub_viewport.world_2d = get_viewport().world_2d


func _enter_tree() -> void:
	SignalBus.raft_penguin_entered.connect(check_depart_menu)


func _exit_tree() -> void:
	SignalBus.raft_penguin_entered.disconnect(check_depart_menu)


func check_depart_menu(penguins: Array[Penguin]) -> void:
	if penguins.size() == get_tree().get_node_count_in_group("penguin"):
			raft_depart_menu.visible = true


func _process(delta: float) -> void:
	if get_tree().get_node_count_in_group("penguin") == 0:
		GlobalUi.transition_screen.change_scene_to_file("res://main scenes/game/game.tscn", "circle")
	
	if Input.is_action_just_pressed("pause") and not command_area.active:
		toggle_paused()


func toggle_paused() -> void:
	pause_menu.visible = !pause_menu.visible
	get_tree().paused = pause_menu.visible


func _on_raft_depart_menu_depart_accepted() -> void:
	GlobalUi.transition_screen.change_scene_to_file("uid://c2ykvkkivub6e", "circle")
