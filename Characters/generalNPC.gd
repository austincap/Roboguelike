extends KinematicBody2D
var Selected = preload("res://Characters/Selected.tscn")
var selected = Selected.instance()
var ConvoScene = preload("res://Conversation/ConvoScene.tscn")
var convoScene = ConvoScene.instance()

#INVENTORY AND SKILLS
var skillDict
var inventory = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] #inventory ID numbers, position corresponds to inventory arrangement
var resourceStats = [100, 30, 50, 20, 10] #[crystals, metal, fuel, carbon fiber, rubber] lower number means more hunger, able to trade/sell resources to others by multiplying by consumption rates
#FIXED STATS
var lilStats = [0.2, 0.1, 0.5, 0.4, 0.2] #[charisma, intelligence, attack, defense, speed]
var bigStats = [30, 40] #[social_stamina, maximum HP]
var consumptionRates = [0.0, 0.3, 0.5, 0.2, 0] #[crystals, metal, fuel, carbon fiber, rubber] #subtract every timestep from corresponding resource
#FLUCTUATING STATS
var fluctStats = [0, 0.5, 0, 40] #[talkDamage given, desperation currently having, personal affinity with player, current HP]
var prevTalkDamageReceived = 0
var NPCprevTopicId = 0
var NPCprevRhetoricId = 0
var topicId = 0
var rhetoricId = 0
var currentTarget
#PERSONALITY TRAITS
var personality = [0.1, 0.55, 0.02, 0.3, 0.7] #[general aggression, openess/curiosity, erraticness, greed/selfishness, grit]
var racismArray = [0, 0, 0, 0, 0] #[hackers, shooters, slinkers, scrappers, forkers] #higher value is more racist
var knowledgeArray = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.2, 0.4, 0.0, 0.0] #[small talk, local area, advice, tribal gossip, big talk, compliments, insults, expound, deflect, joke]
var interestArray = [0.1, 0.15, -0.5, 0.0, 0.3, 0.8, 0.7, 0.6, 0.0, 0.0] #[small talk, local area, advice, tribal gossip, big talk, compliments, insults, expound, deflect, joke]
#TEMP STATES
enum tempState{RELAXED, WARY, HOSTILE, AFRAID, JAZZED}
var currentTempState = tempState.RELAXED
#ACTION STATES
enum actionState{TALKING, SLEEP, SEARCH, MOVING, ATTACK, LOCKEDON}
var currentActionState = actionState.SEARCH
var justChangedState = false
var justChangedDirection = false
var initRandRot = 0
var justFound = false
var justDetectedWall = false

var receivedTalkDamage = 0
var directionVector = Vector2(0,0)
var rotation_dir = 0
var sensoryVector
var tempRotation = 0
var velocity = Vector2(0,0)
var speed = 50
var maxSpeed = 70
var prevPosition
var acceleration = Vector2(0,0)
var detectUpDownLeftRight = [false, false, false, false]


# Called when the node enters the scene tree for the first time.
func _ready():
	self.currentTarget = self.global_position
	velocity = (currentTarget-self.global_transform.origin).normalized()
	$AnimationPlayer.play("RayCastAnim")
	prevPosition = self.global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if currentActionState == actionState.TALKING:
		pass
	elif currentActionState == actionState.SLEEP:
		pass
	elif currentActionState == actionState.SEARCH:
		if detectUpDownLeftRight == [true, true, true, true]:
			velocity = Vector2(0,0)
		else:
			if detectUpDownLeftRight[0]:
				velocity += Vector2(0, 0.2)
			if detectUpDownLeftRight[1]:
				velocity += Vector2(0, -0.2)
			if detectUpDownLeftRight[2]:
				velocity += Vector2(0.2, 0)
			if detectUpDownLeftRight[3]:
				velocity += Vector2(-0.2, 0)
			self.move_and_collide(velocity * delta * speed)
	elif currentActionState == actionState.MOVING:
		if detectUpDownLeftRight[0]:
			velocity += Vector2(0, 0.2)
		if detectUpDownLeftRight[1]:
			velocity += Vector2(0, -0.2)
		if detectUpDownLeftRight[2]:
			velocity += Vector2(0.2, 0)
		if detectUpDownLeftRight[3]:
			velocity += Vector2(-0.2, 0)
#		if justDetectedWall == true:
#			pass
##			velocity = velocity.rotated(180)
##			rotation_degrees += 180
#		else:
#			velocity = velocity.rotated(tempRotation)
#			rotation_degrees += tempRotation
		self.move_and_collide(velocity * delta * speed)
#		if justChangedDirection == true:
#			velocity = (currentTarget-self.global_transform.origin).normalized()
	elif currentActionState == actionState.ATTACK:
		pass
	elif currentActionState == actionState.LOCKEDON:
		pass


