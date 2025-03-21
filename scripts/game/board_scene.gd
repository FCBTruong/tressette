extends BaseBoardScene
class_name BoardScene

# Called when the node enters the scene tree for the first time.
var my_card_panel
var play_ground
var list_my_cards = []
var list_players = []
var _cur_focusing_card = null
var tween: Tween
var tween_animate: Tween
var cards_node_compare = []
var is_portrait = false
@onready var players_pn = find_child("PlayersPn")
@onready var center_play_pn = find_child('CenterPlayPn')
@onready var cardback_node = find_child('CardbackPn')
@onready var seat_pos0 = find_child('PlayerPos0')
@onready var seat_pos1 = find_child('PlayerPos1')
@onready var seat_pos2 = find_child('PlayerPos2')
@onready var seat_pos3 = find_child('PlayerPos3')
@onready var seat_pos_solo0 = find_child('seat_pos_solo0')
@onready var seat_pos_solo1 = find_child('seat_pos_solo1')
var compare_card_poses = []
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
@onready var bet_lb = find_child("BetLb")
@onready var pot_value_lb:Label = find_child("PotValueLb")
@onready var center_play_pn_pos
@onready var game_start_lb = find_child("GameStartLb")
@onready var round_lb = find_child("RoundLb")
@onready var evaluate_ipad_pos_node = find_child('EvaluateIpadPos')
@onready var cheat_bot_card_pn = find_child("CheatBotCardPn")
@onready var napoli_btn = find_child("NapoliBtn")
@onready var action_btn_pn = find_child("ActionBtnPn")
@onready var reach_point_win_lb = find_child("ReachPointWinLb")
@onready var auto_play_pn = find_child("AutoPlayPn")
var pn_highlight_napoli = preload("res://scenes/board/NapoliCardHighlight.tscn")
@onready var bet_info_pn = find_child("BetInfoPn")
@onready var pot_pn = find_child("PotPn")
@onready var score_pn = find_child("ScorePn")
const DEFAULT_CARD_Z_INDEX = 10
const COMPARE_CARD_Z_INDEX = 100
const WIN_CARD_Z_INDEX = 101
const CHAT_EMO_Z_INDEX = 200
const TIME_VIEW_CARD = 1.1
const CARD_DISTANCE_BETWEEN = 95

var card_scene = preload("res://scenes/board/Card.tscn")
var game_logic: GameLogic = g.v.game_constants.game_logic
var SCALE_CARD_COMPARE = 0.7
var SCALE_CARD_DEAL_INIT = 0.8	
var SCALE_CARD_DRAW = 0.6
var SCALE_CARD_NORMAL = 1
var base_text = tr('WAITING_FOR_OTHERS')
var evaluate_lb_default_pos
var game_start_lb_default_pos
var is_auto_play = false
var list_napoli_highlights = []
var center_play_pn_default_pos
var R = 4000
func _ready() -> void:	
	my_score_lb.text = '0'
	opponent_score_lb.text = '0'
	evaluate_lb_default_pos = evaluate_lb.global_position
	center_play_pn_default_pos = center_play_pn.position
	get_tree().get_root().connect("size_changed", _on_screen_resized)
	_on_screen_resized()
	
	if g.v.app_version.is_in_review():
		pot_pn.visible = false
		self.bet_info_pn.visible = false
		
	napoli_btn.visible = false 
	is_auto_play = false
	game_start_lb_default_pos = game_start_lb.position
	g.v.scene_manager.INSTANCES.BOARD_SCENE = self
	my_card_panel = find_child('MyCardPanel')
	play_ground = find_child('PlayGround')
	countdown_start_lb.visible = false
	evaluate_lb.modulate.a = 0
	evaluate_lb.visible = true
	find_child('EmoChat').z_index = CHAT_EMO_Z_INDEX
	_on_enter()
	action_btn_pn.z_index = 200
	auto_play_pn.z_index = 300
	
	# Check and show GUIDE GUI for new user
	if g.v.player_info_mgr.my_user_data.game_count == 0 and not \
		g.v.game_manager.did_show_guide_new_user:
		self._open_guide_gui()
		g.v.game_manager.did_show_guide_new_user = true
			
	g.v.sound_manager.play_music_board()
	#show_prepare_start()
