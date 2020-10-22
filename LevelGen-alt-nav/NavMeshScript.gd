extends Node2D

	
func moveNPC(NPCnode):
	#print("NPC " + str(NPCnode) + " going from " + str(NPCnode.global_position) + " to " + str(NPCnode.currentTarget.global_position))
	var new_path = $Navigation2D.get_simple_path(NPCnode.global_position, NPCnode.currentTarget.global_position, true)
	$Line2D.points = new_path
	NPCnode.path = new_path 
