@tool
extends Node3D

const DEFAULT_PLAYER_PATH = "res://scenes/character_without_hitbox.tscn"
const DEFAULT_GUARD_PATH = "res://scenes/guard_model.tscn"

const DEFAULT_ANIMATION_TREE : String = "res://scenes/animation_tree.tscn"
const DEFAULT_ANIMATION_TREE_GUARD : String = "res://scenes/animation_tree_guard.tscn"

@export_file("*.tscn") var custom_model_path: String = "":
	set(value):
		custom_model_path = value

func _load_model() -> void:
	var edited_scene = get_tree().edited_scene_root
	var parent_node := get_parent()
	if not parent_node or not parent_node.is_inside_tree():
		return

	# 1. Get or create the Model container node
	var model_root := parent_node.get_node_or_null("Model") as Node3D
	if not model_root:
		model_root = Node3D.new()
		model_root.name = "Model"
		parent_node.add_child(model_root)
		model_root.rotate_y(135)
		
		if Engine.is_editor_hint() and get_tree().edited_scene_root:
			model_root.owner = get_tree().edited_scene_root

	# 2. Clear existing child models safely
	for c in model_root.get_children():
		if Engine.is_editor_hint():
			c.free()
		else: 
			c.queue_free()
			

	# 3. Determine resource path to load
	var path_to_load
	if parent_node.name == "Player":
		path_to_load = custom_model_path if custom_model_path != "" else DEFAULT_PLAYER_PATH
	elif parent_node.name == "Guard":
		path_to_load = custom_model_path if custom_model_path != "" else DEFAULT_GUARD_PATH

	if ResourceLoader.exists(path_to_load):
		var model_scene = load(path_to_load) as PackedScene
		if not model_scene:
			return

		var instance = model_scene.instantiate()

		var animationTree : AnimationTree = instance.find_child("AnimationTree", true, false)
		# Ensure AnimationTree exists inside the instantiated scene
		if not animationTree:
			print("Adding animation tree")
			animationTree = preload(DEFAULT_ANIMATION_TREE).instantiate()
			animationTree.name = "AnimationTree"
			instance.add_child(animationTree)
			
		# Add to the tree synchronously
		model_root.add_child(instance)
		
		# 4. Set owner ONLY on the instance root to keep scene file size small
		if Engine.is_editor_hint() and edited_scene:
			if parent_node.name == "Player":
				instance.owner = edited_scene
				var animationPlayer = instance.find_child("AnimationPlayer", true, false)
				animationPlayer.owner = edited_scene
				animationTree.owner = edited_scene
			else:
				_set_owner_recursive(model_root, edited_scene, 2)
			# Do NOT recurse through sub-children! Keeping sub-children owner as null
			# preserves the external scene path link to res:// scenes instead of
			# baking raw 20MB 3D binary data directly into main_scene.tscn.

func _set_owner_recursive(node: Node, scene_root: Node, level: int) -> void:
	if level == 0:
		return
	node.owner = scene_root
	for child in node.get_children():
		_set_owner_recursive(child, scene_root, level - 1)
