extends Node

# DO NOT ADD ANY CHANGES HERE
# IF ADD NEED TO UPLOAD NEW APK, IOS
# CALL WHEN GAME STARTED
var save_path = "user://update.pck"
var update_url = "https://tressette-cdn.s3.ap-southeast-1.amazonaws.com/update.pck"
var game_init
var is_downloading = false
var progress_bar
var version = 1
var is_local = false
func _init():
	if OS.get_name() == "macOS":
		is_local = true
		return
	
	var cache_version = load_version()
	if cache_version != -1:
		version = cache_version
		
	print("load_resource_pack")
	if OS.get_name() != "Web":
		ProjectSettings.load_resource_pack(save_path)

func _ready() -> void:
	get_tree().current_scene.find_child("DownloadPn").visible = false
	add_child(http_request)
	print("root game....")
	await get_tree().process_frame
	
	if is_local:
		_init_game()
		return
	var need_update = false
	
	if OS.get_name() != "Web":
		# call get version
		check_version()
		# after download version successful
		# will handle need update or not
	else:
		_init_game()

func _init_game():
	var game_init = load("res://scripts/root/game_init.gd").new()	
	get_tree().root.add_child(game_init)

var last_update_time = 0.0
func _process(delta: float) -> void:
	if is_downloading:
		last_update_time += delta
		if last_update_time >= 0.5:  # Update every 0.5 seconds
			last_update_time = 0  # Reset timer

			var bodySize = http_request.get_body_size()
			var downloadedBytes = http_request.get_downloaded_bytes()
			
			if bodySize > 0:
				var percent = int((downloadedBytes * 100) / bodySize)
				print(str(percent) + "% downloaded")
				progress_bar.value = percent


@onready var http_request = HTTPRequest.new()


func download_cdn():
	get_tree().current_scene.find_child("DownloadPn").visible = true
	progress_bar = get_tree().current_scene.find_child("ProgressBar")
	is_downloading = true
	http_request.request_completed.connect(_on_download_complete)
	var error = http_request.request(update_url, [], HTTPClient.METHOD_GET, "")  # Enable progress tracking
	if error != OK:
		print("Failed to send update request, error code: ", error)

func _on_download_progress(bytes_downloaded: int, total_bytes: int):
	if total_bytes > 0:
		var percent = float(bytes_downloaded) / total_bytes * 100
		print("Download Progress: ", percent, "%")

func _on_download_complete(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	is_downloading = false
	if response_code == 200:
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		if file:
			file.store_buffer(body)
			file.flush()
			print("Update downloaded successfully!")
			save_version(version)
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
		
	await get_tree().process_frame
	_init_game()
		
		
func load_version() -> int:
	var path = "user://version.txt"
	if not FileAccess.file_exists(path):
		return -1  # File doesn't exist, return default version

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var v = file.get_as_text().strip_edges()
		file.close()
		return int(v) if v.is_valid_int() else -1  # Avoid errors if file is empty or corrupted
	return -1

func save_version(v: int) -> void:
	var path = "user://version.txt"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		print("Saving version:", v)
		file.store_string(str(v))  # Store as text, not binary
		file.close()



func check_version():
	http_request.request_completed.connect(_on_request_complete_version)
	var url = "https://tressette-cdn.s3.ap-southeast-1.amazonaws.com/version.json"
	var error = http_request.request(url)
	if error != OK:
		print("Failed to send request, error code: ", error)

func _on_request_complete_version(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var json_string = body.get_string_from_utf8()
		var json = JSON.new()
		var parse_result = json.parse(json_string)

		if parse_result == OK:
			var data = json.get_data()
			var v = version
			if OS.get_name() == "Android":
				v = data['android']
			else:
				v = data['ios']
			_handle_update_version(v)
		else:
			print("Failed to parse JSON.")
	else:
		print("Failed to download JSON, response code:", response_code)

func _handle_update_version(remote_version):
	if remote_version > version:
		version = remote_version
		download_cdn()
	else:
		_init_game()
