@tool

extends Node2D
class_name Target

@export var active: bool = true
@export var priority: int = 0
@export_range(0.0, 32.0, 0.1, "or_greater") var size: float = 4.0
@export var extent: Vector2:
	set(value):
		extent = value
		queue_redraw()
@export var singular: bool = false
@export var holder: Node
@export var highlight_node: Node2D
@export_flags("Penguin", "Food", "Danger") var layer: int = 0

var time: float = 0.0
var occupant: Node
var highlight: bool:
	set(value):
		var changed := highlight != value
		highlight = value
		
		if not highlight_node:
			return
		
		if changed:
			if not highlight:
				highlight_node.modulate = Color(1.0, 1.0, 1.0)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(-extent / 2.0, extent), Color.BLUE, false, 0.5)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if not is_in_group("target"):
		add_to_group("target")
	
	if not holder:
		holder = owner
	
	if not highlight_node:
		highlight_node = owner


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if highlight:
		highlight_node.modulate = remap(cos(time * 8.0), -1.0, 1.0, 0.8, 1.0) * Color(1.5, 1.5, 1.5, 10.0)
		#print(remap(cos(time * 4.0), -1.0, 1.0, 0.8, 1.0), " : ", cos(time))
		time += delta
	else:
		time = 0.0


func is_overlapping_point(target: Target, point: Vector2) -> bool:
	return true