func _get_card_rotates(n):
	var arr = []
	for i in range(n):
		if is_portrait:
			arr.append(0)
			continue
		var x = (0 - (n - 1) * CARD_DISTANCE_BETWEEN / 2) + i * CARD_DISTANCE_BETWEEN
		var sin_x = asin(x * 1.0 / R)
		arr.append(sin_x)
	return arr
		
func _on_enter():
	game_start_lb.visible = false
	auto_play_pn.visible = false
	compare_card_poses.clear()
	
	if game_logic.match_data.player_mode == GameConstants.PLAYER_MODE.SOLO:
		compare_card_poses.append(find_child('PlaceCard0'))
		compare_card_poses.append(find_child('PlaceCard1'))
	else:
		compare_card_poses.append(find_child('PlaceCard20'))
		compare_card_poses.append(find_child('PlaceCard21'))
		compare_card_poses.append(find_child('PlaceCard22'))
		compare_card_poses.append(find_child('PlaceCard23'))
	_update_current_round()
	on_update_players()
	update_remain_cards()
	in_game_chat_gui.visible = false
	in_game_chat_gui.z_index = 200
	chat_btn.visible = g.v.game_manager.enable_chat_ingame
	chat_btn_reddot.visible = false
	pn_cheat.visible = false #g.v.config.CURRENT_MODE != g.v.config.MODES.LIVE
	room_id_lb.text = "ID" + ': ' + str(game_logic.match_data.match_id)
	if game_logic.match_data.state == MatchData.MATCH_STATE.PLAYING:
		update_cards_on_table()
		if game_logic.check_finishhand():
			on_finishhand(0.5)
			
		on_user_turn()
			
	self.update_team_scores()
	bet_lb.text = tr("BET") + ": " + StringUtils.symbol_number(game_logic.match_data.bet)
	pot_value_lb.text = StringUtils.point_number(game_logic.match_data.pot_value)
	
	var str_reach_win = tr("REACH_POINT_TO_WIN")
	str_reach_win = str_reach_win.replace("#point", str(game_logic.match_data.point_to_win / 3))
	self.reach_point_win_lb.text = str_reach_win
	
func update_cards_on_table():
	remove_all_current_cards()
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
		instance.rotation = rotates[i]
		instance.scale = Vector2(SCALE_CARD_NORMAL, SCALE_CARD_NORMAL)
		list_my_cards.append(instance)
		
	_update_my_card_positions()

func continue_play():
	if game_logic.match_data.state == MatchData.MATCH_STATE.PLAYING:
		return
		
	if self.is_auto_play:
		# quit
		g.v.game_manager.send_register_leave_game()
	cardback_node.visible = false
	remove_all_current_cards()
	_update_display_score(true, 0)
	_update_display_score(false, 0)
	opponent_score_sub.visible = false
	my_score_sub.visible = false
	pot_value_lb.text = '0'
	round_lb.text = ''

func _update_current_round():
	if game_logic.match_data.current_round == 0:
		return
	round_lb.text = tr("ROUND") + ": " + str(game_logic.match_data.current_round)

func on_game_start():
	game_start_lb.text = tr("GAME_START")
	_eff_text_middle()
	_update_current_round()
	
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
	start_eff_tween.parallel().tween_callback(
		self._effect_pot_contribute
	).set_delay(0.2)
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
	_update_current_round()
	
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
		var pos = _get_seat_position(g.v.game_constants.game_logic.match_data.player_mode, seat_id)
		player.global_position = pos
		
