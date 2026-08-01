@tool
extends EditorPlugin

@onready var apply_button: Button
@onready var apply_button_guard: Button
var model_selection: GridContainer

var wizard: Control
var guard_wizard: Control

func _enter_tree() -> void:
	if wizard == null:
		wizard = preload("res://addons/stealth_plugin/setup_wizard.tscn").instantiate()
		add_control_to_dock(DOCK_SLOT_LEFT_BL, wizard)
		
	if guard_wizard == null:
		guard_wizard = preload("res://addons/stealth_plugin/guard_setup_wizard.tscn").instantiate()
		add_control_to_dock(DOCK_SLOT_LEFT_BL, guard_wizard)

	apply_button = wizard.find_child("ApplyButton", true)
	apply_button_guard = guard_wizard.find_child("ApplyButton", true)
	apply_button.pressed.connect(_on_apply_button_pressed) 
	apply_button_guard.pressed.connect(_on_apply_button_guard_pressed)
	
func _exit_tree() -> void:
	if wizard:
		remove_control_from_docks(wizard)
		wizard.free()
		wizard = null
		
	if guard_wizard:
		remove_control_from_docks(guard_wizard)
		guard_wizard.free()
		guard_wizard = null

func _on_apply_button_pressed() -> void:
	var scene := get_editor_interface().get_edited_scene_root()
	if scene == null:
		return

	# Always get exactly one player (never cached, never reused)
	var player := _get_or_create_single_player(scene)

	_apply_inputs_to_player(player)

	model_selection = wizard.find_child("ModelSelection", true)
	_replace_model(player)

func _on_apply_button_guard_pressed() -> void:
	var scene := get_editor_interface().get_edited_scene_root()
	if scene == null:
		return
		
	var guard = _create_guard(scene)
		
	_apply_inputs_to_guard(guard)

	model_selection = guard_wizard.find_child("ImageSelection", true)
	_replace_indicator_image(guard)
	

# ------------------------------------------------------------
# PLAYER (STRICT SINGLE INSTANCE GUARANTEE)
# ------------------------------------------------------------

func _get_or_create_single_player(scene: Node) -> Node:
	var players := scene.get_tree().get_nodes_in_group("Player")

	# If multiple exist → destroy extras (prevents duplication permanently)
	if players.size() > 1:
		for i in range(1, players.size()):
			players[i].free()

	# If one exists → reuse it
	if players.size() == 1:
		return players[0]

	# Otherwise create new ONE
	var player := preload("res://scenes/hamster.tscn").instantiate()
	player.name = "Player"
	player.add_to_group("Player")

	scene.add_child(player)

	# IMPORTANT: ownership must be recursive for saving
	_set_owner_recursive(player, scene)

	return player
	
	
func _create_guard(scene: Node) -> Node:
	var parent = Node3D.new()
	parent.name = "Guard"
	var patrolRoute = Path3D.new()
	patrolRoute.name = "Path3D"
	parent.add_child(patrolRoute)
	
	var guard := preload("res://scenes/guard.tscn").instantiate()
	guard.name = "Guard"
	guard.add_to_group("Guard")
	parent.add_child(guard)
	guard.global_position.y = 0.6

	scene.add_child(parent)

	# IMPORTANT: ownership must be recursive for saving
	parent.owner = scene
	guard.owner = scene
	patrolRoute.owner = scene
	#_set_owner_recursive(parent, scene)

	# Return this because we dont need the parent
	return guard


# ------------------------------------------------------------
# APPLY INPUT VALUES
# ------------------------------------------------------------

func _apply_inputs_to_player(player: Node) -> void:
	var inputs := get_tree().get_nodes_in_group("PlayerInput")
	var index := 0

	for input in inputs:
		if input is SpinBox:
			player.set(input.name, input.value)
		elif input is CheckBox:
			player.set(input.name, input.pressed)

		index += 1
		
func _apply_inputs_to_guard(guard: Node) -> void:
	var inputs := get_tree().get_nodes_in_group("GuardInput")
	var index = 0
	var movement = guard.find_child("GuardMovement")
	var noise = guard.find_child("NoiseSensor")
	var vision = guard.find_child("VisionSensor")
	var gadget_manager = guard.find_child("GadgetManager")
	var state_indicator = guard.find_child("StateIndicator")

	for input in inputs:
		if index > 22:
			return
		var parent = input.get_parent().get_parent().get_parent().name
		var script = guard
		
		if parent == "MovementSpeed":
			script = movement
		elif parent == "Noise":
			script = noise
		elif parent == "Vision":
			script = vision
		elif parent == "StateIndicator":
			script = state_indicator
		elif parent == "Gadgets":
			script = gadget_manager

		if input is SpinBox:
			print(input.name, " ", input.value)
			script.set(input.name, input.value)
		elif input is CheckBox:
			print(input.name, " ", input.button_pressed)
			script.set(input.name, input.button_pressed)
		elif input is ColorPickerButton:
			print(input.name, " ", input.color)
			script.set(input.name, input.color)
		index += 1


# ------------------------------------------------------------
# MODEL REPLACEMENT (SAFE + NO DUPLICATES)
# ------------------------------------------------------------

func _replace_model(player: Node) -> void:
	# Simply pass the path string to the player. 
	# The player's setter script will handle the heavy lifting!
	var model_handler = player.find_child("ModelHandler")
	if model_handler:
		model_handler.custom_model_path = model_selection.modelPath

func _replace_indicator_image(guard: Node) -> void:
	# Simply pass the path string to the player. 
	# The player's setter script will handle the heavy lifting!
	var state_indicator = guard.find_child("StateIndicator")
	if state_indicator:
		state_indicator.assign_image(model_selection.modelPath)
# ------------------------------------------------------------
# OWNER HELPERS
# ------------------------------------------------------------

func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner

	for child in node.get_children():
		_set_owner_recursive(child, owner)
