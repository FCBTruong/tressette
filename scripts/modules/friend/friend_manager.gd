extends RefCounted
class_name FriendManager

var friends: Array[FriendModel] = []
var requests: Array[FriendModel] = []
var recommend_friends: Array[FriendModel] = []
var request_sent_uids = []

	
enum FriendRequestAction {
	ACCEPT = 0,
	REJECT = 1
}


func search_friend(uid: int):
	if uid == g.v.player_info_mgr.my_user_data.uid:
		var gui = await g.v.scene_manager.open_gui("res://scenes/guis/UserInfoGUI.tscn")
		gui.set_info(g.v.player_info_mgr.my_user_data)
		return
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SearchFriend.new()
	pkg.set_uid(uid)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.SEARCH_FRIEND, pkg.to_bytes())

func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		g.v.game_constants.CMDs.SEARCH_FRIEND:
			_on_received_search_friend(payload)
			
		g.v.game_constants.CMDs.FRIEND_LIST:
			_on_received_list_friend(payload)
			
		g.v.game_constants.CMDs.FRIEND_REQUESTS:
			_on_received_friend_requests(payload)
			
		g.v.game_constants.CMDs.NEW_FRIEND_REQUEST:
			_handle_new_friend_request(payload)
			
		g.v.game_constants.CMDs.NEW_FRIEND_ACCEPTED:
			_handle_new_friend_accepted(payload)
			
		g.v.game_constants.CMDs.RECOMMEND_FRIENDS:
			_received_recommended_friends(payload)
func _on_received_search_friend(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.SearchFriendResponse.new()
	var result_code = pkg.from_bytes(payload)
	var error = pkg.get_error()
	if error != 0:
		g.v.scene_manager.show_toast(tr("NOT_FOUND_FRIEND"))
		return
	var uid = pkg.get_uid()
	var avatar = pkg.get_avatar()
	var name = pkg.get_name()
	var level = pkg.get_level()
	var gold = pkg.get_gold()
	var exp = pkg.get_exp()
	var game_count = pkg.get_game_count()
	var win_count = pkg.get_win_count()
	var is_verified = pkg.get_is_verified()
	
	var user_data = UserData.new(uid, name)
	user_data.avatar = avatar
	user_data.gold = gold
	user_data.exp = exp
	user_data.win_count = win_count
	user_data.game_count = game_count
	user_data.is_verified = is_verified
	user_data.avatar_frame = pkg.get_avatar_frame()
	
	var gui = await g.v.scene_manager.open_gui("res://scenes/guis/UserInfoGUI.tscn")
	gui.set_info(user_data)

func _received_recommended_friends(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.RecommendFriends.new()
	var result_code = pkg.from_bytes(payload)
	var friend_ids = pkg.get_uids()
	var friend_names = pkg.get_names()
	var friend_levels = pkg.get_levels()
	var friend_golds = pkg.get_golds()
	var friend_avatars = pkg.get_avatars()
	var avatar_frames = pkg.get_avatar_frames()
	
	self.recommend_friends.clear()
	for i in range(len(friend_ids)):
		var f = FriendModel.new()
		f.uid = friend_ids[i]
		f.name = friend_names[i]
		f.avatar = friend_avatars[i]
		f.gold = friend_golds[i]
		f.level = friend_levels[i]
		f.avatar_frame = avatar_frames[i]
		self.recommend_friends.append(f)
		
	print('list friends commended', len(self.recommend_friends))
	
	
func _on_received_list_friend(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.FriendList.new()
	var result_code = pkg.from_bytes(payload)
	
	var friend_ids = pkg.get_uids()
	var friend_names = pkg.get_names()
	var friend_levels = pkg.get_levels()
	var friend_golds = pkg.get_golds()
	var friend_avatars = pkg.get_avatars()
	var onlines = pkg.get_onlines()
	var is_playings = pkg.get_is_playings()
	var avatar_frames = pkg.get_avatar_frames()
	var last_online_times = pkg.get_last_online_times()
	
	self.friends.clear()
	for i in range(len(friend_ids)):
		var f = FriendModel.new()
		f.uid = friend_ids[i]
		f.name = friend_names[i]
		f.avatar = friend_avatars[i]
		f.gold = friend_golds[i]
		f.level = friend_levels[i]
		f.is_online = onlines[i]
		f.is_playing = is_playings[i]
		f.avatar_frame = avatar_frames[i]
		f.last_online_time = last_online_times[i]
		self.friends.append(f)
	
	self.friends.sort_custom(_compare_friend_sort)
	# sort friends online first
	g.v.signal_bus.emit_signal_global('update_friend_list')

func _on_received_friend_requests(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.FriendRequests.new()
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
		
	g.v.signal_bus.emit_signal_global('update_friend_requests')
		
	
func send_add_friend(uid):
	if len(self.friends) >= 100:
		g.v.scene_manager.show_toast(tr("MAX_FRIENDS"))
		return
	g.v.scene_manager.show_toast(tr("SENT_FRIEND_REQUEST"))
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.AddFriend.new()
	pkg.set_uid(uid)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.ADD_FRIEND, pkg.to_bytes())
	
	self.request_sent_uids.append(uid)

func send_accept_friend_request(friend_uid):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.RequestFriendAccept.new()
	pkg.set_uid(friend_uid)
	pkg.set_action(FRIEND_ACCEPT_REQUEST)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.ACCEPT_FRIEND_REQUEST, pkg.to_bytes())
	
	# Handle logic luon
	for a in self.requests:
		if a.uid == friend_uid:
			self.friends.append(a)
			self.requests.erase(a)
			break
			
	g.v.signal_bus.emit_signal_global('update_friend_list')
	g.v.signal_bus.emit_signal_global('update_friend_requests')

func send_reject_friend_request(friend_uid):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.RequestFriendAccept.new()
	pkg.set_uid(friend_uid)
	pkg.set_action(FRIEND_REJECT_REQUEST)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.ACCEPT_FRIEND_REQUEST, pkg.to_bytes())
	
	for a in self.requests:
		if a.uid == friend_uid:
			self.requests.erase(a)
			break
			
	g.v.signal_bus.emit_signal_global('update_friend_requests')
			
func remove_friend(friend_uid):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.RemoveFriend.new()
	pkg.set_uid(friend_uid)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.REMOVE_FRIEND, pkg.to_bytes())
	
	for a in self.friends:
		if a.uid == friend_uid:
			self.friends.erase(a)
			break
			
	# update list
	g.v.signal_bus.emit_signal_global('update_friend_list')


