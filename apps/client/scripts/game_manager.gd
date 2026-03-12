extends Node
class_name GameManager

var _token:String = 'default' # note, protobuf string can not be empty, otherwise will error not sent

var timestamp_server_delta = 0
var enable_sound = true
var enable_music = false
var enable_chat = true
var enable_chat_ingame = true
var card_style: int = 0 # classic, default, 1 is modern
var table_list = []
var supported_langues = ['en', 'it']
var language = 'en'
var LAST_GAME_IS_WIN = false
var did_show_guide_new_user = false
var type_delete_login
var CURRENT_GAME_PLAY = 0 # tressette, 1 is sette mezzo
var game_th = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("GameManagerReady")
	var lang = 'en'
	var choosed_lang = g.v.storage_cache.fetch('choose_language', 'null')
	if choosed_lang == 'null':
		# try to use device language
		var current_locale = OS.get_locale()
		lang = current_locale.split("_")[0]
		print("device language", lang)
	else:
		lang = choosed_lang
	
	lang = lang.to_lower()
	if g.v.config.CURRENT_MODE == g.v.config.MODES.LOCAL:
		lang = 'it'
		
	if lang not in supported_langues:
		lang = 'en'
		
	self.language = lang
	TranslationServer.set_locale(lang)
	card_style = int(g.v.storage_cache.fetch('card_style', '0'))
	enable_sound = g.v.storage_cache.fetch('enable_sound', '1') == '1'
	enable_music = g.v.storage_cache.fetch('enable_music', '1') == '1'
	enable_chat = g.v.storage_cache.fetch('enable_chat', '1') == '1'


func choose_language(lang):
	if lang not in supported_langues:
		print('language not supported')
		return 
		
	self.language = lang
	g.v.storage_cache.store('choose_language', self.language)
	TranslationServer.set_locale(lang)

	
func set_enable_music(e):
	g.v.storage_cache.store('enable_music', '1' if e else '0')
	enable_music = e
	if not enable_music:
		g.v.sound_manager.stop_music()
	else:
		var scene = g.v.scene_manager.get_current_scene()
		if scene is not BoardScene:
			g.v.sound_manager.play_music_lobby()
		else:
			g.v.sound_manager.play_music_board()
	
func set_enable_sound(e):
	g.v.storage_cache.store('enable_sound', '1' if e else '0')
	enable_sound = e
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func login_success(uid: int, token: String):
	_token = token
	g.v.payment_mgr.on_user_login()
	g.v.scene_manager.switch_scene(g.v.scene_manager.LOADING_SCENE)
	
func get_token() -> String:
	return _token
	
func send_quick_play() -> void:
	g.v.scene_manager.add_loading(5)
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.QuickPlay.new()
	g.v.game_client.send_packet(g.v.game_constants.CMDs.QUICK_PLAY, pkg.to_bytes())
	

func on_game_start() -> void:
	g.v.scene_manager.switch_scene("res://scenes/BoardScene.tscn")
	
func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		g.v.game_constants.CMDs.GENERAL_INFO:
			var pkg = g.v.game_constants.PROTOBUF.PACKETS.GeneralInfo.new()
			var result_code = pkg.from_bytes(payload)
			var timestamp_server = pkg.get_timestamp()
			var delta = timestamp_server - Time.get_unix_time_from_system()
			print('delta timestamp server-client', delta)
			g.v.game_manager.set_timestamp_server_delta(delta)
			g.v.game_server_config.time_thinking_in_turn = pkg.get_time_thinking_in_turn() - 0.5 # client must play before that time
			g.v.game_server_config.exp_levels = pkg.get_exp_levels()
			g.v.game_server_config.fee_mode_no_bet = pkg.get_fee_mode_no_bet()
			
			var level_rewards_pkg = pkg.get_level_rewards()
			g.v.game_server_config.level_rewards = []
			for l in level_rewards_pkg:
				
				var obj = {}
				g.v.game_server_config.level_rewards.append(obj)
				obj["level"] = l.get_level()
				obj["gold"] = l.get_gold()
				obj["items"] = []
				var b = l.get_items()
				for bi in b:
					var t = bi
					var m = {
						"item_id": t.get_item_id(),
						"duration": t.get_duration()
					}
					obj["items"].append(m)
				
			
				
		g.v.game_constants.CMDs.TABLE_LIST:
			var pkg = g.v.game_constants.PROTOBUF.PACKETS.TableList.new()
			var result_code = pkg.from_bytes(payload)
			var table_ids = pkg.get_table_ids()
			var num_players = pkg.get_num_players()
			var player_modes = pkg.get_player_modes()
			var game_modes = pkg.get_game_modes()
			var avatars = pkg.get_avatars()
			var uids = pkg.get_player_uids()
			var avatar_frames = pkg.get_avatar_frames()
			var is_privates = pkg.get_is_private()
			var player_points = pkg.get_points()
			table_list = []
			
			var j = 0
			for i in range(len(table_ids)):
				var table = TableInfo.new()
				table.match_id = table_ids[i]
				table.num_player = num_players[i]
				table.player_mode = player_modes[i]
				table.player_avatars = []
				table.player_uids = []
				table.avatar_frames = []
				table.game_mode = game_modes[i]
				table.is_private = is_privates[i]
				table.player_points = []
				table_list.append(table)
				
				for x in range(table.player_mode):
					if j >= len(uids):
						break
					table.player_uids.append(uids[j])
					table.player_avatars.append(avatars[j])
					table.avatar_frames.append(avatar_frames[j])
					table.player_points.append(player_points[i])
					j += 1
					
				
			g.v.signal_bus.emit_signal_global("update_table_list")
		g.v.game_constants.CMDs.JOIN_TABLE_BY_ID:
			var pkg = g.v.game_constants.PROTOBUF.PACKETS.JoinTableResponse.new()
			var result_code = pkg.from_bytes(payload)
			var error_join = pkg.get_error()
			if error_join != 0:
				var str_err_join = tr('ERROR_JOIN_TABLE_' + str(error_join))
				g.v.scene_manager.show_ok_dialog(str_err_join)
		g.v.game_constants.CMDs.CLAM_SUPPORT:
			_received_claim_support(payload)
		g.v.game_constants.CMDs.DELETE_ACCOUNT:
			_received_delete_account()
			
		g.v.game_constants.CMDs.INVITE_FRIEND_PLAY:
			receive_play_invite(payload)
		g.v.game_constants.CMDs.CLAIM_ADS_REWARD:
			receive_ads_reward(payload)
		g.v.game_constants.CMDs.CLAIM_REWARD_LEVEL:
			receive_reward_level(payload)
		_:
			g.v.game_constants.game_logic.on_receive(cmd_id, payload)
	
