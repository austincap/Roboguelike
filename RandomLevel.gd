extends Node2D
var rand_generate = RandomNumberGenerator.new()
var fuelScene = preload("res://Resources/Fuel.tscn")
var rubberScene = preload("res://Resources/Rubber.tscn")
var metalScene = preload("res://Resources/Metal.tscn")
var carbonScene = preload("res://Resources/Carbon.tscn")
var crystalScene = preload("res://Resources/Crystal.tscn")
#var playerScene = preload("res://Player/Player.tscn")
var characterScene = preload("res://Characters/NPC.tscn")
#var hackerScene = load("res://Characters/Hacker.tscn")
#var slinkerScene = load("res://Characters/Slinker.tscn")
#var scrapperScene = load("res://Characters/Scrapper.tscn")
#var forkerScene = load("res://Characters/Forker.tscn")
var wingerScene = load("res://Characters/Winger.tscn")
var lockedBarricadeScene = preload("res://LevelElements/Entrances/LockedBarricade.tscn")
#var hazardScene = load("res://LevelElements/Hazard.tscn")
var portalScene = preload("res://LevelElements/Entrances/Portal.tscn")

var size_of_each_chunk = 576
var x_chunks = 6
var y_chunks = 6
var chunkArray = [
	["2002", "2000", "2000", "2200", "0000", "0000"],
	["0002", "0000", "0000", "0000", "0000", "0000"],
	["0002", "0000", "0000", "0000", "0000", "0000"],
	["0022", "0000", "0000", "0000", "0000", "0000"],
	["0022", "0000", "0000", "0000", "0000", "0000"],
	["0022", "0000", "0000", "0000", "0000", "0000"]
	]

var elementsChecked = false
var NPCArray = []
var portalArray = []
var resourceArray = []
var tempArray = []
var NPCLikelihood = 0.3
var resourceLikelihood = 0.5
var hazardLikelihood = 0.2

func getRandomNumber(num):
	rand_generate.randomize()
	return str(rand_generate.randi_range(0,num))

# Called when the node enters the scene tree for the first time.
func _ready():
	#$PlayerNode/Camera2D.make_current()
	var northConnection = "2"
	var eastConnection = getRandomNumber(2)
	var southConnection = getRandomNumber(2)
	var westConnection = "2"
	var isolatedchunkCount = 0
	
	var scene
	var chunk
	var element
	var NPCid = 0
	var chunkIdToGet = northConnection+eastConnection+southConnection+westConnection
	for y_chunk in range(y_chunks):
		for x_chunk in range(x_chunks):
			#determine north connection
			if y_chunk == 0:
				northConnection = "2"
			elif chunkArray[y_chunk-1][x_chunk][2] == "2":
				northConnection = "2"
			elif chunkArray[y_chunk-1][x_chunk][2] == "1":
				northConnection = "1"
			elif chunkArray[y_chunk-1][x_chunk][2] == "0":
				northConnection = "0"
			#determine west connection
			if x_chunk == 0:
				westConnection = "2"
			elif chunkArray[y_chunk][x_chunk-1][1] == "2":
				westConnection = "2"
			elif chunkArray[y_chunk][x_chunk-1][1] == "1":
				westConnection = "1"
			elif chunkArray[y_chunk][x_chunk-1][1] == "0":
				westConnection = "0"
			#determine east connection
			if x_chunk+1 == x_chunks:
				eastConnection = "2"
			else:
				eastConnection = getRandomNumber(2)
			#determine south connection
			if y_chunk+1 == y_chunks:
				southConnection = "2"
			else:
				southConnection = getRandomNumber(2)
			chunkIdToGet = northConnection+eastConnection+southConnection+westConnection
			chunkArray[y_chunk][x_chunk] = chunkIdToGet
			#scene = load("res://LevelGen/"+chunkIdToGet+".tscn")
			scene = load("res://LevelGen-alt-nav/"+chunkIdToGet+".tscn")
			chunk = scene.instance()
			chunk.global_position = Vector2(size_of_each_chunk*x_chunk, size_of_each_chunk*y_chunk)
			$Navigation2D.add_child(chunk) #actually a NavigationPolygonInstance that I named wrong
			#add level elements to chunk
			#add tunnels
			if (int(northConnection)+int(eastConnection)+int(southConnection)+int(westConnection)) >= 7:
