extends Label

@onready var free_timer: Timer = $FreeTimer

@export var start_visible: bool = false
@export var start_detached: bool = false

func _ready() -> void:
	visible = start_visible
	if start_detached:
		detach.call_deferred()


func detach() -> void:
	reparent(owner.get_parent())
	
	visible = true
	
	var tween := create_tween()
	tween.tween_property(self, "position", position + Vector2.UP * 8, 0.5)

	free_timer.wait_time = 1.5
	free_timer.start()


func _on_free_timer_timeout() -> void:
	queue_free()
