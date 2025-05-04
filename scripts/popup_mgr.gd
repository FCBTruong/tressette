extends Node

class_name PopupMgr

var arr_popups = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


var time_elapsed = 0.0

func _process(delta):
	if g.v.config.CURRENT_MODE == g.v.config.MODES.LOCAL:
		return
	time_elapsed += delta  # Accumulate time
	if time_elapsed >= 0.5:
		time_elapsed = 0.0  # Reset timer
		check_and_show()  # Call your function



var cur_popup = null


func add_popup(gui_path: String, func_name: String = '', params: Array = [], lobby: bool = true):
	arr_popups.append({
		"gui": gui_path,
		"func_name": func_name,
		"params": params,
		"lobby": lobby
	})

	
func check_and_show():
	if cur_popup and is_instance_valid(cur_popup) and cur_popup.visible:
		return
	if len(arr_popups) == 0:
		return
	var popup = null
	
	var cur_scene = g.v.scene_manager.get_current_scene()
	for p in arr_popups:
		if p.lobby:
			if cur_scene is LobbyScene:
				popup = p
				break
			else:
				continue
		else:
			popup = p
			break
	if not popup:
		return
	arr_popups.erase(popup)
	var gui = g.v.scene_manager.open_gui(popup['gui'])
	if popup["func_name"]:
		gui.callv(popup["func_name"], popup["params"])
	cur_popup = gui