#pick up item, receive player interfacesignal and convos
func _on_Area2D_area_entered(area):
	var ownerOfReceivedSignal = area.get_parent()
	if area.is_in_group("resource"):
		if ownerOfReceivedSignal.get_name() == "Fuel":
			justFound = false
			self.currentActionState = actionState.SEARCH
			ownerOfReceivedSignal.queue_free()
			#print('obtained fuel')
	elif area.is_in_group("convo") and ownerOfReceivedSignal.is_in_group("player"):
		print("CONVO RECEIVED BY NPC")
		print(ownerOfReceivedSignal)
		self.prevTalkDamageReceived = ownerOfReceivedSignal.handleConvoBubble(self)
		fluctStats[2] += prevTalkDamageReceived #add talkDamageDealt to affinity
		#ownerOfReceivedSignal.genericReactionToConvoBubble(ownerOfReceivedSignal, self)
		NPCreactionToConvoBubble(ownerOfReceivedSignal)
		
#	elif area.is_in_group("interfacesignal") and ownerOfReceivedSignal.is_in_group("player") and ownerOfReceivedSignal.lockedOn==false:
#		ownerOfReceivedSignal.currentTarget = self
#		print("INTERFACE SIGNAL RECEIVED")
#		react(3)
#		#self.currentActionState = actionState.TALKING
#		ownerOfReceivedSignal.currentPlayerState = ownerOfReceivedSignal.possiblePlayerStates.LOCKEDON
#		#ownerOfReceivedSignal.initiateTalkSession(self)

#func _on_Area2D_area_exited(area):
#	var ownerOfReceivedSignal = area.get_parent()
#	if area.is_in_group("interfacesignal") and ownerOfReceivedSignal.is_in_group("player"):
#		ownerOfReceivedSignal.currentPlayerState = ownerOfReceivedSignal.possiblePlayerStates.NORMAL
#		area.global_position = ownerOfReceivedSignal.global_position

func NPCreactionToConvoBubble(playerNode):
	#return convo node to player
	playerNode.get_node("AnimationPlayer").play("returnConvoNode")
	yield( playerNode.get_node("AnimationPlayer"), "animation_finished" )
	playerNode.get_node("ConvoScene").position = Vector2(80, -70)
	playerNode.get_node("ConvoScene").scale = Vector2(1, 1)
	playerNode.get_node("ConvoScene").modulate = Color(1, 1, 1, 0.8)
	print(prevTalkDamageReceived)
	if prevTalkDamageReceived > 0:
		$ReactParticles.process_material.hue_variation = 0.6
		$ReactParticles.amount = int(self.prevTalkDamageReceived*30)
		print(int(self.prevTalkDamageReceived*30))
		$ReactParticles.emitting = true
		$ReactParticles.restart()
	else:
		$ReactParticles.process_material.hue_variation = 0.3
		$ReactParticles.amount = int(self.prevTalkDamageReceived*30)
		print(int(self.prevTalkDamageReceived*30))
		$ReactParticles.emitting = true
		$ReactParticles.restart()
	#calculateDesperation()
	#calculateAttackDecision(playerNode)
	sendConvoBubble()

func calculateAttackDecision(playerNode):
	var attackOrNot = ((personality[0]+personality[3]*rand_range(-0.3,0.3)+personality[4])+(racismArray[0]+fluctStats[2])*lilStats[3])*2+fluctStats[1]
	print("attackOrNot "+str(attackOrNot))
	if currentTempState == tempState.HOSTILE:
		if attackOrNot > 2:
			NPCexitTalkSession(actionState.ATTACK)
		else:
			calculateTalkDecision(playerNode)
	elif currentTempState == tempState.AFRAID:
		if attackOrNot > 5:
			NPCexitTalkSession(actionState.ATTACK)
		else:
			calculateTalkDecision(playerNode)
	else:
		if attackOrNot > 3.5:
			NPCexitTalkSession(actionState.ATTACK)
		else:
			calculateTalkDecision(playerNode)

func calculateTalkDecision(playerNode):
	#sum curiousity + charisma + personal affinity + desperation + intelligence + prevTalkDamageReceived - racism - selfishness + rand(erracticness)
	var talkOrNot = (personality[1]+lilStats[2]+fluctStats[2]+lilStats[1]+fluctStats[1]+prevTalkDamageReceived-racismArray[playerNode.raceId]-personality[3])+rand_range(-personality[2], personality[2])
	print("talkOrNot "+str(talkOrNot))
	if currentTempState == tempState.JAZZED:
		if talkOrNot > 2:
			calculateWhatToTalkAbout()
		else:
			NPCexitTalkSession(actionState.SEARCH)
	elif currentTempState == tempState.WARY:
		if talkOrNot > 4:
			calculateWhatToTalkAbout()
		else:
			NPCexitTalkSession(actionState.SEARCH)
	else:
		if talkOrNot > 1.5:
			calculateWhatToTalkAbout()
		else:
			NPCexitTalkSession(actionState.SEARCH)

