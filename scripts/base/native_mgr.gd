extends Node

var native_plugin = null
func _ready() -> void:
	if OS.get_name() == 'Android':
		if Engine.has_singleton("NativeCustomPlugin"):
			native_plugin = Engine.get_singleton("NativeCustomPlugin")
		else:
			print("not found native plugin")
			
func open_app_store():
	if native_plugin:
		native_plugin.openAppStore(GameConstants.PACKAGE_NAME)
	# Google, Apple Store

func rate_app():
	print('rate app')
	if native_plugin && Config.get_platform() == Config.PLATFORMS.ANDROID:
		native_plugin.requestAppReview()

func share_app(text: String):
	if native_plugin:
		if Config.get_platform() == Config.PLATFORMS.ANDROID:
			native_plugin.shareApp(GameConstants.PACKAGE_NAME, text)
