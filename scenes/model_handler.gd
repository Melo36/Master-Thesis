@tool
extends Node3D

const DEFAULT_MODEL_PATH = "res://scenes/character_without_hitbox.tscn"

@export_file("*.tscn") var custom_model_path: String = "":
	set(value):
		custom_model_path = value
		_load_model()

func _load_model() -> void:
	var parent_node := get_parent()
	if not parent_node or not parent_node.is_inside_tree():
		return

	# 1. Get or create the Model container node
	var model_root := parent_node.get_node_or_null("Model") as Node3D
	if not model_root:
		model_root = Node3D.new()
		model_root.name = "Model"
		parent_node.add_child(model_root)
		
		if Engine.is_editor_hint() and get_tree().edited_scene_root:
			model_root.owner = get_tree().edited_scene_root

	# 2. Clear existing child models safely
	for c in model_root.get_children():
		if Engine.is_editor_hint():
			c.free()
		else: 
			c.queue_free()
			

	# 3. Determine resource path to load
	var path_to_load = custom_model_path if custom_model_path != "" else DEFAULT_MODEL_PATH

	if ResourceLoader.exists(path_to_load):
		var model_scene = load(path_to_load) as PackedScene
		if not model_scene:
			return

		var instance = model_scene.instantiate()

		# Ensure AnimationTree exists inside the instantiated scene
		if not instance.find_child("AnimationTree", true):
			var anim_tree = AnimationTree.new()
			anim_tree.name = "AnimationTree"
			anim_tree.tree_root = AnimationNodeStateMachine.new()
			instance.add_child(anim_tree)

		# Add to the tree synchronously
		model_root.add_child(instance)

		# 4. Set owner ONLY on the instance root to keep scene file size small
		if Engine.is_editor_hint() and get_tree().edited_scene_root:
			instance.owner = get_tree().edited_scene_root
			# Do NOT recurse through sub-children! Keeping sub-children owner as null
			# preserves the external scene path link to res:// scenes instead of
			# baking raw 20MB 3D binary data directly into main_scene.tscn.

func _set_owner_recursive(node: Node, scene_root: Node) -> void:
	node.owner = scene_root
	for child in node.get_children():
		_set_owner_recursive(child, scene_root)
