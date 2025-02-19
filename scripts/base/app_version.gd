extends Node

var server_app_version = 0
var server_forced_version = 0
var server_remind_version = 0

# INCREASE WHEN BUILD
const ANDROID_CODE_VERSION: int = 1
const IOS_CODE_VERSION: int = 1

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func handle_version_and_open_login(payload) -> void:
	var pkg = GameConstants.PROTOBUF.PACKETS.AppCodeVersion.new()
	var result_code = pkg.from_bytes(payload)
	var my_code_version
	if Config.get_platform() == Config.PLATFORMS.IOS:
		my_code_version = IOS_CODE_VERSION
		server_app_version = pkg.get_ios_version()
		server_forced_version = pkg.get_ios_forced_update_version()
		server_remind_version = pkg.get_ios_remind_update_version()
	else:
		my_code_version = ANDROID_CODE_VERSION
		server_app_version = pkg.get_android_version()
		server_forced_version = pkg.get_android_forced_update_version()
		server_remind_version = pkg.get_android_remind_update_version()
	
	
	if my_code_version >= server_app_version:
		# Version OK
		print("version ok, open login scene now")
		SceneManager.switch_scene(SceneManager.LOGIN_SCENE)
	else:
		if my_code_version <= server_forced_version:
			SceneManager.show_ok_dialog(
				tr("FORCE_UPDATE_NEW_VERSION"),
				func ():
					_open_app_store()
			)
		else:
			SceneManager.show_dialog(
				tr("REMIND_UPDATE_NEW_VERSION"),
				func():
					print('open store')
					_open_app_store(),
				func():
					SceneManager.switch_scene(SceneManager.LOGIN_SCENE),
				true
			)

func _open_app_store():
	if Config.get_platform() == Config.PLATFORMS.IOS:
		pass
	elif Config.get_platform() == Config.PLATFORMS.ANDROID:
		NativeMgr.open_app_store()
		return
	OS.shell_open("https://play.google.com/store/apps/details?id=" + GameConstants.PACKAGE_NAME)
