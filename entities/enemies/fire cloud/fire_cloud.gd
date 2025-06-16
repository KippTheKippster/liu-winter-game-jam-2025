extends Node2D

@export var start_extinguished: bool
@export var chase_speed: float = 60.0
@export var flee_speed: float = 4.0
@export var puff_distance: float = 8.0

@onready var target: Target = %Target
@onready var target_detector: TargetDetector = $TargetDetector
@onready var flip_group: FlipGroup = $FlipGroup
@onready var state_chart: StateChart = $StateChart

var direction: Vector2
var fire_source_point: Vector2

func _ready() -> void:
	if start_extinguished:
		state_chart.send_event.call_deferred("extinguish")
		direction = Vector2.LEFT


func apply_effect_fire(body: Node2D) -> void:
	return
	if body is Penguin:
		body.danger_target = target
		body.effect_fire_active = true
		body.state_chart.send_event("request_task_panic")


func _on_tile_detector_tile_detected(layer: TileMapLayer, coords: Vector2i) -> void:
	var tile_data := layer.get_cell_tile_data(coords)
	if tile_data and tile_data.has_custom_data("water"):
		if tile_data.get_custom_data("water") == true:
			state_chart.send_event("extinguish")


func _on_chase_state_processing(delta: float) -> void:
	var chase_target := target_detector.get_next_target()
	if not is_instance_valid(chase_target):
		return
	
	var dif := chase_target.global_position - global_position
	direction = dif.normalized()
	position += direction * chase_speed * delta
	flip_group.flip_towards(dif)
	
	if dif.length_squared() < pow(puff_distance, 2):
		state_chart.send_event("request_puff")


func _on_area_2d_body_entered(body: Node2D) -> void:
	apply_effect_fire(body)


func _on_puff_area_body_entered(body: Node2D) -> void:
	apply_effect_fire(body)


func _on_flee_state_entered() -> void:
	var min_distance := 9999999999.0
	for node in get_tree().get_nodes_in_group("fire_source"):
		if node is Node2D:
			var distance := global_position.distance_squared_to(node.global_position)
			if distance < min_distance:
				min_distance = distance
				fire_source_point = node.global_position
	
	direction = (fire_source_point - global_position).normalized()


func _on_flee_state_processing(delta: float) -> void:
	position += direction * flee_speed * delta
	flip_group.flip_towards(direction)


func _on_health_instance_died() -> void:
	queue_free()


func _on_health_instance_damage_received(result: DamageResult) -> void:
	if result.damage_instance.effect == DamageInstance.Effect.FIRE:
		state_chart.send_event("ignite")
