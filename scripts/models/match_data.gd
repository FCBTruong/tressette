# UserData.gd
class_name MatchData

enum MATCH_STATE {
	WAITING = 0,
	PREPARING_START = 1,
	PLAYING = 2,
	ENDING = 3,
	ENDED = 4
}
@export var match_id: int = 0
@export var state: int = MATCH_STATE.WAITING
@export var users: Array[UserData] = []
@export var game_mode: int = GameConstants.GAME_MODE.TRESSETTE
@export var player_mode:int = GameConstants.PLAYER_MODE.SOLO
@export var seat_delta: int = 0
@export var cards_compare = []
@export var current_turn: int = 0
@export var remain_cards: int = 0
@export var bet: int = 0
@export var pot_value: int = 0
	
func print_info():
	pass


class MatchResult:
	var is_win: bool = false
	var win_team_id: int
	var my_team_id: int
	var gold_change: int
	var players: Array[MatchResultPlayer] = [
		
	]

class MatchResultPlayer:
	var uid
	var team_id
	var avatar
	var score_card = 1
	var score_last_trick = 0
	var score_total = 0
