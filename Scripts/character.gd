extends Spatial

# Main scene variables
export (NodePath) var gridMapPath
onready var gridMap = get_node(gridMapPath)

# Ilya/Rena differing constants
const ILYA_MOVESPEED = 6.0
const RENA_MOVESPEED = 9.0

const ILYA_CAMERA_POS = Vector3(0, 2.36, 0.65) # this is when camera container is a child of ilya
const RENA_CAMERA_POS = Vector3(0, 0.98, 0.54) # this is when camera container is a child of rena

# Shared constants
const MOUSE_CAMERA_TURN_SPEED = 0.005

const CAMERA_INTERPOLATION_TIME = 2.0

const CAMERA_HIGH_ANGLE = -PI / 3
const CAMERA_LOW_ANGLE = PI / 3

const FALL_ACC = 0.4
const UP = Vector3(0, 1, 0)
const DEFAULT_FACING_DIR = Vector3(0, 0, 1)
const SIGHTCAST_EXTENT = 1000

# Character variables
var currentCharacter = "Ilya"

var clickEventQueued = false # Queued for physics pass
var nextCharacter

# swap variables
var swapOriginPos
var swapOriginRotation
var swapDeltaPos
var swapDeltaRotation

var cameraInterpolating
var interpolateTimer
# end swap variables

var moveArrAction = ["movement_up", "movement_left", "movement_down", "movement_right"]
var moveArrCheck = [false, false, false, false]
var moveArrDir = [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)]

var facingDir = Vector3(0, 0, 1)
var movementDir = Vector3()

var mouseFrameDelta = Vector2() # CLEARED EACH PHYSICS FRAME

var currentFallSpeed = 0.0

func _ready():
	$ilya.visible = false
	$ilya/camera_container/player_camera.current = true
	facingDir = DEFAULT_FACING_DIR.rotated(UP, $ilya.rotation.y)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# check if player intends to swap characters (and is currently able to)
	var currentCharNode
	if currentCharacter == "Ilya":
		currentCharNode = $ilya
	else:
		currentCharNode = $rena
	if clickEventQueued && currentCharNode.is_on_floor():
		clickEventQueued = false # consume event
		if is_friend_in_sight():
			swap_character()
		else:
			trigger_in_sight()
	
	if currentCharacter == "Swapping":
		if cameraInterpolating:
			$camera_container.translation += (delta / CAMERA_INTERPOLATION_TIME) * swapDeltaPos
			$camera_container.rotation += (delta / CAMERA_INTERPOLATION_TIME) * swapDeltaRotation
		
		# Check for interpolation end
		if !cameraInterpolating:
			var cc_ref = $camera_container
			if nextCharacter == "Ilya":
				remove_child(cc_ref)
				$ilya.add_child(cc_ref)
				$ilya.visible = false
				cc_ref.translation = ILYA_CAMERA_POS
				cc_ref.rotation = Vector3()
			elif nextCharacter == "Rena":
				remove_child(cc_ref)
				$rena.add_child(cc_ref)
				$rena.visible = false
				cc_ref.translation = RENA_CAMERA_POS
				cc_ref.rotation = Vector3()
			
			currentCharacter = nextCharacter
	elif currentCharacter == "Ilya":
		# rotate camera
		$ilya.rotate_y(-mouseFrameDelta.x * MOUSE_CAMERA_TURN_SPEED)
		
		var newPitchAngle = $ilya/camera_container.rotation.x + (mouseFrameDelta.y * MOUSE_CAMERA_TURN_SPEED)
		if !(newPitchAngle > CAMERA_HIGH_ANGLE && newPitchAngle < CAMERA_LOW_ANGLE):
			# camera pitch would be outside the bounds
			if newPitchAngle < CAMERA_HIGH_ANGLE:
				$ilya/camera_container.rotation.x = 0.0
				$ilya/camera_container.rotate_x(CAMERA_HIGH_ANGLE)
			elif newPitchAngle > CAMERA_LOW_ANGLE:
				$ilya/camera_container.rotation.x = 0.0
				$ilya/camera_container.rotate_x(CAMERA_LOW_ANGLE)
		else:
			# camera pitch would be a-ok within the bounds
			$ilya/camera_container.rotate_x(mouseFrameDelta.y * MOUSE_CAMERA_TURN_SPEED)
		
		if !$ilya.is_on_floor():
			# accelerate downwards whilst falling
			currentFallSpeed -= FALL_ACC
		else:
			# gradually decrease falling speed whilst grounded
			currentFallSpeed /= 2
		
		# WASD movement
		movementDir = Vector3()
		for i in range(4):
			if moveArrCheck[i]:
				movementDir += moveArrDir[i].rotated(UP, $ilya.rotation.y)
		$ilya.move_and_slide(ILYA_MOVESPEED * movementDir, UP)
		
		# apply gravity and update is_on_floor().
		$ilya.move_and_slide(currentFallSpeed * UP, UP) # MAS automatically uses delta
	elif currentCharacter == "Rena":
		# rotate camera
		$rena.rotate_y(-mouseFrameDelta.x * MOUSE_CAMERA_TURN_SPEED)
		
		var newPitchAngle = $rena/camera_container.rotation.x + (mouseFrameDelta.y * MOUSE_CAMERA_TURN_SPEED)
		if !(newPitchAngle > CAMERA_HIGH_ANGLE && newPitchAngle < CAMERA_LOW_ANGLE):
			# camera pitch would be outside the bounds
			if newPitchAngle < CAMERA_HIGH_ANGLE:
				$rena/camera_container.rotation.x = 0.0
				$rena/camera_container.rotate_x(CAMERA_HIGH_ANGLE)
			elif newPitchAngle > CAMERA_LOW_ANGLE:
				$rena/camera_container.rotation.x = 0.0
				$rena/camera_container.rotate_x(CAMERA_LOW_ANGLE)
		else:
			# camera pitch would be a-ok within the bounds
			$rena/camera_container.rotate_x(mouseFrameDelta.y * MOUSE_CAMERA_TURN_SPEED)
		
		if !$rena.is_on_floor():
			# accelerate downwards whilst falling
			currentFallSpeed -= FALL_ACC
		else:
			# gradually decrease falling speed whilst grounded
			currentFallSpeed /= 2
		
		# WASD movement
		movementDir = Vector3()
		for i in range(4):
			if moveArrCheck[i]:
				movementDir += moveArrDir[i].rotated(UP, $rena.rotation.y)
		$rena.move_and_slide(RENA_MOVESPEED * movementDir, UP)
		
		# apply gravity and update is_on_floor().
		$rena.move_and_slide(currentFallSpeed * UP, UP) # MAS automatically uses delta
	
	mouseFrameDelta = Vector2() # reset mouse frame delta

