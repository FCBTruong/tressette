extends Node

var _info = null
@onready var name_lb = find_child('NameLb')
@onready var avatar_img = find_child('AvatarImg')
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_accept():
	print('accept friend')
	g.v.friend_mgr.send_accept_friend_request(_info.uid)
	self.get_parent().remove_child(self)
func _on_reject():
	g.v.friend_mgr.send_reject_friend_request(_info.uid)
	print('on reject')
	self.get_parent().remove_child(self)


func set_info(f: FriendModel):
	_info = f
	name_lb.text = f.name
	avatar_img.set_avatar(f.avatar)
	pass

func _click_view_info():
	g.v.friend_mgr.search_friend(_info.uid)
