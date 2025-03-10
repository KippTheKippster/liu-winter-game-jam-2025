extends Node2D
class_name Target

@export var active: bool = true
@export var priority: int = 0
@export_range(0.0, 32.0, 0.1, "or_greater")  var size: float = 4.0
@export_range(0.0, 32.0, 0.1, "or_greater") var range: float = 4.0
@export var singular: bool = false
@export_flags("Penguin Interest") var target_layer: int = 0
var occupant: Node
