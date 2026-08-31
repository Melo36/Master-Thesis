@tool
extends EditorPlugin

@onready var apply_button: Button
@onready var apply_button_guard: Button
var model_selection: GridContainer

var wizard: Control
var guard_wizard: Control

var assign_3D_button
var assign_3D_button_guard
var assign_ill_image_button
var assign_state_ind_button

var wizard_elements: int = 15
var guard_wizard_elements: int = 24

func _enter_tree() -> void:
	print("Initializing tree")
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
	
	assign_3D_button = wizard.find_child("3DModelAssignButton", true)
	assign_3D_button_guard = guard_wizard.find_child("3DModelAssignButton", true)
	assign_ill_image_button = wizard.find_child("AssignIllImageButton", true)
	assign_state_ind_button = guard_wizard.find_child("AssignStateIndButton", true)
	
	var selection := get_editor_interface().get_selection()
	selection.selection_changed.connect(_on_selection_changed)
	
func _exit_tree() -> void:
	if wizard:
		remove_control_from_docks(wizard)
		wizard.free()
		wizard = null
		
	if guard_wizard:
		remove_control_from_docks(guard_wizard)
		guard_wizard.free()
		guard_wizard = null
		
	var selection := get_editor_interface().get_selection()
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)

func _on_apply_button_pressed() -> void:
	var scene := get_editor_interface().get_edited_scene_root()
	if scene == null:
		return

	# Always get exactly one player (never cached, never reused)
	var player := _get_or_create_single_player(scene)

	_apply_inputs_to_player(player)

	_replace_model(player, assign_3D_button)
	_replace_indicator_image(player, "LightLevel", assign_ill_image_button)
	
	var animationButtonList = get_tree().get_nodes_in_group("PlayerAnimation")
	_replace_animations(player, animationButtonList, assign_3D_button, "res://animations/default_player/")

func _on_apply_button_guard_pressed() -> void:
	var scene := get_editor_interface().get_edited_scene_root()
	if scene == null:
		return
		
	var guard = _create_guard(scene)

	model_selection = guard_wizard.find_child("ImageSelection", true)
	#_replace_indicator_image(guard, "ImageIndicator", assign_state_ind_button)
	_replace_model(guard, assign_3D_button_guard)
	
	var guardAnimationButtonList = get_tree().get_nodes_in_group("GuardAnimation")
	_replace_animations(guard, guardAnimationButtonList, assign_3D_button_guard, "res://animations/default_guard/")
	_apply_inputs_to_guard(guard)
	
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
	var player := preload("res://scenes/player.tscn").instantiate()
	player.name = "Player"
	player.add_to_group("Player")

	scene.add_child(player)

	# IMPORTANT: ownership must be recursive for saving
	#_set_owner_recursive(player, scene)
	player.owner = scene
	place_character_on_ground(player)
	
	print("Created new player")

	return player
	
	
func _create_guard(scene: Node) -> Node:
	var selected := get_editor_interface().get_selection().get_selected_nodes()
	var length = len(selected)
	if length == 1:
		var agent = selected[0]
		if agent.is_in_group("Guard"):
			return agent
		var child = agent.find_child("Guard")
		if child && child.is_in_group("Guard"):
			return child

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
	#_set_owner_recursive(parent, scene, 3)
	place_character_on_ground(guard)

	# Return this because we dont need the parent
	return guard
	
func place_character_on_ground(character: CharacterBody3D):
	var space_state = character.get_world_3d().direct_space_state

	var start = character.global_position + Vector3.UP * 10.0
	var end = character.global_position + Vector3.DOWN * 100.0

	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [character]

	var result = space_state.intersect_ray(query)

	if result:
		character.global_position.y = result.position.y


# ------------------------------------------------------------
# APPLY INPUT VALUES
# ------------------------------------------------------------

func _apply_inputs_to_player(player: Node) -> void:
	var inputs := get_tree().get_nodes_in_group("PlayerInput")
	var index := 0

	for input in inputs:
		if index > wizard_elements:
			return
		if input is SpinBox:
			player.set(input.name, input.value)
		elif input is CheckBox:
			player.set(input.name, input.button_pressed)

		index += 1
		
func _apply_inputs_to_guard(guard: Node) -> void:
	var inputs := get_tree().get_nodes_in_group("GuardInput")
	var index = 0
	var movement = guard.find_child("GuardMovement")
	var noise = guard.find_child("NoiseSensor")
	var vision = guard.find_child("VisionSensor")
	var gadget_manager = guard.find_child("GadgetManager")
	var state_indicator = guard.find_child("StateIndicator")
	var chase_solver = guard.find_child("ChaseInfluenceMap")

	for input in inputs:
		if index > guard_wizard_elements:
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
		elif parent == "SearchAlgorithm":
			script = chase_solver

		if input is SpinBox:
			script.set(input.name, input.value)
		elif input is CheckBox:
			script.set(input.name, input.button_pressed)
		elif input is ColorPickerButton:
			script.set(input.name, input.color)
		elif input is LineEdit:
			var scene := get_editor_interface().get_edited_scene_root()
			if scene == null:
				break
			state_indicator.owner = scene
			state_indicator.text_indicator.owner = scene
			state_indicator.image_indicator.owner = scene
			script.assign_text(input.text)
		index += 1


