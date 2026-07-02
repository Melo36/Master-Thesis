@tool
extends Button

var waiting_for_key := false
var action_name := "jump"

func _pressed():
	waiting_for_key = true
	text = "Press a key..."

func _unhandled_input(event):
	if not waiting_for_key:
		return

	if event is InputEventKey and event.pressed:
		var parent = get_parent()
		var my_index = get_index()
		var overwrite = false

		if my_index > 0:
			var line_edit = parent.get_child(my_index - 1) as LineEdit
			action_name = line_edit.text
			
			if action_name.is_empty():
				line_edit.placeholder_text = "Enter name first"
				line_edit.add_theme_color_override("font_placeholder_color", Color.RED)
				return
			
		

		var key := "input/%s" % action_name.strip_edges()

		if ProjectSettings.has_setting(key):
			print("Overwriting")
			overwrite = true
			
		add_or_rebind_action(action_name, event, overwrite)
		
		text = event.as_text()
		waiting_for_key = false
		
		
func add_or_rebind_action(action_name: String, event: InputEvent, overwrite := true) -> void:
	var key := "input/%s" % action_name

	var action_data: Dictionary

	if ProjectSettings.has_setting(key):
		action_data = ProjectSettings.get_setting(key)
	else:
		action_data = {
			"deadzone": 0.2,
			"events": []
		}

	# Ensure correct structure types
	if !action_data.has("events"):
		action_data["events"] = []

	if overwrite:
		action_data["events"] = []
	else:
		action_data["events"] = action_data["events"].duplicate()

	action_data["events"].append(event)

	ProjectSettings.set_setting(key, action_data)

	# Persist to project.godot
	ProjectSettings.save()
	ProjectSettings.save_custom("project.godot")
