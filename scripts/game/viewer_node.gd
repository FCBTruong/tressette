extends Node

@onready var avatar_img = find_child("AvatarImg")
@onready var emo_icon = find_child("EmoPlayer")
@onready var chat_lb = find_child("ChatLb")
@onready var chat_pn = find_child("ChatPn")
@onready var avatar_frame = find_child("AvatarFrame")
var uid: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chat_pn.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_info(uid: int, avatar, name, frame_id):
	self.uid = uid
	avatar_img.set_avatar(avatar)
	avatar_frame.update_frame_by_id(frame_id)
	pass

func click_avatar():
	g.v.friend_mgr.search_friend(self.uid)
	pass

var tw_chat
func on_chat(msg):
	chat_lb.text = msg
	await get_tree().process_frame
	chat_pn.visible = true
	chat_pn.modulate.a = 1
	
	chat_pn.size.x = 50 + chat_lb.size.x
	
	if tw_chat and tw_chat.is_running():
		tw_chat.kill()
	tw_chat = create_tween()
	tw_chat.tween_property(
		chat_pn,
		"modulate:a",
		0,
		0.3
	).set_delay(2)
	
	pass
	
var tween_emo
func show_emotion(emo_id):
	if tween_emo and tween_emo.is_running():
		tween_emo.kill()
	emo_icon.play(str(emo_id))

	emo_icon.visible = true
	tween_emo = create_tween()
	var tween = tween_emo
	emo_icon.scale = Vector2(0, 0)
	emo_icon.modulate.a = 1
	tween.parallel().tween_property(
		emo_icon, 'scale', Vector2(0.5, 0.5), 0.4
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(
		emo_icon, 'modulate:a', 0, 0.4
	).set_delay(2)
