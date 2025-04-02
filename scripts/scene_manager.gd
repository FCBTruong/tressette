extends RefCounted
class_name SceneManager

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
var scene_nodes = {}

var is_in_root = false
var layer_gui: CanvasLayer
# Called when the node enters the scene tree for the first time.

const LAYER_INDEX = {
	GUI = 10
}

func on_ready() -> void:
	print("Loaded lobby scene aaaaa")
	is_in_root = true
	_cur_scene = ROOT.get_tree().current_scene
	layer_gui = CanvasLayer.new()
	layer_gui.layer = LAYER_INDEX.GUI
	ROOT.get_tree().root.add_child(layer_gui)

# Function to switch scenes
func switch_scene(new_scene_path: String) -> void:
	if cur_scene_name:
		last_scene_name = cur_scene_name
	cur_scene_name = new_scene_path
	
	var scene = null
	
	if scene_nodes.has(new_scene_path):
		scene = scene_nodes[new_scene_path]
	else:
		scene = load(new_scene_path)
		scene_nodes[new_scene_path] = scene
		
	var new_scene = scene.instantiate()
	ROOT.get_tree().root.add_child(new_scene)
	
	if is_instance_valid(_cur_scene) and not is_in_root:
		_cur_scene.queue_free()
		
	is_in_root = false
	
	_cur_scene = new_scene
	print("Loaded scene:", new_scene_path)
		
	if g.v.config.CURRENT_MODE != g.v.config.MODES.LIVE:
		var current_scene = self.get_current_scene()
		if current_scene:
			var gui = load('res://scenes/DevGUI.tscn')
			var popup_instance = gui.instantiate()
			current_scene.add_child(popup_instance)
		else:
			print('current scene is null')
		
var gui_nodes = {}
var gui_caches = {}
func open_gui(gui_path: String, cache=false):
	print('open gui: ....', gui_path)

	var gui
	if gui_nodes.has(gui_path):
		gui = gui_nodes[gui_path]
	else:
		gui = load(gui_path)
		if gui == null:
			print("Failed to load gui scene!")  # Check the console

		gui_nodes[gui_path] = gui
		
	var popup_instance
	if cache and gui_caches.has(gui_path):
		popup_instance = gui_caches[gui_path]
		if is_instance_valid(popup_instance):
			if popup_instance.has_method("on_show"):
				popup_instance.on_show()
			return gui_caches[gui_path]
		
	popup_instance = gui.instantiate()
	layer_gui.add_child(popup_instance, 1)
	if cache:
		gui_caches[gui_path] = popup_instance
	if popup_instance.has_method("on_show"):
		popup_instance.on_show()
	return popup_instance


func get_current_scene():
	if not _cur_scene:
		return ROOT.get_tree().current_scene
	return _cur_scene
	
func show_dialog(message: String, ok_callback: Callable = Callable(), close_callback: Callable = Callable(), show_cancel_btn = false,
	custom_ok_txt = null):
	var gui = self.open_gui("res://scenes/guis/NotificationGUI.tscn")
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
	var gui = self.open_gui("res://scenes/guis/NotificationGUI.tscn")
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
	var gui = self.open_gui("res://scenes/guis/ToastGUI.tscn")
	gui.set_toats_text(msg)
	
func add_loading(timeout = -1):
	# check if gui waiting still active, remove it
	if gui_waiting and is_instance_valid(gui_waiting):
		gui_waiting.queue_free()
	var gui = self.open_gui("res://scenes/guis/WaitingGUI.tscn")
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
		self.get_current_scene().add_child(effect_layer)
		effect_layer.layer = 200 
	return effect_layer
