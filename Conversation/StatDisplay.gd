extends Node2D


#signal displayStatPopUp(data_to_pass_up)


#get_node("../..").connect("dialogue_message_sent_to_panel", self, "_on_Message_sent_from_scene_node_to_panel")



# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("displayStatPopUp", get_node("../../.."), "_on_Personality_mouse_entered")

#emit_signal("resource_acquired", $Lumber)




func _on_Personality_mouse_exited():
	pass # Replace with function body.


func _on_Stats_mouse_entered():
	pass # Replace with function body.


func _on_Stats_mouse_exited():
	pass # Replace with function body.


func _on_Interests_mouse_entered():
	pass # Replace with function body.


func _on_Interests_mouse_exited():
	pass # Replace with function body.


func _on_Knowledge_mouse_entered():
	pass # Replace with function body.


func _on_Knowledge_mouse_exited():
	pass # Replace with function body.


func _on_ConsumptionRates_mouse_entered():
	pass # Replace with function body.


func _on_ConsumptionRates_mouse_exited():
	pass # Replace with function body.
