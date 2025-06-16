extends Node
class_name Game

const CommandArea = preload("uid://baptqcm2qgns6")
const PauseMenu = preload("uid://bd3kurkl5qw2t")
const Raft = preload("uid://dw4yqocvldxan")
const SpecialSpawnMarker = preload("uid://bqfx88n80nadn")

const PENGUIN_SCENE = preload("uid://c7hpad4xy14l2")

static var current_level_path: StringName = "uid://cti12nwlj0c2n"
static var penguin_raft_count: int = 3
static var penguin_raft_equipment_list: Array[CarryObjectTypeEquipment]
static var penguin_hub_count: int = 3
static var penguin_hub_equipment_list: Array[CarryObjectTypeEquipment]
var penguin_list: Array[Penguin]

var current_raft: Raft

@onready var ui_layer: CanvasLayer = $UiLayer
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var raft_depart_menu: Control = %RaftDepartMenu
@onready var level_container: Node2D = $LevelContainer
@onready var player_camera: Camera2D = %PlayerCamera
@onready var command_area: CommandArea = %CommandArea
@onready var flow_field_manager: FlowFieldManager = %FlowFieldManager

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
	elif current_level:
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
	flow_field_manager.cells_rect = Rect2i(
		current_level.camera_limit.position / flow_field_manager.cell_size,
		current_level.camera_limit.size / flow_field_manager.cell_size)
	flow_field_manager.reset_cells()
	
	for raft: Raft in get_tree().get_nodes_in_group("raft"):
		raft.penguin_boarded.connect(_on_raft_penguin_boarded.bind(raft))
		raft.departed.connect(_on_raft_departed.bind(raft))
		raft.left.connect(_on_raft_left.bind(raft))
	
	#if current_level.hub:
	#	penguin_raft_count += penguin_hub_count
	#	penguin_raft_equipment_list.append_array(penguin_hub_equipment_list)
	
	#spawn_penguins(penguin_raft_count, , penguin_raft_equipment_list)
	spawn_penguins()
	
	penguin_raft_count = 0
	penguin_raft_equipment_list.clear()


func instantiate_level() -> void:
	var level_scene := ResourceLoader.load(current_level_path) as PackedScene
	current_level = level_scene.instantiate()
	level_container.add_child(current_level)


func go_to_level(file_path: String) -> void:
	GlobalUi.transition_screen.start("circle", false)
	GlobalUi.transition_screen.screen_covered.connect(func() -> void:
		if current_level:
			current_level.get_parent().remove_child(current_level)
			current_level.queue_free()
		
		current_level_path = file_path
		get_tree().paused = true
		get_tree().change_scene_to_file("uid://c2ykvkkivub6e")
		#instantiate_level()
		#prepare_level()
		, ConnectFlags.CONNECT_ONE_SHOT)


func create_penguin(equipment_list: Array[CarryObjectTypeEquipment]) -> Penguin:
	var penguin := PENGUIN_SCENE.instantiate() as Penguin
	level_container.add_child(penguin)
	if equipment_list.size() > 0:
		penguin.equip.call_deferred(equipment_list.pop_front())
	
	return penguin


func spawn_penguins() -> void:
	if current_level.hub:
		var special_start_markers := current_level.special_start_markers.get_children()
		special_start_markers.shuffle()
		var amount = penguin_hub_count
		var special_amount = clamp(penguin_hub_count, 0, special_start_markers.size())
		for i in special_amount:
			var special_start_maker := special_start_markers[i] as SpecialSpawnMarker
			var penguin := create_penguin(penguin_hub_equipment_list)
			penguin.global_position = special_start_maker.global_position
			penguin.flip_group.flip_towards(Vector2(special_start_maker.direction, 0))
			if special_start_maker.action == SpecialSpawnMarker.Action.SLEEPING:
				penguin.state_chart.send_event.call_deferred("request_action_idle_sleep")
			
			amount -= 1
		
		for i in amount:
			var penguin := create_penguin(penguin_hub_equipment_list)
			penguin.global_position = current_level.start_position
	
	for i in penguin_raft_count:
		var penguin := create_penguin(penguin_raft_equipment_list)
		penguin.global_position = current_level.start_position + Vector2.from_angle(2.0 * PI * (1.0 * i / penguin_raft_count)) * 12.0


func store_penguins(penguins: Array, out_equipment_list: Array[CarryObjectTypeEquipment]) -> int:
	var count = penguins.size()
	for penguin: Penguin in penguins:
		if is_instance_valid(penguin) and penguin.equipment_type:
			out_equipment_list.append(penguin.equipment_type)
	
	return count


func _on_penguin_borned(penguin: Penguin) -> void:
	penguin_list.append(penguin)


func _on_penguin_killed(penguin: Penguin) -> void:
	penguin_list.erase(penguin)
	if penguin_list.is_empty():
		go_to_level(current_level_path)


func _on_raft_penguin_boarded(penguin: Penguin, raft: Raft) -> void:
	if not raft.departing:
		current_raft = raft
		pause_menu.allow_depart = true


func _on_raft_departed(raft: Raft) -> void:
	pause_menu.allow_depart = false
	command_area.enabled = false
	current_raft = raft


func _on_raft_left(raft: Raft) -> void:
	penguin_raft_equipment_list.clear()
	penguin_raft_count = store_penguins(raft.penguin_list, penguin_raft_equipment_list)
	
	if current_level.hub:
		penguin_hub_equipment_list.clear()
		penguin_hub_count = store_penguins(get_tree().get_nodes_in_group("penguin"), penguin_hub_equipment_list)
	
	go_to_level(raft.next_level_path)


func _on_raft_depart_menu_depart_accepted() -> void:
	go_to_level(current_level.next_level_path)


func _on_pause_menu_continue_requested() -> void:
	toggle_paused()


func _on_pause_menu_depart_requested() -> void:
	if current_raft and current_raft.fuelled:
		set_paused(false)
		current_raft.depart()


func _on_pause_menu_quit_requested() -> void:
	GlobalUi.transition_screen.change_scene_to_file("uid://c2ykvkkivub6e")
