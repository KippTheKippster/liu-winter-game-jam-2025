extends Node2D

@onready var creature: Creature = $Creature
@onready var kraken_arm_sprite: Sprite2D = %KrakenArmSprite
@onready var penguin_scared_audio: AudioStreamPlayer2D = $PenguinScaredAudio

func grab_penguin() -> void:
	var next_creature := creature.get_next_creature_target()
	if not next_creature or not next_creature.owner:
		return
	
	var penguin := next_creature.owner as Penguin
	if penguin:
		penguin_scared_audio.play()
		kraken_arm_sprite.frame = 1
		penguin.queue_free() # NOTE This could possibly break things!
