extends TextureRect

@export var is_me: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_me:
		set_avatar(PlayerInfoMgr.my_user_data.avatar)
		print('avatar....', PlayerInfoMgr.my_user_data.avatar)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_avatar(avatar: String):
	# Check if the avatar is a URL (starts with "https")
	if avatar.begins_with("https://"):
		# Load from URL (requires an HTTP request)
		var http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.request(avatar)
		http_request.connect("request_completed", Callable(self, "_on_avatar_request_completed"))
	else:
		# Load locally from the assets folder
		var texture_path = "res://assets/images/lobby/avatars/avatar_" + avatar + ".png"
		if ResourceLoader.exists(texture_path):
			self.texture = load(texture_path)
		else:
			# Optional: Set a default texture if the file doesn't exist
			self.texture = load("res://assets/images/lobby/avatars/default.png")

func _on_avatar_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var image = Image.new()
		var error = image.load_png_from_buffer(body)
		if error == OK:
			var texture = ImageTexture.new()
			texture.create_from_image(image)
			self.texture = texture
		else:
			print("Error loading avatar from URL:", error)
	else:
		print("Failed to load avatar from URL, response code:", response_code)
