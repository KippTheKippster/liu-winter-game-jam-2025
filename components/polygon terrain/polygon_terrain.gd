@tool
extends CollisionPolygon2D

@export var tile_size: float = 8.0
@export var tile_texture: Texture2D

@export_tool_button("Refresh")
var refresh_action := refresh

var tiles: Array[Vector2] = []


func _draw() -> void:
	for point in tiles:
		draw_texture(tile_texture, point)


func refresh() -> void:
	print("Refreshing")
	tiles.clear()
	for i in polygon.size(): #1: 
		create_tile_line(i)
	
	#3create_tile_line(polygon[polygon.size() - 1)
	
	queue_redraw()


func is_boundary_right(index: int) -> bool:
	var start_x := polygon[index].x
	for i in polygon.size():
		var j := (index + i + 1) % polygon.size()
		var point := polygon[j]
		if point.x < start_x:
			return true
		elif point.x > start_x:
			return false
		
	return false


func is_boundary_bottom(index: int) -> bool:
	var start_y := polygon[index].y
	for i in polygon.size():
		var j := (index + i + 1) % polygon.size()
		var point := polygon[j]
		if point.y < start_y:
			return true
		elif point.y > start_y:
			return false
		
	return false


func create_tile_line(i: int) -> void:
	var a := i       % polygon.size()
	var b := (i + 1) % polygon.size()
	var point_a := polygon[a]
	var point_b := polygon[b]
	var dif := point_b - point_a
	var dir := dif.normalized()
	var tile_offset := dir.sign() #Vector2(float(dir.x != 0), float(dir.y != 0)) 
	"""if tile_offset.x != 0:
		if tile_offset.x < 0:
			point_a -= tile_offset * tile_size
		else:
			point_b -= tile_offset * tile_size
	print(tile_offset)
	"""
	
	if is_boundary_right(a):
		point_a.x -= tile_size
	
	if is_boundary_right(b):
		point_b.x -= tile_size
	
	if is_boundary_bottom(a):
		point_a.y -= tile_size
	
	if is_boundary_bottom(b):
		point_b.y -= tile_size
	
	#if is_boundary_right(i):
	#	point_a.x += tile_size
	#else:
	##	point_b.x -= tile_size
	
	#if point_a.x > point_b.x:
	#	point_a += tile_offset * tile_size
	#elif point_a.x < point_b.x:
	#	point_b -= tile_offset * tile_size
	
	#if point_a.y > point_b.y:
	#	point_a += tile_offset * tile_size
	#elif point_a.y < point_b.y:
	#	point_b -= tile_offset * tile_size
	
	#if dir.x == 1.0:
	for j in int(dif.length() / (tile_size * tile_offset.length())):#absi(int(dif.x / tile_size)) + absi(int(dif.y / tile_size)):
		var tile_point := point_a + j * tile_offset * tile_size
		tiles.push_back(tile_point)
		#var out_of_bounds := tile_point.x + tile_size > point_b.x or tile_point.y + tile_size < point_b.y
		#print(out_of_bounds)
		#print(tile_point)
