extends Spatial

export (NodePath) var powerablePath
onready var powerable = get_node(powerablePath)

var powerState = false # off

func _activate():
	if !powerState:
		# power was off, now turns on
		powerable._power(self)
		powerState = true
		# play animation for switching on
		$AnimationPlayer.play("default")
	else:
		# power was on, now turns off
		powerable._depower(self)
		powerState = false
		# play animation for switching off
		$AnimationPlayer.play_backwards("default")