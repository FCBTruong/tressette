extends Node

var firebase_plugin
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.has_singleton("FirebasePlugin"):
		firebase_plugin = Engine.get_singleton("FirebasePlugin")
	else:
		printerr("ddCan not find plugin")

func test():
	firebase_plugin.Hello()
	firebase_plugin.signInWithGoogle()
