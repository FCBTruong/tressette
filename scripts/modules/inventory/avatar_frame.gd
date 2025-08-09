extends Control

@export var is_me: bool = false
@onready var frame_default = find_child("Frame0")
@onready var frame_victory = find_child("FrameVictory")
@onready var frame1 = find_child("Frame1")
@onready var frame_vip = find_child("FrameVip")

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
		_:
			show_frame(null)

func show_frame(fr):
	frame_default.visible = frame_default == fr
	frame_victory.visible = frame_victory == fr
	frame_vip.visible = frame_vip == fr
	frame1.visible = frame1 == fr

func on_changed_my_frame():
	if is_me:
		update_frame_by_id(g.v.player_info_mgr.my_user_data.avatar_frame)
