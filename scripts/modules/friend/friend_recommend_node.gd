extends Node

@onready var avatar_img = find_child('AvatarImg')
@onready var name_lb = find_child("NameLb")
@onready var gold_lb = find_child("GoldLb")
@onready var add_btn = find_child('AddBtn')
var _info = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _click_add_friend():
	g.v.friend_mgr.send_add_friend(_info.uid)
	self.queue_free()

func set_info(f: FriendModel):
	_info = f
	name_lb.text = f.name
	avatar_img.set_avatar(f.avatar)
	gold_lb.text = StringUtils.point_number(f.gold) + ' ₤'
	
	var is_sent = g.v.friend_mgr.is_sent_requested(_info.uid)
	self.visible = !is_sent
func _click_info():
	g.v.friend_mgr.search_friend(self._info.uid)
	
	
