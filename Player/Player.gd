extends KinematicBody2D
var Selected = preload("res://Selected.tscn")
var selected = Selected.instance()
var raceId = 0
var perception = 1
var charisma = 2
var intelligence = 1
var talkDamage = 0
var social_stamina = 30
var aimAngle = 0

enum possiblePlayerStates{TALKING, BUYING, COMBAT, HACKING, NORMAL}
var currentPlayerState = possiblePlayerStates.NORMAL
var interfaceRequest = false

var topic = "SmallTalk"
var topicId = 0
var rhetoricId = 1
onready var currentSkillEquipped = get_node("SmallTalk")
#skillDict {SKill:[skillID, skill/topicStat (if applicable), skillEquation (if applicable), SS cost, next selection]}
#onready var skillDict = {
#	"SmallTalk":[0, 3, currentTarget.lilStats[1]*2, 1, "TheResistance", "Technology"], 
#	"TheResistance":[1, 3, 0, 1, "Insult", "SmallTalk"], 
#	"Insult":[2, 1, currentTarget.lilStats[1]+currentTarget.lilStats[2], 2, "Technology", "TheResistance"], 
#	"Technology":[3, 1, 0, 1, "SmallTalk", "Insult"]
#	}
#skillDict {Skill:[skillID, knowledge level, placeholder, SS cost, next selection, prev selection]}
onready var skillDict = {
	"SmallTalk":[0, 0.3, 0, 1, "TheResistance", "Technology"], 
	"TheResistance":[7, 0.1, 0, 1, "Insult", "SmallTalk"], 
	"Insult":[2, 0.1, 0, 2, "Technology", "TheResistance"], 
	"Technology":[3, 0.1, 0, 1, "SmallTalk", "Insult"]
	}
	
#INVENTORY AND SKILLS
var inventory = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] #inventory ID numbers, position corresponds to inventory arrangement
var resourceStats = [100, 30, 50, 20, 10] #[crystals, metal, fuel, carbon fiber, rubber] when hits 0 you're dead, able to trade/sell resources to others by multiplying by consumption rates
#STATS
var lilStats = [0.2, 0.1, 0.5, 0.4, 0.2] #[charisma, intelligence, attack, defense, speed]
var bigStats = [30, 40] #[social_stamina, maxHP]
var consumptionRates = [0.0, 0.3, 0.5, 0.2, 0] #[crystals, metal, fuel, carbon fiber, rubber] #subtract every timestep from corresponding resource
#FLUCTUATING STATS
var fluctStats = [0, 0] #[talkDamage, desperation]
var currentTarget = self
#PERSONALITY TRAITS
var personality = [0.1, 0.55, 0.02, 0.3, 0.7] #[general aggression, curiosity, erraticness, greed, grit]
#var racismArray = [0, 0, 0, 0, 0] #[hackers, shooters, slinkers, scrappers, forkers] #higher value is more racist
var knowledgeArray = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.2, 0.4, 0.0, 0.0] #[small talk, local area, advice, tribal gossip, big talk, compliments, insults, expound, deflect, joke]
#var interestArray = [0.1, 0.15, -0.5, 0.0, 0.3, 0.8, 0.7, 0.6, 0.0, 0.0] #[small talk, local area, advice, tribal gossip, big talk, compliments, insults, expound, deflect, joke]
#TEMP STATES
enum tempState{RELAXED, WARY, HOSTILE, AFRAID, JAZZED}
var currentTempState = tempState.RELAXED
var skillUsed = false
var firingDiction = Vector2()
var directionVector = Vector2(0, 0)
var deadzone = 0.25
var controllerangle = Vector2.ZERO
var xAxisRL = Input.get_joy_axis(0, JOY_AXIS_2)
var yAxisUD = Input.get_joy_axis(0 ,JOY_AXIS_3)
var prevTalkDamageReceived = 0


var leftStrength
var rightStrength
var downStrength
var upStrength

func _ready():
	#currentSkillEquipped.add_child(selected)
	$Camera2D.make_current()


