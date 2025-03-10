extends Area2D

@export var circle_radius_large: float = 12.0
@export var circle_radius_small: float = 4.0

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
var circle_shape: CircleShape2D

var active: bool
var radius: float = 16.0

var target_list: Array[Target]
var penguin_list: Array[Penguin]
var trooper_list: Array[Trooper]

@onready var circle_sub_viewport: SubViewport = %CircleSubViewport
@onready var circle_draw_node: Node2D = %CircleDrawNode
@onready var circle_sprite: Sprite2D = %CircleSprite

func _ready() -> void:
	circle_shape = collision_shape_2d.shape
	circle_sub_viewport.size = Vector2.ONE * circle_radius_large * 2 + Vector2.ONE
	circle_draw_node.draw.connect(func():
		if active:
			circle_draw_node.draw_circle(Vector2.ZERO, radius, Color.CRIMSON, false, 1.0)
		)


func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	
	if Input.is_action_just_pressed("action_1"):
		active = true
		radius = 12.0
		circle_shape.radius = radius - 1
		queue_redraw()
	elif Input.is_action_just_pressed("action_2"):
		active = true
		radius = 4.0
		circle_shape.radius = radius - 1
		queue_redraw()
	
	
	if Input.is_action_just_pressed("release_command"):
		release_command()
		queue_redraw()
	
	
	if Input.is_action_just_released("action_1") or Input.is_action_just_released("action_2"):
		if not Input.is_action_pressed("action_1") and not Input.is_action_pressed("action_2"):
			if active:
				apply_command()
				queue_redraw()
		else:
			if Input.is_action_pressed("action_1"):
				active = true
				radius = 12.0
				circle_shape.radius = radius - 1
				queue_redraw()
			elif Input.is_action_pressed("action_2"):
				active = true
				radius = 4.0
				circle_shape.radius = radius - 1
				queue_redraw()
	
	collision_shape_2d.disabled = !active
	
	if active:
		update_lists()


func _draw() -> void:
	circle_draw_node.queue_redraw()


func update_lists() -> void:
	target_list.clear()
	#penguin_list.clear()
	
	for area in get_overlapping_areas():
		var trooper := Utils.find_child_of_class(area, "Trooper") as Trooper
		if trooper and trooper.is_responsive() and not trooper_list.has(trooper):
			trooper.selected = true
			trooper_list.append(trooper)
		
		var target := Utils.find_child_of_class(area, "Target") as Target
		if target:
			target_list.append(target)


func release_command() -> void:
	for trooper in trooper_list:
		if is_instance_valid(trooper):
			trooper.selected = false
	
	trooper_list.clear()
	penguin_list.clear()
	active = false



func sort_closest(a: Target, b: Target, point: Vector2) -> bool:
	if a.priority != b.priority:
		return a.priority > b.priority
	
	return a.global_position.distance_squared_to(point) < b.global_position.distance_squared_to(point)


func apply_command() -> void:
	target_list.sort_custom(sort_closest.bind(global_position))
	
	for target in target_list:
		if trooper_list.is_empty():
			release_command()
			return
		
		for i in trooper_list.size():
			var change_occured := false
			for j in trooper_list.size() - i - 1:
				var left := trooper_list[j]
				var right := trooper_list[j + 1]
				if right.is_target_prioritized(target, left):
					trooper_list[j] = right
					trooper_list[j + 1] = left
					change_occured = true
			
			if not change_occured:
				break
		
		for i in trooper_list.size():
			var trooper := trooper_list[0]
			trooper_list.remove_at(0)
			if is_instance_valid(trooper) and trooper.responsive:
				trooper.command_applied.emit(global_position, target)
				trooper.selected = false
				if target.singular:
					break
	
	for trooper in trooper_list:
		if is_instance_valid(trooper) and trooper.responsive:
			trooper.command_applied.emit(global_position, null)
			trooper.selected = false
	
	release_command()
