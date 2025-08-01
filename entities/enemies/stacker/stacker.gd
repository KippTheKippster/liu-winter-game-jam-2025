extends CharacterBody2D

const Stacker = preload("uid://d1ipnpaid76tr")
const STACKER_SCENE = preload("uid://cowvagrpdw1pr")

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var danger_target_detector: TargetDetector = $DangerTargetDetector
@onready var target_detector: TargetDetector = $TargetDetector
@onready var flow_field_walker: FlowFieldWalker = $FlowFieldWalker
@onready var self_target: Target = %Target
@onready var health_instance: HealthInstance = %HealthInstance
@onready var vertical_group: VerticalGroup = $VerticalGroup
@onready var flip_group: FlipGroup = %FlipGroup
@onready var carriable_sprite: Sprite2D = %CarriableSprite
@onready var top_transform: RemoteTransform2D = %TopTransform
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_chart: StateChart = $StateChart

@export_range(0, 10, 1, "or_greater") var start_height = 0
@export var height_offset: float = 5.0
@export var explode_speed: float = 20.0
@export var max_speed: float = 16.0
var current_speed: float = 16.0
@export var carriable_type: CarryObjectType
var danger_target: Target

var leader: Stacker
var leader_priority: int = 0
var target: Target = null

var top: Stacker = null
var bottom: Stacker = null

func _ready() -> void:
	current_speed = max_speed
	if start_height > 0:
		set_in_stack(false)
		spawn_stack.call_deferred()


func _process(delta: float) -> void:
	animation_tree.set("parameters/idle_blend_space/blend_position", float(velocity.length() > 0.0))


func _physics_process(delta: float) -> void:
	state_chart.set_expression_property("on_floor", vertical_group.is_on_floor() and bottom == null)
	
	if vertical_group.is_on_floor():
		flip_group.flip_towards(velocity)
	
	move_and_slide()


func spawn_stack() -> void:
	var current := self as Stacker
	for i in start_height:
		var stacker := STACKER_SCENE.instantiate() as Stacker
		stacker.start_height = 0
		current.add_to_stack(stacker)
		current = stacker
		leader_priority = i + 1
	
	if carriable_type != null:
		pass_item()


func pass_item() -> Stacker:
	var top_stacker := get_top()
	top_stacker.carriable_type = carriable_type
	carriable_type.apply_to_sprite(top_stacker.carriable_sprite)
	
	if top_stacker != self:
		carriable_type = null
		carriable_sprite.texture = null
	
	return top_stacker


func has_stack_item() -> bool:
	return get_top().carriable_type != null


func get_top() -> Stacker:
	if top == null:
		return self
	else:
		return top.get_top()


func get_bottom() -> Stacker:
	if bottom == null:
		return self
	else:
		return bottom.get_bottom()


func add_to_stack(stacker: Stacker) -> void:
	if stacker == self:
		return
	
	var top_stacker := get_top()
	if stacker.get_parent() != null:
		stacker.get_parent().remove_child(stacker)
	top_stacker.add_child(stacker)
	stacker.set_in_stack.call_deferred(true)
	top_stacker.top = stacker
	top_stacker.top_transform.remote_path = stacker.get_path()
	stacker.bottom = top_stacker
	stacker.global_position = top_stacker.global_position + Vector2.UP * height_offset
	if top_stacker.carriable_type != null:
		top_stacker.pass_item()
	
	var bottom_stacker := get_bottom()
	bottom_stacker.current_speed *= 0.75


func set_in_stack(in_stack: bool) -> void:
	collision_shape_2d.disabled = in_stack
	self_target.active = !in_stack
	if in_stack:
		state_chart.send_event("request_in_stack")
	else:
		state_chart.send_event("request_idle")


func break_stack(root: Stacker, explode: bool = true) -> void:
	if top:
		top.break_stack(root, explode)
	
	top = null
	bottom = null
	health_instance.current_health = health_instance.base_health
	
	current_speed = max_speed
	top_transform.remote_path = ""
	
	if root != self:
		reparent(root.get_parent())
		var dif := root.global_position.y - global_position.y 
		global_position = root.global_position
		vertical_group.height = dif
		set_in_stack(false)
		if explode:
			vertical_group.jump()
			velocity = Vector2.from_angle(randf() * TAU) * explode_speed
			state_chart.send_event("request_fall")
			if carriable_type != null:
				throw_item(root)
	else:
		if explode:
			state_chart.send_event("request_panic")


