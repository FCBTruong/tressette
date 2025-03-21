extends Node


var text = ''
var parent
@onready var lb = find_child("Label")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_text(txt):
	lb.text = txt
	text = txt
	
func _click_chat():
	parent.text_submitted(text)
	var cur_scene = g.v.scene_manager.get_current_scene()
	if cur_scene is BoardScene:
		for p in cur_scene.list_players:
			if p.user_data.uid == g.v.player_info_mgr.get_user_id():
				p.on_chat(text)
		cur_scene.on_show_chat_gui()
	pass
