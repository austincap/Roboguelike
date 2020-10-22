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
	$PlayerNode/Line2D.points = new_path
	$PlayerNode.path = new_path


	
#func moveNPC(NPCnode):
#	#print("NPC " + str(NPCnode) + " going from " + str(NPCnode.global_position) + " to " + str(NPCnode.currentTarget.global_position))
#	var new_path = $Navigation2D.get_simple_path(NPCnode.global_position, NPCnode.currentTarget.global_position, true)
#	$Line2D.points = new_path
#	NPCnode.path = new_path 


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
	#$Camera2D.make_current()
