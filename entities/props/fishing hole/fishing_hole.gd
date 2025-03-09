extends Node2D
class_name FishingHole

@onready var catch_timer: Timer = $CatchTimer
@onready var carriable_launcher: CarriableLauncher = $CarriableLauncher
@onready var splash_audio: AudioStreamPlayer2D = $SplashAudio
@onready var seat_marker: Marker2D = %SeatMarker
@onready var target: Target = $Area2D/Target

var caught_count: int = 0

var occupant: Node2D:
	set(value):
		occupant = value
		target.occupant = occupant
		if occupant:
			reset_timer()
		else:
			catch_timer.stop()


func _on_catch_timer_timeout() -> void:
	caught_count += 1
	reset_timer()
	carriable_launcher.launch()
	splash_audio.play()


func reset_timer() -> void:
	if not catch_timer.is_stopped():
		catch_timer.stop()
	
	catch_timer.wait_time = randf_range(10.0, 15.0) * (caught_count + 1)
	print("Final wait time: ", catch_timer.wait_time)
	catch_timer.start()
