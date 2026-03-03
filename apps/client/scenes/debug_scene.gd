extends Node

@onready var t = find_child("Test")
var default_pos
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	default_pos = t.position
	pass # Replace with function body.

func test_run():	
	var tw = create_tween()
	t.position = default_pos
	tw.tween_property(t, "position", Vector2(default_pos.x + 900, default_pos.y), 0.5)


func _process(delta: float) -> void:
	pass
