extends Spatial

export var speed = 1.0
export var torque = 1.0
export var emotionSpeed = 1.0
export var animationSpeed = 1.0
export var footstepInterval = 1.0
export var footstepStart = 1.0
var fear = 1.0
var curiosity = 0.0
var aggression = 0.0
var fearButton = false
var curiosityButton = false
var aggressionButton = false
var target = null
var targetID = 0
var interestingObjects = []
var scaryObjects = []
var examinedObjects = []
var obstacles = []
var direction = Vector2(0, 1)
var rotationY = PI / 2
var dead = false
var examining = false
var footstepCountdown
var bullet = preload("res://player/Bullet.tscn")
var reload = 0.0
var scrap = 0

func _ready():
	get_node("../UI/Fear Button").connect("button_down", self, "_on_Fear_down")
	get_node("../UI/Fear Button").connect("button_up", self, "_on_Fear_up")
	get_node("../UI/Curiosity Button").connect("button_down", self, "_on_Curiosity_down")
	get_node("../UI/Curiosity Button").connect("button_up", self, "_on_Curiosity_up")
	get_node("../UI/Aggression Button").connect("button_down", self, "_on_Aggression_down")
	get_node("../UI/Aggression Button").connect("button_up", self, "_on_Aggression_up")
	updateMarker()
	$Astronaut/Vision.connect("body_entered", self, "_on_Vision_enter")
	$Astronaut/Vision.connect("body_exited", self, "_on_Vision_exit")
	$Astronaut/Body.connect("body_entered", self, "_on_Body_enter")
	footstepCountdown = footstepStart

func _process(delta):
	if reload > 0.0:
		reload -= delta
	if examining and dead and not $Astronaut/AnimationPlayer.is_playing():
		examining = false
		$Astronaut/AnimationPlayer.current_animation = "die"
		$DeathAudio.play()
	if dead and not examining:
		if not $Astronaut/AnimationPlayer.is_playing():
			get_tree().reload_current_scene()
		return
	
	var fearPressed = fearButton or Input.is_action_pressed("fear")
	var curiosityPressed = curiosityButton or Input.is_action_pressed("curiosity")
	var aggressionPressed = aggressionButton or Input.is_action_pressed("aggression")
	if fearPressed and curiosityPressed and aggressionPressed:
		return
	elif fearPressed and curiosityPressed:
		if aggression <= 0:
			return
		fear += emotionSpeed * delta
		curiosity += emotionSpeed * delta
		aggression -= emotionSpeed * 2 * delta
	elif fearPressed and aggressionPressed:
		if curiosity <= 0:
			return
		fear += emotionSpeed * delta
		aggression += emotionSpeed * delta
		curiosity -= emotionSpeed * 2 * delta
	elif curiosityPressed and aggressionPressed:
		if fear <= 0:
			return
		curiosity += emotionSpeed * delta
		aggression += emotionSpeed * delta
		fear -= emotionSpeed * 2 * delta
	elif fearPressed and fear < 1:
		fear += emotionSpeed * 2 * delta
		if curiosity <= 0:
			aggression -= emotionSpeed * 2 * delta
		elif aggression <= 0:
			curiosity -= emotionSpeed * 2 * delta
		else:
			curiosity -= emotionSpeed * delta
			aggression -= emotionSpeed * delta
	elif curiosityPressed and curiosity < 1:
		curiosity += emotionSpeed * 2 * delta
		if fear <= 0:
			aggression -= emotionSpeed * 2 * delta
		elif aggression <= 0:
			fear -= emotionSpeed * 2 * delta
		else:
			fear -= emotionSpeed * delta
			aggression -= emotionSpeed * delta
	elif aggressionPressed and aggression < 1:
		aggression += emotionSpeed * 2 * delta
		if fear <= 0:
			curiosity -= emotionSpeed * 2 * delta
		elif curiosity <= 0:
			fear -= emotionSpeed * 2 * delta
		else:
			fear -= emotionSpeed * delta
			curiosity -= emotionSpeed * delta
	updateMarker()
	
	if examining:
		if not $Astronaut/AnimationPlayer.is_playing():
			examining = false
			$Astronaut/AnimationPlayer.current_animation = "idle"
			footstepCountdown = footstepStart
			if scrap >= 3:
				get_tree().change_scene("res://End.tscn")
		else:
			return
	
	var position = Vector2(translation.x, translation.z)
	if fear > 0.9:
		target = null
		targetID = 0
	elif reload <= 0.0 and (aggression > 0.8 or (aggression > 0.5 and scaryObjects.size() > 0)):
		target = null
		targetID = 0
		shoot()
	elif target == null and curiosity > 0.1:
		if curiosity > 0.8 and scaryObjects.size() > 0:
			var targetIndex = randi() % scaryObjects.size()
			var targetPosition = scaryObjects[targetIndex].to_global(Vector3())
			target = Vector2(targetPosition.x, targetPosition.z)
			targetID = scaryObjects[targetIndex].id
		elif interestingObjects.size() > 0:
			var targetIndex = randi() % interestingObjects.size()
			var targetPosition = interestingObjects[targetIndex].to_global(Vector3())
			target = Vector2(targetPosition.x, targetPosition.z)
			targetID = interestingObjects[targetIndex].id
		else:
			target = Vector2()
			if position.x > 5:
				target.x = position.x - 5
			elif position.x < -5:
				target.x = position.x + 5
			if position.y > 5:
				target.y = position.y - 5
			elif position.y < -5:
				target.y = position.y + 5
	
	if $Astronaut/AnimationPlayer.current_animation == "shoot" and $Astronaut/AnimationPlayer.is_playing():
			return
	
	if target and target.distance_squared_to(position) > 1:
		var toTarget = (target - position).normalized()
		var right = Vector2(-direction.y, direction.x)
		var wantedRotation = toTarget.dot(right)
		for index in range(obstacles.size()):
			var obstaclePosition = obstacles[index].to_global(Vector3())
			var toObstacle = (Vector2(obstaclePosition.x, obstaclePosition.z) - position).normalized()
			var scale = obstacles[index].get_parent().scale.x
			var weight = (scale - translation.distance_to(obstaclePosition)) / scale
			if weight < 0 or weight > 0.8:
				continue
			wantedRotation += (toObstacle.dot(right) - PI) * weight
		rotationY += wantedRotation * torque * delta
		direction.x = cos(rotationY)
		direction.y = sin(rotationY)
		translate(Vector3(direction.x, 0, direction.y) * speed * curiosity * delta)
		if target.distance_squared_to(Vector2(translation.x, translation.z)) <= 1:
			target = null
			targetID = 0
		$Astronaut.rotation = Vector3(0, PI / 2 - rotationY, 0)
		$Astronaut/AnimationPlayer.current_animation = "walk"
		$Astronaut/AnimationPlayer.playback_speed = animationSpeed * speed * curiosity
		footstepCountdown -= curiosity * delta
		if footstepCountdown <= 0.0:
			footstepCountdown = footstepInterval
			if randi() % 2 == 0:
				$FootAudio1.play()
			else:
				$FootAudio2.play()
	else:
		target = null
		targetID = 0
		footstepCountdown = footstepStart
		$Astronaut/AnimationPlayer.current_animation = "idle"
		$Astronaut/AnimationPlayer.playback_speed = 1

