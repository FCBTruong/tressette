extends Node

@onready var name_lb = find_child("NameLb")
@onready var rank_lb = find_child("RankLb")
@onready var score_lb = find_child("ScoreLb")
@onready var avt_img = find_child("AvtImg")
@onready var rank_anim = find_child("RankAnim")
@onready var reward_pn = find_child("Reward")
@onready var reward_lb = find_child("RewardLb")
@onready var avatar_frame = find_child("AvatarFrame")
@onready var avatar_reward = find_child("AvatarReward")
# Called when the node enters the scene tree for the first time.
var info
func _ready() -> void:
	
	pass # Replace with function body.


func set_info(inf):
	self.info = inf
	if inf.rank <= 3:
		rank_lb.visible = false
		rank_anim.visible = true
		rank_anim.play(str(inf.rank))
		avatar_reward.visible = true
		var lb = avatar_reward.find_child("ExpireLb")
		if inf.rank == 1:
			lb.text = "7 " + tr("DAYS")
		elif inf.rank == 2:
			lb.text = "5 " + tr("DAYS")
		else:
			lb.text = "3 " + tr("DAYS")
	else:
		avatar_reward.visible = false
		rank_anim.visible = false
		rank_lb.visible = true
		rank_lb.text = str(inf.rank)
		
	name_lb.text = StringUtils.sub_string(inf.name, 19)
	avt_img.set_avatar(inf.avatar)
	avatar_frame.update_frame_by_id(inf.avatar_frame)
	
	inf.reward = g.v.ranking_mgr.get_reward(inf.rank)
	reward_pn.visible = inf.reward > 0
	if inf.reward > 0:
		reward_lb.text = StringUtils.symbol_number(inf.reward)
	score_lb.text = StringUtils.point_number(inf.score)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _click_info():
	g.v.friend_mgr.search_friend(info.uid)
