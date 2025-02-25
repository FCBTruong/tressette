extends Node

const LOBBY_SCENE = 'res://scenes/LobbyScene.tscn'
const BOARD_SCENE = 'res://scenes/BoardScene.tscn'
const TABLES_SCENE = 'res://scenes/ChooseTableScene.tscn'
const LOGIN_SCENE = 'res://scenes/LoginScene.tscn'
const SHOP_SCENE = 'res://scenes/ShopScene.tscn'
const LOADING_SCENE = 'res://scenes/loading/LoadingScene.tscn'

static var INSTANCES = {
	BOARD_SCENE: null
}
var last_scene_name = null
var cur_scene_name = null
var effect_layer = null
var _cur_scene = null

var preload_lobby_scene = preload(LOBBY_SCENE)
var preload_board_scene = preload(BOARD_SCENE)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Loaded lobby scene")
	

# Function to switch scenes
func switch_scene(new_scene_path: String) -> void:
	if cur_scene_name:
		last_scene_name = cur_scene_name
	cur_scene_name = last_scene_name
	
	var scene = null
	if new_scene_path == LOBBY_SCENE:
		scene = preload_lobby_scene
	elif new_scene_path == BOARD_SCENE:
		scene = preload_board_scene
	else:
		scene = load(new_scene_path)
		
	if is_instance_valid(_cur_scene):
		_cur_scene.queue_free()
	_cur_scene = scene.instantiate()
	get_tree().root.add_child(_cur_scene)
	print("Loaded scene:", new_scene_path)
		
	if Config.CURRENT_MODE != Config.MODES.LIVE:
		var current_scene = self.get_current_scene()
		if current_scene:
			var gui = load('res://scenes/DevGUI.tscn')
			var popup_instance = gui.instantiate()
			current_scene.add_child(popup_instance)
		else:
			print('current scene is null')
		
		
func open_gui(gui_path: String, z_order = 1):
	print('open gui: ....', gui_path)
	var current_scene = self.get_current_scene()
	await get_tree().process_frame
	if current_scene:
		var gui = load(gui_path)
		var popup_instance = gui.instantiate()
		current_scene.add_child(popup_instance, z_order)
		return popup_instance
	else:
		print("Current GUI is null", gui_path)
	return null

func get_current_scene():
	return _cur_scene
	
func show_dialog(message: String, ok_callback: Callable = Callable(), close_callback: Callable = Callable(), show_cancel_btn = false,
	custom_ok_txt = null):
	var gui = await SceneManager.open_gui("res://scenes/guis/NotificationGUI.tscn")
	if not gui:
		return
		
	if custom_ok_txt:
		gui.ok_txt_lb.text = custom_ok_txt

	gui.set_message(message)
	gui.set_show_cancel_btn(show_cancel_btn)
	if ok_callback.is_valid():
		gui.connect("ok_pressed", ok_callback)
		
	if close_callback.is_valid():
		gui.connect("close_pressed", close_callback)

func show_ok_dialog(message: String, ok_callback: Callable = Callable(), can_close = false):
	var gui = await SceneManager.open_gui("res://scenes/guis/NotificationGUI.tscn")
	if not gui:
		return
	gui.set_message(message)
	if ok_callback.is_valid():
		gui.connect("ok_pressed", ok_callback)
		gui.connect("close_pressed", ok_callback)
	if not can_close:	
		gui.hide_close_cancel()

var gui_waiting = null
func show_toast(msg = ''):		
	var gui = await SceneManager.open_gui("res://scenes/guis/ToastGUI.tscn")
	gui.set_toats_text(msg)
	
func add_loading(timeout = -1):
	# check if gui waiting still active, remove it
	if gui_waiting and is_instance_valid(gui_waiting):
		gui_waiting.queue_free()
	var gui = await SceneManager.open_gui("res://scenes/guis/WaitingGUI.tscn")
	self.gui_waiting = gui
	if timeout != -1:
		gui.set_timeout(timeout)
		
func clear_loading():
	if gui_waiting and is_instance_valid(gui_waiting):
		gui_waiting.queue_free()

func is_back_from_board():
	if last_scene_name and last_scene_name == BOARD_SCENE:
		return true
	return false

func get_effect_layer():
	if not effect_layer or not is_instance_valid(effect_layer):
		effect_layer = CanvasLayer.new()
		SceneManager.get_current_scene().add_child(effect_layer)
		effect_layer.layer = 200 
	return effect_layer
