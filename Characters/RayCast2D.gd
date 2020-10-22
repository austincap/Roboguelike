class_name RaycastAStar

var openSet = {}
var cameFrom = {}
var gScore = {}
var fScore = {}
var space
var excludes = []
var neighbors_map = {}
var max_iterations = 1000
const GRID_SIZE = 32

# Simple vector serialization. We serialize most vectors so we can use them as dict keys
func _vec_to_id(vec: Vector2) -> String:
	return str(vec.x)+","+str(vec.y)
	
# Finds the (serialized) point in the openSet with the smallest fScore
func find_smallest_fscore():
	var smallestScore = INF
	var smallestPoint = null
	
	for pointId in openSet:
		var point = openSet[pointId]
		if fScore[pointId] and fScore[pointId] < smallestScore:
			smallestScore = fScore[pointId]
			smallestPoint = pointId
	
	return smallestPoint

# Heuristic distance between two points. In this case, actual distance.
# This is straight-line distance though, and ignores any obstacles.
func h_dist(end, start):
	return (end - start).length()

# Uses raycasting to find the traversable neighbors of the given position
# Caches results
func get_neighbors(vec):
	var vecId = _vec_to_id(vec)
	if neighbors_map.has(vecId):
		#print("Had vector in neighbors map")
		return neighbors_map.get(vecId)
		
	var targets = [
		vec + Vector2(GRID_SIZE, 0),
		vec + Vector2(-GRID_SIZE, 0),
		vec + Vector2(0, GRID_SIZE),
		vec + Vector2(0, -GRID_SIZE),
	]
	var valid = []
	
	for target in targets:
		var result = space.intersect_ray(vec, target, excludes)
		# There's nothing there, so we can visit the neighbor
		if not result:
			valid.append(target)
	
	neighbors_map[vecId] = valid
	return valid
	
# Works backward, looking up ideal steps in cameFrom, to reproduce the full path
func reconstruct_path(current):
	var currentId = _vec_to_id(current)
	var total_path = [current]
	
	while cameFrom.has(currentId):
		current = cameFrom[currentId]
		currentId = _vec_to_id(current)
		total_path.push_front(current)
	
	return total_path

# Normalizes a point onto our grid (centering on cells)
func normalize_point(vec):
	return Vector2((round(vec.x / GRID_SIZE) * GRID_SIZE) + (GRID_SIZE/2), (round(vec.y / GRID_SIZE) * GRID_SIZE) + (GRID_SIZE/2))
	
# Entrypoint to the pathfinding algorithm. Will return either null or an array of Vector2s
func path(start, end, space_state, exclude_bodies):
	
	var iterations = 0
	
	# Update class variables
	space = space_state
	excludes = exclude_bodies
	
	start = normalize_point(start)
	end = normalize_point(end)
	var startId = _vec_to_id(start)
	var goalId = _vec_to_id(end)
	
	cameFrom = {}
	openSet = {}
	openSet[startId] = start
	gScore = {}
	fScore = {}
	
	gScore[startId] = 0
	fScore[startId] = h_dist(end, start)
	
	# As long as we have points to visit, let's visit them
	# But not more than max_iterations times.
	while openSet.size() > 0 and iterations < max_iterations:
		# We're going to grab the current best tile, then look at its neighbors
		var currentId = find_smallest_fscore()
		var current = openSet[currentId]
		
		# We reached the goal, so stop here and return the path.
		if currentId == goalId:
			return reconstruct_path(current)
		
		openSet.erase(currentId)
		
		# "neighbors" are only accessible spaces as discovered by the raycaster
		var neighbors = get_neighbors(current)
		for neighbor in neighbors:
			var neighborId = _vec_to_id(neighbor)
			var neighborGscore = INF

			# We've seen this neighbor before, likely when passing through from a different path.
			if gScore.has(neighborId):
				neighborGscore = gScore[neighborId]
				
			# This is the "new" gScore as taken through _this_ path, not the previous path
			var tentative_gscore = gScore[currentId] + GRID_SIZE

			# If this path is better than the previous path through this neighbor, record it
			if tentative_gscore < neighborGscore:
				# This lets us work backwards through best-points later
				cameFrom[neighborId] = current
				# gScore is the actual distance it took to get here from the start
				gScore[neighborId] = tentative_gscore
				
				# fScore is the actual distance from the start plus the estimated distance to the end
				# Whoever has the best fScore in the openSet gets our attention next
				# Therefore we are always inspecting the current best-guess-path
				fScore[neighborId] = tentative_gscore + h_dist(end, neighbor)
				
				# This would allow revisiting if the heuristic were not consistent
				# But in our use case we should not end up revisiting nodes
				if not openSet.has(neighborId):
					openSet[neighborId] = neighbor
			pass
		
		pass
		iterations += 1
	
	# No path found
	return null
	
