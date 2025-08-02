# UserData.gd
class_name UserData
extends Resource  # Use RefCounted for lightweight, reference-managed objects

@export var uid: int = 100
@export var name: String = "Unnamed"
@export var gold: int = 0
@export var game_data: UserGameData = UserGameData.new()
@export var avatar: String
@export var avatar_third_party: String = ''
@export var win_count: int
@export var game_count: int
@export var exp: int
@export var is_vip: bool
@export var is_verified: bool
@export var avatar_frame: int = g.v.game_constants.AVATAR_FRAME_IDS.DEFAULT

func _init(uid: int, name: String) -> void:
	self.uid = uid
	self.name = name
	
func print_info():
	pass
