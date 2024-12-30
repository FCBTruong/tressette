extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func on_receive_packet(cmd_id: int, payload: PackedByteArray):
	print('on_receive_packet', cmd_id)

	match cmd_id:
		GameConstants.CMDs.TEST_MESSAGE:
			return
		GameConstants.CMDs.LOGIN:
			var pkg = GameConstants.PROTOBUF.PACKETS.LoginResponse.new()
			var result_code = pkg.from_bytes(payload)
			var uid = pkg.get_uid()
			var token = pkg.get_token()
			GameManager.login_success(uid, token)
		GameConstants.CMDs.USER_INFO:
			PlayerInfoMgr.on_receive_info(payload)
			pass
		GameConstants.CMDs.GENERAL_INFO:
			pass
		GameConstants.CMDs.GAME_INFO:
			GameManager.on_receive_gameinfo()
		_:
			pass
		

func send_packet(cmd_id: int, payload: PackedByteArray):
	WebsocketClient.send_packet(cmd_id, payload)
