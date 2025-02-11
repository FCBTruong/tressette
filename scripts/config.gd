extends Node

@export var SERVER_IP: String = "127.0.0.1"
@export var SERVER_PORT: String = "8000"

enum MODES { LOCAL, PRIVATE, LIVE }

@export var CURRENT_MODE: int = MODES.LOCAL

var WEBSOCKET_URL: String

func _ready():
	if CURRENT_MODE == MODES.LOCAL:
		if OS.get_name() == "Android":
			CURRENT_MODE = MODES.PRIVATE		
		elif  OS.get_name() == "iOS":
			CURRENT_MODE = MODES.PRIVATE
	if CURRENT_MODE == MODES.PRIVATE:
			WEBSOCKET_URL = "ws://game-dev-bl-1488570784.ap-southeast-1.elb.amazonaws.com/ws"
	elif CURRENT_MODE == MODES.LOCAL:
		WEBSOCKET_URL = "ws://%s:%s/ws" % [SERVER_IP, SERVER_PORT]
	else:
		WEBSOCKET_URL = ""

	print("WebSocket URL: %s" % WEBSOCKET_URL)

var platform = OS.get_name()
enum PLATFORMS {
	ANDROID,
	IOS,
	MAC_OS,
	WINDOWS,
	UNKNOWN
}
func get_platform():
	return PLATFORMS.IOS
	if platform == "Android":
		return PLATFORMS.ANDROID
	elif platform == 'iOS':
		return PLATFORMS.IOS
	elif platform == "MacOS":
		return PLATFORMS.MAC_OS
	elif  platform == "Windows":
		return PLATFORMS.WINDOWS
	return PLATFORMS.UNKNOWN
