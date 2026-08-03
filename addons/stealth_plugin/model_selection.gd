@tool
extends Button
@onready var model_file_dialog: FileDialog

var player
var resourcePath := ""

func _ready():
	model_file_dialog = get_parent().get_child(get_index() + 1)
	pressed.connect(_on_select_model_pressed)
	model_file_dialog.file_selected.connect(_on_file_selected)

func _on_select_model_pressed():
	model_file_dialog.popup_centered()

func _on_file_selected(path: String):
	if path.is_empty():
		return
		
	text = path
	resourcePath = path
