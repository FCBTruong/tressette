# UserData.gd
class_name Reward
extends Resource  # Use RefCounted for lightweight, reference-managed objects

@export var value: int
@export var duration: int
@export var item_id: int

func _init(item_id: int, value: int = 1, duration = 0) -> void:
	self.item_id = item_id
	self.value = value
	self.duration = duration
