extends Node

var firebase_plugin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.has_singleton("FirebasePlugin"):
		firebase_plugin = Engine.get_singleton("FirebasePlugin")
		
		# Connect signals to their respective handlers
		firebase_plugin.on_firebase_auth_success.connect(on_firebase_auth_success)
		firebase_plugin.on_firebase_auth_failed.connect(_on_firebase_auth_failed)
		firebase_plugin.on_firebase_sign_out.connect(on_firebase_sign_out)
		firebase_plugin.test_signal.connect(on_test_signal)
	else:
		print("Cannot find FirebasePlugin!")

# Function to test the Firebase plugin
func test():
	if firebase_plugin:
		firebase_plugin.Hello()
		firebase_plugin.signInWithGoogle()
	else:
		print("Firebase plugin not initialized!")

# Callback when authentication succeeds
func on_firebase_auth_success(user_id: String, user_name: String, user_email: String, id_token: String, provider_id: String):
	print("Firebase login success!")
	print("User ID: ", user_id)
	print("User Name: ", user_name)
	print("User Email: ", user_email)
	print("Provider ID: ", provider_id)
	print("ID Token: ", id_token)
	
	# You can use this ID token to authenticate with your game server if needed
	LoginMgr.send_login_firebase(id_token)
	
# Callback when authentication fails
func _on_firebase_auth_failed(error_message):
	print("Firebase login failed: ", error_message)

# Function to sign out
func sign_out():
	if firebase_plugin:
		firebase_plugin.signOut()
	else:
		print("Firebase plugin not initialized!")

# Callback when user signs out
func on_firebase_sign_out():
	print("User signed out from Firebase!")
	
func login_with_google():
	firebase_plugin.signInWithGoogle()


func on_test_signal(msg):
	print('tessssst', msg)

func login_with_facebook():
	firebase_plugin.signInWithFacebook()
