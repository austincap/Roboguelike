extends KinematicBody2D
#var ConvoScene = preload("res://Conversation/ConvoScene.tscn")
#var convoScene = ConvoScene.instance()

#INVENTORY AND SKILLS
var skillDict
var inventory = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] #inventory ID numbers, position corresponds to inventory arrangement
var resourceStats = [100, 30, 50, 20, 10] #[crystals, metal, fuel, carbon fiber, rubber] lower number means more hunger, able to trade/sell resources to others by multiplying by consumption rates
#FIXED STATS
var lilStats = [0.2, 0.1, 0.5, 0.4, 0.2] #[charisma, intelligence, attack, defense, speed]
var bigStats = [30, 40] #[social_stamina, maximum HP]
var consumptionRates = [0.0, 0.3, 0.5, 0.2, 0] #[crystals, metal, fuel, carbon fiber, rubber] #subtract every timestep from corresponding resource
#FLUCTUATING STATS
var fluctStats = [0, 0.5, 0, 40, 0, 0, 0] #[talkDamage given, desperation currently having, personal affinity with player, current HP, personal affinity with any NPC convo partner, courage, loneliness]
var prevTalkDamageReceived = 0
var NPCprevTopicId = 0
var NPCprevRhetoricId = 0
var topicId = 0
var rhetoricId = 0
var currentTarget = null
#PERSONALITY TRAITS
var personality = [0.1, 0.55, 0.02, 0.3, 0.7] #[general aggression, openess/curiosity, erraticness, greed/selfishness, grit]
var racismArray = [0, 0, 0, 0, 0] #[hackers, shooters, slinkers, scrappers, forkers] #higher value is more racist
var knowledgeArray = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.2, 0.4, 0.0, 0.0] #[small talk, you, advice, tribal gossip, big talk, deflect, emphasize, flatter, insult, joke]
var interestArray = [0.1, 0.15, -0.5, 0.0, 0.3, 0.8, 0.7, 0.6, 0.0, 0.0] #[small talk, you, advice, tribal gossip, big talk, deflect, emphasize, flatter, insult, joke]
#TEMP STATES
enum tempState{RELAXED, WARY, HOSTILE, AFRAID, JAZZED}
var currentTempState = tempState.RELAXED
#ACTION STATES
enum actionState{TALKING, SLEEP, SEARCH, MOVING, ATTACK, LOCKEDON, PATHFINDING}
var currentActionState = actionState.SEARCH
#GOAL STATES
enum goalState{CRYSTALS, METAL, FUEL, CARBON, RUBBER, HEAL, SOCIALIZATION, REST, MISSION, REPRODUCTION, STRENGTHEN, NOTHING}
var currentGoalState = goalState.NOTHING
var initRandRot = 0

var receivedTalkDamage = 0
var rotation_dir = 0
var tempRotation = 0
var velocity = Vector2(0,0)
var speed = 50
var prevPosition
var detectUpDownLeftRight = [false, false, false, false]


var navSpeed := 100.0
var path := PoolVector2Array() setget set_path

func set_path(value: PoolVector2Array) -> void:
	path = value
	if value.size() == 0:
		return
	#currentActionState = actionState.PATHFINDING

func move_along_path(distance: float) -> void:
	var start_point := global_position
	for i in range(path.size()):
		var distance_to_next := start_point.distance_to(path[0])
		if distance <= distance_to_next and distance >= 0.0:
			global_position = start_point.linear_interpolate(path[0], distance/distance_to_next) #+Vector2(rand_range(-30, 30), rand_range(-30, 30))
			if currentTarget == null or str(currentTarget) == "[Deleted Object]":
				break
			else:
				#velocity = (currentTarget.global_position-self.global_transform.origin).normalized()
				global_position = start_point.linear_interpolate(path[0], distance/(distance_to_next)) #+Vector2(rand_range(-30, 30), rand_range(-30, 30))
				break
		elif distance < 0.0:
			global_position = path[0]
			currentActionState = actionState.SEARCH
			break
		distance -= distance_to_next
		start_point = path[0]
		#print(path[0])
		path.remove(0)

