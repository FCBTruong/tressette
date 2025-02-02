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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Loaded lobby scene")

# Function to switch scenes
func switch_scene(new_scene_path: String) -> void:
	var result = get_tree().change_scene_to_file(new_scene_path)
	
	if result != OK:
		print("Failed to load scene:", new_scene_path)
	else:
		print("Loaded scene:", new_scene_path)
		
	if Config.CURRENT_MODE != Config.MODES.LIVE:
		# Wait for the scene to be ready
		await get_tree().process_frame
		var current_scene = get_tree().get_current_scene()
		if current_scene:
			var gui = load('res://scenes/DevGUI.tscn')
			var popup_instance = gui.instantiate()
			current_scene.add_child(popup_instance)
		
func open_gui(gui_path: String, z_order = 1):
	var current_scene = get_tree().get_current_scene()
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
	var current_scene = get_tree().get_current_scene()
	return current_scene
	
func show_dialog(message: String, ok_callback: Callable = Callable(), close_callback: Callable = Callable(), show_cancel_btn = false):
	var gui = await SceneManager.open_gui("res://scenes/guis/NotificationGUI.tscn")
	if not gui:
		return
	gui.set_message(message)
	gui.set_show_cancel_btn(show_cancel_btn)
	if ok_callback.is_valid():
		gui.connect("ok_pressed", ok_callback)
		
	if close_callback.is_valid():
		gui.connect("close_pressed", close_callback)

func show_ok_dialog(message: String, ok_callback: Callable = Callable()):
	var gui = await SceneManager.open_gui("res://scenes/guis/NotificationGUI.tscn")
	if not gui:
		return
	gui.set_message(message)
	if ok_callback.is_valid():
		gui.connect("ok_pressed", ok_callback)
		
	gui.hide_close_cancel()
