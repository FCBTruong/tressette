@tool
extends EditorPlugin

var exportPlugin: AndroidExportPlugin
func _enter_tree() -> void:
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
	var plugin_name = "CustomNativePluginAndroid"
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformAndroid:
			return true
		return false
	
	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(['custom_native/app-debug.aar'])
		
			
	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray([])
		else:
			return PackedStringArray([])
			
	func _get_name():
		return plugin_name
		
