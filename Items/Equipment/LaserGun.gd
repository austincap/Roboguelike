extends Sprite
var laser = preload("res://Items/Equipment/Laser.tscn")

func _ready():
	$Tween.connect("tween_all_completed", $Tween, "queue_free")
	get_node("../..")


func fire_laser(currentTarget):
	var laserScene = laser.instance()
	add_child(laserScene)
	$Tween.interpolate_property(laserScene, "global_position", self.global_position, currentTarget.global_position, 0.5, Tween.TRANS_LINEAR)
	$Tween.start()
	$Tween.connect("tween_all_completed", laserScene, "queue_free")
