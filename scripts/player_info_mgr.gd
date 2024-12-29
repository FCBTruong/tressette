extends Node

var my_user_data = UserData.new(0, '')
func get_user_id():
	return 0
	
func set_my_userdata(user_data: UserData):
	my_user_data = user_data

func on_receive_info(packet: BaseReceivePacket):
	my_user_data.uid = packet.get_int32()
	my_user_data.name = packet.get_string()
	my_user_data.gold = packet.get_int64()
	
	print('on_receive_userinfo', my_user_data.uid, my_user_data.gold)