func _get_seat_position(mode_player: int, seat_id: int):
	if mode_player == g.v.game_constants.PLAYER_MODE.SOLO:
		match seat_id:
			0: 
				return seat_pos_solo0.global_position
			1:
				return seat_pos_solo1.global_position
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
	if len(list_napoli_highlights) > 0:
		for n in list_napoli_highlights:
			n.queue_free()
		list_napoli_highlights.clear()
		
	print("play_a_card", id)
	var valid_card = game_logic.check_valid_card_play(id)
	if not valid_card:
		print('card not valid suit')
		return 
	var card = _get_my_card(id)
	if not card:
		print('not found card')
		return
	if g.v.game_manager.enable_sound:
		$AudioPlayCard.play()
	card.is_played = true
	card.z_index = COMPARE_CARD_Z_INDEX
	card.player_id = g.v.player_info_mgr.my_user_data.uid
	var player_node = get_player_node_by_uid(g.v.player_info_mgr.my_user_data.uid)
	_cur_focusing_card = null
	var rot_degrees = randf_range(3, 6) if randf() > 0.5 else randf_range(-10, -5)
	var rot = deg_to_rad(rot_degrees)
	# Animate the card moving to (0, 0)
	var tween = create_tween()
	var p_place_world = get_place_pos_card(player_node.user_data.game_data.seat_id)
	tween.parallel().tween_property(card, "global_position",p_place_world, 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(card, "rotation",0, 0.3)
	tween.parallel().tween_property(card, "scale", 
		Vector2(SCALE_CARD_NORMAL * 1.5, SCALE_CARD_NORMAL * 1.5), 0.3).set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_SINE)
			
	tween.parallel().tween_callback(
		func():
			card.shadow.visible = true
	).set_delay(0.3)
	
	tween.parallel().tween_property(card, "scale", 
		Vector2(SCALE_CARD_COMPARE, SCALE_CARD_COMPARE), 0.2).set_delay(0.3)
	# send to server
	if not auto:
		game_logic.match_data.current_turn = -1
		g.v.scene_manager.INSTANCES.BOARD_SCENE.on_user_turn()
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
func on_finishhand(delay = 0.5, is_end_round = false):
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
	var is_win = game_logic.is_my_team(player_win_id)
	if is_win:
		if g.v.game_manager.enable_sound:
			$AudioWinTurn.play()
			
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
			tween.parallel().tween_property(c, "global_position",card_win_node.global_position, time_gathering_cards + 0.01)

	for c in cards_node_compare:
		tween.parallel().tween_property(c, "global_position", player_node.global_position, 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT_IN) \
			.set_delay(time_gathering_cards)
		tween.parallel().tween_property(c, "scale", Vector2(SCALE_CARD_COMPARE / 2, SCALE_CARD_COMPARE / 2), 0.3).set_delay(time_gathering_cards)
		tween.parallel().tween_property(c, "modulate:a", 0, 0.2).set_delay(0.3 + time_gathering_cards)
		
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
	
	if is_end_round:
		# effect win last trick
		player_node.show_bonus('+1 ' + tr("LAST_TRICK"))
		
func update_team_scores():
	var my_score = game_logic.get_my_team_score()
	var opponent_score = game_logic.get_opponent_team_score()
	_update_display_score(true, my_score)
	_update_display_score(false, opponent_score)

func _update_display_score(is_myteam, score: int) -> void:
	var main = score / 3
	var sub = score % 3
	var tween = create_tween()
	if is_myteam:
		if main == 0 and sub > 0:
			my_score_lb.text = ''
		else:
			if str(main) != my_score_lb.text:
				tween.parallel().tween_property(my_score_lb, 'modulate:a', 0.5, 0.3)
				tween.parallel().tween_property(my_score_lb, 'scale', Vector2(0.9,0.9), 0.3)
				tween.parallel().tween_callback(func():
					my_score_lb.text = str(main)
					).set_delay(0.3)
				tween.parallel().tween_property(my_score_lb, 'modulate:a', 1, 0.3).set_delay(0.3)
				tween.parallel().tween_property(my_score_lb, 'scale', Vector2(1,1), 0.3).set_delay(0.3)\
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		if main >= game_logic.match_data.point_to_win / 3 - 1:
			score_pn.find_child('FireMine').visible = true
		else:
			score_pn.find_child('FireMine').visible = false
	else:
		if main == 0 and sub > 0:
			opponent_score_lb.text = ''
		else:
			if str(main) != opponent_score_lb.text:
				tween.parallel().tween_property(opponent_score_lb, 'modulate:a', 0.5, 0.3)
				tween.parallel().tween_property(opponent_score_lb, 'scale', Vector2(0.9,0.9), 0.3)
				tween.parallel().tween_callback(func():
					opponent_score_lb.text = str(main)
					).set_delay(0.3)
				tween.parallel().tween_property(opponent_score_lb, 'modulate:a', 1, 0.3).set_delay(0.3)
				tween.parallel().tween_property(opponent_score_lb, 'scale', Vector2(1,1), 0.3).set_delay(0.3)\
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		if main >= game_logic.match_data.point_to_win / 3 - 1:
			score_pn.find_child('FireOpponent').visible = true
		else:
			score_pn.find_child('FireOpponent').visible = false
	
	if sub != 0:
		var tween2 = create_tween()
		var sub_node
		if is_myteam:
			my_score_sub.visible = true
			sub_node = my_score_sub.find_child('Sub1')
		else:
			opponent_score_sub.visible = true
			sub_node = opponent_score_sub.find_child('Sub1')
		sub_node.text = str(sub)
	else:
		if is_myteam:
			my_score_sub.visible = false
		else:
			opponent_score_sub.visible = false

