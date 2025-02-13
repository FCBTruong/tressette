extends Node

@export var _token:String = 'default' # note, protobuf string can not be empty, otherwise will error not sent

@export var timestamp_server_delta = 0
@export var enable_sound = true
@export var enable_music = false
@export var enable_chat_ingame = true
var card_style: int = 0 # classic, default, 1 is modern
var table_list = []
var min_gold_play = 0
var supported_langues = ['en', 'it']
var language = 'en'
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var lang = 'en'
	var choosed_lang = StorageCache.fetch('choose_language', 'null')
	if choosed_lang == 'null':
		# try to use device language
		var current_locale = OS.get_locale()
		lang = current_locale.split("_")[0]
		print("device language", lang)
		
	if Config.CURRENT_MODE == Config.MODES.LOCAL:
		lang = 'it'
		
	if lang not in supported_langues:
		lang = 'en'
		
	self.language = lang
	TranslationServer.set_locale(lang)
	card_style = int(StorageCache.fetch('card_style', '0'))
	enable_sound = StorageCache.fetch('enable_sound', '1') == '1'
	enable_music = StorageCache.fetch('enable_music', '1') == '1'
	pass # Replace with function body.

func choose_language(lang):
	if lang not in supported_langues:
		print('language not supported')
		return 
		
	self.language = lang
	StorageCache.store('choose_language', self.language)
	TranslationServer.set_locale(lang)

	
func set_enable_music(e):
	StorageCache.store('enable_music', '1' if e else '0')
	enable_music = e
	
func set_enable_sound(e):
	StorageCache.store('enable_sound', '1' if e else '0')
	enable_sound = e
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func login_success(uid: int, token: String):
	_token = token
	PaymentMgr.on_user_login()
	SceneManager.switch_scene(SceneManager.LOADING_SCENE)
	
func get_token() -> String:
	return _token
	
func send_quick_play() -> void:
	if PlayerInfoMgr.my_user_data.gold < self.min_gold_play:
		SceneManager.show_dialog(
		tr('NOT_ENOUGH_GOLD_PLAY_BUY')
		,
		func ():
			SceneManager.switch_scene(SceneManager.SHOP_SCENE)
		)
		return
	SceneManager.add_loading(5)
	GameClient.send_packet(GameConstants.CMDs.QUICK_PLAY, [])
	
func on_game_start() -> void:
	SceneManager.switch_scene("res://scenes/BoardScene.tscn")
	
func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		GameConstants.CMDs.GENERAL_INFO:
			var pkg = GameConstants.PROTOBUF.PACKETS.GeneralInfo.new()
			var result_code = pkg.from_bytes(payload)
			self.min_gold_play = pkg.get_min_gold_play()
			var timestamp_server = pkg.get_timestamp()
			var delta = timestamp_server - Time.get_unix_time_from_system()
			print('delta timestamp server-client', delta)
			GameManager.set_timestamp_server_delta(delta)
		GameConstants.CMDs.TABLE_LIST:
			var pkg = GameConstants.PROTOBUF.PACKETS.TableList.new()
			var result_code = pkg.from_bytes(payload)
			var table_ids = pkg.get_table_ids()
			var bets = pkg.get_bets()
			table_list = []
			
			for i in range(len(table_ids)):
				var table = TableInfo.new()
				table.match_id = table_ids[i]
				table_list.append(table)
			print('emit signalllll', len(table_list))
			SignalBus.emit_signal_global("update_table_list")

		_:
			GameConstants.game_logic.on_receive(cmd_id, payload)
	
func send_register_leave_game():
	var pkg = GameConstants.PROTOBUF.PACKETS.RegisterLeaveGame.new()
	pkg.set_status(0)
	GameClient.send_packet(GameConstants.CMDs.REGISTER_LEAVE_GAME, pkg.to_bytes())

func send_deregister_leave_game():
	var pkg = GameConstants.PROTOBUF.PACKETS.RegisterLeaveGame.new()
	pkg.set_status(1)
	GameClient.send_packet(GameConstants.CMDs.REGISTER_LEAVE_GAME, pkg.to_bytes())
		
# SECONDS
func get_timestamp_server():
	return Time.get_unix_time_from_system() + timestamp_server_delta

func get_timestamp_client():
	return Time.get_unix_time_from_system()
		
func set_timestamp_server_delta(del):
	timestamp_server_delta = del # milliseconds
	
func logout():
	_token = "default"
	var last_login_type = StorageCache.fetch('last_login_type')
	if last_login_type == GameConstants.LOGIN_TYPE.FIREBASE:
		FirebaseMgr.sign_out()
	StorageCache.store('last_login_type', GameConstants.LOGIN_TYPE.NONE)
	SceneManager.switch_scene(SceneManager.LOGIN_SCENE)
	
func is_logged_in():
	if _token and _token != 'default':
		return true
	return false
func send_get_table_list():
	GameClient.send_packet(GameConstants.CMDs.TABLE_LIST, [])
	
func change_card_style(p_card_style):
	card_style = p_card_style
	StorageCache.store('card_style', card_style)
	
	# dispatch event for all cards to update texture
	SignalBus.emit_signal_global("update_card_style")
