extends Control

@export var is_me: bool = false
@onready var frame_default = find_child("Frame0")
@onready var frame_victory = find_child("FrameVictory")
@onready var frame1 = find_child("Frame1")
@onready var frame_vip = find_child("FrameVip")
@onready var frame_lv50 = find_child("FrameLv50")
@onready var frame_lv100 = find_child("FrameLv100")
@onready var frame_gold = find_child("FrameGold")

var frame_id: int = g.v.game_constants.AVATAR_FRAME_IDS.DEFAULT

func _ready() -> void:
	if is_me:
		update_frame_by_id(g.v.player_info_mgr.my_user_data.avatar_frame)
	g.v.signal_bus.connect_global('on_changed_frame', Callable(self, "on_changed_my_frame"))

func set_me(me: bool = true):
	is_me = me
	if is_me:
		update_frame_by_id(g.v.player_info_mgr.my_user_data.avatar_frame)
		
func update_frame_by_id(id: int) -> void:
	match id:
		g.v.game_constants.AVATAR_FRAME_IDS.DEFAULT:
			show_frame(frame_default)
		g.v.game_constants.AVATAR_FRAME_IDS.VICTORY:
			show_frame(frame_victory)
		g.v.game_constants.AVATAR_FRAME_IDS.SEASON:
			show_frame(frame1)
		g.v.game_constants.AVATAR_FRAME_IDS.VIP:
			show_frame(frame_vip)
		g.v.game_constants.AVATAR_FRAME_IDS.LEVEL_50:
			show_frame(frame_lv50)
		g.v.game_constants.AVATAR_FRAME_IDS.LEVEL_100:
			show_frame(frame_lv100)
		g.v.game_constants.AVATAR_FRAME_IDS.GOLD:
			show_frame(frame_gold)
		_:
			show_frame(null)

func show_frame(fr):
	frame_default.visible = frame_default == fr
	frame_victory.visible = frame_victory == fr
	frame_vip.visible = frame_vip == fr
	frame1.visible = frame1 == fr
	frame_lv50.visible = frame_lv50 == fr
	frame_lv100.visible = frame_lv100 == fr
	frame_gold.visible = frame_gold == fr

func on_changed_my_frame():
	if is_me:
		update_frame_by_id(g.v.player_info_mgr.my_user_data.avatar_frame)
