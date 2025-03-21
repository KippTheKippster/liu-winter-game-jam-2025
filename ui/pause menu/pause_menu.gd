extends Control

signal depart_request


func _on_depart_button_pressed() -> void:
	depart_request.emit()
