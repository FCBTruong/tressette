class_name GameLogic
extends RefCounted

var match_data: MatchData = null
var card_win_id: int
var win_point_hand: int
var hand_suit = -1 # current hand suit need to follow
var my_idx = 0 # in list users
var match_result = MatchData.MatchResult.new()

func get_list_player() -> Array[UserData]:
	return match_data.users
	
func on_user_leave_game():
	pass

func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		GameConstants.CMDs.GAME_INFO:
			_handle_game_info(payload)
		GameConstants.CMDs.LEAVE_GAME:
			_handle_leave_game(payload)
		GameConstants.CMDs.NEW_USER_JOIN_MATCH:
			_handle_user_join_match(payload)
		GameConstants.CMDs.USER_LEAVE_MATCH:
			_handle_user_leave_match(payload)
		GameConstants.CMDs.DEAL_CARD:
			_handle_deal_card(payload)
		GameConstants.CMDs.PLAY_CARD:
			_handle_play_card(payload)
		GameConstants.CMDs.START_GAME:
			_start_game(payload)
		GameConstants.CMDs.END_HAND:
			_handle_endhand(payload)
		GameConstants.CMDs.NEW_HAND:
			_handle_newhand(payload)
		GameConstants.CMDs.DRAW_CARD:
			_handle_draw_card(payload)
		GameConstants.CMDs.END_GAME:
			_handle_end_game(payload)
		GameConstants.CMDs.PREPARE_START_GAME:
			_handle_prepare_start(payload)


