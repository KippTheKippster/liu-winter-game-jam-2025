extends Area2D

@export var circle_radius_large: float = 12.0
@export var circle_radius_small: float = 4.0

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
var circle_shape: CircleShape2D

var active: bool
var radius: float = 16.0

var target_list: Array[Creature]
var penguin_list: Array[Penguin]

var surprise_effect_list: Array[Node2D]

const SURPRISE_EFFECT_SCENE = preload("res://entities/effects/surprise/surprise_effect.tscn")
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
		var creature := Utils.find_child_of_class(area, "Creature")
		if creature:
			if creature.owner is Penguin:
				var penguin := creature.owner as Penguin
				if not penguin_list.has(penguin):
					penguin_list.append(penguin)
					play_surprise_effect(penguin)
					penguin.command_area_entered.emit(self)
			else:
				target_list.append(creature)


func play_surprise_effect(penguin: Penguin) -> void:
	var effect := SURPRISE_EFFECT_SCENE.instantiate() as Node2D
	surprise_effect_list.append(effect)
	effect.position = Vector2(0.0, -8.0)
	penguin.add_child(effect)


func release_command() -> void:
	for effect in surprise_effect_list:
		if is_instance_valid(effect):
			effect.queue_free()
	
	penguin_list.clear()
	active = false


func apply_command() -> void:
	print("Applying to: ", penguin_list.size())
	if target_list.is_empty():
		for penguin in penguin_list:
			if is_instance_valid(penguin):
				penguin.flow_field_walker.target_point = get_global_mouse_position()
				#penguin.walk_target = penguin.get_global_mouse_position()
				#flow_field.set_target_coords(flow_field.point_to_coords(get_global_mouse_position()))
				#penguin.action_target = "idle"
				penguin.state_chart.send_event("task_travel_request")
	else:
		var closest_distance := 9999999999.0
		var closest_target: Creature
		for target: Creature in target_list:
			var distance := global_position.distance_squared_to(target.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_target = target
	
		for penguin in penguin_list:
			if is_instance_valid(penguin):
				penguin.state_chart.send_event("task_idle_request")
				penguin.request_next_task(closest_target)
	
	release_command()
	
	surprise_effect_list.clear()
