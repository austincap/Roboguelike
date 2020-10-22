extends Node2D

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != BUTTON_LEFT or not event.pressed:
		return
	#print(self.print_tree_pretty())
	#print($PlayerNode.get_name())
	#var new_path = $Node2D/Navigation2D.get_simple_path($PlayerNode.global_position, get_global_mouse_position())
	var new_path = $Navigation2D.get_simple_path($PlayerNode.global_position, get_global_mouse_position())
	$Line2D.points = new_path
	$PlayerNode.path = new_path

func _ready():
	#self.print_tree_pretty()
	var tilemap1 = load("res://TileSets/test1.tscn")
	tilemap1 = tilemap1.instance()
	$Navigation2D.add_child(tilemap1)
	tilemap1.position = Vector2(768, 512)
	var tilemap2 = load("res://TileSets/test2.tscn")
	tilemap2 = tilemap2.instance()
	$Navigation2D.add_child(tilemap2)
	tilemap2.position = Vector2(768, 928)
	var tilemap3 = load("res://TileSets/test3.tscn")
	tilemap3 = tilemap3.instance()
	$Navigation2D.add_child(tilemap3)
	tilemap3.position = Vector2(0, 1152)
	var tilemap4 = load("res://LevelGen-alt-nav/0000.tscn")
	##CONVERT ALL SHIT IN LEVELGEN-alt-nav TO the EXAMPLE 0000.tscn
	tilemap4 = tilemap4.instance()
	$Navigation2D.add_child(tilemap4)
	tilemap4.position = Vector2(288, 576)
	var polygon2 = NavigationPolygon.new()
	var vertices2 = $Node2D/Navigation2D/UnderTileMap.get_tileset().tile_get_navigation_polygon(0).get_vertices()
	print(vertices2)
	polygon2.set_vertices(vertices2)
	var indices2 = PoolIntArray([0,1,2,3])
	polygon2.add_polygon(indices2)
	#$Navigation2D/NavigationPolygonInstance.navpoly = polygon2
	print($Node2D/Navigation2D/UnderTileMap.get_tileset().tile_get_navigation_polygon(30).get_vertices())
	#var newTransform = Transform2D.IDENTITY
	#print($Navigation2D.navpoly_add($Node2D/Navigation2D, newTransform))
	#$Navigation2D.navpoly_add($Node2D2/Navigation2D)
	#print($Navigation2D/UnderTileMap.get_tileset().tile_get_navigation_polygon(0).get_vertices())
#	var newPolygon = Polygon2D.new()
#	newPolygon.polygon = PoolVector2Array([Vector2(0, 0), Vector2(0, 50), Vector2(50, 50), Vector2(50, 0)])
#	newPolygon.texture = Texture.new()
#	newPolygon.color = Color(1, 0, 0)

	
	#var vertices = PoolVector2Array([Vector2(0, 0), Vector2(0, 100), Vector2(50, 50), Vector2(50, -100)])
	#var vertices = $Node2D/Navigation2D/UnderTileMap.get_tileset().tile_get_navigation_polygon(0).get_vertices()
	#polygon.set_vertices(vertices)
	#var indices = PoolIntArray([0, 1, 2, 3])
	#polygon.add_polygon(indices)
	#print(polygon2.get_outline(0))
	#print(polygon.get_vertices())
	#polygon.add_polygon(polygon2.get_polygon(0))
	#$Navigation2D/UnderTileMap.get_tileset().tile_get_navigation_polygon(0).add_polygon(indices)
	var navPolygonInstance = NavigationPolygonInstance.new()
	var outline = PoolVector2Array([Vector2(0, 0), Vector2(0, 50), Vector2(50, 50), Vector2(50, 0)])
	#polygon.add_outline(outline)
	#polygon.make_polygons_from_outlines()
	#navPolygonInstance.navpoly = polygon
	var i = 0
	var thischunkstilemap
	var newpolygonArray = PoolVector2Array()
#	newpolygonArray.append(Vector2(-900, -900))
#	newpolygonArray.append(Vector2(-800, 400))
#	newpolygonArray.append(Vector2(0, 0))
	for node in self.get_children():
		var navTiles = []
		thischunkstilemap = node.get_node("Navigation2D/UnderTileMap")
		if i < 2:
			navTiles = thischunkstilemap.get_used_cells_by_id(0)
			var y = 0
			for tile in navTiles:
				if y < 9:
					var polygon_offset = Vector2(thischunkstilemap.map_to_world(tile)[0], thischunkstilemap.map_to_world(tile)[1]) # - Vector2(0, 0)] #thischunk.get_cell_size()/2, 0
					#print(typeof(polygon_offset))
					newpolygonArray.append(polygon_offset)
				y+=1
			i+=1
		break
	print(newpolygonArray.size())
	#print($Polygon2D.polygon)
	#$Polygon2D.polygon = newpolygonArray
#	var polygon = NavigationPolygon.new()
#	polygon.add_outline(newpolygonArray)
#	polygon.make_polygons_from_outlines()
#	print(polygon.get_outline(0))
#	polygon.make_polygons_from_outlines()
	#$Navigation2D/NavigationPolygonInstance.navpoly = polygon
	#$Navigation2D.navpoly_add(navPolygonInstance)
	#$Navigation2D/NavigationPolygonInstance.navpoly = polygon
	#$Navigation2D.add_child($Node2D/Navigation2D/UnderTileMap)
	#$Navigation2D.add_child($Node2D2/Navigation2D/UnderTileMap)
	
	#print($Navigation2D/NavigationPolygonInstance.get_navigation_polygon().get_vertices())
	#$Navigation2D/NavigationPolygonInstance.navpoly.get_polygon_count()
	#$NavigationPolygonInstance.navpoly = $Navigation2D/UnderTileMap.get_tileset().tile_get_navigation_polygon(0)
	#$Camera2D.make_current()
