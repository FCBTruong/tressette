extends Node2D


var pos_card = null
var is_selecting = false
var pos_touch = null
var is_touching = false
var is_dragging = false
var id = 0
var _default_z_index = 0
var is_played = false
var tween: Tween
var player_id = -1 # ref uid
@onready var card_image = find_child('CardImage')
@onready var main_pn = find_child('Main')
@onready var card_btn = find_child('CardBtn')
var face_state = g.v.game_constants.CARD_FACE_STATE.DOWN
@onready var hint_pn = find_child("HintPn")
@onready var shadow = find_child("Shadow")
@onready var star_icon = find_child("StarIcon")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_played = false
	pos_card = card_image.position
	hint_pn.visible = false
	shadow.visible = false
	star_icon.visible = false
	g.v.signal_bus.connect_global("update_card_style", Callable(self, "_on_update_card_style"))
	
func _on_touch_card() -> void:
	g.v.scene_manager.INSTANCES.BOARD_SCENE.play_my_card(id)
		
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
	face_state = g.v.game_constants.CARD_FACE_STATE.DOWN
	var path = "res://assets/images/card_tressette/card_back.png"
	_load_texture(path)
	
	self.card_image.self_modulate = Color("#ffffff")
	
	if g.v.game_manager.CURRENT_GAME_PLAY == 0:
		return
		#self.card_image.material = null
		card_mat.shader = shader1
		self.card_image.material = card_mat
	
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

var shader = preload("res://shaders/gold.gdshader")
var card_mat = ShaderMaterial.new()

var shader1 = preload('res://shaders/gradient.gdshader')

	
func turn_face_up():
	face_state = g.v.game_constants.CARD_FACE_STATE.UP
	_load_texture_card()
	
	if g.v.game_manager.CURRENT_GAME_PLAY == 0:
		if g.v.game_constants.game_logic.is_most_value_card(self.id):
			card_mat.shader = shader
			self.card_image.material = card_mat
		elif (g.v.game_constants.game_logic.is_strong_card(self.id)):
			#card_mat.shader = shader1
			#self.card_image.material = card_mat
			self.card_image.material = null
		else:
			self.card_image.material = null
	
	#if (g.v.game_constants.game_logic.is_strong_card(self.id)):
		#self.card_image.self_modulate = Color("ffe8ca")
	#else:
		#self.card_image.self_modulate = Color("#ffffff")
	
	# set special colour for strong card

func _load_texture_card():
	var path
	if g.v.game_manager.card_style == g.v.game_constants.CARD_STYLES.CLASSIC:
		path = "res://assets/images/card_tressette/classic/" + str(id) + ".png"
	elif g.v.game_manager.card_style == g.v.game_constants.CARD_STYLES.MODERN:
		path = "res://assets/images/card_tressette/modern/card_" + str(id) + ".png"

		

	_load_texture(path)
	
func show_card(effect_flip: bool = false, callback = null):
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
		if callback != null:
			tween.tween_callback(
				func():
					callback.call()
			)
func hide_card(time_flip = 0.5):
	# Ensure no other tween is running
	if tween and tween.is_running():
		tween.kill()
	
	# Create a new tween
	tween = create_tween()

	var halfway_time = time_flip / 2

	# First part: Scale X to 0 (flip card to its edge)
	tween.tween_property(card_image, "scale:x", 0, halfway_time).set_ease(Tween.EASE_IN)

	# Change the card face in the middle of the flip
	tween.tween_callback(func():
		turn_face_down()
	)
	# Second part: Scale X back to 1 (flip card back)
	tween.tween_property(card_image, "scale:x", 1, halfway_time).set_ease(Tween.EASE_OUT)

var light_scene = preload("res://scenes/board/EffectLightCard.tscn")
func effect_win_card():
	var instance = light_scene.instantiate()
	add_child(instance)
	move_child(instance, 0)
	var tween = create_tween()
	tween.tween_property(instance, "rotation_degrees", 360, 3.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)  
	tween.finished.connect(func(): instance.queue_free())

func update_state_can_play(is_valid: bool):
	if is_valid:
		card_btn.visible = true
		main_pn.modulate = Color(1, 1, 1)  # RGB values for red
		pass
	else:
		card_btn.visible = false
		main_pn.modulate = Color('585151')  # RGB values for red
		pass

func update_recommend():
	var x = g.v.game_constants.game_logic.check_can_win_card(self.id)
	if x == 1:
		recommend(true)
	elif x == 0:
		recommend(false)
	# -1 ignore
		
func _on_update_card_style():
	if face_state != g.v.game_constants.CARD_FACE_STATE.UP:
		return
	_load_texture_card()
	
func recommend(should_play = true):
	self.hint_pn.visible = true
	if should_play:
		self.hint_pn.rotation = 0
		self.hint_pn.modulate = Color('#00d337')
	else:
		self.hint_pn.rotation = deg_to_rad(180)
		self.hint_pn.modulate = Color('#ff110a')

func set_star():
	self.star_icon.visible = true
