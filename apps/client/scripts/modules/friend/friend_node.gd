extends Node

@onready var avatar_img = find_child('AvatarImg')
@onready var online_icon = find_child('OnlineIcon')
@onready var name_lb = find_child("NameLb")
@onready var gold_lb = find_child("GoldLb")
@onready var avatar_frame = find_child("AvatarFrame")
@onready var last_online_lb = find_child("LastOnlineLb")
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
	avatar_frame.update_frame_by_id(f.avatar_frame)
	
	if f.is_online:
		last_online_lb.visible = false
	else:
		last_online_lb.visible = true
		if f.last_online_time == -1:
			last_online_lb.text = ''
		else:
			var secs = g.v.game_manager.get_timestamp_server() - f.last_online_time
			if secs > 86400 * 30:
				last_online_lb.text = tr("LONG_TIME_AGO")
			else:
				var last_off = StringUtils.format_time(secs)
				var s = tr("LAST_TIME_ONLINE")
				s = s.replace("@time", last_off)
				last_online_lb.text = s
	
func _click_info():
	g.v.friend_mgr.search_friend(self._info.uid)
	
	
