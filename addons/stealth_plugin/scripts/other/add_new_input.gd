@tool
extends Button
@onready var forward: LineEdit = $"../Forward"
@onready var forward_button: Button = $"../ForwardButton"

func _pressed():
	var copyLine = forward.duplicate()
	var copyButton = forward_button.duplicate()
	var index = get_index()
	
	copyLine.text = ""
	copyLine.editable = true
	copyLine.placeholder_text = "New action name..."
	
	copyButton.text = ""
	
	var parent = get_parent()
	parent.add_child(copyLine)
	parent.add_child(copyButton)
	parent.move_child(self, index + 2)
