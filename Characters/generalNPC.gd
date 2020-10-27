extends KinematicBody2D



#INVENTORY AND SKILLS AND OTHER FREQUENTLY CHANGING DATA
var skillDict
var memory = [] #NUMBER OF MEMORIES CONTROLLED BY INTELLIGENCE
var inventory = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] #inventory ID numbers, position corresponds to inventory arrangement
var resourceStats = [100, 30, 50, 20, 10] #[crystals, metal, fuel, carbon fiber, rubber] lower number means more hunger, able to trade/sell resources to others by multiplying by consumption rates
#var impulseStats = [100, 0, 100, 0, 0] #[current_health, desperation, social_stamina/lonely/socially_satiated, fear/courage, temp_personal_affinity]
var knowledgeArray = [0.05, 0.1, 0.2, 0.1, 0.05, 0.0, 0.0, 0.0, 0.0, 0.0] #[small talk, knowledgeOfSelf, gossip, news, big talk, deflect, emphasize, flatter, insult, joke]
#PERSONALITY TRAITS (CAN BE CHANGED BY TALKING OR HACKING)
var personality = [0.1, 0.55, 0.02, 0.3, 0.7] #[aggression/impulsivity, openess/curiosity, erraticness, greed/selfishness, grit/confidence]
var racismArray = [0, 0, 0, 0, 0] #[hackers, shooters, slinkers, scrappers, forkers] #higher value is more racist
var interestArray = [0.1, -0.05, 0.0, 0.1, -0.1, 0.0, 0.0, 0.1, -0.2, 0.0] #[small talk, interestInSelf, gossip, news, big talk, deflect, emphasize, flatter, insult, joke]
#FIXED STATS (ALTHOUGH THEY CAN BE CHANGED BY AUGMENTS)
var raceId = 3
var NPCid
var lilStats = [0.1, 0.1, 0.5, 0.4, 0.2] #[charisma, intelligence, attack, defense, speed]
var bigStats = [30, 120] #[current_social_stamina, maximum_HP] ##max_social_stamina == charisma*300, max_hp=defense*300
var consumptionRates = [0.0, 0.3, 0.5, 0.2, 0] #[crystals, metal, fuel, carbon fiber, rubber] #subtract every timestep from corresponding resource
#FLUCTUATING STATS
var fluctStats = [0, 0.5, 0, 40, 0, 0.5, 0.9] #[talkDamage given, desperation currently having, personal affinity with player, current HP, personal affinity with any NPC convo partner, courage, loneliness]
var prevTalkDamageReceived = 0
var NPCprevTopicId = 0
var NPCprevRhetoricId = 0
var topicId = 0
var rhetoricId = 0
var currentTarget = null
var clickedThisNPC = false
var justSentConvo = false
#TEMP STATES
enum tempState{RELAXED, WARY, HOSTILE, AFRAID, JAZZED}
var currentTempState = tempState.RELAXED
#ACTION STATES
enum actionState{TALKING, SLEEP, SEARCH, ESCAPING, ATTACK, LOCKEDON, PATHFINDING}
var currentActionState = actionState.SEARCH
#GOAL STATES
enum goalState{CRYSTALS, METAL, FUEL, CARBON, RUBBER, HEAL, SOCIALIZATION, DEFEND, MISSION, REPRODUCTION, STRENGTHEN, NOTHING}
var currentGoalState = goalState.NOTHING
var initRandRot = 0

var receivedTalkDamage = 0
var rotation_dir = 0
var tempRotation = 0
var velocity = Vector2(0,0)
var prevPosition
var detectUpDownLeftRight = [false, false, false, false]

var navSpeed = lilStats[4]*300.0 #speed*300
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
		if distance <= distance_to_next and distance > 0.0:
			global_position = start_point.linear_interpolate(path[0], distance/distance_to_next) #+Vector2(rand_range(-30, 30), rand_range(-30, 30))
			if currentTarget == null or str(currentTarget) == "[Deleted Object]":
				break
			else:
				velocity = (currentTarget.global_position-self.global_position).normalized()
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

		navSpeed = lilStats[4]*390+40
		get_node("BigSensoryRayCast2D").set_deferred("monitoring", false)
		new_path = self.get_parent().get_parent().get_simple_path(self.global_position, self.currentTarget.global_position, true)
	elif currentActionState == actionState.TALKING or currentActionState == actionState.LOCKEDON:
		pass
	elif currentActionState == actionState.ESCAPING:
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
		new_path = self.get_parent().get_parent().get_simple_path(self.global_position, self.global_position+20*randomPositionChange, true)
	
	else:

		navSpeed = lilStats[4]*390
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
	self.path = new_path 
