extends RefCounted
class_name MissionMgr

func open_mission_gui():
	var a = MissionInfo.new()
	a.id = 0
	a.status = 1
	a.gold = 20000
	a.name = 'Login with google'
	
	missions.append(a)
	
	var b = MissionInfo.new()
	b.id = 0
	b.status = 0
	b.gold = 100000
	b.name = 'Share with your friends'
	
	missions.append(b)
	missions.sort_custom(custom_sort)

	# sort mission
	
	g.v.scene_manager.open_gui('res://scenes/mission/MissionGUI.tscn')
	pass

func custom_sort(a, b):
	var order = {1: 0, 0: 1, 2: 2} # Define the sorting order
	return order[a.status] < order[b.status] 
	
class MissionInfo:
	var name: String
	var id: int
	var status: int
	var time_refresh: int
	var gold: int

var missions = []
