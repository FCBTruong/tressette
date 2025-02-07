extends Node
class_name BoardScene

# Called when the node enters the scene tree for the first time.
var my_card_panel
var play_ground
var list_my_cards = []
var list_players = []
var _cur_focusing_card = null
var place_card_node = null
var tween: Tween
var tween_animate: Tween
var cards_node_compare = []
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
@onready var my_score_lb = find_child('MyScoreLb')
@onready var opponent_score_lb = find_child('OpponentScoreLb')
@onready var my_score_sub = find_child('MyScoreSub')
@onready var opponent_score_sub = find_child("OpponentScoreSub")
@onready var countdown_start_lb = find_child('CountdownStartLb')
@onready var room_id_lb = find_child('RoomIdLb')
@onready var pn_cheat = find_child('PnCheat')
@onready var in_game_chat_gui = find_child('InGameChatGui')
@onready var chat_btn = find_child('ChatBtn')
@onready var chat_btn_reddot = chat_btn.find_child('RedDot')
@onready var waiting_other_lb = find_child('WaitingOtherLb')
@onready var evaluate_lb = find_child('EvaluateLb')
@onready var back_btn = find_child("BackBtn")

const DEFAULT_CARD_Z_INDEX = 10
const COMPARE_CARD_Z_INDEX = 100
const WIN_CARD_Z_INDEX = 101
const CHAT_EMO_Z_INDEX = 200

var card_scene = preload("res://scenes/board/Card.tscn")
var game_logic: GameLogic = GameConstants.game_logic
var SCALE_CARD_COMPARE = 0.8
var SCALE_CARD_DEAL_INIT = 0.8	
var base_text = tr('WAITING_FOR_OTHERS')
var evaluate_lb_default_pos
func _ready() -> void:	
	SceneManager.INSTANCES.BOARD_SCENE = self
	my_card_panel = find_child('MyCardPanel')
	play_ground = find_child('PlayGround')
	place_card_node = find_child('PlaceCard1')
	countdown_start_lb.visible = false
	evaluate_lb_default_pos = evaluate_lb.position
	evaluate_lb.modulate.a = 0
	find_child('EmoChat').z_index = CHAT_EMO_Z_INDEX
	_on_enter()
	
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
		
func _on_enter():
	on_update_players()
	update_remain_cards()
	in_game_chat_gui.visible = false
	chat_btn.visible = GameManager.enable_chat_ingame
	chat_btn_reddot.visible = false
	pn_cheat.visible = false #Config.CURRENT_MODE != Config.MODES.LIVE
	room_id_lb.text = 'ROOM ID: ' + str(game_logic.match_data.match_id)
	if game_logic.match_data.state == MatchData.MATCH_STATE.PLAYING:
		# case reconnect
		# update cards compare
		var idx = 0
		for card_id in game_logic.match_data.cards_compare:
			var user = game_logic.match_data.users[idx]
			idx += 1
			if card_id != -1:
				var instance = card_scene.instantiate()
				play_ground.add_child(instance)
				instance.set_card(card_id)
				instance.turn_face_up()
				instance.z_index = COMPARE_CARD_Z_INDEX
				instance.scale = Vector2(SCALE_CARD_COMPARE, SCALE_CARD_COMPARE)
				instance.player_id = user.uid
				instance.global_position = get_place_pos_card(user.game_data.seat_id)
				cards_node_compare.append(instance)
				
		# update current cards
		var cards = game_logic.get_my_cards()
		var number = len(cards)
		var rotates = _get_card_rotates(number)
		for i in range(number):
			var instance = card_scene.instantiate()
			play_ground.add_child(instance)
			instance.set_card(cards[i])
			instance.turn_face_up()
			list_my_cards.append(instance)
			
		_update_my_card_positions()
		if game_logic.check_finishhand():
			on_finishhand()
			
	self.update_team_scores()

func continue_play():
	cardback_node.visible = false
	remove_all_current_cards()
	
func on_update_players():
	var players_info = game_logic.get_list_player()
	var i = 0
	for p in list_players:	
		p.queue_free()
	list_players.clear()
	_create_players(game_logic.match_data.player_mode)
	for info in players_info:
		list_players[i].set_user_data(info)
		i += 1
	update_player_seat()
	
