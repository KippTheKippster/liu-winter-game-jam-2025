@tool
extends EditorPlugin

@onready var undo_redo := get_undo_redo()
var container: Container

var canvas_transform_menu: MenuButton
var visible_on_screen_notifier_2d_menu: MenuButton

func _enter_tree() -> void:
	 # MEGA HACK
	var tmp := Control.new()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tmp)
	container = tmp.get_parent().get_parent().get_parent().get_child(0)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tmp)
	tmp.queue_free()
	#print(container.get_parent().get_parent().get_parent())
	
	canvas_transform_menu = preload("canvas_transform_menu.tscn").instantiate() 
	canvas_transform_menu.get_popup().id_pressed.connect(_on_canvas_transform_menu_id_pressed)
	container.add_child(canvas_transform_menu, false)
	container.move_child(canvas_transform_menu, container.get_child_count() - 3)
	
	visible_on_screen_notifier_2d_menu = preload("visible_on_screen_notifier_2d_menu.tscn").instantiate()
	visible_on_screen_notifier_2d_menu.get_popup().id_pressed.connect(_on_visible_on_screen_notifier_2d_menu_id_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, visible_on_screen_notifier_2d_menu)
	
	EditorInterface.get_inspector().edited_object_changed.connect(_on_edited_object_changed)

	update_menu_visibility()

var E := true

func _process(delta: float) -> void:
	return
	if not Input.is_action_just_pressed("ui_accept"):
		return
		
	print("--------------------------------------------------------")
	var parent := canvas_transform_menu.get_parent()
	while parent is not Window:
		parent = parent.get_parent()
	
	E = false
	#for child in get_tree().get_children():
	#	if child is Window:
	#		print(child) 

	a(parent)

func a(node: Node) -> void:
	for child in node.get_children():
		if child is Window:
			print(child.name )
			return
		a(child)

func _exit_tree() -> void:
	canvas_transform_menu.queue_free()
	canvas_transform_menu.get_popup().id_pressed.disconnect(_on_canvas_transform_menu_id_pressed)
	
	visible_on_screen_notifier_2d_menu.queue_free()
	visible_on_screen_notifier_2d_menu.get_popup().id_pressed.disconnect(_on_visible_on_screen_notifier_2d_menu_id_pressed)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, visible_on_screen_notifier_2d_menu)

func _on_edited_object_changed() -> void:
	update_menu_visibility()

func update_menu_visibility() -> void:
	visible_on_screen_notifier_2d_menu.visible = EditorInterface.get_inspector().get_edited_object() is VisibleOnScreenNotifier2D

func is_array_of_class(array: Array[Node], class_string: String) -> bool:
	for item in array:
		if item.get_class() != class_string:
			return false
	return true

func _on_canvas_transform_menu_id_pressed(id: int) -> void:
	match id:
		0:
			undo_redo.create_action("Object to Screen Center")
			for node in EditorInterface.get_selection().get_selected_nodes():
				if node is Node2D:
					undo_redo.add_do_method(self, "object_to_viewport_center", node)
					undo_redo.add_undo_method(self, "undo_object_to_viewport_center", node, node.global_position)
			undo_redo.commit_action()
		1:
			undo_redo.create_action("Object to Child Center")
			for node in EditorInterface.get_selection().get_selected_nodes():
				if node is Node2D:
					undo_redo.add_do_method(self, "object_origin_to_child_center", node)
					undo_redo.add_undo_method(self, "undo_object_origin_to_child_center", node, node.global_position)
			undo_redo.commit_action()

func _on_visible_on_screen_notifier_2d_menu_id_pressed(id: int) -> void:
	match id:
		0:
			EditorInterface.popup_node_selector(func(node_path: NodePath) -> void:
				var notifier := EditorInterface.get_selection().get_selected_nodes()[0] as VisibleOnScreenNotifier2D
				set_notifier_rect_to_canvas_item_boundary(notifier, notifier.owner.get_node_or_null(node_path)),
				["CanvasItem"])

func object_origin_to_child_center(node: Node2D) -> void:
	var center: Vector2
	var child_count: int
	for child in node.get_children():
		if child is Node2D:
			child_count += 1
			center += child.global_position
			
	center /= child_count
	
	var dif := center - node.global_position
	for child in node.get_children():
		if child is Node2D:
			child.global_position -= dif
	
	node.global_position = center

func undo_object_origin_to_child_center(node: Node2D, previous_position: Vector2) -> void:
	var dif := node.global_position - previous_position
	node.global_position = previous_position
	for child in node.get_children():
		if child is Node2D:
			child.global_position += dif

func object_to_viewport_center(node: Node2D) -> void:
	var viewport := EditorInterface.get_editor_viewport_2d()
	var transform := viewport.global_canvas_transform
	var final_position := ((viewport.size as Vector2) / transform.get_scale()) / 2 - transform.origin / transform.get_scale()
	node.global_position = final_position

func undo_object_to_viewport_center(node: Node2D, previous_position) -> void:
	node.global_position = previous_position
	
func set_notifier_rect_to_canvas_item_boundary(notifier: VisibleOnScreenNotifier2D, canvas_item: CanvasItem) -> void:
	if not is_instance_valid(canvas_item):
		return
	
	undo_redo.create_action("Rect to CanvasItem  Boundary")
	
	#undo_redo.add_undo_property(notifier, "global_scale", notifier.global_scale)
	#undo_redo.add_undo_property(notifier, "position", notifier.global_position)
	undo_redo.add_undo_property(notifier, "rect", notifier.rect)
	
	notifier.rect = Rect2()
	
	##undo_redo.add_do_property(notifier, "global_scale", Vector2.ONE)
	#undo_redo.add_do_property(notifier, "global_position", Vector2.ZERO) # TODO Move rect instead of node
	undo_redo.add_do_property(notifier, "rect", 
			canvas_item.get_transform() * RenderingServer.debug_canvas_item_get_rect(canvas_item.get_canvas_item()))
			#recursive_get_canvas_item_boundary(canvas_item.get_transform() * RenderingServer.debug_canvas_item_get_rect(canvas_item.get_canvas_item()), 
			#canvas_item, notifier))
	
	undo_redo.commit_action()

func recursive_get_canvas_item_boundary(current_rect: Rect2, current_node: Node, target_node: CanvasItem) -> Rect2:
	#if current_node is CanvasItem and current_node != target_node:
	#	current_rect = current_node.get_global_transform() * current_rect
		#var center := current_rect.get_center()
		#var scale = node.get_global_transform().get_scale()
		#current_rect.position += node.get_global_transform().origin
		#current_rect.position = center - (current_rect.size / 2.0) * scale
		#current_rect.end = center + (current_rect.size / 2.0) * scale
	
	for child in current_node.get_children():
		if child is CanvasItem and child != target_node:
			var child_rect = child.get_transform() * RenderingServer.debug_canvas_item_get_rect(child.get_canvas_item())
			if child_rect == Rect2():
				continue
			current_rect = current_rect.merge(child_rect)
			current_rect = recursive_get_canvas_item_boundary(current_rect, child, target_node)

	return current_rect
