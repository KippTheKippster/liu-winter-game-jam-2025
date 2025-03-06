extends Control

signal depart_accepted()

func _on_accept_button_pressed() -> void:
	depart_accepted.emit()
	visible = false



func _on_cancel_button_pressed() -> void:
	visible = false
