extends Spatial

# Derived classes HAVE to implement a _power_on() and _power_off() method. (Can be empty)

export (NodePath) var connectedPath1
export (NodePath) var connectedPath2
export (NodePath) var connectedPath3
export (NodePath) var connectedPath4

var connectedPowerables = []
var powerSources = []

func _ready():
	# Load in valid paths
	if connectedPath1 != null:
		connectedPowerables.append(get_node(connectedPath1))
	if connectedPath2 != null:
		connectedPowerables.append(get_node(connectedPath2))
	if connectedPath3 != null:
		connectedPowerables.append(get_node(connectedPath3))
	if connectedPath4 != null:
		connectedPowerables.append(get_node(connectedPath4))

func _power(source):
	if !powerSources.has(source):
		powerSources.append(source)
	if powerSources.size() == 1:
		# We've powered on, send a _power signal to next in chain and _power_on to ourselves
		for powerable in connectedPowerables:
			powerable._power(self)
		_power_on()

func _depower(source):
	if powerSources.has(source):
		powerSources.erase(source)
	if powerSources.empty():
		# We've powered off, send a _depower signal to next in chain and _power_off to ourselves
		for powerable in connectedPowerables:
			powerable._depower(self)
		_power_off()

func is_powered():
	return !powerSources.empty()