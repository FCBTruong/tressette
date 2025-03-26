extends Node
@onready var main_pn = find_child("MainPn")
@onready var list_player = find_child("ListPlayer")
@onready var time_lb = find_child("TimeLb")
@onready var my_name_lb = find_child("MyNameLb")
@onready var my_score_lb = find_child("ScoreLb")
@onready var my_rank_lb = find_child("RankLb")
@onready var my_reward_lb = find_child("RewardLb")
@onready var my_rank_anim = find_child("RankAnim")
@onready var reward_pn = find_child("Reward")
var ranking_player_scene = preload("res://scenes/ranking/RankingPlayer.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var pos = main_pn.position
	var tween = create_tween()
	main_pn.position.y  -= 500
	#main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'position', pos, 0.3)
	#tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
	for u in g.v.ranking_mgr.list_users:
		var n = ranking_player_scene.instantiate()
		list_player.add_child(n)
		n.set_info(u)
		
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
	self.queue_free()
