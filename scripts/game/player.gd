extends Node


@onready var time_progress_bar: TextureProgressBar = find_child('TimeProgressBar')
@onready var empty_slot = find_child("EmptySlot")
@onready var main_pn = find_child("MainPn")
@onready var score_lb = find_child("ScoreLb")
@onready var vortex = find_child("Vortex")
@onready var avatar_img = find_child('AvatarImg')
@onready var emo_icon = find_child('EmoPlayer')
@onready var bonus_info_pn = find_child("BonusInfo")
@onready var bonus_txt_lb = find_child("BonusTxtLb")
@onready var red_dot = find_child("RedDot")
@onready var bonus_info_colour = find_child("BonusInfoColour")
@onready var name_pn = find_child("NamePn")
@onready var name_lb = find_child("NameLb")
@onready var chat_tooltip = find_child("ChatTooltip")
@onready var vip_icon = find_child("VipIcon")
@onready var invite_btn = find_child("InviteBtn")
@onready var join_btn = find_child("JoinBtn")
var default_pos_bonus
var is_me: bool = false
func _ready() -> void:
	chat_tooltip.visible = false
	#effect_add_score(5)
	emo_icon.visible = false
	time_progress_bar.visible = false
	self.bonus_info_pn.visible = false
	default_pos_bonus = self.bonus_info_pn.position
	red_dot.visible = false
	vortex.visible = false
	
	g.v.signal_bus.connect_global('ingame_update_player_money', Callable(self, "_ingame_update_player_money"))

# Properties
var user_data: UserData


# Function to update properties
func set_user_data(user_dt: UserData, is_viewing: bool = false) -> void:
	user_data = user_dt
	if not user_data or user_data.uid == -1:
		main_pn.visible = false
		empty_slot.visible = true
		if is_viewing:
			self.invite_btn.visible = false
			self.join_btn.visible = true
		else:
			self.invite_btn.visible = true
			self.join_btn.visible = false
		return
	red_dot.visible = false

	main_pn.visible = true
	empty_slot.visible = false
	
	vip_icon.visible = user_data.is_vip
	
	if name_lb.visible:
		name_lb.text = StringUtils.sub_string(user_data.name, 15)
	
	
	_update_gold()
	update_points_display()
	# update avatar
	print('userdatavat', user_data.avatar)
	if user_data.uid == g.v.player_info_mgr.my_user_data.uid:
		is_me = true
		avatar_img.set_me()
	
		# add red noti for if not yet click avatar pick
		
		if g.v.player_info_mgr.my_user_data.game_count < 10:
			var is_clicked_pick_avatar = g.v.storage_cache.fetch("open_picking_avatar_gui", '0') == '1'
			if not is_clicked_pick_avatar:
				red_dot.visible = true
				
	else:
		is_me = false
			
	avatar_img.set_avatar(user_data.avatar)

func _update_gold():
	return

func update_points_display(effect_add = false):
	pass
	#score_lb.text = str(user_data.game_data.points)


var elapsed_time: float = 0.0  # Tracks the elapsed time
var running: bool = false
var is_in_turn: bool = false

var did_alarm_clock = false
func start_timer():
	if self.user_data.uid == g.v.player_info_mgr.my_user_data.uid:
		g.v.scene_manager.INSTANCES.BOARD_SCENE.play_sound_my_turn()
		did_alarm_clock = false
	time_progress_bar.visible = true
	elapsed_time = 0.0
	running = true
	time_progress_bar.value = 0
	vortex.visible = true
func on_turn():
	is_in_turn = true
	start_timer()
	
func end_turn():
	is_in_turn = false
	end_timer()
	
func _process(delta: float):
	if not self.user_data:
		return
	if self.user_data.uid == -1:
		time_progress_bar.visible = false
		vortex.visible = false
		return
		
	if running:
		elapsed_time += delta
		
		if elapsed_time < g.v.game_server_config.time_thinking_in_turn:
			# Update progress bar value based on elapsed time
			time_progress_bar.value = (g.v.game_server_config.time_thinking_in_turn - elapsed_time) \
				/ g.v.game_server_config.time_thinking_in_turn * 100
			
			if user_data.uid == g.v.player_info_mgr.get_user_id():
				if g.v.scene_manager.INSTANCES.BOARD_SCENE.is_auto_play:
					if elapsed_time > 3:
						g.v.scene_manager.INSTANCES.BOARD_SCENE.game_logic.auto_play_card()
						end_timer()
				var time_remain = g.v.game_server_config.time_thinking_in_turn - elapsed_time
				if time_remain < 5 and not did_alarm_clock:
					did_alarm_clock = true
					var board = g.v.scene_manager.get_current_scene()
					if board is BoardScene:
						board.on_alarm_clock()
		else:
			end_timer(true)

func get_user_data() -> UserData:
	return user_data
	
func end_timer(out_time=false):
	running = false
	if out_time and user_data.uid == g.v.player_info_mgr.get_user_id():
		g.v.scene_manager.INSTANCES.BOARD_SCENE.user_not_play_turn()
	time_progress_bar.visible = false
	vortex.visible = false

