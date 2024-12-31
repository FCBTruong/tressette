class_name GameLogic
extends RefCounted

var match_data: MatchData = null

func get_list_player() -> Array[UserData]:
	return match_data.users
	
func on_update_matchdata(p_match_data: MatchData):
	match_data = p_match_data
	print('Match data', len(match_data.users))

func on_user_leave_game():
	pass
