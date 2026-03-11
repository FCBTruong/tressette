extends Node
class_name WebsocketClient

var socket := WebSocketPeer.new()
var is_connected := false

# Store received packets before handling
var pending_packets: Array = []

func _ready():
	if g.v.config.CURRENT_MODE == g.v.config.MODES.LOCAL and g.v.config.EDIT_MODE:
		return

	socket.heartbeat_interval = 5.0
	connect_to_server()

func connect_to_server():
	socket = WebSocketPeer.new()
	is_connected = false
	pending_packets.clear()

	var websocket_url = g.v.config.WEBSOCKET_URL
	var err = socket.connect_to_url(websocket_url)
	print("Connecting to WebSocket server at %s..." % websocket_url)

	if err != OK:
		print("Unable to connect: ", err)
		set_process(false)
		g.v.scene_manager.show_dialog(
			"Can not connect to server, try again.",
			func():
				self.connect_to_server()
		)
	else:
		print("Connected %s..." % websocket_url)
		set_process(true)

func _process(_delta):
	if g.v.config.CURRENT_MODE == g.v.config.MODES.LOCAL and g.v.config.EDIT_MODE:
		return

	socket.poll()
	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected:
			g.v.scene_manager.clear_loading()
			is_connected = true

		_collect_incoming_packets()
		_handle_pending_packets()

	elif state == WebSocketPeer.STATE_CLOSING:
		print("WebSocket is closing...")

	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)
		_disconnect()

func _collect_incoming_packets():
	while socket.get_available_packet_count() > 0:
		var raw_packet = socket.get_packet()
		_push_packet_to_queue(raw_packet)

func _push_packet_to_queue(data: PackedByteArray):
	var received_packet = g.v.game_constants.PROTOBUF.PACKETS.Packet.new()
	var result_code = received_packet.from_bytes(data)

	if result_code != g.v.game_constants.PROTOBUF.PACKETS.PB_ERR.NO_ERRORS:
		print("error package parse")
		return
	print("OKKKKK")

	pending_packets.append({
		"timestamp": received_packet.get_timestamp(),
		"packet_id": received_packet.get_packet_id(),
		"cmd_id": received_packet.get_cmd_id(),
		"payload": received_packet.get_payload()
	})

func _handle_pending_packets():
	if pending_packets.is_empty():
		return

	pending_packets.sort_custom(func(a, b):
		if a.timestamp == b.timestamp:
			return a.packet_id < b.packet_id
		return a.timestamp < b.timestamp
	)

	#var server_ts = get_timestamp_server()

	while not pending_packets.is_empty():
		var packet = pending_packets[0]

		# Stop if this packet is for the future
		#if packet.timestamp > server_ts:
			#break

		packet = pending_packets.pop_front()
		_handle_packet(packet)

func _handle_packet(packet: Dictionary):
	var cmd_id: int = packet.cmd_id
	var payload: PackedByteArray = packet.payload

	if cmd_id == g.v.game_constants.CMDs.PING_PONG:
		var pkg = g.v.game_constants.PROTOBUF.PACKETS.PingPong.new()
		send_packet(g.v.game_constants.CMDs.PING_PONG, pkg.to_bytes())
	elif cmd_id == g.v.game_constants.CMDs.APP_VERSION:
		g.v.app_version.handle_version_and_open_login(payload)
	else:
		print("receive cmd_id: ", cmd_id)
		g.v.game_client.on_receive_packet(cmd_id, payload)

func _disconnect():
	print("Disconnected from server.")
	g.v.scene_manager.show_ok_dialog(
		tr("YOU_ARE_DISCONNECTED"),
		func():
			socket.close()
			g.v.scene_manager.add_loading(2)
			connect_to_server()
	)

func send_packet(cmd_id: int, payload: PackedByteArray):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var packet = g.v.game_constants.PROTOBUF.PACKETS.Packet.new()
		packet.set_cmd_id(cmd_id)
		packet.set_token(g.v.game_manager.get_token())
		packet.set_payload(payload)
		var serialized_packet = packet.to_bytes()
		socket.put_packet(serialized_packet)
	else:
		print("Cannot send packet. WebSocket is not open.")
		_disconnect()

func get_timestamp_server() -> int:
	return Time.get_unix_time_from_system() * 1000
