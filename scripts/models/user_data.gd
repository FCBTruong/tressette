# UserData.gd
class_name UserData
extends Resource  # Use RefCounted for lightweight, reference-managed objects

@export var uid: int = 100
@export var name: String = "Unnamed"
@export var gold: int = 0
@export var game_data: UserGameData = UserGameData.new()

func _init(uid: int, name: String) -> void:
	self.uid = uid
	self.name = name
	
func print_info():
	pass
