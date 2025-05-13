extends RefCounted
class_name PlayerInfoMgr

var my_user_data = UserData.new(0, '')
var support_num = 0
var startup_gold = 0
var time_show_ads = 0
var has_first_buy: bool = false
func get_user_id():
	return my_user_data.uid
	
func set_my_userdata(user_data: UserData):
	my_user_data = user_data

func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		g.v.game_constants.CMDs.USER_INFO:
			_on_receive_info(payload)
		g.v.game_constants.CMDs.UPDATE_MONEY:
			_on_update_money(payload)
			
		g.v.game_constants.CMDs.UPDATE_ADS:
			receive_update_ads(payload)
			
var time_end_offer = 0
var login_type
var enable_ads_reward = false
var time_ads_reward = 0
func _on_receive_info(bytes: PackedByteArray):
	var packet = g.v.game_constants.PROTOBUF.PACKETS.UserInfo.new()
	packet.from_bytes(bytes)
	my_user_data.uid = packet.get_uid()
	my_user_data.name = packet.get_name()
	my_user_data.gold = packet.get_gold()
	my_user_data.avatar = packet.get_avatar()
	my_user_data.win_count = packet.get_win_count()
	my_user_data.game_count = packet.get_game_count()
	my_user_data.exp = packet.get_exp()
	my_user_data.avatar_third_party = packet.get_avatar_third_party()
	support_num = packet.get_support_num()
	startup_gold = packet.get_startup_gold()
	has_first_buy = packet.get_has_first_buy()
	time_show_ads = packet.get_time_show_ads()
	login_type = packet.get_login_type()
	time_ads_reward = packet.get_time_ads_reward()
	#time_ads_reward = g.v.game_manager.get_timestamp_server() + 3000
	#if time_ads_reward == -1:
		#enable_ads_reward = false
	#else:
		#enable_ads_reward = true
	my_user_data.is_verified = login_type != g.v.game_constants.LOGIN_TYPE.GUEST
	
	if g.v.config.get_platform() == g.v.config.PLATFORMS.WEB:
		has_first_buy = false
	
	if has_first_buy:
		# this should check cache of client, because countdown time client manage
		time_end_offer = g.v.storage_cache.fetch("first_buy_offer_time" + str(self.get_user_id()), 0)
		
		if time_end_offer < g.v.game_manager.get_timestamp_client():
			if time_end_offer > g.v.game_manager.get_timestamp_client() - 86400:
				has_first_buy = false
				# due to offer just expired, need to cooldown
			else:
				# regen time end offer
				time_end_offer = g.v.game_manager.get_timestamp_client() + 86400
				# save to cache
				g.v.storage_cache.store("first_buy_offer_time" + str(self.get_user_id()), time_end_offer)
	if has_first_buy and my_user_data.game_count > 0:
		g.v.popup_mgr.add_popup("res://scenes/lobby/FirstBuyGUI.tscn")
	
	if login_type == g.v.game_constants.LOGIN_TYPE.GUEST:
		if my_user_data.game_count > 2:
			var last_time_remind_link = g.v.storage_cache.fetch("link_acc_remind", 0)
			var remind_link_times = g.v.storage_cache.fetch("remind_link_times", 0)
			if remind_link_times < 5 and last_time_remind_link < g.v.game_manager.get_timestamp_client() - 86400:			
				g.v.popup_mgr.add_popup("res://scenes/lobby/LinkAccountGUI.tscn")
				g.v.storage_cache.store("link_acc_remind", g.v.game_manager.get_timestamp_client())
				g.v.storage_cache.store("remind_link_times", remind_link_times + 1)
	print('on_receive_userinfo', my_user_data.uid, ' ', my_user_data.win_count)
	
	if is_linking_acc:
		if login_type != g.v.game_constants.LOGIN_TYPE.GUEST:
			if uid_linking == my_user_data.uid:
				# link successfully
				g.v.scene_manager.show_ok_dialog(tr("LINK_ACCOUNT_SUCCESS"))
			else:
				g.v.scene_manager.show_ok_dialog(tr("CANNOT_LINK_ACCOUNT"))
		is_linking_acc = false
		
	if enable_ads_reward and time_ads_reward < g.v.game_manager.get_timestamp_server():
		# add popup watch ads
		g.v.popup_mgr.add_popup("res://scenes/lobby/WatchAdsGUI.tscn")
		
	# add popup change user name
	if self.my_user_data.game_count > 3 and my_user_data.name == 'tressette player':
		g.v.popup_mgr.add_popup("res://scenes/lobby/ChangeUserNameGUI.tscn")
	
	if self.my_user_data.game_count > 2 and not g.v.app_version.is_in_review():
		var sette_times = g.v.storage_cache.fetch("sette_mezzo_play", 0)
		if sette_times < 3:
			g.v.popup_mgr.add_popup("res://scenes/sette_mezzo/SetteMezzoIntroGUI.tscn")
	
	var should_ask_support = packet.get_add_for_user_support()
	if self.has_first_buy:
		if should_ask_support:
			_handle_ask_for_support()
func _on_update_money(bytes: PackedByteArray):
	var packet = g.v.game_constants.PROTOBUF.PACKETS.UpdateMoney.new()
	packet.from_bytes(bytes)
	my_user_data.gold = packet.get_gold()
	print('_on_update_money', my_user_data.gold)
	g.v.signal_bus.emit_signal_global('on_update_money')

func check_and_show_offer():
	if not self.has_first_buy:
		return
	g.v.popup_mgr.add_popup("res://scenes/lobby/FirstBuyGUI.tscn")
	
func on_update_avatar(avatar: String):
	my_user_data.avatar = avatar
	g.v.signal_bus.emit_signal_global('on_changed_avatar')
	
func receive_update_ads(bytes: PackedByteArray):
	var packet = g.v.game_constants.PROTOBUF.PACKETS.UpdateAds.new()
	packet.from_bytes(bytes)
	self.time_show_ads = packet.get_time_show_ads()
	g.admob_mgr._on_banner_close()
	g.v.signal_bus.emit_signal_global('on_update_ads')
	

func is_user_vip() -> bool:
	return g.v.player_info_mgr.time_show_ads > g.v.game_manager.get_timestamp_server()

var is_linking_acc: bool = false
var uid_linking: int


func _handle_ask_for_support():
	var should_show = g.v.storage_cache.fetch("show_ask_support", '0')
	
	g.v.popup_mgr.add_popup("res://scenes/lobby/AskForSupportGUI.tscn")
	pass
