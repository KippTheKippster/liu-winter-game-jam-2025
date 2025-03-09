extends CarryObjectTypeInstance

const PENGUIN_SCENE = preload("res://entities/penguin/penguin.tscn")
const PENGUIN_EGG_CRACK = preload("uid://cwesqfpkj4mto")

func _ready() -> void:
	applied.connect(func(carriable: Carriable) -> void:
		var timer := Timer.new()
		timer.wait_time = randf_range(25.0, 35.0)
		timer.one_shot = true
		timer.autostart = true
		timer.timeout.connect(func() -> void:
			var penguin := PENGUIN_SCENE.instantiate() as Penguin2
			carriable.add_sibling(penguin)
			penguin.vertical_group.jump()
			penguin.global_position = carriable.global_position
			
			var audio := AudioStreamPlayer2D.new()
			carriable.add_sibling(audio)
			audio.global_position = carriable.global_position
			audio.stream = PENGUIN_EGG_CRACK
			audio.finished.connect(audio.queue_free)
			audio.volume_db = -5.0
			audio.bus = "Effects"
			audio.play()
			
			carriable.queue_free()
			)
		add_child(timer)
		)
