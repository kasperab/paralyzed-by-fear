extends Spatial

var one = 4.0
var two = 4.0
var three = 4.0
var four = 3.0
var five = 3.0

func _ready():
	$One/Astronaut/AnimationPlayer.current_animation = "examine"

func _process(delta):
	if one > 0.0:
		one -= delta
		if one <= 0.0:
			$One.hide()
			$Two.show()
			$Two/Astronaut/AnimationPlayer.current_animation = "examine"
		return
	if two > 0.0:
		two -= delta
		if two <= 0.0:
			$Two.hide()
			$Three.show()
			$Three/Astronaut/AnimationPlayer.current_animation = "examine"
		return
	if three > 0.0:
		three -= delta
		if three <= 0.0:
			$Three/Astronaut.hide()
		return
	if four > 0.0:
		four -= delta
		if four <= 0.0:
			$Three.hide()
		return
	if five > 0.0:
		five -= delta
		if five <= 0.0:
			get_tree().change_scene("res://menu/Menu.tscn")
		return
