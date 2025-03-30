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
	
	if g.v.config.get_platform() == g.v.config.PLATFORMS.WEB:
		has_first_buy = false
	
	print('on_receive_userinfo', my_user_data.uid, ' ', my_user_data.win_count)


func _on_update_money(bytes: PackedByteArray):
	var packet = g.v.game_constants.PROTOBUF.PACKETS.UpdateMoney.new()
	packet.from_bytes(bytes)
	my_user_data.gold = packet.get_gold()
	print('_on_update_money', my_user_data.gold)
	g.v.signal_bus.emit_signal_global('on_update_money')
	
func on_update_avatar(avatar: String):
	my_user_data.avatar = avatar
	g.v.signal_bus.emit_signal_global('on_changed_avatar')
	
func receive_update_ads(bytes: PackedByteArray):
	var packet = g.v.game_constants.PROTOBUF.PACKETS.UpdateAds.new()
	packet.from_bytes(bytes)
	self.time_show_ads = packet.get_time_show_ads()
	g.admob_mgr._on_banner_close()
	g.v.signal_bus.emit_signal_global('on_update_ads')
	
	
