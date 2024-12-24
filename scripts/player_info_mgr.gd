extends RefCounted

var my_user_data = UserData.new('', '')
func get_user_id():
	return 0
	
func set_my_userdata(user_data: UserData):
	my_user_data = user_data
