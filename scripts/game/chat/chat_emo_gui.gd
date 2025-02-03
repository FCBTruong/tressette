extends Node


# Called when the node enters the scene tree for the first time.
var is_showing = false
@onready var main = find_child('Panel')
var default_pos
var tween
func _ready() -> void:
	default_pos = main.position
	main.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _click_emo(id):
	pass
	
func hide():
	is_showing = false
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.parallel().tween_property(
		main,
		'position',
		Vector2(
			default_pos.x,
			default_pos.y + 200
		),
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
func show():
	main.visible = true
	main.position.y = default_pos.y + 200
	is_showing = true
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.parallel().tween_property(
		main,
		'position',
		Vector2(
			default_pos.x,
			default_pos.y
		),
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
func _on_emo_btn_1_pressed() -> void:
	var id = 1
	hide()
	_send_chat_emo(id)
	pass # Replace with function body.
	
func _on_emo_btn_2_pressed() -> void:
	var id = 2
	_send_chat_emo(id)
	hide()
	pass # Replace with function body.
	
func _on_emo_btn_3_pressed() -> void:
	var id = 3
	_send_chat_emo(id)
	hide()
	pass # Replace with function body.
	
func _on_emo_btn_4_pressed() -> void:
	var id = 4
	_send_chat_emo(id)
	hide()
	pass # Replace with function body.
	
func _on_emo_btn_5_pressed() -> void:
	var id = 5
	_send_chat_emo(id)
	hide()
	pass # Replace with function body.


func _on_emo_btn_pressed() -> void:
	if is_showing:
		hide()
	else:
		show()
	pass # Replace with function body.

func _send_chat_emo(emo: int):
	var pkg = GameConstants.PROTOBUF.PACKETS.InGameChatEmoticon.new()
	pkg.set_emoticon(emo)
	GameClient.send_packet(GameConstants.CMDs.CHAT_EMOTICON, pkg.to_bytes())
