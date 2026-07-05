extends Node

@onready var player = get_parent()

@onready var shuriken_label: Label = $"../CanvasLayer/ShurikenUI/ShurikenLabel"
@onready var bell_label: Label = $"../CanvasLayer/BellUI/BellLabel"

func _ready() -> void:
	player.shuriken_changed.connect(_on_shuriken_changed)
	player.bells_changed.connect(_on_bells_changed)

	# initialize UI
	_on_shuriken_changed(player.shuriken)
	_on_bells_changed(player.bells)

func _on_shuriken_changed(value: int) -> void:
	shuriken_label.text = str(value)

func _on_bells_changed(value: int) -> void:
	bell_label.text = str(value)
