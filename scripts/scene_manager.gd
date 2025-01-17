extends Node

const LOBBY_SCENE = 'res://scenes/LobbyScene.tscn'
const BOARD_SCENE = 'res://scenes/BoardScene.tscn'
const TABLES_SCENE = 'res://scenes/ChooseTableScene.tscn'
const LOGIN_SCENE = 'res://scenes/LoginScene.tscn'

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
		
func open_gui(gui_path: String) -> void:
	var current_scene = get_tree().get_current_scene()
	if current_scene:
		var gui = load(gui_path)
		var popup_instance = gui.instantiate()
		current_scene.add_child(popup_instance)
	else:
		print("Current GUI is null", gui_path)

func get_current_scene():
	var current_scene = get_tree().get_current_scene()
	return current_scene
