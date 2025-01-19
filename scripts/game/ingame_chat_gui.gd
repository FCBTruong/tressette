extends Control

@onready var chat_log = find_child('ChatLog')
var input_label
var input_field
var groups = [
	{'name': 'Team', 'color': '#ffd600'},
	{'name': 'Match', 'color': '#32e400'},
	{'name': 'Global', 'color': '#fc4727'},
	{'name': 'Global', 'color': '#08d99b'}
]

var group_index = 0
var user_name = 'Emilia'

func _ready():
	input_label = get_node("VBoxContainer/HBoxContainer/Label")
	input_field = get_node("VBoxContainer/HBoxContainer/LineEdit")
	input_field.connect("text_submitted", Callable(self, "text_submitted"))


func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			input_field.grab_focus()
		if event.pressed and event.keycode == KEY_ESCAPE:
			input_field.release_focus()

func _click_submit():
	print('_click_submit')
	input_field.release_focus()
	text_submitted(input_field.text)
	
func text_submitted(text):
	if text == '':
		return
	if len(text) >= 100:
		text = text.substr(0, 100)
		
	print(text)
	input_field.text = ''
	user_name = PlayerInfoMgr.my_user_data.name
	add_message(PlayerInfoMgr.my_user_data.uid, user_name, text)
	var pkg = GameConstants.PROTOBUF.PACKETS.InGameChatMessage.new()
	pkg.set_chat_message(text)
	GameClient.send_packet(GameConstants.CMDs.NEW_INGAME_CHAT_MESSAGE, pkg.to_bytes())
	
func add_message(uid, user_name, text):
	var group_index = _get_group_index(uid)
			
	chat_log.text += '[color=' + groups[group_index]['color'] + ']'
	chat_log.text += '[' + user_name + ']: ' + '[/color]'
	chat_log.text += text
	chat_log.text += ''
	chat_log.text += '\n'
	
func on_received_new_chat(uid, message):
	var user_name = str(uid)
	var user = GameConstants.game_logic.get_user(uid)
	if user:
		user_name = user.name
	add_message(uid, user_name, message)
	
func _get_group_index(uid):
	var user = GameConstants.game_logic.get_user(uid)
	if user:
		return user.game_data.seat_id
	return 0
