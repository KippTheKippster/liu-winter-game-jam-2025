extends Node2D

@onready var room: Room = $Room

@onready var horizontal_group: Node2D = $HorizontalGroup
@onready var vertical_group: Node2D = $VerticalGroup

func _on_room_layout_updated() -> void:
	if room.neigbor_directions.has(Vector2i.UP) and room.neigbor_directions.has(Vector2i.DOWN):
		remove_child(vertical_group)
		vertical_group.queue_free()
	else:
		remove_child(horizontal_group)
		horizontal_group.queue_free()
