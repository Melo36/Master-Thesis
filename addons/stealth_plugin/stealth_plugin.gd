@tool
extends EditorPlugin

@onready var apply_button: Button
var model_selection: GridContainer


func _enter_tree() -> void:
	var wizard = preload("res://addons/stealth_plugin/setup_wizard.tscn").instantiate()

	apply_button = wizard.find_children("ApplyButton", "", true)[0]
	model_selection = wizard.find_children("ModelSelection", "", true)[0]

	apply_button.pressed.connect(_on_apply_button_pressed)

	add_control_to_dock(DOCK_SLOT_LEFT_BL, wizard)


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
			players[i].queue_free()

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


# ------------------------------------------------------------
# MODEL REPLACEMENT (SAFE + NO DUPLICATES)
# ------------------------------------------------------------

func _replace_model(player: Node, owner: Node) -> void:
	var model_root := player.get_node_or_null("Model")

	if model_root == null:
		model_root = Node3D.new()
		model_root.name = "Model"
		player.add_child(model_root)
		model_root.owner = owner

	# Clear existing model safely
	for c in model_root.get_children():
		c.queue_free()

	# Add new model
	var instance : Node = load(model_selection.modelPath).instantiate()
	model_root.add_child(instance)

	_set_owner_recursive(instance, owner)


# ------------------------------------------------------------
# OWNER HELPERS
# ------------------------------------------------------------

func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner

	for child in node.get_children():
		_set_owner_recursive(child, owner)


func _exit_tree() -> void:
	pass
