extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func on_receive_packet(cmd_id: int, payload: PackedByteArray):
	print('on_receive_packet', cmd_id)

var ChatMessage = preload("res://scripts/network/chat_message.gd")
func send_packet(cmd_id: int):
	var chat_message = ChatMessage.new()
	chat_message.username = 'Truong'
	chat_message.message = 'Hello everyone'
	var chat_payload = chat_message.serialize()
	WebsocketClient.send_packet(cmd_id, chat_payload)
