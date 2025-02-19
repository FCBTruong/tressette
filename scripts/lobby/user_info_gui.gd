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
	SignalBus.connect_global('update_friend_list', Callable(self, '_update_status_friend'))
	SignalBus.connect_global('update_friend_requests', Callable(self, '_update_status_friend'))
	
func set_info(info: UserData):
	_info = info
	
	if _info.uid == PlayerInfoMgr.my_user_data.uid:
		avt_edit_btn.visible = true
		avatar_img.set_me()
		is_me = true
	else:
		avt_edit_btn.visible = false
		avatar_img.set_avatar(_info.avatar)
		is_me = false
	
	user_name_lb.text = _info.name
	gold_lb.text = StringUtils.point_number(_info.gold)
	uid_lb.text = str(_info.uid)
	_update_status_friend()
	
	game_count_lb.text = StringUtils.point_number(_info.game_count)
	var win_rate = '-'
	if _info.game_count > 0:
		var win_rate_val = round((_info.win_count / _info.game_count) * 10) * 100 / 10.0
		win_rate = str(win_rate_val) + '%'
		
	win_rate_lb.text = win_rate
	exp_lb.text = StringUtils.point_number(_info.exp)
	
func _copy_uid() -> void:
	DisplayServer.clipboard_set(str(_info.uid))
	
	SceneManager.show_toast(str('COPY_OK'))
	pass
	
func _open_pick_avatar() -> void:
	SceneManager.open_gui('res://scenes/lobby/PickAvatarGUI.tscn', GameConstants.GUI_ZORDER.PICK_AVATAR)
	
func _send_request_friend():
	FriendManager.send_add_friend(self._info.uid)
	print('_send_request_friend', _info.uid)
	_update_status_friend()

func _update_status_friend():
	request_friend_btn.visible = false
	friend_requested.visible = false
	friend_status.visible = false
	reject_friend_btn.visible = false
	accept_friend_btn.visible = false
	if not is_me:
		var is_friend = FriendManager.is_my_friend(_info.uid)
		if is_friend:
			friend_status.visible = true	
			return
		var is_sent = FriendManager.is_sent_requested(_info.uid)
		if is_sent:
			friend_requested.visible = true
			return
		var is_pending_accepted = FriendManager.is_pending_accepted(_info.uid)
		if is_pending_accepted:
			reject_friend_btn.visible = true
			accept_friend_btn.visible = true
			return
			
		
		request_friend_btn.visible = true
			
			
func _click_quick_accept_friend():
	FriendManager.send_accept_friend_request(_info.uid)
	pass
	
func _click_quick_reject_friend():
	FriendManager.send_reject_friend_request(_info.uid)
	pass