func _on_Fear_down():
	fearButton = true

func _on_Fear_up():
	fearButton = false

func _on_Curiosity_down():
	curiosityButton = true

func _on_Curiosity_up():
	curiosityButton = false

func _on_Aggression_down():
	aggressionButton = true

func _on_Aggression_up():
	aggressionButton = false

func _on_Vision_enter(body):
	obstacles.append(body)
	if body.name == "InterestingBody":
		for index in range(examinedObjects.size()):
			if body.id == examinedObjects[index]:
				return
		interestingObjects.append(body)
	elif body.name == "ScaryBody":
		scaryObjects.append(body)

func _on_Vision_exit(body):
	obstacles.erase(body)
	if body.name == "InterestingBody":
		interestingObjects.erase(body)
	if body.name == "ScaryBody":
		scaryObjects.erase(body)

func _on_Body_enter(body):
	if body.name == "InterestingBody" and body.id == targetID:
		examinedObjects.append(body.id)
		target = null
		var index = 0
		while index < interestingObjects.size():
			if interestingObjects[index].id == body.id:
				interestingObjects.remove(index)
			else:
				index += 1
		$Astronaut/AnimationPlayer.current_animation = "examine"
		$Astronaut/AnimationPlayer.playback_speed = 1
		$ExamineAudio.play()
		examining = true
		if body.id < 10:
			scrap += 1
	elif body.name == "ScaryBody" and body.id == targetID:
		$Astronaut/AnimationPlayer.current_animation = "examine"
		$Astronaut/AnimationPlayer.playback_speed = 1
		$ExamineAudio.play()
		examining = true
		dead = true

func updateMarker():
	var x = 224 - 224 * fear + 224 * aggression
	var y = 384 - 384 * curiosity
	get_node("../UI/Marker").rect_position = Vector2(x, y)
	var fogColor = get_node("../UI/Fog").get_modulate()
	fogColor.r = aggression * 0.5
	fogColor.g = curiosity * 0.5
	fogColor.b = fear * 0.5
	get_node("../UI/Fog").set_modulate(fogColor)

func shoot():
	var bullet1 = bullet.instance()
	bullet1.direction = direction
	bullet1.global_transform = global_transform
	get_parent().add_child(bullet1)
	var bullet2 = bullet.instance()
	bullet2.direction = direction.rotated(PI / 4)
	bullet2.global_transform = global_transform
	get_parent().add_child(bullet2)
	var bullet3 = bullet.instance()
	bullet3.direction = direction.rotated(-PI / 4)
	bullet3.global_transform = global_transform
	get_parent().add_child(bullet3)
	$ShootAudio.play()
	$Astronaut/AnimationPlayer.current_animation = "shoot"
	$Astronaut/AnimationPlayer.playback_speed = 4
	if aggression > 0.9:
		reload = 1.0
	else:
		reload = 10.0
	footstepCountdown = footstepStart
