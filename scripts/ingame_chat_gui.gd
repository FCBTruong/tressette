extends Control

var chat_log
var input_label
var input_field
var groups = [
	{'name': 'Team', 'color': '#f3e700'},
	{'name': 'Match', 'color': '#f3e700'},
	{'name': 'Global', 'color': '#f3e700'}
]

var group_index = 0
var user_name = 'Emilia'

func _ready():
	chat_log = get_node("VBoxContainer/RichTextLabel")
	input_label = get_node("VBoxContainer/HBoxContainer/Label")
	input_field = get_node("VBoxContainer/HBoxContainer/LineEdit")
	input_field.connect("text_submitted", Callable(self, "text_submitted"))


func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			input_field.grab_focus()
		if event.pressed and event.keycode == KEY_ESCAPE:
			input_field.release_focus()

func text_submitted(text):
	print(text)
	input_field.text = ''
	add_message(user_name, text, group_index)
	
func add_message(user_name, text, group_index):
	chat_log.text += '[color=' + groups[group_index]['color'] + ']'
	chat_log.text += '[' + user_name + ']: '
	chat_log.text += text
	chat_log.text += '[/color]'
	chat_log.text += '\n'
