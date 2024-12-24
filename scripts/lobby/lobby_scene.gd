extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_game_button_pressed():
	print('start game...')
	SceneManager.switch_scene("res://scenes/BoardScene.tscn")

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
	
