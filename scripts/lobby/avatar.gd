extends TextureRect

@export var is_me: bool = true
var hash_key: String
var file_path: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_me:
		set_me()
	g.v.signal_bus.connect_global('on_changed_avatar', Callable(self, "on_changed_my_avatar"))


func set_me():
	is_me = true
	set_avatar(g.v.player_info_mgr.my_user_data.avatar)
	
	
func _update_my_avatar():
	set_avatar(g.v.player_info_mgr.my_user_data.avatar)
	print('avatar....', g.v.player_info_mgr.my_user_data.avatar)

func on_changed_my_avatar():
	if not is_me:
		return
	_update_my_avatar()
	pass		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_avatar(avatar: String):
	if avatar == '-1':
		avatar = g.v.player_info_mgr.my_user_data.avatar_third_party
	# Check if the avatar is a URL (starts with "https")
	if avatar.begins_with("https://"):
		# Load from URL (requires an HTTP request)
		hash_key = avatar.md5_text()
		print(OS.get_data_dir())
		# check if file exist from local
		file_path = "user://avatars/" + hash_key + '.png'
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			file.close()
			print('found avatar local')
			var image = Image.new()
			var err = image.load(file_path)
			var texture = ImageTexture.create_from_image(image)
			if texture:
				self.texture = texture
			return
				
		var http_request = HTTPRequest.new()
		var url = avatar
		add_child(http_request)
		http_request.request(url)
		http_request.connect("request_completed", Callable(self, "_on_avatar_request_completed"))
	else:
		# Load locally from the assets folder
		var texture_path = "res://assets/images/lobby/avatars/avatar_" + avatar + ".png"
		if ResourceLoader.exists(texture_path):
			self.texture = load(texture_path)
		
func _on_avatar_request_completed(result, response_code, headers, body):
	print('_on_avatar_request_completed')
	if response_code == 200:
		var image = Image.new()
		var error = image.load_png_from_buffer(body)
		if error == OK:
			var texture = ImageTexture.new()
			texture.set_image(image)
			self.texture = texture
			
			# save file local
			var dir = DirAccess.open("user://")
			if not dir.dir_exists("user://avatars/"):
				dir.make_dir_recursive("user://avatars/")
			var file = FileAccess.open(file_path, FileAccess.ModeFlags.WRITE)	
			if file:
				file.store_buffer(body)
				file.close()
			else:
				print("Failed to open file for writing.")
				
		else:
			print("Error loading avatar from URL:", error)
	else:
		print("Failed to load avatar from URL, response code:", response_code)
