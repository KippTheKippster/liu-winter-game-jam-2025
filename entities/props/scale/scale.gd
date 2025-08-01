extends Node2D

signal threshold_reached
signal threshold_lost

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var label: Label = $Label

@export var threshold: int = 10
var penguin_count: int = 0:
	set(value):
		var old := penguin_count
		penguin_count = value
		if is_node_ready():
			label.text = str(penguin_count) + "/" + str(threshold)
			label.visible = penguin_count != 0
		
			if penguin_count == 0:
				sprite_2d.frame = 0
			elif penguin_count < threshold:
				sprite_2d.frame = 1
			else:
				sprite_2d.frame = 2
		
		if penguin_count == threshold and old < threshold:
			threshold_reached.emit()
		elif penguin_count < threshold and old == threshold:
			threshold_lost.emit()


func _ready() -> void:
	penguin_count = 0


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Penguin:
		penguin_count += 1


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Penguin:
		penguin_count -= 1
