extends Node


var pos_card = null
var is_selecting = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pos_card = $Image.position
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_card(id: int) -> void:
	pass
	
func _on_touch_card() -> void:
	var img = $Image
	is_selecting = !is_selecting
	if is_selecting:
		img.position.y = pos_card.y - 30
	else:
		img.position = pos_card