func _handle_user_leave_match(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.UserLeaveMatch.new()
	var result_code = pkg.from_bytes(payload)
	var uid = pkg.get_uid()
	var board_scene: BoardScene = SceneManager.INSTANCES.BOARD_SCENE
	if uid == PlayerInfoMgr.my_user_data.uid:
		board_scene.exit_game()
		return
	for user in match_data.users:
		if user.uid == uid:
			# update info
			user.uid = -1
	
	# reload
	board_scene.on_update_players()
	
func _handle_user_join_match(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.NewUserJoinMatch.new()
	var result_code = pkg.from_bytes(payload)
	var uid = pkg.get_uid()
	var seat_server = pkg.get_seat_server()
	var name = pkg.get_name()
	var team_id = pkg.get_team_id()
	var avatar = pkg.get_avatar()
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
			
	for user in match_data.users:
		print('debug seat', user.game_data.seat_id)
	
	# reload
	var board_scene: BoardScene = SceneManager.INSTANCES.BOARD_SCENE
	board_scene.on_update_players()
		
func _handle_leave_game(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.LeaveGame.new()
	var result_code = pkg.from_bytes(payload)
	var status_leave = pkg.get_status()
	if status_leave == 0:
		SceneManager.switch_scene("res://scenes/LobbyScene.tscn")
	
func _handle_game_info(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.GameInfo.new()
	var result_code = pkg.from_bytes(payload)
	match_data = MatchData.new()
	match_data.match_id = pkg.get_match_id()
	match_data.game_mode = pkg.get_game_mode()
	match_data.player_mode = pkg.get_player_mode()
	match_data.seat_delta = 0 # between server and client
	match_data.state = pkg.get_game_state()
	match_data.current_turn = pkg.get_current_turn()
	match_data.remain_cards = pkg.get_remain_cards()
	self.hand_suit = pkg.get_hand_suit()
	
	var compare = pkg.get_cards_compare()
	for c in compare:
		match_data.cards_compare.append(c)
	
	var uids = pkg.get_uids()
	print('uids: ', uids)
	var user_names = pkg.get_user_names()
	var golds = pkg.get_user_golds()
	var avatars = pkg.get_avatars()
	var user_points = pkg.get_user_points()
	var team_ids = pkg.get_team_ids()
	
	var users: Array[UserData] = []
	
	my_idx = -1
	for i in range(len(uids)):
		var uid = uids[i]
		var userdata = UserData.new(uid, user_names[i])
		userdata.game_data.points = user_points[i]
		userdata.game_data.team_id = team_ids[i]
		userdata.avatar = avatars[i]
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
	
	var my_cards = pkg.get_my_cards()
	_update_my_cards(my_cards)
	
	SceneManager.switch_scene("res://scenes/BoardScene.tscn")

func _handle_deal_card(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.DealCard.new()
	var result_code = pkg.from_bytes(payload)
	var cards = pkg.get_cards()
	cards.sort_custom(_card_sorter)
	match_data.remain_cards = pkg.get_remain_cards()
	
	for player in match_data.users:
		if player.uid == PlayerInfoMgr.my_user_data.uid:
			player.game_data.cards = []
			for c in cards:
				player.game_data.cards.append(int(c))
	print('_handle_deal_card', cards)
	SceneManager.INSTANCES.BOARD_SCENE.deal_my_cards(self.get_my_cards())
	
func _handle_play_card(payload: PackedByteArray):
	if not match_data:
		return
	var pkg = GameConstants.PROTOBUF.PACKETS.PlayCard.new()
	var result_code = pkg.from_bytes(payload)
	var uid = pkg.get_uid()
	var card_id = pkg.get_card_id()
	var auto = pkg.get_auto()
	self.hand_suit = pkg.get_hand_suit()
	match_data.current_turn = pkg.get_current_turn()
	SceneManager.INSTANCES.BOARD_SCENE.play_card(uid, card_id, auto)
	push_cards_compare(uid, card_id)

func send_play_card(card_id: int):
	match_data.current_turn = -1
	var pkg = GameConstants.PROTOBUF.PACKETS.PlayCard.new()
	pkg.set_card_id(card_id)
	GameClient.send_packet(GameConstants.CMDs.PLAY_CARD, pkg.to_bytes())
	
	var idx = get_index_by_uid(PlayerInfoMgr.my_user_data.uid)
	
	# remove this card 
	match_data.users[idx].game_data.cards.erase(card_id)
	
	push_cards_compare(PlayerInfoMgr.my_user_data.uid, card_id)
	
func push_cards_compare(uid, card_id):
	var idx = get_index_by_uid(uid)
	match_data.cards_compare[idx] = card_id
	
func get_my_cards():
	for user in match_data.users:
		if user.uid == PlayerInfoMgr.my_user_data.uid:
			return user.game_data.cards
	return []
	
func _start_game(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.StartGame.new()
	var result_code = pkg.from_bytes(payload)
	match_data.state = MatchData.MATCH_STATE.PLAYING
	reset_cards_compare()

func check_finishhand():
	print('cards compares', match_data.cards_compare)
	for c in match_data.cards_compare:
		if c == -1:
			return false
	return true

func get_index_by_uid(uid: int) -> int:
	for i in range(len(match_data.users)):
		var u = match_data.users[i]
		if u.uid == uid:
			return i
	return -1

func get_user(uid: int) -> UserData:
	for i in range(len(match_data.users)):
		var u = match_data.users[i]
		if u.uid == uid:
			return u
	return null
	
func reset_cards_compare():
	match_data.cards_compare = []
	for i in range(match_data.player_mode):
		match_data.cards_compare.append(-1)

func is_my_turn():
	#print('is_my_turn ', match_data.current_turn)
	if match_data.current_turn == -1:
		return false
	var uid_inturn = match_data.users[match_data.current_turn].uid
	if uid_inturn == PlayerInfoMgr.my_user_data.uid:
		return true
	else:
		return false
		
func get_uid_in_turn():
	if match_data.current_turn == -1:
		return -1
	return match_data.users[match_data.current_turn].uid
	
func _update_my_cards(card_ids):
	card_ids.sort_custom(_card_sorter)
	# sort card ids by suits and rank tressette
	for player in match_data.users:
		if player.uid == PlayerInfoMgr.my_user_data.uid:
			player.game_data.cards = card_ids

func _card_sorter(a: int, b: int) -> bool:
	var suit_a = a % 4  # Suit of card a
	var suit_b = b % 4  # Suit of card b

	# First, compare by suit (mod 4)
	if suit_a < suit_b:
		return false
	elif suit_a > suit_b:
		return true

	# If suits are the same, compare by card ID (optional)
	if a < b:
		return false
	elif a > b:
		return true

	return false
	
func get_card_win_inhand():
	return card_win_id
	
func _handle_endhand(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.EndHand.new()
	var result_code = pkg.from_bytes(payload)
	var win_uid = pkg.get_win_uid()
	win_point_hand = pkg.get_win_point()
	card_win_id = pkg.get_win_card()
	var points = pkg.get_user_points()
	
	var i = 0
	for user in match_data.users:
		user.game_data.points = points[i]
		i += 1
	
	print('finish rounds...')
	SceneManager.INSTANCES.BOARD_SCENE.on_finishhand()
	reset_cards_compare()
	
func _handle_newhand(payload: PackedByteArray):
	if not match_data:
		return
	var pkg = GameConstants.PROTOBUF.PACKETS.NewHand.new()
	var result_code = pkg.from_bytes(payload)
	match_data.current_turn = pkg.get_current_turn()
	print('new hand: ', match_data.current_turn)
	
	self.hand_suit = -1


func _handle_draw_card(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.DrawCard.new()
	var result_code = pkg.from_bytes(payload)
	var cards = pkg.get_cards()
	var i = 0
	var arr = []
	for user in match_data.users:
		user.game_data.cards.append(cards[i])
		
		var obj = {
			'uid': user.uid,
			'card': cards[i]
		}
		arr.append(obj)
		i += 1
	
	SceneManager.INSTANCES.BOARD_SCENE.on_draw_cards(arr)
	
func _handle_end_game(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.EndGame.new()
	var result_code = pkg.from_bytes(payload)
	var win_uids = pkg.get_win_uids()
	var score_cards = pkg.get_score_cards()
	var score_last_tricks = pkg.get_score_last_tricks()
	var score_totals = pkg.get_score_totals()
	match_result = MatchData.MatchResult.new()
	match_result.is_win = PlayerInfoMgr.my_user_data.uid in win_uids
	
	match_result.scores = []
	for i in range(len(match_data.users)):
		var score_data = MatchData.MatchResultScore.new()
		score_data.score_card = score_cards[i]
		score_data.score_last_trick = score_last_tricks[i]
		score_data.score_total = score_totals[i]
		match_result.scores.append(score_data)
		
	SceneManager.open_gui('res://scenes/board/GameResultGUI.tscn')

func _handle_prepare_start(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.PrepareStartGame.new()
	var result_code = pkg.from_bytes(payload)
	var time_start = pkg.get_time_start()
	await SceneManager.get_tree().create_timer(0.5).timeout
	SceneManager.INSTANCES.BOARD_SCENE.show_prepare_start()
	match_data.state = MatchData.MATCH_STATE.PREPARING_START
	
func get_my_team_score() -> int:
	var c = 0
	var my_team_id = match_data.users[my_idx].game_data.team_id
	for u in match_data.users:
		if u.game_data.team_id == my_team_id:
			c += u.game_data.points
	return c

func get_opponent_team_score() -> int:
	#SignalBus.update_current_turn.emit()
	var c = 0
	var my_team_id = match_data.users[my_idx].game_data.team_id
	for u in match_data.users:
		if u.game_data.team_id != my_team_id:
			c += u.game_data.points
	return c

func check_valid_card_play(card_id):
	if self.hand_suit == -1:
		return true
	var suit = card_id % 4
	if suit == self.hand_suit:
		return true
	
	# get my cards
	var user = self.match_data.users[my_idx]
	var my_cards = user.game_data.cards
	for c in my_cards:
		var c_suit = c % 4
		if c_suit == self.hand_suit:
			# because you have a card with that suit -> must play
			return false
			
	return true
	
func update():
	# handle logic every frame
	if match_data.state == MatchData.MATCH_STATE.PLAYING:
		pass
	

	