#signal displayStatPopUp(data_to_pass_up)

func _on_Personality_mouse_entered(rownode):
	var tempName
	for child in rownode.get_children():
		if child.text.substr(0,1) == "-":
			tempName = child.text.substr(2,3)+"-"+child.text.substr(3)
		else:
			tempName = child.text.substr(0,1)+"-"+child.text.substr(2)
		child.text = child.get_name()
		child.set_name(tempName)


func _on_Personality_mouse_exited(rownode):
	var tempName
	for child in rownode.get_children():
		tempName = child.text
		if child.get_name().substr(0,1) == "-":
			child.text = child.get_name().substr(2,3)+"."+child.get_name().substr(3)
		else:
			child.text = child.get_name().substr(0,1)+"."+child.get_name().substr(2)
		child.set_name(tempName)




func _ready():
	$StatDisplay/VBoxContainer/Personality.connect("mouse_entered", self, "_on_Personality_mouse_entered", [$StatDisplay/VBoxContainer/Personality])
	$StatDisplay/VBoxContainer/Personality.connect("mouse_exited", self, "_on_Personality_mouse_exited", [$StatDisplay/VBoxContainer/Personality])
	$StatDisplay/VBoxContainer/Stats.connect("mouse_entered", self, "_on_Personality_mouse_entered", [$StatDisplay/VBoxContainer/Stats])
	$StatDisplay/VBoxContainer/Stats.connect("mouse_exited", self, "_on_Personality_mouse_exited", [$StatDisplay/VBoxContainer/Stats])
	$StatDisplay/VBoxContainer/Interests.connect("mouse_entered", self, "_on_Personality_mouse_entered", [$StatDisplay/VBoxContainer/Interests])
	$StatDisplay/VBoxContainer/Interests.connect("mouse_exited", self, "_on_Personality_mouse_exited", [$StatDisplay/VBoxContainer/Interests])
	$StatDisplay/VBoxContainer/ConsumptionRates.connect("mouse_entered", self, "_on_Personality_mouse_entered", [$StatDisplay/VBoxContainer/ConsumptionRates])
	$StatDisplay/VBoxContainer/ConsumptionRates.connect("mouse_exited", self, "_on_Personality_mouse_exited", [$StatDisplay/VBoxContainer/ConsumptionRates])
	$StatDisplay/VBoxContainer/Knowledge.connect("mouse_entered", self, "_on_Personality_mouse_entered", [$StatDisplay/VBoxContainer/Knowledge])
	$StatDisplay/VBoxContainer/Knowledge.connect("mouse_exited", self, "_on_Personality_mouse_exited", [$StatDisplay/VBoxContainer/Knowledge])
	#get_node("../../../PlayerNode").connect("showNPCstats", self, "_on_Personality_mouse_entered", [$StatDisplay/VBoxContainer/Knowledge])
	#randomize individual
	for i in range(5):
		randomize()
		personality[i] = clamp(personality[i]+rand_range(-0.3, 0.3), 0, 1)+0.00001
		$StatDisplay/VBoxContainer/Personality.get_child(i).text = str(personality[i])
	for i in range(5):
		randomize()
		lilStats[i] = clamp(lilStats[i]+rand_range(-0.2, 0.2), 0, 1)+0.00001
		$StatDisplay/VBoxContainer/Stats.get_child(i).text = str(lilStats[i])
	for i in range(5):
		randomize()
		interestArray[i] = interestArray[i]+rand_range(-0.4, 0.4)
		#interestArray[i] = clamp(interestArray[i]+rand_range(-0.4, 0.4), 0, 1)+0.00001
		$StatDisplay/VBoxContainer/Interests.get_child(i).text = str(interestArray[i])
	for i in range(5):
		randomize()
		knowledgeArray[i]+rand_range(-0.2, 0.2)
		#knowledgeArray[i] = clamp(knowledgeArray[i]+rand_range(-0.2, 0.2), 0, 1)+0.00001
		$StatDisplay/VBoxContainer/Knowledge.get_child(i).text = str(knowledgeArray[i])
	for i in range(5):
		randomize()
		consumptionRates[i] = clamp(consumptionRates[i]+rand_range(-0.3, 0.3), 0, 1)+0.00001
		$StatDisplay/VBoxContainer/ConsumptionRates.get_child(i).text = str(consumptionRates[i])
	$Timer.wait_time -= lilStats[4] #speed mitigates timer speed
	currentActionState = actionState.SEARCH
	self.currentTarget = self
	velocity = (currentTarget.global_position-self.global_position).normalized()
	$AnimationPlayer.play("RayCastAnim")
	prevPosition = self.global_position

