extends "res://Characters/generalNPC.gd"

var rapportDict = {"player":0}

#SCRAPPER
func _ready():
	consumptionRates = [0.33, 0.1, 0.34, 0.02, 0.01] # higher base demand of crystals and fuel
	lilStats = [0.05, 0.36, 0.05, 0.09, 0.37] #higher base intelligence and speed
	for i in range(5):
		randomize()
		consumptionRates[i] = clamp(consumptionRates[i]+rand_range(-0.1, 0.1), 0, 1)+0.00001
		$StatDisplay/VBoxContainer/ConsumptionRates.get_child(i).text = str(consumptionRates[i])
	for i in range(5):
		randomize()
		lilStats[i] = clamp(lilStats[i]+rand_range(-0.1, 0.1), 0, 1)+0.00001
		$StatDisplay/VBoxContainer/Stats.get_child(i).text = str(lilStats[i])
	raceId = 3

func _physics_process(delta):
	if currentActionState == actionState.ATTACK:
		pass
		#$LaserGunSprite.fire_laser(currentTarget)
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

