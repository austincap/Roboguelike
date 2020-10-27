extends "res://Characters/generalNPC.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	if velocity.y >= 1:
		if abs(velocity.x) < 0.28:
			#DOWN
			$EquippedItemNode.rotation_degrees = 0
			$AnimatedSprite.play("Down")
		elif velocity.x >= 0:
			#RIGHT
			$EquippedItemNode.rotation_degrees = -90
			$AnimatedSprite.play("Right")
		else:
			#LEFT
			$EquippedItemNode.rotation_degrees = 90
			$AnimatedSprite.play("Left")
	else:
		if abs(velocity.x) < 0.28:
			#UP
			$EquippedItemNode.rotation_degrees = 180
			$AnimatedSprite.play("Up")
		elif velocity.x >= 0:
			#RIGHT
			$EquippedItemNode.rotation_degrees = -90
			$AnimatedSprite.play("Right")
		else:
			#LEFT
			$EquippedItemNode.rotation_degrees = 90
			$AnimatedSprite.play("Left")
