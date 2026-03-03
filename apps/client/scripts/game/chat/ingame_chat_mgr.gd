extends RefCounted
class_name IngameChatMgr




func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		g.v.game_constants.CMDs.NEW_INGAME_CHAT_MESSAGE:
			_handle_new_message(payload)
		g.v.game_constants.CMDs.CHAT_EMOTICON:
			_handle_chat_emo(payload)
			
func _handle_new_message(payload):
	if not g.v.game_manager.enable_chat:
		return
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.InGameChatMessage.new()
	var result_code = pkg.from_bytes(payload)
	var message = pkg.get_chat_message()
	var uid = pkg.get_uid()
	
	var scene = g.v.scene_manager.get_current_scene()
	if scene is BaseBoardScene:
		scene.on_new_chat_message(uid, message)

func _handle_chat_emo(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.InGameChatEmoticon.new()
	var result_code = pkg.from_bytes(payload)
	var emo = pkg.get_emoticon()
	var uid = pkg.get_uid()
	
	var scene = g.v.scene_manager.get_current_scene()
	if scene is BaseBoardScene:
		scene.on_new_chat_emo(uid, emo)