# ------------------------------------------------------------
# MODEL REPLACEMENT (SAFE + NO DUPLICATES)
# ------------------------------------------------------------

func _replace_model(agent: Node, button: Button) -> void:
	print("replace_model")
	# Simply pass the path string to the player. 
	# The player's setter script will handle the heavy lifting!
	var model_handler = agent.find_child("ModelHandler")
	var resourcePath = button.resourcePath
	if model_handler && resourcePath:
		model_handler.custom_model_path = resourcePath
	model_handler._load_model()

func _replace_indicator_image(agent: Node, child: String, button: Button) -> void:
	# Simply pass the path string to the player. 
	# The player's setter script will handle the heavy lifting!
	var state_indicator = agent.find_child(child)
	var resourcePath = button.resourcePath
	if state_indicator && resourcePath:
		state_indicator.texture = load(resourcePath)
		
func _replace_animations(agent: Node, animationList: Array, model_button : Button, default_anim_path: String):
	print("replace_animations")
	var lib_name : String = "Custom"
	var animationTree = agent.find_child("AnimationTree", true, false)
	var animationPlayer : AnimationPlayer = agent.find_child("AnimationPlayer", true)
	animationTree.anim_player = animationPlayer.get_path()
	var state_machine = animationTree.tree_root
	
	var library := AnimationLibrary.new()
	var has_custom_model : bool = model_button.resourcePath != ""
	for button in animationList:
		var node = find_state(state_machine, button.name)
		if !node:
			continue
		node.animation = lib_name + "/" + button.name
		var resourcePath : String
		var animation: Animation
		if has_custom_model:
			if button.resourcePath:
				animation = load(button.resourcePath)
		else:
			animation = load(default_anim_path + button.name + ".tres")
		library.add_animation(button.name, animation)
	animationPlayer.add_animation_library(lib_name, library)
			
func find_state(machine: AnimationNodeStateMachine,state_name: String) -> AnimationNodeAnimation:
	if machine.has_node(state_name):
		var state := machine.get_node(state_name)
		if state is AnimationNodeAnimation:
			return state

	for node_name in machine.get_node_list():
		var node := machine.get_node(node_name)

		if node is AnimationNodeStateMachine:
			var result := find_state(node, state_name)
			if result:
				return result

	return null

func _on_selection_changed():
	var selected := get_editor_interface().get_selection().get_selected_nodes()
	var length = len(selected)
	if length > 1 || length == 0:
		return
		
	var agent = selected[0]
	if agent.is_in_group("Player"):
		apply_button.text = "Apply Changes"
		apply_button_guard.text = "Create Guard"
		update_player_wizard(agent)
		return
	elif agent.is_in_group("Guard"):
		apply_button_guard.text = "Apply Changes"
		update_guard_wizard(agent)
		return
	var child = agent.find_child("Guard")
	if child && child.is_in_group("Guard"):
		apply_button_guard.text = "Apply Changes"
		update_guard_wizard(child)
		return
		
	apply_button_guard.text = "Create Guard"
		
func update_player_wizard(player: Node):
	var inputs := get_tree().get_nodes_in_group("PlayerInput")
	var index := 0
	for input in inputs:
		if index > wizard_elements:
			return
		if input is SpinBox:
			input.value = player.get(input.name)
		elif input is CheckBox:
			input.button_pressed = player.get(input.name)
			
		index += 1
	
func update_guard_wizard(guard: Node):
	var inputs := get_tree().get_nodes_in_group("GuardInput")
	var index = 0
	var movement = guard.find_child("GuardMovement")
	var noise = guard.find_child("NoiseSensor")
	var vision = guard.find_child("VisionSensor")
	var gadget_manager = guard.find_child("GadgetManager")
	var state_indicator = guard.find_child("StateIndicator")

	for input in inputs:
		if index > guard_wizard_elements:
			return
		var parent = input.get_parent().get_parent().get_parent().name
		var script = guard
		
		if parent == "MovementSpeed":
			script = movement
		elif parent == "Noise":
			if input.name == "hearing_threshold":
				continue
			script = noise
		elif parent == "Vision":
			script = vision
		elif parent == "StateIndicator":
			script = state_indicator
		elif parent == "Gadgets":
			script = gadget_manager

		if input is SpinBox:
			input.value = script.get(input.name)
		elif input is CheckBox:
			input.button_pressed = script.get(input.name)
		elif input is ColorPickerButton:
			input.color = script.get(input.name)
		elif input is LineEdit:
			input.text = script.text_indicator.text
		index += 1
		
# ------------------------------------------------------------
# OWNER HELPERS
# ------------------------------------------------------------

func _set_owner_recursive(node: Node, owner: Node, level: int = -1) -> void:
	if level == 0:
		return
	node.owner = owner

	for child in node.get_children():
		_set_owner_recursive(child, owner, level - 1)
