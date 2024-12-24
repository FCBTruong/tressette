# UserData.gd
class_name UserData
extends Resource  # Use RefCounted for lightweight, reference-managed objects

@export var uid: String = '100'
@export var name: String = "Unnamed"
@export var gold: int = 0

func _init(uid: String, name: String) -> void:
	self.uid = uid
	self.name = name
	
func print_info():
	pass
