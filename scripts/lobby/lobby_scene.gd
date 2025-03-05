extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SoundManager.play_music_lobby()
	_do_effect()
	on_update_gui()
	update_lobby_friends()
	FriendManager.send_friend_list()
	SignalBus.connect_global('on_update_money', Callable(self, "_on_update_money"))
	SignalBus.connect_global('update_friend_list', Callable(self, 'update_lobby_friends'))
	SignalBus.connect_global('update_friend_requests', Callable(self, '_update_friend_requests'))
	
	# check claim support
	if PlayerInfoMgr.my_user_data.gold < \
		GameServerConfig.min_gold_play and PlayerInfoMgr.support_num > 0:
			GameManager.send_claim_support()
			
	var store_rate = StorageCache.fetch("store_rating", 0)
	if store_rate == 0:
		if Config.get_platform() == Config.PLATFORMS.ANDROID:
			if SceneManager.is_back_from_board() \
				and GameManager.LAST_GAME_IS_WIN \
				and PlayerInfoMgr.my_user_data.game_count > 5:
				NativeMgr.rate_app()
				StorageCache.store("store_rating", 1)
				
	if PlayerInfoMgr.startup_gold > 0:
		# popup received gold startup
		var str_startup = tr("STARTUP_GOLD")
		str_startup = str_startup.replace("@num", StringUtils.point_number(PlayerInfoMgr.startup_gold))
		SceneManager.show_dialog(
			str_startup,
			func ():
				GameManager.send_quick_play(),
			func ():
				pass,
			true,
			tr("PLAY_NOW")
		)
		PlayerInfoMgr.startup_gold = 0

@onready var left_panel = find_child('LeftPanel')
@onready var play_container = find_child('PlayContainer')
@onready var bg = find_child('Background')
@onready var panel_info = find_child('PanelInfo')
@onready var gold_lb:Label = panel_info.find_child('GoldLb')
@onready var name_lb:Label = panel_info.find_child('NameLb')
@onready var avatar_img = find_child('Avatar')
@onready var friend_btn = find_child('FriendBtn')
@onready var friend_img_hot = friend_btn.find_child('ImgHot')
@onready var nofriend_btn = find_child('NofriendBtn')
@onready var animation_player = find_child("AnimationPlayer")
func _do_effect() -> void:
	var left_panel_defaultpos = left_panel.position
	var play_container_defaultpos = play_container.position
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Animate left_panel (Move left and back to original position)
	left_panel.position.x -= 200
	tween.parallel().tween_property(left_panel, "position", left_panel_defaultpos, 0.5)

	# Animate play_container (Move right and back to original position)
	play_container.position.x += 200
	tween.parallel().tween_property(play_container, "position", play_container_defaultpos, 0.5)

	# Animate bg scale (Scale up and back to original size)
	#var tween2 = create_tween()
	#var original_scale = bg.scale
	#bg.scale = Vector2(1.2, 1.2)
	#tween2.tween_property(bg, "scale", original_scale, 0.3)
	
	animation_player.play("play_now_icon")
	
func _on_update_money():
	gold_lb.text = StringUtils.point_number(PlayerInfoMgr.my_user_data.gold)

func on_update_gui():
	_on_update_money()
	name_lb.text = str(PlayerInfoMgr.my_user_data.name)
	_update_friend_requests()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_game_button_pressed():
	print('start game...')
	GameManager.send_quick_play()

func _open_user_info_gui():
	var gui = await SceneManager.open_gui("res://scenes/guis/UserInfoGUI.tscn")
	gui.set_info(PlayerInfoMgr.my_user_data)
	
func _open_friend_gui():
	#SceneManager.show_toast(tr('FEATURE_COMING_SOON'))
	#return
	SceneManager.switch_scene("res://scenes/FriendScene.tscn")
	
func _open_setting_gui():
	SceneManager.open_gui("res://scenes/guis/SettingsGUI.tscn")
	
func _open_tables_scene():
	SceneManager.switch_scene(SceneManager.TABLES_SCENE)
	
func _open_mail_gui():
	SceneManager.show_toast(tr('FEATURE_COMING_SOON'))
	
func _open_customer_service_gui():
	SceneManager.open_gui("res://scenes/customer_service/CustomerServiceGUI.tscn")

func _click_mission_btn():
	SceneManager.show_toast(tr('FEATURE_COMING_SOON'))
	
func open_shop():
	SceneManager.switch_scene(SceneManager.SHOP_SCENE)

var friend_lobby_scene = preload("res://scenes/lobby/FriendLobbyNode.tscn")
@onready var lobby_friend_list = find_child('LobbyFriendList')	
func update_lobby_friends():
	for c in lobby_friend_list.get_children():
		if c.name == 'NofriendBtn':
			continue
		c.queue_free()
	for f in FriendManager.friends:
		var n = friend_lobby_scene.instantiate()
		lobby_friend_list.add_child(n)
		n.set_info(f)
	if len(FriendManager.friends) == 0:
		nofriend_btn.visible = true
	else:
		nofriend_btn.visible = false
		
func _update_friend_requests():
	friend_img_hot.visible = len(FriendManager.requests) > 0
	pass
	

func _click_nofriend_btn():
	SceneManager.switch_scene("res://scenes/FriendScene.tscn")
	
func _click_guide_btn():
	SceneManager.open_gui("res://scenes/guis/GuideGUI.tscn")