func _physics_process(delta):
	if currentActionState == actionState.TALKING:
		modulate = Color(1, 1, 1)
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
		modulate = Color(0, 1, 0)
		velocity = Vector2(0, 0)
	elif currentActionState == actionState.ESCAPING:
		modulate = Color(0,0,1)
		move_along_path(navSpeed*1.2*delta)
#		if self.global_position.distance_to(self.prevPosition) < 1:
#			print("ESCAPING TO SEARCH")
#			currentActionState = actionState.SEARCH
#			moveNPC()


#pick up item, receive player interfacesignal and convos
func _on_Area2D_area_entered(area):
	var ownerOfReceivedSignal = area.get_parent()
	if area.is_in_group("resource"):
		#print('OBTAINED RESOURCE')
		if ownerOfReceivedSignal.get_name() == "Crystal":
			resourceStats[0] += rand_range(10,90)
		elif ownerOfReceivedSignal.get_name() == "Metal":
			resourceStats[1] += rand_range(10,90)
		elif ownerOfReceivedSignal.get_name() == "Fuel":
			resourceStats[2] += rand_range(10,90)
		elif ownerOfReceivedSignal.get_name() == "Carbon":
			resourceStats[3] += rand_range(10,90)
		elif ownerOfReceivedSignal.get_name() == "Rubber":
			resourceStats[4] += rand_range(10,90)
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
	playerNode.get_node("ConvoNode").position = Vector2(40, -40)
	playerNode.get_node("ConvoNode").scale = Vector2(1, 1)
	playerNode.get_node("ConvoNode").modulate = Color(1, 1, 1, 0.8)
	#print(prevTalkDamageReceived)
	if prevTalkDamageReceived > 0:
		$ReactParticles.process_material.hue_variation = 0.6
		$ReactParticles.amount = int(self.prevTalkDamageReceived*30)
		$ReactParticles.emitting = true
		$ReactParticles.restart()
	else:
		if prevTalkDamageReceived < -0.4:
			playerNode.displayMessage("he stared at me with racist eyes...", 5)
			racismArray[playerNode.raceId] -= 0.02
		$ReactParticles.process_material.hue_variation = 0.3
		$ReactParticles.amount = int(self.prevTalkDamageReceived*30)
		$ReactParticles.emitting = true
		$ReactParticles.restart()
	currentTarget = playerNode
	sendConvoBubble()

func calculateAttackDecision(playerNode):
	calculateDesperation()
	var attackOrNot = ((personality[0]+personality[3]*rand_range(-0.25,0.25)+personality[4])+(racismArray[playerNode.raceId]+fluctStats[2])*lilStats[3])*2+fluctStats[1]
	#print("attackOrNot "+str(attackOrNot))
	if currentTempState == tempState.HOSTILE or currentGoalState == goalState.STRENGTHEN:
		if attackOrNot > 2:
			modulate = Color(1,0,0,1)
			NPCexitTalkSession(actionState.ATTACK)
		else:
			calculateTalkDecision(playerNode)
	elif currentTempState == tempState.AFRAID:
		if attackOrNot > 5:
			modulate = Color(1,0,0,1)
			NPCexitTalkSession(actionState.ATTACK)
		else:
			calculateTalkDecision(playerNode)
	else:
		if attackOrNot > 3:
			modulate = Color(1,0,0,1)
			NPCexitTalkSession(actionState.ATTACK)
		else:
			calculateTalkDecision(playerNode)

func calculateTalkDecision(playerNode):
	#sum curiousity + charisma + personal affinity + desperation + intelligence + prevTalkDamageReceived - racism - selfishness + rand(erracticness)
	var talkOrNot = (personality[1]+lilStats[2]+fluctStats[2]+lilStats[1]+fluctStats[1]+prevTalkDamageReceived-racismArray[playerNode.raceId]-personality[3])+rand_range(-personality[2], personality[2])
	#print("talkOrNot "+str(talkOrNot))
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
		if talkOrNot > 1.2:
			calculateWhatToTalkAbout()
		else:
			playerNode.NPCsThatAreInterestedInThisPlayer -= 1
			NPCexitTalkSession(actionState.SEARCH)

