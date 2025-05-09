extends Node

@onready var bet_lb = find_child("BetLb")
@onready var player_icon = find_child('PlayerIcon')
@onready var full_icon = find_child("FullIcon")
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

@onready var game_lb = find_child("GameLb")
func set_info(table: TableInfo):
	self._info = table
	self.bet_lb.text = StringUtils.point_number(table.bet)

	if table.player_mode < 4:
		slots[2].visible = false
		slots[3].visible = false
	else:
		slots[2].visible = true
		slots[3].visible = true
	
	if table.num_player == table.player_mode:
		full_icon.visible = true
	else:
		full_icon.visible = false
	if table.game_mode == g.v.game_constants.GAME_MODE.TRESSETTE:
		game_lb.text = "Tressette"
	else:
		game_lb.text = "Sette e Mezzo"
	
	for i in range(len(table.player_uids)):
		var uid = table.player_uids[i]
		var avatar = table.player_avatars[i]
		if i >= len(slots):
			break
		if uid == -1:
			slots[i].find_child("AvatarCircle").visible = false
			continue
		slots[i].find_child("AvatarCircle").visible = true
		slots[i].find_child("AvatarImg").set_avatar(avatar)

func _click_play():
	if self._info.num_player == self._info.player_mode:
		g.v.scene_manager.show_dialog(
			tr("ROOM_IS_FULL")
		)
		return
	# check if enough gold
	if self._info.bet * g.v.game_server_config.bet_multiplier_min > \
		g.v.player_info_mgr.my_user_data.gold:
		g.v.game_manager.show_not_gold_recommend_shop()
		return
	g.v.game_manager.join_game_by_id(self._info.match_id)
