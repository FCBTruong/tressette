extends Node

var my_user_data = UserData.new(0, '')
func get_user_id():
	return 0
	
func set_my_userdata(user_data: UserData):
	my_user_data = user_data

func on_receive_info(bytes: PackedByteArray):
	var packet = GameConstants.PROTOBUF.PACKETS.UserInfo.new()
	packet.from_bytes(bytes)
	my_user_data.uid = packet.get_uid()
	my_user_data.name = packet.get_name()
	my_user_data.gold = packet.get_gold()
	var scores = packet.get_scores()
	var names = packet.get_names()
	var ac = packet.get_abc()
	print(scores, names, ac)
	
	print('on_receive_userinfo', my_user_data.uid, my_user_data.gold)
