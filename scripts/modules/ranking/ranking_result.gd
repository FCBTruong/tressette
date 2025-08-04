extends Node

var season_id
@onready var rank_lb = find_child("RankLb")
@onready var rank_anim = find_child("RankAnim")
@onready var reward_lb = find_child("RewardLb")
@onready var main_pn = find_child("MainPn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NodeUtils.set_center_pivot(self.main_pn)
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func set_info(season_id, rank, gold_reward):
	self.season_id = season_id
	if rank <= 3:
		rank_lb.visible = false
		rank_anim.visible = true
		rank_anim.play(str(rank))
		find_child("AvatarReward").visible = true
	else:
		rank_lb.visible = true
		rank_anim.visible = false
		rank_lb.text = str(rank)
		find_child("AvatarReward").visible = false
	reward_lb.text = StringUtils.point_number(gold_reward)

func click_claim():
	g.v.ranking_mgr.send_claim_reward(self.season_id)
	self.queue_free()
	pass
