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
	pass
	
func auto_login():
	if (g.v.config.CURRENT_MODE == g.v.config.MODES.LOCAL):
		return
	
	login_guest()
	
func login_guest():
	var guest_id = load_guest_id()
	print("guest id", guest_id)
	_send_login_guest(guest_id)

func _send_login_guest(guest_id):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.Login.new()
	pkg.set_type(LOGIN_GUEST)	
	pkg.set_token(guest_id)
	_set_device_info(pkg)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.LOGIN, pkg.to_bytes())

func load_guest_id() -> String:
	var path := "user://guest_id.txt"

	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var guest_id := file.get_as_text().strip_edges()
			file.close()
			if guest_id != "":
				return guest_id

	var raw := str(Time.get_unix_time_from_system()) + "_" + str(Time.get_ticks_usec()) + "_" + str(randi())
	var guest_id := raw.md5_text()

	var save_file := FileAccess.open(path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(guest_id)
		save_file.close()

	return guest_id
	
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