func _cal_portrait_world_card_positions(number):
	var list_pos = []
	
	var second_line = 5
	second_line = min(number, 5)  
	var first_line = number - second_line       

	var p_center = Vector2(my_card_panel.size.x / 2, 0)
	var spacing = 170  # Adjust spacing between cards

	for i in range(first_line):
		var x_offset = (i - (first_line - 1) / 2.0) * spacing
		var pos = p_center + Vector2(x_offset, -250)
		pos = my_card_panel.get_global_transform().origin + pos
		list_pos.append(pos)
 
	for i in range(second_line):
		var x_offset = (i - (second_line - 1) / 2.0) * spacing
		var pos = p_center + Vector2(x_offset, 0)
		pos = my_card_panel.get_global_transform().origin + pos
		list_pos.append(pos)

	return list_pos

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
		var dis_x = (index - mid) * distance
		pos.x = p_center.x + dis_x
		
		var dis_y = R - sqrt(R * R - dis_x * dis_x)
		pos.y = p_center.y + dis_y
		var global_pos = my_card_panel.get_global_transform().origin + pos
		list_pos.append(global_pos)
		index += 1
	
	return list_pos
	
@export var card_offset_x: float = 20.0
@export var rot_max: float = 6.0
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
	cardback_node.visible = false
	if g.v.game_manager.enable_sound:
		$AudioShuffleDealCard.play()
	var from_pos = NodeUtils.get_center_position(cardback_node)
	if game_logic.match_data.player_mode != GameConstants.PLAYER_MODE.SOLO:
		from_pos = get_viewport().get_visible_rect().size / 2
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
		play_ground.add_child(instance)
		instance.set_card(cards[i])
		instance.scale = Vector2(SCALE_CARD_DRAW, SCALE_CARD_DRAW)
		instance.turn_face_down()
		var z_des = DEFAULT_CARD_Z_INDEX + i
		var z_now = DEFAULT_CARD_Z_INDEX + number - i 
		instance.z_index = z_now
		list_my_cards.append(instance)
		instance.global_position = from_pos
		
		# -(instance.size / 2.0) to center the card
		var final_pos: Vector2 = list_pos_des[i]
		## offset to the right everything has we are going to place cards to the left
		#final_pos.x += ((card_offset_x * (number-1)) / 2.0)
		
		#print("Offset: ", float(i)/float(number-1))
		var rot_radians: float = 0
		
		rot_radians = rotates[i]
		#print("Rot: ", rot_radians)
		#print("Card %d: , size: %s, pivot: %s" % [i, str(instance.size), str(instance.pivot_offset)])
		
		var delay = i * 0.1
		# Animate pos
		if i == number - 1:
			tween.parallel().tween_callback(
				func():
					update_remain_cards()
					pass
			).set_delay(delay)
		tween.parallel().tween_property(instance, "position", final_pos, 0.3).set_delay(delay).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(instance, "rotation", rot_radians, 0.3).set_delay(delay)
		tween.parallel().tween_property(instance, "scale", Vector2(SCALE_CARD_NORMAL, SCALE_CARD_NORMAL), 0.3).set_delay(delay)
		tween.parallel().tween_callback(func():
			instance.z_index = z_des
			instance.show_card(true)
		).set_delay(0.3 + delay)
	
	tween.tween_callback(set_process.bind(true))
	tween.tween_property(self, "sine_offset_mult", anim_offset_y, 1.5).from(0.0)