# Comparator function to sort
func _compare_friend_sort(a, b):
	if a.is_online and not b.is_online:
		return true  # a comes first
	elif not a.is_online and b.is_online:
		return false  # b comes first
	else:
		return true   
		
func send_friend_list():
	g.v.game_client.send_packet(g.v.game_constants.CMDs.FRIEND_LIST, [])
	
func _handle_new_friend_request(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.NewFriendRequest.new()
	var result_code = pkg.from_bytes(payload)
	var f = FriendModel.new()
	f.uid = pkg.get_uid()
	f.avatar = pkg.get_avatar()
	f.name = pkg.get_name()
	f.gold = pkg.get_gold()
	f.level = pkg.get_level()
	
	self.requests.append(f)
	g.v.signal_bus.emit_signal_global('update_friend_requests')
	var txt = tr("NEW_FRIEND_REQUEST")
	txt = txt.replace("@name", f.name)
	g.v.scene_manager.show_toast(txt)
	
func _handle_new_friend_accepted(payload):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.FriendRequestAccepted.new()
	var result_code = pkg.from_bytes(payload)
	var f = FriendModel.new()
	f.uid = pkg.get_uid()
	f.avatar = pkg.get_avatar()
	f.name = pkg.get_name()
	f.gold = pkg.get_gold()
	f.level = pkg.get_level()
	f.avatar_frame = pkg.get_avatar_frame()
	f.is_online = true # realtime -> always online
	
	self.friends.append(f)
	g.v.signal_bus.emit_signal_global('update_friend_list')
	var txt = tr("NEW_FRIEND_ACCEPTED")
	txt = txt.replace("@name", f.name)
	g.v.scene_manager.show_toast(txt)
	
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
	
func get_online_friends():
	var arr = []
	for f in friends:
		if f.is_online:
			arr.append(f)
			
	return arr
	
const FRIEND_ACCEPT_REQUEST: int = 0
const FRIEND_REJECT_REQUEST: int = 1