#				scene = load("res://LevelElements/SewerEntrance.tscn")
#				element = scene.instance()
				element = portalScene.instance()
				tryToRandomlyPlaceElement(element, chunk)
				portalArray.append(element.global_position) #probably need a smarter way of tracking this if I stay with portals
				isolatedchunkCount += 1
			#add resources and items
			randomize()
			if rand_range(0.0, 1.0) < resourceLikelihood:
				var resourceType = getRandomNumber(4)
				if resourceType == "0":
					element = crystalScene.instance()
				elif resourceType == "1":
					element = metalScene.instance()
				elif resourceType == "2":
					element = fuelScene.instance()
				elif resourceType == "3":
					element = carbonScene.instance()
				elif resourceType == "4":
					element = rubberScene.instance()
				tryToRandomlyPlaceElement(element, chunk)
			#add NPCs
			randomize()
			#if rand_range(0.0, 1.0) < NPCLikelihood:
			if true:
			
#			if x_chunk==0 and y_chunk==0:
#				element = characterScene.instance()
#				tryToRandomlyPlaceElement(element, chunk)
				
#				var NPCType = getRandomNumber(4)
#				if NPCType == "0":
#					for i in int(getRandomNumber(6)):
#						element = slinkerScene.instance()
#						tryToRandomlyPlaceElement(element, chunk)
#				elif NPCType == "1":
#					for i in int(getRandomNumber(2)):
#						element = hackerScene.instance()
#						tryToRandomlyPlaceElement(element, chunk)
#				elif NPCType == "2":
#					for i in int(getRandomNumber(3)):
#						element = scrapperScene.instance()
#						tryToRandomlyPlaceElement(element, chunk)
#				for i in int(getRandomNumber(1)):
#					element = characterScene.instance()
#					element.NPCid = NPCid
#					NPCid += 1
#					tryToRandomlyPlaceElement(element, chunk)
				for i in int(getRandomNumber(1)):
					element = wingerScene.instance()
					element.NPCid = NPCid
					NPCid += 1
					tryToRandomlyPlaceElement(element, chunk)
			#add hazards and flavor objects
			randomize()
			if rand_range(0.0, 1.0) < hazardLikelihood:
				element = lockedBarricadeScene.instance()
				tryToRandomlyPlaceElement(element, chunk)
	#$Camera2D.make_current()

func checkNPCs():
	var i = 0
	for element in NPCArray:
		if is_instance_valid(element) and element.is_in_group("NPC"):
			if element.global_transform.origin.distance_to(element.prevPosition) < 1: #how far it has to be to justify culling
				element.queue_free()
			else:
				i+=1
	print(i)
	elementsChecked = true

func _unhandled_input(event: InputEvent) -> void:
	if $PlayerNode.currentPlayerState != $PlayerNode.possiblePlayerStates.TALKING:
		if not event is InputEventMouseButton:
			return
		if event.button_index != BUTTON_LEFT or not event.pressed:
			return
		var new_path = $Navigation2D.get_simple_path($PlayerNode.global_position, get_global_mouse_position())
		#$PlayerNode/Line2D.points = new_path
		$PlayerNode.path = new_path

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	yield(get_tree().create_timer(1.1), "timeout")
	if elementsChecked == false:
		checkNPCs()
	
func tryToRandomlyPlaceElement(elementToPlace, chunkToPlaceIn):
	randomize()
	elementToPlace.position = Vector2(rand_range(0,100), rand_range(0,170))
	if str(elementToPlace) == "[Deleted Object]":
		print(str(elementToPlace))
	else:
		chunkToPlaceIn.add_child(elementToPlace)
		NPCArray.append(elementToPlace)
	#chunkToPlaceIn.add_child(elementToPlace)
	#elementToPlace.position = Vector2(rand_range(50,100), rand_range(50,170))
	#print(chunkToPlaceIn.get_child(0))
	#print(elementToPlace.get_child(0).get_name())
	#print(elementToPlace.get_child(0).get_overlapping_bodies())
#	if elementToPlace.get_child(0).get_overlapping_bodies().size() > 0:
#	#if elementToPlace.get_child(0).overlaps_area(chunkToPlaceIn.get_child(0)):
#		print('overlap')
#		tryToRandomlyPlaceElement(elementToPlace, chunkToPlaceIn)
#	else:
#		if str(elementToPlace) == "[Deleted Object]":
#			print(str(elementToPlace))
#		else:
#			chunkToPlaceIn.add_child(elementToPlace)
#			NPCArray.append(elementToPlace)
#		#print('no overlap')
#	#print("done")

func fuckFunction(NPCnode, playerNode):
	print(NPCnode.get_name())
	print(playerNode.get_name())
	var playerScene = load("res://Player/Player.tscn")
	var newPlayer = playerScene.instance()
	newPlayer.lilStats[4] = NPCnode.lilStats[4]
	newPlayer.modulate = Color(0, 1, 0, 1)
	newPlayer.scale = Vector2(2, 2)
	add_child(newPlayer)
	newPlayer.global_position = playerNode.global_position
	var element = crystalScene.instance()
	add_child(element)
	element.global_position = NPCnode.global_position
	NPCnode.queue_free()
	playerNode.queue_free()
