extends "res://Characters/generalNPC.gd"

func _physics_process(delta):
	if velocity.y >= 1:
		if abs(velocity.x) < 0.28:
			#DOWN
			$EquippedItemNode.rotation_degrees = 0
			$Sprite.frame = 0
		elif velocity.x >= 0:
			#RIGHT
			$EquippedItemNode.rotation_degrees = -90
			$Sprite.frame = 3
		else:
			#LEFT
			$EquippedItemNode.rotation_degrees = 90
			$Sprite.frame = 2
	else:
		if abs(velocity.x) < 0.28:
			#UP
			$EquippedItemNode.rotation_degrees = 180
			$Sprite.frame = 1
		elif velocity.x >= 0:
			#RIGHT
			$EquippedItemNode.rotation_degrees = -90
			$Sprite.frame = 3
		else:
			#LEFT
			$EquippedItemNode.rotation_degrees = 90
			$Sprite.frame = 2

