extends RefCounted
class_name SetteMezzoMgr

var match_data: SetteMezzoMatchData
var my_idx = -1
var dealer_cards = []
var playing_users = []
var play_turn_time = 0 # server timestamp, time player must play
var is_registered_leave = false
var time_end_bet
var time_bet_total = 10
class SetteDealCard:
	var uid: int
	var card: int
	
func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		g.v.game_constants.CMDs.REGISTER_LEAVE_GAME:
			_handle_register_leave_game(payload)
			
		g.v.game_constants.CMDs.SETTE_MEZZO_GAME_INFO:
			_handle_game_info(payload)
			
		g.v.game_constants.CMDs.SETTE_MEZZO_USER_LEAVE_MATCH:
			_handle_user_leave_match(payload)
			
		g.v.game_constants.CMDs.SETTE_MEZZO_START_GAME:
			_start_game(payload)
			
		g.v.game_constants.CMDs.SETTE_MEZZO_PREPARE_START_GAME:
			_handle_prepare_start(payload)
			
		g.v.game_constants.CMDs.SETTE_MEZZO_NEW_USER_JOIN_MATCH:
			_handle_user_join_match(payload)
		g.v.game_constants.CMDs.SETTE_MEZZO_ACTION_HIT:
			_handle_action_hit(payload)
		g.v.game_constants.CMDs.SETTE_MEZZO_ACTION_STAND:
			_handle_action_stand(payload)
		g.v.game_constants.CMDs.SETTE_MEZZO_UPDATE_TURN:
			_handle_update_turn(payload)
		g.v.game_constants.CMDs.SETTE_MEZZO_SHOW_BANKER_CARD:
			_handle_show_banker_card(payload)
		g.v.game_constants.CMDs.SETTE_MEZZO_END_GAME:
			_handle_end_game(payload)
		g.v.game_constants.CMDs.SETTE_MEZZO_BETTING:
			_handle_start_betting(payload)
		g.v.game_constants.CMDs.SETTE_MEZZO_USER_BET:
			_received_user_bet(payload)
	

func _handle_game_info(payload):
	g.v.game_manager.CURRENT_GAME_PLAY = 1
	g.v.scene_manager.clear_loading()
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoGameInfo.new()
	var result_code = pkg.from_bytes(payload)
	match_data = SetteMezzoMatchData.new()
	playing_users.clear()
	match_data.bet = pkg.get_bet()
	match_data.match_id = pkg.get_match_id()
	match_data.game_mode = pkg.get_game_mode()
	match_data.player_mode = pkg.get_player_mode()
	match_data.seat_delta = 0 # between server and client
	match_data.state = pkg.get_game_state()
	match_data.current_turn = pkg.get_current_turn()
	match_data.pot_value = pkg.get_pot_value()
	match_data.current_round = pkg.get_current_round()
	match_data.hand_in_round = pkg.get_hand_in_round()
	match_data.banker_uid = pkg.get_banker_uid()
	dealer_cards = pkg.get_banker_cards()
	play_turn_time = pkg.get_play_turn_time()
	self.time_end_bet = pkg.get_time_end_bet()
	self.is_registered_leave = pkg.get_is_registered_leave()
	
	var uids = pkg.get_uids()
	print('uids: ', match_data.current_turn)
	var user_names = pkg.get_user_names()
	var golds = pkg.get_user_golds()
	var avatars = pkg.get_avatars()
	var team_ids = pkg.get_team_ids()
	var is_in_games = pkg.get_is_in_games()
	var player_bets = pkg.get_player_bets()
	
	var users: Array[UserData] = []
	var player_infos = pkg.get_player_infos()
	my_idx = -1
	for i in range(len(uids)):
		var uid = uids[i]
		var player_bytes = player_infos[i]
		var pkg_player = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoPlayerInfo.new()
		pkg_player.from_bytes(player_bytes)
		var userdata = UserData.new(uid, user_names[i])
		userdata.avatar = avatars[i]
		userdata.gold = golds[i]
		userdata.game_data.is_in_game = is_in_games[i]
		userdata.game_data.sette_bet = player_bets[i]
		userdata.game_data.cards = pkg_player.get_card_ids()
		if userdata.game_data.is_in_game:
			playing_users.append(uid)
		users.append(userdata)
		if uid == g.v.player_info_mgr.my_user_data.uid:
			my_idx = i
			userdata.game_data.seat_id = 0
			match_data.seat_delta = i
	print("oodods", playing_users)
	# Assign seat IDs
	if my_idx != -1:
		# Assign seat IDs starting from my_idx
		var seat_id = 1  # Start with seat_id 1 as 0 is already assigned
		for i in range(len(users)):
			var index = (my_idx + i + 1) % len(users)  # Circular index
			if index != my_idx:  # Skip the user's own seat
				users[index].game_data.seat_id = seat_id
				seat_id += 1
	else:
		# Assign seat IDs sequentially from 0
		for i in range(len(users)):
			users[i].game_data.seat_id = i
	match_data.users = users
	
	
	g.v.scene_manager.switch_scene("res://scenes/sette_mezzo/SetteMezzoScene.tscn")



