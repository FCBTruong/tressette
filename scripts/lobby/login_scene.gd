extends Node

@onready var pn_cheat = find_child('PnCheat')
@onready var input_uid_cheat = find_child('InputUIDCheat')
@onready var apple_btn = find_child("AppleBtn")
@onready var login_pn = find_child("LoginPn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(on_login_local_firebase_succeeed)
	
	LoginMgr.auto_login()	
	if Config.CURRENT_MODE != Config.MODES.LIVE:
		pn_cheat.visible = true
		input_uid_cheat.text = StorageCache.fetch('login_uid_cheat', '')
	else:
		pn_cheat.visible = false
	
	if Config.get_platform() == Config.PLATFORMS.IOS:
		apple_btn.visible = true
	else:
		apple_btn.visible = false
		
	var tween = create_tween()
	var default_pos = login_pn.position
	
	login_pn.modulate.a = 0
	login_pn.position.y -= 300
	
	tween.parallel().tween_property(login_pn,
		"position", default_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(login_pn,
		"modulate:a", 1, 0.4)
		

func on_login_local_firebase_succeeed(auth):
	# For computer testing, outdated
	print('login succeeded')
	print(auth)
	LoginMgr.send_login_firebase(auth.get('idtoken'), 0)

	
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
	FirebaseMgr.login_with_google()
	
	# outdated
	#return
	#var provider: AuthProvider = Firebase.Auth.get_GoogleProvider()
	#Firebase.Auth.get_auth_localhost(provider, 8060)
	#pass

func _login_facebook() -> void:
	if Config.CURRENT_MODE == Config.MODES.LOCAL:
		var provider: AuthProvider = Firebase.Auth.get_FacebookProvider()
		Firebase.Auth.get_auth_localhost(provider, 8060)
		return
	FirebaseMgr.login_with_facebook()
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

func _login_with_apple() -> void:
	FirebaseMgr.login_with_apple()
	pass
