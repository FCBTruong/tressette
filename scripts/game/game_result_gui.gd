extends Node


var list_players = []
@onready var TitleLb = find_child('TitleLb')
@onready var MainPn = find_child('MainPn')
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(4):
		list_players.append(find_child('PlayerResult' + str(i + 1)))
	update_result(GameConstants.game_logic.match_result)
	
	MainPn.scale = Vector2(0, 0)
	var tween = create_tween()
	tween.tween_property(MainPn, 'scale', Vector2(1, 1), 0.5).set_ease(Tween.EASE_IN_OUT)
	pass # Replace with function body.


func update_result(data):
	if data.is_win:
		TitleLb.text = 'You Win'
		TitleLb.add_theme_color_override("font_color", Color('ff9744'))  # RGB for red
	else:
		TitleLb.add_theme_color_override("font_color", Color('3f414a'))  # RGB for red
		TitleLb.text = 'You Lose'

		
	for p in list_players:
		p.visible = false
	var i = 0
	for d in data.scores:
		_update_player(list_players[i], d)
		i += 1

func _update_player(p, data):
	p.visible = true
	p.find_child('ScoreCard').text = str(data.score_card)
	p.find_child('ScoreLastTrick').text = str(data.score_last_trick)
	p.find_child('ScoreTotal').text = str(data.score_total)
	
func _click_continue_play():
	queue_free()
	pass
	
func _click_exit_game():
	GameManager.send_register_leave_game()
	pass
