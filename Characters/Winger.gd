extends "res://Characters/generalNPC.gd"
var rapportDict = {"player":0}

func _ready():
	consumptionRates = [0.04, 0.1, 0.37, 0.03, 0.35] # higher base demand of fuel and rubber
	lilStats = [0.34, 0.11, 0.06, 0.11, 0.27] #higher base charisma and speed
	for i in range(5):
		randomize()
		consumptionRates[i] = clamp(consumptionRates[i]+rand_range(-0.1, 0.1), 0, 1)+0.00001
		$StatDisplay/VBoxContainer/ConsumptionRates.get_child(i).text = str(consumptionRates[i])
	for i in range(5):
		randomize()
		lilStats[i] = clamp(lilStats[i]+rand_range(-0.1, 0.1), 0, 1)+0.00001
		$StatDisplay/VBoxContainer/Stats.get_child(i).text = str(lilStats[i])
	raceId = 1

func _physics_process(delta):
	if currentActionState == actionState.ATTACK and justUsedSkill == false:
		attack(self.currentTarget)
		yield(get_tree().create_timer(1.0), "timeout")
		justUsedSkill = true
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

func attack(target):
	print(self.global_position.direction_to(target.global_position))
	$Tween.interpolate_property(self, "global_position", self.global_position, target.global_position, 0.4, Tween.TRANS_BACK)
	$Tween.start()
	#yield(tween2, "tween_completed")
	#$AnimationPlayer.play("Attack")
	
