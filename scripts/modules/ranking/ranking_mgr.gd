extends RefCounted

class_name RankingMgr

var time_end: int
var rewards = []
var my_rank: int
var my_score: int
var last_time_received = 0
var rank_enable: bool = false

class RankingPlayer:
	var uid: int
	var name: String
	var rank: int
	var avatar: String
	var reward: int
	var score: int
	
var list_users = []
func get_reward(rank):
	if rank - 1 < len(rewards):
		return rewards[rank - 1]
	return 0

func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	match cmd_id:
		g.v.game_constants.CMDs.RANKING_INFO:
			last_time_received = g.v.game_manager.get_timestamp_client()
			list_users.clear()
			rank_enable = true
			var pkg = g.v.game_constants.PROTOBUF.PACKETS.RankingInfo.new()
			var result_code = pkg.from_bytes(payload)
			rewards = pkg.get_rewards()
			time_end = pkg.get_time_end()
			
			my_rank = pkg.get_my_rank()
			my_score = pkg.get_my_score()
			
			var uids = pkg.get_uids()
			var names = pkg.get_names()
			var avatars = pkg.get_avatars()
			var scores = pkg.get_scores()
			for i in range(len(uids)):
				var r = RankingPlayer.new()
				r.rank = i + 1
				r.name = names[i]
				r.avatar = avatars[i]
				r.score = scores[i]
				r.uid = uids[i]
				
				list_users.append(r)
			pass
			
		g.v.game_constants.CMDs.RANKING_RESULT:
			on_received_ranking_result(payload)
			pass
		g.v.game_constants.CMDs.RANKING_CLAIM_REWARD:
			pass

var rank_results = []
func on_received_ranking_result(payload):
	rank_results.append(payload)
	
func show_rank_result():
	var payload = rank_results.pop_front()
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.RankingResult.new()
	var result_code = pkg.from_bytes(payload)
	var season_id = pkg.get_season_id()
	var rank = pkg.get_rank()
	var gold_reward = pkg.get_gold_reward()
	
	var gui = g.v.scene_manager.open_gui("res://scenes/ranking/RankingResult.tscn")
	gui.set_info(season_id, rank, gold_reward)

func check_and_update():
	var interval = g.v.game_manager.get_timestamp_client() - last_time_received
	if interval < 15:
		return
	send_get_ranking_info()
	
func send_get_ranking_info():
	g.v.game_client.send_packet(g.v.game_constants.CMDs.RANKING_INFO, [])

func user_win_game():
	my_score += 1
	if my_rank > 10:
		var n = RankingPlayer.new()
		n.uid = g.v.player_info_mgr.get_user_id()
		n.score = my_score
		n.avatar = g.v.player_info_mgr.my_user_data.avatar
		n.name = g.v.player_info_mgr.my_user_data.name
		
		list_users.append(n)
	else:
		# find user
		for p in list_users:
			if p.uid == g.v.player_info_mgr.get_user_id():
				p.score = my_score
	sort_and_rank_users(list_users)
	
func sort_and_rank_users(list_users: Array) -> void:
	# Sort by score (highest first)
	list_users.sort_custom(func(a, b): return a.score > b.score)

	# Assign ranks (1-based index)
	for i in range(list_users.size()):
		list_users[i].rank = i + 1

	# Remove the 11th element if it exists
	if list_users.size() > 10:
		list_users.pop_at(10)

func send_claim_reward(season_id):
	var pkg = g.v.game_constants.PROTOBUF.PACKETS.RankingClaimReward.new()
	pkg.set_season_id(season_id)
	g.v.game_client.send_packet(g.v.game_constants.CMDs.RANKING_CLAIM_REWARD, pkg.to_bytes())

func show_gui():
	g.v.scene_manager.open_gui("res://scenes/ranking/RankingGUI.tscn", true)
