extends Sprite
var laser = preload("res://Items/Equipment/Laser.tscn")

func _ready():
	pass # Replace with function body.


func fire_laser(currentTarget):
	var laserScene = laser.instance()
	add_child(laserScene)
	$Tween.interpolate_property(laserScene, "global_position", self.global_position, currentTarget.global_position, 1, Tween.TRANS_ELASTIC)
	$Tween.start()
