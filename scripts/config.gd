extends Node

@export var SERVER_IP: String = "127.0.0.1"
@export var SERVER_PORT: String = "8000"

enum MODES { LOCAL, PRIVATE, LIVE }

@export var CURRENT_MODE: int = MODES.PRIVATE

var WEBSOCKET_URL: String

func _ready():
	if CURRENT_MODE == MODES.PRIVATE:
			WEBSOCKET_URL = "ws://game-dev-bl-1488570784.ap-southeast-1.elb.amazonaws.com/ws"
	elif CURRENT_MODE == MODES.LOCAL:
		WEBSOCKET_URL = "ws://%s:%s/ws" % [SERVER_IP, SERVER_PORT]
	else:
		WEBSOCKET_URL = ""

	print("WebSocket URL: %s" % WEBSOCKET_URL)
