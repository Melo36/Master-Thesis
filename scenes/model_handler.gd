@tool
extends Node3D # Or whatever your player base class is

const DEFAULT_MODEL_PATH = "res://scenes/character_without_hitbox.tscn"

# This exported variable will be saved inside your level scenes
@export_file("*.tscn") var custom_model_path: String = "":
	set(value):
		custom_model_path = value
		if is_inside_tree():
			_load_model()
			
func _ready() -> void:
	if !Engine.is_editor_hint():
		_load_model()

func _load_model() -> void:
	var model_root := get_node_or_null("Model")
	if not model_root:
		model_root = Node3D.new()
		model_root.name = "Model" 
		get_parent().add_child.call_deferred(model_root)
		print("Added to parent")

	# Clear existing children safely
	for c in model_root.get_children():
		if Engine.is_editor_hint():
			c.free()
		else:
			model_root.remove_child(c)
			c.queue_free()

	# Determine what path to load
	var path_to_load = custom_model_path if custom_model_path != "" else DEFAULT_MODEL_PATH

	if ResourceLoader.exists(path_to_load):
		var instance = load(path_to_load).instantiate()
		print("I am ", instance.name)
		for child in instance.get_children():
			print(child.name)
		# Add AnimationTree to Model Node
		if !instance.find_child("AnimationTree", true):
			var animationTree = AnimationTree.new()
			animationTree.name = "AnimationTree"
			animationTree.tree_root = AnimationNodeStateMachine.new()
			instance.add_child(AnimationTree.new())
		model_root.add_child.call_deferred(instance)
		instance.rotation.y = 135
		print("Added instance to Model Node")
		
		# If we are in the editor, ensure it belongs to the scene root so it's visible/editable
		if Engine.is_editor_hint() and get_tree().edited_scene_root:
			instance.owner = get_tree().edited_scene_root
			
		# --- RE-INITIALIZE YOUR ANIMATION TREE HERE ---
		# e.g., if your AnimationTree needs to target the new model:
		# if has_node("AnimationTree"):
		#     get_node("AnimationTree").anim_player = instance.get_node("AnimationPlayer").get_path()
