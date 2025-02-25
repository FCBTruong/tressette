extends Node

var my_user_data = UserData.new(0, '')
var support_num = 0
var startup_gold = 0
func get_user_id():
	return my_user_data.uid
	
func set_my_userdata(user_data: UserData):
	my_user_data = user_data

func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		GameConstants.CMDs.USER_INFO:
			_on_receive_info(payload)
		GameConstants.CMDs.UPDATE_MONEY:
			_on_update_money(payload)
			
func _on_receive_info(bytes: PackedByteArray):
	var packet = GameConstants.PROTOBUF.PACKETS.UserInfo.new()
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
	
	print('on_receive_userinfo', my_user_data.uid, ' ', my_user_data.win_count)


func _on_update_money(bytes: PackedByteArray):
	var packet = GameConstants.PROTOBUF.PACKETS.UpdateMoney.new()
	packet.from_bytes(bytes)
	my_user_data.gold = packet.get_gold()
	print('_on_update_money', my_user_data.gold)
	SignalBus.emit_signal_global('on_update_money')
	
func on_update_avatar(avatar: String):
	my_user_data.avatar = avatar
	SignalBus.emit_signal_global('on_changed_avatar')
	
	