func calculateWhatToTalkAbout():
	var prevTopicId = topicId
	var prevRhetoricId = rhetoricId
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
		topicId = 0
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
		rhetoricId = 0
	print("NPC sends topicId: " + str(topicId))
	print("NPC sends rhetoricId: " + str(rhetoricId))
	currentActionState = actionState.TALKING
	$ConvoNode/ConvoBubble/Topic.get_child(prevTopicId).visible = false
	$ConvoNode/ConvoBubble/Topic.get_child(topicId).visible = true
	$ConvoNode/ConvoBubble/Rhetoric.get_child(prevRhetoricId).visible = false
	$ConvoNode/ConvoBubble/Rhetoric.get_child(rhetoricId).visible = true
	sendConvoBubble()

func sendConvoBubble():
	$ConvoNode.set_deferred("monitorable", true)
	$ConvoNode.visible = true
	$ConvoNode.modulate = Color(1,1,1,1)
	$Tween.interpolate_property($ConvoNode, "global_position", self.global_position+Vector2(40,-40), currentTarget.global_position, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$Tween.start()
	justSentConvo = true

func calculateDesperation():
	var dmgPercent = 1-fluctStats[3]/bigStats[1]
	fluctStats[1] = (dmgPercent+fluctStats[1]+personality[3])/(lilStats[4]+lilStats[2]+personality[4])
	#print("DESPERATION: " + str(fluctStats[1]))

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
	

static func sum_array(array):
	var sum = 0.0
	for element in array:
		sum += element
	return sum

func bodyEntersSensoryArea(body):
	if body.is_in_group("NPC"):
		if currentGoalState == goalState.SOCIALIZATION and currentActionState != actionState.PATHFINDING:
			currentTarget = body
			calculateTalkDecision(currentTarget)
	elif body.is_in_group("player"):
		if currentActionState != actionState.LOCKEDON and currentActionState != actionState.TALKING:
			if currentActionState == actionState.ESCAPING:
				print("SPOTTED PLAYER RUN AWAY")
			else:
				currentTarget = body
				calculateAttackDecision(currentTarget)
		

func _on_LookUpArea_body_entered(body):
	if body.is_in_group("tilemap"):
		detectUpDownLeftRight[0] = true
	else:
		bodyEntersSensoryArea(body)

func _on_LookDownArea_body_entered(body):
	if body.is_in_group("tilemap"):
		detectUpDownLeftRight[1] = true
	else:
		bodyEntersSensoryArea(body)

func _on_LookLeftArea_body_entered(body):
	if body.is_in_group("tilemap"):
		detectUpDownLeftRight[2] = true
	else:
		bodyEntersSensoryArea(body)

func _on_LookRightArea_body_entered(body):
	if body.is_in_group("tilemap"):
		detectUpDownLeftRight[3] = true
	else:
		bodyEntersSensoryArea(body)

func _on_LookUpArea_body_exited(body):
	if body.is_in_group("tilemap"):
		detectUpDownLeftRight[0] = false
	if body.is_in_group("player"):
		body.NPCsThatAreInterestedInThisPlayer -= 1
		NPCexitTalkSession(actionState.SEARCH)
	if body.is_in_group("NPC") and currentActionState == actionState.TALKING:
		NPCexitTalkSession(actionState.SEARCH)

func _on_LookDownArea_body_exited(body):
	if body.is_in_group("tilemap"):
		detectUpDownLeftRight[1] = false
	if body.is_in_group("player"):
		body.NPCsThatAreInterestedInThisPlayer -= 1
		NPCexitTalkSession(actionState.SEARCH)
	if body.is_in_group("NPC") and currentActionState == actionState.TALKING:
		NPCexitTalkSession(actionState.SEARCH)

func _on_LookLeftArea_body_exited(body):
	if body.is_in_group("tilemap"):
		detectUpDownLeftRight[2] = false
	if body.is_in_group("player"):
		body.NPCsThatAreInterestedInThisPlayer -= 1
		NPCexitTalkSession(actionState.SEARCH)
	if body.is_in_group("NPC") and currentActionState == actionState.TALKING:
		NPCexitTalkSession(actionState.SEARCH)

func _on_LookRightArea_body_exited(body):
	if body.is_in_group("tilemap"):
		detectUpDownLeftRight[3] = false
	if body.is_in_group("player"):
		body.NPCsThatAreInterestedInThisPlayer -= 1
		NPCexitTalkSession(actionState.SEARCH)
	if body.is_in_group("NPC") and currentActionState == actionState.TALKING:
		NPCexitTalkSession(actionState.SEARCH)

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
	if area.is_in_group("player") and ownerOfReceivedSignal.currentPlayerState != ownerOfReceivedSignal.possiblePlayerStates.TALKING:
		if str(currentTarget) != "[Deleted Object]":
#			print(ownerOfReceivedSignal.NPCsThatAreInterestedInThisPlayer)
#			print(currentTarget.get_name())
#			print(ownerOfReceivedSignal.get_name())
			ownerOfReceivedSignal.NPCsThatAreInterestedInThisPlayer += 1
			#print("FOUND PLAYER")
			currentTarget = ownerOfReceivedSignal
			currentActionState = actionState.PATHFINDING
			moveNPC()
#			if ownerOfReceivedSignal.NPCsThatAreInterestedInThisPlayer < 5:
#				ownerOfReceivedSignal.NPCsThatAreInterestedInThisPlayer += 1
#				print("FOUND PLAYER")
#				currentTarget = ownerOfReceivedSignal
#				currentActionState = actionState.PATHFINDING
#				moveNPC()
#	if area.is_in_group("entrance"):
#		memory.append(area.get_parent())

func _on_Area2D_input_event(viewport, event, shape_idx):
	if clickedThisNPC == false:
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
		if currentActionState == actionState.ESCAPING:
			print("ESCAPING")
		if currentActionState == actionState.ATTACK:
			print("ATTACK")
		if currentActionState == actionState.LOCKEDON:
			print("LOCKEDON")
		if currentActionState == actionState.SLEEP:
			print("SLEEP")
		print("THIS NPC's detectUpDownLeftRight: "+str(detectUpDownLeftRight))
		print("THIS NPC'S velocity: " + str(self.velocity))
		print("DIFFERENCE BETWEEN LAST AND CURRENT POSITION: " + str(self.global_transform.origin.distance_to(self.prevPosition)))
		print("inventory: " + str(inventory))
		print("resourceStats: "+ str(resourceStats))
		print("knowledgeArray: "+str(knowledgeArray))
		print("personality: "+str(personality))
		print("racismArray: "+str(racismArray))
		print("interestArray: "+str(interestArray))
		print("raceId: "+str(raceId))
		print("lilStats: "+str(lilStats))
		print("bigStats"+str(bigStats))
		print("consumptionRates: "+str(consumptionRates))
		print("fluctStats: "+str(fluctStats))
		print("NPCid: " +str(NPCid))
		clickedThisNPC = true

func _on_Timer_timeout():
	clickedThisNPC = false
	if currentActionState != actionState.TALKING:
		if str(self.currentTarget) == "[Deleted Object]":
			self.currentTarget = self
			#velocity = (currentTarget.global_transform.origin-self.global_transform.origin).normalized()
		initRandRot = rand_range(0,360)
		$Tween.interpolate_property($BigSensoryRayCast2D, "rotation_degrees", initRandRot, initRandRot+360, 2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		$Tween.start()
		fluctStats[6] -= 0.01 #loneliness
		if bigStats[0] < lilStats[0]*250: #charisma*250==max_social_stamina
			bigStats[0] += 0.5
	else:
			pass
	self.prevPosition = self.global_position
	for i in range(5):
		resourceStats[i] -= consumptionRates[i]


func _on_ConvoBoredomTimer_timeout():
	if currentActionState == actionState.TALKING:
		if justSentConvo == false: #if 8 seconds since last convo, cancel
			var playerNode = get_tree().get_root().get_child(0).get_node("PlayerNode")
			playerNode.displayMessage("he got bored and walked away...", 5)
			playerNode.exitTalkSession(self)
			NPCexitTalkSession(actionState.ESCAPING)
		justSentConvo = false
	else:
		goalAssignment()

func react(reactionId):
	$Reactions.get_child(reactionId).visible = true
	$AnimationPlayer.play("React")
	yield( $AnimationPlayer, "animation_finished" )
	$Reactions.get_child(reactionId).visible = false

func NPCexitTalkSession(newActionState):
	$StatDisplay.visible = false
	$ConvoNode.visible = false
	$ConvoNode.set_deferred("monitorable", false)
	$BigSensoryRayCast2D.set_deferred("monitoring", true)
	self.set_deferred("monitorable", true)
	currentTarget = self
	currentActionState = newActionState
