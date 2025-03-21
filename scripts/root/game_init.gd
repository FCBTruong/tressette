extends Node

# RELOADABLE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	g.v = GlobalVar.new()
	self.auto_load_scripts()

func auto_load_scripts():
	print("hellloccxxxxxc 122")
	g.v.test_hello()
	
	g.v.storage_cache = StorageCache.new() 
	g.v.storage_cache.on_ready()

	g.v.config = Config.new()
	g.v.config.on_ready()
	
	g.v.game_constants = GameConstants.new()
	
	g.v.scene_manager = SceneManager.new()
	g.v.scene_manager.on_ready()
	
	g.v.player_info_mgr = PlayerInfoMgr.new()
	
	g.v.native_mgr = NativeMgr.new()
	g.v.native_mgr.on_ready()
	
	g.v.firebase_mgr = FirebaseMgr.new()
	self.add_child(g.v.firebase_mgr)
	
	g.v.ingame_chat_mgr = IngameChatMgr.new()
	
	g.v.websocket_client = WebsocketClient.new()
	self.add_child(g.v.websocket_client)
	
	g.v.logs_mgr = LogsMgr.new()
	
	g.v.effect_mgr = EffectMgr.new()
	self.add_child(g.v.effect_mgr)
	
	g.v.app_version = AppVersion.new()
	
	g.v.game_manager = GameManager.new() # load("res://scripts/game_manager.gd").new()
	self.add_child(g.v.game_manager)
	
	g.v.login_mgr = LoginMgr.new()
	
	g.v.game_client = GameClient.new()
	
	g.v.payment_mgr = PaymentMgr.new()
	self.add_child(g.v.payment_mgr)
	
	g.v.game_server_config = GameServerConfig.new()
	
	g.v.friend_mgr = FriendManager.new()
	
	g.v.signal_bus = SignalBus.new()
	
	g.v.sound_manager = SoundManager.new()
	self.add_child(g.v.sound_manager)
	
	g.v.sette_mezzo_mgr = SetteMezzoMgr.new()
	
	g.v.mission_mgr = MissionMgr.new()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
