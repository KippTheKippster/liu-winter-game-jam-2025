extends Node
class_name Game

const CommandArea = preload("res://main scenes/game/command_area.gd")

const PENGUIN_SCENE = preload("res://entities/penguin/penguin.tscn")

static var current_level_path: StringName = "res://levels/level_001.tscn"
var penguin_list: Array[Penguin2]
var penguin_spawn_count: int = 3
var penguin_spawn_equipment_list: Array[CarryObjectTypeEquipment]

@onready var ui_layer: CanvasLayer = $UiLayer
@onready var raft_depart_menu: Control = %RaftDepartMenu
@onready var level_container: Node2D = $LevelContainer
@onready var pause_menu: Control = %PauseMenu
@onready var command_area: CommandArea = %CommandArea
@onready var player_camera: Camera2D = %PlayerCamera

@export var current_level: Level
@export var load_level_on_ready: bool = false
@export var spawn_penguins_on_level_ready: bool

func _ready() -> void:
	SignalBus.penguin_borned.connect(_on_penguin_borned)
	SignalBus.penguin_killed.connect(_on_penguin_killed)
	SignalBus.raft_departed.connect(_on_raft_departed)
	
	if load_level_on_ready:
		if current_level:
			current_level.queue_free()
		
		instantiate_level()
	else:
		current_level_path = current_level.scene_file_path
	
	prepare_level()
	
	
	ui_layer.visible = true
	pause_menu.visible = false
	#sub_viewport.world_2d = get_viewport().world_2d


#func _enter_tree() -> void:


#func _exit_tree() -> void:
#	SignalBus.raft_departed.disconnect(go_to_level)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not command_area.active:
		toggle_paused()


func toggle_paused() -> void:
	pause_menu.visible = !pause_menu.visible
	get_tree().paused = pause_menu.visible


func prepare_level() -> void:
	player_camera.global_position = current_level.start_position
	player_camera.camera_limit = current_level.camera_limit
	spawn_penguins()


func instantiate_level() -> void:
	var level_scene := ResourceLoader.load(current_level_path) as PackedScene
	current_level = level_scene.instantiate()
	level_container.add_child(current_level)



func go_to_level(file_path: String) -> void:
	GlobalUi.transition_screen.start("circle", false)
	GlobalUi.transition_screen.screen_covered.connect(func() -> void:
		if current_level:
			current_level_path = file_path
			current_level.get_parent().remove_child(current_level)
			current_level.queue_free()
		
		instantiate_level()
		prepare_level()
		#set_camera_limit(current_level.camera_limit)
		, ConnectFlags.CONNECT_ONE_SHOT)


func spawn_penguins() -> void:
	for i in penguin_spawn_count:
		var penguin := PENGUIN_SCENE.instantiate() as Penguin2
		level_container.add_child(penguin)
		penguin.global_position = current_level.start_position + Vector2.from_angle(2.0 * PI * (1.0 * i / penguin_spawn_count)) * 12.0
		if penguin_spawn_equipment_list.size() > 0:
			#penguin.equipment_type = penguin_spawn_equipment_list[0]
			penguin.equip.call_deferred(penguin_spawn_equipment_list[0])
			penguin_spawn_equipment_list.remove_at(0)


func _on_penguin_borned(penguin: Penguin2) -> void:
	penguin_list.append(penguin)


func _on_penguin_killed(penguin: Penguin2) -> void:
	penguin_list.erase(penguin)
	if penguin_list.is_empty():
		go_to_level(current_level_path)


func _on_raft_departed(boarded_penguin_list: Array[Penguin2]) -> void:
	print("raft_departed: ", boarded_penguin_list)
	penguin_spawn_count = boarded_penguin_list.size()
	penguin_spawn_equipment_list.clear()
	for penguin in boarded_penguin_list:
		if penguin.equipment_type:
			penguin_spawn_equipment_list.append(penguin.equipment_type)
	
	go_to_level(current_level.next_level_path)


func _on_raft_depart_menu_depart_accepted() -> void:
	go_to_level(current_level.next_level_path)


func _on_pause_menu_depart_request() -> void:
	go_to_level(current_level.next_level_path)