func send_register_leave_game():
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.RegisterLeaveGame.new()
	pkg.set_status(0)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.REGISTER_LEAVE_GAME, pkg.to_bytes())

func send_deregister_leave_game():
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.RegisterLeaveGame.new()
	pkg.set_status(1)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.REGISTER_LEAVE_GAME, pkg.to_bytes())
		
# SECONDS
func get_timestamp_server():
	return Time.get_unix_time_from_system() + timestamp_server_delta

func get_timestamp_client():
	return Time.get_unix_time_from_system()
		
func set_timestamp_server_delta(del):
	timestamp_server_delta = del # milliseconds
	
func logout():
	_token = "default"
	var last_login_type = g.v.storage_cache.fetch('last_login_type')
	if last_login_type == g.v.game_constants.LOGIN_TYPE.FIREBASE:
		g.v.firebase_mgr.sign_out()
	g.v.storage_cache.store('last_login_type', g.v.game_constants.LOGIN_TYPE.NONE)
	g.v.scene_manager.switch_scene(g.v.scene_manager.LOGIN_SCENE)
	
func is_logged_in():
	if _token and _token != 'default':
		return true
	return false
func send_get_table_list():
	g.v.game_client.send_packet(g.v.game_constants.CMDs.TABLE_LIST, [])
	
func change_card_style(p_card_style):
	card_style = p_card_style
	g.v.storage_cache.store('card_style', card_style)
	
	# dispatch event for all cards to update texture
	g.v.signal_bus.emit_signal_global("update_card_style")
	
func show_not_gold_recommend_shop():
	g.v.scene_manager.show_dialog(
		tr('NOT_ENOUGH_GOLD_PLAY_BUY')
		,
		func ():
			g.v.scene_manager.switch_scene(g.v.scene_manager.SHOP_SCENE),
		func ():
			pass,
		true
		)

func show_not_gold():
	g.v.scene_manager.show_ok_dialog(
		tr('NOT_ENOUGH_GOLD')
		,
		func ():
			pass,
		true
	)

func send_claim_support():
	print('send claim support')
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CLAM_SUPPORT, [])
	
func _received_claim_support(payload):
	print('received claim support')
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.ClaimSupport.new()
	var result_code = pkg.from_bytes(payload)
	var gold = pkg.get_support_amount()
	var txt = tr("DAILY_SUPPORT")
	txt = txt.replace("@num", StringUtils.point_number(gold))
	g.v.scene_manager.show_dialog(txt,
		func():
			print('click ok'),
		func():
			print('click close')
	)

func join_game_by_id(id):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.JoinTableById.new()
	pkg.set_match_id(id)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.JOIN_TABLE_BY_ID, pkg.to_bytes())

func view_game_by_id(id):
	print("view gamemmmm", id)
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.ViewGame.new()
	pkg.set_match_id(id)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.VIEW_GAME, pkg.to_bytes())

func send_invite_friend_play(uid):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.InviteFriendPlay.new()
	pkg.set_uid(uid)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.INVITE_FRIEND_PLAY, pkg.to_bytes())


