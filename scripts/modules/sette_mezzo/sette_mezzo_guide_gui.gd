extends Node

@onready var main_pn = find_child("Main")
var default_pos
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	default_pos = main_pn.position
	var tween = create_tween()
	main_pn.position.y = default_pos.y - 600
	tween.tween_property(main_pn, "position", default_pos, 0.5)
	
func on_close():
	self.queue_free()
