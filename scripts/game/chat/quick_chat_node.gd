extends Node


var text = ''
var parent
@onready var lb = find_child("Label")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_text(txt):
	lb.text = txt
	text = txt
	
func _click_chat():
	parent.text_submitted(text)
	pass