func calculateWhatToTalkAbout():
	var talkDecision = []
	var index = 0
	for topic in interestArray.slice(0, 4):
		if topic > 0:
			randomize()
			if rand_range(0, 1) < topic:
				talkDecision.append(index)
		index+=1
	if talkDecision.size() > 0:
		topicId = randi() % talkDecision.size()
	else:
		topicId = randi() % interestArray.slice(0, 4).size()
	talkDecision = []
	index = 0
	randomize()
	#if openness + rand_range(erraticness)
	if rand_range(0, 1) < personality[1]+rand_range(-personality[2], personality[2]):
		for rhetoric in interestArray.slice(5, 9):
			if rhetoric > 0:
				randomize()
				if rand_range(0, 1) < rhetoric:
					talkDecision.append(index)
			index+=1
	if talkDecision.size() > 0:
		 rhetoricId = randi() % talkDecision.size()
	else:
		rhetoricId = randi() % interestArray.slice(5, 9).size()
	print(topicId)
	print(rhetoricId)
	sendConvoBubble()

func sendConvoBubble():
	$ConvoScene.modulate = Color(1,1,1,1)
	$Tween.interpolate_property($ConvoScene, "global_position", self.global_position+Vector2(80,-70), currentTarget, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()

func calculateDesperation():
	var dmgPercent = 1-fluctStats[3]/bigStats[1]
	fluctStats[1] = (dmgPercent+fluctStats[1]+personality[3])/(lilStats[4]+lilStats[2]+personality[4])

func calculateBehavior():
	calculateDesperation()
	

#pathfinding
func _on_SensoryRayCast2D_body_entered(body):
	#print(body.get_name())
	if body.is_in_group("tilemap") == false or body.is_in_group("NPC") or str(body.get_name()) == "TileMap":
		tempRotation = $SensoryRayCast2D.rotation_degrees/2
	if body.is_in_group("player"):
		if body.currentPlayerState != body.possiblePlayerStates.TALKING:
			currentTarget = body.global_position
			$Tween.interpolate_property($InterfaceSignal, "global_position", self.global_position, currentTarget, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$Tween.start()
		#velocity = (currentTarget-self.global_transform.origin).normalized()
			

static func sum_array(array):
	var sum = 0.0
	for element in array:
		sum += element
	return sum

func _on_LookUpArea_body_entered(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[0] = true
	if body.is_in_group("player"):
		currentTarget = body.global_position
		$Tween.interpolate_property($InterfaceSignal, "global_position", self.global_position, currentTarget, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween.start()

func _on_LookDownArea_body_entered(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[1] = true
	if body.is_in_group("player"):
		currentTarget = body.global_position
		$Tween.interpolate_property($InterfaceSignal, "global_position", self.global_position, currentTarget, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween.start()

func _on_LookLeftArea_body_entered(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[2] = true
	if body.is_in_group("player"):
		currentTarget = body.global_position
		$Tween.interpolate_property($InterfaceSignal, "global_position", self.global_position, currentTarget, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween.start()

func _on_LookRightArea_body_entered(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[3] = true
	if body.is_in_group("player"):
		currentTarget = body.global_position
		$Tween.interpolate_property($InterfaceSignal, "global_position", self.global_position, currentTarget, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween.start()

func _on_LookUpArea_body_exited(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[0] = false

func _on_LookDownArea_body_exited(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[1] = false

func _on_LookLeftArea_body_exited(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[2] = false

func _on_LookRightArea_body_exited(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[3] = false


#pathfinding
func _on_SensoryRayCast2D_area_entered(area):
	#print(area.get_parent().get_name())
	if area.is_in_group("interesting"):
		#print("interesting thing found by " + self.get_name())
		calculateBehavior()


#resource locating
func _on_BigSensoryRayCast2D_area_entered(area):
	#print("FOUND " + area.get_parent().get_name())
	justFound = true
	currentActionState = actionState.MOVING
	currentTarget = area.global_position
	velocity = (currentTarget-self.global_transform.origin).normalized()

#player detection
func _on_BigSensoryRayCast2D_body_entered(body):
	#print(body.get_name())
	if body.is_in_group("player"):
		currentTarget = body.global_position

func _on_Timer_timeout():
	if self.currentActionState != actionState.TALKING:
		justChangedDirection = false
		justDetectedWall = false
		detectUpDownLeftRight = [false, false, false, false]
		#print(currentTarget)
		velocity = (currentTarget-self.global_position).normalized()
		prevPosition = self.global_position
		#$AnimationPlayer.play("BigSensor")
		if justFound == false:
			initRandRot = rand_range(0,360)
			$Tween.interpolate_property($BigSensoryRayCast2D, "rotation_degrees", initRandRot, initRandRot+360, 2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			$Tween.start()
		else:
			velocity = (currentTarget-self.global_transform.origin).normalized()
	#	$BigSensoryRayCast2D.rotation_degrees = rand_range(-180,190)
	#	$AnimationPlayer.play("BigSensor")
	#	$BigSensoryRayCast2D.rotation_degrees = rand_range(-180,190)
		calculateDesperation()
	else:
		pass

func react(reactionId):
	$Reactions.get_child(reactionId).visible = true
	$AnimationPlayer.play("React")
	yield( $AnimationPlayer, "animation_finished" )
	$Reactions.get_child(reactionId).visible = false

func NPCexitTalkSession(newActionState):
	get_node("ConvoScene").set_deferred("monitorable", false)
	$ConvoScene.visible = false
	self.currentActionState = newActionState



