extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		GameConstants.CMDs.NEW_INGAME_CHAT_MESSAGE:
			_handle_new_message(payload)
		GameConstants.CMDs.CHAT_EMOTICON:
			_handle_chat_emo(payload)
			
func _handle_new_message(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.InGameChatMessage.new()
	var result_code = pkg.from_bytes(payload)
	var message = pkg.get_chat_message()
	var uid = pkg.get_uid()
	
	var scene = SceneManager.get_current_scene()
	if scene is BaseBoardScene:
		scene.on_new_chat_message(uid, message)

func _handle_chat_emo(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.InGameChatEmoticon.new()
	var result_code = pkg.from_bytes(payload)
	var emo = pkg.get_emoticon()
	var uid = pkg.get_uid()
	
	var scene = SceneManager.get_current_scene()
	if scene is BaseBoardScene:
		scene.on_new_chat_emo(uid, emo)
