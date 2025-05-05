extends BaseBoardScene
class_name SetteMezzoScene

# Called when the node enters the scene tree for the first time.
var my_card_panel
var play_ground
var list_my_cards = []
var list_players = []
var _cur_focusing_card = null
var place_card_node = null
var tween: Tween
var tween_animate: Tween
var is_portrait = false
@onready var players_pn = find_child("PlayersPn")
@onready var center_play_pn = find_child('CenterPlayPn')
@onready var cardback_node = find_child('CardBack')
@onready var seat_pos0 = find_child('PlayerPos0')
@onready var seat_pos1 = find_child('PlayerPos1')
@onready var seat_pos2 = find_child('PlayerPos2')
@onready var seat_pos3 = find_child('PlayerPos3')
@onready var place_card0 = find_child('PlaceCard0')
@onready var place_card1 = find_child('PlaceCard1')
@onready var place_card2 = find_child('PlaceCard2')
@onready var place_card3 = find_child('PlaceCard3')
@onready var remain_cards_lb = find_child('RemainCardsLb')

@onready var countdown_start_lb = find_child('CountdownStartLb')
@onready var room_id_lb = find_child('RoomIdLb')
@onready var pn_cheat = find_child('PnCheat')
@onready var in_game_chat_gui = find_child('InGameChatGui')
@onready var chat_btn = find_child('ChatBtn')
@onready var chat_btn_reddot = chat_btn.find_child('RedDot')
@onready var waiting_other_lb = find_child('WaitingOtherLb')
@onready var back_btn = find_child("BackBtn")
@onready var bet_lb = find_child("BetLb")
@onready var pot_value_lb:Label = find_child("PotValueLb")
@onready var center_play_pn_pos
@onready var game_start_lb = find_child("GameStartLb")
@onready var round_lb = find_child("RoundLb")
@onready var action_btn_pn = find_child("ActionBtnPn")
@onready var reach_point_win_lb = find_child("ReachPointWinLb")
@onready var auto_play_pn = find_child("AutoPlayPn")
@onready var bet_info_pn = find_child("BetInfoPn")

const DEFAULT_CARD_Z_INDEX = 10
const WIN_CARD_Z_INDEX = 101
const CHAT_EMO_Z_INDEX = 200
const TIME_VIEW_CARD = 1.1
const CARD_DISTANCE_BETWEEN = 90

var card_scene = preload("res://scenes/board/Card.tscn")
var game_logic: SetteMezzoMgr
var SCALE_CARD_DEAL_INIT = 0.8	
var SCALE_CARD_DRAW = 0.6
var SCALE_CARD_NORMAL = 1
var base_text = tr('WAITING_FOR_OTHERS')
var game_start_lb_default_pos
var is_auto_play = false
var list_napoli_highlights = []
var center_play_pn_default_pos
var start_card_pos
@onready var card_cont0 = find_child("CardContainer0")
@onready var card_cont1 = find_child("CardContainer1")
@onready var card_cont2 = find_child("CardContainer2")
@onready var card_cont3 = find_child("CardContainer3")
@onready var card_cont_dealer = find_child("CardContainerDealer")

func _ready() -> void:	
	start_card_pos = find_child("Dealer").global_position
	start_card_pos += Vector2(60, 130)
	game_logic = g.v.sette_mezzo_mgr
	center_play_pn_default_pos = center_play_pn.position
	get_tree().get_root().connect("size_changed", _on_screen_resized)
	_on_screen_resized()
	
	if true:
		self.bet_info_pn.visible = false

	is_auto_play = false
	game_start_lb_default_pos = game_start_lb.position
	g.v.scene_manager.INSTANCES.BOARD_SCENE = self
	my_card_panel = find_child('MyCardPanel')
	play_ground = find_child('PlayGround')
	place_card_node = find_child('PlaceCard1')
	countdown_start_lb.visible = false

	_on_enter()
	action_btn_pn.z_index = 200
	auto_play_pn.z_index = 300
			
	g.v.sound_manager.play_music_board()
	#show_prepare_start()
func _get_card_rotates(n):
	if n == 1:
		return [0]
	var rot_max_radians = deg_to_rad(rot_max * n / 10)
	var arr = []
	for i in range(n):
		var rot_radians: float = lerp_angle(-rot_max_radians, rot_max_radians, float(i)/float(n-1))
		arr.append(rot_radians)
	return arr

