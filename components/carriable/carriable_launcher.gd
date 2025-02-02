extends Node2D
class_name CarriableLauncher

@export var creature: Creature
@export var start_height = 0.0

var carriables: Array[Carriable]

func _ready() -> void:
	for child in get_children():
		var carriable := Utils.find_child_of_class(child, "Carriable") as Carriable
		if carriable:
			carriables.append(carriable)
			carriable.pickup()
	
	if creature:
		creature.died.connect(launch)


func launch() -> void:
	for carriable in carriables:
		carriable.place(global_position, start_height, owner.get_parent())
