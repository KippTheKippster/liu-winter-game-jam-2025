extends Node

const KRAKEN_ARM_SCENE = preload("res://entities/enemies/kraken arm/kraken_arm.tscn")
const KrakenArm = preload("res://entities/enemies/kraken arm/kraken_arm.gd")

var arms: Dictionary[Penguin, KrakenArm]

func _ready() -> void:
	SignalBus.penguin_entered_deep_water.connect(func(penguin: Penguin) -> void:
		var kraken_arm := KRAKEN_ARM_SCENE.instantiate() as KrakenArm
		add_sibling(kraken_arm)
		kraken_arm.global_position = penguin.global_position
		kraken_arm.penguin = penguin
		arms[penguin] = kraken_arm
		)
	
	SignalBus.penguin_exited_deep_water.connect(func(penguin: Penguin) -> void:
		if arms.has(penguin):
			var kraken_arm := arms[penguin]
			if is_instance_valid(kraken_arm):
				kraken_arm.get_parent().remove_child(kraken_arm)
				kraken_arm.queue_free()
		)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
