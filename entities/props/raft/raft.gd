extends Node2D

const ARCH_JUMPER_SCENE = preload("uid://dx2ns68b7vg48")
const ArchJumper = preload("uid://c403lnxgiy5ii")

signal penguin_boarded(penguin: Penguin)
signal departed
signal left

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var penguin_sprites: Node2D = %PenguinSprites
@onready var transition_timer: Timer = $TransitionTimer
@onready var camera_2d: Camera2D = $Camera2D
@onready var horn_audio: AudioStreamPlayer2D = $HornAudio

var acceleration: float = 10.0
var velocity: float = 0.0

@export_file("*.tscn") var next_level_path: String = "uid://cti12nwlj0c2n"
@export var fuelled: bool:
	set(value):
		var changed := fuelled != value
		fuelled = value
		if changed and fuelled and is_node_ready():
			animation_player.play("roll")

@export var fuel_object_types: Array[CarryObjectType]

var departing: bool 

var penguin_list: Array[Penguin] = []
var penguin_sprite_list: Array[AnimatedSprite2D] = []

func _ready() -> void:
	for sprite: AnimatedSprite2D in penguin_sprites.get_children():
		sprite.speed_scale = randf_range(0.9, 1.2)
		sprite.visible = false
		penguin_sprite_list.append(sprite)
	
	#set_deferred("fuelled", fuelled)
	if fuelled:
		animation_player.play("roll")


func add_penguin(penguin: Penguin) -> void:
	penguin.get_parent().remove_child(penguin)
	penguin_list.append(penguin)
	var sprite := penguin_sprite_list[penguin_list.size() - 1]
	sprite.visible = true # TODO Add check
	#sprite.play(sprite.animation)
	
	penguin_boarded.emit(penguin)
	
	if get_tree().get_node_count_in_group("penguin") == 0:
		depart()
	#if penguin_list.size() == 3:
		#depart()


func provide_fuel(point: Vector2, type: CarryObjectType) -> void:
	var arch_jumper := ARCH_JUMPER_SCENE.instantiate() as ArchJumper
	arch_jumper.global_position = point
	add_sibling(arch_jumper)
	arch_jumper.copy_carry_object_sprite(type)
	arch_jumper.jump_to_point(global_position)
	arch_jumper.landed.connect(func() -> void:
		fuelled = true
		arch_jumper.queue_free()
		, ConnectFlags.CONNECT_ONE_SHOT)


func _process(delta: float) -> void:
	if departing:
		velocity += acceleration * delta
		velocity = minf(72.0, velocity)
		position += transform.basis_xform(Vector2.RIGHT * velocity * delta)


func depart() -> void:
	if departing:
		return
	
	departing = true
	transition_timer.start()
	camera_2d.reparent(get_parent())
	camera_2d.enabled = true
	camera_2d.make_current()
	horn_audio.play()
	
	departed.emit()


func _on_transition_timer_timeout() -> void:
	left.emit()
