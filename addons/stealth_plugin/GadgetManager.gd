@tool
extends Node

# Example
var night_vision_enabled: bool = false:
	set(value):
		print("Set value")
		night_vision_for_guards(value)
var night_vision_multiplier: float = 1.5
			
# This function increases vision of guards for darker areas
func night_vision_for_guards(value: bool):
	var vision_sensor: Node3D = get_parent().find_child("VisionSensor")
	var goggles = get_parent().find_child("NightVisionGoggles", true, false)
	print("Goggles ", goggles)
	if value:
		vision_sensor.night_vision_multiplier = night_vision_multiplier
		goggles.visible = true
	else:
		vision_sensor.night_vision_multiplier = 1.0
		goggles.visible = false
	
