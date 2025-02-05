extends Node

const LOGIN_GUEST: int = 0
const LOGIN_GOOGLE: int = 1
const LOGIN_FACEBOOK: int = 2
const LOGIN_UID_CHEAT: int = 10
var last_login_type: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		GameConstants.CMDs.CREATE_GUEST_ACCOUNT:
			_on_received_guest_acc(payload)
			pass
		GameConstants.CMDs.LOGIN_FIREBASE:
			_on_received_firebase_acc(payload)
			pass
			
func _on_received_guest_acc(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.GuestAccount.new()
	var result_code = pkg.from_bytes(payload)
	var guest_id = pkg.get_guest_id()
	_send_login_guest(guest_id)
	# save 
	save_guest_id(guest_id)
	
func _on_received_firebase_acc(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.LoginFirebase.new()
	var result_code = pkg.from_bytes(payload)
	var token = pkg.get_login_token()
	save_login_token(token)
	# call login
	StorageCache.store('last_login_type', 1) # use token
	auto_login()

func auto_login():
	last_login_type = StorageCache.fetch('last_login_type', -1)
	if last_login_type == -1:
		return
	if last_login_type == 1: # use token
		var login_token = load_login_token()
		print('login_token')
		var pkg = GameConstants.PROTOBUF.PACKETS.Login.new()
		pkg.set_type(LOGIN_GOOGLE)	
		pkg.set_token(login_token)
		GameClient.send_packet(GameConstants.CMDs.LOGIN, pkg.to_bytes())
	elif  last_login_type == 0: # guest
		login_guest()
	
func login_guest():
	StorageCache.store('last_login_type', 0)
	var guest_id = load_guest_id()
	print('load guest', guest_id)
	#return
	if guest_id == '':
		_create_guest_account()
	else:
		_send_login_guest(guest_id)
		print('guest id', guest_id)

func _send_login_guest(guest_id):
	var pkg = GameConstants.PROTOBUF.PACKETS.Login.new()
	pkg.set_type(LOGIN_GUEST)	
	pkg.set_token(guest_id)
	GameClient.send_packet(GameConstants.CMDs.LOGIN, pkg.to_bytes())

func _create_guest_account():
	GameClient.send_packet(GameConstants.CMDs.CREATE_GUEST_ACCOUNT, [])

	
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

func send_login_firebase(token: String) -> void:
	var pkg = GameConstants.PROTOBUF.PACKETS.LoginFirebase.new()
	pkg.set_login_token(token)
	GameClient.send_packet(GameConstants.CMDs.LOGIN_FIREBASE, pkg.to_bytes())
	
