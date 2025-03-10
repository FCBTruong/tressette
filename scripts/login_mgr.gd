extends Node
class_name LoginMgr

const LOGIN_GUEST: int = 0
const LOGIN_GOOGLE: int = 1
const LOGIN_FACEBOOK: int = 2
const LOGIN_APPLE: int = 3
const LOGIN_TOKEN: int = 20
const LOGIN_UID_CHEAT: int = 10
var last_login_type: int = g.v.game_constants.LOGIN_TYPE.GUEST



func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		g.v.game_constants.CMDs.CREATE_GUEST_ACCOUNT:
			_on_received_guest_acc(payload)
			pass
		g.v.game_constants.CMDs.LOGIN_FIREBASE:
			_on_received_firebase_acc(payload)
			pass
			
func _on_received_guest_acc(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.GuestAccount.new()
	var result_code = pkg.from_bytes(payload)
	var guest_id = pkg.get_guest_id()
	_send_login_guest(guest_id)
	# save 
	save_guest_id(guest_id)
	
func _on_received_firebase_acc(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.LoginFirebase.new()
	var result_code = pkg.from_bytes(payload)
	var token = pkg.get_login_token()
	save_login_token(token)
	# call login
	g.v.storage_cache.store('last_login_type', g.v.game_constants.LOGIN_TYPE.FIREBASE) # use token
	auto_login()

func auto_login():
	last_login_type = g.v.storage_cache.fetch('last_login_type', g.v.game_constants.LOGIN_TYPE.NONE)
	if last_login_type == g.v.game_constants.LOGIN_TYPE.NONE:
		# For web and is first time open game, auto login guest
		if g.v.config.get_platform() == g.v.config.PLATFORMS.WEB:
			var loginned = g.v.storage_cache.fetch('loginned', 0)
			if loginned == 0:
				login_guest()
				g.v.storage_cache.store('loginned', 1)
		
		return false
	if last_login_type == g.v.game_constants.LOGIN_TYPE.FIREBASE: # use token
		var login_token = load_login_token()
		print('login_token')
		var pkg = g.v.game_constants.PROTOBUF.PACKETS.Login.new()
		pkg.set_type(LOGIN_TOKEN)	
		pkg.set_token(login_token)
		
		_set_device_info(pkg)
	
		g.v.game_client.send_packet(g.v.game_constants.CMDs.LOGIN, pkg.to_bytes())
	elif  last_login_type == g.v.game_constants.LOGIN_TYPE.GUEST: # guest
		login_guest()
	return true
	
func login_guest():
	g.v.storage_cache.store('last_login_type', g.v.game_constants.LOGIN_TYPE.GUEST)
	var guest_id = load_guest_id()
	print('load guest', guest_id)
	#return
	if guest_id == '':
		_create_guest_account()
	else:
		_send_login_guest(guest_id)
		print('guest id', guest_id)

func _send_login_guest(guest_id):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.Login.new()
	pkg.set_type(LOGIN_GUEST)	
	pkg.set_token(guest_id)
	_set_device_info(pkg)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.LOGIN, pkg.to_bytes())

func _create_guest_account():
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CREATE_GUEST_ACCOUNT, [])

	
func load_guest_id() -> String:
	var file = FileAccess.open("user://guest_id.txt", FileAccess.READ)
	if file:
		var guest_id = file.get_as_text().strip_edges()
		file.close()
		return guest_id
	return ""
	
func save_guest_id(guest_id: String) -> void:
	var file = FileAccess.open("user://guest_id.txt", FileAccess.WRITE)
	if file:
		print('save guest', guest_id)
		file.store_string(guest_id)
		file.close()

func load_login_token() -> String:
	var file = FileAccess.open("user://token.txt", FileAccess.READ)
	if file:
		var token = file.get_as_text().strip_edges()
		file.close()
		return token
	return ""
	
func save_login_token(token: String) -> void:
	print('save login token', token)
	var file = FileAccess.open("user://token.txt", FileAccess.WRITE)
	if file:
		file.store_string(token)
		file.close()

func send_login_firebase(token: String, sub_type) -> void:
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.LoginFirebase.new()
	pkg.set_login_token(token)
	pkg.set_sub_type(sub_type)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.LOGIN_FIREBASE, pkg.to_bytes())
	
func _set_device_info(pkg):
	var device_model = OS.get_model_name()
	var platform = ''
	
	if g.v.config.get_platform() == g.v.config.PLATFORMS.IOS:
		platform = 'ios'
	elif g.v.config.get_platform() == g.v.config.PLATFORMS.WEB:
		platform = 'web'
	else:
		platform = 'android'
	pkg.set_device_model(device_model)
	pkg.set_platform(platform)
	pkg.set_app_version_code(g.v.app_version.my_code_version)
	
	var current_locale = OS.get_locale()
	var country = current_locale.split("_")[-1]
	pkg.set_device_country(country)
