extends Node

@onready var avatar_img = find_child('AvatarImg')
@onready var online_icon = find_child('OnlineIcon')
@onready var name_lb = find_child("NameLb")
@onready var gold_lb = find_child("GoldLb")
var _info = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _remove_friend():
	var txt = tr("CONFIRM_REMOVE_FRIEND")
	# replace @name by _info.name
	txt = txt.replace("@name", _info.name)
	g.v.scene_manager.show_dialog(txt,
		func ():
			g.v.friend_mgr.remove_friend(_info.uid),
		func ():
			pass,
		true 
	)


func set_info(f: FriendModel):
	_info = f
	name_lb.text = f.name
	avatar_img.set_avatar(f.avatar)
	gold_lb.text = StringUtils.point_number(f.gold) #+ ' ₤'
	online_icon.visible = f.is_online
	
func _click_info():
	g.v.friend_mgr.search_friend(self._info.uid)
	
	