func quick_play():
	if g.v.player_info_mgr.my_user_data.gold < g.v.game_server_config.min_gold_play_sette_mezzo:
		var str_noti = tr('NOT_ENOUGH_MIN_GOLD_PLAY_BUY')
		str_noti = str_noti.replace("@num", StringUtils.point_number(g.v.game_server_config.min_gold_play_sette_mezzo))
		g.v.scene_manager.show_dialog(
				str_noti
				,
				func ():
					g.v.scene_manager.switch_scene(g.v.scene_manager.SHOP_SCENE),
				func ():
					pass,
				true
			)
			
		return
	g.v.scene_manager.add_loading(3)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.SETTE_MEZZO_QUICK_PLAY, [])
	pass


func get_list_player() -> Array[UserData]:
	return match_data.users
	
func _handle_user_leave_match(payload: PackedByteArray):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.UserLeaveMatch.new()
	var result_code = pkg.from_bytes(payload)
	var uid = pkg.get_uid()
	var reason = pkg.get_reason()
	var board_scene = g.v.scene_manager.get_current_scene()
	if not board_scene is SetteMezzoScene:
		return
	if uid == g.v.player_info_mgr.my_user_data.uid:
		if reason == g.v.game_constants.REASON_KICK_GAMES.NOT_ENOUGH_GOLD:
			g.v.scene_manager.show_dialog(
				tr('NOT_ENOUGH_GOLD_PLAY_BUY')
				,
				func ():
					g.v.scene_manager.switch_scene(g.v.scene_manager.SHOP_SCENE),
				func ():
					board_scene.exit_game(),
				true
			)
		else:
			board_scene.exit_game()
		return
	for user in match_data.users:
		if user.uid == uid:
			# update info
			user.uid = -1
	
	# reload
	board_scene.on_update_players(uid)
	
	
func get_user(uid: int) -> UserData:
	for i in range(len(match_data.users)):
		var u = match_data.users[i]
		if u.uid == uid:
			return u
	return null

func get_my_cards():
	for p in self.match_data.users:
		if p.uid == g.v.player_info_mgr.get_user_id():
			return p.game_data.cards

func _start_game(payload: PackedByteArray):
	if not match_data:
		return
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoStartGame.new()
	var result_code = pkg.from_bytes(payload)

	match_data.state = MatchData.MATCH_STATE.PLAYING
	#
	#var players_gold = pkg.get_players_gold()
	#var i = 0
	
	var uids = pkg.get_uids()
	var cards = pkg.get_cards()
	dealer_cards = []
	var i = 0
	var card_deal = []

	for uid in uids:
		var a = SetteDealCard.new()
		a.uid = uid
		a.card = cards[i]
		card_deal.append(a)
		if uid == g.v.game_constants.BANKER_DEFAULT_UID:
			dealer_cards.append(cards[i])
			i += 1
			continue
		var p = get_user(uid)
		p.game_data.cards = [cards[i]]
		i += 1
	var scene = g.v.scene_manager.get_current_scene()
	if scene is SetteMezzoScene:
		scene.on_game_start()
		#await ROOT.get_tree().create_timer(0.25).timeout
		scene.deal_cards(card_deal)


