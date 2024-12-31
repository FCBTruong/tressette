extends Node


# Called when the node enters the scene tree for the first time.
var my_card_panel
var play_ground
var list_my_cards = []
var list_players = []
var _cur_focusing_card = null
var place_card_node = null
var tween: Tween
var tween_animate: Tween
@onready var players_pn = find_child("PlayersPn")
@onready var center_play_pn = find_child('CenterPlayPn')
@onready var cardback_node = find_child('CardBack')
@onready var seat_pos0 = find_child('PlayerPos0')
@onready var seat_pos1 = find_child('PlayerPos1')
@onready var seat_pos2 = find_child('PlayerPos2')
@onready var seat_pos3 = find_child('PlayerPos3')
@onready var place_card0 = find_child('PlaceCard0')
@onready var place_card1 = find_child('PlaceCard1')
@onready var place_card2 = find_child('PlaceCard2')
@onready var place_card3 = find_child('PlaceCard3')

var card_scene = preload("res://scenes/board/Card.tscn")

func _ready() -> void:
	SceneManager.INSTANCES.BOARD_SCENE = self
	my_card_panel = find_child('MyCardPanel')
	play_ground = find_child('PlayGround')
	place_card_node = find_child('PlaceCard1')
	
	_init_my_cards()
	_on_enter()
	
func _on_enter():
	var players_info = GameConstants.game_logic.get_list_player()
	var i = 0
	for p in list_players:	
		p.queue_free()
	_create_players(GameConstants.game_logic.match_data.player_mode)
	for info in players_info:
		list_players[i].set_user_data(info)
		i += 1
	update_player_seat()
	pass
	
# Function to create players
func _create_players(player_count: int) -> void:
	var player_scene = load("res://scenes/board/Player.tscn")  # Load player scene
	
	for i in range(player_count):
		var player_instance = player_scene.instantiate()  # Create a new player instance
		player_instance.name = "Player_%d" % i  # Name the player nodes uniquely
		
		# Add to the current scene
		players_pn.add_child(player_instance)
		list_players.append(player_instance)

func update_player_seat():
	for player in list_players:
		var seat_id = player.user_data.game_data.seat_id
		var pos = _get_seat_position(GameConstants.game_logic.match_data.player_mode, seat_id)
		player.global_position = pos
		
func _get_seat_position(mode_player: int, seat_id: int):
	if mode_player == GameConstants.PLAYER_MODE.SOLO:
		match seat_id:
			0: 
				return seat_pos0.global_position
			1:
				return seat_pos2.global_position
		return
	match seat_id:
		0: 
			return seat_pos0.global_position
		1:
			return seat_pos1.global_position
		2:
			return seat_pos2.global_position
		3: 
			return seat_pos3.global_position
	return null
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func back_to_lobby() -> void:
	GameManager.request_leave_game()
	
func _init_my_cards() -> void:
	return
	list_my_cards = []
	for i in range(10):
		var card = card_scene.instantiate()
		my_card_panel.add_child(card)
		list_my_cards.append(card)
		card.set_card(i)
		card._set_default_z_index(i)
	
	# Update position
	_update_my_card_positions()

func _update_my_card_positions():
	var list = []
	for card in list_my_cards:
		if card.is_played:
			continue
		list.append(card)
		
	var list_pos = _calculate_world_card_positions(len(list))
	for i in range(len(list)):
		var card = list[i]
		card.global_position = list_pos[i]
		
func _open_chat_gui() -> void:
	SceneManager.open_gui("res://scenes/board/GameChatGUI.tscn")

func on_focus_card(card_id: int) -> void:
	var card = _get_my_card(card_id)
	if card.is_played:
		return
	if _cur_focusing_card:
		_cur_focusing_card.set_state_focusing(false)
	if _cur_focusing_card == card:
		_cur_focusing_card = null
		return
	_cur_focusing_card = card
	card.set_state_focusing(true)

func _get_my_card(id):
	for i in range(len(list_my_cards)):
		var c = list_my_cards[i]
		if c.get_card_id() == id:
			return c
	return null
	
