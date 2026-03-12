# UserData.gd
class_name TableInfo
extends Resource  # Use RefCounted for lightweight, reference-managed objects

var match_id: int
var bet: int
var player_mode:  int
var num_player: int
var player_uids
var player_avatars
var game_mode: int
var avatar_frames
var is_private: bool
var player_points

func _init() -> void:
	pass
	
func print_info():
	pass
