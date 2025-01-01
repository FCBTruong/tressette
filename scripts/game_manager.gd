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
	GameConstants.game_logic.on_receive(cmd_id, payload)
	
func request_leave_game():
	var pkg = GameConstants.PROTOBUF.PACKETS.LeaveGame.new()
	GameClient.send_packet(GameConstants.CMDs.LEAVE_GAME, pkg.to_bytes())
	
