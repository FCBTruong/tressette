extends Node

@export var _token:String = 'default' # note, protobuf string can not be empty, otherwise will error not sent

@export var timestamp_server_delta = 0
@export var enable_sound = true
@export var enable_chat_ingame = true
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
	GameClient.send_packet(GameConstants.CMDs.QUICK_PLAY, [])
	
func on_game_start() -> void:
	SceneManager.switch_scene("res://scenes/BoardScene.tscn")
	
func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
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