func moveNPC():
	var new_path
	if currentActionState == actionState.PATHFINDING:
		$Polygon2D.modulate = Color(1, 0, 0)
		get_node("BigSensoryRayCast2D").set_deferred("monitoring", false)
		new_path = self.get_parent().get_parent().get_simple_path(self.global_position, self.currentTarget.global_position, true)
	else:
		$Polygon2D.modulate = Color(0, 1, 0)
		get_node("BigSensoryRayCast2D").set_deferred("monitoring", true)
		var randomPositionChange
		randomize()
		if randf() < 0.25:
			randomPositionChange = Vector2(rand_range(-100,-60), rand_range(-100,-60))
		elif randf() < 0.5:
			randomPositionChange = Vector2(rand_range(-100,-60), rand_range(60,100))
		elif randf() < 0.75:
			randomPositionChange = Vector2(rand_range(60,100), rand_range(-100,-60))
		elif randf() < 1:
			randomPositionChange = Vector2(rand_range(60,100), rand_range(60,100))
		new_path = self.get_parent().get_parent().get_simple_path(self.global_position, self.global_position+2*randomPositionChange, true)
	$Line2D.points = new_path
	self.path = new_path 

func _ready():
	currentActionState = actionState.SEARCH
	self.currentTarget = self
	velocity = (currentTarget.global_position-self.global_transform.origin).normalized()
	$AnimationPlayer.play("RayCastAnim")
	prevPosition = self.global_position

func _physics_process(delta):
	if currentActionState == actionState.TALKING:
		$Polygon2D.modulate = Color(1, 1, 1)
		pass
	elif currentActionState == actionState.PATHFINDING:
		move_along_path(navSpeed*delta)
		if self.global_position.distance_to(self.prevPosition) < 5:
			#print("PATHFINDING TO SEARCH")
			currentActionState = actionState.SEARCH
			moveNPC()
	elif currentActionState == actionState.SEARCH:
		move_along_path(navSpeed*delta)
		if self.global_position.distance_to(self.prevPosition) < 3:
			#print("SEARCH TO NEW SEARCH")
			moveNPC()
	elif currentActionState == actionState.ATTACK:
		pass
	elif currentActionState == actionState.LOCKEDON:
		$Polygon2D.modulate = Color(0, 0, 1)



#pick up item, receive player interfacesignal and convos
func _on_Area2D_area_entered(area):
	var ownerOfReceivedSignal = area.get_parent()
	if area.is_in_group("resource"):
		print('OBTAINED RESOURCE')
		if ownerOfReceivedSignal.get_name() == "Fuel":
			resourceStats[2] += rand_range(10,90)
			currentActionState = actionState.SEARCH
			moveNPC()
			ownerOfReceivedSignal.queue_free()
	elif area.is_in_group("convo") and ownerOfReceivedSignal.is_in_group("player"):
		print("CONVO RECEIVED BY NPC")
		print(ownerOfReceivedSignal)
		self.prevTalkDamageReceived = ownerOfReceivedSignal.handleConvoBubble(self, ownerOfReceivedSignal)
		fluctStats[2] += prevTalkDamageReceived #add talkDamageDealt to affinity
		#ownerOfReceivedSignal.genericReactionToConvoBubble(ownerOfReceivedSignal, self)
		NPCreactionToConvoBubble(ownerOfReceivedSignal)

func NPCreactionToConvoBubble(playerNode):
	#return convo node to player
	playerNode.get_node("AnimationPlayer").play("returnConvoNode")
	yield( playerNode.get_node("AnimationPlayer"), "animation_finished" )
	playerNode.get_node("ConvoScene").position = Vector2(80, -70)
	playerNode.get_node("ConvoScene").scale = Vector2(1, 1)
	playerNode.get_node("ConvoScene").modulate = Color(1, 1, 1, 0.8)
	#print(prevTalkDamageReceived)
	if prevTalkDamageReceived > 0:
		$ReactParticles.process_material.hue_variation = 0.6
		$ReactParticles.amount = int(self.prevTalkDamageReceived*30)
		$ReactParticles.emitting = true
		$ReactParticles.restart()
	else:
		$ReactParticles.process_material.hue_variation = 0.3
		$ReactParticles.amount = int(self.prevTalkDamageReceived*30)
		$ReactParticles.emitting = true
		$ReactParticles.restart()
	#calculateDesperation()
	#calculateAttackDecision(playerNode
	currentTarget = playerNode
	sendConvoBubble()

