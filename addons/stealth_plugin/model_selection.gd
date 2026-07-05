@tool
extends GridContainer

@onready var assign_button: Button = $AssignButton
@onready var model_file_dialog: FileDialog = $ModelFileDialog
var player
var modelPath := ""

func _ready():
	assign_button.pressed.connect(_on_select_model_pressed)
	model_file_dialog.file_selected.connect(_on_file_selected)


func _on_select_model_pressed():
	model_file_dialog.popup_centered()

func _on_file_selected(path: String):
	if path.is_empty():
		return
		
	assign_button.text = path
	modelPath = path
