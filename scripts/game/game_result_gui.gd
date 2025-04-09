extends Node


var list_players = []
var win_team_id
var my_team_id
@onready var TitleLb = find_child('TitleLb')
@onready var MainPn = find_child('MainPn')
@onready var players_pn = find_child("PlayersPn")
@onready var crown_icon = find_child('CrownIcon')
@onready var gold_result_lb_win = find_child("GoldResultWin")
@onready var gold_result_lb_lose = find_child("GoldResultLose")
@onready var player_result_node_scene = preload("res://scenes/board/PlayerResultNode.tscn")
@onready var continue_timer = find_child("ContinueTimer")
@onready var continue_time_lb = find_child("ContinueTimeLb")
@onready var continue_time_node = find_child("ContinueTimeNode")
@onready var win_pn = find_child("WinPn")
@onready var lose_pn = find_child("LosePn")
var gold_result_lb = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
func on_show():
	self.visible = true
	if g.v.app_version.is_in_review():
		gold_result_lb_lose.visible = false
		gold_result_lb_win.visible = false
		find_child("TitleLbLose").position.y += 170
		find_child("TitleLb").position.y += 170
	update_result(g.v.game_constants.game_logic.match_result)
	
	MainPn.scale = Vector2(0, 0)
	var tween = create_tween()
	tween.parallel().tween_property(MainPn, 'scale', Vector2(1, 1), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	TitleLb.scale = Vector2(3, 3)
	tween.parallel().tween_property(TitleLb, 'scale', Vector2(1, 1), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
		.set_delay(0.5)
	
	TitleLb.modulate.a = 0
	tween.parallel().tween_property(TitleLb, 'modulate:a', 1, 0.5) \
		.set_delay(0.5)
	
	continue_time_node.visible = false
	tween.parallel().tween_callback(
		func ():
			continue_time_node.visible = true
			continue_timer.connect("timeout", Callable(self, "_process_continue"))
			continue_timer.start()
			
	)
	
	MainPn.pivot_offset = Vector2(MainPn.size / 2)

func _process(delta: float) -> void:
	continue_time_node.value = continue_timer.time_left / 6 * 100
	self.continue_time_lb.text = str(int(continue_timer.time_left))
	
func update_result(data: MatchData.MatchResult):
	win_team_id = data.win_team_id
	my_team_id = data.my_team_id
	var gold_change = 0
	if data.is_win:
		gold_result_lb = gold_result_lb_win
		gold_change = data.gold_win
		# Set green border
		win_pn.visible = true
		lose_pn.visible = false
		g.v.sound_manager.play_win_congrat_sound()
	else:
		gold_result_lb = gold_result_lb_lose
		gold_change = data.gold_lose
		g.v.sound_manager.play_lose_sound()
		# Set green border
		win_pn.visible = false
		lose_pn.visible = true

	
	var tween_gold = create_tween()
	var time_run = 1.5
	if abs(gold_change) > 10000000: # 10M
		time_run = 1.5
	elif abs(gold_change) > 5000000:
		time_run = 1.2
	elif abs(gold_change) >= 500000:
		time_run = 1.1
	else:
		time_run = 1
	tween_gold.tween_method(set_int_to_text.bind(gold_result_lb, true), 0, gold_change, time_run)

func set_int_to_text(value: int, label, add: bool = false) -> void:
	var str
	if value >= 0:
		str = "+" + StringUtils.point_number(value)
	else:
		str = StringUtils.point_number(value) 
	label.text = str


func _update_player(p, data: MatchData.MatchResultPlayer):
	print('update player...')
	p.visible = true
	p.find_child('ScoreCard').text = str(int(data.score_card / 3))
	p.find_child('ScoreLastTrick').text = str(int(data.score_last_trick / 3))
	p.find_child('ScoreTotal').text = str(int(data.score_total / 3))
	var avt = p.find_child("AvatarCircle")
	var avt_img = p.find_child("AvatarImg")
	var avt_border = p.find_child("AvtBorder")
	if avt_border and data.team_id == my_team_id:
		avt_border.self_modulate = Color('17a03a')  # Green (R, G, B format)
	elif avt_border:
		avt_border.self_modulate = Color('dc2b3a')  # Red (R, G, B format)

		
	avt_img.set_avatar(data.avatar)
	
func _click_continue_play():
	var scene = g.v.scene_manager.get_current_scene()
	if scene is BoardScene:
		scene.is_auto_play = false
		
	self._process_continue()

	
func _process_continue():
	# send to server that this user is ready to play
	g.v.game_manager.user_ready_match()
	
	continue_timer.stop()
	self.visible = false
	
	# continue play
	var scene = g.v.scene_manager.get_current_scene()
	if scene is BoardScene:
		scene.continue_play()
	
	if g.v.game_manager.is_enable_ads() and g.v.player_info_mgr.my_user_data.game_count > 3:
		if g.v.game_manager.game_th % 4 == 0:
			g.admob_mgr._on_interstitial_pressed()
			#g.admob_mgr._on_reward_interstitial_pressed()
		else:
			g.admob_mgr._on_interstitial_pressed()
func _click_exit_game():
	self.visible = false
	g.v.game_manager.send_register_leave_game()
	if g.v.game_manager.is_enable_ads():
		#g.admob_mgr._on_reward_pressed()
		g.admob_mgr._on_interstitial_pressed()
	pass
