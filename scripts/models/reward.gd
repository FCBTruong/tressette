# UserData.gd
class_name Reward
extends Resource  # Use RefCounted for lightweight, reference-managed objects

@export var type: int
@export var value: int
@export var duration: int
@export var item_id: int

func _init(type: int, value: int = 1) -> void:
	self.type = type
	self.value = value
