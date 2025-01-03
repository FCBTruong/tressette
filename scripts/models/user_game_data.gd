# UserData.gd
class_name UserGameData
extends Resource  # Use RefCounted for lightweight, reference-managed objects

var seat_id :int = 0
var cards = []
var points: int = 0


func _init() -> void:
	pass
	
func print_info():
	pass
