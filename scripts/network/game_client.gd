extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func on_receive_packet(cmd_id: int, payload: PackedByteArray):
	print('on_receive_packet', cmd_id)

	match cmd_id:
		GameConstants.CMDs.TEST_MESSAGE:
			return
		GameConstants.CMDs.ADMIN_BROADCAST:
			var pkg = GameConstants.PROTOBUF.PACKETS.AdminBroadcast.new()
			var result_code = pkg.from_bytes(payload)
			
			var msg = pkg.get_mes()
			SceneManager.show_ok_dialog(msg)
		GameConstants.CMDs.LOGIN:
			var pkg = GameConstants.PROTOBUF.PACKETS.LoginResponse.new()
			var result_code = pkg.from_bytes(payload)
			var error = pkg.get_error()
			if error != 0:
				print('error login')
				SceneManager.show_ok_dialog("LOGIN_ERROR_" + str(error),
					func ():
						GameManager.logout()
				)
				
				return
			var uid = pkg.get_uid()
			var token = pkg.get_token()
			GameManager.login_success(uid, token)
		GameConstants.CMDs.LOG_OUT:
			GameManager.logout()
		_:
			GameManager.on_receive(cmd_id, payload)
			InGameChatMgr.on_receive(cmd_id, payload)
			PaymentMgr.on_receive(cmd_id, payload)
			PlayerInfoMgr.on_receive(cmd_id, payload)
			LoginMgr.on_receive(cmd_id, payload)
			FriendManager.on_receive(cmd_id, payload)
			pass
		

func send_packet(cmd_id: int, payload: PackedByteArray):
	WebsocketClient.send_packet(cmd_id, payload)