func reset_scores():
	card_cont0.find_child("LbScore").text = ''
	card_cont1.find_child("LbScore").text = ''
	card_cont2.find_child("LbScore").text = ''
	card_cont3.find_child("LbScore").text = ''
	card_cont_dealer.find_child("LbScore").text = ''
	lb_my_score.text = ''
	
func _on_enter():
	reset_scores()
	# init player slot
	for p in list_players:	
		p.queue_free()
	list_players.clear()
	_create_players(game_logic.match_data.player_mode)
	
	
	game_start_lb.visible = false
	auto_play_pn.visible = false
	on_update_players()
	update_remain_cards()
	in_game_chat_gui.visible = false
	in_game_chat_gui.z_index = 200
	chat_btn.visible = g.v.game_manager.enable_chat_ingame
	chat_btn_reddot.visible = false
	pn_cheat.visible = false #g.v.config.CURRENT_MODE != g.v.config.MODES.LIVE
	room_id_lb.text = tr("ROOM_ID") + ': ' + str(game_logic.match_data.match_id)
	if game_logic.match_data.state == MatchData.MATCH_STATE.PLAYING:
		update_cards_on_table()
		update_banker()
		
	update_cards_on_table()
	bet_lb.text = tr("BET") + ": " + StringUtils.symbol_number(game_logic.match_data.bet)
	on_user_turn()
	
func update_banker():
	pass
func update_cards_on_table():
	# Update my cards
	remove_all_current_cards()	
	# update current cards
	var cards = game_logic.get_my_cards()
	var number = len(cards)
	var rotates = _get_card_rotates(number)
	for i in range(number):
		var instance = card_scene.instantiate()
		play_ground.add_child(instance)
		instance.set_card(cards[i])
		instance.turn_face_up()
		instance.scale = Vector2(SCALE_CARD_NORMAL, SCALE_CARD_NORMAL)
		list_my_cards.append(instance)
		
	_update_my_card_positions()
	
	# update other cards on table
	for p in list_players:
		if p.user_data.uid == g.v.player_info_mgr.get_user_id():
			continue
		_show_cards_player(p)
	_show_card_dealer()

func _show_card_dealer():
	var cards = game_logic.dealer_cards
	var size = card_cont_dealer.size
	var i = 0
	for c in cards:
		var n = card_scene.instantiate()
		self.node_card_map[-1].append(n)
		card_cont_dealer.add_child(n)
		n.set_card(c)
		if c == -1:
			n.turn_face_down()
		else:
			n.turn_face_up()
		n.scale = Vector2(0.4, 0.4)
		i += 1
		
	var j = 0
	var arr_pos = get_pos_card_table(-1)
	for c in self.node_card_map[-1]:
		c.position = arr_pos[j]
		j += 1
		
func _show_cards_player(p):
	var seat_id = p.user_data.game_data.seat_id
	var card_cont = get_card_container(seat_id)
	var cards = p.user_data.game_data.cards

	for i in range(cards.size()):
		var card = card_scene.instantiate()
		self.node_card_map[seat_id].append(card)
		card_cont.add_child(card)
		card.set_card(cards[i])
		card.turn_face_up()
		card.scale = Vector2(0.4, 0.4)

	var arr_pos = get_pos_card_table(seat_id)
	var children = self.node_card_map[seat_id]
	for i in range(children.size()):
		children[i].position = arr_pos[i]

func get_card_container(seat_id):
	match seat_id:
		0: return card_cont0
		1: return card_cont1
		2: return card_cont2
		3: return card_cont3
		-1: return card_cont_dealer
	return null

func get_pos_card_table(seat_id):
	var card_cont = get_card_container(seat_id)
	if not card_cont:
		return []

	var arr = []
	var count = self.node_card_map[seat_id].size()

	if seat_id in [0, 3]:  # Left to right alignment
		for i in range(count):
			arr.append(Vector2(i * 40, 0))
	elif seat_id in [1, 2]:  # Right to left alignment
		for i in range(count):
			arr.append(Vector2(card_cont.size.x - i * 40, 0))
	elif seat_id == -1:  # Dealer centered alignment
		for i in range(count):
			var x = 40 * (i - (count - 1) / 2.0) + card_cont.size.x / 2
			arr.append(Vector2(x, 0))

	return arr

func continue_play():
	if game_logic.match_data.state == MatchData.MATCH_STATE.PLAYING:
		return
	reset_scores()
		
	if self.is_auto_play:
		# quit
		g.v.game_manager.send_register_leave_game()
	cardback_node.visible = false
	remove_all_current_cards()

	pot_value_lb.text = '0'
	round_lb.text = ''

