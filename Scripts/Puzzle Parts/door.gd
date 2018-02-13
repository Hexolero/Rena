extends "res://Scripts/Powerable.gd"

export var DOOR_SPEED = 2.0

const UP = Vector3(0, 1, 0)

# doorState values: up, descending, down, ascending
var doorState = "up"
onready var upPos = translation
onready var downPos = translation + Vector3(0, -4, 0)

func _ready():
	pass

func _physics_process(delta):
	match doorState:
		"up":
			pass
		"descending":
			var newPos = translation + delta * DOOR_SPEED * -UP
			if newPos.y < downPos.y:
				# We've finished going down. Set manually
				translation = downPos
				doorState = "down"
			else:
				# Just move_and_collide as usual
				move_and_collide(delta * DOOR_SPEED * -UP)
		"down":
			pass
		"ascending":
			var newPos = translation + delta * DOOR_SPEED * UP
			if newPos.y > upPos.y:
				# We've finished going up. Set manually
				translation = upPos
				doorState = "up"
			else:
				# Just move_and_collide as usual
				move_and_collide(delta * DOOR_SPEED * UP)

func _power_on():
	match doorState:
		"up":
			doorState = "descending"
		"descending":
			# undefined behaviour
			pass
		"down":
			# undefined behaviour
			pass
		"ascending":
			doorState = "descending"

func _power_off():
	match doorState:
		"up":
			# undefined behaviour
			pass
		"descending":
			doorState = "ascending"
		"down":
			doorState = "ascending"
		"ascending":
			# undefined behaviour
			pass