extends Node2D
class_name FishingHole

signal finished

@onready var catch_timer: Timer = $CatchTimer
@onready var carriable_launcher: CarriableLauncher = $CarriableLauncher
@onready var splash_audio: AudioStreamPlayer2D = $SplashAudio
@onready var seat_marker: Marker2D = %SeatMarker
@onready var target: Target = $Area2D/Target
@onready var hole_sprite: AnimatedSprite2D = $HoleSprite

var caught_count: int = 0

var occupant: Node2D:
	set(value):
		occupant = value
		target.occupant = occupant
		if occupant:
			reset_timer()
		else:
			catch_timer.stop()

func _ready() -> void:
	hole_sprite.play()
	update_animation()


func update_animation() -> void:
	hole_sprite.animation = str(clampi(carriable_launcher.carriables.size(), 0, 3))


func _on_catch_timer_timeout() -> void:
	caught_count += 1
	if caught_count >= 3:
		target.active = false
		finished.emit()
	else:
		reset_timer()
	carriable_launcher.launch()
	splash_audio.play()
	update_animation()


func reset_timer() -> void:
	if not catch_timer.is_stopped():
		catch_timer.stop()
	
	catch_timer.wait_time = randf_range(10.0, 15.0) * (caught_count + 1)
	print("Final wait time: ", catch_timer.wait_time)
	catch_timer.start()
