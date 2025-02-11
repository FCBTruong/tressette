extends Node

var firebase_plugin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.get_name() == 'Android':
		if Engine.has_singleton("FirebasePlugin"):
			firebase_plugin = Engine.get_singleton("FirebasePlugin")
			
			# Connect signals to their respective handlers
			firebase_plugin.on_firebase_auth_success.connect(on_firebase_auth_success)
			firebase_plugin.on_firebase_auth_failed.connect(_on_firebase_auth_failed)
			firebase_plugin.on_firebase_sign_out.connect(on_firebase_sign_out)
			firebase_plugin.test_signal.connect(on_test_signal)
		else:
			print("Cannot find Android FirebasePlugin!")
	elif OS.get_name() == 'iOS':
		print("Firebase IOS check")
		if Engine.has_singleton("FirebaseIosPlugin"):
			print('has ios plugin')
			firebase_plugin = Engine.get_singleton("FirebaseIosPlugin")
			firebase_plugin.addition_result.connect(_addition_result_test)
			firebase_plugin.add()
			firebase_plugin.on_firebase_auth_success.connect(on_firebase_auth_success)
			firebase_plugin.on_firebase_auth_failed.connect(_on_firebase_auth_failed)
			firebase_plugin.on_firebase_sign_out.connect(on_firebase_sign_out)
		else:
			print("not found ios firebase plugin")

# Function to test the Firebase plugin
func test():
	if firebase_plugin:
		firebase_plugin.Hello()
		firebase_plugin.signInWithGoogle()
	else:
		print("Firebase plugin not initialized!")

# Callback when authentication succeeds
func on_firebase_auth_success(user_id, user_name, user_email, id_token, provider_id):
	print("Firebase login success!")
	print("User ID: ", user_id)
	print("User Name: ", user_name)
	print("User Email: ", user_email)
	print("Provider ID: ", provider_id)

	var sub_type = 0 # Exactly Firebase token, 1 is Google Token
	
	# FOR iOS, we need to customize a little bit
	# Due to ERROR with Firebase Auth -> can not login firebase directly
	# So need server login to firebase
	if Config.get_platform() == Config.PLATFORMS.IOS:
		if provider_id == "google":
			sub_type = 1 # GOOGLE TOKEN
		elif provider_id == "apple":
			sub_type = 3
		elif provider_id == "facebook":
			sub_type = 2
	LoginMgr.send_login_firebase(id_token, sub_type)
	
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

func _addition_result_test(a, b):
	print('ddhdhsjsj', a)
	print('ddhddddhsjsj', b)

func login_with_apple():
	print('login with apple')
	firebase_plugin.signInWithApple()
