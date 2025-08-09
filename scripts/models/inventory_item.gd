# UserData.gd
class_name InventoryItem
extends Resource  # Use RefCounted for lightweight, reference-managed objects

@export var item_id: int
@export var name: String
@export var description: String
@export var expire_time: int
@export var shop: Array

func _init() -> void:
	pass
	
func print_info():
	pass

func is_own() -> bool:
	if expire_time == g.v.game_constants.ITEM_PERMANENT_TIME:
		return true
	if expire_time > g.v.game_manager.get_timestamp_server():
		return true
	return false
