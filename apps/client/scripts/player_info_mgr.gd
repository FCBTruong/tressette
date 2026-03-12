extends RefCounted
class_name PlayerInfoMgr

var my_user_data = UserData.new(0, '')
var support_num = 0
var startup_gold = 0
var time_show_ads = 0
var has_first_buy: bool = false
var claimed_levels = []
var price_change_name = 0

func _init() -> void:
	pass
	
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
		g.v.game_constants.CMDs.UPDATE_EXP:
			_on_update_exp(payload)
			
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
	var key_gold = GameConstants.STORAGE_KEY_GOLD
	var current_gold = g.v.storage_cache.fetch(
		key_gold,
		0
	)
	my_user_data.gold = current_gold
	my_user_data.name = packet.get_name()
	update_using_frame(packet.get_avatar_frame())
	on_update_avatar(packet.get_avatar())

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

func on_update_avatar_by_id(avatar_id: int):
	var avatar = str(avatar_id)
	if avatar_id == -1:
		avatar = g.v.player_info_mgr.my_user_data.avatar_third_party
	
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

func get_my_level():
	return g.v.game_server_config.convert_exp_to_level(my_user_data.exp)
	
func _on_update_exp(bytes: PackedByteArray):
	var packet = g.v.game_constants.PROTOBUF.PACKETS.UpdateExp.new()
	packet.from_bytes(bytes)
	my_user_data.exp = packet.get_exp()
	g.v.signal_bus.emit_signal_global('on_update_exp')
	
func update_using_frame(item_id):
	self.my_user_data.avatar_frame = item_id
	g.v.signal_bus.emit_signal_global('on_changed_frame')
	

func get_avatar_id_using() -> int:
	if my_user_data.avatar.contains("https://"):
		return -1
	else:
		return int(my_user_data.avatar)
		
func consume_money(money: int):
	my_user_data.gold = max(0, my_user_data.gold - money)
	g.v.signal_bus.emit_signal_global('on_update_money')
	
	var key_gold = GameConstants.STORAGE_KEY_GOLD
	g.v.storage_cache.store(
		key_gold,
		my_user_data.gold
	)

func add_money(money: int):
	my_user_data.gold += money
	g.v.signal_bus.emit_signal_global('on_update_money')
	
	var key_gold = GameConstants.STORAGE_KEY_GOLD
	g.v.storage_cache.store(
		key_gold,
		my_user_data.gold
	)
