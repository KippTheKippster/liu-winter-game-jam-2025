extends StaticBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@onready var horizontal_group: Node2D = $HorizontalGroup
@onready var vertical_group: Node2D = $VerticalGroup

enum Orientation {
	HORIZONTAL,
	VERTICAL
}

@export var orientation: Orientation

func _ready() -> void:
	remove_side.call_deferred()


func remove_side() -> void:
	var rectangle_shape := collision_shape_2d.shape as RectangleShape2D
	
	match orientation:
		Orientation.HORIZONTAL:
			horizontal_group.visible = true
			remove_child(vertical_group)
			vertical_group.queue_free()
			rectangle_shape.size = Vector2(24.0, 8.0)
		Orientation.VERTICAL:
			vertical_group.visible = true
			remove_child(horizontal_group)
			horizontal_group.queue_free()
			rectangle_shape.size = Vector2(8.0, 24.0)
