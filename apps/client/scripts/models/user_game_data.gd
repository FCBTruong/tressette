# UserData.gd
class_name UserGameData
extends Resource  # Use RefCounted for lightweight, reference-managed objects

var seat_id :int = 0
var cards = []
var points: int = 0
var team_id: int = 0
var is_in_game: bool = false
var sette_bet: int = 0
var seat_server_id: int = 0


func _init() -> void:
	pass
	
func print_info():
	pass
