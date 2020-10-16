extends Node2D
var rand_generate = RandomNumberGenerator.new()
var fuelScene = preload("res://Resources/Fuel.tscn")
var rubberScene = preload("res://Resources/Rubber.tscn")
var metalScene = preload("res://Resources/Metal.tscn")
var carbonScene = preload("res://Resources/Carbon.tscn")
var crystalScene = preload("res://Resources/Crystal.tscn")

var characterScene = preload("res://Characters/NPC.tscn")
#var hackerScene = load("res://Characters/Hacker.tscn")
#var slinkerScene = load("res://Characters/Slinker.tscn")
#var scrapperScene = load("res://Characters/Scrapper.tscn")
#var forkerScene = load("res://Characters/Forker.tscn")
#var stalkerScene = load("res://Characters/Stalker.tscn")

#var hazardScene = load("res://LevelElements/Hazard.tscn")

var x_chunks = 5
var y_chunks = 5
var chunkArray = [
	["2002", "2000", "2000", "2200", "0000"],
	["0002", "0000", "0000", "0000", "0000"],
	["0002", "0000", "0000", "0000", "0000"],
	["0022", "0000", "0000", "0000", "0000"],
	["0022", "0000", "0000", "0000", "0000"]
	]

var elementsChecked = false
var NPCArray = []
var entranceArray = []

var NPCLikelihood = 0.1
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
			scene = load("res://LevelGen/"+chunkIdToGet+".tscn")
			chunk = scene.instance()
			chunk.global_position = Vector2(576*x_chunk, 576*y_chunk)
			add_child(chunk)
			#add level elements to chunk
			#add tunnels
			if (int(northConnection)+int(eastConnection)+int(southConnection)+int(westConnection)) >= 7:
				scene = load("res://LevelElements/SewerEntrance.tscn")
				element = scene.instance()
				tryToRandomlyPlaceElement(element, chunk)
				entranceArray.append([isolatedchunkCount, element])
				isolatedchunkCount += 1
			#add resources and items
			randomize()
			if rand_range(0.0, 1.0) < resourceLikelihood:
				element = fuelScene.instance()
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
				for i in int(getRandomNumber(3)):
					element = characterScene.instance()
					tryToRandomlyPlaceElement(element, chunk)
			#add hazards and flavor objects
#			randomize()
#			if rand_range(0.0, 1.0) < hazardLikelihood:
#				for i in int(getRandomNumber(3)):
#					element = hazardScene.instance()
#					tryToRandomlyPlaceElement(element, chunk)
	$Camera2D.make_current()

func checkNPCs():
	for element in NPCArray:
		print(element)
		if is_instance_valid(element) and element.is_in_group("NPC"):
			print(element.velocity)
			if element.velocity.x > -3 and element.velocity.x < 3 and element.velocity.y > -3 and element.velocity.y < 3:
				
				print("DELETE")
				element.queue_free()
#		print(element)
#		print(element.get_child(0))
#		print(element.get_child(0).get_name())
#		print(element.get_child(0).get_overlapping_bodies())
#		if element.get_child(0).get_overlapping_bodies().size() > 0:
#			element.queue_free()
#			print(element.get_child(0).get_parent().get_name())
	elementsChecked = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	yield(get_tree().create_timer(0.9), "timeout")
	if elementsChecked == false:
		checkNPCs()
	
func tryToRandomlyPlaceElement(elementToPlace, chunkToPlaceIn):
	randomize()
	elementToPlace.position = Vector2(rand_range(0,100), rand_range(0,170))
	#chunkToPlaceIn.add_child(elementToPlace)
	#elementToPlace.position = Vector2(rand_range(50,100), rand_range(50,170))
	#print(chunkToPlaceIn.get_child(0))
	#print(elementToPlace.get_child(0).get_name())
	#print(elementToPlace.get_child(0).get_overlapping_bodies())
	if elementToPlace.get_child(0).get_overlapping_bodies().size() > 0:
	#if elementToPlace.get_child(0).overlaps_area(chunkToPlaceIn.get_child(0)):
		#print('overlap')
		tryToRandomlyPlaceElement(elementToPlace, chunkToPlaceIn)
	else:
		chunkToPlaceIn.add_child(elementToPlace)
		NPCArray.append(elementToPlace)
		#print('no overlap')
	#print("done")
