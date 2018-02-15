extends Area

export (NodePath) var powerablePath
onready var powerable = get_node(powerablePath)

var ilyaOnPlate = false
var renaOnPlate = false

func _on_plate_body_entered(body):
	if ilyaOnPlate || renaOnPlate:
		# We were previously already on this plate (with the other character)
		if body.name == "ilya":
			ilyaOnPlate = true
		elif body.name == "rena":
			renaOnPlate = true
	else:
		# We were previously off
		if body.name == "ilya":
			ilyaOnPlate = true
		elif body.name == "rena":
			renaOnPlate = true
		
		powerable._power(self)
		$plateSFX.play()

func _on_plate_body_exited(body):
	if body.name == "ilya":
		ilyaOnPlate = false
	elif body.name == "rena":
		renaOnPlate = false
	# Now check off status
	if !ilyaOnPlate && !renaOnPlate:
		powerable._depower(self)
		$plateSFX.play()