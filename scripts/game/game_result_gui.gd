extends Node


var list_players = []
var win_team_id
var my_team_id
@onready var TitleLb = find_child('TitleLb')
@onready var MainPn = find_child('MainPn')
@onready var player_result_node_scene = preload("res://scenes/board/PlayerResultNode.tscn")
@onready var continue_timer = find_child("ContinueTimer")
@onready var continue_time_lb = find_child("ContinueTimeLb")
@onready var continue_time_node = find_child("ContinueTimeNode")
@onready var win_pn = find_child("WinPn")
@onready var lose_pn = find_child("LosePn")
@onready var eff_win = find_child("EffWin")
@onready var eff_lose = find_child("EffLose")


@onready var my_team_score_lb = find_child("MyTeamScoreLb")
@onready var opp_score_lb = find_child("OppScoreLb")
@onready var player1_team1 = find_child("Player1Team1")
@onready var player2_team1 = find_child("Player2Team1")
@onready var player1_team2 = find_child("Player1Team2")
@onready var player2_team2 = find_child("Player2Team2")
@onready var eff_rotate_light = find_child("EffRotateLight")
@onready var hbox_rewards = find_child("HBoxRewards")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
func on_show():
	self.visible = true

	update_result(g.v.game_constants.game_logic.match_result)
	
	MainPn.scale = Vector2(0, 0)
	var tween = create_tween()
	tween.parallel().tween_property(MainPn, 'scale', Vector2(1, 1), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	eff_win.scale = Vector2(3, 3)
	tween.parallel().tween_property(eff_win, 'scale', Vector2(1, 1), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(0.2)
	
	eff_win.modulate.a = 0
	tween.parallel().tween_property(eff_win, 'modulate:a', 1, 0.5).set_delay(0.2)
		
	
	continue_time_node.visible = false
	tween.parallel().tween_callback(
		func ():
			continue_time_node.visible = true
			continue_timer.connect("timeout", Callable(self, "_process_continue"))
			continue_timer.start()
			
	)
	
	MainPn.pivot_offset = Vector2(MainPn.size / 2)

func _process(_delta: float) -> void:
	continue_time_node.value = continue_timer.time_left / 6 * 100
	self.continue_time_lb.text = str(int(continue_timer.time_left))
	
func update_result(data: MatchData.MatchResult):
	win_team_id = data.win_team_id
	my_team_id = data.my_team_id
	var my_score = int(data.my_team_score / 3)
	var opp_score = int(data.opp_score / 3)
	my_team_score_lb.text = str(my_score)
	opp_score_lb.text = str(opp_score)
	var gold_change = 0
	eff_win.visible = false
	eff_lose.visible = false
	if data.is_win:
		g.v.sound_manager.play_win_congrat_sound()
		eff_win.visible = true
		eff_rotate_light.visible = true
	else:
		g.v.sound_manager.play_lose_sound()
		eff_lose.visible = true
		eff_rotate_light.visible = false
	
	var t1 = 0
	var t2 = 0
	player1_team1.visible = false
	player2_team1.visible = false
	player1_team2.visible = false
	player2_team2.visible = false
	player1_team1.find_child("WinnerImgDouble").visible = false
	player1_team1.find_child("WinnerImg").visible = false
	player1_team2.find_child("WinnerImgDouble").visible = false
	player1_team2.find_child("WinnerImg").visible = false
	var is_double = len(data.players) > 2
	for p in data.players:
		var n
		if p.team_id == 0:
			if t1 == 0:
				n = player1_team1
				t1 = 1
				if p.team_id == data.win_team_id:
					if is_double:
						n.find_child("WinnerImgDouble").visible = true
					else:
						n.find_child("WinnerImg").visible = true
			else:
				n = player2_team1
		else:
			if t2 == 0:
				t2 = 1
				n = player1_team2
				if p.team_id == data.win_team_id:
					if is_double:
						n.find_child("WinnerImgDouble").visible = true
					else:
						n.find_child("WinnerImg").visible = true
			else:
				n = player2_team2
		n.visible = true
		var avt_img = n.find_child("AvatarImg")
		var avt_frame = n.find_child("AvatarFrame")
		avt_img.set_avatar(p.avatar)
		avt_frame.update_frame_by_id(p.avatar_frame)
	
	NodeUtils.remove_all_child(hbox_rewards)
	for r in data.rewards:
		var n = result_reward_node_scene.instantiate()
		hbox_rewards.add_child(n)
		n.find_child("Label").text = StringUtils.point_number(r.value)
		if r.duration > 0:
			n.find_child("Label").text = str(r.duration) + " " + tr("DAYS")
		n.find_child("TextureRect").texture = load(g.v.inventory_mgr.get_image_item(r.item_id))


var result_reward_node_scene = preload("res://scenes/board/ResultRewardNode.tscn")	


func set_int_to_text(value: int, label, add: bool = false) -> void:
	if not is_instance_valid(label):
		return
	var str = ''
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
	
	#if g.v.game_manager.is_enable_ads() and g.v.player_info_mgr.my_user_data.game_count > 3:
		#if g.v.game_manager.game_th % 3 == 0:
			#g.admob_mgr._on_interstitial_pressed()
	
func _click_exit_game():
	self.visible = false
	g.v.game_manager.send_register_leave_game()
	if g.v.game_manager.is_enable_ads():
		#g.admob_mgr._on_reward_pressed()
		g.admob_mgr._on_interstitial_pressed()
	pass
