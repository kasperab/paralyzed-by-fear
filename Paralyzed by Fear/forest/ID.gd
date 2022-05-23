extends StaticBody

export var id = 0
export var canExplode = true

func explode():
	if canExplode:
		get_node("../../../DestroyAudio").play()
		get_parent().queue_free()
