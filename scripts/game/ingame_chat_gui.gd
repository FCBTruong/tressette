extends CanvasLayer

@onready var chat_log = find_child('ChatLog')
@onready var quick_list = find_child("QuickList")
@onready var main_pn = find_child("MainPn")
@onready var quick_chat = find_child("QuickChat")
var main_pn_default_pos
var groups = [
	{'name': 'Team', 'color': '#037509'},
	{'name': 'Match', 'color': '#b46400'},
	{'name': 'Global', 'color': '#254199'},
	{'name': 'Global', 'color': '#be1a94'}
]

var group_index = 0
var user_name = 'Emilia'
var last_time_chat = 0
var quick_chat_pos
@onready var input_field = find_child("LineEdit")
func _ready():
	main_pn_default_pos = main_pn.position
	quick_chat_pos = quick_chat.position
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
			
	chat_log.text += '[color=' + groups[group_index]['color'] + '][b]'
	chat_log.text += '[' + user_name + ']: ' + '[/b][/color]'
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

var tween
func on_show():
	self.visible = true
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	main_pn.position.x = main_pn_default_pos.x - 800
	tween.parallel().tween_property(
		main_pn,
		"position:x",
		main_pn_default_pos.x,
		0.5
	)
	quick_chat.visible = true
	quick_chat.position.x = quick_chat_pos.x + 100
	quick_chat.modulate.a = 0
	tween.parallel().tween_property(
		quick_chat,
		'position:x',
		quick_chat_pos.x,0.3
	).set_delay(0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		quick_chat,
		'modulate:a',
		1,0.3
	).set_delay(0.5)
	pass
func on_hide():
	quick_chat.visible = false
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(
		main_pn,
		"position:x",
		main_pn_default_pos.x - 800,
		0.5
	)
	
	
	tween.tween_callback(
		func():
			self.visible = false
			pass
			)
	pass
