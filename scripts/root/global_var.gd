extends Node
class_name GlobalVar

var app_version: AppVersion
var storage_cache: StorageCache
var config: Config
var game_constants: GameConstants
var scene_manager: SceneManager
var player_info_mgr: PlayerInfoMgr
var game_manager: GameManager
var signal_bus: SignalBus
var game_client: GameClient
var sound_manager: SoundManager
var game_server_config: GameServerConfig
var native_mgr: NativeMgr
var payment_mgr: PaymentMgr
var firebase_mgr: FirebaseMgr
var ingame_chat_mgr: IngameChatMgr
var friend_mgr: FriendManager
var websocket_client: WebsocketClient
var logs_mgr: LogsMgr
var effect_mgr: EffectMgr
var login_mgr: LoginMgr
var sette_mezzo_mgr: SetteMezzoMgr

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func test_hello():
	print("33")
