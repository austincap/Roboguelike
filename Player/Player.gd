extends KinematicBody2D
var raceId = 0
var aimAngle = 0

enum possiblePlayerStates{TALKING, TRADING, COMBAT, HACKING, NORMAL, LOCKEDON}
var currentPlayerState = possiblePlayerStates.NORMAL


var topicId = 0
var rhetoricId = 1
var currentEquipmentIndex = 0
export var equipmentSlot = [1, 1]

#INVENTORY AND SKILLS
var inventory = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] #inventory ID numbers, position corresponds to inventory arrangement
var resourceStats = [100, 30, 50, 20, 10] #[crystals, metal, fuel, carbon fiber, rubber] when hits 0 you're dead, able to trade/sell resources to others by multiplying by consumption rates
#STATS
var lilStats = [0.2, 0.1, 0.5, 0.4, 0.2] #[charisma, intelligence, attack, defense, speed]
var bigStats = [30, 40] #[social_stamina, maxHP]
var consumptionRates = [0.0, 0.3, 0.5, 0.2, 0] #[crystals, metal, fuel, carbon fiber, rubber] #subtract every timestep from corresponding resource
var currentTarget = self
#PERSONALITY TRAITS
var personality = [0.1, 0.55, 0.02, 0.3, 0.7] #[general aggression, curiosity, erraticness, greed, grit]
#var racismArray = [0, 0, 0, 0, 0] #[hackers, shooters, slinkers, scrappers, forkers] #higher value is more racist
var knowledgeArray = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.2, 0.4, 0.0, 0.0] #[small talk, you, gossip, news, big talk, deflect, emphasize, flatter, insult, joke]
var interestArray = [0.1, 0.15, -0.5, 0.0, 0.3, 0.8, 0.7, 0.6, 0.0, 0.0] #[small talk, you, gossip, news, big talk, deflect, emphasize, flatter, insult, joke]
#TEMP STATES
enum tempState{RELAXED, WARY, HOSTILE, AFRAID, JAZZED}
var currentTempState = tempState.RELAXED
var skillUsed = false
var directionVector = Vector2(0, 0)
var deadzone = 0.15
var controllerangle = Vector2.ZERO
var xAxisRL = Input.get_joy_axis(0, JOY_AXIS_2)
var yAxisUD = Input.get_joy_axis(0 ,JOY_AXIS_3)
var prevTalkDamageReceived = 0
var signalSpeed = 200
var NPCsThatAreInterestedInThisPlayer = 0


var speed = 900.0*lilStats[4]
var path := PoolVector2Array() setget set_path

func set_path(value: PoolVector2Array) -> void:
	path = value
	if value.size() == 0:
		return
	set_process(true)

func _process(delta: float) -> void:
	move_along_path(speed*delta)

func move_along_path(distance: float) -> void:
	var start_point := position
	for i in range(path.size()):
		var distance_to_next := start_point.distance_to(path[0])
		if distance <= distance_to_next and distance >= 0.0:
			position = start_point.linear_interpolate(path[0], distance/distance_to_next)
			break
		elif distance < 0.0:
			position = path[0]
			set_process(false)
			break
		distance -= distance_to_next
		start_point = path[0]
		path.remove(0)


func _ready():
	set_physics_process(true)
	set_process(false)
	$Camera2D.make_current()
	var test = equipmentSlot[currentEquipmentIndex].instance()
	$EquippedItemNode.add_child(test)

func _physics_process(delta):
	if currentPlayerState == possiblePlayerStates.TALKING:
		if Input.is_action_pressed("interface"):
			$InterfaceSignal.global_position = currentTarget.global_position
		else:
			exitTalkSession(currentTarget)
	else:
		var xAxisRL = Input.get_joy_axis(0, JOY_AXIS_2)
		var yAxisUD = Input.get_joy_axis(0 ,JOY_AXIS_3)
		if abs(xAxisRL) > deadzone || abs(yAxisUD) > deadzone:
			controllerangle = Vector2(xAxisRL, yAxisUD).angle()
			var x = controllerangle
			$EquippedItemNode.rotation_degrees = rad2deg(controllerangle)
			$InterfaceSignal.position = signalSpeed*getShotVelocityVector()
		self.position += speed*delta*getLeftStickVector()
		if currentPlayerState == possiblePlayerStates.LOCKEDON and str(currentTarget) != "[Deleted Object]":
			$InterfaceSignal.global_position = currentTarget.global_position
			if !currentTarget.is_in_group("NPC"):
				currentPlayerState == possiblePlayerStates.NORMAL
			if Input.is_action_pressed("interface"):
				initiateTalkSession(currentTarget)
			else:
				#currentTarget.currentActionState = currentTarget.actionState.SEARCH
				currentPlayerState == possiblePlayerStates.NORMAL
	move_and_collide(delta*getLeftStickVector())

