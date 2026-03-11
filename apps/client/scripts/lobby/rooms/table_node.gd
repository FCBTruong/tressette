extends Node

@onready var player_icon = find_child('PlayerIcon')
@onready var icon_vs1 = find_child("IconVs1")
@onready var icon_vs2 = find_child("IconVs2")
@onready var view_btn = find_child("ViewBtn")
@onready var play_btn = find_child("PlayBtn")
@onready var private_icon = find_child("PrivateIcon")
var _info: TableInfo
var slots = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slots.append(find_child("Slot1"))
	slots.append(find_child("Slot2"))
	slots.append(find_child("Slot3"))
	slots.append(find_child("Slot4"))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_info(table: TableInfo):
	self._info = table

	if table.player_mode < 4:
		slots[2].visible = false
		slots[3].visible = false
		icon_vs2.visible = false
		icon_vs1.visible = true
	else:
		slots[2].visible = true
		slots[3].visible = true
		icon_vs2.visible = true
		icon_vs1.visible = false
	
	if table.num_player == table.player_mode:
		self.view_btn.visible = true
		self.play_btn.visible = false
	else:
		self.view_btn.visible = false
		self.play_btn.visible = true
	
	private_icon.visible = _info.is_private
	for i in range(len(table.player_uids)):
		var uid = table.player_uids[i]
		var avatar = table.player_avatars[i]
		var avatar_frame = table.avatar_frames[i]
		if i >= len(slots):
			break
		if uid == -1:
			slots[i].find_child("AvatarCircle").visible = false
			continue
		slots[i].find_child("AvatarCircle").visible = true
		slots[i].find_child("AvatarImg").set_avatar(avatar)
		slots[i].find_child("AvatarFrame").update_frame_by_id(avatar_frame)

func _click_play():
	if self._info.num_player == self._info.player_mode:
		g.v.scene_manager.show_dialog(
			tr("ROOM_IS_FULL")
		)
		return
		
	if self._info.is_private:
		var gui = g.v.scene_manager.open_gui("res://scenes/lobby/JoinPrivateTable.tscn")
		gui.set_info(self._info.match_id, true)
	else:
		g.v.game_manager.join_game_by_id(self._info.match_id)

func _click_view():
	if self._info.is_private:
		var gui = g.v.scene_manager.open_gui("res://scenes/lobby/JoinPrivateTable.tscn")
		gui.set_info(self._info.match_id, false)
	else:
		g.v.game_manager.join_game_by_id(self._info.match_id)

	
func click_user1():
	var uid = _info.player_uids[0]
	g.v.friend_mgr.search_friend(uid)
		
func click_user2():
	var uid = _info.player_uids[1]
	g.v.friend_mgr.search_friend(uid)
		
func click_user3():
	var uid = _info.player_uids[2]
	g.v.friend_mgr.search_friend(uid)
		
func click_user4():
	var uid = _info.player_uids[3]
	g.v.friend_mgr.search_friend(uid)
