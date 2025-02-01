extends Node2D

@onready var projectile: Projectile = $Projectile
@onready var area_2d: Area2D = $Area2D
@onready var damage_instance: DamageInstance = %DamageInstance

@export_group("Movement")
@export var start_speed: float = 60
@export var gravity: float = 0.0
@export var use_longest_time: bool = false
@export_group("Display")
@export var look_at_direction: bool

var velocity: Vector2 = Vector2.RIGHT:
	set(value):
		velocity = value
		if look_at_direction and velocity.length() > 0:
			rotation = velocity.angle()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			set_physics_process(true)
			velocity = start_speed * Vector2.RIGHT
			
			projectile.get_velocity_callable = func() -> Vector2: return velocity
			projectile.get_damage_instance_callable = func() -> DamageInstance: return damage_instance
			projectile.get_area_callable = func() -> Area2D: return area_2d
			projectile.set_direction_to_target_point_callable = set_direction_to_target_point
			projectile.set_velocity_callable = func(new_velocity: Vector2) -> void: velocity = new_velocity
		NOTIFICATION_PHYSICS_PROCESS:
			var delta := get_process_delta_time()
			velocity.y += gravity * delta
			position += velocity * delta


func set_direction_to_target_point(requested_point: Vector2) -> void:
	var distance := requested_point - global_position
	var min_point_time := sqrt(distance.length() / (2 * gravity)) # https://www.desmos.com/calculator/0hvwhwmjje
	var time: float
	if use_longest_time:
		time = approximate_time(distance, start_speed, min_point_time, 1)
	else:
		time = approximate_time(distance, start_speed, min_point_time, -1)
	
	velocity = get_velocity_from_time(distance, time).normalized() * start_speed


func get_velocity_from_time(distance: Vector2, time: float) -> Vector2:
	var v: Vector2
	v.x = distance.x / (2.0 * time)
	v.y = distance.y / (2.0 * time) - gravity * time
	return v


func approximate_time(distance: Vector2, target_speed: float, start_time: float, dir: int):
	var offset := 0.1 * dir
	var time := start_time
	var min_dif := absf(get_velocity_from_time(distance, time).length() - target_speed)
	# Search for time where velocity is closest to target_speed
	for i in 5:
		var v := get_velocity_from_time(distance, time + offset)
		var speed_dif := absf(v.length() - target_speed)
		if speed_dif <= min_dif:
			min_dif = speed_dif
			time += offset
		else:
			offset *= 0.5
	
	return time
