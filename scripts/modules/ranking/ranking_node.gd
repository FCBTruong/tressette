extends Node

@onready var name_lb = find_child("NameLb")
@onready var rank_lb = find_child("RankLb")
@onready var score_lb = find_child("ScoreLb")
@onready var avt_img = find_child("AvtImg")
@onready var rank_anim = find_child("RankAnim")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


func set_info(inf):
	if inf.rank <= 3:
		rank_lb.visible = false
		rank_anim.visible = true
		rank_anim.play(str(inf.rank))
	else:
		rank_anim.visible = false
		rank_lb.visible = true
		rank_lb.text = str(inf.rank)
		
	name_lb.text = StringUtils.sub_string(inf.name, 25)
	avt_img.set_avatar(inf.avatar)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
