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

	# Check if the number is negative
	var is_negative = number < 0
	if is_negative:
		number_str = number_str.substr(1)  # Remove the negative sign for formatting

	# Format the number
	for i in range(number_str.length() - 1, -1, -1):
		formatted = number_str[i] + formatted
		count += 1
		if count % 3 == 0 and i != 0:
			formatted = "." + formatted

	# Re-add the negative sign if the number is negative
	if is_negative:
		formatted = "-" + formatted

	return formatted


func symbol_number(num: int) -> String:
	if num >= 1_000_000_000:
		return str(floor(num / 1_000_000_000.0)) + "B"
	elif num >= 1_000_000:
		return str(floor(num / 1_000_000.0)) + "M"
	elif num >= 1_000:
		return str(floor(num / 1_000.0)) + "K"
	else:
		return str(num)
		
func sub_string(str: String, size: int) -> String:
	if str.length() > size:
		return str.substr(0, size) + "..."
	return str
	
func convert_point_string_to_int(point_str: String) -> int:
	# Remove all periods from the string
	var cleaned_str = point_str.replace(".", "")
	# Convert the cleaned string to an integer
	return cleaned_str.to_int()
