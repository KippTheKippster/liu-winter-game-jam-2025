extends Area2D

var COMMAND_POSITION_OFFSETS: Array[Vector2]

@export var enabled: bool = true:
	set(value):
		enabled = value
		set_process(enabled)
		if not enabled:
			active = false
			queue_redraw()
			release_command()

@export var circle_radius_large: float = 12.0
@export var circle_radius_medium: float = 8.0
@export var circle_radius_small: float = 4.0

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var circle_sub_viewport: SubViewport = %CircleSubViewport
@onready var circle_draw_node: Node2D = %CircleDrawNode
@onready var circle_sprite: Sprite2D = %CircleSprite

var circle_shape: CircleShape2D

var active: bool
var radius: float = 16.0

var target_list: Array[Target]
var trooper_list: Array[Trooper]


func _ready() -> void:
	COMMAND_POSITION_OFFSETS.resize(140)
	
	var point_amounts: Array[int] = [1, 6, 12]
	var index := 0
	for i in point_amounts.size():
		var amount := point_amounts[i]
		for j in amount:
			COMMAND_POSITION_OFFSETS[index] = i * 8.0 * Vector2.from_angle(TAU * ((float(j)) / float(amount)))
			print(COMMAND_POSITION_OFFSETS[index], ": ", COMMAND_POSITION_OFFSETS[index].length())
			index += 1
	
	circle_shape = collision_shape_2d.shape
	circle_sub_viewport.size = Vector2.ONE * circle_radius_large * 2 + Vector2.ONE
	circle_draw_node.draw.connect(func() -> void:
		if active:
			circle_draw_node.draw_circle(Vector2.ZERO, radius, Color.CRIMSON, false, 1.0)
		)


func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	
	var action_1_pressed := Input.is_action_pressed("action_1")
	var action_2_pressed := Input.is_action_pressed("action_2")
	
	if action_1_pressed and not action_2_pressed:
		active = true
		radius = circle_radius_large
		circle_shape.radius = radius - 1
		queue_redraw()
	elif action_2_pressed and not action_1_pressed:
		active = true
		radius = circle_radius_small
		circle_shape.radius = radius - 1
		queue_redraw()
	elif action_1_pressed and action_2_pressed:
		active = true
		radius = circle_radius_medium
		circle_shape.radius = radius - 1
		queue_redraw()
	
	#if action_1_pressed and action_2_pressed:
	#	active = true
	#	radius = circle_radius_small
	#	circle_shape.radius = radius - 1
	#	queue_redraw()
	
	
	if Input.is_action_just_pressed("release_command"):
		release_command()
		queue_redraw()
	
	
	if Input.is_action_just_released("action_1") or Input.is_action_just_released("action_2"):
		if not Input.is_action_pressed("action_1") and not Input.is_action_pressed("action_2"):
			if active:
				apply_command()
				queue_redraw()
		#else:
		#	if Input.is_action_pressed("action_1"):
		#		active = true
		#		radius = 12.0
		#		circle_shape.radius = radius - 1
		#		queue_redraw()
		#	elif Input.is_action_pressed("action_2"):
		#		active = true
		#		radius = 4.0
		#		circle_shape.radius = radius - 1
		#		queue_redraw()
	
	collision_shape_2d.disabled = !active
	
	if active:
		update_lists()
	
	for target in target_list:
		for trooper in trooper_list:
			if is_instance_valid(trooper) and trooper.is_target_valid(target):
				target.highlight = true
				break
			else:
				target.highlight = false


func _draw() -> void:
	circle_draw_node.queue_redraw()


func update_lists() -> void:
	for target in target_list:
		if is_instance_valid(target):
			target.highlight = false
	
	target_list.clear()
	
	for area in get_overlapping_areas():
		var trooper := Utils.find_child_of_class(area, "Trooper") as Trooper
		if trooper and trooper.is_responsive() and not trooper_list.has(trooper):
			trooper.listening = true
			trooper_list.append(trooper)
		
		var target := Utils.find_child_of_class(area, "Target") as Target
		if target and target.active and target.layer & 1 == 0:
			#target.highlight = true
			target_list.append(target)
	
	target_list.sort_custom(sort_closest.bind(global_position))
	for i in min(trooper_list.size(), target_list.size()):
		#target_list[i].highlight = true
		if not target_list[i].singular:
			return


func release_command() -> void:
	for trooper in trooper_list:
		if is_instance_valid(trooper):
			trooper.listening = false
	
	for target in target_list:
		if is_instance_valid(target):
			target.highlight = false
	
	trooper_list.clear()
	active = false



func sort_closest(a: Target, b: Target, point: Vector2) -> bool:
	if a.priority != b.priority:
		return a.priority > b.priority
	
	return a.global_position.distance_squared_to(point) < b.global_position.distance_squared_to(point)


func get_command_position(count: int) -> Vector2:
	return global_position + COMMAND_POSITION_OFFSETS[count]
	var log_4 := log(count) / log(4)
	var radius_index := ceili(log_4)
	var angle := TAU * fmod(log_4, 4) 
	return global_position + Vector2.from_angle(angle) * 8.0 * radius_index


func apply_command() -> void:
	#target_list.sort_custom(sort_closest.bind(global_position))
	#for trooper in trooper_list:
	#	if not is_instance_valid(trooper):
	#		trooper_list.erase(trooper)
	var count := 0
	for target in target_list:
		if trooper_list.is_empty():
			release_command()
			return
		
		for i in trooper_list.size():
			var change_occured := false
			for j in trooper_list.size() - i - 1:
				var left := trooper_list[j]
				var right := trooper_list[j + 1]
				if is_instance_valid(left) and is_instance_valid(right):
					if right.is_target_prioritized(target, left):
						trooper_list[j] = right
						trooper_list[j + 1] = left
						change_occured = true
			
			if not change_occured:
				break
		
		for i in trooper_list.size():
			var trooper := trooper_list[0]
			trooper_list.remove_at(0)
			if  is_instance_valid(trooper) and trooper.responsive:
				trooper.command_applied.emit(global_position, COMMAND_POSITION_OFFSETS[count], target)
				trooper.listening = false
				count += 1
				if target.singular:
					break
	
	for trooper in trooper_list:
		if is_instance_valid(trooper) and trooper.responsive:
			trooper.command_applied.emit(global_position, COMMAND_POSITION_OFFSETS[count], null)
			trooper.listening = false
			count += 1
	
	release_command()
