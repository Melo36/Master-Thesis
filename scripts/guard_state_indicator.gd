@tool
extends Node3D
# Floating "!" above the guard. Color/opacity reflect the brain's current state:
#   - CHASE / SEARCH_LOST → red (solid)
#   - INVESTIGATE         → yellow (solid)
#   - otherwise (PATROL)  → white, alpha = vision detection strength

@export var color_chase: Color = Color(1.0, 0.15, 0.15)
@export var color_investigate: Color = Color(1.0, 0.9, 0.15)
@export var color_detecting: Color = Color(1.0, 1.0, 1.0)

@onready var brain: Node = get_parent()
@onready var vision: Node = brain.get_node("VisionSensor")
@onready var text_indicator: Label3D = $TextIndicator
@onready var image_indicator: Sprite3D = $ImageIndicator


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if text_indicator:
		change_color(text_indicator)
	if image_indicator:
		change_color(image_indicator)
		
func change_color(indicator: Node):
	var s: int = brain.current_state
	if s == brain.State.CHASE or s == brain.State.SEARCH_LOST:
		indicator.modulate = color_chase
		indicator.visible = true
	elif s == brain.State.INVESTIGATE:
		indicator.modulate = color_investigate
		indicator.visible = true
	else:
		var det: float = vision.get_detection_strength()
		var c: Color = color_detecting
		c.a = det
		indicator.modulate = c
		indicator.visible = det > 0.01

func assign_image(path: String):
	image_indicator.texture = load(path)
