extends Node

@export var _token:String = ''
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func login_success(uid: int, token: String):
	_token = token
	SceneManager.switch_scene(SceneManager.LOBBY_SCENE)
	pass

func get_token() -> String:
	return _token
	
func send_quick_play() -> void:
	GameClient.send_packet(GameConstants.CMDs.QUICK_PLAY, [])
	
func on_game_start() -> void:
	SceneManager.switch_scene("res://scenes/BoardScene.tscn")
	
func on_receive_gameinfo(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		GameConstants.CMDs.GAME_INFO:
			_handle_game_info(payload)
		GameConstants.CMDs.LEAVE_GAME:
			_handle_leave_game(payload)
			
func _handle_leave_game(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.LeaveGame.new()
	var result_code = pkg.from_bytes(payload)
	var status_leave = pkg.get_status()
	if status_leave == 0:
		SceneManager.switch_scene("res://scenes/LobbyScene.tscn")
	
func request_leave_game():
	var pkg = GameConstants.PROTOBUF.PACKETS.LeaveGame.new()
	GameClient.send_packet(GameConstants.CMDs.LEAVE_GAME, pkg.to_bytes())
	
func _handle_game_info(payload: PackedByteArray):
	var pkg = GameConstants.PROTOBUF.PACKETS.GameInfo.new()
	var result_code = pkg.from_bytes(payload)
	var match_data = MatchData.new()
	match_data.match_id = pkg.get_match_id()
	match_data.game_mode = pkg.get_game_mode()
	match_data.player_mode = pkg.get_player_mode()
	
	var uids = pkg.get_uids()
	print('uids: ', uids)
	var user_names = ['a', 'b', 'c']
	var golds = pkg.get_user_golds()
	
	var users: Array[UserData] = []
	
	var my_idx = -1
	for i in range(len(uids)):
		var uid = uids[i]
		var userdata = UserData.new(uid, user_names[i])
		users.append(userdata)
		if uid == PlayerInfoMgr.my_user_data.uid:
			my_idx = i
			userdata.game_data.seat_id = 0
		
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
	
	GameConstants.game_logic.on_update_matchdata(match_data)
	SceneManager.switch_scene("res://scenes/BoardScene.tscn")
