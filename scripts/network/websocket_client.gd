extends Node

# Our WebSocketPeer instance
var socket: WebSocketPeer = WebSocketPeer.new()
# Timer to track the time since the last ping
var ping_timeout: float = 30.0  # Timeout duration in seconds
var time_since_last_ping: float = 0.0  # Tracks time since last ping
var last_ping_time: float = 0.0  # The time when the last ping was received

var is_connected = false
func _ready():
	connect_to_server()
	
func connect_to_server():
	is_connected = false
	
	var websocket_url = Config.WEBSOCKET_URL
	# Initiate connection to the given URL
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect: ", err)
		set_process(false)  # Stop processing if connection fails
		SceneManager.show_dialog(
			'Can not connect to server, try again.',
			func ():
				self.connect_to_server()
		)
	else:
		print("Connecting to WebSocket server at %s..." % websocket_url)
		set_process(true)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected:
			is_connected = true
			# switch to LoginScene	
			SceneManager.switch_scene(SceneManager.LOGIN_SCENE)
			
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			receive_packet(packet)
			
	 	# Track time since the last ping message
		time_since_last_ping += _delta
		# If no ping was received within the timeout period, disconnect
		if time_since_last_ping >= ping_timeout:
			print("Error: No ping received for %s seconds. Disconnecting." % ping_timeout)
			set_process(false)
			_disconnect()

	elif state == WebSocketPeer.STATE_CLOSING:
		print("WebSocket is closing...")

	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)
		_disconnect()

	elif state == WebSocketPeer.STATE_CONNECTING:
		pass
		
func _disconnect():
	print("Disconnected from server.")
	# show popup
	SceneManager.show_dialog(
		'You are disconnected, try to reconnect!',
		func ():
			SceneManager.switch_scene(SceneManager.LOGIN_SCENE)
			connect_to_server()
	)
	# Perform any cleanup operations if necessary

func send_packet(cmd_id: int, payload: PackedByteArray):
	# Send a packet to the WebSocket server
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var packet = GameConstants.PROTOBUF.PACKETS.Packet.new()
		packet.set_cmd_id(cmd_id)
		packet.set_token(GameManager.get_token())
		packet.set_payload(payload)
		var serialized_packet = packet.to_bytes()
		socket.put_packet(serialized_packet)
	else:
		print("Cannot send packet. WebSocket is not open.")

func receive_packet(data: PackedByteArray):
	var received_packet = GameConstants.PROTOBUF.PACKETS.Packet.new()
	var result_code = received_packet.from_bytes(data)
	
	if result_code == GameConstants.PROTOBUF.PACKETS.PB_ERR.NO_ERRORS:
		pass
	else:
		print('error package parse')
		return
	var cmd_id = received_packet.get_cmd_id()

	if cmd_id == GameConstants.CMDs.PING_PONG:
		var pkg = GameConstants.PROTOBUF.PACKETS.PingPong.new()
		send_packet(GameConstants.CMDs.PING_PONG, pkg.to_bytes())
		time_since_last_ping = 0.0
	else:
		print('receive cmd_id: ', cmd_id)
		var payload = received_packet.get_payload()
		GameClient.on_receive_packet(cmd_id, payload)
