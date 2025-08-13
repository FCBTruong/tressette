extends Node

@onready var anim_player = find_child("AnimPlayer")
@onready var vip_img = find_child("VipImg")
var emo_id
var mgr
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_click():
	if not is_active:
		return
	mgr.hide_emo()
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.InGameChatEmoticon.new()
	pkg.set_emoticon(emo_id)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CHAT_EMOTICON, pkg.to_bytes())
	pass

var is_active
func set_emo(emo_id, mgr):
	is_active = true
	if emo_id in g.v.game_server_config.emo_vip_ids:
		if not g.v.player_info_mgr.is_user_vip():
			is_active = false
	if not is_active:
		vip_img.visible = true
		self.modulate.a = 0.5
	else:
		vip_img.visible = false
		self.modulate.a = 1
	self.mgr = mgr
	self.emo_id = emo_id
	anim_player.play(str(emo_id))