func throw_item(root: Node2D) -> Carriable:
	var carry_object := load(carriable_type.carriable_scene_path).instantiate() as Carriable
	carry_object.carry_object_type = carriable_type
	carry_object.place(global_position, 1.0, Vector2.ZERO, root.get_parent())
	carriable_type = null
	carriable_sprite.texture = null
	return carry_object

func _on_health_instance_died() -> void:
	if top == null:
		if has_stack_item():
			throw_item(self)
		queue_free()
	else:
		break_stack(self)


func _on_stun_state_exited() -> void:
	vertical_group.jump(60.0)


func _on_idle_state_physics_processing(delta: float) -> void:
	danger_target = danger_target_detector.get_next_target()
	if is_instance_valid(danger_target):
		state_chart.send_event("request_panic")


func _on_panic_state_entered() -> void:
	flow_field_walker.reverse_path = true


func _on_panic_state_exited() -> void:
	flow_field_walker.reverse_path = false
	danger_target = null


func _on_panic_state_physics_processing(delta: float) -> void:
	if is_instance_valid(danger_target):
		flow_field_walker.target_point = danger_target.global_position
		velocity = flow_field_walker.get_direction() * current_speed


func _on_fall_state_exited() -> void:
	velocity = Vector2.ZERO


func find_leader() -> Stacker:
	var stackers := get_tree().get_nodes_in_group("stacker")
	var next_leader = self
	for stacker: Stacker in stackers:
		if has_stack_item() and stacker.has_stack_item():
			continue
		
		if next_leader.leader_priority < stacker.leader_priority:
			next_leader = stacker
		elif next_leader.leader_priority == stacker.leader_priority:
			if next_leader.get_instance_id() < stacker.get_instance_id():
				next_leader = stacker
	
	return next_leader


func decide() -> void:
	var next_leader := find_leader()
	var next_target := target_detector.get_next_target()
	if has_stack_item():
		state_chart.send_event("request_panic")
		next_target = null
	
	target = null
	leader = null
	
	if next_leader == self:
		leader = null
		state_chart.send_event("request_panic")
		return
	
	if (is_instance_valid(next_target) and
		next_target.holder is Carriable and
		global_position.distance_squared_to(next_target.global_position) <
		global_position.distance_squared_to(next_leader.global_position)):
		target = next_target
		state_chart.send_event("request_item_search")
	else:
		leader = next_leader
		state_chart.send_event("request_leader_search")


func _on_decide_state_entered() -> void:
	decide()


func move_to_node(node: Node2D, callable: Callable) -> void:
	flow_field_walker.reverse_path = false
	flow_field_walker.target_point = node.global_position
	velocity = flow_field_walker.get_direction() * current_speed
	var dif := node.global_position - global_position
	#velocity = dif.normalized() * 16.0 
	if dif.length_squared() < 4.0 and vertical_group.is_on_floor():
		callable.call()


func _on_leader_search_state_physics_processing(delta: float) -> void:
	if not is_instance_valid(leader) or (has_stack_item() and leader.has_stack_item()):
		state_chart.send_event("request_decide")
		return
	
	move_to_node(leader, func():
		vertical_group.jump()
		vertical_group.landed.connect(func ():
			if is_instance_valid(leader) and leader.is_inside_tree():
				var dif := leader.global_position - global_position
				if dif.length_squared() < 4.0:
					if is_instance_valid(leader):
						leader.add_to_stack(self)
						leader = null
						velocity = Vector2.ZERO
					, ConnectFlags.CONNECT_ONE_SHOT)
	)

func _on_item_search_state_processing(delta: float) -> void:
	if (is_instance_valid(target) and target.is_inside_tree() and target.holder is Carriable) == false:
		state_chart.send_event("request_decide")
		return
	
	move_to_node(target, func():
		var carriable := target.holder as Carriable
		carriable_type = carriable.carry_object_type
		pass_item()
		carriable.get_parent().remove_child(carriable)
		carriable.queue_free()
	)


func _on_stack_state_entered() -> void:
	velocity = Vector2.ZERO
