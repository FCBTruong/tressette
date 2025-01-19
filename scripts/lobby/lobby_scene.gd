extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_do_effect()
	on_update_gui()
	pass # Replace with function body.

@onready var left_panel = find_child('LeftPanel')
@onready var play_container = find_child('PlayContainer')
@onready var bg = find_child('Background')
@onready var panel_info = find_child('PanelInfo')
@onready var gold_lb:Label = panel_info.find_child('GoldLb')
@onready var name_lb:Label = panel_info.find_child('NameLb')

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

func on_update_gui():
	gold_lb.text = StringUtils.point_number(PlayerInfoMgr.my_user_data.gold)
	name_lb.text = str(PlayerInfoMgr.my_user_data.name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_game_button_pressed():
	print('start game...')
	GameManager.send_quick_play()

var user_info_gui: PackedScene = preload("res://scenes/guis/UserInfoGUI.tscn")

func _open_user_info_gui():
	SceneManager.open_gui("res://scenes/guis/UserInfoGUI.tscn")
	
func _hide_user_info_gui():
	$UserInfoGUI.hide()
	
func _open_friend_gui():
	SceneManager.switch_scene("res://scenes/FriendScene.tscn")
	
func _open_setting_gui():
	SceneManager.open_gui("res://scenes/guis/SettingsGUI.tscn")
	
func _open_tables_scene():
	SceneManager.switch_scene(SceneManager.TABLES_SCENE)
	
func _open_mail_gui():
	SceneManager.open_gui("res://scenes/guis/ToastGUI.tscn")
	
func _open_customer_service_gui():
	SceneManager.open_gui("res://scenes/customer_service/CustomerServiceGUI.tscn")
	
func open_shop():
	SceneManager.switch_scene(SceneManager.SHOP_SCENE)
