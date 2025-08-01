extends Node


@onready var time_progress_bar: TextureProgressBar = find_child('TimeProgressBar')
@onready var empty_slot = find_child("EmptySlot")
@onready var main_pn = find_child("MainPn")
@onready var score_lb = find_child("ScoreLb")
@onready var vortex = find_child("Vortex")
@onready var avatar_img = find_child('AvatarImg')
@onready var emo_icon = find_child('EmoPlayer')
@onready var gold_lb = find_child("GoldLb")
@onready var bonus_info_pn = find_child("BonusInfo")
@onready var bonus_txt_lb = find_child("BonusTxtLb")
@onready var red_dot = find_child("RedDot")
@onready var bonus_info_colour = find_child("BonusInfoColour")
@onready var name_pn = find_child("NamePn")
@onready var name_lb = find_child("NameLb")
@onready var chat_tooltip = find_child("ChatTooltip")
@onready var vip_icon = find_child("VipIcon")
@onready var icon_stand = find_child("IconStand")
@onready var eff_gold_lb = find_child("EffGoldLb")
var default_pos_bonus
var is_me: bool = false
const TIME_THINKING_IN_TURN = 10
var default_pos_eff_gold
func _ready() -> void:
	chat_tooltip.visible = false

	name_pn.visible = true

	#effect_add_score(5)
	emo_icon.visible = false
	time_progress_bar.visible = false
	self.bonus_info_pn.visible = false
	default_pos_bonus = self.bonus_info_pn.position
	red_dot.visible = false
	vortex.visible = false
	icon_stand.visible = false
	default_pos_eff_gold = self.eff_gold_lb.position
	eff_gold_lb.visible = false
	g.v.signal_bus.connect_global('ingame_update_player_money', Callable(self, "_ingame_update_player_money"))

# Properties
var user_data: UserData


# Function to update properties
func set_user_data(user_dt: UserData) -> void:
	user_data = user_dt
	if not user_data or user_data.uid == -1:
		main_pn.visible = false
		empty_slot.visible = true
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
	
func update_state_ingame():
	if not user_data or user_data.uid == -1:
		#self.main_pn.modulate.a = 1
		return
	var g_mgr = g.v.sette_mezzo_mgr
	var is_game_playing = false
	if g_mgr.match_data.state == MatchData.MATCH_STATE.PLAYING \
		or g_mgr.match_data.state == MatchData.MATCH_STATE.BETTING:
			is_game_playing = true
	if is_game_playing and not user_data.game_data.is_in_game:
		self.main_pn.modulate.a = 0.5
	else:
		self.main_pn.modulate.a = 1

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
	elapsed_time = TIME_THINKING_IN_TURN - (g.v.sette_mezzo_mgr.play_turn_time - g.v.game_manager.get_timestamp_server())
	if elapsed_time < 0:
		elapsed_time = 0
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
		
		if elapsed_time < TIME_THINKING_IN_TURN:
			# Update progress bar value based on elapsed time
			time_progress_bar.value = (TIME_THINKING_IN_TURN - elapsed_time) \
				/ TIME_THINKING_IN_TURN * 100
			
			if user_data.uid == g.v.player_info_mgr.get_user_id():
				if g.v.scene_manager.INSTANCES.BOARD_SCENE.is_auto_play:
					if elapsed_time > 3:
						#g.v.scene_manager.INSTANCES.BOARD_SCENE.game_logic.auto_play_card()
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
		self.bonus_info_pn.position.x = default_pos_bonus.x - 230
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
	

var effect_burst = null
var burst_scene = preload("res://vfx/explosion/explosion.tscn")
func effect_bursted():
	if effect_burst == null:
		effect_burst = burst_scene.instantiate()
		self.add_child(effect_burst)
		effect_burst.z_index = 10
	g.v.sound_manager.play_bursted_sound()
	effect_burst.find_child("AnimationPlayer").play("Explode")
	pass

func effect_user_stand():
	icon_stand.visible = true
	icon_stand.modulate.a = 1
	icon_stand.scale = Vector2(0, 0)
	var tw = create_tween()
	tw.tween_property(
		icon_stand,
		"scale",
		Vector2(1, 1),
		0.4
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(
		icon_stand,
		"modulate:a",
		0,
		0.3		
	).set_delay(1)

var tw_eff_win_gold
func eff_win_gold(gold):
	if gold > 0:
		eff_gold_lb.modulate = Color("f3dd01")
		self.eff_gold_lb.text = "+" + StringUtils.symbol_number(gold)
	else:
		eff_gold_lb.modulate = Color("c4c4c4")
		self.eff_gold_lb.text = StringUtils.symbol_number(gold)
	self.eff_gold_lb.position = default_pos_eff_gold
	if tw_eff_win_gold and tw_eff_win_gold.is_running():
		tw_eff_win_gold.kill()
	tw_eff_win_gold = create_tween()
	eff_gold_lb.visible = true
	eff_gold_lb.modulate.a = 0
	tw_eff_win_gold.parallel().tween_property(
		self.eff_gold_lb,
		"modulate:a",
		1,
		0.1
	).set_delay(0.5)
	
	tw_eff_win_gold.parallel().tween_property(
		self.eff_gold_lb,
		"position",
		Vector2(default_pos_eff_gold.x, default_pos_eff_gold.y - 50),
		0.5
	).set_delay(0.5)
	tw_eff_win_gold.tween_property(
		self.eff_gold_lb,
		"modulate:a",
		0,
		0.3
	).set_delay(1)
