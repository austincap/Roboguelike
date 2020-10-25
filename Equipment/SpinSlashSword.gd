extends Node2D

export var id = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func use(direction):
	$Tween.interpolate_property(self, "rotation_degrees", 0, 360, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()

func cancel():
	$Tween.stop()
	$Tween.interpolate_property(self, "rotation_degrees", self.rotation_degrees, 0, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()



func _on_SpinSlashSword_body_entered(body):
	get_tree().get_root().get_child(0).fuckFunction(body, self.get_parent().get_parent())
