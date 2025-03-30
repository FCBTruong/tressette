# UserData.gd
class_name PackInfo
extends Resource  # Use RefCounted for lightweight, reference-managed objects

@export var pack_id: String
var gold: int
var no_ads_days: int

func _init() -> void:
	pass
	
func print_info():
	pass