func on_game_start():
	# clear all current cards
	remove_all_current_cards()
	game_start_lb.text = tr("GAME_START")
	_eff_text_middle()
	update_banker()
	reset_scores()
	
func _eff_text_middle():
	# effect start game
	game_start_lb.visible = true
	game_start_lb.position = game_start_lb_default_pos
	game_start_lb.position.x -= 200
	game_start_lb.modulate.a = 0
	var start_eff_tween = create_tween()
	start_eff_tween.parallel().tween_property(
		game_start_lb,
		"position",
		game_start_lb_default_pos,
		0.3
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	start_eff_tween.parallel().tween_property(
		game_start_lb,
		"modulate:a",
		1,
		0.3
	)
	
	var p2 = game_start_lb_default_pos
	p2.x += 200
	start_eff_tween.tween_interval(0)
	#start_eff_tween.parallel().tween_callback(
		##self._effect_pot_contribute
	#).set_delay(0.2)
	start_eff_tween.parallel().tween_property(
		game_start_lb,
		"position",
		p2,
		0.3
	).set_delay(0.5)
	start_eff_tween.parallel().tween_property(
		game_start_lb,
		"modulate:a",
		0,
		0.3
	).set_delay(0.5)
	
func on_new_round():
	game_start_lb.text = tr("ROUND") + " " + str(game_logic.match_data.current_round)
	_eff_text_middle()
	
func on_update_players():
	var players_info = game_logic.get_list_player()
	var i = 0

	for info in players_info:
		list_players[i].set_user_data(info)
		i += 1
	update_player_seat()
	
# Function to create players
func _create_players(player_count: int) -> void:
	var player_scene = load("res://scenes/sette_mezzo/SetteMezzoPlayer.tscn")  # Load player scene
	
	for i in range(player_count):
		var player_instance = player_scene.instantiate()  # Create a new player instance
		player_instance.name = "Player_%d" % i  # Name the player nodes uniquely
		
		# Add to the current scene
		players_pn.add_child(player_instance)
		list_players.append(player_instance)

func update_player_seat():
	for player in list_players:
		var seat_id = player.user_data.game_data.seat_id
		var pos = _get_seat_position(g.v.sette_mezzo_mgr.match_data.player_mode, seat_id)
		player.global_position = pos
		
func _get_seat_position(mode_player: int, seat_id: int):
	match seat_id:
		0: 
			return seat_pos0.global_position
		1:
			return seat_pos1.global_position
		2:
			return seat_pos2.global_position
		3: 
			return seat_pos3.global_position
	return null
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if game_logic.match_data.state == MatchData.MATCH_STATE.WAITING:
		var cur = int(Time.get_unix_time_from_system())
		var str = base_text
		if cur % 4 == 1:
			str = base_text + " ."
		elif cur % 4 == 2:
			str = base_text + " .."
		elif cur % 4 == 3:
			str = base_text + " ..."
		self.waiting_other_lb.text = str
	else:
		self.waiting_other_lb.text = ''
	if countdown_timer and countdown_start_lb.visible:
		var time_left_str = str(ceil(countdown_timer.time_left))
		#if countdown_start_lb.text != time_left_str:
			## effect zoom and disppear
		countdown_start_lb.text = time_left_str
		if countdown_timer.time_left <= 0:
			countdown_start_lb.visible = false


func _update_my_card_positions(effect = false):
	var list = []
	for card in list_my_cards:
		if card.is_played:
			continue
		list.append(card)
	var size = len(list)
	var list_pos = _calculate_world_card_positions(size)
	var rotates = _get_card_rotates(size)
	var tween = create_tween()
	for i in range(len(list)):
		var card = list[i]
		card.z_index = DEFAULT_CARD_Z_INDEX + i
		var desired_pos = list_pos[i]
		var desired_rot = rotates[i]
		if not effect:
			card.global_position = desired_pos
			#card.rotation = desired_rot
		else:
			tween.parallel().tween_property(card, 'global_position', desired_pos, 0.3)
			#tween.parallel().tween_property(card, 'rotation', desired_rot, 0.3)
		
func on_focus_card(card_id: int) -> void:
	var card = _get_my_card(card_id)
	if card.is_played:
		return
	if _cur_focusing_card:
		_cur_focusing_card.set_state_focusing(false)
	if _cur_focusing_card == card:
		_cur_focusing_card = null
		return
	_cur_focusing_card = card
	card.set_state_focusing(true)

func _get_my_card(id):
	for i in range(len(list_my_cards)):
		var c = list_my_cards[i]
		if c.get_card_id() == id:
			return c
	return null
	
func play_my_card(id: int, auto: bool = false):	
	pass

var win_messages = [
		'FANTASTIC',
		'WELL_DONE',
		'GREAT_JOB',
		'CONGRATULATION',
		'YOU_ARE_AMAZING'
	]
var lose_msgs = ['BAD_LUCK', 'TRY_AGAIN', 'DONT_GIVE_UP', 'KEEP_GOING']
func on_finishhand(delay = 0.5, is_end_round = false):
	return

func _cal_portrait_world_card_positions(number):
	return []
	

func _calculate_world_card_positions(number: int):
	if is_portrait:
		return _cal_portrait_world_card_positions(number)
	var list_pos = []
	var p_center = Vector2(my_card_panel.size.x / 2, my_card_panel.size.y / 2)
	var distance = CARD_DISTANCE_BETWEEN
	
	# Calculate positions for each not-played card, centering around p_center
	var index = 0
	var mid = (number - 1) / 2.0
	for i in range(number):
		var pos = Vector2()
		pos.x = p_center.x + (index - mid) * distance
		pos.y = p_center.y
		
		var global_pos = my_card_panel.get_global_transform().origin + pos
		list_pos.append(global_pos)
		index += 1
	
	return list_pos
	
@export var card_offset_x: float = 20.0
@export var rot_max: float = 19.0
@export var anim_offset_y: float = 0.3
var sine_offset_mult: float = 0.0
var node_card_map: Dictionary = {}
func remove_all_current_cards():
	for card in list_my_cards:
		card.queue_free()
		
	for key in node_card_map:
		for node in node_card_map[key]:
			if is_instance_valid(node):
				node.queue_free()	
	list_my_cards.clear()
	node_card_map[0] = []
	node_card_map[1] = []
	node_card_map[2] = []
	node_card_map[3] = []
	node_card_map[-1] = []
	


func update_remain_cards():
	if game_logic.match_data.remain_cards == 0:
		cardback_node.visible = false
	else:
		cardback_node.visible = true
		remain_cards_lb.text = str(game_logic.match_data.remain_cards)

func deal_cards(cards, delay = 0) -> void:	
	if g.v.game_manager.enable_sound:
		$AudioShuffleDealCard.play()
	var from_pos = NodeUtils.get_center_position(cardback_node)
	
	var start_pos = find_child("Dealer").global_position
	start_pos += Vector2(60, 130)
	var seat_id = -1
	for i in range(len(cards)):
		var card_id = cards[i].card
		var uid = cards[i].uid
		
		if uid == g.v.player_info_mgr.get_user_id():
			draw_my_card(card_id, delay)
			continue
			
		if uid != g.v.game_constants.BANKER_DEFAULT_UID:
			var p = get_player_node_by_uid(uid)
			seat_id = p.user_data.game_data.seat_id
		else:
			seat_id = -1
		var con = get_card_container(seat_id)
		var score = self.game_logic.calculate_score([card_id])
		if score > 0.1: # prevent case 0.0
			con.find_child("LbScore").text = str(score)
		var ins = card_scene.instantiate()
		
		self.node_card_map[seat_id].append(ins)
		ins.scale = Vector2(0.4, 0.4)
		con.add_child(ins)
		ins.turn_face_down()
		
		ins.set_card(card_id)
		 
		ins.global_position = start_pos
		var tween = create_tween()
		var arr = get_pos_card_table(seat_id)
		var final_pos = arr.back()
		ins.modulate.a = 0
		tween.parallel().tween_property(ins, "position", final_pos, 0.3).set_delay(delay)
		tween.parallel().tween_property(ins, "scale", Vector2(0.4, 0.4), 0.3).set_delay(delay)
		tween.parallel().tween_property(ins, "modulate:a", 1, 0.1).set_delay(delay)
		delay += 0.1
		
		tween.parallel().tween_callback(func():
			if ins.id != -1:
				ins.show_card(true)
		).set_delay(0.3 + delay)

func play_card(user_id: int, card_id: int, auto: bool = false):
	pass
#	

func get_player_node_by_uid(user_id: int):
	for p in list_players:
		if p.get_user_data().uid == user_id:
			return p
	return null
	
func test_deal_card():
	var arr = []
	var a = SetteMezzoMgr.SetteDealCard.new()
	a.uid = -1
	a.card = 10
	arr.append(a)
	
	var b = SetteMezzoMgr.SetteDealCard.new()
	b.uid = 1000021
	b.card = 10
	arr.append(b)
	deal_cards(arr)
	return

func test_play_playercard():
	#play_card(4, 3)
	draw_my_card(4)
	return
	
func on_draw_cards(arr):
	pass
	
func play_sound_my_turn():
	if g.v.game_manager.enable_sound:
		$AudioYourTurn.play()
			
func draw_my_card(card_id, delay = 0):
	if g.v.game_manager.enable_sound:
		$AudioDrawCard.play()
	var tween = create_tween()
	var instance = card_scene.instantiate()
	play_ground.add_child(instance)
	instance.set_card(card_id)
	instance.scale = Vector2(0.6 * SCALE_CARD_NORMAL, 0.6 * SCALE_CARD_NORMAL)
	tween.parallel().tween_property(instance, 'scale', Vector2(SCALE_CARD_DEAL_INIT, SCALE_CARD_DEAL_INIT), 0.3)
	instance.turn_face_down()
	instance.z_index = DEFAULT_CARD_Z_INDEX
	var from_pos = start_card_pos
	instance.global_position = from_pos
	var final_pos
	
	var l = len(list_my_cards)
	var next_size = l + 1
	var card_suit = card_id % 4
	# Find suitable position
	var des_i = l
			
	var new_pos_arr = _calculate_world_card_positions(next_size)
	var new_rotates = _get_card_rotates(next_size)
	final_pos = new_pos_arr[des_i]
	list_my_cards.insert(des_i, instance)
	
	var rot_radians: float = new_rotates[des_i]

	tween.parallel().tween_property(instance, "global_position", final_pos, 0.3).set_delay(delay)
	tween.parallel().tween_property(instance, "scale", Vector2(SCALE_CARD_NORMAL, SCALE_CARD_NORMAL), 0.3).set_delay(delay)
	
	tween.parallel().tween_callback(
		func():
			_update_my_card_positions(true)
	).set_delay(delay)
	tween.chain().tween_callback(
		func():
			instance.show_card(true)
			update_my_score()
			self.check_burst(g.v.player_info_mgr.get_user_id())
	)
	
func check_burst(uid):
	var score = game_logic.get_score_uid(uid)
	if score > 7.5:
		# bursted
		var p = self.get_player_node_by_uid(uid)
		p.effect_bursted()
		
func _on_received_draw_card():
	pass
func get_center(node):
	var scaled_size = node.size * node.scale
	return node.global_position + (scaled_size / 2)

# Countdown duration and initial value
var countdown_value: int = 3
@onready var countdown_timer: Timer = find_child('CountdownTimer')

func show_prepare_start():
	print('show_prepare_start')
	countdown_start_lb.visible = true
	countdown_timer.start()
	# count from 3 -> 2 -> 1 -> 0 and disappear
	pass

func exit_game():
	g.v.scene_manager.switch_scene("res://scenes/LobbyScene.tscn")

func on_show_chat_gui():
	in_game_chat_gui.visible = !in_game_chat_gui.visible
	chat_btn_reddot.visible = false

func on_new_chat_message(uid, message):
	if not in_game_chat_gui.visible:
		g.v.sound_manager.play_notification_alert()
		chat_btn_reddot.visible = true
		
	in_game_chat_gui.on_received_new_chat(uid, message)

func on_new_chat_emo(uid, emo):
	var p = get_player_node_by_uid(uid)
	if p:
		p.show_emotion(emo)
	
func _input(event):
	if g.v.config.CURRENT_MODE != g.v.config.MODES.LOCAL:
		return
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_Q:
				test_deal_card()
				return
			if event.keycode == KEY_R:
				test_play_playercard()
			

func update_register_leave_state():
	if g.v.game_constants.game_logic.is_registered_leave:
		back_btn.modulate = Color("f6353f67")
		pass
	else:
		back_btn.modulate = Color("ffffffd3")
		pass
		

func _on_back_btn_pressed() -> void:
	if g.v.game_constants.game_logic.is_registered_leave:
		# cancel
		g.v.game_manager.send_deregister_leave_game()
	else:
		g.v.game_manager.send_register_leave_game()

func _open_settings_gui() -> void:
	g.v.scene_manager.open_gui("res://scenes/guis/SettingsGUI.tscn")

func _open_guide_gui() -> void:
	g.v.game_manager.open_guide_gui()
	
func on_finish_effect_contribute_pot():
	var cur_pot_value =  StringUtils.convert_point_string_to_int(pot_value_lb.text)
	print('curreent pot', cur_pot_value)
	var new_pot_value =  game_logic.match_data.pot_value
	
	
	var pot_tween = create_tween()
	pot_tween.tween_method(_set_int_to_text.bind(pot_value_lb, false), cur_pot_value, new_pot_value, 0.4)

func _set_int_to_text(value: int, label, add: bool = false) -> void:
	var str = StringUtils.point_number(value)
	if add:
		str = '+' + str
	label.text = str

func _show_cheat_cards_bot(card_ids):
	pass

func on_user_turn():
	var uid_in_turn = self.game_logic.get_uid_in_turn()
	if uid_in_turn != -1:
		if uid_in_turn == g.v.player_info_mgr.get_user_id():
			action_btn_pn.visible = true
		else:
			action_btn_pn.visible = false
		for p in self.list_players:
			if p.is_in_turn:
				p.end_turn()
			if p.user_data.uid == uid_in_turn:
				p.on_turn()
	pass

func _click_show_info_bet() -> void:
	g.v.scene_manager.open_gui("res://scenes/board/BetDetailGUI.tscn")

func user_not_play_turn():
	is_auto_play = true
	self.auto_play_pn.visible = true
	
func _click_return_table() -> void:
	is_auto_play = false
	self.auto_play_pn.visible = false
	g.v.game_client.send_packet(g.v.game_constants.CMDs.USER_RETURN_TO_TABLE, [])

func _on_screen_resized():
	if is_portrait:
		return
	var screen_size = DisplayServer.window_get_size()
	if screen_size.y > screen_size.x * 1.4:
		var r = 1.9
		is_portrait = true


func click_stand_btn() -> void:
	g.v.sette_mezzo_mgr.action_stand()
	pass # Replace with function body.


func click_hit_btn() -> void:
	g.v.sette_mezzo_mgr.action_hit()
	pass # Replace with function body.

func user_hit_card(uid, card_id) -> void:	
	print('user hit card', uid, 'card ', card_id)
	if uid == g.v.player_info_mgr.get_user_id():
		draw_my_card(card_id)
		return
	var from_pos = NodeUtils.get_center_position(cardback_node)
	
	var start_pos = start_card_pos
	var seat_id = -1
	var score = self.game_logic.get_score_uid(uid)
	if uid != g.v.game_constants.BANKER_DEFAULT_UID:
		var p = get_player_node_by_uid(uid)
		seat_id = p.user_data.game_data.seat_id
	var con = get_card_container(seat_id)

	var tween = create_tween()

	var ins = card_scene.instantiate()
	self.node_card_map[seat_id].append(ins)
	con.add_child(ins)
	ins.scale = Vector2(0.4, 0.4)
	ins.turn_face_down()
	ins.set_card(card_id)		 
	ins.global_position = start_pos
	var arr = get_pos_card_table(seat_id)
	var j = 0
	for c in self.node_card_map[seat_id]:
		if c == ins:
			continue
		var tw = create_tween()
		var p = arr[j]
		tw.tween_property(
			c,
			'position',
			p,
			0.3
		)
		j += 1
	
	var final_pos = arr.back()
	ins.modulate.a = 0
	var delay = 0
	tween.parallel().tween_property(ins, "position", final_pos, 0.3).set_delay(delay)
	tween.parallel().tween_property(ins, "scale", Vector2(0.4, 0.4), 0.3).set_delay(delay)
	tween.parallel().tween_property(ins, "modulate:a", 1, 0.1).set_delay(delay)
	delay += 0.1
		
	tween.parallel().tween_callback(func():
		if ins.id != -1:
			ins.show_card(
				true, 
				func():
					con.find_child("LbScore").text = str(score)
			)
	).set_delay(0.3 + delay)

@onready var lb_my_score = find_child("LbMyScore")
func update_my_score():
	var my_cards = self.game_logic.get_my_cards()
	var score = self.game_logic.calculate_score(my_cards)
	lb_my_score.text = str(score)
	pass

func dealer_show_card(card_id):
	var score = self.game_logic.get_score_uid(g.v.game_constants.BANKER_DEFAULT_UID)
	var card = self.node_card_map[-1][0]
	card.set_card(card_id)
	card.show_card(true, 
		func():
			card_cont_dealer.find_child("LbScore").text = str(score)
	)
