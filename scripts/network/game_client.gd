extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func on_receive_packet(cmd_id: int, payload: PackedByteArray):
	print('on_receive_packet', cmd_id)
	var packet_receive = BaseReceivePacket.new(payload)
	match cmd_id:
		GameConstants.CMDs.TEST_MESSAGE:
			var a = packet_receive.get_int32()
			print('aaa', a)
			var un = packet_receive.get_string()
			var b = packet_receive.get_double()
			var x = packet_receive.get_bool()
			print('bbb', un)
			print('bbb', b, x)
		GameConstants.CMDs.LOGIN:
			var uid = packet_receive.get_int32()
			var token = packet_receive.get_string()
			GameManager.login_success(uid, token)
		GameConstants.CMDs.USER_INFO:
			PlayerInfoMgr.on_receive_info(packet_receive)
			pass
		GameConstants.CMDs.GENERAL_INFO:
			pass
		GameConstants.CMDs.GAME_INFO:
			GameManager.on_receive_gameinfo()
		_:
			pass
		

func send_packet(cmd_id: int, packet: BaseSendPacket):
	var chat_payload = packet.buffer
	WebsocketClient.send_packet(cmd_id, chat_payload)
