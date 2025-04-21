extends RefCounted
class_name Config

@export var SERVER_IP: String = "127.0.0.1"
@export var SERVER_PORT: String = "8000"

enum MODES { LOCAL, PRIVATE, LIVE }

@export var CURRENT_MODE: int = MODES.LOCAL
@export var SHOW_CARD_BOT: bool = true
var WEBSOCKET_URL: String
var EDIT_MODE = false

func on_ready():
	if CURRENT_MODE == MODES.LOCAL:
		if OS.get_name() == "Android":
			CURRENT_MODE = MODES.LIVE		
		elif OS.get_name() == "iOS":
			CURRENT_MODE = MODES.PRIVATE
		elif OS.get_name() == "Web":
			CURRENT_MODE = MODES.LIVE
			pass

	if CURRENT_MODE == MODES.PRIVATE:	
		WEBSOCKET_URL = "wss://tressette-dev.clareentertainment.com/ws"
	elif CURRENT_MODE == MODES.LOCAL:
		WEBSOCKET_URL = "ws://%s:%s/ws" % [SERVER_IP, SERVER_PORT]
	else:
		WEBSOCKET_URL = "wss://tressette-dev.clareentertainment.com/ws"

	print("WebSocket xxxxxURL: %s" % WEBSOCKET_URL)

var platform = OS.get_name()
enum PLATFORMS {
	ANDROID,
	IOS,
	WEB,
	MAC_OS,
	WINDOWS,
	UNKNOWN
}
func get_platform():
	#if g.v.config.CURRENT_MODE == g.v.config.MODES.LOCAL:
		#return PLATFORMS.WEB
	if platform == "Android":
		return PLATFORMS.ANDROID
	elif platform == 'iOS':
		return PLATFORMS.IOS
	elif platform == "macOS":
		return PLATFORMS.MAC_OS
	elif platform == "Windows":
		return PLATFORMS.WINDOWS
	elif platform == "Web":
		return PLATFORMS.WEB
	return PLATFORMS.UNKNOWN
