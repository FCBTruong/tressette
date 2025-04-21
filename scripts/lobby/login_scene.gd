extends Node

@onready var pn_cheat = find_child('PnCheat')
@onready var input_uid_cheat = find_child('InputUIDCheat')
@onready var apple_btn = find_child("ApplePn")
@onready var login_pn = find_child("LoginPn")
@onready var select_uid_cheat = find_child("SelectUIDCheat")
@onready var privacy_pn = find_child("PrivacyTermPn")
var uids_cheat = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	var auto = g.v.login_mgr.auto_login()	
	if g.v.config.CURRENT_MODE != g.v.config.MODES.LIVE:
		pn_cheat.visible = true
		
		self.uids_cheat = [1000003,
		1000004, 1000005, 1000006, 1000007]
		for x in uids_cheat:
			select_uid_cheat.add_item(str(x))
			
		input_uid_cheat.text = g.v.storage_cache.fetch('login_uid_cheat', '')
	else:
		pn_cheat.visible = false
	
	if g.v.config.get_platform() == g.v.config.PLATFORMS.IOS:
		apple_btn.visible = true
	else:
		apple_btn.visible = false
		
	var tween = create_tween()
	var default_pos = login_pn.position
	
	login_pn.modulate.a = 0
	login_pn.position.y -= 300
	var delay = 2 if auto else 0
	
	tween.parallel().tween_property(login_pn,
		"position", default_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) \
			.set_delay(delay) 
	tween.parallel().tween_property(login_pn,
		"modulate:a", 1, 0.4).set_delay(delay) 
	
	var privacy_pn_pos = privacy_pn.position
	privacy_pn.position.y += 200
	tween.parallel().tween_property(privacy_pn,
		"position:y", privacy_pn_pos.y, 0.4).set_delay(delay) 
		
	var screen_size = DisplayServer.window_get_size()
	if screen_size.y > screen_size.x * 1.4:
		login_pn.scale = Vector2(2.5, 2.5)
		

func on_login_local_firebase_succeeed(auth):
	# For computer testing, outdated
	print('login succeeded')
	print(auth)
	g.v.login_mgr.send_login_firebase(auth.get('idtoken'), 0)

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func test_login_user_A() -> void:
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.Login.new()
	pkg.set_token('fb4e942c-ea07-437f-a56a-e12a8bb08709')
	pkg.set_type(g.v.login_mgr.LOGIN_GUEST)
	g.v.login_mgr._set_device_info(pkg)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.LOGIN, pkg.to_bytes())

func test_login_userB() -> void:
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.Login.new()
	pkg.set_token('625fd7af-f734-41a1-877d-2cdef81df36a')
	pkg.set_type(g.v.login_mgr.LOGIN_GUEST)
	g.v.login_mgr._set_device_info(pkg)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.LOGIN, pkg.to_bytes())

func _login_google() -> void:
	if g.v.config.CURRENT_MODE == g.v.config.MODES.LOCAL:
		g.v.login_mgr.send_login_firebase("abcd1234", 0)
		return
	
	g.v.firebase_mgr.login_with_google()

func _login_facebook() -> void:
	g.v.firebase_mgr.login_with_facebook()
	pass

func _login_guest() -> void:
	print('login_guest')
	g.v.login_mgr.login_guest()


func _login_by_uid_cheat(text) -> void:
	# no cred
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.Login.new()
	pkg.set_token(text)
	pkg.set_type(g.v.login_mgr.LOGIN_UID_CHEAT)
	g.v.login_mgr._set_device_info(pkg)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.LOGIN, pkg.to_bytes())
	g.v.storage_cache.store('login_uid_cheat', text)
	pass

func _login_with_apple() -> void:
	g.v.firebase_mgr.login_with_apple()
	pass


func _cheat_select_uid():
	var a = select_uid_cheat.get_selected_id()
	_login_by_uid_cheat(str(self.uids_cheat[a]))

func _click_privacy_policy():
	OS.shell_open(g.v.game_constants.PRIVACY_POLICY_URL)

func _click_terms_of_service():
	OS.shell_open(g.v.game_constants.TERMS_OF_SERVICE_URL)
