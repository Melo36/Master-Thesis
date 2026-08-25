@tool
extends Node

var guard

# Example
var night_vision_enabled: bool = false:
	set(value):
		print("Set value")
		if night_vision_enabled != value:
			night_vision_for_guards(value)
var night_vision_multiplier: float = 1.5

func _ready() -> void:
	guard = get_parent()
			
# This function increases vision of guards for darker areas
func night_vision_for_guards(value: bool):
	print("Setting night vision ", value)
	# Get player script
	if !guard:
		guard = get_parent()
	var vision_sensor: Node3D = get_parent().find_child("VisionSensor")
	# Create goggles if they dont exist yet
	var goggles = guard.find_child("NightVisionGoggles", true)
	if !goggles && value:
		# Create new BoneAttachment 
		var head_attachment : BoneAttachment3D = BoneAttachment3D.new()
		var skeleton = guard.find_child("Skeleton3D", true)
		var head_bone := find_bone(skeleton, "head")
		# Attach head bone to Head Attachment
		head_attachment.bone_name = skeleton.get_bone_name(head_bone)
		head_attachment.bone_idx = 5
		goggles = preload("res://scenes/night_vision_goggles.tscn").instantiate()
		var edited_scene = get_tree().edited_scene_root
		skeleton.owner = edited_scene
		skeleton.add_child(head_attachment)
		head_attachment.owner = edited_scene
		head_attachment.add_child(goggles)
		goggles.owner = edited_scene
		goggles.rotation_degrees.y = 270
	goggles.visible = value
	if value:
		vision_sensor.night_vision_multiplier = night_vision_multiplier
	else:
		vision_sensor.night_vision_multiplier = 1.0
	
# Helper functions
func find_bone(skeleton: Skeleton3D, name : String) -> int:
	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i)
		if name in bone_name.to_lower():
			return i
	
	return -1

# Add more gadgets here
