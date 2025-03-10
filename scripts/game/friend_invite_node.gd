extends Node

@onready var avatar_img = find_child("AvatarImg")
@onready var name_lb = find_child("NameLb")
@onready var invite_btn = find_child("InviteBtn")
var _info
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_info(inf: FriendModel):
	_info = inf
	
	avatar_img.set_avatar(_info.avatar)
	name_lb.text = _info.name
	
func _click_invite():
	invite_btn.visible = false
	g.v.game_manager.send_invite_friend_play(_info.uid)
