# UserData.gd
class_name InventoryItem
extends Resource  # Use RefCounted for lightweight, reference-managed objects

@export var item_id: int
@export var name: String
@export var description: String
@export var expire_time: int
@export var is_own: bool

func _init() -> void:
	pass
	
func print_info():
	pass
