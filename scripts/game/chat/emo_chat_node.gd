extends Node

@onready var img = find_child("Img")
var emo_id
var mgr
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_click():
	mgr.hide_emo()
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.InGameChatEmoticon.new()
	pkg.set_emoticon(emo_id)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.CHAT_EMOTICON, pkg.to_bytes())
	pass

func set_emo(emo_id, mgr):
	self.mgr = mgr
	self.emo_id = emo_id
	img.texture = g.v.emoticon_mgr.get_texture_emoticon(emo_id)
