extends Node2D

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != BUTTON_LEFT or not event.pressed:
		return
	var new_path = $Navigation2D.get_simple_path($PlayerNode.global_position, get_global_mouse_position())
	$Line2D.points = new_path
	$PlayerNode.path = new_path

func moveNPC(NPCnode):
	var new_path = $Navigation2D.get_simple_path(NPCnode.global_position, NPCnode.currentTarget, true)
	$Line2D.points = new_path
	NPCnode.path = new_path 
