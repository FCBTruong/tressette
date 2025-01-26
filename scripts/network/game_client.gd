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
		GameConstants.CMDs.LOG_OUT:
			GameManager.logout()
		GameConstants.CMDs.GENERAL_INFO:
			var pkg = GameConstants.PROTOBUF.PACKETS.GeneralInfo.new()
			var result_code = pkg.from_bytes(payload)
			var timestamp_server = pkg.get_timestamp()
			var delta = timestamp_server - Time.get_unix_time_from_system()
			print('delta timestamp server-client', delta)
			GameManager.set_timestamp_server_delta(delta)
			pass
		_:
			GameManager.on_receive(cmd_id, payload)
			InGameChatMgr.on_receive(cmd_id, payload)
			PaymentMgr.on_receive(cmd_id, payload)
			PlayerInfoMgr.on_receive(cmd_id, payload)
			pass
		

func send_packet(cmd_id: int, payload: PackedByteArray):
	WebsocketClient.send_packet(cmd_id, payload)
