extends Node

# Our WebSocketPeer instance
var socket: WebSocketPeer = WebSocketPeer.new()
var Packet = preload("res://scripts/network/Packet.gd")

func _ready():
	var websocket_url = "ws://%s:%s/ws" % [Config.SERVER_IP, Config.SERVER_PORT]
	# Initiate connection to the given URL
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect: ", err)
		set_process(false)  # Stop processing if connection fails
	else:
		print("Connecting to WebSocket server at %s..." % websocket_url)
		set_process(true)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			receive_packet(packet)

	elif state == WebSocketPeer.STATE_CLOSING:
		print("WebSocket is closing...")

	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)
		_disconnect()

	elif state == WebSocketPeer.STATE_CONNECTING:
		print("WebSocket is connecting...")

func _disconnect():
	print("Disconnected from server.")
	# Perform any cleanup operations if necessary

func send_packet(cmd_id: int, payload: PackedByteArray):
	print('sending packet: ', cmd_id)
	# Send a packet to the WebSocket server
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var packet = Packet.new()
		packet.cmd_id = cmd_id
		packet.payload = payload
		var serialized_packet = packet.serialize()
		socket.put_packet(serialized_packet)
	else:
		print("Cannot send packet. WebSocket is not open.")

func receive_packet(data: PackedByteArray):
	var received_packet = Packet.new()
	received_packet.parse(data)
	GameClient.on_receive_packet(received_packet.cmd_id, received_packet.payload)
