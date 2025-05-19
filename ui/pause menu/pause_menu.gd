extends Control

signal continue_requested
signal depart_requested
signal quit_requested

@onready var depart_button: Button = $VBoxContainer/DepartButton

var allow_depart: bool:
	set(value):
		allow_depart = value
		depart_button.disabled = !allow_depart


func _on_continue_button_pressed() -> void:
	continue_requested.emit()


func _on_depart_button_pressed() -> void:
	depart_requested.emit()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()
