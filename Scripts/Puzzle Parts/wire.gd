extends "res://Scripts/Powerable.gd"

export (NodePath) var meshPath
onready var mesh = get_node(meshPath)

const offMaterial = preload("res://Graphical Assets/WireOff.material")
const onMaterial = preload("res://Graphical Assets/WireOn.material")

func _power_on():
	mesh.set_material_override(onMaterial)

func _power_off():
	mesh.set_material_override(offMaterial)