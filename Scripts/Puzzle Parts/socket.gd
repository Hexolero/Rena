extends Spatial

export (NodePath) var powerablePath
onready var powerable = get_node(powerablePath)

var hasBattery = false

func _place_battery():
	hasBattery = true
	$display_battery.visible = true
	powerable._power(self)
	pass

func _remove_battery():
	hasBattery = false
	$display_battery.visible = false
	powerable._depower(self)
	pass