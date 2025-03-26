extends RefCounted

class_name RankingMgr

var time_end: int
class RankingPlayer:
	var uid: int
	var name: String
	var rank: int
	var avatar: String
	
var list_users = []

func on_receive(cmd_id: int, payload: PackedByteArray) -> void:
	print('addds', g.v.game_constants.CMDs.RANKING_INFO)
	match cmd_id:
		g.v.game_constants.CMDs.RANKING_INFO:
			list_users.clear()
			
			for i in range(10):
				var r = RankingPlayer.new()
				r.rank = i + 1
				r.name = "Huy Truong"
				r.avatar = '2'
				list_users.append(r)
			pass