func play_card(user_id: int, card_id: int, auto: bool = false):
	print("user " + str(user_id) + "play_a_card", card_id)
	if user_id == g.v.player_info_mgr.my_user_data.uid:
		if auto:
			play_my_card(card_id, auto)
		return
	if g.v.game_manager.enable_sound:
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
	card_instance.scale = Vector2(SCALE_CARD_NORMAL * 0.8, SCALE_CARD_NORMAL * 0.8)
	# Animate the card moving to (0, 0)
	var tween = create_tween()
	var p_place_world = get_place_pos_card(player_node.user_data.game_data.seat_id)
	var rot_degrees = randf_range(3, 6) if randf() > 0.5 else randf_range(-10, -5)
	var rot = deg_to_rad(rot_degrees)
	tween.parallel().tween_property(card_instance, "global_position",p_place_world, 0.5).set_trans(Tween.TRANS_SINE)
	#tween.parallel().tween_property(card_instance, "rotation", rot, 0.3)
	tween.parallel().tween_property(card_instance, "scale", 
		Vector2(SCALE_CARD_NORMAL * 1.1, SCALE_CARD_NORMAL * 1.1), 0.3)\
			.set_trans(Tween.TRANS_SINE)
			
	tween.parallel().tween_callback(
		func():
			card_instance.shadow.visible = true
	).set_delay(0.3)
	
	tween.parallel().tween_property(card_instance, "scale", 
		Vector2(SCALE_CARD_COMPARE, SCALE_CARD_COMPARE), 0.2).set_delay(0.3)
	_update_my_card_positions()
	cards_node_compare.append(card_instance)
#	
func get_place_pos_card(seat_id: int) -> Vector2:
	return compare_card_poses[seat_id].global_position

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
	if g.v.game_manager.enable_sound:
		$AudioYourTurn.play()
			
