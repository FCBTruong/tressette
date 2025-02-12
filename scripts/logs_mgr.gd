extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func log_dev(str, group = ""):
	if Config.CURRENT_MODE == Config.MODES.LIVE:
		return
	var log = "LOG_DEV: " + group + ": " + str
	print(log)
	
