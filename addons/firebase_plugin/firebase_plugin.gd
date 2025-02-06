@tool
extends EditorPlugin

var exportPlugin: AndroidExportPlugin
func _enter_tree() -> void:
	print("_enter_treedddd")
	# Initialization of the plugin goes here.
	exportPlugin = AndroidExportPlugin.new()
	add_export_plugin(exportPlugin)
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_export_plugin(exportPlugin)
	exportPlugin = null
	pass

class AndroidExportPlugin extends EditorExportPlugin:
	var plugin_name = "FirebasePlugin"
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		print("okkdddk")
		if platform is EditorExportPlatformAndroid:
			return true
		return false
	
	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		print('AndroidExportPlugin ddss', debug)
		if debug:
			print('firebase: _get_android_libraries')
			return PackedStringArray(['firebase_plugin/app-debug.aar'])
		else:
			return PackedStringArray(['firebase_plugin/app-debug.aar'])
			
	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray([])
		else:
			return PackedStringArray([])
			
	func _get_name():
		return plugin_name
