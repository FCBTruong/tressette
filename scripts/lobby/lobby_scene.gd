extends Control

class_name LobbyScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_size = DisplayServer.window_get_size()
	if screen_size.y > screen_size.x * 1.4:
		mobile_web_pn.scale = Vector2(3, 3)
		play_container.scale = Vector2(2, 2)
	g.v.sound_manager.play_music_lobby()
	_do_effect()
	on_update_gui()
	update_lobby_friends()
	g.v.friend_mgr.send_friend_list()
	g.v.signal_bus.connect_global('on_update_money', Callable(self, "_on_update_money"))
	g.v.signal_bus.connect_global('update_friend_list', Callable(self, 'update_lobby_friends'))
	g.v.signal_bus.connect_global('update_friend_requests', Callable(self, '_update_friend_requests'))
	
	# check claim support
	if g.v.player_info_mgr.my_user_data.gold < \
		g.v.game_server_config.min_gold_play and g.v.player_info_mgr.support_num > 0:
			g.v.game_manager.send_claim_support()
			
	var store_rate = g.v.storage_cache.fetch("store_rating", 0)
	if store_rate == 0:
		if g.v.config.get_platform() == g.v.config.PLATFORMS.ANDROID:
			if g.v.scene_manager.is_back_from_board() \
				and g.v.game_manager.LAST_GAME_IS_WIN \
				and g.v.player_info_mgr.my_user_data.game_count > 5:
				g.v.native_mgr.rate_app()
				g.v.storage_cache.store("store_rating", 1)
				
	if g.v.player_info_mgr.startup_gold > 0:
		# popup received gold startup
		var str_startup = tr("STARTUP_GOLD")
		str_startup = str_startup.replace("@num", StringUtils.point_number(g.v.player_info_mgr.startup_gold))
		g.v.scene_manager.show_dialog(
			str_startup,
			func ():
				var gui = g.v.game_manager.open_guide_gui()
				gui.is_quick_play = true
				,
			func ():
				pass,
			true,
			tr("PLAY_NOW")
		)
		g.v.player_info_mgr.startup_gold = 0
		
		

	#if g.v.game_manager.is_enable_ads():
		#g.admob_mgr._on_banner_pressed()
	
	
	#g.v.popup_mgr.add_popup("res://scenes/lobby/LikeFanpageGUI.tscn")

	
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
@onready var mobile_web_pn = find_child("MobileWebPn")
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
	mobile_web_pn.visible = g.v.config.get_platform() == g.v.config.PLATFORMS.WEB

func _on_update_money():
	gold_lb.text = StringUtils.point_number(g.v.player_info_mgr.my_user_data.gold)

func on_update_gui():
	_on_update_money()
	name_lb.text = str(g.v.player_info_mgr.my_user_data.name)
	_update_friend_requests()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_game_button_pressed():
	print('start game...')
	g.v.game_manager.send_quick_play()

func _open_user_info_gui():
	var gui = await g.v.scene_manager.open_gui("res://scenes/guis/UserInfoGUI.tscn")
	gui.set_info(g.v.player_info_mgr.my_user_data)
	
func _open_friend_gui():
	#g.v.scene_manager.show_toast(tr('FEATURE_COMING_SOON'))
	#return
	g.v.scene_manager.switch_scene("res://scenes/FriendScene.tscn")
	
func _open_setting_gui():
	g.v.scene_manager.open_gui("res://scenes/guis/SettingsGUI.tscn")
	
func _open_tables_scene():
	g.v.scene_manager.switch_scene(g.v.scene_manager.TABLES_SCENE)
	
func _open_mail_gui():
	g.v.scene_manager.show_toast(tr('FEATURE_COMING_SOON'))
	
func _open_customer_service_gui():
	g.v.scene_manager.open_gui("res://scenes/customer_service/CustomerServiceGUI.tscn")

func _click_mission_btn():
	#g.v.mission_mgr.open_mission_gui()
	g.v.scene_manager.show_toast(tr('FEATURE_COMING_SOON'))
	
func open_shop():
	g.v.scene_manager.switch_scene(g.v.scene_manager.SHOP_SCENE)

var friend_lobby_scene = preload("res://scenes/lobby/FriendLobbyNode.tscn")
@onready var lobby_friend_list = find_child('LobbyFriendList')	
func update_lobby_friends():
	for c in lobby_friend_list.get_children():
		if c.name == 'NofriendBtn':
			continue
		c.queue_free()
	for f in g.v.friend_mgr.friends:
		var n = friend_lobby_scene.instantiate()
		lobby_friend_list.add_child(n)
		n.set_info(f)
	if len(g.v.friend_mgr.friends) == 0:
		nofriend_btn.visible = true
	else:
		nofriend_btn.visible = false
		
func _update_friend_requests():
	friend_img_hot.visible = len(g.v.friend_mgr.requests) > 0
	pass
	

func _click_nofriend_btn():
	g.v.scene_manager.switch_scene("res://scenes/FriendScene.tscn")
	
func _click_guide_btn():
	g.v.game_manager.open_guide_gui()

func _click_open_appstore():
	OS.shell_open('https://apps.apple.com/us/app/tressette-royal/id6741761784')
	pass

func _click_open_chplay():
	OS.shell_open('https://play.google.com/store/apps/details?id=com.clareentertainment.tressette')
	pass

func _click_ranking():
	g.v.ranking_mgr.show_gui()
