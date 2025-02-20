extends Node

var friends: Array[FriendModel] = []
var requests: Array[FriendModel] = []
var recommend_friends: Array[FriendModel] = []
var request_sent_uids = []
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
			
		GameConstants.CMDs.FRIEND_REQUESTS:
			_on_received_friend_requests(payload)
			
		GameConstants.CMDs.NEW_FRIEND_REQUEST:
			_handle_new_friend_request(payload)
			
		GameConstants.CMDs.NEW_FRIEND_ACCEPTED:
			_handle_new_friend_accepted(payload)
			
		GameConstants.CMDs.RECOMMEND_FRIENDS:
			_received_recommended_friends(payload)
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
	var exp = pkg.get_exp()
	var game_count = pkg.get_game_count()
	var win_count = pkg.get_win_count()
	
	var user_data = UserData.new(uid, name)
	user_data.avatar = avatar
	user_data.gold = gold
	user_data.exp = exp
	user_data.win_count = win_count
	user_data.game_count = game_count
	
	var gui = await SceneManager.open_gui("res://scenes/guis/UserInfoGUI.tscn")
	gui.set_info(user_data)

func _received_recommended_friends(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.RecommendFriends.new()
	var result_code = pkg.from_bytes(payload)
	var friend_ids = pkg.get_uids()
	var friend_names = pkg.get_names()
	var friend_levels = pkg.get_levels()
	var friend_golds = pkg.get_golds()
	var friend_avatars = pkg.get_avatars()
	
	self.recommend_friends.clear()
	for i in range(len(friend_ids)):
		var f = FriendModel.new()
		f.uid = friend_ids[i]
		f.name = friend_names[i]
		f.avatar = friend_avatars[i]
		f.gold = friend_golds[i]
		f.level = friend_levels[i]
		self.recommend_friends.append(f)
		
	print('list friends commended', len(self.recommend_friends))
	
	
func _on_received_list_friend(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.FriendList.new()
	var result_code = pkg.from_bytes(payload)
	
	var friend_ids = pkg.get_uids()
	var friend_names = pkg.get_names()
	var friend_levels = pkg.get_levels()
	var friend_golds = pkg.get_golds()
	var friend_avatars = pkg.get_avatars()
	var onlines = pkg.get_onlines()
	
	self.friends.clear()
	for i in range(len(friend_ids)):
		var f = FriendModel.new()
		f.uid = friend_ids[i]
		f.name = friend_names[i]
		f.avatar = friend_avatars[i]
		f.gold = friend_golds[i]
		f.level = friend_levels[i]
		f.is_online = onlines[i]
		self.friends.append(f)
	
	self.friends.sort_custom(_compare_friend_sort)
	# sort friends online first
	SignalBus.emit_signal_global('update_friend_list')

func _on_received_friend_requests(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.FriendRequests.new()
	var result_code = pkg.from_bytes(payload)

	self.request_sent_uids = pkg.get_sent_uids()
	self.requests.clear()
	
	var uids = pkg.get_uids()
	var names = pkg.get_names()
	var avatars = pkg.get_avatars()
	var golds = pkg.get_golds()
	var levels = pkg.get_levels()
	
	print('requests....', uids)
	
	for i in range(len(uids)):
		var f = FriendModel.new()
		f.uid = uids[i]
		f.name = names[i]
		f.avatar = avatars[i]
		f.gold = golds[i]
		f.level = levels[i]
		
		self.requests.append(f)
		
	SignalBus.emit_signal_global('update_friend_requests')
		
	
func send_add_friend(uid):
	if len(self.friends) >= 100:
		SceneManager.show_toast(tr("MAX_FRIENDS"))
		return
	SceneManager.show_toast(tr("SENT_FRIEND_REQUEST"))
	var pkg = GameConstants.PROTOBUF.PACKETS.AddFriend.new()
	pkg.set_uid(uid)
	GameClient.send_packet(GameConstants.CMDs.ADD_FRIEND, pkg.to_bytes())
	
	self.request_sent_uids.append(uid)

func send_accept_friend_request(friend_uid):
	var pkg = GameConstants.PROTOBUF.PACKETS.RequestFriendAccept.new()
	pkg.set_uid(friend_uid)
	pkg.set_action(FRIEND_ACCEPT_REQUEST)
	GameClient.send_packet(GameConstants.CMDs.ACCEPT_FRIEND_REQUEST, pkg.to_bytes())
	
	# Handle logic luon
	for a in self.requests:
		if a.uid == friend_uid:
			self.friends.append(a)
			self.requests.erase(a)
			break
			
	SignalBus.emit_signal_global('update_friend_list')
	SignalBus.emit_signal_global('update_friend_requests')

func send_reject_friend_request(friend_uid):
	var pkg = GameConstants.PROTOBUF.PACKETS.RequestFriendAccept.new()
	pkg.set_uid(friend_uid)
	pkg.set_action(FRIEND_REJECT_REQUEST)
	GameClient.send_packet(GameConstants.CMDs.ACCEPT_FRIEND_REQUEST, pkg.to_bytes())
	
	for a in self.requests:
		if a.uid == friend_uid:
			self.requests.erase(a)
			break
			
	SignalBus.emit_signal_global('update_friend_requests')
			
func remove_friend(friend_uid):
	var pkg = GameConstants.PROTOBUF.PACKETS.RemoveFriend.new()
	pkg.set_uid(friend_uid)
	GameClient.send_packet(GameConstants.CMDs.REMOVE_FRIEND, pkg.to_bytes())
	
	for a in self.friends:
		if a.uid == friend_uid:
			self.friends.erase(a)
			break
			
	# update list
	SignalBus.emit_signal_global('update_friend_list')


# Comparator function to sort
func _compare_friend_sort(a, b):
	if a.is_online and not b.is_online:
		return true  # a comes first
	elif not a.is_online and b.is_online:
		return false  # b comes first
	else:
		return true   
		
func send_friend_list():
	GameClient.send_packet(GameConstants.CMDs.FRIEND_LIST, [])
	
func _handle_new_friend_request(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.NewFriendRequest.new()
	var result_code = pkg.from_bytes(payload)
	var f = FriendModel.new()
	f.uid = pkg.get_uid()
	f.avatar = pkg.get_avatar()
	f.name = pkg.get_name()
	f.gold = pkg.get_gold()
	f.level = pkg.get_level()
	
	self.requests.append(f)
	SignalBus.emit_signal_global('update_friend_requests')
	var txt = tr("NEW_FRIEND_REQUEST")
	txt = txt.replace("@name", f.name)
	SceneManager.show_toast(txt)
	
func _handle_new_friend_accepted(payload):
	var pkg = GameConstants.PROTOBUF.PACKETS.FriendRequestAccepted.new()
	var result_code = pkg.from_bytes(payload)
	var f = FriendModel.new()
	f.uid = pkg.get_uid()
	f.avatar = pkg.get_avatar()
	f.name = pkg.get_name()
	f.gold = pkg.get_gold()
	f.level = pkg.get_level()
	f.is_online = true # realtime -> always online
	
	self.friends.append(f)
	SignalBus.emit_signal_global('update_friend_list')
	var txt = tr("NEW_FRIEND_ACCEPTED")
	txt = txt.replace("@name", f.name)
	SceneManager.show_toast(txt)
	
func is_my_friend(friend_uid):
	for f in self.friends:
		if f.uid == friend_uid:
			return true
	return false	
	
func is_sent_requested(friend_uid):
	if friend_uid in self.request_sent_uids:
		return true
	return false
	
func is_pending_accepted(friend_uid):
	for f in self.requests:
		if f.uid == friend_uid:
			return true
	return false	
	
const FRIEND_ACCEPT_REQUEST: int = 0
const FRIEND_REJECT_REQUEST: int = 1