func _physics_process(delta):
	if currentPlayerState == possiblePlayerStates.TALKING:
		if Input.is_action_pressed("interface"):
			$InterfaceSignal.global_position = currentTarget.global_position
		else:
			exitTalkSession(currentTarget)
	else:
		self.move_and_collide(directionVector)
		var xAxisRL = Input.get_joy_axis(0, JOY_AXIS_2)
		var yAxisUD = Input.get_joy_axis(0 ,JOY_AXIS_3)
		if skillUsed == false:
			leftStrength = Input.get_action_strength("aim_left")
			rightStrength = Input.get_action_strength("aim_right")
			downStrength = Input.get_action_strength("aim_down")
			upStrength = Input.get_action_strength("aim_up")
			if abs(xAxisRL) > deadzone || abs(yAxisUD) > deadzone:
				controllerangle = Vector2(xAxisRL, yAxisUD).angle()
				var x = controllerangle
				$InterfaceSignal.position = Vector2(150*(rightStrength-leftStrength)+20*(((x*sin(2*x)+sin(1.8*x)*sin(1.8*x))/1.7)-0.075), 150*(downStrength-upStrength)+20*(((x*sin(2*x)+sin(1.8*x)*sin(1.8*x))/1.7)-0.075))
				#currentSkillEquipped.position = Vector2(150*(rightStrength-leftStrength)+20*(((x*sin(2*x)+sin(1.8*x)*sin(1.8*x))/1.7)-0.075), 150*(downStrength-upStrength)+20*(((x*sin(2*x)+sin(1.8*x)*sin(1.8*x))/1.7)-0.075))
		else:
			#currentSkillEquipped.position += signalSpeed*delta*getShotVelocityVector()
			$InterfaceSignal.position += signalSpeed*delta*getShotVelocityVector()
		self.position += 200*delta*getLeftStickVector()

func getShotVelocityVector():
	return Vector2(Input.get_action_strength("aim_right")-Input.get_action_strength("aim_left"),  Input.get_action_strength("aim_down")-Input.get_action_strength("aim_up"))

func getLeftStickVector():
	return Vector2(Input.get_action_strength("rightmove")-Input.get_action_strength("leftmove"),  Input.get_action_strength("downmove")-Input.get_action_strength("upmove"))



func _input(event):
	if currentPlayerState == possiblePlayerStates.NORMAL or currentPlayerState == possiblePlayerStates.COMBAT:
		if event.is_action_released("rt"):
			executeSkill(currentSkillEquipped)
		if event.is_action_released("x"):
			changeSkill(skillDict[topic][4])
		if event.is_action_released("y"):
			changeSkill(skillDict[topic][5])
		if event.is_action_pressed("interface"):
			if interfaceRequest and currentTarget != self:
				print(currentTarget)
				print("ETGETETG")
				initiateTalkSession(currentTarget)
			else:
				sendInterfaceRequestInThisDirection(getShotVelocityVector())
	elif currentPlayerState == possiblePlayerStates.TALKING:
		if event.is_action_pressed("downmove"):
			changeTopicOrRhetoric(1)
		if event.is_action_pressed("upmove"):
			changeTopicOrRhetoric(0)
		if event.is_action_pressed("rightmove"):
			changeTopicOrRhetoric(3)
		if event.is_action_pressed("leftmove"):
			changeTopicOrRhetoric(2)