func calculateAttackDecision(playerNode):
	var attackOrNot = ((personality[0]+personality[3]*rand_range(-0.3,0.3)+personality[4])+(racismArray[0]+fluctStats[2])*lilStats[3])*2+fluctStats[1]
	print("attackOrNot "+str(attackOrNot))
	if currentTempState == tempState.HOSTILE or currentGoalState == goalState.STRENGTHEN:
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
			playerNode.NPCsThatAreInterestedInThisPlayer -= 1
			NPCexitTalkSession(actionState.SEARCH)
	elif currentTempState == tempState.WARY or currentGoalState == goalState.MISSION:
		if talkOrNot > 4:
			calculateWhatToTalkAbout()
		else:
			playerNode.NPCsThatAreInterestedInThisPlayer -= 1
			NPCexitTalkSession(actionState.SEARCH)
	else:
		if talkOrNot > 1.5:
			calculateWhatToTalkAbout()
		else:
			playerNode.NPCsThatAreInterestedInThisPlayer -= 1
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
	print("NPC sends topicId: " + str(topicId))
	print("NPC sends rhetoricId: " + str(rhetoricId))
	sendConvoBubble()

func sendConvoBubble():
	$ConvoScene.modulate = Color(1,1,1,1)
	$Tween.interpolate_property($ConvoScene, "global_position", self.global_position+Vector2(80,-70), currentTarget.global_position, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()

func calculateDesperation():
	var dmgPercent = 1-fluctStats[3]/bigStats[1]
	fluctStats[1] = (dmgPercent+fluctStats[1]+personality[3])/(lilStats[4]+lilStats[2]+personality[4])

func goalAssignment():
	calculateDesperation()
	#get all fluctuating stats out of critical level
	for i in range(4):
		if resourceStats[i] < 10:
			currentGoalState = i
			return
	if fluctStats[3]/bigStats[0] < 0.4: #dmg percent
		currentGoalState = goalState.HEAL
		return
	if fluctStats[6] > 0.4: #loneliness
		currentGoalState = goalState.SOCIALIZATION
	#start executing missions
	

#pathfinding
#func _on_SensoryRayCast2D_body_entered(body):
#	if body.is_in_group("player"):
#		if body.currentPlayerState != body.possiblePlayerStates.TALKING:
#			currentTarget = body
#			print(self.get_parent().get_name())
#			print("player within NPCs attack range")
#			self.get_parent().moveNPC(self)
#			self.currentActionState = self.actionState.PATHFINDING

static func sum_array(array):
	var sum = 0.0
	for element in array:
		sum += element
	return sum

func _on_LookUpArea_body_entered(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[0] = true
	if body.is_in_group("player"):
		currentTarget = body
		$Tween.interpolate_property($InterfaceSignal, "global_position", self.global_position, currentTarget.global_position, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween.start()

func _on_LookDownArea_body_entered(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[1] = true
	if body.is_in_group("player"):
		currentTarget = body
		$Tween.interpolate_property($InterfaceSignal, "global_position", self.global_position, currentTarget.global_position, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween.start()

func _on_LookLeftArea_body_entered(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[2] = true
	if body.is_in_group("player"):
		currentTarget = body
		$Tween.interpolate_property($InterfaceSignal, "global_position", self.global_position, currentTarget.global_position, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween.start()

func _on_LookRightArea_body_entered(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[3] = true
	if body.is_in_group("player"):
		currentTarget = body
		$Tween.interpolate_property($InterfaceSignal, "global_position", self.global_position, currentTarget.global_position, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		$Tween.start()

func _on_LookUpArea_body_exited(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[0] = false
	if body.is_in_group("player"):
		body.NPCsThatAreInterestedInThisPlayer -= 1
		currentActionState = actionState.SEARCH

func _on_LookDownArea_body_exited(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[1] = false
	if body.is_in_group("player"):
		body.NPCsThatAreInterestedInThisPlayer -= 1
		currentActionState = actionState.SEARCH

func _on_LookLeftArea_body_exited(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[2] = false
	if body.is_in_group("player"):
		body.NPCsThatAreInterestedInThisPlayer -= 1
		currentActionState = actionState.SEARCH

func _on_LookRightArea_body_exited(body):
	if str(body.get_name()) == "TileMap" or body.is_in_group("tilemap") or body.is_in_group("NPC"):
		detectUpDownLeftRight[3] = false
	if body.is_in_group("player"):
		body.NPCsThatAreInterestedInThisPlayer -= 1
		currentActionState = actionState.SEARCH

#resource and player detection
func _on_BigSensoryRayCast2D_area_entered(area):
	var ownerOfReceivedSignal = area.get_parent()
	if area.is_in_group("resource"):
		#PUT GOAL STATE STUFF HERE
		#
		currentTarget = area
		#print("FOUND RESOURCE")
		currentActionState = actionState.PATHFINDING
		moveNPC()
	if area.is_in_group("player"):
		if str(currentTarget) != "[Deleted Object]":
#			print(ownerOfReceivedSignal.NPCsThatAreInterestedInThisPlayer)
#			print(currentTarget.get_name())
#			print(ownerOfReceivedSignal.get_name())
			ownerOfReceivedSignal.NPCsThatAreInterestedInThisPlayer += 1
			print("FOUND PLAYER")
			currentTarget = ownerOfReceivedSignal
			currentActionState = actionState.PATHFINDING
			moveNPC()
#			if ownerOfReceivedSignal.NPCsThatAreInterestedInThisPlayer < 5:
#				ownerOfReceivedSignal.NPCsThatAreInterestedInThisPlayer += 1
#				print("FOUND PLAYER")
#				currentTarget = ownerOfReceivedSignal
#				currentActionState = actionState.PATHFINDING
#				moveNPC()

func _on_Area2D_input_event(viewport, event, shape_idx):
	if str(self.currentTarget) == "[Deleted Object]":
		return
	print("THIS NPC's currentTarget: " + str(self.currentTarget.get_name()))
	print("THIS NPC's state: ")
	if currentActionState == actionState.PATHFINDING:
		print("PATHFINDING")
	if currentActionState == actionState.SEARCH:
		print("SEARCH")
	if currentActionState == actionState.TALKING:
		print("TALKING")
	if currentActionState == actionState.MOVING:
		print("MOVING")
	if currentActionState == actionState.ATTACK:
		print("ATTACK")
	if currentActionState == actionState.LOCKEDON:
		print("LOCKEDON")
	if currentActionState == actionState.SLEEP:
		print("SLEEP")
	print("THIS NPC's detectUpDownLeftRight: ")
	print(detectUpDownLeftRight)
	print("THIS NPC'S velocity: " + str(self.velocity))
	print("DIFFERENCE BETWEEN LAST AND CURRENT POSITION: " + str(self.global_transform.origin.distance_to(self.prevPosition)))

func _on_Timer_timeout():
	if currentActionState != actionState.TALKING:
		if str(self.currentTarget) == "[Deleted Object]":
			self.currentTarget = self
			#velocity = (currentTarget.global_transform.origin-self.global_transform.origin).normalized()
		initRandRot = rand_range(0,360)
		$Tween.interpolate_property($BigSensoryRayCast2D, "rotation_degrees", initRandRot, initRandRot+360, 2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		$Tween.start()
	else:
		pass
	prevPosition = self.global_transform.origin
	for i in range(5):
		resourceStats[i] -= consumptionRates[i]

func react(reactionId):
	$Reactions.get_child(reactionId).visible = true
	$AnimationPlayer.play("React")
	yield( $AnimationPlayer, "animation_finished" )
	$Reactions.get_child(reactionId).visible = false

func NPCexitTalkSession(newActionState):
	get_node("ConvoScene").set_deferred("monitorable", false)
	get_node("BigSensoryRayCast2D").set_deferred("monitoring", true)
	$ConvoScene.visible = false
	self.currentActionState = newActionState
