extends Node

var season_id
@onready var rank_lb = find_child("RankLb")
@onready var rank_anim = find_child("RankAnim")
@onready var reward_lb = find_child("RewardLb")
@onready var main_pn = find_child("MainPn")
@onready var light = find_child("Light")
@onready var confettie = find_child("Confettie")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NodeUtils.set_center_pivot(self.main_pn)
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)
	
	confettie.play()
	var tw_light = create_tween()

	# Start fully transparent
	light.modulate.a = 0.0

	# Wait 0.5 seconds
	tw_light.tween_interval(0.5)

	# Fade in (alpha 1.0) over 1 second
	tw_light.tween_property(light, "modulate:a", 1.0, 1.0)

	# Rotate forever (360° in 5 seconds, loops infinitely)
	var rotate_tween = create_tween().set_loops()
	rotate_tween.tween_property(light, "rotation_degrees", light.rotation_degrees + 360.0, 5.0).as_relative()


	g.v.sound_manager.play_win_congrat_sound()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

var has_item_reward = false
func set_info(season_id, rank, gold_reward):
	self.season_id = season_id
	has_item_reward = false
	if rank <= 3:
		rank_lb.visible = false
		rank_anim.visible = true
		rank_anim.play(str(rank))
		find_child("AvatarReward").visible = true
		has_item_reward = true
	else:
		rank_lb.visible = true
		rank_anim.visible = false
		rank_lb.text = str(rank)
		find_child("AvatarReward").visible = false
	reward_lb.text = StringUtils.point_number(gold_reward)

func click_claim():
	g.v.ranking_mgr.send_claim_reward(self.season_id)
	self.queue_free()
	if has_item_reward:
		g.v.inventory_mgr.open_gui()
	pass