func _handle_prepare_start(payload: PackedByteArray):
	return
	if not match_data:
		return
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.PrepareStartGame.new()
	var result_code = pkg.from_bytes(payload)
	var time_start = pkg.get_time_start()
	await ROOT.get_tree().create_timer(0.5).timeout
	var cur_scene = g.v.scene_manager.get_current_scene()
	match_data.state = MatchData.MATCH_STATE.PREPARING_START
	if cur_scene is SetteMezzoScene:
		cur_scene.show_prepare_start()	


func _handle_user_join_match(payload: PackedByteArray):
	if not match_data:
		return
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.NewUserJoinMatch.new()
	var result_code = pkg.from_bytes(payload)
	var uid = pkg.get_uid()
	var seat_server = pkg.get_seat_server()
	var name = pkg.get_name()
	var team_id = pkg.get_team_id()
	var avatar = pkg.get_avatar()
	var gold = pkg.get_gold()
	print('seat server', seat_server)
	var seat_id = seat_server - match_data.seat_delta
	if seat_id < 0:
		seat_id += match_data.player_mode
	print('user ', uid, ' join with seat ', seat_id)
	
	for user in match_data.users:
		if user.game_data.seat_id == seat_id:
			# update info
			user.uid = uid
			user.name = name
			user.game_data = UserGameData.new()
			user.game_data.team_id = team_id
			user.game_data.is_in_game = not self.is_game_started()
			user.avatar = avatar
			user.gold = gold
			
	for user in match_data.users:
		print('debug seat', user.game_data.seat_id)
	
	# reload
	var cur_scene = g.v.scene_manager.get_current_scene()
	if cur_scene is SetteMezzoScene:
		cur_scene.on_update_players(uid)
	
func action_hit():
	g.v.game_client.send_packet(g.v.game_constants.CMDs.SETTE_MEZZO_ACTION_HIT, [])

func action_stand():
	g.v.game_client.send_packet(g.v.game_constants.CMDs.SETTE_MEZZO_ACTION_STAND, [])

func get_uid_in_turn():
	if not match_data:	
		return -1
	if match_data.current_turn == g.v.game_constants.BANKER_DEFAULT_TURN:
		return g.v.game_constants.BANKER_DEFAULT_UID
		
	if match_data.current_turn == -1:
		return -1
	return self.playing_users[match_data.current_turn]