# Function to create players
func _create_players(player_count: int) -> void:
	var player_scene = load("res://scenes/board/Player.tscn")  # Load player scene
	
	for i in range(player_count):
		var player_instance = player_scene.instantiate()  # Create a new player instance
		player_instance.name = "Player_%d" % i  # Name the player nodes uniquely
		
		# Add to the current scene
		players_pn.add_child(player_instance)
		list_players.append(player_instance)

func update_player_seat():
	for player in list_players:
		var seat_id = player.user_data.game_data.seat_id
		var pos = _get_seat_position(GameConstants.game_logic.match_data.player_mode, seat_id)
		player.global_position = pos
		
func _get_seat_position(mode_player: int, seat_id: int):
	if mode_player == GameConstants.PLAYER_MODE.SOLO:
		match seat_id:
			0: 
				return seat_pos0.global_position
			1:
				return seat_pos2.global_position
		return
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
	game_logic.update()
	#print('handsulttt', game_logic.hand_suit)
	for c in list_my_cards:
		c.update_state_can_play(true)
	if game_logic.match_data.state == MatchData.MATCH_STATE.PLAYING:
		if game_logic.is_my_turn():
			for c in list_my_cards:
				var is_valid_play = game_logic.check_valid_card_play(c.id)
				c.update_state_can_play(is_valid_play)
	
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
			card.rotation = desired_rot
		else:
			tween.parallel().tween_property(card, 'global_position', desired_pos, 0.3)
			tween.parallel().tween_property(card, 'rotation', desired_rot, 0.3)
		
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
	print("play_a_card", id)
	var valid_card = game_logic.check_valid_card_play(id)
	if not valid_card:
		print('card not valid suit')
		return 
	var card = _get_my_card(id)
	if not card:
		print('not found card')
		return
	if GameManager.enable_sound:
		$AudioPlayCard.play()
	card.is_played = true
	card.z_index = COMPARE_CARD_Z_INDEX
	card.player_id = PlayerInfoMgr.my_user_data.uid
	var player_node = get_player_node_by_uid(PlayerInfoMgr.my_user_data.uid)
	_cur_focusing_card = null
	var rot_degrees = randf_range(3, 6) if randf() > 0.5 else randf_range(-10, -5)
	var rot = deg_to_rad(rot_degrees)
	# Animate the card moving to (0, 0)
	var tween = create_tween()
	var p_place_world = get_place_pos_card(player_node.user_data.game_data.seat_id)
	tween.parallel().tween_property(card, "global_position",p_place_world, 0.3)
	tween.parallel().tween_property(card, "rotation",rot, 0.3)
	tween.parallel().tween_property(card, "scale", 
		Vector2(SCALE_CARD_COMPARE, SCALE_CARD_COMPARE), 0.3)
	
	# send to server
	if not auto:
		game_logic.send_play_card(id)
	cards_node_compare.append(card)
	
	list_my_cards.erase(card)
	_update_my_card_positions(true)

var win_messages = [
		'FANTASTIC',
		'WELL_DONE',
		'GREAT_JOB',
		'CONGRATULATION',
		'YOU_ARE_AMAZING'
	]
