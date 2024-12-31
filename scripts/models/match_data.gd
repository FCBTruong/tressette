# UserData.gd
class_name MatchData

enum MATCH_STATE {
	WAITING = 0,
	PLAYING = 1,
	ENDING = 2,
	ENDED = 3
}
@export var match_id: int = 0
@export var state: int = MATCH_STATE.WAITING
@export var users: Array[UserData] = []
@export var game_mode: int = GameConstants.GAME_MODE.TRESSETTE
@export var player_mode:int = GameConstants.PLAYER_MODE.SOLO
	
func print_info():
	pass
