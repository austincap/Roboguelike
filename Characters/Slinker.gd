extends Node2D
var Selected = preload("res://Characters/Selected.tscn")
var selected = Selected.instance()


var skillDict
#CLASS STATS
var lilStats = [0.1, 0.2, 0.1, 0.5, 0.4, 0.2] #[perception, charisma, intelligence, attack, defense, speed]
var bigStats = [30, 40, 50, 1] #[social_stamina, HP, carrying capacity, equipment slots] #
#FLUCTUATING STATS
var fluctStats = [0, 0, 0] #[talkDamage, desperation, personal affinity with player]
var hungerStats = [0, 0.3, 0.5, 0.2] #[crystals, metal, fuel, carbon fiber]
var currentTarget
#PERSONALITY TRAITS
var personality = [0.1, 0.55, 0.02, 0.3, 0.7, 0.2] #[general aggression, curiosity, erraticness, greed, grit]
var racismArray = [0, 0, 0, 0, 0] #[hackers, shooters, slinkers, armers, forkers]
var knowledge = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ] #[insult, compliment, question, pontificate, deflect, small talk, local area, tribal gossip, techniques, resistance]
var knowledgeArray = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.2, 0.4] #[small talk, local area, insults, techniques, other tribes, compliments, meta/religion/love, resistance]
var interestArray = [0.1, 0.0, -0.5, 0.0, 0.3, 0.8, 0.7, 0.6] #[small talk, local area, insults, techniques, other tribes, compliments, meta/religion/love, resistance]
#TEMP STATES
enum tempState{RELAXED, WARY, HOSTILE, AFRAID, JAZZED}
var currentTempState = tempState.RELAXED
#ACTION STATES
enum actionState{STANDBY, SLEEP, SEARCH, MOVING, ATTACK}
var currentActionState = actionState.STANDBY
var justChangedState = false





var receivedTalkDamage = 0
var patrol_points
var patrol_index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	randomizeNewCharacter()
	patrol_points = $Path2D.curve.get_baked_points()
	self.currentTarget = self
	$RayCastTween.interpolate_property($SensoryRayCast2D, "rotation", 0, 100, 100, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$RayCastTween.start()
	skillDict = {
	"SmallTalk":[0, 3, currentTarget.lilStats[1]*2, 1, "TheResistance"], 
	"TheResistance":[1, 3, 0, 1, "Insult"], 
	"Insult":[2, 1, currentTarget.lilStats[1]+currentTarget.lilStats[2], 2, "Technology"], 
	"Technology":[3, 1, 0, 1, "SmallTalk"]
	}
	

func randomizeNewCharacter():
	var i = 0
	for trait in personality:
		personality[i] = rand_range(0, 1)
		i+=1
	i = 0
	for topic_or_rhetoric_affinity in knowledge:
		knowledge[i] = rand_range(-0.5, 0.5)*(1+personality[1]) #random multiplied by 1+curiousity
		i+=1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if currentActionState == actionState.STANDBY:
		pass
	elif currentActionState == actionState.SLEEP:
		pass
	elif currentActionState == actionState.SEARCH:
		pass
	elif currentActionState == actionState.MOVING:
		pass
	elif currentActionState == actionState.ATTACK:
		pass


func _on_Area2D_body_entered(body):
	print(body.get_name())


func _on_SensoryRayCast2D_body_entered(body):
	currentTempState = tempState.HOSTILE
	print(body.get_name())


func _on_Area2D_area_entered(area):
	var ownerOfReceivedSignal = area.get_parent()
	receivedTalkDamage = (ownerOfReceivedSignal.talkDamage+ownerOfReceivedSignal.lilStats[1])*interestArray[ownerOfReceivedSignal.topicId]+racismArray[ownerOfReceivedSignal.raceId]
	initialReactionToSignalReceived()
	print(fluctStats[2])
	ownerOfReceivedSignal.skillUsed = false
	calculateAttackDecision()
	print(area.get_name())

func initialReactionToSignalReceived():
	fluctStats[2] += receivedTalkDamage
	if receivedTalkDamage > 0.15:
		print("WHOA!!")
	elif receivedTalkDamage > 0.5:
		print("Wow!")
	elif receivedTalkDamage > 0.0:
		print("meh.")
	elif receivedTalkDamage > -0.1:
		print("...")
	else:
		print("fuck you")


func calculateAttackDecision():
	var attackOrNot = ((personality[0]+personality[3]*rand_range(-0.3,0.3)+personality[4])+(racismArray[0]+fluctStats[2])*lilStats[3])*2+fluctStats[1]
	if currentTempState == tempState.HOSTILE:
		if attackOrNot > 2:
			currentActionState = actionState.ATTACK
		else:
			calculateTalkDecision()
	elif currentTempState == tempState.AFRAID:
		if attackOrNot > 5:
			currentActionState = actionState.ATTACK
		else:
			calculateTalkDecision()
	else:
		if attackOrNot > 3.5:
			currentActionState = actionState.ATTACK
		else:
			calculateTalkDecision()
		
func calculateTalkDecision():
	#sum curiousity + charisma + personal affinity + desperation + intelligence
	var talkOrNot = (personality[1]+lilStats[2]+fluctStats[2]+lilStats[1]+fluctStats[1])
	if currentTempState == tempState.JAZZED:
		if talkOrNot > 2:
			calculateWhichTopicDecision()
	elif currentTempState == tempState.WARY:
		if talkOrNot > 5:
			calculateWhichTopicDecision()
	else:
		if talkOrNot > 3.5:
			calculateWhichTopicDecision()

func calculateWhichTopicDecision():
	pass

func calculateDesperation():
	pass

func calculateDesire():
	pass
