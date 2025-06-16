extends Control

@onready var spawn_item_button: Button = %SpawnItemButton
@onready var show_items_button: Button = %ShowItemsButton
@onready var spawn_enemy_button: Button = %SpawnEnemyButton
@onready var show_enemies_button: Button = %ShowEnemiesButton
@onready var item_container: GridContainer = %ItemContainer
@onready var enemy_container: GridContainer = %EnemyContainer
@onready var fps_label: Label = %FpsLabel
@onready var speed_label: Label = %SpeedLabel
@onready var penguin_label: Label = %PenguinLabel

@export var items: Array[CarryObjectType]
@export var enemies: Dictionary[PackedScene, Texture2D]

var current_item: CarryObjectType
var current_enemy: PackedScene

const PENGUIN_SCENE = preload("uid://c7hpad4xy14l2")
const CARRY_OBJECT_SCENE = preload("uid://dwxtrccdrpoyl")
const EQUIPMENT_POOL_RING = preload("uid://3756488067p0")

func _ready() -> void:
	for type in items:
		var button := Button.new()
		button.icon = type.texture
		button.expand_icon = true
		button.custom_minimum_size = type.texture.get_size() * 3
		button.pressed.connect(select_item.bind(type))
		item_container.add_child(button)
	
	for scene in enemies.keys():
		var button := Button.new()
		button.icon = enemies[scene]
		button.expand_icon = true
		button.custom_minimum_size = enemies[scene].get_size() * 1
		button.pressed.connect(select_enemy.bind(scene))
		enemy_container.add_child(button)
	
	show_items_button.button_pressed = item_container.visible
	select_item(items[0])
	
	show_enemies_button.button_pressed = enemy_container.visible
	select_enemy(enemies.keys()[0])


func _process(delta: float) -> void:
	visible = Debug.enabled
	if not Debug.enabled:
		return
	
	fps_label.text = str(Engine.get_frames_per_second())
	speed_label.text = str(Engine.time_scale)
	penguin_label.text = str(get_tree().get_node_count_in_group("penguin"))
	
	if Input.is_action_just_pressed("debug_spawn_penguin"):
		var current_scene := get_tree().current_scene
		if current_scene is Game:
			spawn_penguin(current_scene.level_container, current_scene.level_container.get_global_mouse_position())
	elif Input.is_action_just_pressed("debug_spawn_item"):
		var current_scene := get_tree().current_scene
		if current_scene is Game:
			spawn_item(current_item, current_scene.level_container, current_scene.level_container.get_global_mouse_position())
	elif Input.is_action_just_pressed("debug_spawn_enemy"):
		var current_scene := get_tree().current_scene
		if current_scene is Game:
			spawn_enemy(current_enemy, current_scene.level_container, current_scene.level_container.get_global_mouse_position())


func spawn_penguin(parent: Node, point: Vector2 = Vector2.ZERO) -> Penguin:
	var penguin := PENGUIN_SCENE.instantiate() as Penguin
	penguin.global_position = point
	penguin.position += Vector2.from_angle(randf() * TAU)
	parent.add_child(penguin)
	return penguin


func select_item(type: CarryObjectType) -> void:
	spawn_item_button.icon = type.texture
	current_item = type


func spawn_item(type: CarryObjectType, parent: Node, point: Vector2 = Vector2.ZERO) -> Carriable:
	var carry_object := ResourceLoader.load(type.carriable_scene_path).instantiate() as Carriable
	carry_object.global_position = point
	carry_object.carry_object_type = type
	parent.add_child(carry_object)
	return carry_object


func select_enemy(enemy_scene: PackedScene) -> void:
	spawn_enemy_button.icon = enemies[enemy_scene]
	current_enemy = enemy_scene


func spawn_enemy(enemy_scene: PackedScene, parent: Node, point: Vector2 = Vector2.ZERO) -> Node2D:
	var enemy = enemy_scene.instantiate() as Node2D
	parent.add_child(enemy)
	enemy.global_position = point
	return enemy


func _on_finish_level_button_pressed() -> void:
	if get_tree().current_scene is Game:
		var game := get_tree().current_scene as Game
		if game.current_level:
			game.current_level_path = game.current_level.next_level_path
			game.penguin_raft_count = 0
			game.penguin_raft_equipment_list.clear()
			if game.current_level.hub:
				game.penguin_hub_count = 0
				game.penguin_hub_equipment_list.clear()
			
			for node in get_tree().get_nodes_in_group("penguin"):
				if node is Penguin:
					game.penguin_raft_count += 1
					if node.equipment_type:
						game.penguin_raft_equipment_list.push_back(node.equipment_type)
			
			get_tree().reload_current_scene()


func _on_spawn_penguin_button_pressed() -> void:
	var current_scene := get_tree().current_scene
	if current_scene is Game:
		spawn_penguin(current_scene.level_container)


func _on_spawn_equipment_button_pressed() -> void:
	var current_scene := get_tree().current_scene
	if current_scene is Game:
		spawn_item(current_item, current_scene.level_container)


func _on_show_items_button_toggled(toggled_on: bool) -> void:
	item_container.visible = toggled_on
	if toggled_on:
		show_items_button.text = "<"
	else:
		show_items_button.text = ">"


func _on_spawn_enemy_button_pressed() -> void:
	var current_scene := get_tree().current_scene
	if current_scene is Game:
		spawn_enemy(current_enemy, current_scene.level_container)


func _on_show_enemies_button_toggled(toggled_on: bool) -> void:
	enemy_container.visible = toggled_on
	if toggled_on:
		show_enemies_button.text = "<"
	else:
		show_enemies_button.text = ">"
