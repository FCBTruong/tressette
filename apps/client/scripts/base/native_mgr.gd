extends RefCounted
class_name NativeMgr

var native_plugin = null
func on_ready() -> void:
	if OS.get_name() == 'Android':
		if Engine.has_singleton("NativeCustomPlugin"):
			native_plugin = Engine.get_singleton("NativeCustomPlugin")
		else:
			print("not found native plugin")
			
func open_app_store():
	if native_plugin:
		native_plugin.openAppStore(g.v.game_constants.PACKAGE_NAME)
	# Google, Apple Store

func rate_app():
	print('rate app')
	if native_plugin && g.v.config.get_platform() == g.v.config.PLATFORMS.ANDROID:
		native_plugin.requestAppReview()

func share_app(text: String):
	if native_plugin:
		if g.v.config.get_platform() == g.v.config.PLATFORMS.ANDROID:
			native_plugin.shareApp(g.v.game_constants.PACKAGE_NAME, text)
