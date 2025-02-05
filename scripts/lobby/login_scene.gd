extends Node

@onready var pn_cheat = find_child('PnCheat')
@onready var input_uid_cheat = find_child('InputUIDCheat')
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)
	Firebase.Auth.signup_failed.connect(on_signup_failed)
	
	LoginMgr.auto_login()	
	if Config.CURRENT_MODE != Config.MODES.LIVE:
		pn_cheat.visible = true
		input_uid_cheat.text = StorageCache.fetch('login_uid_cheat', '')
	else:
		pn_cheat.visible = false
	pass # Replace with function body.

func on_login_succeeded(auth):
	print('login succeeded')
	print(auth)
	LoginMgr.send_login_firebase(auth.get('idtoken'))

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
	pkg.set_token('fb4e942c-ea07-437f-a56a-e12a8bb08709')
	pkg.set_type(LoginMgr.LOGIN_GUEST)
	GameClient.send_packet(GameConstants.CMDs.LOGIN, pkg.to_bytes())

func test_login_userB() -> void:
	var pkg = GameConstants.PROTOBUF.PACKETS.Login.new()
	pkg.set_token('625fd7af-f734-41a1-877d-2cdef81df36a')
	pkg.set_type(LoginMgr.LOGIN_GUEST)
	GameClient.send_packet(GameConstants.CMDs.LOGIN, pkg.to_bytes())

func _login_google() -> void:
	var provider: AuthProvider = Firebase.Auth.get_GoogleProvider()
	Firebase.Auth.get_auth_localhost(provider, 8060)
	pass

func _login_facebook() -> void:
	var provider: AuthProvider = Firebase.Auth.get_FacebookProvider()
	Firebase.Auth.get_auth_localhost(provider, 8060)
	pass

func _login_guest() -> void:
	print('login_guest')
	LoginMgr.login_guest()


func _login_by_uid_cheat(text) -> void:
	# no cred
	var pkg = GameConstants.PROTOBUF.PACKETS.Login.new()
	pkg.set_token(text)
	pkg.set_type(LoginMgr.LOGIN_UID_CHEAT)
	GameClient.send_packet(GameConstants.CMDs.LOGIN, pkg.to_bytes())
	StorageCache.store('login_uid_cheat', text)
	pass
