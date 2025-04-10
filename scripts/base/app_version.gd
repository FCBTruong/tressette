extends Node2D
class_name AppVersion

# from server, do not edit here
var server_app_version = 0
var server_forced_version = 0
var server_remind_version = 0
var reviewing_version = 0
var cdn_version = 0

# INCREASE WHEN BUILD, should edit when upload new build
const ANDROID_CODE_VERSION: int = 8
const IOS_CODE_VERSION: int = 5
var my_code_version

func test():
	print("oooodddss")
	pass
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func handle_version_and_open_login(payload) -> void:
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.AppCodeVersion.new()
	var result_code = pkg.from_bytes(payload)
	
	if g.v.config.get_platform() == g.v.config.PLATFORMS.IOS:
		my_code_version = IOS_CODE_VERSION
		server_app_version = pkg.get_ios_version()
		server_forced_version = pkg.get_ios_forced_update_version()
		server_remind_version = pkg.get_ios_remind_update_version()
		reviewing_version = pkg.get_ios_reviewing_version()
	else:
		my_code_version = ANDROID_CODE_VERSION
		server_app_version = pkg.get_android_version()
		server_forced_version = pkg.get_android_forced_update_version()
		server_remind_version = pkg.get_android_remind_update_version()
		reviewing_version = -1

	if my_code_version >= server_app_version:
		# Version OK
		print("version ok, open login scene now")
		g.v.scene_manager.switch_scene(g.v.scene_manager.LOGIN_SCENE)
	else:
		if my_code_version <= server_forced_version:
			g.v.scene_manager.show_ok_dialog(
				tr("FORCE_UPDATE_NEW_VERSION"),
				func ():
					_open_app_store()
			)
		else:
			g.v.scene_manager.show_dialog(
				tr("REMIND_UPDATE_NEW_VERSION"),
				func():
					print('open store')
					_open_app_store(),
				func():
					g.v.scene_manager.switch_scene(g.v.scene_manager.LOGIN_SCENE),
				true
			)

func _open_app_store():
	if g.v.config.get_platform() == g.v.config.PLATFORMS.IOS:
		OS.shell_open("https://apps.apple.com/app/id" + g.v.game_constants.APPLE_APP_ID)
		pass
	elif g.v.config.get_platform() == g.v.config.PLATFORMS.ANDROID:
		g.v.native_mgr.open_app_store()
		return
	OS.shell_open("https://play.google.com/store/apps/details?id=" + g.v.game_constants.PACKAGE_NAME)

func is_in_review():		
	if g.v.config.get_platform() == g.v.config.PLATFORMS.WEB:
		return false
	if g.v.config.get_platform() == g.v.config.PLATFORMS.IOS:
		if g.v.player_info_mgr.my_user_data:
			if g.v.player_info_mgr.my_user_data.game_count < 3:
				return true
				
	return reviewing_version == my_code_version
