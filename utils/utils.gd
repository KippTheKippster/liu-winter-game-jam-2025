@tool
class_name Utils

static func find_child_of_class(parent: Node, class_string: StringName, recursive: bool = true) -> Node:
	if is_global_class(parent, class_string):
		return parent
	
	for child in parent.get_children():
		if recursive:
			var class_instance := find_child_of_class(child, class_string)
			if class_instance:
				return class_instance
		else:
			if is_global_class(child, class_string):
				return child
	
	return null


static func get_children_of_class(parent: Node, class_string: StringName, recursive: bool = true) -> Array[Node]:
	var list: Array[Node]
	for child in parent.get_children():
		if is_global_class(child, class_string):
			list.append(child)
		
		if recursive:
			list.append_array(get_children_of_class(child, class_string, true))
	
	return list


static func get_global_class(object: Object) -> StringName:
	var script := object.get_script() as Script
	if script:
		var global_name := script.get_global_name()
		if global_name.is_empty():
			return script.get_instance_base_type() 
		else:
			return global_name
	else:
		return object.get_class()


static func is_global_class(object: Object, class_string: StringName) -> bool:
	var script: Script = object.get_script()
	while script:
		if script.get_global_name() == class_string:
			return true
		
		script = script.get_base_script()
	
	return object.is_class(class_string)


static func area_get_overlapping_areas_of_class(area: Area2D, class_string: StringName) -> Array[Area2D]:
	var areas: Array[Area2D] = []
	for overlapping_area in area.get_overlapping_areas():
		if is_global_class(overlapping_area, class_string):
			areas.append(overlapping_area)
	
	return areas


static func set_bitmask_layer_value(bitmask: int, layer_number: int, value: bool) -> int:
	if value:
		bitmask |= 1 << layer_number;
	else:
		bitmask &= ~(1 << layer_number);
	
	return bitmask


static func get_bitmask_layer_value(bitmask: int, layer_number: int) -> bool:
	return bitmask & (1 << layer_number) != 0


static func remap_clamp(value: float, istart: float, istop: float, ostart: float, ostop: float) -> float:
	if ostart < ostop:
		return clampf(remap(value, istart, istop, ostart, ostop), ostart, ostop)
	else:
		return clampf(remap(value, istart, istop, ostart, ostop), ostop, ostart)


static func set_camera_limit_rect(camera: Camera2D, rect: Rect2i) -> void:
	camera.limit_left = rect.position.x
	camera.limit_right = rect.end.x
	camera.limit_top = rect.position.y
	camera.limit_bottom = rect.end.y


static func rect_add(rect_1: Rect2, rect_2: Rect2) -> Rect2:
	rect_1.position += rect_2.position
	rect_1.size += rect_2.size
	return rect_1


static func call_delayed(node: Node, delay: float, method: Callable) -> void:
	var timer := Timer.new()
	node.add_child(timer)
	timer.wait_time = delay
	timer.start()
	timer.timeout.connect((func(_method: Callable, _node: Node, _timer: Timer) -> void: 
			method.call()
			_node.remove_child(_timer)
			_timer.queue_free()
			).bind(method, node, timer)
	)


static func seconds_to_string(seconds: float) -> String:
	return "%02d:%02d" % [seconds, fmod(seconds, 1) * 100]


static func play_audio_2d(stream: AudioStream, point: Vector2, parent: Node, bus: StringName = "Effects") -> AudioStreamPlayer2D:
	var audio := AudioStreamPlayer2D.new()
	audio.stream = stream
	audio.autoplay = true
	audio.finished.connect(audio.queue_free)
	audio.bus = bus
	parent.add_sibling(audio)
	return audio
