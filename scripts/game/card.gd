extends Node


var pos_card = null
var is_selecting = false
var pos_touch = null
var is_touching = false
var is_dragging = false
var id = 0
var _default_z_index = 0
var is_played = false
var tween: Tween
@onready var card_image = find_child('CardImage')
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_played = false
	pos_card = card_image.position
	pass # Replace with function body.
	
func _on_touch_card() -> void:
	SceneManager.INSTANCES.BOARD_SCENE.play_my_card(id)
	
func set_state_focusing(focus = false) -> void:
	if focus:
		is_selecting = true
		card_image.position.y = pos_card.y - 30
		self.z_index = 30
	else:
		card_image.position = pos_card
		self.z_index = _default_z_index
		
func _on_touch_card_down() -> void:
	return
	print('deubbbb')
	is_touching = true
	is_dragging = false
	pos_touch = get_viewport().get_mouse_position()

func _process(delta: float) -> void:
	return
	if is_touching:
		var current_pos = get_viewport().get_mouse_position()
		# Check if the card has been dragged far enough to start dragging
		if not is_dragging and pos_touch.distance_to(current_pos) > 10: # Threshold for drag detection
			is_dragging = true
		if is_dragging:
			card_image.position = current_pos

func _on_touch_card_up() -> void:
	is_touching = false
	is_dragging = false

func set_card(card_id: int):
	print('set_card...', card_id)
	id = card_id
	
func turn_face_down():
	var path = "res://assets/images/cards/card_back.png"
	_load_texture(path)
	
func _load_texture(path):
	var new_texture = load(path)
	if new_texture is Texture2D:
		card_image.texture = new_texture
	else:
		print("Failed to load texture:", path)
		
func get_card_id():
	return id
	
func _set_default_z_index(z):
	_default_z_index = z
	self.z_index = z

func turn_face_up():
	var path = "res://assets/images/cards/card_" + str(id) + ".png"
	_load_texture(path)
	
func show_card(effect_flip: bool = false):
	if not effect_flip:
		turn_face_up()
	else:
		# Ensure no other tween is running
		if tween and tween.is_running():
			tween.kill()
		
		# Create a new tween
		tween = create_tween()

		var time_flip = 0.5
		var halfway_time = time_flip / 2

		# First part: Scale X to 0 (flip card to its edge)
		tween.tween_property(card_image, "scale:x", 0, halfway_time).set_ease(Tween.EASE_IN)

		# Change the card face in the middle of the flip
		tween.tween_callback(func():
			turn_face_up()
		)
		# Second part: Scale X back to 1 (flip card back)
		tween.tween_property(card_image, "scale:x", 1, halfway_time).set_ease(Tween.EASE_OUT)
