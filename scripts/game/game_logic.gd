class_name GameLogic
extends RefCounted

var game_mode: int = GameConstants.GAME_MODE.TRESSETTE
@export var player_mode: int = GameConstants.PLAYER_MODE.TEAM

var list_players = [
	{
		'uid': 1,
		'name': 'Alex Nguyen',
		'seat_id': 0
	},
	{
		'uid': 2,
		'name': 'An Alice',
		'seat_id': 1
	},
	{
		'uid': 3,
		'name': 'Sir Abe',
		'seat_id': 2
	},
		{
		'uid': 4,
		'name': 'Truong Huy',
		'seat_id': 3
	}
]

func get_list_player() -> Array[UserData]:
	var player_objects: Array[UserData] = []
	var i = 0
	for player in list_players:
		if i >= player_mode:
			continue
		var user = UserData.new(player['uid'], player['name'])
		user.game_data.seat_id = player['seat_id']
		player_objects.append(user)
		i += 1
	return player_objects
	
