extends Node

# Call the plugin's functions
var firebase

func _ready():
	firebase = FirebasePlugin.new()
	firebase.connect("authenticated", self, "_on_authenticated")
	firebase.connect("auth_failed", self, "_on_auth_failed")
	# Initialize Firebase (if needed)
	firebase.initializeFirebase()

func _on_authenticated(user_id):
	print("Authenticated with ID: ", user_id)

func _on_auth_failed(error_message):
	print("Authentication failed: ", error_message)