var effect_add_score_scene = preload('res://scenes/board/AddScoreEffect.tscn')
func effect_add_score(score):
	if score <= 0:
		return
	var main = score / 3
	var sub = score % 3
	# send auto play to server
	var eff = effect_add_score_scene.instantiate()
	self.add_child(eff)
	eff.find_child('MainLb').text = str(main) if main > 0 else ''
	eff.find_child('SubLb').text = str(sub)
	eff.find_child('Sub').visible = true if sub > 0 else false
	var x = 70
	if self.global_position.x > get_viewport().get_visible_rect().size.x / 2:
		x = -120
	var default_pos = Vector2(x, 0)
	eff.position = default_pos
	var n_pos = Vector2(x, -50)
	var tween = create_tween()
	tween.tween_property(eff, 'position', n_pos, 0.5)
	tween.tween_property(eff, 'modulate:a', 0, 0.5)
	tween.tween_callback(eff.queue_free)


func _show_info():
	if is_me:
		red_dot.visible = false
	g.v.friend_mgr.search_friend(user_data.uid)

var tween_emo
func show_emotion(emo_id):
	if tween_emo and tween_emo.is_running():
		tween_emo.kill()
	emo_icon.play(str(emo_id))

	emo_icon.visible = true
	tween_emo = create_tween()
	var tween = tween_emo
	emo_icon.scale = Vector2(0, 0)
	emo_icon.modulate.a = 1
	tween.parallel().tween_property(
		emo_icon, 'scale', Vector2(0.85, 0.85), 0.4
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(
		emo_icon, 'modulate:a', 0, 0.4
	).set_delay(2)
	

func _get_gold_str(gold) -> String:
	var str = StringUtils.point_number(gold)
	if gold > 100000000:
		str = StringUtils.symbol_number(gold)
	return str

func _click_open_invite_gui() -> void:
	g.v.scene_manager.open_gui("res://scenes/board/FriendInviteGUI.tscn")
	pass
	
func _click_join_game() -> void:
	var scene = g.v.scene_manager.get_current_scene()
	if scene is BoardScene:
		scene.stop_view_join_game()
	pass
	
var tw_bonus
func show_bonus(txt, type=0): # last trick
	if type == 0:
		self.bonus_info_colour.color = Color('288019')
	else:
		self.bonus_info_colour.color = Color('1d7fff')
		# napoli
	var p = self.global_position
	var screen_size_width = get_viewport().get_visible_rect().size.x
	
	self.bonus_info_pn.pivot_offset = Vector2(0, 0)
	if p.x > screen_size_width / 2:
		# player in the left
		self.bonus_info_pn.position.x = default_pos_bonus.x - 225
		self.bonus_info_pn.pivot_offset = Vector2(bonus_info_pn.size.x, 0)
	else:
		self.bonus_info_pn.position = default_pos_bonus

	if tw_bonus and tw_bonus.is_running():
		tw_bonus.kill()
	tw_bonus = create_tween()
	self.bonus_info_pn.visible = true
	self.bonus_info_pn.modulate.a = 0
	self.bonus_info_pn.scale = Vector2(0, 0)
	bonus_txt_lb.text = txt
	tw_bonus.parallel().tween_property(self.bonus_info_pn, 'modulate:a', 1, 0.3)
	tw_bonus.parallel().tween_property(self.bonus_info_pn, 'scale', Vector2(1, 1), 0.3)
	tw_bonus.tween_interval(0)
	tw_bonus.parallel().tween_property(self.bonus_info_pn, 'modulate:a', 0, 0.3).set_delay(2)
	tw_bonus.tween_callback(
		func():
			self.bonus_info_pn.visible = false
	).set_delay(2)
	pass


func show_napoli(s, suits):
	self.show_bonus(s, 1)
	var arr_pos = []
	if len(suits) == 1:
		arr_pos = [Vector2(0, 0)]
	elif len(suits) == 2:
		arr_pos = [Vector2(-25, 0), Vector2(25, 0)]
	else:
		arr_pos = [Vector2(-50, 0), Vector2(0, 0), Vector2(50, 0)]
	var i = 0
	for n in suits:
		var card = g.v.scene_manager.INSTANCES.BOARD_SCENE.card_scene.instantiate()
		card.scale = Vector2(0, 0)
		card.position = arr_pos[i]
		card.set_card(n)
		self.add_child(card)
		card.turn_face_up()
		
		var tw = create_tween()
		tw.tween_property(card, 'scale', Vector2(0.6, 0.6), 0.2)
		tw.tween_property(card, 'modulate:a', 0, 0.2).set_delay(1.5)
		tw.tween_callback(
			func():
				card.queue_free()
		)
		i += 1


func _ingame_update_player_money(uid):
	if uid == user_data.uid:
		print('user ' + str(uid) + 'update money')
		_update_gold()
	pass


var chat_tw
func on_chat(text):
	if chat_tw and chat_tw.is_running():
		chat_tw.kill()
	chat_tooltip.visible = true
	var str = StringUtils.sub_string(text, 30)
	var content_lb = chat_tooltip.find_child("ChatContent")
	content_lb.text = str
	#await get_tree().process_frame
	var content_size = content_lb.get_minimum_size()
	var pn = chat_tooltip.find_child("Panel")
	pn.size.x = content_size.x + 60
	pn.position.x = -pn.size.x / 2
	chat_tw = create_tween()
	chat_tooltip.scale = Vector2(0, 0)
	chat_tw.tween_property(chat_tooltip, 'scale', Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	chat_tw.tween_property(chat_tooltip, 'scale', Vector2(0, 0), 0.3).set_delay(2)
	pass