func play_my_card(id: int):
	print("play_a_card", id)
	var card = _get_my_card(id)
	if not card:
		print('not found card')
		return
	
	card.is_played = true
	_cur_focusing_card = null
	
	# Animate the card moving to (0, 0)
	var tween = create_tween()
	var p_place_world = place_card_node.global_position
	tween.tween_property(card, "global_position",p_place_world, 0.3)
	_update_my_card_positions()
	
func _on_click_btn_play_card():
	if _cur_focusing_card:
		play_my_card(_cur_focusing_card.get_card_id())

func _calculate_world_card_positions(number: int):
	var list_pos = []
	var p_center = Vector2(my_card_panel.size.x / 2, my_card_panel.size.y / 2)
	var distance = 90
	
	# Calculate positions for each not-played card, centering around p_center
	var index = 0
	var mid = (number - 1) / 2.0
	for i in range(number):
		var pos = Vector2()
		pos.x = p_center.x + (index - mid) * distance
		pos.y = p_center.y
		
		var global_pos = my_card_panel.get_global_transform().origin + pos
		list_pos.append(global_pos)
		index += 1
	
	return list_pos
	
@export var card_offset_x: float = 20.0
@export var rot_max: float = 19.0
@export var anim_offset_y: float = 0.3
var sine_offset_mult: float = 0.0

func remove_all_current_cards():
	for card in list_my_cards:
		card.queue_free()
	list_my_cards.clear()
		
func draw_cards(from_pos: Vector2, number: int) -> void:
	remove_all_current_cards()
	list_my_cards = []
	var drawn = true
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	var list_pos_des = _calculate_world_card_positions(number)
	for i in range(number):
		var instance = card_scene.instantiate()
		play_ground.add_child(instance)
		instance.set_card(i)
		instance.turn_face_down()
		list_my_cards.append(instance)
		instance.global_position = from_pos
		
		# -(instance.size / 2.0) to center the card
		var final_pos: Vector2 = list_pos_des[i]
		# offset to the right everything has we are going to place cards to the left
		final_pos.x += ((card_offset_x * (number-1)) / 2.0)
		
		#print("Offset: ", float(i)/float(number-1))
		var rot_radians: float = lerp_angle(-rot_max, rot_max, float(i)/float(number-1))
		#print("Rot: ", rot_radians)
		#print("Card %d: , size: %s, pivot: %s" % [i, str(instance.size), str(instance.pivot_offset)])
		
		# Animate pos
		tween.parallel().tween_property(instance, "position", final_pos, 0.3 + (i * 0.075))
		tween.parallel().tween_property(instance, "rotation", rot_radians, 0.3 + (i * 0.075))
		
		# cal instance.show_card(true) after arrived
			# Schedule card flip after animation finishes
		tween.parallel().tween_callback(func():
			instance.show_card(true)
		).set_delay(0.3 + (i * 0.075))
	
	tween.tween_callback(set_process.bind(true))
	tween.tween_property(self, "sine_offset_mult", anim_offset_y, 1.5).from(0.0)

func play_card(user_id: int, card_id: int):
	print("user " + str(user_id) + "play_a_card", card_id)
	if user_id == PlayerInfoMgr.my_user_data.uid:
		play_my_card(card_id)
		return

	var card_instance = card_scene.instantiate()
	play_ground.add_child(card_instance)
	var player_node = get_player_node_by_uid(user_id)
	if not player_node:
		return
	card_instance.global_position = player_node.global_position
	
	# Animate the card moving to (0, 0)
	var tween = create_tween()
	var p_place_world = get_place_pos_card(player_node.user_data.game_data.seat_id)
	tween.tween_property(card_instance, "global_position",p_place_world, 0.3)
	_update_my_card_positions()
	
func get_place_pos_card(seat_id: int) -> Vector2:
	if seat_id == 0:
		return place_card0.global_position
	elif seat_id == 1:
		return place_card1.global_position
	elif seat_id == 2:
		return place_card2.global_position
	else:
		return place_card3.global_position

func get_player_node_by_uid(user_id: int):
	for p in list_players:
		if p.get_user_data().uid == user_id:
			return p
	return null
func test_deal_card():
	draw_cards(cardback_node.global_position, 10)
	return

func test_play_playercard():
	play_card(4, 3)
	return
