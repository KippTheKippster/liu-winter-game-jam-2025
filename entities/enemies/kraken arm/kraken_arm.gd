extends Node2D

@onready var target_detector: TargetDetector = $TargetDetector
@onready var kraken_arm_sprite: Sprite2D = %KrakenArmSprite
@onready var penguin_scared_audio: AudioStreamPlayer2D = $PenguinScaredAudio
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@export var grab_wait_time: float = 2.0

var penguin: Penguin
var time: float 

func _process(delta: float) -> void:
	if is_instance_valid(penguin):
		global_position = penguin.global_position
		time += delta
		if time >= grab_wait_time:
			#grab_penguin()
			state_machine.travel("grab")
			grab_penguin()
			penguin = null


func grab_penguin() -> void:
	#var next_target := target_detector.get_next_target()
	if not is_instance_valid(penguin):
		return
	
	#var penguin := next_target.holder as Penguin
	#if penguin:
	penguin_scared_audio.play()
	kraken_arm_sprite.frame = 1
	if penguin.carriable:
		penguin.throw_carriable()
	penguin.kill()
