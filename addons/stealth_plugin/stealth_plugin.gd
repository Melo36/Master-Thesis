@tool
extends EditorPlugin

@onready var apply_button: Button
var model_selection: GridContainer

var player

	
func _enter_tree() -> void:
	var wizard = preload("res://addons/stealth_plugin/setup_wizard.tscn").instantiate()
	player = preload("res://scenes/hamster.tscn").instantiate()
	apply_button = wizard.find_children("ApplyButton", "", true)[0]
	model_selection = wizard.find_children("ModelSelection", "", true)[0]
	apply_button.pressed.connect(_on_apply_button_pressed)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL, wizard)

func _on_apply_button_pressed():
	var inputs = get_tree().get_nodes_in_group("ValueInput")
	var index = 0
	
	for input in inputs:
		if index >= 15:
			break
		
		if input is SpinBox:
			player.set(input.name, input.value)
		elif input is CheckBox:
			player.set(input.name, input.pressed)
		index += 1
		
	var edited_scene = get_editor_interface().get_edited_scene_root()
	
	if edited_scene:
		edited_scene.add_child(player)
		player.owner = edited_scene # Makes sure the node is saved with the scene
		if model_selection.modelPath != "":
			add_new_3d_model()
	
func add_new_3d_model():
	var scene: PackedScene = load(model_selection.modelPath)
	var instance = scene.instantiate()
	instance.add_to_group("Model")
	var children = player.get_children()
	for child in children:
		if child.is_in_group("Model"):
			print("removinfg child", child.name)
			child.queue_free()
			break
	player.add_child(instance)

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
