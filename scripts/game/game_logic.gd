class_name GameLogic
extends RefCounted

var list_players = [
	{
		'uid': '1',
		'name': 'Alex Nguyen'
	},
	{
		'uid': '2',
		'name': 'An Alice'
	},
	{
		'uid': '3',
		'name': 'Sir Abe'
	},
		{
		'uid': '4',
		'name': 'Truong Huy'
	}
]

func get_list_player() -> Array:
	var player_objects: Array = []
	for player in list_players:
		player_objects.append(UserData.new(player['uid'], player['name']))
	return player_objects
	
var game_mode = GameConstants.GAME_MODE.TRESSETTE