var lose_msgs = ['BAD_LUCK', 'TRY_AGAIN', 'DONT_GIVE_UP', 'KEEP_GOING']
func on_finishhand(delay = 0.5):
	#for card in cards_node_compare:
		#card.visible = false
	var card_win_id = game_logic.get_card_win_inhand()
	var win_hand_point = game_logic.win_point_hand
	# show effect
	var card_win_node = null
	var player_win_id = null
	for c in cards_node_compare:
		if c.get_card_id() == card_win_id:
			card_win_node = c
			card_win_node.z_index = WIN_CARD_Z_INDEX
			player_win_id = c.player_id
			break
	
	if not card_win_node:
		return 
	# effect card_win
	card_win_node.effect_win_card()
			
	if not player_win_id:
		return
	var is_win = false
	if player_win_id == PlayerInfoMgr.my_user_data.uid:
		if GameManager.enable_sound:
			$AudioWinTurn.play()
		is_win = true
	var eval_str = ''
	if is_win: 
		var random_index = randi() % win_messages.size()
		var win_message = tr(win_messages[random_index])
		_effect_evaluate(win_message)
		# Random textwin ('Fantastic!, 'Well Done!....)
	else:
		var random_index = randi() % lose_msgs.size()
		var lose_message = tr(lose_msgs[random_index])
		_effect_evaluate(lose_message)
	
	
	# effect move to cards win
	var player_node = get_player_node_by_uid(player_win_id)
	var time_gathering_cards = 0.3
	
	await get_tree().create_timer(1).timeout
	var tween = create_tween()
	
	for c in cards_node_compare:
		if c != card_win_node:
			tween.parallel().tween_property(c, "global_position",card_win_node.global_position, time_gathering_cards)
	
	tween.tween_interval(0)  # 1-second delay
	
	for c in cards_node_compare:
		tween.parallel().tween_property(c, "global_position", player_node.global_position, 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(c, "scale", Vector2(0.6, 0.6), 0.3)
		
	tween.tween_interval(0)
	for c in cards_node_compare:
		tween.tween_callback(c.queue_free)
	
	cards_node_compare.clear()
	
	for player in list_players:
		player.update_points_display(true)
	# effect add score
	await get_tree().create_timer(0.5).timeout
	player_node.effect_add_score(win_hand_point)
	self.update_team_scores()
		
func update_team_scores():
	var my_score = game_logic.get_my_team_score()
	var opponent_score = game_logic.get_opponent_team_score()
	_update_display_score(true, my_score)
	_update_display_score(false, opponent_score)

func _update_display_score(is_myteam, score: int) -> void:
	var main = score / 3
	var sub = score % 3
	if is_myteam:
		if main == 0 and sub > 0:
			my_score_lb.text = ''
		else:
			my_score_lb.text = str(main)
	else:
		if main == 0 and sub > 0:
			opponent_score_lb.text = ''
		else:
			opponent_score_lb.text = str(main)
	if sub != 0:
		if is_myteam:
			my_score_sub.visible = true
			my_score_sub.find_child('Sub1').text = str(sub)
		else:
			opponent_score_sub.visible = true
			opponent_score_sub.find_child('Sub1').text = str(sub)
	else:
		if is_myteam:
			my_score_sub.visible = false
		else:
			opponent_score_sub.visible = false
			
func _calculate_world_card_positions(number: int):
	var list_pos = []
	var p_center = Vector2(my_card_panel.size.x / 2, my_card_panel.size.y / 2)
	var distance = 90
	
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

func remove_all_current_cards():
	for card in list_my_cards:
		card.queue_free()
	list_my_cards.clear()

func update_remain_cards():
	if game_logic.match_data.remain_cards == 0:
		cardback_node.visible = false
	else:
		cardback_node.visible = true
		remain_cards_lb.text = str(game_logic.match_data.remain_cards)
	
func deal_my_cards(cards) -> void:	
	update_remain_cards()
	if GameManager.enable_sound:
		$AudioShuffleDealCard.play()
	var from_pos = cardback_node.global_position
	remove_all_current_cards()
	list_my_cards = []
	var number = len(cards)
	var drawn = true
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	var list_pos_des = _calculate_world_card_positions(number)
	var rotates = _get_card_rotates(number) 
	for i in range(number):
		var instance = card_scene.instantiate()
		print('debug----01')
		play_ground.add_child(instance)
		instance.set_card(cards[i])
		instance.turn_face_down()
		instance.z_index = DEFAULT_CARD_Z_INDEX + i
		list_my_cards.append(instance)
		instance.global_position = from_pos
		
		# -(instance.size / 2.0) to center the card
		var final_pos: Vector2 = list_pos_des[i]
		# offset to the right everything has we are going to place cards to the left
		final_pos.x += ((card_offset_x * (number-1)) / 2.0)
		
		#print("Offset: ", float(i)/float(number-1))
		var rot_radians: float = 0
		
		rot_radians = rotates[i]
		#print("Rot: ", rot_radians)
		#print("Card %d: , size: %s, pivot: %s" % [i, str(instance.size), str(instance.pivot_offset)])
		
		# Animate pos
		tween.parallel().tween_property(instance, "position", final_pos, 0.3 + (i * 0.075))
		tween.parallel().tween_property(instance, "rotation", rot_radians, 0.3 + (i * 0.075))
		
		# cal instance.show_card(true) after arrived
			# Schedule card flip after animation finishes
		tween.parallel().tween_callback(func():
			instance.show_card(true)
		).set_delay(0.3 + (i * 0.075))
	
	tween.tween_callback(set_process.bind(true))
	tween.tween_property(self, "sine_offset_mult", anim_offset_y, 1.5).from(0.0)

func play_card(user_id: int, card_id: int, auto: bool = false):
	print("user " + str(user_id) + "play_a_card", card_id)
	if user_id == PlayerInfoMgr.my_user_data.uid:
		if auto:
			play_my_card(card_id, auto)
		return
	if GameManager.enable_sound:
		$AudioPlayCard.play()

	var card_instance = card_scene.instantiate()
	play_ground.add_child(card_instance)
	card_instance.player_id = user_id
	card_instance.set_card(card_id)
	card_instance.turn_face_up()
	var player_node = get_player_node_by_uid(user_id)
	if not player_node:
		return
	card_instance.global_position = player_node.global_position
	
	# Animate the card moving to (0, 0)
	var tween = create_tween()
	var p_place_world = get_place_pos_card(player_node.user_data.game_data.seat_id)
	var rot_degrees = randf_range(3, 6) if randf() > 0.5 else randf_range(-10, -5)
	var rot = deg_to_rad(rot_degrees)
	tween.parallel().tween_property(card_instance, "global_position",p_place_world, 0.3)
	tween.parallel().tween_property(card_instance, "rotation", rot, 0.3)
	tween.parallel().tween_property(card_instance, "scale", 
		Vector2(SCALE_CARD_COMPARE, SCALE_CARD_COMPARE), 0.3)
	_update_my_card_positions()
	cards_node_compare.append(card_instance)
#	
func get_place_pos_card(seat_id: int) -> Vector2:
	if game_logic.match_data.player_mode == GameConstants.PLAYER_MODE.SOLO:
		if seat_id == 0:
			return place_card0.global_position
		else:
			return place_card2.global_position
	else:
		if seat_id == 0:
			return place_card0.global_position
		elif seat_id == 1:
			return place_card1.global_position
		elif seat_id == 2:
			return place_card2.global_position
		else:
			return place_card3.global_position

func get_player_node_by_uid(user_id: int):
	for p in list_players:
		if p.get_user_data().uid == user_id:
			return p
	return null
func test_deal_card():
	#deal_my_cards([2, 3, 5, 6, 7, 8, 9])
	
	_effect_evaluate()
	return

func test_play_playercard():
	#play_card(4, 3)
	_effect_draw_card(1000000, 4)
	return
	
func on_draw_cards(arr):
	for obj in arr:
		var uid = obj['uid']
		var card_id = obj['card']
		_effect_draw_card(uid, card_id)
		game_logic.match_data.remain_cards -= 1
		update_remain_cards()
		await get_tree().create_timer(1.75).timeout

func play_sound_my_turn():
	if GameManager.enable_sound:
		$AudioYourTurn.play()
			
func _effect_draw_card(uid, card_id):
	if GameManager.enable_sound:
		$AudioDrawCard.play()
	var tween = create_tween()
	var instance = card_scene.instantiate()
	play_ground.add_child(instance)
	instance.set_card(card_id)
	instance.scale = Vector2(SCALE_CARD_DEAL_INIT, SCALE_CARD_DEAL_INIT)
	instance.turn_face_down()
	instance.show_card(true)
	instance.z_index = DEFAULT_CARD_Z_INDEX
	var from_pos = get_center(cardback_node)
	instance.global_position = from_pos
	var final_pos
	if uid != PlayerInfoMgr.my_user_data.uid:
		var player_node = get_player_node_by_uid(uid)
		final_pos = player_node.global_position
		tween.tween_property(instance, "global_position", final_pos, 0.3).set_delay(1)
		tween.tween_callback(
			func():
				instance.queue_free()
		)
		return
	
	var l = len(list_my_cards)
	var next_size = l + 1
	var card_suit = card_id % 4
	# Find suitable position
	var des_i = l
	
	var on_suit_ray = false
	for i in range(len(list_my_cards)):
		var c = list_my_cards[i]
		var suit = c.id % 4
		if suit == card_suit:
			on_suit_ray = true
		
		if on_suit_ray and suit != card_suit:
			# Mean that not any cards same suit after, get position here
			des_i = i
			break
		if on_suit_ray:
			if game_logic.get_rank_card(card_id) > game_logic.get_rank_card(c.id):
				continue
			else:
				# this is exactly position we should place the card
				des_i = i
				break
			
	var new_pos_arr = _calculate_world_card_positions(next_size)
	var new_rotates = _get_card_rotates(next_size)
	final_pos = new_pos_arr[des_i]
	
	var rot_radians: float = new_rotates[des_i]
	print(rot_radians)

	# Animate pos
	var delay = 1

	tween.parallel().tween_property(instance, "global_position", final_pos, 0.3).set_delay(delay)
	tween.parallel().tween_property(instance, "scale", Vector2(1, 1), 0.3).set_delay(delay)
	tween.parallel().tween_property(instance, "rotation", rot_radians, 0.3).set_delay(delay)

	tween.chain().tween_callback(
		func():
			list_my_cards.insert(des_i, instance)
			_update_my_card_positions(true)
	)
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
	SceneManager.switch_scene("res://scenes/LobbyScene.tscn")

func on_show_chat_gui():
	in_game_chat_gui.visible = !in_game_chat_gui.visible
	chat_btn_reddot.visible = false

func on_new_chat_message(uid, message):
	if not in_game_chat_gui.visible:
		SoundManager.play_notification_alert()
		chat_btn_reddot.visible = true
		
	in_game_chat_gui.on_received_new_chat(uid, message)

func on_new_chat_emo(uid, emo):
	var p = get_player_node_by_uid(uid)
	if p:
		p.show_emotion(emo)
	
func _effect_evaluate(text = 'Fantastic!'):
	evaluate_lb.text = text
	var tween = create_tween()
	evaluate_lb.modulate.a = 1
	evaluate_lb.position = evaluate_lb_default_pos
	evaluate_lb.scale = Vector2(0, 0)
	tween.tween_property(self.evaluate_lb, 'scale', Vector2(1, 1), 0.4)
	# delay 1 second
	var y = evaluate_lb_default_pos.y - 30
	var d = 1
	tween.parallel().tween_property(evaluate_lb, 'modulate:a', 0, 0.3).set_delay(d)
	tween.parallel().tween_property(evaluate_lb, 'position:y', y, 0.3).set_delay(d)
	tween.parallel().tween_property(evaluate_lb, 'scale', Vector2(0.7, 0.7), 0.3).set_delay(d)
	pass

func _input(event):
	if Config.CURRENT_MODE != Config.MODES.LOCAL:
		return
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_W:
				show_prepare_start()
				return
				#_effect_evaluate()
				self.list_players[0].show_emotion(4)
				print("W key pressed")
			elif event.keycode == KEY_S:
				test_play_playercard()
				print("S key pressed")
			elif event.keycode == KEY_1:
				deal_my_cards([2,3,4,5,6,8,9,33])
		else:
			if event.keycode == KEY_W:
				print("W key released")

func update_register_leave_state():
	if GameConstants.game_logic.is_registered_leave:
		back_btn.modulate = Color("f6353f67")
		pass
	else:
		back_btn.modulate = Color("5ed85767")
		pass
		

func _on_back_btn_pressed() -> void:
	if GameConstants.game_logic.is_registered_leave:
		# cancel
		GameManager.send_deregister_leave_game()
	else:
		GameManager.send_register_leave_game()

func _open_settings_gui() -> void:
	SceneManager.open_gui("res://scenes/guis/SettingsGUI.tscn")
	pass # Replace with function body.
