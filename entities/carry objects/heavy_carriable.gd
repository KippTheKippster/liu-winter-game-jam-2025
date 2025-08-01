@tool
extends CharacterBody2D
class_name HeavyCarriable

const Raft = preload("uid://dw4yqocvldxan")

@onready var flow_field_walker: FlowFieldWalker = $FlowFieldWalker
@onready var area_2d: Area2D = $Area2D
@onready var target: Target = $Area2D/Target
@onready var label: Label = $Label

@export var raft: Raft
@export var speed: float = 8.0
@export var weight: int = 3:
	set(value):
		max_carriers = max_carriers
		weight = value

@export var max_carriers: int = 5:
	set(value):
		max_carriers = max(value, weight)

var carriers: Array[Penguin]
#var remote_transforms: Array[RemoteTransform2D]
var targets: Array[Target]
var moving: bool


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	label.visible = false
	for i in max_carriers:
		var _target := Target.new()
		#area_2d.add_child(_target, true)
		_target.position = Vector2.from_angle(TAU * (float(i) / float(max_carriers))) * 16.0
		#remote_transforms.push_back(_target)
		#_target.singular = true
		_target.holder = self
		_target.highlight_node = self
		_target.layer = 1


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not moving:
		return
	
	velocity = flow_field_walker.get_direction() * speed
	move_and_slide()


func is_movable() -> bool:
	return carriers.size() >= weight


func add_carrier(carrier: Penguin) -> bool:
	if carriers.has(carrier) or carriers.size() >= max_carriers:
		return false
	
	#var index: int = -1
	#for i in remote_transforms.size():
	#	if remote_transforms[i].remote_path.is_empty():
	#		index = i
	#		break
	
	#if index == -1:
	#	return false
	
	carriers.push_back(carrier) 
	#remote_transforms[index].remote_path = carrier.get_path()
	#remote_transforms[carriers.size() - 1].remote_path = carrier.get_path()
	update_label()
	if is_movable():
		flow_field_walker.target_point = raft.global_position
		moving = true
	
	return true


func remove_carrier(carrier: Penguin) -> void:
	#var i := carriers.find(carrier)
	#if carriers.has(carrier):	
		#carriers.remove_at(i)
	#	remote_transforms[i].remote_path = ""
	#carriers[carrier].remote_path = ""
	carriers.erase(carrier)
	
	moving = is_movable()
	update_label()


func update_label() -> void:
	label.visible = carriers.size() != 0
	label.text = str(carriers.size()) + "/" + str(weight)
