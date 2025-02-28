extends Node

const STORAGE_FILE_PATH := "user://storage.json"

var cache: Dictionary = {}  # In-memory cache

func _ready() -> void:
	_load_cache()

# Load data from file into memory
func _load_cache() -> void:
	if FileAccess.file_exists(STORAGE_FILE_PATH):
		var file = FileAccess.open(STORAGE_FILE_PATH, FileAccess.READ)
		if file:
			var json_data = file.get_as_text()
			var json_instance = JSON.new()
			if json_instance.parse(json_data) == OK:
				cache = json_instance.data
			file.close()

# Store key-value pair in memory and persist to file
func store(key: String, value: Variant) -> void:
	cache[key] = value
	_save_cache()

# Fetch a value from memory, return default if not found
func fetch(key: String, default_value: Variant = null) -> Variant:
	return cache.get(key, default_value)

# Save the cache to the file
func _save_cache() -> void:
	var file = FileAccess.open(STORAGE_FILE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(cache))
	file.close()
