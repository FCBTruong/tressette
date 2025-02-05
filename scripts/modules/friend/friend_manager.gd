extends Node

var friends: Array[FriendModel] = []
var requests: Array[FriendModel] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	return
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
enum FriendRequestAction {
	ACCEPT = 0,
	REJECT = 1
}


func search_friend(uid: int):
	if uid == PlayerInfoMgr.my_user_data.uid:
		var gui = await SceneManager.open_gui("res://scenes/guis/UserInfoGUI.tscn")
		gui.set_info(PlayerInfoMgr.my_user_data)
		return
	var pkg = GameConstants.PROTOBUF.PACKETS.SearchFriend.new()
	pkg.set_uid(uid)
	GameClient.send_packet(GameConstants.CMDs.SEARCH_FRIEND, pkg.to_bytes())

func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		GameConstants.CMDs.SEARCH_FRIEND:
			_on_received_search_friend(payload)
			
		GameConstants.CMDs.FRIEND_LIST:
			_on_received_list_friend(payload)

func _on_received_search_friend(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.SearchFriendResponse.new()
	var result_code = pkg.from_bytes(payload)
	var error = pkg.get_error()
	if error != 0:
		SceneManager.show_toast(tr("NOT_FOUND_FRIEND"))
		return
	var uid = pkg.get_uid()
	var avatar = pkg.get_avatar()
	var name = pkg.get_name()
	var level = pkg.get_level()
	var gold = pkg.get_gold()
	
	var user_data = UserData.new(uid, name)
	user_data.avatar = avatar
	user_data.gold = gold
	
	var gui = await SceneManager.open_gui("res://scenes/guis/UserInfoGUI.tscn")
	gui.set_info(user_data)
	
	
func _on_received_list_friend(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.FriendList.new()
	var result_code = pkg.from_bytes(payload)
	
	var friend_ids = pkg.get_uids()
	var friend_names = pkg.get_names()
	var friend_levels = pkg.get_levels()
	var friend_golds = pkg.get_golds()
	var friend_avatars = pkg.get_avatars()
	
	self.friends.clear()
	for i in range(len(friend_ids)):
		var f = FriendModel.new()
		f.uid = friend_ids[i]
		f.name = friend_names[i]
		f.avatar = friend_avatars[i]
		f.gold = friend_golds[i]
		f.level = friend_levels[i]
		
		self.friends.append(f)
