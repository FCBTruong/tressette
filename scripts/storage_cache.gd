extends Node

# File path to store the key-value data
const STORAGE_FILE_PATH := "user://storage.json"

# Function to store key-value pairs into a file
func store(key: String, value: Variant) -> void:
	var file = FileAccess.open(STORAGE_FILE_PATH, FileAccess.WRITE_READ)
	
	# Read existing data from file (if any)
	var data: Dictionary = {}
	if file:
		var json_data = file.get_as_text()
		var json_instance = JSON.new()
		var parse_result = json_instance.parse(json_data)
		if parse_result == OK:
			data = json_instance.result
	
	# Store the new key-value pair
	data[key] = value
	
	# Write updated data back to file
	file.seek_end()
	file.store_string(JSON.stringify(data))
	file.close()

# Function to fetch a value by key, with a default value if the key is not found
func fetch(key: String, default_value: Variant = null) -> Variant:
	var file = FileAccess.open(STORAGE_FILE_PATH, FileAccess.READ)
	
	# Read existing data from file (if any)
	if file:
		var json_data = file.get_as_text()
		var json_instance = JSON.new()
		var parse_result = json_instance.parse(json_data)
		if parse_result == OK:
			var data: Dictionary = json_instance.get_data()
			if data.has(key):
				return data[key]
	
	# Return default value if key is not found
	return default_value
