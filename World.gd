extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func moveNPC(NPCnode):
	var new_path = $Navigation2D.get_simple_path(NPCnode.global_position, NPCnode.currentTarget, true)
	$Line2D.points = new_path
	NPCnode.path = new_path 
