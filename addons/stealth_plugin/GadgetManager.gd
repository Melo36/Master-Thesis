@tool
extends Node

var guard

var night_vision_enabled: bool = false:
	set(value):
		if night_vision_enabled != value:
			night_vision_enabled = value
			night_vision_for_guards(value)

var night_vision_multiplier: float = 1.5

func _ready() -> void:
	guard = get_parent()

func night_vision_for_guards(value: bool):
	if !guard:
		guard = get_parent()
		
	var vision_sensor: Node3D = guard.find_child("VisionSensor", true)
	var goggles = guard.find_child("NightVisionGoggles", true)
	
	if value:
		if !goggles:
			var skeleton: Skeleton3D = guard.find_child("Skeleton3D", true)
			if not skeleton:
				push_error("Skeleton3D not found on guard!")
				return
				
			var head_bone_idx := find_bone(skeleton, "head")
			if head_bone_idx == -1:
				push_error("Head bone not found!")
				return

			var head_attachment := BoneAttachment3D.new()
			# Set ONLY the bone_name (do not manually set bone_idx)
			head_attachment.bone_name = skeleton.get_bone_name(head_bone_idx)
			head_attachment.name = "NightVisionAttachment"
			
			goggles = preload("res://scenes/night_vision_goggles.tscn").instantiate()
			goggles.name = "NightVisionGoggles"
			
			var edited_scene = get_tree().edited_scene_root
			
			# Attach to skeleton first, then set ownership
			skeleton.add_child(head_attachment)
			head_attachment.owner = edited_scene
			
			head_attachment.add_child(goggles)
			goggles.owner = edited_scene
			
			goggles.rotation_degrees.y = 270

		goggles.visible = true
		if vision_sensor:
			vision_sensor.night_vision_multiplier = night_vision_multiplier
	else:
		if goggles:
			goggles.visible = false
		if vision_sensor:
			vision_sensor.night_vision_multiplier = 1.0

func find_bone(skeleton: Skeleton3D, name: String) -> int:
	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i)
		if name in bone_name.to_lower():
			return i
	return -1
