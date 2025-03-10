extends Node2D

var variables = {}  # Dictionary to store global variables
var v: GlobalVar
func set_var(key: String, value):
	variables[key] = value

func get_var(key: String):
	return variables.get(key, null)

func has_var(key: String) -> bool:
	return variables.has(key)

func global() -> GlobalVar:
	return v