#		if event.is_action_pressed("interface"):
#			exitTalkSession()
		if event.is_action_released("rt"):
			$ConvoScene.modulate = Color(1,1,1,1)
			$SkillTween.interpolate_property($ConvoScene, "global_position", self.global_position+Vector2(80,-70), currentTarget.global_position, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			$SkillTween.start()

func sendInterfaceRequestInThisDirection(direction):
	$SkillTween.interpolate_property($InterfaceSignal, "global_position", self.global_position, direction*signalSpeed, 1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	$SkillTween.start()

func initiateTalkSession(NPCnode):
	print(NPCnode.get_name())
	print(NPCnode.get_parent().get_name())
	interfaceRequest = true
	currentTarget = NPCnode
	get_node("ConvoScene/ConvoBubble").set_deferred("monitorable", true)
	$ConvoScene.visible = true
	currentPlayerState = possiblePlayerStates.TALKING
	NPCnode.currentTarget = self.global_position
	NPCnode.get_node("ConvoScene").visible = true
	NPCnode.get_node("ConvoScene/ConvoBubble").set_deferred("monitorable", true)
	NPCnode.currentActionState = NPCnode.actionState.TALKING
	$InterfaceSignal.global_position = currentTarget.global_position
	$InterfaceSignal/Particles2D.process_material.initial_velocity = 300
	print('talk session initiated')
	

func exitTalkSession(NPCnode):
	$InterfaceSignal.global_position = self.global_position
	$InterfaceSignal/Particles2D.process_material.initial_velocity = 10
	get_node("ConvoScene/ConvoBubble").set_deferred("monitorable", false)
	$ConvoScene.visible = false
	interfaceRequest = false
	NPCnode.NPCexitTalkSession(NPCnode.actionState.SEARCH)
	currentPlayerState = possiblePlayerStates.NORMAL

func handleConvoBubble(NPCnode):
	var talkDamageDealt = 0
	if self.topicId == 0:
		self.bigStats[0] -= 3 #social stamina cost 3
		talkDamageDealt = self.lilStats[0]-NPCnode.lilStats[1] #smalltalk = player charisma- NPC openness 
	elif self.topicId == 1:
		self.bigStats[0] -= 2 #social stamina cost 2
		talkDamageDealt = 0.3
		pass #local area talk damage = 
	elif self.topicId == 2:
		self.bigStats[0] -= 2 #social stamina cost 3
		talkDamageDealt = 0.3
		pass #advice = 
	elif self.topicId == 3:
		talkDamageDealt = 0.3
		pass #gossip (incorporates racism)
	elif self.topicId == 4:
		talkDamageDealt = 0.3
		pass #big talk
		
	var rhetoricMultiplier = 1
	if self.rhetoricId == 0:
		self.bigStats[0] -= 3 #social stamina cost 3
		talkDamageDealt = 0.3
		pass #none
	elif self.rhetoricId == 1:
		self.bigStats[0] -= 3 #social stamina cost 3
		talkDamageDealt = 0.3
		pass #deflect
	elif self.rhetoricId == 2:
		self.bigStats[0] -= 3 #social stamina cost 3
		talkDamageDealt = 0.3
		pass #expound
	elif self.rhetoricId == 3:
		self.bigStats[0] -= 3 #social stamina cost 3
		talkDamageDealt = 0.3
		pass #flatter
	elif self.rhetoricId == 4:
		self.bigStats[0] -= 3 #social stamina cost 3
		rhetoricMultiplier = 1+clamp((self.lilStats[0]+self.lilStats[2]-NPCnode.lilStats[1]-self.personality[4]), 0, 1)
		pass #insult = (chr+atk-enemy int- enemy grit)
	elif self.rhetoricId == 5:
		self.bigStats[0] -= 3 #social stamina cost 3
		talkDamageDealt = 0.3
		pass #joke (incorporates knowledge)
	talkDamageDealt *= rhetoricMultiplier
	print(self.get_name() + " delivered this much talk damage: " + str(talkDamageDealt))
	return talkDamageDealt
	#NPCnode.fluctStats[2] += talkDamageDealt #add "talk damage to personal affinity"
	#NPCnode.initialReactionToSignalReceived(self) #react to it
	

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
		$SkillTween.interpolate_property($ConvoScene/ConvoBubble/BubbleSprite/UpArrow, "scale", Vector2(0.25,0.25), Vector2(0.2,0.2), 0.4, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
		$SkillTween.start()
		$ConvoScene/ConvoBubble/Topic.get_child(topicId).visible = false
		$ConvoScene/ConvoBubble/Topic.get_child(nextTopicId).visible = true
		topicId = nextTopicId
	#1 down topic
	elif choice == 1:
		$SkillTween.interpolate_property($ConvoScene/ConvoBubble/BubbleSprite/DownArrow, "scale", Vector2(0.25,0.25), Vector2(0.2,0.2), 0.4, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
		$SkillTween.start()
		$ConvoScene/ConvoBubble/Topic.get_child(topicId).visible = false
		$ConvoScene/ConvoBubble/Topic.get_child(prevTopicId).visible = true
		topicId = prevTopicId
	#2 left rhetoric
	elif choice == 2:
		$SkillTween.interpolate_property($ConvoScene/ConvoBubble/BubbleSprite/LeftArrow, "scale", Vector2(0.25,0.25), Vector2(0.2,0.2), 0.4, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
		$SkillTween.start()
		$ConvoScene/ConvoBubble/Rhetoric.get_child(rhetoricId).visible = false
		$ConvoScene/ConvoBubble/Rhetoric.get_child(prevRhetoricId).visible = true
		rhetoricId = prevRhetoricId
	#3 right rhetoric
	elif choice == 3:
		$SkillTween.interpolate_property($ConvoScene/ConvoBubble/BubbleSprite/RightArrow, "scale", Vector2(0.25,0.25), Vector2(0.2,0.2), 0.4, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
		$SkillTween.start()
		$ConvoScene/ConvoBubble/Rhetoric.get_child(rhetoricId).visible = false
		$ConvoScene/ConvoBubble/Rhetoric.get_child(nextRhetoricId).visible = true
		rhetoricId = nextRhetoricId

func react(reactionId):
	$Reactions.get_child(reactionId).visible = true
	$AnimationPlayer.play("React")
	yield( $AnimationPlayer, "animation_finished" )
	$Reactions.get_child(reactionId).visible = false

func executeSkill(skillNode):
	var skillName = skillNode.get_name()
	topic = skillName
	topicId = skillDict[skillName][0]
	talkDamage = skillDict[skillName][1]
#	if topic == "SmallTalk" or topic == "Insult":
#		talkDamage = skillDict[skillName][2] + skillDict[skillName][1]
#	elif topic == "TheResistance" or topic == "Technology":
#		talkDamage = skillDict[skillName][1]
	social_stamina -= skillDict[skillName][3]
	skillUsed = true
	$SkillReturnTimer.start()

var signalSpeed = 200


func changeSkill(newtopic):
	currentSkillEquipped.remove_child(get_node(topic+"/Selected"))
	currentSkillEquipped.visible = false
	currentSkillEquipped = get_node(newtopic)
	currentSkillEquipped.visible = true
	currentSkillEquipped.add_child(Selected.instance())
	topic = newtopic


func _on_SkillReturnTimer_timeout():
	skillUsed = false


#receive interface signals and convo bubbles
func _on_Area2D_area_entered(area):
	print(area.get_name())
	print('testete')
	var ownerOfReceivedSignal = area.get_parent()
	print(ownerOfReceivedSignal.get_name())
	if area.is_in_group("convo") and ownerOfReceivedSignal.get_parent().is_in_group("NPC"):
		prevTalkDamageReceived = handleConvoBubble(ownerOfReceivedSignal.get_parent())
		reactionToNPCConvoBubble(ownerOfReceivedSignal.get_parent())
	else: #if interfacesignal from NPC
		react(3)
		interfaceRequest = true
		currentTarget = ownerOfReceivedSignal


func reactionToNPCConvoBubble(NPCnode):
	print("player received convo")
	NPCnode.get_node("AnimationPlayer").play("returnConvoNode")
	yield( NPCnode.get_node("AnimationPlayer"), "animation_finished" )
	NPCnode.get_node("ConvoScene").position = Vector2(80, -70)
	NPCnode.get_node("ConvoScene").scale = Vector2(1, 1)
	NPCnode.get_node("ConvoScene").modulate = Color(1, 1, 1, 0.8)
	print(prevTalkDamageReceived)
	if prevTalkDamageReceived > 0:
		$ReactParticles.amount = int(prevTalkDamageReceived*10)
		$ReactParticles.emitting = true
		$ReactParticles.restart()
	else:
		react(2)
		print("fuck you")

