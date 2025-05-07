extends Control
@onready var main_pn = find_child("MainPn")
@onready var list_player = find_child("ListPlayer")
@onready var time_lb = find_child("TimeLb")
@onready var my_name_lb = find_child("MyNameLb")
@onready var my_score_lb = find_child("ScoreLb")
@onready var my_rank_lb = find_child("RankLb")
@onready var my_reward_lb = find_child("RewardLb")
@onready var my_rank_anim = find_child("RankAnim")
@onready var reward_pn = find_child("Reward")
var list_nodes = []
var main_pos
var ranking_player_scene = preload("res://scenes/ranking/RankingPlayer.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_pos = main_pn.position
	for i in range(10):
		var n = ranking_player_scene.instantiate()
		list_player.add_child(n)
		list_nodes.append(n)
		n.visible = false

var tween
func on_show():
	self.show()
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	main_pn.position.y = main_pos.y - 600
	tween.parallel().tween_property(main_pn, 'position', main_pos, 0.4)

	self.update_info()
	
func update_info():
	var i = 0
	for u in g.v.ranking_mgr.list_users:
		if i >= len(list_nodes):
			break
		list_nodes[i].set_info(u)
		list_nodes[i].visible = true
		i += 1
	my_name_lb.text = g.v.player_info_mgr.my_user_data.name
	if g.v.ranking_mgr.my_rank <= 3:
		my_rank_lb.visible = false
		my_rank_anim.visible = true
		my_rank_anim.play(str(g.v.ranking_mgr.my_rank))
		pass
	else:
		my_rank_lb.visible = true
		my_rank_anim.visible = false
		my_rank_lb.text = StringUtils.point_number(g.v.ranking_mgr.my_rank)
		
	my_score_lb.text = StringUtils.point_number(g.v.ranking_mgr.my_score)
	
	var reward = g.v.ranking_mgr.get_reward(g.v.ranking_mgr.my_rank)
	if reward > 0:
		reward_pn.visible = true
		my_reward_lb.text = StringUtils.symbol_number(reward)
	else:
		reward_pn.visible = false
	g.v.ranking_mgr.check_and_update()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not visible:
		return
	var time_remain = int(g.v.ranking_mgr.time_end - g.v.game_manager.get_timestamp_server())
	var days = time_remain / 86400
	var hours = (time_remain % 86400) / 3600
	var minutes = (time_remain % 3600) / 60
	var seconds = time_remain % 60

	var parts = []
	if days > 0:
		parts.append("%dd" % days)
	if hours > 0 or days > 0:  # Always show hours if there are days
		parts.append("%dh" % hours)
	if minutes > 0 or days == 0:  # Always show minutes if no days
		parts.append("%dm" % minutes)
	#if days == 0:  # Show seconds if less than a day
	parts.append("%ds" % seconds)

	var str_time = ":".join(parts)
	self.time_lb.text = str_time



func _on_close():
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.parallel().tween_property(main_pn, 'position:y', main_pos.y - 700, 0.3)
	tween.tween_callback(
		func():
			self.hide()
	).set_delay(0.3)