func _effect_draw_card(uid, card_id):
	if g.v.game_manager.enable_sound:
		$AudioDrawCard.play()
	var tween = create_tween()
	var instance = card_scene.instantiate()
	play_ground.add_child(instance)
	instance.set_card(card_id)
	instance.scale = Vector2(0.6 * SCALE_CARD_NORMAL, 0.6 * SCALE_CARD_NORMAL)
	tween.parallel().tween_property(instance, 'scale', Vector2(SCALE_CARD_DEAL_INIT, SCALE_CARD_DEAL_INIT), 0.3)
	instance.turn_face_down()
	instance.show_card(true)
	instance.z_index = DEFAULT_CARD_Z_INDEX
	var from_pos = get_center(cardback_node)
	instance.global_position = from_pos
	var final_pos
	if uid != g.v.player_info_mgr.my_user_data.uid:
		var player_node = get_player_node_by_uid(uid)
		final_pos = player_node.global_position
		tween.parallel().tween_callback(
			func():
				instance.hide_card()
		).set_delay(TIME_VIEW_CARD)
		tween.parallel().tween_property(instance, "global_position", final_pos, 0.35).set_delay(0.55 + TIME_VIEW_CARD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN	)
		tween.parallel().tween_property(instance, "scale", Vector2(0.5 * SCALE_CARD_NORMAL, 0.5 * SCALE_CARD_NORMAL), 0.35).set_delay(0.55 + TIME_VIEW_CARD) 
		tween.tween_interval(0)
		tween.tween_property(instance, 'modulate:a', 0, 0.2)
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
	list_my_cards.insert(des_i, instance)
	
	var rot_radians: float = new_rotates[des_i]

	# Animate pos
	var delay = TIME_VIEW_CARD

	tween.parallel().tween_property(instance, "global_position", final_pos, 0.4).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(instance, "scale", Vector2(SCALE_CARD_NORMAL, SCALE_CARD_NORMAL), 0.4).set_delay(delay)
	tween.parallel().tween_property(instance, "rotation", rot_radians, 0.4).set_delay(delay)
	
	var c_idx = 0
	for c in list_my_cards:
		if c_idx == des_i:
			continue
		
		var c_tween = create_tween()
		c_tween.tween_property(
			c, "global_position", 
			new_pos_arr[c_idx],
			0.3
		).set_delay(delay)
		
		c_idx += 1
		
	tween.chain().tween_callback(
		func():
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
	g.v.scene_manager.switch_scene("res://scenes/LobbyScene.tscn")

func on_show_chat_gui():
	in_game_chat_gui.visible = !in_game_chat_gui.visible
	chat_btn_reddot.visible = false

func on_new_chat_message(uid, message):
	if not in_game_chat_gui.visible:
		g.v.sound_manager.play_notification_alert()
		chat_btn_reddot.visible = true
		
	in_game_chat_gui.on_received_new_chat(uid, message)
	for p in list_players:
		if p.user_data.uid == uid:
			p.on_chat(message)
func on_new_chat_emo(uid, emo):
	var p = get_player_node_by_uid(uid)
	if p:
		p.show_emotion(emo)
	
func _effect_evaluate(text = 'Fantastic!'):
	#var screen_size = DisplayServer.window_get_size()
	#if screen_size.x / screen_size.y < 1.4 or g.v.app_version.is_in_review():
		## because if in review, pot will be invisible
		#evaluate_lb_default_pos = evaluate_ipad_pos_node.position
		#evaluate_lb_default_pos -= evaluate_lb.size * evaluate_lb.scale / 2
	evaluate_lb.text = text
	var tween = create_tween()
	evaluate_lb.modulate.a = 1
	evaluate_lb.scale = Vector2(1, 1)
	evaluate_lb.global_position = evaluate_lb_default_pos
	evaluate_lb.scale = Vector2(0, 0)
	tween.tween_property(self.evaluate_lb, 'scale', Vector2(1, 1), 0.4)
	# delay 1 second
	var y = evaluate_lb_default_pos.y - 30
	var d = 1
	tween.parallel().tween_property(evaluate_lb, 'modulate:a', 0, 0.3).set_delay(d)
	tween.parallel().tween_property(evaluate_lb, 'global_position:y', y, 0.3).set_delay(d)
	tween.parallel().tween_property(evaluate_lb, 'scale', Vector2(0.7, 0.7), 0.3).set_delay(d)
	pass

func _input(event):
	if g.v.config.CURRENT_MODE != g.v.config.MODES.LOCAL:
		return
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_W:
				
				#show_prepare_start()
				return
				#_effect_evaluate()
				self.list_players[0].show_emotion(4)
				print("W key pressed")
			elif event.keycode == KEY_S:
				self.list_players[0].on_chat('Hel;oddosososdds')
				#_effect_evaluate("win_messageall")
				return
				test_play_playercard()
				print("S key pressed")
			elif event.keycode == KEY_1:
				deal_my_cards([2,3,4,5,6,8,9,33])
				#on_game_start()
				#return
				#_effect_pot_contribute()
				#return
				#deal_my_cards([2,3,4,5,6,8,9,33])
				
				#for p in list_players:
					#p.show_bonus("+1 " + tr("LAST_TRICK"))
			elif event.keycode == KEY_2:
				for p in list_players:
					p.show_napoli("Napoli", [1,2,3])
		else:
			if event.keycode == KEY_W:
				print("W key released")

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
	g.v.scene_manager.open_gui("res://scenes/guis/GuideGUI.tscn")
	
func _effect_pot_contribute():
	if g.v.app_version.is_in_review():
		return
	center_play_pn_pos = NodeUtils.get_center_position(center_play_pn)
	var i = 0
	for player in list_players:
		var pos = player.global_position
		var des_p = Vector2(center_play_pn_pos.x, center_play_pn_pos.y)

		g.v.effect_mgr.effect_fly_coin_bet_table(
			"res://assets/images/lobby/lira_icon.png",
			5,
			pos,
			des_p,
			0.6,
			1,
			self,
			i == 0
		)
		i = i + 1
	pass
	
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
	for c in cheat_bot_card_pn.get_children():
		c.queue_free()
	
	var idx = 0
	var cp = NodeUtils.get_center_position(self.cheat_bot_card_pn)
	var total_cards = card_ids.size()
	var spacing = 70  # Adjust as needed
	var start_x = -200 + cp.x - ((total_cards - 1) * spacing) / 2  # Centered starting position

	for card_id in card_ids:
		var instance = card_scene.instantiate()
		cheat_bot_card_pn.add_child(instance)
		instance.set_card(card_id)
		instance.turn_face_up()
		instance.scale = Vector2(0.7, 0.7)
		instance.position = Vector2(start_x + idx * spacing, cp.y)  # Spread from center
		idx += 1

func _click_napoli_btn() -> void:
	napoli_btn.visible = false
	game_logic.send_action_napoli()
	pass # Replace with function body.

func on_user_turn():
	napoli_btn.visible = false
	var uid_in_turn = g.v.game_constants.game_logic.get_uid_in_turn()
	if len(list_napoli_highlights) > 0:
		for n in list_napoli_highlights:
			n.queue_free()
		list_napoli_highlights.clear()
	if game_logic.match_data.hand_in_round == 0:
		if uid_in_turn == g.v.player_info_mgr.get_user_id():
			var nap_sets = game_logic.find_napoli()
			if len(nap_sets) > 0:
				napoli_btn.visible = true
				for nap in nap_sets:
					_hight_light_napoli_set(nap)
					pass
	for p in self.list_players:
		if p.is_in_turn:
			p.end_turn()
			
			if p.user_data.uid == g.v.player_info_mgr.get_user_id():
				for c in list_my_cards:
					c.update_state_can_play(true)
					c.hint_pn.visible = false
					
		if p.user_data.uid == uid_in_turn:
			p.on_turn()	

	if uid_in_turn == g.v.player_info_mgr.get_user_id():
		for c in list_my_cards:
			c.update_state_can_play(true)
		if game_logic.match_data.state == MatchData.MATCH_STATE.PLAYING:
			if game_logic.is_my_turn():
				for c in list_my_cards:
					var is_valid_play = game_logic.check_valid_card_play(c.id)
					c.update_state_can_play(is_valid_play)
					if is_valid_play:
						c.update_recommend()


func _hight_light_napoli_set(nap):
	for c in list_my_cards:
		if c.id in nap:
			var h = pn_highlight_napoli.instantiate()
			c.get_parent().add_child(h)
			h.position = c.position
			h.z_index = c.z_index + 1
			h.rotation = c.rotation
				
			list_napoli_highlights.append(h)
			
func _on_user_napoli(uid, point_add, suits):
	var p = get_player_node_by_uid(uid)
	if uid == g.v.player_info_mgr.get_user_id():
		if len(list_napoli_highlights) > 0:
			for n in list_napoli_highlights:
				n.queue_free()
			list_napoli_highlights.clear()
	if p:
		var s = "+" + str(int(point_add / 3)) + " NAPOLI"
		p.show_napoli(s, suits)


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
		center_play_pn.scale = Vector2(1.5, 1.5)
		evaluate_ipad_pos_node.position.y += 200
		evaluate_lb.add_theme_font_size_override("font_size", 50)
		SCALE_CARD_COMPARE = 0.7 * r
		SCALE_CARD_DEAL_INIT = 0.8 * r
		SCALE_CARD_DRAW = 0.6 * r
		SCALE_CARD_NORMAL = 1 * r
		score_pn.scale = Vector2(2, 2)
		auto_play_pn.size.y = 600
		auto_play_pn.position.y = get_viewport().get_visible_rect().size.y - auto_play_pn.size.y
		auto_play_pn.find_child("ReturnTableBtn").scale = Vector2(2, 2)
	