func _handle_action_hit(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoActionHit.new()

	var result_code = pkg.from_bytes(payload)
	var uid = pkg.get_uid()
	var card_id = pkg.get_card_id()
	
	var scene = g.v.scene_manager.get_current_scene()
	
	if uid == g.v.game_constants.BANKER_DEFAULT_UID:
		dealer_cards.append(card_id)
	else:
		for p in self.match_data.users:
			if p.uid == uid:
				p.game_data.cards.append(card_id)
	if scene is SetteMezzoScene:
		scene.user_hit_card(uid, card_id)
	pass
	
func _handle_action_stand(payload):
	if not self.match_data:
		return
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoActionStand.new()

	var result_code = pkg.from_bytes(payload)
	var uid = pkg.get_uid()
	self.match_data.current_turn = pkg.get_current_turn()
	self.play_turn_time = pkg.get_play_turn_time()
	
	var scene = g.v.scene_manager.get_current_scene()
	
	if scene is SetteMezzoScene:
		scene.user_stand(uid)
		scene.on_user_turn()
	
	
func _handle_update_turn(payload):
	if not match_data:
		return
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoUpdateTurn.new()

	var result_code = pkg.from_bytes(payload)

	self.match_data.current_turn = pkg.get_current_turn()
	self.play_turn_time = pkg.get_play_turn_time()
	var scene = g.v.scene_manager.get_current_scene()
	
	
	if scene is SetteMezzoScene:
		scene.on_user_turn()

func _handle_show_banker_card(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoShowBankerCard.new()

	var result_code = pkg.from_bytes(payload)

	var card_id = pkg.get_card_id()
	var scene = g.v.scene_manager.get_current_scene()
	self.dealer_cards = [card_id]
	
	if scene is SetteMezzoScene:
		scene.dealer_show_card(card_id)

func calculate_score(cards):
	var score = 0.0
	for c in cards:
		if c == -1:
			continue
		var r = int(c / 4)
		if r < 7:
			score += r + 1
		else:
			score += 0.5
	return score

func get_score_uid(uid):
	if uid == g.v.game_constants.BANKER_DEFAULT_UID:
		return calculate_score(dealer_cards)
	else:
		for p in self.match_data.users:
			if p.uid == uid:
				var cards = p.game_data.cards
				return calculate_score(cards)
	return 0

func _handle_end_game(payload):
	if not match_data:
		return
	match_data.state = MatchData.MATCH_STATE.ENDED
	var scene = g.v.scene_manager.get_current_scene()
	
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoEndGame.new()

	var result_code = pkg.from_bytes(payload)
	var uids = pkg.get_uids()
	var is_wins = pkg.get_is_wins()
	var scores = pkg.get_scores()
	var golds_change = pkg.get_golds_change()
	
	var player_golds = pkg.get_player_golds()
	
	for i in range(len(uids)):
		var gold = player_golds[i]
		var uid = uids[i]
		var u = get_user(uid)
		u.gold = gold
		g.v.signal_bus.emit_signal_global("ingame_update_player_money", [uid])
	
	if scene is SetteMezzoScene:
		scene.on_end_game(uids, is_wins, golds_change)
	pass

func _handle_register_leave_game(payload: PackedByteArray):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.RegisterLeaveGame.new()
	var result_code = pkg.from_bytes(payload)
	var status_leave = pkg.get_status()
	self.is_registered_leave = status_leave == 0 
	
	# Make toast
	if self.is_registered_leave:
		g.v.scene_manager.show_toast("REGISTER_LEAVE")
	else:
		g.v.scene_manager.show_toast("CANCEL_REGISTER_LEAVE")
	
	var scene = g.v.scene_manager.get_current_scene()
	if scene is BaseBoardScene:
		scene.update_register_leave_state()

func _handle_start_betting(payload):
	if not match_data:
		return
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoBetting.new()
	var result_code = pkg.from_bytes(payload)
	self.match_data.state = MatchData.MATCH_STATE.BETTING
	self.time_end_bet = pkg.get_time_end_bet()
	self.time_bet_total = self.time_end_bet - g.v.game_manager.get_timestamp_server()
	var scene = g.v.scene_manager.get_current_scene()
	
	playing_users.clear()
	for p in match_data.users:
		p.game_data.sette_bet = 0
		p.game_data.is_in_game = true
		playing_users.append(p.uid)
		
	if scene is SetteMezzoScene:
		scene.on_start_betting()

func send_bet(bet_value: int):
	print("user bet::: ", bet_value)
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoUserBet.new()
	pkg.set_bet(bet_value)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.SETTE_MEZZO_USER_BET, pkg.to_bytes())

func _received_user_bet(payload):
	if not match_data:
		return
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SetteMezzoUserBet.new()
	var result_code = pkg.from_bytes(payload)
	var uid = pkg.get_uid()
	var bet = pkg.get_bet()
	
	var p = get_user(uid)
	p.game_data.sette_bet += bet
	p.gold -= bet
	
	g.v.signal_bus.emit_signal_global("ingame_update_player_money", [p.uid])
	var scene = g.v.scene_manager.get_current_scene()
	if scene is SetteMezzoScene:
		scene.on_user_bet(uid, p.game_data.sette_bet)
	pass


func open_guide_gui():
	return g.v.scene_manager.open_gui("res://scenes/sette_mezzo/SetteMezzoGuideGUI.tscn")

func is_me_in_game():
	if not match_data:
		return false
	for uid in self.playing_users:
		if uid == g.v.player_info_mgr.get_user_id():
			return true
	return false
	
func is_game_started():
	if not match_data:
		return false
	if self.match_data.state == MatchData.MATCH_STATE.PLAYING \
		or self.match_data.state == MatchData.MATCH_STATE.BETTING:
			return true
	return false
