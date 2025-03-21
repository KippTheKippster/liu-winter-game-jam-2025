extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var penguin_sprites: Node2D = %PenguinSprites
@onready var transition_timer: Timer = $TransitionTimer
@onready var camera_2d: Camera2D = $Camera2D
@onready var horn_audio: AudioStreamPlayer2D = $HornAudio

var acceleration: float = 10.0
var velocity: float = 0.0

@export var fuelled: bool:
	set(value):
		var changed := fuelled != value
		fuelled = value
		if changed and fuelled:
			
			animation_player.play("roll")

@export var fuel_object_types: Array[CarryObjectType]

var departing: bool 

var penguin_list: Array[Penguin2] = []
var penguin_sprite_list: Array[AnimatedSprite2D] = []

func _ready() -> void:
	for sprite: AnimatedSprite2D in penguin_sprites.get_children():
		sprite.speed_scale = randf_range(0.9, 1.2)
		sprite.visible = false
		penguin_sprite_list.append(sprite)


func add_penguin(penguin: Penguin2) -> void:
	penguin.get_parent().remove_child(penguin)
	penguin_list.append(penguin)
	var sprite := penguin_sprite_list[penguin_list.size() - 1]
	sprite.visible = true # TODO Add check
	#sprite.play(sprite.animation)
	if penguin_list.size() == 3:
		depart()


func _process(delta: float) -> void:
	if departing:
		velocity += acceleration * delta
		velocity = minf(72.0, velocity)
		position.x += velocity * delta


func depart() -> void:
	if departing:
		return
	
	departing = true
	transition_timer.start()
	camera_2d.reparent(get_parent())
	camera_2d.enabled = true
	camera_2d.make_current()
	horn_audio.play()


func _on_transition_timer_timeout() -> void:
	#GlobalUi.transition_screen.change_scene_to_file("res://main scenes/game/game.tscn")
	SignalBus.raft_departed.emit(penguin_list)
