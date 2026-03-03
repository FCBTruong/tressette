extends Node

@onready var highlight = find_child("Highlight")
var id: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_hightlight(high):
	highlight.visible = high

func on_click():
	g.v.signal_bus.emit_signal_global('on_picking_avatar', [id])
	pass