func getShotVelocityVector():
	return Vector2(Input.get_action_strength("aim_right")-Input.get_action_strength("aim_left"),  Input.get_action_strength("aim_down")-Input.get_action_strength("aim_up"))

func getLeftStickVector():
	return Vector2(Input.get_action_strength("rightmove")-Input.get_action_strength("leftmove"),  Input.get_action_strength("downmove")-Input.get_action_strength("upmove"))

func _input(event):
	if currentPlayerState == possiblePlayerStates.NORMAL or currentPlayerState == possiblePlayerStates.COMBAT:
		if event.is_action_released("rt"):
			$EquippedItemNode.get_child(0).use(getShotVelocityVector())
		if event.is_action_released("x"):
			changeEquippedItem(-1)
		if event.is_action_released("y"):
			changeEquippedItem(1)
		if event.is_action_pressed("downmove"):
			$EquippedItemNode.rotation_degrees = 90
			$Sprite.frame = 0
		if event.is_action_pressed("upmove"):
			$EquippedItemNode.rotation_degrees = -90
			$Sprite.frame = 1
		if event.is_action_pressed("rightmove"):
			$EquippedItemNode.rotation_degrees = 0
			$Sprite.frame = 3
		if event.is_action_pressed("leftmove"):
			$EquippedItemNode.rotation_degrees = 180
			$Sprite.frame = 2
		if event.is_action_released("quicksave"):
			var packed_scene = PackedScene.new()
			packed_scene.pack(get_tree().get_current_scene())
			ResourceSaver.save("res://savedscene.tscn", packed_scene)
		if event.is_action_released("quickload"):
			var packed_scene = load("res://savedscene.tscn")
			var my_scene = packed_scene.instance()
			add_child(my_scene)
	elif currentPlayerState == possiblePlayerStates.LOCKEDON:
		if !event.is_action_pressed("interface"):
			if event.is_action_pressed("downmove"):
				currentPlayerState = possiblePlayerStates.NORMAL
			if event.is_action_pressed("upmove"):
				currentPlayerState = possiblePlayerStates.NORMAL
			if event.is_action_pressed("rightmove"):
				currentPlayerState = possiblePlayerStates.NORMAL
			if event.is_action_pressed("leftmove"):
				currentPlayerState = possiblePlayerStates.NORMAL
	elif currentPlayerState == possiblePlayerStates.TALKING:
		if event.is_action_pressed("downmove"):
			changeTopicOrRhetoric(1)
		if event.is_action_pressed("upmove"):
			changeTopicOrRhetoric(0)
		if event.is_action_pressed("rightmove"):
			changeTopicOrRhetoric(3)
		if event.is_action_pressed("leftmove"):
			changeTopicOrRhetoric(2)
		if event.is_action_released("rt"):
			if bigStats[0] > 2: #if some social_stamina left can still talk
				$ConvoNode.modulate = Color(1,1,1,1)
				$SkillTween.interpolate_property($ConvoNode, "global_position", self.global_position+Vector2(40,-40), currentTarget.global_position, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
				$SkillTween.start()
			else:
				$Messages.text = "Not enough social stamina to talk"
				currentPlayerState = possiblePlayerStates.NORMAL

func initiateTalkSession(NPCnode):
	currentPlayerState = possiblePlayerStates.TALKING
	NPCnode.currentTarget = self
	NPCnode.currentActionState = NPCnode.actionState.TALKING
	get_node("ConvoNode").set_deferred("monitorable", true)
	self.set_deferred("monitorable", false)
	NPCnode.set_deferred("monitorable", false)
	$ConvoNode.visible = true
	NPCnode.get_node("ConvoNode").visible = true
	NPCnode.get_node("ConvoNode").set_deferred("monitorable", true)
	$InterfaceSignal.global_position = currentTarget.global_position
	$InterfaceSignal/Particles2D.process_material.initial_velocity = 300
	print('-----------------talk session initiated')

func exitTalkSession(NPCnode):
	$InterfaceSignal.global_position = self.global_position
	$InterfaceSignal/Particles2D.process_material.initial_velocity = 150
	get_node("ConvoNode").set_deferred("monitorable", false)
	self.set_deferred("monitorable", true)
	$ConvoNode.visible = false
	NPCnode.NPCexitTalkSession(NPCnode.actionState.SEARCH)
	currentPlayerState = possiblePlayerStates.NORMAL
	print('-----------------talk session ended')

func handleConvoBubble(receiverNode, senderNode):
	#topics are clamped between 0 and 2
	var talkDamageDealt = 0
	if senderNode.topicId == 0: #small talk
		senderNode.bigStats[0] -= 1 #social stamina cost 1
		talkDamageDealt = clamp((senderNode.lilStats[0]-receiverNode.lilStats[1]), 0, 1) #smalltalk = player charisma- NPC openness 
	elif senderNode.topicId == 1: #you
		senderNode.bigStats[0] -= 1 #social stamina cost 1 
		talkDamageDealt = clamp((receiverNode.personality[3]+receiverNode.interestArray[senderNode.topicId]-(1-senderNode.knowledgeArray[senderNode.topicId])), 0, 1)
	elif senderNode.topicId == 2: #gossip
		senderNode.bigStats[0] -= 2 #social stamina cost 2
		talkDamageDealt = clamp((receiverNode.interestArray[senderNode.topicId]*(1+senderNode.knowledgeArray[senderNode.topicId])), 0, 1)
		pass #advice = 
	elif senderNode.topicId == 3: #news
		senderNode.bigStats[0] -= 2 #social stamina cost 2
		talkDamageDealt = clamp((receiverNode.interestArray[senderNode.topicId]*(1+senderNode.knowledgeArray[senderNode.topicId])), 0, 1)
	elif senderNode.topicId == 4: #big talk
		senderNode.bigStats[0] -= 2 #social stamina cost 2
		talkDamageDealt = clamp((senderNode.personality[1]+receiverNode.interestArray[senderNode.topicId]*(1+senderNode.knowledgeArray[senderNode.topicId])), 0, 1)
	#rhetorics are clamped between -2 and 2; high risk, high reward
	var rhetoricMultiplier = 1
	if senderNode.rhetoricId == 0: #none
		senderNode.bigStats[0] -= 0 #social stamina cost 0
	elif senderNode.rhetoricId == 1: #deflect
		senderNode.bigStats[0] -= 3 #social stamina cost 3 (+3-2)
		rhetoricMultiplier = 1+clamp((-receiverNode.lilStats[0]-receiverNode.lilStats[1]+receiverNode.personality[0]+receiverNode.personality[1]+senderNode.personality[4]), -2, 2)
	elif senderNode.rhetoricId == 2: #emphasize
		senderNode.bigStats[0] -= 2 #social stamina cost 2 (+2-2)
		rhetoricMultiplier = 1+clamp((senderNode.lilStats[0]-receiverNode.lilStats[1]-receiverNode.personality[0]+senderNode.personality[3]), -2, 2)
	elif senderNode.rhetoricId == 3: #flatter
		senderNode.bigStats[0] -= 3 #social stamina cost 3 (+3-2)
		rhetoricMultiplier = 1+clamp((senderNode.lilStats[0]-receiverNode.lilStats[1]-receiverNode.personality[0]+senderNode.personality[1]+receiverNode.personality[3]), -2, 2)
	elif senderNode.rhetoricId == 4: #insult
		senderNode.bigStats[0] -= 3 #social stamina cost 3 (+3-2)
		rhetoricMultiplier = 1+clamp((-receiverNode.lilStats[0]+senderNode.lilStats[1]+senderNode.lilStats[4]+senderNode.personality[0]-receiverNode.personality[4]), -2, 2)
	elif senderNode.rhetoricId == 5: #joke
		senderNode.bigStats[0] -= 1 #social stamina cost 2 (+2-2)
		rhetoricMultiplier = 1+clamp((senderNode.lilStats[0]-receiverNode.lilStats[1]+senderNode.lilStats[4]-receiverNode.personality[0]), -2, 2)
	talkDamageDealt *= rhetoricMultiplier
	talkDamageDealt += rand_range(-receiverNode.personality[2], receiverNode.personality[2])/2
	print("MULTIPLIED: " + str(rhetoricMultiplier))
	print(senderNode.get_name() + " delivered this much talk damage: " + str(talkDamageDealt) +" to " + str(receiverNode.get_name()))
	return talkDamageDealt

func changeTopicOrRhetoric(choice):
	var nextTopicId
	var prevTopicId
	if topicId == 0:
		prevTopicId = 4
		nextTopicId = 1
	elif topicId == 4:
		nextTopicId = 0
		prevTopicId = 3
	else:
		nextTopicId = topicId + 1
		prevTopicId = topicId - 1
	var nextRhetoricId
	var prevRhetoricId
	if rhetoricId == 0:
		prevRhetoricId = 5
		nextRhetoricId = 1
	elif rhetoricId == 5:
		nextRhetoricId = 0
		prevRhetoricId = 4
	else:
		nextRhetoricId = rhetoricId + 1
		prevRhetoricId = rhetoricId - 1
	#0 up topic
	if choice == 0:
		$SkillTween.interpolate_property($ConvoNode/ConvoBubble/UpArrow, "scale", Vector2(0.25,0.25), Vector2(0.2,0.2), 0.4, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
		$SkillTween.start()
		$ConvoNode/ConvoBubble/Topic.get_child(topicId).visible = false
		$ConvoNode/ConvoBubble/Topic.get_child(nextTopicId).visible = true
		topicId = nextTopicId
	#1 down topic
	elif choice == 1:
		$SkillTween.interpolate_property($ConvoNode/ConvoBubble/DownArrow, "scale", Vector2(0.25,0.25), Vector2(0.2,0.2), 0.4, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
		$SkillTween.start()
		$ConvoNode/ConvoBubble/Topic.get_child(topicId).visible = false
		$ConvoNode/ConvoBubble/Topic.get_child(prevTopicId).visible = true
		topicId = prevTopicId
	#2 left rhetoric
	elif choice == 2:
		$SkillTween.interpolate_property($ConvoNode/ConvoBubble/LeftArrow, "scale", Vector2(0.25,0.25), Vector2(0.2,0.2), 0.4, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
		$SkillTween.start()
		$ConvoNode/ConvoBubble/Rhetoric.get_child(rhetoricId).visible = false
		$ConvoNode/ConvoBubble/Rhetoric.get_child(prevRhetoricId).visible = true
		rhetoricId = prevRhetoricId
	#3 right rhetoric
	elif choice == 3:
		$SkillTween.interpolate_property($ConvoNode/ConvoBubble/RightArrow, "scale", Vector2(0.25,0.25), Vector2(0.2,0.2), 0.4, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
		$SkillTween.start()
		$ConvoNode/ConvoBubble/Rhetoric.get_child(rhetoricId).visible = false
		$ConvoNode/ConvoBubble/Rhetoric.get_child(nextRhetoricId).visible = true
		rhetoricId = nextRhetoricId

func react(reactionId):
	$Reactions.get_child(reactionId).visible = true
	$AnimationPlayer.play("React")
	yield( $AnimationPlayer, "animation_finished" )
	$Reactions.get_child(reactionId).visible = false

func changeEquippedItem(changeDirection):
	print(currentEquipmentIndex)
	if 0 == currentEquipmentIndex:
		if changeDirection == 1:
			currentEquipmentIndex+=1
		else:
			currentEquipmentIndex = equipmentSlot.size()-1
	elif equipmentSlot.size()-1 == currentEquipmentIndex:
		if changeDirection == 1:
			currentEquipmentIndex = 0
		else:
			currentEquipmentIndex-=1
	else:
		currentEquipmentIndex+=changeDirection
	$EquippedItemNode.get_child(0).queue_free()
	var test = equipmentSlot[currentEquipmentIndex].instance()
	$EquippedItemNode.add_child(test)

func _on_SkillReturnTimer_timeout():
	skillUsed = false

#receive interface signals and convo bubbles
func _on_Area2D_area_entered(area):
	var ownerOfReceivedSignal = area.get_parent()
	#print(area.get_name())
	#print(ownerOfReceivedSignal.get_name())
	if ownerOfReceivedSignal.is_in_group("player") == false:
		if area.is_in_group("convo") and ownerOfReceivedSignal.is_in_group("NPC"):
			self.prevTalkDamageReceived = handleConvoBubble(self, ownerOfReceivedSignal)
			reactionToNPCConvoBubble(ownerOfReceivedSignal)
			if currentPlayerState != possiblePlayerStates.TALKING:
				ownerOfReceivedSignal.fluctStats[2] -= 0.2
				$Messages.text = "HEY! Listen to me!"
				$Messages.visible = true
				ownerOfReceivedSignal.react(2)
				ownerOfReceivedSignal.get_node("ReactParticles").process_material.hue_variation = 0.3
				ownerOfReceivedSignal.get_node("ReactParticles").amount = int(0.2*30)
				ownerOfReceivedSignal.get_node("ReactParticles").emitting = true
				ownerOfReceivedSignal.get_node("ReactParticles").restart()
				ownerOfReceivedSignal.NPCexitTalkSession(ownerOfReceivedSignal.actionState.SEARCH)
		elif area.is_in_group("portal"):
			var portalIndex = self.get_parent().portalArray.find(area.global_position)
			if portalIndex+1 >= self.get_parent().portalArray.size():
				self.global_position = self.get_parent().portalArray[0]+Vector2(0,40)
			else:
				self.global_position = self.get_parent().portalArray[portalIndex+1]+Vector2(0,40)
				
		elif area.is_in_group("resource"):
			#print('OBTAINED RESOURCE')
			if ownerOfReceivedSignal.get_name() == "Fuel":
				resourceStats[2] += rand_range(10,90)
			ownerOfReceivedSignal.queue_free()
		else: #if interfacesignal from NPC
			react(3)


func reactionToNPCConvoBubble(NPCnode):
	print("PLAYER REACT TO NPC CONVO")
	NPCnode.get_node("AnimationPlayer").play("returnConvoNode")
	yield( NPCnode.get_node("AnimationPlayer"), "animation_finished" )
	NPCnode.get_node("ConvoNode").position = Vector2(40, -40)
	NPCnode.get_node("ConvoNode").scale = Vector2(0.5, 0.5)
	NPCnode.get_node("ConvoNode").modulate = Color(1, 1, 1, 0.8)
	print(prevTalkDamageReceived)
	if self.prevTalkDamageReceived > 0:
		$ReactParticles.process_material.hue_variation = 0.6
		$ReactParticles.amount = int(prevTalkDamageReceived*30)
		$ReactParticles.emitting = true
		$ReactParticles.restart()
	else:
		$ReactParticles.process_material.hue_variation = 0.3
		$ReactParticles.amount = int(self.prevTalkDamageReceived*30)
		$ReactParticles.emitting = true
		$ReactParticles.restart()


func reactionToConvoBubbleGeneric(nodeThatSentTheBubble, nodeThatReceivedTheBubble):
	print("REACTING TO CONVO")
	nodeThatSentTheBubble.get_node("AnimationPlayer").play("returnConvoNode")
	yield( nodeThatSentTheBubble.get_node("AnimationPlayer"), "animation_finished" )
	nodeThatSentTheBubble.get_node("ConvoNode").position = Vector2(40, -40)
	nodeThatSentTheBubble.get_node("ConvoNode").scale = Vector2(0.5, 0.5)
	nodeThatSentTheBubble.get_node("ConvoNode").modulate = Color(1, 1, 1, 0.8)
	print(nodeThatReceivedTheBubble.prevTalkDamageReceived)
	if nodeThatReceivedTheBubble.prevTalkDamageReceived > 0:
		react(1)
#		$ReactParticles.amount = int(nodeThatSentTheBubble.prevTalkDamageReceived*100)
#		print(int(nodeThatSentTheBubble.prevTalkDamageReceived*100))
#		$ReactParticles.emitting = true
#		$ReactParticles.restart()
	else:
		react(2)


func _on_InterfaceSignal_body_entered(body):
	#print(body.get_name())
	if body.is_in_group("NPC"):
		body.react(3)
		self.react(3)
		self.currentTarget = body
		body.currentTarget = self
		body.velocity = Vector2(0, 0)
		self.currentPlayerState = possiblePlayerStates.LOCKEDON
		body.currentActionState = body.actionState.LOCKEDON


func _on_HungerTimer_timeout():
	for i in range(5):
		resourceStats[i] -= consumptionRates[i]
