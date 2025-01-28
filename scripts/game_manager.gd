extends Node

@export var _token:String = 'default' # note, protobuf string can not be empty, otherwise will error not sent

@export var timestamp_server_delta = 0
@export var enable_sound = true
@export var enable_chat_ingame = true
var table_list = []
var min_gold_play = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func login_success(uid: int, token: String):
	_token = token
	PaymentMgr.on_user_login()
	SceneManager.switch_scene(SceneManager.LOADING_SCENE)

func get_token() -> String:
	return _token
	
func send_quick_play() -> void:
	if PlayerInfoMgr.my_user_data.gold < self.min_gold_play:
		SceneManager.show_dialog('
		Not enough gold to play, Want to buy more?
		',
		func ():
			SceneManager.switch_scene(SceneManager.SHOP_SCENE)
		)
		
	GameClient.send_packet(GameConstants.CMDs.QUICK_PLAY, [])
	
func on_game_start() -> void:
	SceneManager.switch_scene("res://scenes/BoardScene.tscn")
	
func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		GameConstants.CMDs.GENERAL_INFO:
			var pkg = GameConstants.PROTOBUF.PACKETS.GeneralInfo.new()
			var result_code = pkg.from_bytes(payload)
			self.min_gold_play = pkg.get_min_gold_play()
			var timestamp_server = pkg.get_timestamp()
			var delta = timestamp_server - Time.get_unix_time_from_system()
			print('delta timestamp server-client', delta)
			GameManager.set_timestamp_server_delta(delta)
		GameConstants.CMDs.TABLE_LIST:
			var pkg = GameConstants.PROTOBUF.PACKETS.TableList.new()
			var result_code = pkg.from_bytes(payload)
			var table_ids = pkg.get_table_ids()
			var bets = pkg.get_bets()
			table_list = []
			
			for i in range(len(table_ids)):
				var table = TableInfo.new()
				table.match_id = table_ids[i]
				table_list.append(table)
			print('emit signalllll', len(table_list))
			SignalBus.emit_signal_global("update_table_list")

		_:
			GameConstants.game_logic.on_receive(cmd_id, payload)
	
func request_leave_game():
	var pkg = GameConstants.PROTOBUF.PACKETS.LeaveGame.new()
	GameClient.send_packet(GameConstants.CMDs.LEAVE_GAME, pkg.to_bytes())
	
func get_timestamp_server():
	return Time.get_unix_time_from_system() + timestamp_server_delta
	
func set_timestamp_server_delta(del):
	timestamp_server_delta = del # milliseconds
	
func logout():
	SceneManager.switch_scene(SceneManager.LOGIN_SCENE)
	
func send_get_table_list():
	GameClient.send_packet(GameConstants.CMDs.TABLE_LIST, [])
