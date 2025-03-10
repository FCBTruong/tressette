extends Node
class_name DynamicMgr

var update_url = "https://tressette-cdn.s3.ap-southeast-1.amazonaws.com/update.pck"  # Replace with actual URL
var save_path = "user://update.pck"

@onready var http_request = HTTPRequest.new()

func download_cdn():
	return
	add_child(http_request)
	http_request.request_completed.connect(_on_download_complete)  # Callable function
	var error = http_request.request(update_url)
	if error != OK:
		print("Failed to send update request, error code: ", error)

func _on_download_complete(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		if file:
			file.store_buffer(body)
			file.flush()
			print("Update downloaded successfully!")
			# save version
			g.v.storage_cache.store("cdn_version", g.v.app_version.cdn_version)
			apply_update()
		else:
			print("Failed to save update.")
	else:
		print("Download failed with response code: ", response_code)

func apply_update():
	if ProjectSettings.load_resource_pack(save_path):
		print("Update applied successfully!")
	else:
		print("Failed to load update.")
		
