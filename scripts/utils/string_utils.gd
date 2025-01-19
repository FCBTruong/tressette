extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func point_number(number: int) -> String:
	var number_str = str(number)
	var formatted = ""
	var count = 0
	for i in range(number_str.length() - 1, -1, -1):
		formatted = number_str[i] + formatted
		count += 1
		if count % 3 == 0 and i != 0:
			formatted = "." + formatted
	return formatted
