extends Node

var match_data: SetteMezzoMatchData
var my_idx = -1
var dealer_cards = []

class SetteDealCard:
	var uid: int
	var card: int
	
func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		GameConstants.CMDs.SETTE_MEZZO_GAME_INFO:
			_handle_game_info(payload)
			
		GameConstants.CMDs.SETTE_MEZZO_USER_LEAVE_MATCH:
			_handle_user_leave_match(payload)
			
		GameConstants.CMDs.SETTE_MEZZO_START_GAME:
			_start_game(payload)
			
		GameConstants.CMDs.SETTE_MEZZO_PREPARE_START_GAME:
			_handle_prepare_start(payload)
			
		GameConstants.CMDs.SETTE_MEZZO_NEW_USER_JOIN_MATCH:
			_handle_user_join_match(payload)
	

func _handle_game_info(payload):
	GameManager.CURRENT_GAME_PLAY = 1
	SceneManager.clear_loading()
	var pkg = GameConstants.PROTOBUF.PACKETS.SetteMezzoGameInfo.new()
	var result_code = pkg.from_bytes(payload)
	match_data = SetteMezzoMatchData.new()
	match_data.bet = pkg.get_bet()
	match_data.match_id = pkg.get_match_id()
	match_data.game_mode = pkg.get_game_mode()
	match_data.player_mode = pkg.get_player_mode()
	match_data.seat_delta = 0 # between server and client
	match_data.state = pkg.get_game_state()
	match_data.current_turn = pkg.get_current_turn()
	match_data.remain_cards = pkg.get_remain_cards()
	match_data.pot_value = pkg.get_pot_value()
	match_data.current_round = pkg.get_current_round()
	match_data.hand_in_round = pkg.get_hand_in_round()
	match_data.banker_uid = pkg.get_banker_uid()
	
	var uids = pkg.get_uids()
	print('uids: ', uids)
	var user_names = pkg.get_user_names()
	var golds = pkg.get_user_golds()
	var avatars = pkg.get_avatars()
	var team_ids = pkg.get_team_ids()
	
	var users: Array[UserData] = []
	
	my_idx = -1
	for i in range(len(uids)):
		var uid = uids[i]
		var userdata = UserData.new(uid, user_names[i])
		userdata.avatar = avatars[i]
		userdata.gold = golds[i]
		users.append(userdata)
		if uid == PlayerInfoMgr.my_user_data.uid:
			my_idx = i
			userdata.game_data.seat_id = 0
			match_data.seat_delta = i
		
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
	
	
	SceneManager.switch_scene("res://scenes/sette_mezzo/SetteMezzoScene.tscn")



func quick_play():
	GameClient.send_packet(GameConstants.CMDs.SETTE_MEZZO_QUICK_PLAY, [])
	pass


func get_list_player() -> Array[UserData]:
	return match_data.users
	
func _handle_user_leave_match(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.UserLeaveMatch.new()
	var result_code = pkg.from_bytes(payload)
	var uid = pkg.get_uid()
	var reason = pkg.get_reason()
	var board_scene = SceneManager.get_current_scene()
	if not board_scene is SetteMezzoScene:
		return
	if uid == PlayerInfoMgr.my_user_data.uid:
		if reason == GameConstants.REASON_KICK_GAMES.NOT_ENOUGH_GOLD:
			SceneManager.show_dialog(
				tr('NOT_ENOUGH_GOLD_PLAY_BUY')
				,
				func ():
					SceneManager.switch_scene(SceneManager.SHOP_SCENE),
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
	board_scene.on_update_players()
	
	
func get_user(uid: int) -> UserData:
	for i in range(len(match_data.users)):
		var u = match_data.users[i]
		if u.uid == uid:
			return u
	return null

func get_my_cards():
	return []

func _start_game(payload: PackedByteArray):
	if not match_data:
		return
	var pkg = GameConstants.PROTOBUF.PACKETS.SetteMezzoStartGame.new()
	var result_code = pkg.from_bytes(payload)

	match_data.state = MatchData.MATCH_STATE.PLAYING
	#
	#var players_gold = pkg.get_players_gold()
	#var i = 0
	#for p in match_data.users:
		#p.gold = players_gold[i]
		#i += 1
		#
		#SignalBus.emit_signal_global("ingame_update_player_money", [p.uid])
	#
	
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
		if uid == -1:
			dealer_cards.append(cards[i])
			i += 1
			continue
		var p = get_user(uid)
		p.game_data.cards = [cards[i]]
		i += 1
	var scene = SceneManager.get_current_scene()
	if scene is SetteMezzoScene:
		scene.on_game_start()
		await get_tree().create_timer(1).timeout
		scene.deal_cards(card_deal)


func _handle_prepare_start(payload: PackedByteArray):
	if not match_data:
		return
	var pkg = GameConstants.PROTOBUF.PACKETS.PrepareStartGame.new()
	var result_code = pkg.from_bytes(payload)
	var time_start = pkg.get_time_start()
	await SceneManager.get_tree().create_timer(0.5).timeout
	var cur_scene = SceneManager.get_current_scene()
	match_data.state = MatchData.MATCH_STATE.PREPARING_START
	if cur_scene is SetteMezzoScene:
		cur_scene.show_prepare_start()	


func _handle_user_join_match(payload: PackedByteArray):
	if not match_data:
		return
	var pkg = GameConstants.PROTOBUF.PACKETS.NewUserJoinMatch.new()
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
	
	# find slot
	for user in match_data.users:
		if user.game_data.seat_id == seat_id:
			# update info
			user.uid = uid
			user.name = name
			user.game_data.team_id = team_id
			user.avatar = avatar
			user.gold = gold
			
	for user in match_data.users:
		print('debug seat', user.game_data.seat_id)
	
	# reload
	var cur_scene = SceneManager.get_current_scene()
	if cur_scene is SetteMezzoScene:
		cur_scene.on_update_players()
	
func action_hit():
	pass

func action_stand():
	pass
