@tool
extends EditorPlugin

var value_dict = ["walking_noise", "sprinting_noise", "crouched_noise", "crawling_noise", "walk_speed",
"sprint_speed", "crouch_speed", "crawl_speed", "charge_speed", "max_charge"]

@onready var apply_button: Button

var player

func _enter_tree() -> void:
	var wizard = preload("res://addons/stealth_plugin/setup_wizard.tscn").instantiate()
	player = preload("res://scenes/hamster.tscn").instantiate()
	var children = wizard.get_children()
	apply_button = wizard.find_children("ApplyButton", "", true)[0]
	apply_button.pressed.connect(_on_apply_button_pressed)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL, wizard)
	

func _on_apply_button_pressed():
	var inputs = get_tree().get_nodes_in_group("ValueInput")
	print(len(inputs))
	var index = 0
	for input in inputs:
		if index >= 10:
			return
		print(input)
		player[value_dict[index]] = input.value
		index += 1
		print("New noise ", player.walking_noise)
	

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
