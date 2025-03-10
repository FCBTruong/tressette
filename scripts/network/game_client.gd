extends RefCounted
class_name GameClient


func on_receive_packet(cmd_id: int, payload: PackedByteArray):
	print('on_receive_packet', cmd_id)

	match cmd_id:
		g.v.game_constants.CMDs.TEST_MESSAGE:
			return
		g.v.game_constants.CMDs.ADMIN_BROADCAST:
			var pkg = g.v.game_constants.PROTOBUF.PACKETS.AdminBroadcast.new()
			var result_code = pkg.from_bytes(payload)
			
			var msg = pkg.get_mes()
			g.v.scene_manager.show_ok_dialog(msg)
		g.v.game_constants.CMDs.LOGIN:
			var pkg = g.v.game_constants.PROTOBUF.PACKETS.LoginResponse.new()
			var result_code = pkg.from_bytes(payload)
			var error = pkg.get_error()
			if error != 0:
				print('error login')
				g.v.scene_manager.show_ok_dialog("LOGIN_ERROR_" + str(error),
					func ():
						g.v.game_manager.logout()
				)
				
				return
			var uid = pkg.get_uid()
			var token = pkg.get_token()
			g.v.game_manager.login_success(uid, token)
		g.v.game_constants.CMDs.LOG_OUT:
			g.v.game_manager.logout()
		_:
			g.v.game_manager.on_receive(cmd_id, payload)
			g.v.ingame_chat_mgr.on_receive(cmd_id, payload)
			g.v.payment_mgr.on_receive(cmd_id, payload)
			g.v.player_info_mgr.on_receive(cmd_id, payload)
			g.v.login_mgr.on_receive(cmd_id, payload)
			g.v.friend_mgr.on_receive(cmd_id, payload)
			#SetteMezzoMgr.on_receive(cmd_id, payload)
			pass
		

func send_packet(cmd_id: int, payload: PackedByteArray):
	g.v.websocket_client.send_packet(cmd_id, payload)
