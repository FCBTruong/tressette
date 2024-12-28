extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func on_receive_packet(cmd_id: int, payload: PackedByteArray):
	print('on_receive_packet', cmd_id)
		

func send_packet(cmd_id: int, packet: BaseSendPacket):
	var chat_payload = packet.buffer
	WebsocketClient.send_packet(cmd_id, chat_payload)
