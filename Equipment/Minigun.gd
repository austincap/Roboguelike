extends Node2D
export var id = 3
var heldDown = false
#var bullet = preload("res://Equipment/Bullet.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func use(direction):
	print(get_node("../..").get_name())
	print(self.get_parent().get_parent().get_name())
	var bullet = preload("res://Equipment/Bullet.tscn").instance()
	add_child(bullet)
	heldDown = true
	$Tween.start()

func cancel():
	heldDown = false




func _on_Timer_timeout():
	if heldDown:
		var bullet = preload("res://Equipment/Bullet.tscn").instance()
		add_child(bullet)
		
