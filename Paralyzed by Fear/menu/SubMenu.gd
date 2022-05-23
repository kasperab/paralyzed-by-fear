extends TextureButton

export (String) var subMenu

func _pressed():
	get_node("../../" + subMenu).show()
	get_parent().hide()
