extends Node


var list_players = []
var win_team_id
var my_team_id
@onready var TitleLb = find_child('TitleLb')
@onready var MainPn = find_child('MainPn')
@onready var players_pn = find_child("PlayersPn")
@onready var crown_icon = find_child('CrownIcon')
@onready var gold_result_lb = find_child("GoldResult")
@onready var player_result_node_scene = preload("res://scenes/board/PlayerResultNode.tscn")
@onready var continue_timer = find_child("ContinueTimer")
@onready var continue_time_lb = find_child("ContinueTimeLb")
@onready var continue_time_node = find_child("ContinueTimeNode")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_result(GameConstants.game_logic.match_result)
	
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
			continue_timer.connect("timeout", Callable(self, "_click_continue_play"))
			continue_timer.start()
			
	).set_delay(2)
	
	pass # Replace with function body.

func _process(delta: float) -> void:
	self.continue_time_lb.text = str(int(continue_timer.time_left))
	
func update_result(data: MatchData.MatchResult):
	win_team_id = data.win_team_id
	my_team_id = data.my_team_id
	if data.is_win:
		SoundManager.play_win_congrat_sound()
		TitleLb.text = tr("YOU_WIN")
		TitleLb.add_theme_color_override("font_color", Color('ff9744'))  # RGB for red
	else:
		TitleLb.add_theme_color_override("font_color", Color('b3b3b3'))  # RGB for red
		TitleLb.text = tr("YOU_LOSE")
		
	var i = 0
	
	for child in players_pn.get_children():
		child.queue_free()
		
	var list = []
	for d in data.players:	
		var p = player_result_node_scene.instantiate()	
		list.append(p)
		players_pn.add_child(p)
		
		_update_player(p, d)
		i += 1
	
	var gold_change = data.gold_change
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
	var str = "[center]@num[/center]"
	if value >= 0:
		str = str.replace("@num", "+" + StringUtils.point_number(value))
	else:
		str = "[center][color=b8b8b8]@num[/color][/center]"
		str = str.replace("@num", StringUtils.point_number(value))
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
		# Set green border
		avt_border.self_modulate = Color('17a03a')  # Green (R, G, B format)
	elif avt_border:
		# Set red border
		avt_border.self_modulate = Color('dc2b3a')  # Red (R, G, B format)

		
	avt_img.set_avatar(data.avatar)
	
func _click_continue_play():
	queue_free()
	
	# continue play
	var scene = SceneManager.get_current_scene()
	if scene is BoardScene:
		scene.continue_play()
	pass
	
func _click_exit_game():
	GameManager.send_register_leave_game()
	pass
