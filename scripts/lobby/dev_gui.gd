extends Node

@onready var fps_lb = find_child('FpsLb')
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	fps_lb.text = str(Engine.get_frames_per_second())
	pass
