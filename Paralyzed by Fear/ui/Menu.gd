extends TextureButton

func _pressed():
	get_tree().change_scene("res://menu/Menu.tscn")

func _process(delta):
	if Input.is_action_just_released("menu"):
		_pressed()
