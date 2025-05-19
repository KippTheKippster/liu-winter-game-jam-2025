extends Node
class_name Game

const CommandArea = preload("uid://baptqcm2qgns6")
const PauseMenu = preload("uid://bd3kurkl5qw2t")
const Raft = preload("uid://dw4yqocvldxan")

const PENGUIN_SCENE = preload("uid://c7hpad4xy14l2")

static var current_level_path: StringName = "uid://pgubkf04gmmt"
var penguin_list: Array[Penguin]
var penguin_spawn_count: int = 3
var penguin_spawn_equipment_list: Array[CarryObjectTypeEquipment]

@onready var ui_layer: CanvasLayer = $UiLayer
@onready var raft_depart_menu: Control = %RaftDepartMenu
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var level_container: Node2D = $LevelContainer
@onready var command_area: CommandArea = %CommandArea
@onready var player_camera: Camera2D = %PlayerCamera

@export var current_level: Level
@export var load_level_on_ready: bool = false
@export var spawn_penguins_on_level_ready: bool

func _ready() -> void:
	SignalBus.penguin_borned.connect(_on_penguin_borned)
	SignalBus.penguin_killed.connect(_on_penguin_killed)
	
	if load_level_on_ready:
		if current_level:
			current_level.queue_free()
		
		instantiate_level()
	else:
		current_level_path = current_level.scene_file_path
	
	prepare_level()
	
	ui_layer.visible = true
	pause_menu.visible = false
	pause_menu.allow_depart = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not command_area.active:
		toggle_paused()


func toggle_paused() -> void:
	set_paused(!pause_menu.visible)


func set_paused(paused: bool) -> void:
	pause_menu.visible = paused
	get_tree().paused = paused


func prepare_level() -> void:
	player_camera.global_position = current_level.start_position
	player_camera.camera_limit = current_level.camera_limit
	if current_level.raft:
		current_level.raft.penguin_boarded.connect(_on_raft_penguin_boarded.bind(current_level.raft))
		current_level.raft.departed.connect(_on_raft_departed.bind(current_level.raft))
		current_level.raft.left.connect(_on_raft_left.bind(current_level.raft))
	
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
		var penguin := PENGUIN_SCENE.instantiate() as Penguin
		level_container.add_child(penguin)
		penguin.global_position = current_level.start_position + Vector2.from_angle(2.0 * PI * (1.0 * i / penguin_spawn_count)) * 12.0
		if penguin_spawn_equipment_list.size() > 0:
			#penguin.equipment_type = penguin_spawn_equipment_list[0]
			penguin.equip.call_deferred(penguin_spawn_equipment_list[0])
			penguin_spawn_equipment_list.remove_at(0)


func _on_penguin_borned(penguin: Penguin) -> void:
	penguin_list.append(penguin)


func _on_penguin_killed(penguin: Penguin) -> void:
	penguin_list.erase(penguin)
	if penguin_list.is_empty():
		go_to_level(current_level_path)


func _on_raft_penguin_boarded(penguin: Penguin, raft: Raft) -> void:
	if not raft.departing:
		pause_menu.allow_depart = true


func _on_raft_departed(raft: Raft) -> void:
	pause_menu.allow_depart = false


func _on_raft_left(raft: Raft) -> void:
	penguin_spawn_count = raft.penguin_list.size()
	penguin_spawn_equipment_list.clear()
	for penguin in raft.penguin_list:
		if penguin.equipment_type:
			penguin_spawn_equipment_list.append(penguin.equipment_type)
	
	go_to_level(current_level.next_level_path)



func _on_raft_depart_menu_depart_accepted() -> void:
	go_to_level(current_level.next_level_path)


func _on_pause_menu_continue_requested() -> void:
	toggle_paused()


func _on_pause_menu_depart_requested() -> void:
	if current_level.raft and current_level.raft.fuelled:
		set_paused(false)
		current_level.raft.depart()


func _on_pause_menu_quit_requested() -> void:
	GlobalUi.transition_screen.change_scene_to_file("uid://c2ykvkkivub6e")
