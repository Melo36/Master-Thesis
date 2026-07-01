@tool
extends EditorPlugin


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	var wizard = preload("res://addons/stealth_plugin/setup_wizard.tscn").instantiate()
	var player = preload("res://scenes/hamster.tscn").instantiate()
	var children = wizard.get_children()
	
	for child in children:
		if !child.is_in_group("ValueInput"):
			continue
		print(child.name)
		player.walking_noise = child.get_child(1).value
		print("Assigned Value ", player.walking_noise)
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL, wizard)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
