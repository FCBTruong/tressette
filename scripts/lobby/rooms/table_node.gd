extends Node

@onready var bet_lb = find_child("BetLb")
@onready var player_lb = find_child("PlayerLb")
@onready var player_icon = find_child('PlayerIcon')
var _info: TableInfo
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_info(table: TableInfo):
	self._info = table
	self.bet_lb.text = StringUtils.point_number(table.bet) \
		 + ' ' + GameConstants.LIRA_TEXT
		
	var str = ""
	str += str(table.num_player) + '/' + str(table.player_mode)
	player_lb.text = str
	
	if table.num_player == table.player_mode:
		#player_icon.modulate = Color('a61616')
		pass
	

func _click_play():
	if self._info.num_player == self._info.player_mode:
		SceneManager.show_dialog(
			tr("ROOM_IS_FULL")
		)
		return
	# check if enough gold
	if self._info.bet * GameServerConfig.bet_multiplier_min > \
		PlayerInfoMgr.my_user_data.gold:
		GameManager.show_not_gold_recommend_shop()
		return
	GameManager.join_game_by_id(self._info.match_id)
