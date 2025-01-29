extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)
	Firebase.Auth.signup_failed.connect(on_signup_failed)
	pass # Replace with function body.

func on_login_succeeded(auth):
	print('login succeeded')
	print(auth)

func on_signup_succeeded(auth):
	print(auth)
	Firebase.Auth.save_auth(auth)
	
func on_login_failed(error_code, message):
	print(error_code)
	print(message)
	
	
func on_signup_failed(error_code, message):
	print(error_code)
	print(message)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _login() -> void:
	GameClient.send_packet(GameConstants.CMDs.LOGIN, [])

func test_login_user_A() -> void:
	var pkg = GameConstants.PROTOBUF.PACKETS.Login.new()
	pkg.set_uid(1000000)
	GameClient.send_packet(GameConstants.CMDs.LOGIN, pkg.to_bytes())

func test_login_userB() -> void:
	var pkg = GameConstants.PROTOBUF.PACKETS.Login.new()
	pkg.set_uid(1000001)
	GameClient.send_packet(GameConstants.CMDs.LOGIN, pkg.to_bytes())

func _login_google() -> void:
	var provider: AuthProvider = Firebase.Auth.get_GoogleProvider()
	Firebase.Auth.get_auth_localhost(provider, 8060)
	pass
