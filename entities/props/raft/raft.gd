extends Node2D

@onready var area_2d: Area2D = $Area2D

var overlapping_penguins: Array[Penguin] = []

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Penguin:
		overlapping_penguins.append(body)
		SignalBus.raft_penguin_entered.emit(overlapping_penguins)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Penguin:
		overlapping_penguins.erase(body)
		SignalBus.raft_penguin_exited.emit(overlapping_penguins)
