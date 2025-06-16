extends Node2D

enum Size {
	SMALL,
	MEDIUM,
	LARGE
}

const SnowExplosion = preload("res://entities/effects/snow explosion/snow_explosion.gd")
const SNOW_EXPLOSION_SCENE = preload("res://entities/effects/snow explosion/snow_explosion.tscn")

@onready var creature: Creature = $Creature
@onready var scared_audio: AudioStreamPlayer2D = $ScaredAudio
@onready var grow_timer: Timer = $GrowTimer
@onready var damage_instance: DamageInstance = $DamageInstance
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var speed: float = 20.0
@export var direction: Vector2 = Vector2.RIGHT

@export var sprites: Array[Sprite2D]

var caught_penguins: Array[Penguin]:
	set(value):
		caught_penguins = value
		for i in sprites.size():
			sprites[i].visible = i <= caught_penguins.size()
			print(i, ": ", sprites[i].visible)


var penguin_limit: int = 1
var snowball_size: Size:
	set(value):
		snowball_size = value
		match value:
			Size.SMALL:
				penguin_limit = 1
				creature.detection_range = 6.0
			Size.MEDIUM:
				penguin_limit = 2
				creature.detection_range = 8.0
			Size.LARGE:
				penguin_limit = 4
				creature.detection_range = 12.0
		
		for i in sprites.size():
			var sprite := sprites[i]
			sprite.frame_coords.y = i + value * sprites.size()
		
		#snowball_sprite.frame_coords.y = value * 4


func _ready() -> void:
	#penguins_sprite.frame = 0
	snowball_size = Size.SMALL
	#snowball_size = Size.LARGE
	caught_penguins = caught_penguins


func _process(delta: float) -> void:
	position += speed * direction * delta
	
	if caught_penguins.size() >= penguin_limit:
		return
	
	var next_creature := creature.get_next_creature_target()
	if not next_creature or not next_creature.owner or not next_creature.owner is Penguin:
		return
	
	var penguin := next_creature.owner
	if caught_penguins.has(penguin):
		return
	
	#penguin.queue_free() # NOTE REPLACE THIS WITH PENGUIN REMOVE FUNCTION
	penguin.get_parent().remove_child(penguin)
	caught_penguins.append(penguin)
	caught_penguins = caught_penguins
	
	scared_audio.play()


func destroy() -> void:
	for penguin in caught_penguins:
		add_sibling(penguin)
		var launch_direction := Vector2.from_angle(2.0 * PI * randf())
		penguin.position = position + launch_direction
		penguin.health_instance.damage(damage_instance, launch_direction) # DANGER if direction is the same twice then the penguins will be stuck in eachother
		#penguin.vertical_group.jump()
	
	var snow_explosion := SNOW_EXPLOSION_SCENE.instantiate() as SnowExplosion
	snow_explosion.start_size = max(snowball_size, Size.MEDIUM)
	add_sibling(snow_explosion)
	snow_explosion.position = position
	
	animation_player.play("smash")
	#queue_free()


func _on_frame_timer_timeout() -> void:
	for sprite in sprites:
		sprite.frame_coords.x = (sprite.frame_coords.x + 1) % sprite.hframes
	#snowball_sprite.frame_coords.x = (snowball_sprite.frame_coords.x + 1) % snowball_sprite.hframes
	#penguins_sprite.frame_coords.x = (penguins_sprite.frame_coords.x + 1) % penguins_sprite.hframes


func _on_grow_timer_timeout() -> void:
	snowball_size += 1
	if snowball_size == Size.LARGE:
		grow_timer.stop()


func _on_area_2d_body_entered(body: Node2D) -> void:
	destroy.call_deferred()


func _on_tile_detector_tile_detected(layer: TileMapLayer, coords: Vector2i) -> void:
	var tile_data := layer.get_cell_tile_data(coords)
	if tile_data:
		if tile_data.has_custom_data("water") and tile_data.get_custom_data("water") == true:
			destroy()
