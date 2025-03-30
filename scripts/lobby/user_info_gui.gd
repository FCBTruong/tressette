extends CanvasLayer

# Close button action
func _on_CloseButton_pressed():
	hide()

# Show popup at the center of the screen
func _show_popup():
	show()

@onready var user_name_lb = find_child('UserNameLb')
@onready var gold_lb = find_child('GoldLb')
@onready var main_pn = find_child('MainPn')
@onready var uid_lb = find_child('UidLb')
@onready var request_friend_btn = find_child('RequestFriendBtn')
@onready var avt_edit_btn = find_child('AvtEditBtn')
@onready var avatar_img = find_child('AvatarImg')
@onready var friend_requested = find_child("FriendRequested")
@onready var friend_status = find_child("FriendStatus")
@onready var accept_friend_btn = find_child("AcceptFriendBtn")
@onready var reject_friend_btn = find_child("RejectFriendBtn")
@onready var mail_btn = find_child("MailBtn")
@onready var game_count_lb = find_child("GameCountLb")
@onready var win_rate_lb = find_child("WinRateLb")
@onready var exp_lb = find_child("ExpLb")
@onready var level_lb = find_child("LevelLb")
@onready var exp_bar = find_child("ExpBar")
@onready var head_pn = find_child("HeadPn")
@onready var red_dot_avt = find_child("RedDotAvt")
@onready var hbox_premium = find_child("HBoxPremium")
@onready var premium_lb = find_child("PremiumLb")
var is_me: bool = false
var _info:UserData = null
func _ready() -> void:
	mail_btn.visible = false
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0.5
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.4)
	g.v.signal_bus.connect_global('update_friend_list', Callable(self, '_update_status_friend'))
	g.v.signal_bus.connect_global('update_friend_requests', Callable(self, '_update_status_friend'))
	red_dot_avt.visible = false
func set_info(info: UserData):
	_info = info
	red_dot_avt.visible = false
	if _info.uid == g.v.player_info_mgr.my_user_data.uid:
		avt_edit_btn.visible = true
		avatar_img.set_me()
		is_me = true
		
		var time_remain = int(g.v.player_info_mgr.time_show_ads - g.v.game_manager.get_timestamp_server())
		if time_remain > 0:
			hbox_premium.visible = true
			var days = time_remain / 86400
			var hours = (time_remain % 86400) / 3600
			var minutes = (time_remain % 3600) / 60
			if days > 0:
				premium_lb.text = str(days) + "d:" + str(hours) + "h"
			else:
				premium_lb.text = str(hours) + "h:" + str(minutes) + "m"

		else:
			hbox_premium.visible = false
		var is_clicked_pick_avatar = g.v.storage_cache.fetch("open_picking_avatar_gui", '0') == '1'
		if not is_clicked_pick_avatar:
			red_dot_avt.visible = true
		
		head_pn.self_modulate = Color('#429648ca')
	else:
		hbox_premium.visible = false
		avt_edit_btn.visible = false
		avatar_img.set_avatar(_info.avatar)
		is_me = false
		head_pn.self_modulate = Color('#0b000056')
	
	user_name_lb.text = _info.name
	gold_lb.text = StringUtils.point_number(_info.gold)
	uid_lb.text = str(_info.uid)
	_update_status_friend()
	
	game_count_lb.text = StringUtils.point_number(_info.game_count)
	var win_rate = '-'
	if _info.game_count > 0:
		var win_rate_val = round((_info.win_count * 1.0 / _info.game_count) * 10) * 100 / 10.0
		win_rate = str(win_rate_val) + '%'
		
	win_rate_lb.text = win_rate
	exp_lb.text = StringUtils.point_number(_info.exp)
	var level = g.v.game_server_config.convert_exp_to_level(_info.exp)
	if g.v.game_server_config.is_max_level(level):
		exp_lb.text = tr("MAX")
		exp_bar.value = 100
	else:
		var a = g.v.game_server_config.exp_levels[level - 1]
		var b = g.v.game_server_config.exp_levels[level]
		var cur = _info.exp - a
		var des = b - a
		exp_bar.value = cur * 1.0 / des * 100
		exp_lb.text = str(cur) + '/' + str(des)
	self.level_lb.text = str(level)
	
func _copy_uid() -> void:
	DisplayServer.clipboard_set(str(_info.uid))
	
	g.v.scene_manager.show_toast(str('COPY_OK'))
	pass
	
func _open_pick_avatar() -> void:
	red_dot_avt.visible = false
	g.v.scene_manager.open_gui('res://scenes/lobby/PickAvatarGUI.tscn', g.v.game_constants.GUI_ZORDER.PICK_AVATAR)
	
func _send_request_friend():
	g.v.friend_mgr.send_add_friend(self._info.uid)
	print('_send_request_friend', _info.uid)
	_update_status_friend()

func _update_status_friend():
	request_friend_btn.visible = false
	friend_requested.visible = false
	friend_status.visible = false
	reject_friend_btn.visible = false
	accept_friend_btn.visible = false
	if not is_me:
		var is_friend = g.v.friend_mgr.is_my_friend(_info.uid)
		if is_friend:
			friend_status.visible = true	
			return
		var is_sent = g.v.friend_mgr.is_sent_requested(_info.uid)
		if is_sent:
			friend_requested.visible = true
			return
		var is_pending_accepted = g.v.friend_mgr.is_pending_accepted(_info.uid)
		if is_pending_accepted:
			reject_friend_btn.visible = true
			accept_friend_btn.visible = true
			return
			
		
		request_friend_btn.visible = true
			
			
func _click_quick_accept_friend():
	g.v.friend_mgr.send_accept_friend_request(_info.uid)
	pass
	
func _click_quick_reject_friend():
	g.v.friend_mgr.send_reject_friend_request(_info.uid)
	pass
