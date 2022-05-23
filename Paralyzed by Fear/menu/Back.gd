extends TextureButton

func _pressed():
	get_node("../../Title").show()
	get_parent().hide()

func _process(delta):
	if Input.is_action_just_released("menu"):
		_pressed()