func receive_play_invite(payload):
	print("receive play invite")
	
	var cur_scene = g.v.scene_manager.get_current_scene()
	if cur_scene is BoardScene:
		return
		
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.InviteFriendPlay.new()
	var result_code = pkg.from_bytes(payload)
	var uid = pkg.get_uid()
	var room_id = pkg.get_room_id()
	var str = tr('INVITE_PLAY')
	str = str.replace("@name", str(uid))
	g.v.scene_manager.show_dialog(
		str,
		func():
			join_game_by_id(room_id)
	)
	
	
func get_country():
	pass
	#var http_request = HTTPRequest.new()
	#add_child(http_request)
	#http_request.request_completed.connect(_on_request_completed)
	#http_request.request(g.v.game_constants.GEO_API_URL)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			var country_code = data.get("country_code", "Unknown")
			print("User is from:", country_code)

func request_delete_account():
	type_delete_login = g.v.storage_cache.fetch('last_login_type', g.v.game_constants.LOGIN_TYPE.NONE)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.DELETE_ACCOUNT, [])

func _received_delete_account():
	if type_delete_login == g.v.game_constants.LOGIN_TYPE.GUEST:
		g.v.login_mgr.save_guest_id('')

func is_enable_ads() -> bool:
	if g.v.config.get_platform() != g.v.config.PLATFORMS.ANDROID and g.v.config.get_platform() != g.v.config.PLATFORMS.IOS:
		return false
	if g.v.player_info_mgr.time_show_ads > self.get_timestamp_server():
		return false
	return true

func open_guide_gui():
	return g.v.scene_manager.open_gui("res://scenes/guis/GuideGUI.tscn", true)

var did_show_fanpage = false
var did_show_fb_group = false
func check_show_fanpage():
	if did_show_fanpage:
		return
	if g.v.player_info_mgr.my_user_data.game_count < 2:
		return
	did_show_fanpage = true
	var n = g.v.storage_cache.fetch("show_fanpage", 0)
	
	print('debugxdds', n)
	if n >= g.v.game_constants.MAX_SHOW_FANPAGE_LIKE:
		return
	
	g.v.popup_mgr.add_popup("res://scenes/lobby/LikeFanpageGUI.tscn")

func check_show_group_fb():
	if did_show_fb_group:
		return
	if g.v.player_info_mgr.my_user_data.game_count < 4:
		return
	did_show_fb_group = true
	var n = g.v.storage_cache.fetch("join_group_fb", 0)
	

	if n >= g.v.game_constants.MAX_SHOW_JOIN_GROUP_FB:
		return
	
	g.v.popup_mgr.add_popup("res://scenes/lobby/JoinFbGroupGUI.tscn")

func set_enable_chat(e):
	g.v.storage_cache.store('enable_chat', '1' if e else '0')
	enable_chat = e


func user_ready_match():
	# must send this pack to let server know
	g.v.game_client.send_packet(g.v.game_constants.CMDs.USER_READY_MATCH, [])

func receive_ads_reward(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.AdsReward.new()
	var result_code = pkg.from_bytes(payload)
	var gold = pkg.get_gold()
	g.v.player_info_mgr.time_ads_reward = pkg.get_time_ads_reward()
	var str = tr("CLAIM_REWARD_SUCCESS")
	
	var rewards:Array[Reward] = [
		Reward.new(g.v.game_constants.CRYPSTAL_ITEM_ID, gold)
	]
	g.v.popup_mgr.add_popup(
		"res://scenes/lobby/ReceiveGiftGUI.tscn",
		"set_info",
		[tr("YOU_RECEIVED"), rewards],
		false
	)
	var scene = g.v.scene_manager.get_current_scene()
	if scene is LobbyScene:
		scene.update_ads_reward_info()

func receive_reward_level(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.ClaimRewardLevelResponse.new()
	var result_code = pkg.from_bytes(payload)
	var rewards: Array[Reward] = []
	var gold = pkg.get_gold()
	if gold > 0:
		rewards.append(
			Reward.new(g.v.game_constants.CRYPSTAL_ITEM_ID, gold)
		)
		
	var items = pkg.get_items()
	for item in items:
		var item_id = item.get_item_id()
		var duration = item.get_duration()
		rewards.append(
			Reward.new(
				item_id,
				1,
				duration
			)
		)
	var g = g.v.scene_manager.open_gui(
					"res://scenes/lobby/ReceiveGiftGUI.tscn")
	g.set_info(tr("YOU_RECEIVED"), rewards)
	
func check_has_reward_level() -> bool:
	for l in g.v.game_server_config.level_rewards:
		var level = l['level']
		if level > g.v.player_info_mgr.get_my_level():
			break
		if level not in g.v.player_info_mgr.claimed_levels:
			return true
			
	return false
