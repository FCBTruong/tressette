extends Node

var parent
var text
@onready var lb = find_child("Label")
@export var str_key = ''

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = tr(str_key)
	lb.text = text
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_text(txt):
	lb.text = txt
	text = txt
	
func _click_chat():
	var cur_scene = g.v.scene_manager.get_current_scene()
	if cur_scene is BaseBoardScene:
		parent = cur_scene.in_game_chat_gui
	parent.text_submitted(text)
	if cur_scene is BaseBoardScene:
		for p in cur_scene.list_players:
			if p.user_data.uid == g.v.player_info_mgr.get_user_id():
				p.on_chat(text)
		cur_scene.on_show_chat_gui()
	pass