#func _process(delta):
#	
#	pass

func _input(event):
	# Keyboard input
	if event.is_action_pressed("ui_cancel"):
		# REMOVE THIS FOR RELEASE VERSION. USED FOR DEBUGGING.
		get_tree().quit()
	for i in range(4):
		if event.is_action_pressed(moveArrAction[i]):
			moveArrCheck[i] = true
		elif event.is_action_released(moveArrAction[i]):
			moveArrCheck[i] = false
	
	# Mouse input
	if event.is_action_pressed("swap_character"):
		clickEventQueued = true
	if event is InputEventMouseMotion:
		mouseFrameDelta += event.relative

func get_collider_in_sight():
	# call this only during _physics_process(), else space may be locked -> error
	# returns raycast data from centre of screen
	var midScreen = OS.window_size / 2
	var space_state = get_world().direct_space_state
	var exceptions = []
	
	var sightcast_normal
	var sightcast_origin
	if currentCharacter == "Ilya":
		sightcast_normal = $ilya/camera_container/player_camera.project_ray_normal(midScreen)
		sightcast_origin = $ilya/camera_container/player_camera.project_ray_origin(midScreen)
	elif currentCharacter == "Rena":
		sightcast_normal = $rena/camera_container/player_camera.project_ray_normal(midScreen)
		sightcast_origin = $rena/camera_container/player_camera.project_ray_origin(midScreen)
	return space_state.intersect_ray(sightcast_origin, sightcast_origin + sightcast_normal * SIGHTCAST_EXTENT, exceptions)

func is_friend_in_sight():
	# call this only during _physics_process(), else space may be locked -> error
	# returns true if the player is currently looking at the collider of their friend, otherwise false
	var sightcast_data = get_collider_in_sight()
	if currentCharacter == "Ilya":
		if !sightcast_data.empty():
			return sightcast_data.collider.name == "rena"
	elif currentCharacter == "Rena":
		if !sightcast_data.empty():
			return sightcast_data.collider.name == "ilya"

func trigger_in_sight():
	var sightcast_data = get_collider_in_sight()
	if !sightcast_data.empty():
		# check if collider in sight is a lever
		# and that we meet the requirements to activate it
		if sightcast_data.collider.name.find("lever") != -1 && currentCharacter == "Ilya":
			sightcast_data.collider._activate()

func swap_character():
	# We can successsfully start a character swap.
	
	var swapNewPos
	var swapNewRotation
	var cc_ref # camera_container reference
	
	if currentCharacter == "Ilya":
		# Save position + rotation of camera (These are global)
		swapOriginPos = $ilya/camera_container.translation + $ilya.translation
		swapOriginRotation = Vector3($ilya/camera_container.rotation.x, $ilya.rotation.y, 0.0)
		# Set up new position + rotation of camera (These are global)
		swapNewPos = RENA_CAMERA_POS + $rena.translation
		swapNewRotation = Vector3(0.0, $rena.rotation.y, 0.0)
		# Set cc_ref
		cc_ref = $ilya/camera_container
	elif currentCharacter == "Rena":
		# Save position + rotation of camera (These are global)
		swapOriginPos = $rena/camera_container.translation + $rena.translation
		swapOriginRotation = Vector3($rena/camera_container.rotation.x, $rena.rotation.y, 0.0)
		# Set up new position + rotation of camera (These are global)
		swapNewPos = ILYA_CAMERA_POS + $ilya.translation
		swapNewRotation = Vector3(0.0, $ilya.rotation.y, 0.0)
		# Set cc_ref
		cc_ref = $rena/camera_container
	
	# Calculate global deltas
	swapDeltaPos = swapNewPos - swapOriginPos
	swapDeltaRotation = swapNewRotation - swapOriginRotation
	
	# Timer setup
	cameraInterpolating = true
	interpolateTimer = Timer.new()
	add_child(interpolateTimer)
	interpolateTimer.connect("timeout", self, "stop_interpolating")
	interpolateTimer.wait_time = CAMERA_INTERPOLATION_TIME
	interpolateTimer.one_shot = true
	interpolateTimer.start()
	
	# Unparent camera_container and set its position/rotation properly. Make current character visible again
	if currentCharacter == "Ilya":
		$ilya.remove_child(cc_ref)
		add_child(cc_ref)
		
		$ilya.visible = true
		
		nextCharacter = "Rena"
	elif currentCharacter == "Rena":
		$rena.remove_child(cc_ref)
		add_child(cc_ref)
		
		$rena.visible = true
		
		nextCharacter = "Ilya"
	
	cc_ref.translation = swapOriginPos
	cc_ref.rotation = swapOriginRotation
	
	# Finally, set currentCharacter to the swapping state
	currentCharacter = "Swapping"

func stop_interpolating():
	cameraInterpolating = false