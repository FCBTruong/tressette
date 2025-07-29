extends Control

class_name LobbyScene
var did_share_session
@onready var sette_mezzo_btn = find_child("SetteMezzoBtn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_size = DisplayServer.window_get_size()
	if screen_size.y > screen_size.x * 1.4:
		mobile_web_pn.scale = Vector2(3, 3)
		play_container.scale = Vector2(2, 2)
	g.v.sound_manager.play_music_lobby()
	_do_effect()
	on_update_gui()
	g.v.friend_mgr.send_friend_list()
	g.v.signal_bus.connect_global('on_update_money', Callable(self, "_on_update_money"))
	g.v.signal_bus.connect_global('update_friend_requests', Callable(self, '_update_friend_requests'))
	
	# check claim support
	if g.v.player_info_mgr.my_user_data.gold < \
		g.v.game_server_config.min_gold_play and g.v.player_info_mgr.support_num > 0:
			g.v.game_manager.send_claim_support()
			
	var store_rate = g.v.storage_cache.fetch("store_rating2", 0)
	if store_rate == 0:
		if g.v.config.get_platform() == g.v.config.PLATFORMS.ANDROID \
				and g.v.player_info_mgr.my_user_data.game_count > 5:
				g.v.storage_cache.store("store_rating2", 1)
				g.v.popup_mgr.add_popup("res://scenes/lobby/RatingGUI.tscn")			

	if g.v.player_info_mgr.startup_gold > 0:
		# popup received gold startup
		var str_startup = tr("STARTUP_GOLD")
		str_startup = str_startup.replace("@num", StringUtils.point_number(g.v.player_info_mgr.startup_gold))
		g.v.scene_manager.show_ok_dialog(
			str_startup,
			func ():
				g.v.scene_manager.open_gui("res://scenes/lobby/PickCardGUI.tscn")
				,
			false,
			tr("PLAY_NOW")
		)
		g.v.player_info_mgr.startup_gold = 0
		
		

	#if g.v.game_manager.is_enable_ads():
		#g.admob_mgr._on_banner_pressed()
	
	g.v.game_manager.check_show_fanpage()
	g.v.game_manager.check_show_group_fb()
	
	self.offer_first_btn.visible = g.v.player_info_mgr.has_first_buy
	#g.v.scene_manager.open_gui("res://scenes/lobby/LinkAccountGUI.tscn")
	update_ads_reward_info()
	
	if g.v.config.get_platform() == g.v.config.PLATFORMS.ANDROID:
		var num_share = g.v.storage_cache.fetch("share_game", 0)
		if not did_share_session and num_share < 3 and g.v.player_info_mgr.my_user_data.game_count > 10:
			# add popup share
			did_share_session = true
			g.v.storage_cache.store("share_game", num_share + 1)
			g.v.scene_manager.show_dialog(
				tr("SHARE_GAME"),
				func():
					g.v.storage_cache.store("share_game", 3)
					g.v.native_mgr.share_app(
						tr("SHARE_CONTENT")
					)
					pass
			)
	if g.v.app_version.is_in_review():
		self.sette_mezzo_btn.visible = false
	else:
		self.sette_mezzo_btn.visible = true
		
@onready var watch_ads_btn = find_child("WatchAdsBtn")
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
@onready var offer_first_btn = find_child("OfferFirstBtn")
func _do_effect() -> void:
	var play_container_defaultpos = play_container.position
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

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

func _click_offer_first_buy():
	if not g.v.player_info_mgr.has_first_buy:
		self.offer_first_btn.visible = false
		return
	g.v.scene_manager.open_gui("res://scenes/lobby/FirstBuyGUI.tscn")

func watch_ads_reward():
	if not g.v.player_info_mgr.enable_ads_reward:
		return
	if g.v.player_info_mgr.time_ads_reward > g.v.game_manager.get_timestamp_server():
		return
	g.admob_mgr._on_reward_pressed()
	pass

var tween_btn_ads
@onready var ads_time_lb = find_child("AdsTime")
func update_ads_reward_info():
	if not g.v.player_info_mgr.enable_ads_reward:
		self.watch_ads_btn.visible = false
		return
	if tween_btn_ads and tween_btn_ads.is_running():
		tween_btn_ads.kill()
	self.watch_ads_btn.visible = true
	if g.v.player_info_mgr.time_ads_reward < g.v.game_manager.get_timestamp_server():
		ads_time_lb.visible = false
		watch_ads_btn.find_child("IconActive").visible = true
		watch_ads_btn.find_child("IconDisable").visible = false
		pass
	else:
		watch_ads_btn.find_child("IconActive").visible = false
		watch_ads_btn.find_child("IconDisable").visible = true
		ads_time_lb.visible = true
		tween_btn_ads = create_tween()
		tween_btn_ads.set_loops()
		tween_btn_ads.tween_callback(
			func():
				var remain = g.v.player_info_mgr.time_ads_reward - g.v.game_manager.get_timestamp_server()
				remain = int(remain)
				ads_time_lb.text = format_time(remain)
				pass
		)
		tween_btn_ads.tween_interval(1)

func format_time(remain: int) -> String:
	var hours = remain / 3600
	var minutes = (remain % 3600) / 60
	var seconds = remain % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]


func play_sette_mezzo():
	g.v.sette_mezzo_mgr.quick_play()

func open_fb_group():
	OS.shell_open("https://www.facebook.com/share/g/1ALgWc7Lg9/")
