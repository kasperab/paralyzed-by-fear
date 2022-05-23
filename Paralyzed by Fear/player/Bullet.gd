extends Spatial

export var speed = 1.0
export var life = 1.0
var direction = Vector2()

func _process(delta):
	translate(Vector3(direction.x, 0, direction.y) * speed * delta)
	life -= delta
	if life <= 0:
		get_tree().queue_delete(self)

func _on_Area_body_entered(body):
	if body.name == "InterestingBody" or body.name == "ScaryBody":
		body.explode()
		queue_free()
