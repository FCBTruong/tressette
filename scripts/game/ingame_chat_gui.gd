extends Control

@onready var chat_log = find_child('ChatLog')
@onready var quick_list = find_child("QuickList")
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
var last_time_chat = 0

func _ready():
	input_label = get_node("VBoxContainer/HBoxContainer/Label")
	input_field = get_node("VBoxContainer/HBoxContainer/LineEdit")
	input_field.connect("text_submitted", Callable(self, "text_submitted"))
	
	for c in quick_list.get_children():
		c.queue_free()
	
	var quick_chat_node = load("res://scenes/board/QuickChatNode.tscn")
	for i in range(6):
		var n = quick_chat_node.instantiate()
		quick_list.add_child(n)
		n.set_text(tr("QUICK_CHAT_" + str(i)))
		n.parent = self

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
		
	var now = g.v.game_manager.get_timestamp_client()
	if now - last_time_chat < 1:
		# too fast
		return
	last_time_chat = now
		
	print(text)
	input_field.text = ''
	user_name = g.v.player_info_mgr.my_user_data.name
	add_message(g.v.player_info_mgr.my_user_data.uid, user_name, text)
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.InGameChatMessage.new()
	pkg.set_chat_message(text)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.NEW_INGAME_CHAT_MESSAGE, pkg.to_bytes())
	
func add_message(uid, user_name, text):
	var group_index = _get_group_index(uid)
			
	chat_log.text += '[color=' + groups[group_index]['color'] + ']'
	chat_log.text += '[' + user_name + ']: ' + '[/color]'
	chat_log.text += text
	chat_log.text += ''
	chat_log.text += '\n'
	
func on_received_new_chat(uid, message):
	var cur_scene = g.v.scene_manager.get_current_scene()
	if cur_scene is BaseBoardScene:
		var user_name = str(uid)
		var user = cur_scene.game_logic.get_user(uid)
		if user:
			user_name = user.name
		add_message(uid, user_name, message)
	
func _get_group_index(uid):
	var cur_scene = g.v.scene_manager.get_current_scene()
	if cur_scene is BaseBoardScene:
		var user = cur_scene.game_logic.get_user(uid)
		if user:
			return user.game_data.seat_id
	return 0
