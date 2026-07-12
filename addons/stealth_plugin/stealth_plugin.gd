@tool
extends EditorPlugin

@onready var apply_button: Button
@onready var apply_button_guard: Button
var model_selection: GridContainer

func _enter_tree() -> void:
	var wizard = preload("res://addons/stealth_plugin/setup_wizard.tscn").instantiate()
	var guardWizard = preload("res://addons/stealth_plugin/guard_setup_wizard.tscn").instantiate()

	apply_button = wizard.find_child("ApplyButton", true)
	apply_button_guard = guardWizard.find_child("ApplyButton", true)
	model_selection = wizard.find_children("ModelSelection", "", true)[0]

	apply_button.pressed.connect(_on_apply_button_pressed)
	apply_button_guard.pressed.connect(_on_apply_button_guard_pressed)

	add_control_to_dock(DOCK_SLOT_LEFT_BL, wizard)
	add_control_to_dock(DOCK_SLOT_LEFT_BL, guardWizard)


func _on_apply_button_guard_pressed() -> void:
	var scene := get_editor_interface().get_edited_scene_root()
	if scene == null:
		return
		
	var guard = _create_guard(scene)
		
	_apply_inputs_to_guard(guard)
	

func _on_apply_button_pressed() -> void:
	var scene := get_editor_interface().get_edited_scene_root()
	if scene == null:
		return

	# Always get exactly one player (never cached, never reused)
	var player := _get_or_create_single_player(scene)

	_apply_inputs_to_player(player)

	if model_selection.modelPath != "":
		_replace_model(player, scene)


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
	var patrolRoute = Node3D.new()
	patrolRoute.name = "PatrolRoute"
	parent.add_child(patrolRoute)

	for i in range(5):
		patrolRoute.add_child(Marker3D.new())
	
	var guard := preload("res://scenes/guard.tscn").instantiate()
	guard.name = "Guard"
	guard.add_to_group("Guard")
	parent.add_child(guard)

	scene.add_child(parent)

	# IMPORTANT: ownership must be recursive for saving
	_set_owner_recursive(parent, scene)

	# Return this because we dont need the parent
	return guard


# ------------------------------------------------------------
# APPLY INPUT VALUES
# ------------------------------------------------------------

func _apply_inputs_to_player(player: Node) -> void:
	var inputs := get_tree().get_nodes_in_group("ValueInput")
	var index := 0

	for input in inputs:
		if index >= 15:
			break

		if input is SpinBox:
			player.set(input.name, input.value)
		elif input is CheckBox:
			player.set(input.name, input.pressed)

		index += 1


func _apply_inputs_to_guard(guard: Node) -> void:
	var inputs := get_tree().get_nodes_in_group("ValueInput")
	var index := 0
	var movement = guard.find_child("GuardMovement")
	var noise = guard.find_child("NoiseSensor")
	var vision = guard.find_child("VisionSensor")
	var state_indicator = guard.find_child("StateIndicator")

	for input in inputs:
		if index >= 21:
			break
			
		var parent = input.get_parent().get_parent().name
		var script = guard
		
		if parent == "MovementSpeed":
			script = movement
		elif parent == "Noise":
			script = noise
		elif parent == "Vision":
			script = vision
		elif parent == "State Indicator":
			script = state_indicator
			

		if input is SpinBox:
			script.set(input.name, input.value)
		elif input is CheckBox:
			script.set(input.name, input.pressed)
		elif input is ColorPickerButton:
			script.set(input.name, input.color)

		index += 1


# ------------------------------------------------------------
# MODEL REPLACEMENT (SAFE + NO DUPLICATES)
# ------------------------------------------------------------

func _replace_model(player: Node, owner: Node) -> void:
	# Simply pass the path string to the player. 
	# The player's setter script will handle the heavy lifting!
	var model_handler = player.find_child("ModelHandler")
	if model_handler:
		model_handler.custom_model_path = model_selection.modelPath


# ------------------------------------------------------------
# OWNER HELPERS
# ------------------------------------------------------------

func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner

	for child in node.get_children():
		_set_owner_recursive(child, owner)


func _exit_tree() -> void:
	pass
